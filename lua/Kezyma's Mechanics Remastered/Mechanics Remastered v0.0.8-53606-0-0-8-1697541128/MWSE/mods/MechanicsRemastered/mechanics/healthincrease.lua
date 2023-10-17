local config = require('MechanicsRemastered.config')

-- Health Increase Overhaul

local levelBaseHealth = nil
local levelBaseEndurance = nil

local function fortifyHealthBonus(mobile)
    local bonus = 0
    if (tes3.hasCodePatchFeature(tes3.codePatchFeature.fortifyMaximumHealth)) then
        for _, effect in pairs(mobile:getActiveMagicEffects({effect = tes3.effect.fortifyHealth})) do
            bonus = bonus + effect.effectInstance.effectiveMagnitude
        end
    end
    return bonus
end

local function inferBaseHealth()
    local strength = nil
    local endurance = nil

    -- Racial base attributes
    local str_attr = tes3.mobilePlayer.object.race.baseAttributes[tes3.attribute.strength + 1]
    local end_attr = tes3.mobilePlayer.object.race.baseAttributes[tes3.attribute.endurance + 1]
    if tes3.mobilePlayer.object.female then
        endurance = end_attr.female
        strength = str_attr.female
    else
        endurance = end_attr.male
        strength = str_attr.male
    end

    -- Class base attribute bonus
    local class_attr = tes3.mobilePlayer.object.class.attributes
    if class_attr[1] == tes3.attribute.endurance or class_attr[2] == tes3.attribute.endurance then
        endurance = endurance + 10
    end
    if class_attr[1] == tes3.attribute.strength or class_attr[2] == tes3.attribute.strength then
        strength = strength + 10
    end

    -- Birthsign endurance bonus
    local enduranceBonus = 0.0
    if tes3.mobilePlayer.birthsign then
        for _, spell in pairs(tes3.mobilePlayer.birthsign.spells) do
            if spell.castType == tes3.spellType.ability then
                for i = 1, spell:getActiveEffectCount() do
                    local effect = spell.effects[i]
                    if effect.id == tes3.effect.fortifyAttribute and effect.attribute == tes3.attribute.endurance then
                        bonus = bonus + effect.max
                    end
                end
            end
        end
    end

    -- Initial health calculation
    levelBaseEndurance = endurance + enduranceBonus
    levelBaseHealth = (strength + endurance) / 2
end

local function updatePlayerHealth()
    -- Calculate total health additions if all levels had the current endurance.
    local endMulti = tes3.findGMST(tes3.gmst.fLevelUpHealthEndMult).value
    local maxMulti = tes3.findGMST(tes3.gmst.iLevelUp10Mult).value
    local enduranceDiff = tes3.mobilePlayer.endurance.base - levelBaseEndurance
    local newHealth = levelBaseHealth
    local baseEndurance = levelBaseEndurance
    local currentLevel = tes3.mobilePlayer.object.level
    for _ = 1, currentLevel - 1 do
        if (enduranceDiff >= maxMulti) then
            baseEndurance = baseEndurance + maxMulti
            enduranceDiff = enduranceDiff - maxMulti
        else
            baseEndurance = baseEndurance + enduranceDiff
            enduranceDiff = 0
        end
        newHealth = newHealth + (baseEndurance * endMulti)
    end

    -- Find and include any fortify health effects.
    local fortifyBonus = fortifyHealthBonus(tes3.mobilePlayer)
    newHealth = newHealth + fortifyBonus

    -- Update base and total health to the new values.
    tes3.setStatistic({ reference = tes3.player, name = 'health', base = newHealth })
    local healthChange = newHealth - tes3.mobilePlayer.health.base;
    if (healthChange > 0) then
        tes3.modStatistic({ reference = tes3.player, name = 'health', current = healthChange })
    end
end

--- @param e loadedEventData
local function loadedCallback(e)
    inferBaseHealth()
end

--- @param e levelUpEventData
local function levelUpCallback(e)
    updatePlayerHealth()
end

event.register(tes3.event.loaded, loadedCallback)
event.register(tes3.event.levelUp, levelUpCallback)
mwse.log(config.Name .. ' Health Increase Module Initialised.')