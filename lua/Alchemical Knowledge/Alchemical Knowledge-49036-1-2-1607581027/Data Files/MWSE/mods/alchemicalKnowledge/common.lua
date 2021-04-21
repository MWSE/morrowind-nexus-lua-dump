local strings = require("alchemicalKnowledge.strings")
local common = {}

common.filteredEffect = nil

local function setToList(set)
	local list = {}
	for value, _ in pairs(set) do
		table.insert(list, value)
	end
	table.sort(list)
	return list
end

local function isSame(ingred1, ingred2)
	if common.config.sameIngred[ingred1.id] and common.config.sameIngred[ingred1.id][ingred2.id] then
		return true
	elseif common.config.sameIngred[ingred2.id] and common.config.sameIngred[ingred2.id][ingred1.id] then
		return true
	end
	return false
end

local counter = {
	[1] = "one", 
	[2] = "two", 
	[3] = "three", 
	[4] = "four"
}

common.isSelected = function(item)
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuAlchemy"))
	if not menu then 
		return false 
	end
	for i = 1, 4 do
		 local currentIngred = menu:findChild(tes3ui.registerID("MenuAlchemy_ingredient_"..counter[i]))
		 currentIngred = currentIngred:getPropertyObject("MenuAlchemy_object")
		 if currentIngred and isSame(currentIngred, item) then
			return true
		 end
	end
	return false
end

common.getVisibleEffectsCount = function()
    local skill = tes3.mobilePlayer.alchemy.current
    local gmst = tes3.findGMST(tes3.gmst.fWortChanceValue)
    return math.clamp(math.floor(skill / gmst.value), 0, 4)
end

common.getEffectName = function(effect, stat)
    local statName
    if effect.targetsAttributes then
        statName = tes3.findGMST(888 + stat).value
    elseif effect.targetsSkills then
        statName = tes3.findGMST(896 + stat).value
    end

    local effectName = tes3.findGMST(1283 + effect.id).value
    if statName then
        return effectName:match("%S+") .. " " .. statName
    else
        return effectName
    end
end

common.getIngredEffectList = function(inventory)
	local effectSet = {}
	if common.filteredEffect then
		effectSet[common.filteredEffect.id] = true
	end
	local count = common.getVisibleEffectsCount()
	
	-- Iterating over ingreds in the inventory
	
	for _, stack in pairs(inventory) do
		if stack.object.objectType == tes3.objectType.ingredient then
			for i, effect in ipairs(stack.object.effects) do
				if i <= count or (tes3.player.data.alchemyKnowledge[stack.object.id] and tes3.player.data.alchemyKnowledge[stack.object.id][i]) then
					if effect >= 0 then
						effectSet[effect] = true
					end
				end
			end
		end
	end
	
	-- Iterating over ingreds selected in the alchemy menu
	
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuAlchemy"))
	if menu then 
		for i = 1, 4 do
			 local currentIngred = menu:findChild(tes3ui.registerID("MenuAlchemy_ingredient_"..counter[i]))
			 currentIngred = currentIngred:getPropertyObject("MenuAlchemy_object")
			 if currentIngred then
				 for i, effect in ipairs(currentIngred.effects) do
					if i <= count or (tes3.player.data.alchemyKnowledge[currentIngred.id] and tes3.player.data.alchemyKnowledge[currentIngred.id][i]) then
						if effect >= 0 then
							effectSet[effect] = true
						end
					end
				end
			end
		end
	end
	return setToList(effectSet)
end

return common