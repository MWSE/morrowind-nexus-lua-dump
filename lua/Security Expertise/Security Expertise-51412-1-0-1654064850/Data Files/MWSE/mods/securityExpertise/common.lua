local common = {}

common.loadTranslation = function ()
	-- Get the ISO language code.
	local language = tes3.getLanguage()

	-- Load the dictionaries, and start off with English.
	local dictionaries = dofile("securityExpertise.translations")
	local dictionary = dictionaries[language]

	-- If we aren't doing English, copy over missing entries.
	if (language ~= "eng") then
		table.copymissing(dictionary, dictionaries["eng"])
	end

	-- Set the dictionary.
	common.dictionary = dictionary
end

local function getEffectName(effect, stat)
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

common.safeDelete = function(reference)
    tes3.positionCell{
        reference = reference, 
        position = { 0, 0, 10000, },
    }
    reference:disable()
    timer.delayOneFrame(function()
        mwscript.setDelete{reference = reference}
    end)
end

common.getEffectText = function(effect)
	local text = getEffectName(effect.object, math.max(effect.attribute, effect.skill))
	if not effect.object.hasNoMagnitude then
		if effect.min == effect.max then
			text = text..string.format(common.dictionary.magnitudeEqual, effect.min)
		else
			text = text..string.format(common.dictionary.magnitudeMinMax, effect.min, effect.max)
		end
	end
	if not effect.object.hasNoDuration then
		text = text..string.format(common.dictionary.duration, effect.duration)
	end
	return text..common.dictionary.onSelf
end

common.getTrapFromSource = function(source)
	local trap = tes3.getObject("t"..source.id) or tes3.createObject{objectType = tes3.objectType.spell, id = "t"..source.id, name = "Trap"}
	local j = 1
	local effects = source.effects or ( source.enchantment and source.enchantment.effects )
	for i, effect in ipairs(effects) do
		if effect.id ~= tes3.effect.lock and effect.id ~= tes3.effect.open then
			local trapEffect = effect
			trapEffect.rangeType = tes3.effectRange.touch
			trapEffect.radius = 0
			trap.effects[j] = trapEffect
			j = j + 1
		end
	end
	return trap
end


common.createObjects = function()
	local merchantContainer = tes3.createObject{
		objectType = tes3.objectType.container, 
		id = "se_merchant_container", 
		mesh = [[EditorMarker.nif]],
		-- organic = false,
		-- respawns = true,
		capacity = 100
	} --[[EditorMarker.nif]]
	local trapPanelCont = tes3.createObject{objectType = tes3.objectType.container, id = "se_trap_panel_cont", name = common.dictionary.trapPanel, mesh = [[SecExp\trap_panel.nif]]}
	local trapPanelMisc = tes3.createObject{
		objectType = tes3.objectType.miscItem, 
		id = "se_trap_panel_misc", 
		name = common.dictionary.trapPanel, 
		mesh = [[SecExp\trap_panel.nif]], 
		icon = [[SecExp\trap_panel.dds]],
		value = 100,
		weight = 5
	}
	merchantContainer.inventory:addItem{item = trapPanelMisc, count = -1}
	
end

common.addTrapsStock =  function(merchantRef)
	merchantRef.data.trapsStockAdded = true
    local container = tes3.createReference{
        object = "se_merchant_container",
        position = merchantRef.position:copy(),
        orientation = merchantRef.orientation:copy(),
        cell = merchantRef.cell
    }
    tes3.setOwner{ reference = container, owner = merchantRef}
	local ai = merchantRef.object.aiConfig
	ai.bartersMiscItems = true
end

return common