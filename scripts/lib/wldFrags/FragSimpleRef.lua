
local ffi			= require "ffi"
local FragHeader	= require "wldFrags/FragHeader"

ffi.cdef[[
typedef struct WLDFragSimpleRef {
	WLDFragHeader	header;
	int				ref;
	uint32_t		flag;
} WLDFragSimpleRef;
]]

return FragHeader.plainType("WLDFragSimpleRef")
