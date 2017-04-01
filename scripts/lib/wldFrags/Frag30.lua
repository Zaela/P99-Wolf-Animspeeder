
local ffi			= require "ffi"
local FragHeader	= require "wldFrags/FragHeader"

ffi.cdef[[
typedef struct WLDFrag30 {
	WLDFragHeader	header;
	uint32_t		flag;
	uint32_t		visibilityFlag;
	uint32_t		unknown[3];
	int				ref;
	int				unknownB[2];
} WLDFrag30;
]]

return FragHeader.plainType("WLDFrag30")
