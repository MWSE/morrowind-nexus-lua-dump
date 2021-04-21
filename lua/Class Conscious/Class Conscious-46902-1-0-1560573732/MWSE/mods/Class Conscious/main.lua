local function onMenuClassChoice(e)
	e.element:findChild(tes3ui.registerID("MenuClassChoice_CreateClassbutton")).visible = false
end
event.register("uiActivated", onMenuClassChoice, {filter = "MenuClassChoice"})