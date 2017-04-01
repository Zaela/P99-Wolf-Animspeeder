
local Util = require "Util"

local iup 			= iup
local setmetatable	= setmetatable

local Menu = {}
Menu.__index = Menu

function Menu.new()
	return setmetatable({menu = iup.menu{}}, Menu)
end

function Menu:addSubMenu(title)
	local add = Menu.new()

	iup.Append(self.menu, iup.submenu{
		title = title,
		add.menu,
	})

	return add
end

function Menu:addItem(name, func, enabled)
	if enabled == nil then enabled = true end

	iup.Append(self.menu, iup.item{
		title	= name,
		action	= func,
		active	= enabled and "YES" or "NO",
	})
end

function Menu:addSeparator()
	iup.Append(self.menu, iup.separator{})
end

function Menu:popup(x, y)
	if not x then
		x, y = Util.getCursorPos()
	end
	iup.Popup(self.menu, x, y)
	iup.Destroy(self.menu)
end

function Menu:getIupMenu()
	return self.menu
end

return Menu
