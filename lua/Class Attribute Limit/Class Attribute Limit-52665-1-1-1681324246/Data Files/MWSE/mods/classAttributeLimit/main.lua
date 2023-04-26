local common = require("classAttributeLimit.common")

event.register("modConfigReady", function()
    require("classAttributeLimit.mcm")
	common.config  = require("classAttributeLimit.config")
end)

local playerAttributeLimit = {}
local preLvlUpAttributes = {}

local function calculateAttributeLimit(e)
	local pcClass = tes3.player.object.class
	local pcRace = tes3.player.object.race
	local pcSex = tes3.player.object.female and "female" or "male"
	for name, attribute in pairs(tes3.attribute) do
		playerAttributeLimit[attribute] = pcRace.baseAttributes[attribute+1][pcSex] + common.config.baseRaise
	end
	for _, attribute in pairs(pcClass.attributes) do
		if playerAttributeLimit[attribute] then
			playerAttributeLimit[attribute] = playerAttributeLimit[attribute] + common.config.classCoef * 10
		end
	end
	-- mwse.log(inspect(playerAttributeLimit))
end

local function onLevelUpEnd(e)
	for i, _ in ipairs(tes3.mobilePlayer.attributes) do
		if tes3.mobilePlayer.attributes[i].base > playerAttributeLimit[i-1] then
			if tes3.mobilePlayer.attributes[i].base > preLvlUpAttributes[i] then
				local delta = playerAttributeLimit[i-1] - tes3.mobilePlayer.attributes[i].base
				tes3.modStatistic{reference = tes3.player, attribute = i-1, value = delta}
			end
		end
	end
end

local function limitLevelUpPoints(menu)
	local count = 0
	for name, attribute in pairs(tes3.attribute) do
		if tes3.mobilePlayer.attributes[attribute + 1].base >= playerAttributeLimit[attribute] then
			count = count + 1
		end
	end

	local numberOfPoints = math.min(8 - count, 3)

	if numberOfPoints < 3 then
		menu:findChild("MenuLevelUp_IconThree").visible = false
	end
	if numberOfPoints < 2 then
		menu:findChild("MenuLevelUp_IconTwo").visible = false
	end
	if numberOfPoints < 1 then
		menu:findChild("MenuLevelUp_IconOne").visible = false
	end

end

local function onMenuLevelUp(e)
	local menu = e.element
	local firstAttributes = menu:findChild("MenuLevelUp_FirstAttributes")
	local firstLimit = false
	local secondLimit = false

	limitLevelUpPoints(menu)

	for i, child in ipairs(firstAttributes.children) do
		local attribute = i - 1
		if tes3.mobilePlayer.attributes[i].base >= playerAttributeLimit[attribute] then
			child:findChild("list"):register("mouseClick", function(e) 
			end)
			firstLimit = true
		end
	end

	local secondtAttributes = menu:findChild("MenuLevelUp_SecondAttributes")

	for i, child in ipairs(secondtAttributes.children) do
		local attribute = i + 3
		if tes3.mobilePlayer.attributes[i + 4].base >= playerAttributeLimit[attribute] then
			child:findChild("list2"):register("mouseClick", function(e) 
			end)
			secondLimit = true
		end
	end

	if firstLimit then
		local iconList = menu:findChild("MenuLevelUp_IconList")
		local multipliers
		for i, child in ipairs(iconList.children) do
			if child.id == -1519 then
				multipliers = child
			end
		end
		for i, child in ipairs(multipliers.children) do
			local attribute = i - 1
			if tes3.mobilePlayer.attributes[i].base >= playerAttributeLimit[attribute] then
				local label = child:findChild(-32588)
				if label then
					label.visible = false
				-- else
				-- 	mwse.log("failed to find label")
				end
			end
		end
	end

	if secondLimit then
		local iconList = menu:findChild("MenuLevelUp_IconList")
		local found = false
		local multipliers
		for i, child in ipairs(iconList.children) do
			if child.id == -1525 then
				if found then
					multipliers = child
				else
					found = true
				end
			end
		end
		for i, child in ipairs(multipliers.children) do
			local attribute = i + 3
			if tes3.mobilePlayer.attributes[i + 4].base >= playerAttributeLimit[attribute] then
				local label = child:findChild(-32588)
				if label then
					label.visible = false
				end
			end
		end
	end
	for i, stat in ipairs(tes3.mobilePlayer.attributes) do
		preLvlUpAttributes[i] = stat.base
	end
end

local function OnMenuStatTooltip(source, effectFilter, idProperty, fortifyEffect, statsArray)
	-- Get the associated attribute.
	local attribute = source:getPropertyInt(idProperty)
	-- Create a new tooltip block.
	local tooltip = tes3ui.findHelpLayerMenu("HelpMenu")
	if not tooltip then
		return
	end

	local main = tooltip:findChild("PartHelpMenu_main")

	for i, block in ipairs(main.children) do
		if i == 3 then
			local maxValue = playerAttributeLimit[attribute]
			local label = block:createLabel({ text = string.format(common.dictionary.maxValue, maxValue) })
			label.borderBottom = 6
			block:reorderChildren(2, -1, 1)
			if not block.visible then
				for _, child in ipairs(block.children) do
					child.visible = false
				end
				label.visible = true
				block.visible = true
				break
			end
		end
	end
end

local function onMenuStatAttributeTooltip(e)
	OnMenuStatTooltip(e.source, "targetsAttributes", "MenuStat_attribute_strength", tes3.effect.fortifyAttribute, "attributes")
end

local function onMenuStatActivated(e)
	if (not e.newlyCreated) then
		return
	end
	-- Add tooltips to attributes.
	local idParts = { "agility", "endurance", "intellegence", "luck", "personality", "speed", "strength", "willpower" }
	for _, idPart in pairs(idParts) do
		local MenuStat_attribute_layout = e.element:findChild(string.format("MenuStat_attribute_layout_%s", idPart))
		MenuStat_attribute_layout:registerAfter("help", onMenuStatAttributeTooltip)

		-- Prevent children from using their own events.
		local children = MenuStat_attribute_layout.children
		for _, child in pairs(children) do
			child.consumeMouseEvents = false
		end
	end
end

local function onInitialized(e)
	if common.config.modEnabled then
		mwse.log(string.format("[%s]: enabled", common.dictionary.modName))
		event.register("levelUp", onLevelUpEnd)
		event.register("uiActivated", onMenuLevelUp, {filter = "MenuLevelUp"})
		event.register("uiRefreshed", calculateAttributeLimit)
		event.register("uiActivated", onMenuStatActivated, { filter = "MenuStat", priority = -999 })
	else
		mwse.log(string.format("[%s]: disabled", common.dictionary.modName))
	end
end

event.register("initialized", onInitialized)