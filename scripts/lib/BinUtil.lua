
local ffi = require "ffi"

ffi.cdef[[
/* for fileRaw */
size_t fread(void* ptr, size_t size, size_t count, void* file);
]]

local C			= ffi.C
local io		= io
local math		= math
local tonumber	= tonumber

local BinUtil = {
	Uint			= ffi.typeof("uint32_t"),

	VoidPtr			= ffi.typeof("void*"),
	BytePtr			= ffi.typeof("uint8_t*"),
	CharPtr			= ffi.typeof("char*"),
	UintPtr			= ffi.typeof("uint32_t*"),
	IntPtr			= ffi.typeof("int*"),
	IntPtrT			= ffi.typeof("intptr_t"),

	IntArg			= ffi.typeof("int[1]"),
	UintArg			= ffi.typeof("uint32_t[1]"),
	ConstCharPtrArg	= ffi.typeof("const char*[1]"),

	CharArray		= ffi.typeof("char[?]"),
	ByteArray		= ffi.typeof("uint8_t[?]"),
	IntArray		= ffi.typeof("int[?]"),
	UintArray		= ffi.typeof("uint32_t[?]"),

	FuncRInt			= ffi.typeof("int(*)()"),
	FuncRIntAInt		= ffi.typeof("int(*)(int)"),
	FuncRConstCharAPtr	= ffi.typeof("const char*(*)(void*)"),
}

-- converts a pointer type to its (signed) address as a lua number
function BinUtil.toAddress(ptr)
	return tonumber(ffi.cast(BinUtil.IntPtrT, ptr))
end
BinUtil.ptrToInt = BinUtil.toAddress

-- converts a numeric address to a void pointer
function BinUtil.addrToPtr(addr)
	return ffi.cast(BinUtil.VoidPtr, addr)
end

-- turns a 4-character file signature string into a uint32_t
function BinUtil.toFileSignature(str)
	return ffi.cast(BinUtil.UintPtr, str)[0]
end

-- checks if an arbitrary struct (ref&, not ptr*) has a field of the given name
function BinUtil.hasField(struct, fieldName)
	return ffi.offsetof(struct, fieldName) ~= nil
end

-- does (stack-limited) quicksort over a binary array of an arbitrary (supplied) type
function BinUtil.sortArray(array, numElements, compFunc, cType)
	local temp = cType()
	local size = ffi.sizeof(cType)

	local function swap(a, b)
		if a == b then return end -- same address
		ffi.copy(temp, array[a], size) -- can't do copy-assignment because it would overwrite temp variable-wise
		array[a] = array[b]
		array[b] = temp
	end

	local function partition(low, high)
		local pivotIndex = math.floor((low + high) / 2) -- random may be better than middle

		swap(pivotIndex, high)

		local mem = low
		for i = low, high - 1 do
			if compFunc(array[i], array[high]) then
				swap(mem, i)
				mem = mem + 1
			end
		end

		swap(mem, high)
		return mem
	end

	local function quicksort(low, high)
		if low < high then
			local p = partition(low, high)
			quicksort(low, p - 1)
			quicksort(p + 1, high)
		end
	end

	quicksort(0, numElements - 1)
end

function BinUtil.fileRaw(file)
	local n = file:seek("end")
	file:seek("set")
	local data = BinUtil.ByteArray(n)
	C.fread(data, 1, n, file)
	file:close()
	return data, n
end

function BinUtil.openRaw(path)
	local file = assert(io.open(path, "rb"))
	return BinUtil.fileRaw(file)
end

return BinUtil
