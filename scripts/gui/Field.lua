
local Grid	= require "Grid"
local S3D	= require "S3D"
local WLD	= require "WLD"
local Util	= require "Util"
local iup	= iup

local field = iup.text{mask = iup.MASK_UINT}

local grid = Grid.new{}
grid:add("Milliseconds between keyframes:")
grid:add(field)

local initErr = function() error("Could not find necessary EQ files") end

local TARGET_S3D = "growthplane_chr.s3d"
local TARGET_WLD = "growthplane_chr.wld"
local BACKUP_S3D = "growthplane_chr.zae"

local function apply()
	local milliseconds = tonumber(field.value)

	if not milliseconds or milliseconds == 0 then
		error("Invalid input value!")
	end

	if not Util.fileExists(TARGET_S3D) then initErr() end

	-- make sure we have a backup
	if not Util.fileExists(BACKUP_S3D) then
		Util.copyFile(TARGET_S3D, BACKUP_S3D)
	end

	local s3d = S3D.open(TARGET_S3D)
	if not s3d then initErr() end

	local data, len = s3d:getEntryByName(TARGET_WLD)
	if not data then initErr() end

	local wld = WLD.open(data, len)

	for i, f13 in wld:getFragsByType(0x13) do
		local name = wld:getFragName(f13)
		if name:find("^L02WOL") and f13:getLen() == 24 then
			f13.param = milliseconds
		end
	end

	s3d:saveWLD(wld, TARGET_WLD)

	Util.popupMessage("Done", "Milliseconds between keyframes changed to " .. milliseconds .."!")
end

local button = iup.button{title = "Apply", action = apply, padding = "24x6"}

local Field = {}

function Field.init()
	local s3d = S3D.open(TARGET_S3D)
	if not s3d then initErr() end

	local data, len = s3d:getEntryByName(TARGET_WLD)
	if not data then initErr() end

	local wld = WLD.open(data, len)

	for i, f13 in wld:getFragsByType(0x13) do
		local name = wld:getFragName(f13)
		if name:find("^L02WOL") and f13:getLen() == 24 then
			field.value = tostring(f13.param)
			break
		end
	end
end

function Field:getBox()
	return grid:getBox()
end

function Field:button()
	return button
end

return Field
