
local ffi			= require "ffi"
local bit			= require "bit"
local BinUtil		= require "BinUtil"
local FragHeader	= require "wldFrags/FragHeader"

local FragTypes = {
	[0x03] = require "wldFrags/Frag03",
	[0x04] = require "wldFrags/Frag04",
	[0x05] = require "wldFrags/Frag05",
	[0x10] = require "wldFrags/Frag10",
	[0x11] = require "wldFrags/Frag11",
	[0x12] = require "wldFrags/Frag12",
	[0x13] = require "wldFrags/Frag13",
	[0x14] = require "wldFrags/Frag14",
	[0x15] = require "wldFrags/Frag15",
	[0x2d] = require "wldFrags/Frag2D",
	[0x30] = require "wldFrags/Frag30",
	[0x31] = require "wldFrags/Frag31",
	[0x36] = require "wldFrags/Frag36",
}

ffi.cdef[[
typedef struct WLDHeader {
	uint32_t	signature;
	uint32_t	version;
	uint32_t	fragCount;
	uint32_t	unknownA[2];
	uint32_t	stringsLen;
	uint32_t	unknownB;

	static const uint32_t VERSION1 = 0x00015500;
	static const uint32_t VERSION2 = 0x1000C800;
} WLDHeader;
]]

local setmetatable	= setmetatable
local string		= string
local table			= table

local WLDHeader		= ffi.typeof("WLDHeader")
local WLDHeaderPtr	= ffi.typeof("WLDHeader*")
local Signature		= BinUtil.toFileSignature(string.char(0x02, 0x3D, 0x50, 0x54))

local WLD = {
	HeaderType	= WLDHeader,
	Signature	= Signature,
}
WLD.__index = WLD

function WLD.open(data, len)
	local p = 0
	local function checkTooShort()
		if p > len then error("File is too short for length of data indicated") end
	end

	local header = ffi.cast(WLDHeaderPtr, data)
	p = ffi.sizeof(WLDHeader)

	checkTooShort()

	if header.signature ~= Signature then
		error("File is not a valid WLD")
	end

	local version = bit.band(header.version, 0xFFFFFFFE)
	if version ~= header.VERSION1 and version ~= header.VERSION2 then
		error("Invalid WLD version")
	end
	version = (version == header.VERSION1) and 1 or 2

	-- process the string block
	local stringBlock = ffi.cast(BinUtil.CharPtr, data + p)
	p = p + header.stringsLen
	checkTooShort()
	WLD.processString(stringBlock, header.stringsLen)

	-- gather fragments
	local fragsByIndex		= {}
	local fragsByNameIndex	= {}
	local fragsByName		= {}
	local fragsByType		= {}

	local function byType(frag)
		local t = frag:getType()
		local tbl = fragsByType[t]
		if not tbl then
			tbl = {}
			fragsByType[t] = tbl
		end

		tbl[#tbl + 1] = frag
	end

	local minRef = -header.stringsLen

	for i = 1, header.fragCount do
		local frag = ffi.cast(FragHeader.Ptr, data + p)
		local cast = FragTypes[frag:getType()]

		if cast then
			frag = ffi.cast(cast.Ptr, frag)
		end

		fragsByIndex[i] = frag
		byType(frag)
		local nameref = frag:getNameRef()
		if nameref < 0 and nameref > minRef then
			fragsByNameIndex[nameref] = frag
			fragsByName[ffi.string(stringBlock - nameref)] = frag
		end

		p = p + frag:getLen()
		checkTooShort()
	end

	local wld = {
		header				= header,
		version				= version,
		stringBlock			= stringBlock,
		stringBlockLen		= header.stringsLen,
		rawData		        = data,
        rawLength           = len,
		fragsByIndex		= fragsByIndex,
		fragsByNameIndex	= fragsByNameIndex,
		fragsByName			= fragsByName,
		fragsByType			= fragsByType,
	}

	return setmetatable(wld, WLD)
end

--------------------------------------------------------------------------------
-- WLD info getter functions
--------------------------------------------------------------------------------

function WLD:getVersion()
	return self.version
end

function WLD:getStringBlock()
	return self.stringBlock
end

function WLD:getStringBlockLength()
	return self.stringBlockLen
end

function WLD:getRawData()
    return self.rawData, self.rawLength
end

--------------------------------------------------------------------------------
-- Fragment getter functions
--------------------------------------------------------------------------------

function WLD:getFragByRef(ref)
	if ref > 0 then
		return self.fragsByIndex[ref]
	end
	if ref == 0 then ret = -1 end
	return self.fragsByNameIndex[ref]
end

function WLD:getFragByRefVar(frag)
	return self:getFragByRef(frag.ref)
end

function WLD:getFragsByType(t)
	return ipairs(self.fragsByType[t])
end

function WLD:getFragNameByRef(ref)
	if ref < 0 and ref > -self.stringBlockLen then
		return ffi.string(self.stringBlock - ref)
	end
	return ""
end

function WLD:getFragName(frag)
	return self:getFragNameByRef(frag.header.nameref)
end

--------------------------------------------------------------------------------

local xor	= bit.bxor
local hash	= BinUtil.ByteArray(8, 0x95, 0x3A, 0xC5, 0x2A, 0x95, 0x7A, 0x95, 0x6A)
function WLD.processString(cstr, len)
	for i = 0, len - 1 do
		cstr[i] = xor(cstr[i], hash[i % 8])
	end
end

return WLD
