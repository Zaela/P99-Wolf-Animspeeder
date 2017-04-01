
package.path  = "scripts/lib/?.lua;scripts/gui/?.lua"
package.cpath = "scripts/dll/?.dll"

local MainWindow	= require "MainWindow"
local Menu			= require "Menu"
local Spacer		= require "Spacer"
local Settings		= require "Settings"
local Field			= require "Field"

local menu = Menu.new()
-----------------------
local sub = menu:addSubMenu("&File")
sub:addItem("Set EQ Folder", Settings.setEQFolder)
sub:addSeparator()
sub:addItem("&Quit", function() return iup.CLOSE end)
-----------------------

Settings:init(Field.init)

MainWindow:init{
	iup.vbox{
		Field:getBox(),
		Spacer.vertical(15),
		Field:button(),
		--------------------
		nmargin = "30x30",
		alignment = "ACENTER",
	},
	menu	= menu:getIupMenu(),
	title	= "P99 Wolf Animspeeder v0.1",
	---------------------
	onLoad = function()
		Settings:load()
	end,
}
