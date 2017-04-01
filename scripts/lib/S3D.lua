
local BinUtil	= require "BinUtil"
local Buffer	= require "Buffer"
local Zlib		= require "Zlib"
local ffi		= require "ffi"
local bit		= require "bit"
local lfs		= require "lfs"
local Settings	= require "Settings"

local C				= ffi.C
local os			= os
local setmetatable	= setmetatable
local table			= table
local ipairs 		= ipairs

ffi.cdef[[
typedef struct S3DHeader {
	uint32_t offset;
	uint32_t signature;
	uint32_t unknown;
} S3DHeader;

typedef struct S3DBlockHeader {
	uint32_t deflatedLen;
	uint32_t inflatedLen;
} S3DBlockHeader;

typedef struct S3DDirEntry {
	uint32_t crc;
	uint32_t offset;
	uint32_t inflatedLen;
} S3DDirEntry;

typedef struct S3DEntry {
	uint32_t pos;
	uint32_t crc;
	uint32_t offset;
	uint32_t inflatedLen;
	uint32_t deflatedLen;
} S3DEntry;

size_t fwrite(const void*, size_t, size_t, void*);
]]

local S3DHeaderPtr		= ffi.typeof("S3DHeader*")
local S3DBlockHeader	= ffi.typeof("S3DBlockHeader")
local S3DBlockHeaderPtr = ffi.typeof("S3DBlockHeader*")
local S3DDirEntry		= ffi.typeof("S3DDirEntry")
local S3DDirEntryPtr	= ffi.typeof("S3DDirEntry*")
local S3DEntry			= ffi.typeof("S3DEntry")
local S3DEntryPtr		= ffi.typeof("S3DEntry*")
local Signature			= BinUtil.toFileSignature("PFS ")

local lshift		= bit.lshift
local rshift		= bit.rshift
local xor			= bit.bxor
local bitwise_and	= bit.band
local crc_table		= require "crc_table"

local function CalcCRC(name)
	local val = 0
	for i = 1, #name + 1 do
		local index = bitwise_and(xor(rshift(val, 24), name:byte(i)), 0xFF)
		val = xor(lshift(val, 8), crc_table[index])
	end
	return val
end

local S3D = {}
S3D.__index = S3D

local function DecompressDirEntry(data, inflatedLen)
	local read = 0
	local pos = 0
	local buf = Buffer.new()

	while read < inflatedLen do
		local bh = ffi.cast(S3DBlockHeaderPtr, data + pos)
		pos = pos + ffi.sizeof(S3DBlockHeader)

		local buffer = Zlib.Decompress(data + pos, bh.deflatedLen)
		read = read + bh.inflatedLen
		pos = pos + bh.deflatedLen
		buf:Add(buffer, bh.inflatedLen)
	end

	return buf:Take()
end

local function AddByExt(by_ext, name, n)
	local ext = name:match("[^%.]+$")
	local t = by_ext[ext]
	if not t then
		t = {}
		by_ext[ext] = t
	end
	table.insert(t, n)
end

