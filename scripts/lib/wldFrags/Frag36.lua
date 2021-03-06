
local ffi			= require "ffi"
local FragHeader	= require "wldFrags/FragHeader"

ffi.cdef[[
#pragma pack(1)

typedef struct WLDFrag36 {
	WLDFragHeader	header;
	uint32_t		flag;				// many values seen, seems like 3 means it has particles, else 81923 or 16387
	int				materialListRef;	// reference to 0x31 fragment which goes on to list all materials/textures
	int				animVertRef;		// always 0
	int				unknownA[2];		// [0] = 0, [1] usually = 0 but sometimes -2
	float			x, y, z;			// position offsets... 0, 0, 0 is fine (seen on fist gems)
	float			rotation[3];		// 0, 0, 0
	float			maxDist;			// effectively meaningless, as are the following
	float			minX;
	float			minY;
	float			minZ;
	float			maxX;
	float			maxY;
	float			maxZ;
	uint16_t		vertCount;			// number of vertices
	uint16_t		uvCount;			// number of texture coordinates, = num vertices or 0
	uint16_t		normalCount;		// number of vertex normals, = num vertices
	uint16_t		colorCount;			// always 0
	uint16_t		polyCount;			// number of triangles
	uint16_t		boneAssignCount;	// usually 0, non-zero if flag = 3
	uint16_t		polyTextureCount;	// number of TextureEntries
	uint16_t		vertTextureCount;	// = poly_texture_count, also uses TextureEntries, per vert instead of tri, not sure of the point of that
	uint16_t		size9;				// always 0
	uint16_t		scale;
} WLDFrag36;

#pragma pack()
]]

local Frag36 = FragHeader.derivedType("WLDFrag36")

Frag36.Type = ffi.typeof("WLDFrag36")

function Frag36:fixRefs(refMap)
	self.materialListRef = refMap:get(self.materialListRef)
	self.animVertRef = refMap:get(self.animVertRef)
end

ffi.metatype("WLDFrag36", Frag36)

return Frag36
