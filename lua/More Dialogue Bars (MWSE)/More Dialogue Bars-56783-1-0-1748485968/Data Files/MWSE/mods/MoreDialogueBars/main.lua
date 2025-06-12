local npcRef

local function updateDialogFillBars()
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
	if not menu then return end
	local disposition = menu:findChild(tes3ui.registerID("MenuDialog_disposition"))
	local parent = disposition.parent
	disposition.visible = false

	-- Show Disposition
	disposition = menu:findChild(tes3ui.registerID("MenuDialog_disposition2"))
	if disposition then
		disposition:destroy()
	end
	disposition = parent:createFillBar{id = tes3ui.registerID("MenuDialog_disposition2"), current = npcRef.object.disposition, max = 100, showText = true}
	disposition.width = 192
	disposition.height = 19
	disposition.borderAllSides = 4
	disposition:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = "Disposition: " .. disposition:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text
	disposition.widget.fillColor = tes3ui.getPalette("magic_color")
	disposition.visible = true

	-- Show Hello
	local hello = menu:findChild(tes3ui.registerID("MenuDialog_hello"))
	if hello then
		hello:destroy()
	end
	hello = parent:createFillBar{id = tes3ui.registerID("MenuDialog_hello"), current = npcRef.mobile.hello, max = 100}
	hello.width = 192
	hello.height = 19
	hello.borderLeft = 4
	hello.borderBottom = 4
	hello:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = "Hello: " .. hello:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text
	hello.widget.fillColor = tes3ui.getPalette("magic_color")
	hello.visible = true

	-- Show Fight
	local fight = menu:findChild(tes3ui.registerID("MenuDialog_fight"))
	if fight then
		fight:destroy()
	end
	fight = parent:createFillBar{id = tes3ui.registerID("MenuDialog_fight"), current = npcRef.mobile.fight, max = 100}
	fight.width = 192
	fight.height = 19
	fight.borderLeft = 4
	fight.borderBottom = 4
	fight:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = "Fight: " .. fight:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text
	fight.widget.fillColor = tes3ui.getPalette("magic_color")
	fight.visible = true

	-- Show Flee
	local flee = menu:findChild(tes3ui.registerID("MenuDialog_flee"))
	if flee then
		flee:destroy()
	end
	flee = parent:createFillBar{id = tes3ui.registerID("MenuDialog_flee"), current = npcRef.mobile.flee, max = 100}
	flee.width = 192
	flee.height = 19
	flee.borderLeft = 4
	flee.borderBottom = 4
	flee:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = "Flee: " .. flee:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text
	flee.widget.fillColor = tes3ui.getPalette("magic_color")
	flee.visible = true

	-- Show Alarm
	local alarm = menu:findChild(tes3ui.registerID("MenuDialog_alarm"))
	if alarm then
		alarm:destroy()
	end
	alarm = parent:createFillBar{id = tes3ui.registerID("MenuDialog_alarm"), current = npcRef.mobile.alarm, max = 100}
	alarm.width = 192
	alarm.height = 19
	alarm:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = "Alarm: " .. alarm:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text
	alarm.widget.fillColor = tes3ui.getPalette("magic_color")
	alarm.borderBottom = 4
	alarm.borderLeft = 4
	alarm.visible = true

	-- Order
	parent:reorderChildren(1, -5, 5)
	local topics = menu:findChild(tes3ui.registerID("MenuDialog_topics_pane"))
	topics.minWidth = 192
	topics.maxWidth = 192
	topics.autoWidth = true
	menu:updateLayout()

	-- Preventing text from being eaten
	local border = menu:findChild("PartDragMenu_top_left_grow")
	border:triggerEvent("mouseClick")
end

local function onMenuDialog(e)
	npcRef = e.element:getPropertyObject("PartHyperText_actor").reference
	if npcRef.object.objectType ~= tes3.objectType.npc then
		npcRef = nil
		return
	end
	updateDialogFillBars()
	timer.start{
		duration = 0.01,
		type = timer.real,
		callback = function()
			updateDialogFillBars()
		end
	}
end

local function onDialog(e)
	updateDialogFillBars()
	timer.start{
		duration = 0.01,
		type = timer.real,
		callback = function()
			updateDialogFillBars()
		end
	}
end

local function onBarterEnd(e)
	updateDialogFillBars()
	timer.start{
		duration = 0.01,
		type = timer.real,
		callback = function()
			updateDialogFillBars()
		end
	}
end

local function initialized(e)
	mwse.log("More Dialogue Bars: ON")
	event.register("infoGetText", onDialog)
	event.register("uiActivated", onMenuDialog, {filter = "MenuDialog"})
end

event.register("initialized", initialized)