function S3D.open(path, reload)
	path = Settings.getEQFolder() .."/".. path
	local data = BinUtil.openRaw(path)

	local header = ffi.cast(S3DHeaderPtr, data)
	if header.signature ~= Signature then
		error("File is not a valid S3D/EQG archive")
	end

	local p = header.offset
	local n = ffi.cast(BinUtil.UintPtr, data + p)
	local num_entries = n[0]
	p = p + ffi.sizeof(BinUtil.Uint)

	local tbl
	if reload then
		reload.raw_data = data
		reload.path = path
		reload.decompressed = {}
		reload.names = {}
		reload.by_name = {}
		reload.by_ext = {}
		reload.timestamp = lfs.attributes(path, "modification") or os.time()
		tbl = reload
	else
		tbl = {
			raw_data = data, path = path, decompressed = {}, names = {}, by_name = {}, by_ext = {},
			timestamp = lfs.attributes(path, "modification") or os.time(),
		}
	end

	for i = 1, num_entries do
		local entry = ffi.cast(S3DDirEntryPtr, data + p)
		p = p + ffi.sizeof(S3DDirEntry)

		local ent = S3DEntry()
		ent.crc = entry.crc
		ent.offset = entry.offset
		ent.inflatedLen = entry.inflatedLen

		local dpos = entry.offset
		local ilen = 0
		while ilen < entry.inflatedLen do
			local bh = ffi.cast(S3DBlockHeaderPtr, data + dpos)
			local shift = ffi.sizeof(S3DBlockHeader) + bh.deflatedLen
			dpos = dpos + shift
			ilen = ilen + bh.inflatedLen
		end
		ent.deflatedLen = dpos - entry.offset

		tbl[i] = ent
	end

	table.sort(tbl, function(a, b) return a.offset < b.offset end)
	local last = tbl[#tbl]
	tbl[#tbl] = nil --name listing is not a real entry

	local name_data = DecompressDirEntry(data + last.offset, last.inflatedLen)
	n = ffi.cast(BinUtil.UintPtr, name_data)
	n = n[0]
	p = ffi.sizeof(BinUtil.Uint)

	for i = 1, n do
		local len = ffi.cast(BinUtil.UintPtr, name_data + p)
		len = len[0]
		p = p + ffi.sizeof(BinUtil.Uint)
		local name = ffi.cast(BinUtil.CharPtr, name_data + p)
		p = p + len

		name = ffi.string(name, len - 1) --cut trailing null byte

		--tbl[i].pos = i
		tbl.names[i] = name
		tbl.by_name[name] = i
		AddByExt(tbl.by_ext, name, i)
	end

	S3D.cur = tbl

	return setmetatable(tbl, S3D)
end

function S3D.getCurrent()
	return S3D.cur
end

function S3D:reload()
	local m = lfs.attributes(self.path, "modification")
	if m and m > self.timestamp then
		S3D.open(self.path, self)
	end
end

function S3D:outdated()
	return (lfs.attributes(self.path, "modification") > self.timestamp)
end

function S3D:getEntry(i)
	local ent = self.decompressed[i]
	if ent then return ent, ffi.sizeof(ent) end

	ent = self[i]
	local data = DecompressDirEntry(self.raw_data + ent.offset, ent.inflatedLen)
	if data then
		self.decompressed[i] = data
		return data, ent.inflatedLen
	end
end

function S3D:getEntryByName(name)
	local i = self.by_name[name]
	if i then return self:getEntry(i) end
end

function S3D:getEntryByExt(ext, pos)
	local tbl = self.by_ext[ext]
	if not tbl then return end
	pos = pos or 1
	local i = tbl[pos]
	if i then return self:getEntry(i), self.names[i] end
end

function S3D:fileNames()
	local i = 0
	return function()
		i = i + 1
		return self.names[i]
	end
end

function S3D:extNames(ext)
	local ext_indices = self.by_ext[ext]
	return function(names, i)
		i = i + 1
		local n = ext_indices[i]
		if not n then return end
		local name = names[n]
		if name then return i, name end
	end, self.names, 0
end

function S3D:export(i, path)
	self:reload()
	local file = assert(io.open(path, "wb+"))
	local data, len = self:getEntry(i)
	C.fwrite(data, 1, len, file)
	file:close()
end

function S3D:exportByName(name, path)
	local i = self.by_name[name]
	if i then self:export(i, path) end
end

function S3D:import(path, filename)
	local name = filename and filename:lower() or path:match("[^\\/]+$"):lower()
	local data, len = BinUtil.openRaw(path)

	self:importFromMemory(data, len, name)
end

function S3D:importFromMemory(data, len, name)
	self:reload()

	local n = self.by_name[name]
	if not n then
		n = #self + 1
	end

	local ent = S3DEntry()
	ent.pos = n
	ent.crc = CalcCRC(name)
	ent.inflatedLen = len

	self[n] = ent
	self.names[n] = name
	self.by_name[name] = n
	self.decompressed[n] = data
	AddByExt(self.by_ext, name, n)
end

local function CompressDirEntry(data, len)
	local buf = Buffer.new()

	while len > 0 do
		local r = len < 8192 and len or 8192
		local bh = S3DBlockHeader()
		bh.inflatedLen = r

		local d, dlen = Zlib.Compress(data, r)
		bh.deflatedLen = dlen

		buf:Add(bh, ffi.sizeof(bh))
		buf:Add(d, dlen)

		len = len - r
		data = data + r
	end

	return buf:Take(), buf:GetLen()
end

function S3D:save(override_path)
	if override_path then self.path = Settings.getEQFolder() .."/".. override_path end

	local header		= ffi.new("S3DHeader")
	header.signature	= Signature
	header.unknown		= 131072

	local file_pos = ffi.sizeof(header)

	local dir_entries = {}
	local data_buf = Buffer.new(true)
	local name_buf = Buffer.new()

	local n = BinUtil.UintArg(#self)
	name_buf:Add(n, ffi.sizeof(BinUtil.Uint))

	local decompressed = self.decompressed
	local raw_data = self.raw_data
	local names = self.names
	for i = 1, #self do
		local ent = self[i]
		--write name with 32bit len header
		local name = names[i]
		n[0] = #name + 1
		name_buf:Add(n, ffi.sizeof(BinUtil.Uint))
		name_buf:Add(name, n[0])

		local e = S3DDirEntry()
		e.crc = ent.crc
		e.offset = file_pos
		e.inflatedLen = ent.inflatedLen
		dir_entries[i] = e

		local d = decompressed[i]
		if d then
			local data, len = CompressDirEntry(d, ent.inflatedLen)
			data_buf:Add(data, len)
			file_pos = file_pos + len
		else
			local len = ent.deflatedLen
			data_buf:Add(raw_data + ent.offset, len)
			file_pos = file_pos + len
		end
	end

	--compress names entry so we can tell the header the offset after it
	local ent = S3DDirEntry()
	ent.crc = 0x61580AC9 --always this
	ent.offset = file_pos
	ent.inflatedLen = name_buf:GetLen()
	table.insert(dir_entries, ent)

	table.sort(dir_entries, function(a, b) return a.crc < b.crc end)

	local add_names = Buffer.new()
	local d, len = CompressDirEntry(name_buf:Take(), name_buf:GetLen())
	add_names:Add(d, len)
	file_pos = file_pos + len

	header.offset = file_pos

	--finally, start writing to the file
	local file = assert(io.open(self.path, "wb+"))

	--write header
	C.fwrite(header, ffi.sizeof(header), 1, file)

	--write compressed entries
	C.fwrite(data_buf:Take(), 1, data_buf:GetLen(), file)

	--write file names entry
	C.fwrite(add_names:Take(), 1, add_names:GetLen(), file)

	--write offset and crc list in order of crc
	n[0] = #dir_entries
	C.fwrite(n, ffi.sizeof(BinUtil.Uint), 1, file)
	for i = 1, #dir_entries do
		local ent = dir_entries[i]
		C.fwrite(ent, ffi.sizeof(ent), 1, file)
	end

	file:close()
end

function S3D.new(path)
	local new = {path = path, decompressed = {}, names = {}, by_name = {}, by_ext = {}, timestamp = os.time()}
	setmetatable(new, S3D)
	new:save()
	return new
end

function S3D:deleteEntry(i)
	local names = self.names
	local decompressed = self.decompressed
	local by_name = self.by_name

	table.remove(self, i)
	local name = names[i]
	table.remove(names, i)
	by_name[name] = nil
	if decompressed[i] then
		decompressed[i] = nil
	end

	--correct by_name and decompressed for subsequent entries
	for n = i, #self do
		by_name[names[n]] = n
		local d = decompressed[n + 1]
		if d then
			decompressed[n] = d
			decompressed[n + 1] = nil
		end
	end
end

function S3D:deleteEntryByName(name)
	local i = self.by_name[name]
	if i then self:deleteEntry(i) end
end

function S3D:nameExists(name)
	local i = self.by_name[name]
	return i
end

function S3D:saveWLD(wld, name)
    local strings = wld:getStringBlock()
    local n = wld:getStringBlockLength()
    wld.processString(strings, n)

    local data, len = wld:getRawData()

    self:importFromMemory(data, len, name)
    self:save()
end

return S3D
