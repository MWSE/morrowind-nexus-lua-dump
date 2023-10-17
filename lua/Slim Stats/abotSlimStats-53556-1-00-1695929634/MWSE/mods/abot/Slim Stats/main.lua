local uiidMenuStat_layout = tes3ui.registerID('MenuStat_layout')

local function uiActivated(e)
	if not e.newlyCreated then
		return
	end
	local menu = e.element
	local menuStat_layout = menu:findChild(uiidMenuStat_layout)
	if not menuStat_layout then
		return
	end
	menuStat_layout.minWidth = 300
	---mwse.log('menuStat_layout.minWidth = %s', menuStat_layout.minWidth)
	menuStat_layout.flowDirection = 'top_to_bottom'
	---mwse.log('menuStat_layout.flowDirection = %s', menuStat_layout.flowDirection)
	menu:updateLayout()
end
event.register('uiActivated', uiActivated, { filter = 'MenuStat', priority = -100000})
