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
			mwse.log("%s, %s", tes3.mobilePlayer.attributes[i].base, playerAttributeLimit[attribute])
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

local function onInitialized(e)
	if common.config.modEnabled then
		mwse.log(string.format("[%s]: enabled", common.dictionary.modName))
		event.register("levelUp", onLevelUpEnd)
		event.register("uiActivated", onMenuLevelUp, {filter = "MenuLevelUp"})
		event.register("uiRefreshed", calculateAttributeLimit)
	else
		mwse.log(string.format("[%s]: disabled", common.dictionary.modName))
	end
end

event.register("initialized", onInitialized)