
local ffi			= require "ffi"
local FragHeader	= require "wldFrags/FragHeader"

ffi.cdef[[
typedef struct WLDFrag13 {
	WLDFragHeader	header;
	int				ref;
	uint32_t		flag;
	uint32_t		param;
} WLDFrag13;
]]

return FragHeader.plainType("WLDFrag13")
