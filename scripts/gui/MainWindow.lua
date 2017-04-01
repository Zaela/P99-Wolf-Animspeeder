
local iup = iup

local MainWindow = {}

function MainWindow:init(data)
	self.data		= assert(iup.dialog(data))
	self.base_title = data.title
	self.edited		= false

	function self.data:k_any(key)
		if key == iup.K_ESC then
			return iup.CLOSE
		end
	end

	self.data:show()
	if data.onLoad then
		data.onLoad()
		data.onLoad = nil
	end
	iup.MainLoop()
end

return MainWindow
