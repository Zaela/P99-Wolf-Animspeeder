
local ffi			= require "ffi"
local FragHeader	= require "wldFrags/FragHeader"

ffi.cdef[[
typedef struct WLDFrag15 {
	WLDFragHeader	header;
	int				refName;
	uint32_t		flag;
	int				refB;
	float			x, y, z;
	float			rotX, rotY, rotZ;
	float			scaleX, scaleY, scaleZ;
	int				refC;
	uint32_t		refCParam;
} WLDFrag15;
]]

return FragHeader.plainType("WLDFrag15")
