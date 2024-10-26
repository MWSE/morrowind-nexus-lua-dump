local interop = include("mer.RightClickMenuExit")

if not interop then return end

local uiid = require("Command Menu.ui.uiid")


interop.registerMenu({
	menuId = uiid.menu,
	buttonId = uiid.doneButton,
})
