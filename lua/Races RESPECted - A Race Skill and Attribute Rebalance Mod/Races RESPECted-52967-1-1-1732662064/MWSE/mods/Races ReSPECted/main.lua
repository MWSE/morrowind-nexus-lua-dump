-- MWSE support made by Petethegoat. Races ReSPECted by Qualia.
local versionString = "1.0"
local i18n = mwse.loadTranslations("Races ReSPECted")
local menuID = tes3ui.registerID("pg_rr_argonianInfo")

if mwse.buildDate == nil or mwse.buildDate < 20230528 then
    mwse.log("[Races ReSPECted] Build date of %s does not meet minimum build date of 2023 05 28. Mod not initialized.", mwse.buildDate)
	event.register(tes3.event.modConfigReady, function()
		tes3.messageBox("Races ReSPECted not initialized. Run MWSE-Update.exe.")
	end)
    return
end

--get caius on load, so we aren't doing getReference every frame.
local caius
event.register(tes3.event.loaded, function()
	caius = tes3.getReference("caius cosades")
end)

--let's make an attempt at compatibility for other languages
local raceName
event.register(tes3.event.initialized, function()
	for _, v in ipairs(tes3.dataHandler.nonDynamicData.races) do
		if v.id == i18n("RaceID") then
			raceName = v.name
			break
		end
	end
end)

local skillBonusesF = {
	[tes3.skill.alchemy] = 5,
	[tes3.skill.illusion] = 5,
	[tes3.skill.mysticism] = 5,
}

local skillBonusesM = {
	[tes3.skill.athletics] = 5,
	[tes3.skill.unarmored] = 5,
	[tes3.skill.spear] = 5,
}

--- @param insertIn tes3uiElement
--- @param targetSkill tes3skill
--- @param amount integer
local function createSkillLine(insertIn, targetSkill, amount)
	local block = insertIn:createBlock()
	block.childAlignX = -1
	block.widthProportional = 1.0
	block.autoHeight = true
	block.autoWidth = true
	block:createLabel{text = targetSkill.name}.borderRight = 16
	block:createLabel{text = tostring(amount)}
	block:register(tes3.uiEvent.help, function()
		tes3ui.createTooltipMenu{skill = targetSkill}
	end)
end

local function destroyMenu()
	local menu = tes3ui.findMenu(menuID)
	if menu then
		menu:saveMenuPosition()
		menu:destroy()
	end
end

--- @param show boolean
local function doMenu(show)
	local menu = tes3ui.findMenu(menuID)
	destroyMenu()
	if not show then return end

	menu = tes3ui.createMenu{id = menuID, dragFrame = true, loadable = true}
	--remove title from titlebar
	menu:findChild("PartDragMenu_title").visible = false
	menu:findChild("PartDragMenu_right_title_block").visible = false
	local title = menu:findChild("PartDragMenu_left_title_block")
	title.heightProportional = -1
	title.height = 12
	if not menu:loadMenuPosition() then	--try to load position from ini, use default position otherwise
		menu.absolutePosAlignX = 0.91
		menu.absolutePosAlignY = 0.4
	end
	local height = tonumber(i18n("DescHeight"))
	menu.maxHeight = height
	menu.minHeight = height
	menu.height = height
	menu.maxWidth = 320
	menu.minWidth = 320
	menu.width = 320
	menu:getContentElement().paddingAllSides = 16

	local desc = menu:createLabel{text = i18n("Description")}
	desc.borderBottom = 8
	desc.wrapText = true

	local header = menu:createLabel{text = i18n("HeaderM") .. " " .. tes3.findGMST(tes3.gmst.sBonusSkillTitle).value}
	header.color = tes3ui.getPalette(tes3.palette.headerColor)
	for k, v in pairs(skillBonusesM) do
		createSkillLine(menu, tes3.getSkill(k), v)
	end

	header = menu:createLabel{text = i18n("HeaderF") .. " " .. tes3.findGMST(tes3.gmst.sBonusSkillTitle).value}
	header.color = tes3ui.getPalette(tes3.palette.headerColor)
	header.borderTop = 8
	for k, v in pairs(skillBonusesF) do
		createSkillLine(menu, tes3.getSkill(k), v)
	end

	--Position it, but let's make sure it's draggable nicely too.
	menu:updateLayout()
	menu.absolutePosAlignX = nil
	menu.absolutePosAlignY = nil
	menu:updateLayout()
end

--- @param e uiActivatedEventData
local function onMenuRaceSex(e)
	if not e.newlyCreated then return end

	--register to show/hide the popup
	for _, v in ipairs(e.element:findChild("MenuRaceSex_RaceList"):getContentElement().children) do
		if v.children[1].text == raceName then
			v.children[1]:registerAfter(tes3.uiEvent.mouseClick, function() doMenu(true) end)
			if v.children[1].widget.state == tes3.uiState.active then	--popup if we're already argonian
				doMenu(true)
			end
		else
			v.children[1]:registerAfter(tes3.uiEvent.mouseClick, function() doMenu(false) end)
		end
	end
	--make sure the popup goes away
	e.element:findChild("MenuRaceSex_Okbutton"):registerBefore(tes3.uiEvent.mouseClick, function()
		destroyMenu()
	end)
end
event.register(tes3.event.uiActivated, onMenuRaceSex, { filter = "MenuRaceSex" })

--Cover our bases to make sure the god damn popup goes away
event.register(tes3.event.uiActivated, function() destroyMenu() end, { filter = "MenuStatReview" })
event.register(tes3.event.uiActivated, function() destroyMenu() end, { filter = "MenuClassChoice" })

--Update player skills.
event.register("calcChargenStats", function()
	if tes3.player.baseObject.race.name == raceName then
		local skills = tes3.player.baseObject.female and skillBonusesF or skillBonusesM
		for k, v in pairs(skills) do
			tes3.modStatistic{reference = tes3.player, skill = k, value = v}
		end
	end
end)

local function customWeightHeight(ref, node, weight, height)
    local m = tes3matrix33.new()
    local r = tes3matrix33.new()
    local inv_r = tes3matrix33.new()

    m:toRotationZ(ref.orientation.z)
    r:toIdentity()
    inv_r:toIdentity()

    r.x.x = weight
    r.y.y = weight
    r.z.z = height
    inv_r.x.x = 1 / weight
    inv_r.y.y = 1 / weight
    inv_r.z.z = 1 / height
    
    node.rotation = m*r
    for i = 3,#node.children do
        node.children[i].rotation = inv_r
    end
    
    node:update()
end

--Save Caius.
event.register(tes3.event.simulated, function()
	--probably a better way to check this, but oh well.
	if not caius.sceneNode then return end
	customWeightHeight(caius, caius.sceneNode, 1.25, 1.00)
end)

event.register(tes3.event.modConfigReady, function()
	mwse.log("[Races ReSPECted] " .. versionString .. " loaded successfully.")
end)