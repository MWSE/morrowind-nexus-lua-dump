local tidyFrameUIID = tes3ui.registerID("MenuStat_pg_tidy_frame")
local birthUIID = tes3ui.registerID("MenuStat_pg_birth")
local factionUIID = tes3ui.registerID("MenuStat_faction_layout")

--- @param element tes3uiElement
--- @param visible boolean
local function SetAboveDividerVisible(element, visible)
	for i, child in ipairs(element.parent.children) do
		if child == element then
			element.parent.children[i - 1].visible = visible
			break
		end
	end
end

local function UpdateFactions()
	local menu = tes3ui.findMenu("MenuStat")
	assert(menu, "[TidyCharsheet] Stat menu not found, can't create factions.")
	local tidy = menu:findChild(tidyFrameUIID)

	local anyFactionsJoined = false
	for i = 1, #tes3.dataHandler.nonDynamicData.factions do
		local f = tes3.dataHandler.nonDynamicData.factions[i]
		if f.playerJoined then
			anyFactionsJoined = true
			break
		end
	end

	if not anyFactionsJoined then return end

	local title = menu:findChild("MenuStat_faction_title")
	tidy:createDivider{id = "MenuStat_divider"}
	local newTitle = tidy:createLabel{id = "MenuStat_faction_title"}
	newTitle.text = title.text
	newTitle.color = tes3ui.getPalette(tes3.palette.headerColor)

	local pane = menu:findChild("MenuStat_scroll_pane")
	local oldTitle = pane:findChild("MenuStat_faction_title")

	for i = 1, #oldTitle.parent.children do
		local e = oldTitle.parent.children[i]
		if e.id == factionUIID then
			local new = tidy:createLabel{id = factionUIID}
			new.borderLeft = 10
			new.text = e.text
			new:register("help", function()
				e:triggerEvent("help")
			end)
		end
	end
end

local function HideFactions()
	local menu = tes3ui.findMenu("MenuStat")
	assert(menu, "[TidyCharsheet] Stat menu not found, can't hide factions.")
	local pane = menu:findChild("MenuStat_scroll_pane")

	local title = pane:findChild("MenuStat_faction_title")
	title.visible = false
	SetAboveDividerVisible(title, false)

	for i = 1, #title.parent.children do
		local e = title.parent.children[i]
		if e.id == factionUIID then
			e.visible = false
		end
	end
end

local function UpdateBirthsign()
	local menu = tes3ui.findMenu("MenuStat")
	assert(menu, "[TidyCharsheet] Stat menu not found, can't create birthsign.")

	local birthBlock = menu:findChild("MenuStat_class_layout").parent:createBlock{id = birthUIID}
	birthBlock.widthProportional = 1
	birthBlock.autoHeight = true
	birthBlock.childAlignX = -1

	local label = menu:findChild("MenuStat_birth_layout")
	local sign = menu:findChild("birth")
	if not sign then return end

	local newLabel = birthBlock:createLabel{text = label.text}
	newLabel.color = label.color
	birthBlock:createLabel{text = sign.text}

	if sign then
		birthBlock:register("help", function()
			sign:triggerEvent("help")
		end)
	end
end

local function HideBirthsign()
	local menu = tes3ui.findMenu("MenuStat")
	assert(menu, "[TidyCharsheet] Stat menu not found, can't hide birthsign.")
	local label = menu:findChild("MenuStat_birth_layout")
	label.visible = false

	local sign = menu:findChild("birth")
	if sign then
		sign.visible = false
	end

	SetAboveDividerVisible(label, false)
end

