local common = require("UI Expansion.common")

local GUI_ID_MenuContents = tes3ui.registerID("MenuContents")

local function menuQuantity(e)
	-- Enable keyboard support for the scroll bar.
	local scrollBar = e.element:findChild(tes3ui.registerID("MenuQuantity_scrollbar"))
	local submitButton = e.element:findChild(tes3ui.registerID("MenuQuantity_buttonok"))
	common.bindScrollBarToKeyboard({
		element = scrollBar,
		onSubmit = function()
			submitButton:triggerEvent("mouseClick")
		end
	})

	-- Register event so that when mouseClick happens on ok button an update event is
	-- sent to the contents menu.
	local contentsMenu = tes3ui.findMenu(GUI_ID_MenuContents)
	submitButton:register("mouseClick",
		function(e2)
			e2.source:forwardEvent(e2)
			contentsMenu:triggerEvent("update")
		end)
end
event.register("uiActivated", menuQuantity, { filter = "MenuQuantity"})
