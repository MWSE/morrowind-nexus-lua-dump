local config
local playerSkillLimit = {}

event.register("modConfigReady", function()
    require("classSkillLimit.mcm")
	config  = require("classSkillLimit.config")
end)

local function exercisePreventionCheck(e)
	if not playerSkillLimit[e.skill] then return end
	if tes3.mobilePlayer:getSkillStatistic(e.skill).base >= playerSkillLimit[e.skill] then
		e.progress = 0
	end
end


local function calculateSkillLimit(e)
	local pcClass = tes3.player.object.class
	local pcRace = tes3.player.object.race
	playerSkillLimit = {}
	for name, skill in pairs(tes3.skill) do
		playerSkillLimit[skill] = config.misc
	end
	for _, skill in pairs(pcClass.majorSkills) do
		playerSkillLimit[skill] = config.major
	end
	for _, skill in pairs(pcClass.minorSkills) do
		playerSkillLimit[skill] = config.minor
	end
	for _, skill in pairs(pcRace.skillBonuses) do
		if playerSkillLimit[skill.skill] then
			playerSkillLimit[skill.skill] = playerSkillLimit[skill.skill] + skill.bonus * config.raceCoef
		end
	end
	local spec = pcClass.specialization * 9 
	for skill = spec, spec + 8 do
		playerSkillLimit[skill] = playerSkillLimit[skill] + 5 * config.specialisationCoef
	end
end

local trainer
local trainerSkills = {}
local button


local function onTrainingFinished(e)
	for skillId, value in pairs(trainerSkills) do
		trainer:getSkillStatistic(skillId).base = value
	end
	trainerSkills = {}
	trainer = nil
	button:forwardEvent(e)
end

local function onTraining(e)
	local menu = e.element
	button = menu.name .. "_Okbutton"
	button = menu:findChild(tes3ui.registerID(button))
	button:unregister("mouseClick", onTrainingFinished)
	button:register("mouseClick", onTrainingFinished)
end

local function onCalcTrainingPrice(e)
	if tes3.mobilePlayer:getSkillStatistic(e.skillId).base >= playerSkillLimit[e.skillId] then
		trainer = e.mobile
		trainerSkills[e.skillId] = e.mobile:getSkillStatistic(e.skillId).base
		trainer:getSkillStatistic(e.skillId).base = playerSkillLimit[e.skillId]
		timer.delayOneFrame(onTrainingFinished)
	end
end

local attributeTooltipElements = {
	tes3ui.registerID("MenuStat_misc_layout"),
	tes3ui.registerID("MenuStat_minor_layout"),
	tes3ui.registerID("MenuStat_major_layout")
}


local function onMenuStatSkillTooltip(e)
	-- e.source:forwardEvent(e)
	local skill = e.source:getPropertyInt("MenuStat_message")
	local tooltip = tes3ui.findHelpLayerMenu(tes3ui.registerID("HelpMenu"))
	if not tooltip then
		return
	end

	if tes3.mobilePlayer:getSkillStatistic(skill).base < playerSkillLimit[skill] then


		local main = tooltip:findChild("PartHelpMenu_main")

		for i, block in ipairs(main.children) do
			if i == 4 then
				local maxValue = playerSkillLimit[skill]
				local label = block:createLabel({ text = string.format("Maximum value: %s", maxValue) })
				label.borderBottom = 6
				block:reorderChildren(2, -1, 1)
				if not block.visible then
					for _, child in ipairs(block.children) do
						child.visible = false
					end
					label.visible = true
					block.visible = true
					label.text = string.format("Maximum proficiency at %s", maxValue)
					--block.autoWidth = true
					block.childAlignX = 0.5
					block.widthProportional = 1
					break
				end
			end
		end

	else

		local progressBar = tooltip:findChild(tes3ui.registerID("progressbar"))
		local level = tooltip:findChild(tes3ui.registerID("level"))
		level.text = tes3.findGMST(tes3.gmst.sSkillMaxReached).value
		level.color = tes3ui.getPalette("normal_color")
		progressBar.visible = false
	end
	
end


local function onStatsMenuRefreshed(e)
	local menu = tes3ui.findMenu("MenuStat")
	if menu then
		local scrollPaneChildren = menu:findChild(tes3ui.registerID("PartScrollPane_pane")).children
		for _, element in pairs(scrollPaneChildren) do
			if (table.find(attributeTooltipElements, element.id)) then
				element:registerAfter("help", onMenuStatSkillTooltip)
				local children = element.children
				for _, child in pairs(children) do
					child.consumeMouseEvents = false
				end
			end
		end
	end
end

local function initialized(e)
	if config.modEnabled then
		mwse.log("[Class Skill Limit: Enabled]")
		event.register("exerciseSkill", exercisePreventionCheck)
		event.register("uiRefreshed", calculateSkillLimit)
		event.register("menuEnter", onStatsMenuRefreshed, { priority = -100 } )
		if config.limitTraining then 
			event.register("calcTrainingPrice", onCalcTrainingPrice)
			event.register("uiActivated", onTraining, {filter = "MenuServiceTraining"})
		end
	else
		mwse.log("[Class Skill Limit: Disabled]")
	end
end


event.register("initialized", initialized)