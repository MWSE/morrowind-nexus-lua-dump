local common = {}

common.filteredEffect = nil
common.selectedEffects = {
	-- slotName = {
	-- 	effectId = {
	-- 		attribute = true
	-- 	}
	-- }
}

local function loadTranslation()
	-- Get the ISO language code.
	local language = tes3.getLanguage()

	-- Load the dictionaries, and start off with English.
	local dictionaries = dofile("alchemyArt.translations")
	local dictionary = dictionaries[language]

	-- If we aren't doing English, copy over missing entries.
	if (language ~= "eng") then
		table.copymissing(dictionary, dictionaries["eng"])
	end
	-- Set the dictionary.
	return dictionary
end

common.dictionary = loadTranslation()

common.setToList = function(set)
	local list = {}
	for value, _ in pairs(set) do
		table.insert(list, value)
	end
	table.sort(list)
	return list
end

common.getPotionEffectList = function (inventory)
	local effectSet = {}
	if common.filteredEffect then
		effectSet[common.filteredEffect.id] = true
	end
	--local count = 8 --common.getVisibleEffectsCount()
	
	-- Iterating over potions in the inventory
	
	for _, stack in pairs(inventory) do
		if stack.object.objectType == tes3.objectType.alchemy then
			for i, effect in ipairs(stack.object.effects) do
				--if i <= count or (tes3.player.data.alchemyKnowledge[stack.object.id] and tes3.player.data.alchemyKnowledge[stack.object.id][i]) then
				if effect.id >= 0 then
					effectSet[effect.id] = true
				end
				--end
			end
		end
	end
	
	-- Iterating over potions selected in the alchemy menu
	
	-- local menu = tes3ui.findMenu(tes3ui.registerID("MenuAlchemy"))
	-- if menu then 
	-- 	for i = 1, 4 do
	-- 		 local currentIngred = menu:findChild(tes3ui.registerID("MenuAlchemy_ingredient_"..counter[i]))
	-- 		 currentIngred = currentIngred:getPropertyObject("MenuAlchemy_object")
	-- 		 if currentIngred then
	-- 			 for i, effect in ipairs(currentIngred.effects) do
	-- 				if i <= count or (tes3.player.data.alchemyKnowledge[currentIngred.id] and tes3.player.data.alchemyKnowledge[currentIngred.id][i]) then
	-- 					if effect >= 0 then
	-- 						effectSet[effect] = true
	-- 					end
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end
	return common.setToList(effectSet)
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

common.getEffectText = function(effect)
    local magicEffect = tes3.getMagicEffect(effect.id)
	local text = common.getEffectName(magicEffect, math.max(effect.attribute, effect.skill))
	if not magicEffect.hasNoMagnitude then
        if effect.magnitude then
            text = text..string.format(common.dictionary.magnitudeEqual, effect.magnitude)
		elseif effect.min == effect.max then
			text = text..string.format(common.dictionary.magnitudeEqual, effect.min)
		else
			text = text..string.format(common.dictionary.magnitudeMinMax, effect.min, effect.max)
		end
	end
	if not magicEffect.hasNoDuration and effect.duration ~= 0 then
		text = text..string.format(common.dictionary.duration, effect.duration)
	end
	return text..common.dictionary.onSelf
end

common.practiceAlchemy = function(value)
	local multiplier = {
		[1] = 0.33,
		[2] = 0.5,
		[3] = 0.75,
		[4] = 1,
		[5] = 1.5,
		[6] = 2,
		[7] = 3
	}
	local experienceGained = common.config.alchemyTime * multiplier[common.config.experienceGain] * value
	tes3.mobilePlayer:exerciseSkill(tes3.skill.alchemy, experienceGained)
end

common.init = function ()
	common.magicSchoolName = {
		[0] = tes3.findGMST(tes3.gmst.sSchoolAlteration).value,
		[1] = tes3.findGMST(tes3.gmst.sSchoolConjuration).value,
		[2] = tes3.findGMST(tes3.gmst.sSchoolDestruction).value,
		[3] = tes3.findGMST(tes3.gmst.sSchoolIllusion).value,
		[4] = tes3.findGMST(tes3.gmst.sSchoolMysticism).value,
		[5] = tes3.findGMST(tes3.gmst.sSchoolRestoration).value,
	}
end


return common