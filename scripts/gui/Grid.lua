
local iup			= iup
local type			= type
local setmetatable	= setmetatable

local Grid = {}
Grid.__index = Grid

function Grid.new(a)
	local grid = {
		box = iup.gridbox{
			numdiv			= a.span or 2,
			gapcol			= a.columnGap or 10,
			gaplin			= a.lineGap or 8,
			orientation		= "HORIZONTAL",
			homogeneouslin	= "YES",
			alignmentlin	= "ACENTER",
			sizelin			= 0,
		},
	}

	return setmetatable(grid, Grid)
end

function Grid:add(elem)
	if type(elem) == "string" then
		elem = iup.label{title = elem}
	end
	iup.Append(self.box, elem)
end

function Grid:setLongestLine(n)
	self.box.sizelin = n - 1
end

function Grid:getBox()
	return self.box
end

return Grid
