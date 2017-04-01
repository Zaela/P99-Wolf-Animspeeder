
local ffi			= require "ffi"
local bit			= require "bit"
local BinUtil		= require "BinUtil"
local FragHeader	= require "wldFrags/FragHeader"

ffi.cdef[[
typedef struct WLDFrag10 {
	WLDFragHeader	header;
	uint32_t		flag;
	int				numBones;
	int				ref;
} WLDFrag10;

typedef struct WLDFrag10Bone {
	int			nameref;
	uint32_t	flag;
	int			refA;
	int			refB;
	int			size;
} WLDFrag10Bone;
]]

local Frag10	= FragHeader.derivedType("WLDFrag10")
local BoneType	= ffi.typeof("WLDFrag10Bone")
local BonePtr	= ffi.typeof("WLDFrag10Bone*")

function Frag10:getRefList()
	local ptr = ffi.cast(BinUtil.BytePtr, self) + ffi.sizeof(Frag10.Type)

	-- skip optional fields if they exist
	if bit.band(self.flag, 1) ~= 0 then
		ptr = ptr + 12
	end
	if bit.band(self.flag, 2) ~= 0 then
		ptr = ptr + 4
	end

	-- skipping of various sizes
	for i = 1, self.numBones do
		ptr = ptr + 16
		local count = ffi.cast(BinUtil.IntPtr, ptr)[0]
		ptr = ptr + count * 4 + 4
	end

	local n = ffi.cast(BinUtil.IntPtr, ptr)[0]
	ptr = ptr + 4
	return ffi.cast(BinUtil.IntPtr, ptr), n
end

function Frag10:fixRefs(refMap)
	self.ref = refMap:get(self.ref)

	local ptr = ffi.cast(BinUtil.BytePtr, self) + ffi.sizeof(Frag10.Type)

	-- skip optional fields if they exist
	if bit.band(self.flag, 1) ~= 0 then
		ptr = ptr + 12
	end
	if bit.band(self.flag, 2) ~= 0 then
		ptr = ptr + 4
	end

	-- bones
	for i = 1, self.numBones do
		local bone = ffi.cast(BonePtr, ptr)

		bone.nameref = refMap:get(bone.nameref)
		bone.refA = refMap:get(bone.refA)
		bone.refB = refMap:get(bone.refB)

		ptr = ptr + (bone.size * 4 + ffi.sizeof(BoneType))
	end

	-- ref list
	local int = ffi.cast(BinUtil.IntPtr, ptr)
	local n = int[0]
	for i = 1, n do
		int[i] = refMap:get(int[i])
	end
end

ffi.metatype("WLDFrag10", Frag10)

return Frag10
