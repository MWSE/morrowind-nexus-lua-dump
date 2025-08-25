-- Interoperability for: https://www.nexusmods.com/morrowind/mods/48458

local interop = include("mer.RightClickMenuExit")

if not interop then return end

local ui = require("Place Stacks.ui")

interop.registerMenu({
	menuId = ui.id.menuName,
	buttonId = ui.id.closeButtonName,
})