local function UpdateBountyAndReputation()
	local menu = tes3ui.findMenu("MenuStat")
	assert(menu, "[TidyCharsheet] Stat menu not found, can't create bounty/reputation.")
	local tidy = menu:findChild(tidyFrameUIID)

	--Reputation
	local block = tidy:createBlock{id = "MenuStat_misc_layout"}
	block.autoHeight = true
	block.autoWidth = true
	block.widthProportional = 1

	local label = block:createLabel{id = "MenuStat_reputation_name"}
	---@diagnostic disable-next-line: assign-type-mismatch
	label.text = tes3.findGMST(tes3.gmst.sReputation).value

	label = block:createLabel{id = "MenuStat_reputation_value"}
	label.absolutePosAlignX = 1
	label.text = tostring(tes3.mobilePlayer.object.reputation)

	--Bounty
	block = tidy:createBlock{id = "MenuStat_misc_layout"}
	block.autoHeight = true
	block.autoWidth = true
	block.widthProportional = 1

	label = block:createLabel{id = "MenuStat_Bounty_name"}
---@diagnostic disable-next-line: assign-type-mismatch
	label.text = tes3.findGMST(tes3.gmst.sBounty).value

	label = block:createLabel{id = "MenuStat_Bounty_layout"}
	label.absolutePosAlignX = 1
	label.text = tostring(tes3.mobilePlayer.bounty)
end

local function HideBountyAndReputation()
	local menu = tes3ui.findMenu("MenuStat")
	assert(menu, "[TidyCharsheet] Stat menu not found, can't hide bounty/reputation.")

	local pane = menu:findChild("MenuStat_scroll_pane")
	local rep = pane:findChild("MenuStat_reputation_name")
	local bounty = pane:findChild("MenuStat_Bounty_name")
	rep.parent.visible = false
	bounty.parent.visible = false

	SetAboveDividerVisible(rep.parent, false)
end

local function PrepareUI()
	local menu = tes3ui.findMenu("MenuStat")
	assert(menu, "[TidyCharsheet] Stat menu not found, can't prep UI.")

	local tidy = menu:findChild(tidyFrameUIID)
	if tidy then tidy:destroy() end
	local birth = menu:findChild(birthUIID)
	if birth then birth:destroy() end

	local left = menu:findChild("MenuStat_left_main")
	tidy = left:createThinBorder{id = tidyFrameUIID}
	tidy.autoWidth = true
	tidy.autoHeight = true
	tidy.widthProportional = 1
	tidy.borderAllSides = 4
	tidy.paddingAllSides = 4
	tidy.flowDirection = tes3.flowDirection.topToBottom
end
--[[
--- @param e uiActivatedEventData
local function onMenuStat(e)
	--needs delay, for some reason.
	timer.delayOneFrame(function()
		PrepareUI()
		UpdateBirthsign()
		UpdateBountyAndReputation()
		UpdateFactions()
	end)
end
event.register("uiActivated", onMenuStat, {filter = "MenuStat", priority = 1})
--Priority 1 to make sure we're faster than the notoriously slow Merlord and his Character Backgrounds mod.

--- @param e loadedEventData
local function onLoaded(e)
	tes3.messageBox("fuck the police")
	if not tes3.isCharGenFinished() then return end
	--doesn't need delay
	PrepareUI()
	UpdateBirthsign()
	UpdateBountyAndReputation()
	UpdateFactions()
end
event.register(tes3.event.loaded, onLoaded)
]]
--- @param e uiRefreshedEventData
local function onStatRefresh(e)
	PrepareUI()
	UpdateBirthsign()
	UpdateBountyAndReputation()
	UpdateFactions()

	HideBirthsign()
	HideBountyAndReputation()
	HideFactions()
end
event.register(tes3.event.uiRefreshed, onStatRefresh, {filter = "MenuStat_scroll_pane", priority = 10 } )

--Merlord's Character Backgrounds reordering.
--- @param e uiActivatedEventData
local function UpdateCharacterBackgrounds(e)
	if not e.newlyCreated then return end
	local menu = tes3ui.findMenu("MenuStat")
	assert(menu, "[TidyCharsheet] Stat menu not found, can't prep UI.")

	local mer =  menu:findChild("GUI_MenuStat_CharacterBackground_Stat")
	if mer then
		local birth = menu:findChild(birthUIID)
		mer.parent:reorderChildren(mer, birth, 1)
	end
end
event.register("uiActivated", UpdateCharacterBackgrounds, { filter = "MenuStat", priority = -10})