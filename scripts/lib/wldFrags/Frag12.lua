
local ffi			= require "ffi"
local FragHeader	= require "wldFrags/FragHeader"

ffi.cdef[[
typedef struct WLDFrag12Entry {
	int16_t	rotDenom;
	int16_t	rotX, rotY, rotZ;
	int16_t	shiftX, shiftY, shiftZ;
	int16_t	shiftDenom;
} WLDFrag12Entry;

typedef struct WLDFrag12 {
	WLDFragHeader	header;
	uint32_t		flag;
	uint32_t		count;
	WLDFrag12Entry	entry[0];
} WLDFrag12;
]]

return FragHeader.plainType("WLDFrag12")
