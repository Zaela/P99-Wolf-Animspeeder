
local ffi 		= require "ffi"
local zlib 		= require "Zlib"
local BinUtil	= require "BinUtil"

local setmetatable = setmetatable

local Buffer = {}
Buffer.__index = Buffer

function Buffer.new(huge)
	local cap = huge and 2 ^ 22 or 8192
	local buf = {
		len = 0,
		cap = cap,
		data = BinUtil.ByteArray(cap),
	}
	return setmetatable(buf, Buffer)
end

local function resize(buf, targ_len)
	local cap = buf.cap
	repeat
		cap = cap * 2
	until cap > targ_len
	local data = BinUtil.ByteArray(cap)
	ffi.copy(data, buf.data, buf.len)
	buf.cap = cap
	buf.data = data
end

function Buffer:Add(ptr, len)
	len = len or ffi.sizeof(ptr)
	local newlen = self.len + len
	if newlen >= self.cap then
		resize(self, newlen)
	end
	ffi.copy(self.data + self.len, ptr, len)
	self.len = newlen
end

function Buffer:GetLen()
	return self.len
end

local function finalize_size(buf)
	local data = BinUtil.ByteArray(buf:GetLen())
	ffi.copy(data, buf.data, buf:GetLen())
	buf.data = data
end

function Buffer:Take()
	if self.len < (self.cap - 1) then
		finalize_size(self)
	end
	local data = self.data
	self.data = nil
	return data
end

function Buffer:GetData()
	return self.data
end

function Buffer:GetPtr(index, size_type, ptr_type)
	local p = index * ffi.sizeof(size_type)
	return ffi.cast(ptr_type, self.data + p)
end

function Buffer:GetBasePtr(ptr_type)
	return ffi.cast(ptr_type, self.data)
end

function Buffer:GetElement(index, ptr_type)
	local ptr = ffi.cast(ptr_type, self.data)
	return ptr[index]
end

function Buffer:Compress()
	self.data, self.len = zlib.CompressWhole(self.data, self.len)
end

return Buffer
