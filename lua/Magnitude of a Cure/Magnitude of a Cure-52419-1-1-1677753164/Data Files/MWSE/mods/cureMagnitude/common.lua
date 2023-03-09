local common = {}

local function loadTranslation()
	-- Get the ISO language code.
	local language = tes3.getLanguage()

	-- Load the dictionaries, and start off with English.
	local dictionaries = dofile("cureMagnitude.translations")
	local dictionary = dictionaries[language]

	-- If we aren't doing English, copy over missing entries.
	if (language ~= "eng") then
		table.copymissing(dictionary, dictionaries["eng"])
	end
	-- Set the dictionary.
	return dictionary
end

common.dictionary = loadTranslation()

common.cureEffects = {}

common.init = function()
	if common.config.scaleCureCommon then
	    common.cureEffects[tes3.effect.cureCommonDisease] = tes3.findGMST('sEffectCureCommonDisease').value
    end
    if common.config.scaleCureBlight then
	    common.cureEffects[tes3.effect.cureBlightDisease] = tes3.findGMST('sEffectCureBlightDisease').value
    end
    if common.config.scaleCurePoison then
	    common.cureEffects[tes3.effect.curePoison] = tes3.findGMST('sEffectCurePoison').value
    end
    if common.config.scaleCureParalyzation then
	    common.cureEffects[tes3.effect.cureParalyzation] = tes3.findGMST('sEffectCureParalyzation').value
    end
end

common.getMagnitudeFromSource = function(source, effectId)
	for _, effect in ipairs(source.effects) do
		if effect.id == effectId then
			local magnitude = math.random(effect.min, effect.max)
			return magnitude
		end
	end
end


return common