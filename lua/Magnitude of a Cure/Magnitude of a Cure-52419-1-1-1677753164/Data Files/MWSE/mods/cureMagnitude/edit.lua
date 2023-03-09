local common = require("cureMagnitude.common")
local iterop = require("cureMagnitude.interop")

local edit = {}
local effectsTable = {}


edit.onMenuAlchemy = function(e)

    local originalCost = {}

	for name, effect in pairs(effectsTable) do
        originalCost[name] = effect.baseMagickaCost
        if name == "cureCommon" then
		    effect.baseMagickaCost = 0.5
        elseif name == "cureBlight" then
            effect.baseMagickaCost = 1.2
        else
            effect.baseMagickaCost = 0.25
        end
	end
    local dispel = tes3.getMagicEffect(tes3.effect.dispel)
    dispel.baseMagickaCost = 0.6
    originalCost["dispel"] = dispel.baseMagickaCost

    timer.delayOneFrame(function()
        for name, effect in pairs(effectsTable) do
            effect.baseMagickaCost = originalCost[name]
        end
        dispel.baseMagickaCost = originalCost["dispel"]
    end)
end

edit.effectLabel = function(effectLabel)
    for effect, name in pairs(common.cureEffects) do
        if string.startswith(effectLabel.text, name) then
            effectLabel.text = string.gsub(effectLabel.text, " pts* ", "%% ")
            break
        end
    end
end

edit.effects = function()
    if common.config.scaleCureCommon then
	    effectsTable["cureCommon"] = tes3.getMagicEffect(tes3.effect.cureCommonDisease)
    end
    if common.config.scaleCureBlight then
	    effectsTable["cureBlight"] = tes3.getMagicEffect(tes3.effect.cureBlightDisease)
    end
    if common.config.scaleCurePoison then
	    effectsTable["curePoison"] = tes3.getMagicEffect(tes3.effect.curePoison)
    end
    if common.config.scaleCureParalyzation then
	    effectsTable["cureParalyzation"] = tes3.getMagicEffect(tes3.effect.cureParalyzation)
    end
	-- local dispel = tes3.getMagicEffect(tes3.effect.dispel)
	for name, effect in pairs(effectsTable) do
		effect.appliesOnce = true
		effect.hasNoMagnitude = false
		effect.baseMagickaCost = effect.baseMagickaCost/100
	end
end

local function getMagnitude(objectId, objectType, effectId)
    if iterop.uniqueMagnitude[effectId][objectId] then
        return iterop.uniqueMagnitude[effectId][objectId]
    else
        return common.config.defaultMagnitude[tostring(effectId)][tostring(objectType)]
    end
end

edit.objects = function()
	local objectTypes = {
		[1] = 1212369985, --tes3.objectType.alchemy
		[2] = 1212370501, --tes3.objectType.enchantment
		[3] = 1279610963, --tes3.objectType.spell
	}

	for _, objectType in ipairs(objectTypes) do
		for obj in tes3.iterateObjects(objectType) do
			for i, effect in ipairs(obj.effects) do
				if common.cureEffects[effect.id] then
                    local magnitude = getMagnitude(obj.id, objectType, effect.id)
					obj.effects[i].min = magnitude
                    obj.effects[i].max = magnitude
				end
			end
		end
	end
end

return edit