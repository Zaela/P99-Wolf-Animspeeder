
local ffi		= require "ffi"
local BinUtil	= require "BinUtil"

local assert = assert

ffi.cdef[[
unsigned long zlib_compressBound(unsigned long sourceLen);
int zlib_compress(uint8_t* dest, unsigned long* destLen, const uint8_t* source, unsigned long sourceLen, int level);
int zlib_uncompress(uint8_t* dest, unsigned long* destLen, const uint8_t* source, unsigned long sourceLen);
]]

local C = ffi.C

local zlib = {}

local buffer 	= BinUtil.ByteArray(16384)
local buflen 	= ffi.new("unsigned long[1]")

function zlib.Compress(data, len)
	assert(C.zlib_compressBound(len) <= 16384)
	buflen[0] = 16384
	local res = C.zlib_compress(buffer, buflen, data, len, 9)
	assert(res == 0)
	return buffer, buflen[0]
end

function zlib.Decompress(data, len)
	buflen[0] = 16384
	local res = C.zlib_uncompress(buffer, buflen, data, len)
	assert(res == 0)
	return buffer, buflen[0]
end

function zlib.compressWhole(data, len)
	data = ffi.cast(BinUtil.BytePtr, data)
	buflen[0] = C.zlib_compressBound(len)
	local new = BinUtil.ByteArray(buflen[0])
	local res = C.zlib_compress(new, buflen, data, len, 9)
	assert(res == 0)
	return new, buflen[0]
end

function zlib.decompressWhole(data, orig_len)
	data = ffi.cast(BinUtil.BytePtr, data)
	buflen[0] = orig_len
	local new = BinUtil.ByteArray(orig_len)
	local res = C.zlib_uncompress(new, buflen, data, orig_len)
	assert(res == 0)
	return new, buflen[0]
end

return zlib
