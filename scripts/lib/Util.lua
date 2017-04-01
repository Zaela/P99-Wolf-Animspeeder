
local lfs = require "lfs"

local iup		= iup
local tonumber	= tonumber

local Util = {}

local function fileDlg(a)
	local dlg = iup.filedlg{
		title		= a.title or "?",
		dialogtype	= a.type or "FILE",
		directory	= a.startingDir or lfs.currentdir(),
		extfilter	= a.filter,
	}

	iup.Popup(dlg)
	local status	= dlg.status
	local path		= dlg.value
	iup.Destroy(dlg)
	if status ~= "0" or not path then return end

	return path
end

function Util.getDirectory(a)
	return fileDlg{
		title		= a.title,
		type		= "DIR",
		startingDir = a.startingDir,
	}
end

function Util.getFile(a)
	return fileDlg{
		title		= a.title,
		type		= "FILE",
		startingDir	= a.startingDir,
		filter		= a.filter,
	}
end

function Util.textFieldDialog(a)
	local ret, dlg

	local input = iup.text{
		visibilecolumns = 10,
		mask			= a.mask,
		nc				= a.chars,
	}

	local label = iup.label{title = a.prompt}

	local ok		= iup.button{title = "OK", size = "40x15"}
	local cancel	= iup.button{title = "Cancel", size = "40x15"}

	function cancel:action()
		dlg:hide()
	end

	function ok:action()
		ret = input.value
		dlg:hide()
	end

	dlg = iup.dialog{
		iup.vbox{
			label,
			input,
			iup.hbox{
				ok,
				cancel,
				gap = 10,
				alignment = "ACENTER",
			},
			gap = 10,
			alignment = "ACENTER",
			nmargin = "10x10",
		},
	}

	function dlg:k_any(key)
		if key == iup.K_CR then return ok:action() end
	end

	iup.Popup(dlg)
	iup.Destroy(dlg)

	return ret
end

function Util.getCursorPos()
	local x, y = iup.GetGlobal("CURSORPOS"):match("(%d+)x(%d+)")
	return tonumber(x), tonumber(y)
end

function Util.popupMessage(title, text)
	iup.Message(title, text)
end

function Util.fileExists(name)
	local path = Settings.getEQFolder() .. "/" .. name
	local file = io.open(path, "rb")
	if file then
		file:close()
		return true
	end
	return false
end

function Util.copyFile(from, to)
	local path = Settings.getEQFolder() .. "/"
	local file = io.open(path .. from, "rb")
	if not file then error("Could not open file ".. from) end
	local out = assert(io.open(path .. to, "wb+"))
	out:write(file:read("*a"))
	file:close()
	out:close()
end

function Util.nullFunc() end

return Util
