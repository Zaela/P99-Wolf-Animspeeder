
local iup = iup

local Spacer = {}

function Spacer.vertical(n)
	return iup.vbox{nmargin = "0x" .. n}
end

function Spacer.horizontal(n)
	return iup.hbox{nmargin = n .. "x0"}
end

return Spacer
