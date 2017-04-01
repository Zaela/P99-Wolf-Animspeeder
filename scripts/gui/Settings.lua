
local Util = require "Util"

local FILENAME = "settings.txt"

local iup		= iup
local type		= type
local rawget	= rawget
local rawset	= rawset

local Settings = {
	pathFunc	= Util.nullFunc,
	values		= {},
}

_G.Settings = Settings

local function tolower(k)
	if type(k) == "string" then
		return k:lower()
	end
	return k
end

local mt = {
	__index = function(t, k)
		return rawget(t, tolower(k))
	end,

	__newindex = function(t, k, v)
		rawset(t, tolower(k), v)
	end,
}

setmetatable(Settings.values, mt)

function Settings:init(pathFunc)
	self.pathFunc = pathFunc
	self.init = nil
end

function Settings.setEQFolder()
	local self = Settings
	local path = Util.getDirectory{title = "Select EQ Folder"}
	if not path then return end

	self:set("EQFolder", path)
	self.pathFunc(path)
	return path
end

function Settings.getEQFolder()
	local self = Settings
	local path = self:get("EQFolder")
	if path then return path end

	return self.setEQFolder()
end

function Settings:get(key)
	return self.values[key]
end

function Settings:set(key, value, save)
	self.values[key] = value
	if save or save == nil then self:save() end
end

function Settings:save()
	local file = assert(io.open(FILENAME, "w+"))
	file:write[[
-----------------------------------
-- P99 Wolf Animspeeder Settings --
-----------------------------------

]]

	for k, v in pairs(self.values) do
		local t = type(v)
		if t == "string" then
			v = '"' .. (v:gsub("\\", "\\\\")) .. '"'
		end
		file:write(k, " = ", v, "\n")
	end
end

function Settings:load()
	local f = loadfile(FILENAME)
	if not f then
		return self.setEQFolder()
	end

	setfenv(f, self.values)
	pcall(f)

	local path = self:get("EQFolder")
	if not path then return end

	self.pathFunc(path)
	self.load = nil
end

return Settings
