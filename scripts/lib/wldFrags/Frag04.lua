
local ffi			= require "ffi"
local FragHeader	= require "wldFrags/FragHeader"

ffi.cdef[[
typedef struct WLDFrag04 {
	WLDFragHeader	header;
	uint32_t		flag;
	int				count;
	int				ref;
} WLDFrag04;

typedef struct WLDFrag04Animated {
	WLDFragHeader	header;
	uint32_t		flag;
	int				count;
	uint32_t		milliseconds;
	int				refList[0];
} WLDFrag04Animated;
]]

local Frag04			= FragHeader.derivedType("WLDFrag04")
local Frag04Animated	= FragHeader.derivedType("WLDFrag04Animated")

function Frag04:isAnimated()
	return self.count > 1
end

function Frag04:toAnimated()
	return ffi.cast(Frag04Animated.Ptr, self)
end

function Frag04:fixRefs(refMap)
	if self:isAnimated() then
		local f = self:toAnimated()
		for i = 0, f.count - 1 do
			f.refList[i] = refMap:get(f.refList[i])
		end
		return
	end

	self.ref = refMap:get(self.ref)
end

ffi.metatype("WLDFrag04", Frag04)
ffi.metatype("WLDFrag04Animated", Frag04Animated)

return Frag04
