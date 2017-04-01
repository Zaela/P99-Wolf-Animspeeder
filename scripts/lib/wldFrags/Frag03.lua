
local ffi			= require "ffi"
local FragHeader	= require "wldFrags/FragHeader"

ffi.cdef[[
#pragma pack(1)

typedef struct WLDFrag03 {
	WLDFragHeader	header;
	int				count;
	uint16_t		stringLen;
	uint8_t			string[0];
} WLDFrag03;

#pragma pack()
]]

return FragHeader.plainType("WLDFrag03")
