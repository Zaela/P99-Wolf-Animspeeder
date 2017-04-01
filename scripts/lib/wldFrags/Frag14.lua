
local ffi			= require "ffi"
local FragHeader	= require "wldFrags/FragHeader"
local BinUtil		= require "BinUtil"
local bit			= require "bit"

ffi.cdef[[
typedef struct WLDFrag14 {
	WLDFragHeader	header;
	uint32_t		flag;
	int				refA;
	int				size[2];
	int				refB;
} WLDFrag14;
]]

local Frag14 = FragHeader.derivedType("WLDFrag14")

Frag14.Type = ffi.typeof("WLDFrag14")

function Frag14:hasMeshRefs()
	return self.size[1] > 0
end

local function skipToRefList(self)
	local ptr = ffi.cast(BinUtil.BytePtr, self) + ffi.sizeof(Frag14.Type)
	ptr = ffi.cast(BinUtil.IntPtr, ptr)

	-- skip optional fields, if they are indicated to exist
	if bit.band(self.flag, 1) ~= 0 then
		ptr = ptr + 1
	end
	if bit.band(self.flag, 2) ~= 0 then
		ptr = ptr + 1
	end
	-- skip variable size portions
	for i = 0, self.size[0] - 1 do
		ptr = ptr + (ptr[0] * 2 + 1)
	end

	return ptr
end

function Frag14:getRefListFrags(wld)
	local ptr = skipToRefList(self)

	-- get frags
	local frags = {}
	for i = 1, self.size[1] do
		frags[i] = wld:getFragByRef(ptr[0])
		ptr = ptr + 1
	end
	return frags
end

function Frag14:getFirstRefPtr()
	local ptr = skipToRefList(self)
	return ptr
end

function Frag14:getMeshRefCount()
	return self.size[1]
end

function Frag14:fixRefs(refMap)
	self.refA = refMap:get(self.refA)
	self.refB = refMap:get(self.refB)

	if not self:hasMeshRefs() then return end

	local ptr = self:getFirstRefPtr()
	for i = 0, self:getMeshRefCount() - 1 do
		ptr[i] = refMap:get(ptr[i])
	end
end

ffi.metatype("WLDFrag14", Frag14)

return Frag14
