
local ffi			= require "ffi"
local FragHeader	= require "wldFrags/FragHeader"

ffi.cdef[[
typedef struct WLDFrag31 {
	WLDFragHeader	header;
	uint32_t		flag;
	uint32_t		refCount;
	int				refList[0];
} WLDFrag31;
]]

local Frag31 = FragHeader.derivedType("WLDFrag31")

function Frag31:fixRefs(refMap)
	for i = 0, self.refCount - 1 do
		self.refList[i] = refMap:get(self.refList[i])
	end
end

ffi.metatype("WLDFrag31", Frag31)

return Frag31
