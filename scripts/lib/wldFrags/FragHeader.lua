
local ffi = require "ffi"

ffi.cdef[[
typedef struct WLDFragHeader {
	uint32_t	len;
	uint32_t	type;
	int			nameref;
} WLDFragHeader;

typedef struct WLDFragHeaderWrapper {
	WLDFragHeader	header;
} WLDFragHeaderWrapper;
]]

local setmetatable = setmetatable

local FragHeader = {
	Ptr = ffi.typeof("WLDFragHeaderWrapper*"),
}
FragHeader.__index = FragHeader

function FragHeader:getLen()
	-- nameref is not considered part of the header for size, but it's *always* there
	return 8 + self.header.len
end

function FragHeader:getType()
	return self.header.type
end

function FragHeader:getNameRef()
	return self.header.nameref
end

function FragHeader:setNameRef(ref)
	self.header.nameref = ref
end

function FragHeader:fixRefs(refMap)
	if ffi.offsetof(self[0], "ref") then
		self.ref = refMap:get(self.ref)
	end
end

-- to reduce boilerplate for derived frag types
function FragHeader.derivedType(name)
	local fragType = {
		Ptr		= ffi.typeof(name .. "*"),
		Type	= ffi.typeof(name),
	}
	fragType.__index = fragType
	setmetatable(fragType, FragHeader)
	return fragType
end

function FragHeader.plainType(name)
	local fragType = FragHeader.derivedType(name)
	ffi.metatype(name, fragType)
	return fragType
end

ffi.metatype("WLDFragHeaderWrapper", FragHeader)

return FragHeader
