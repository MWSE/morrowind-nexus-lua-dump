local formulas = require("alchemyArt.formulas")
local common = require("alchemyArt.common")

local standardPotion = {

}

local endingQuality = {
    _b = 5,
    _c = 4,
    _s = 3,
    _q = 2,
    _e = 1
}

local qualityNoMagnitude = {
    [5] = 1,
    [4] = 3,
    [3] = 6,
    [2] = 12,
    [1] = 25
}

local qualityNoDuration = {
    [5] = 6,
    [4] = 12,
    [3] = 25,
    [2] = 50,
    [1] = 100
}

local qualityPower = {
    [5] = 40,
    [4] = 120,
    [3] = 300,
    [2] = 675,
    [1] = 1200
}

local effectsToRecount = {
    [tes3.effect.restoreHealth] = true,
    [tes3.effect.restoreFatigue] = true,
    [tes3.effect.restoreMagicka] = true,
    [tes3.effect.restoreAttribute] = true,
    [tes3.effect.restoreSkill] = true,
    [tes3.effect.fortifyMaximumMagicka] = true,
    [tes3.effect.fortifyMagicka] = true,
    [tes3.effect.fortifyHealth] = true,
    [tes3.effect.fortifyFatigue] = true,
    [tes3.effect.burden] = true,
    [tes3.effect.sound] = true,
}

standardPotion.getQuality = function(item)
    local ending = string.sub(item.id, -2):lower()
    return endingQuality[ending] or false
end

standardPotion.init = function ()
    for alch in tes3.iterateObjects(tes3.objectType.alchemy) do
        if string.startswith(alch.id, "p_") and alch:getActiveEffectCount() == 1 then
            local quality = standardPotion.getQuality(alch)
            if quality then
                local effect = alch.effects[1]
                if common.config.rebalancePotions then
                    -- mwse.log(alch.id)
                    if effectsToRecount[effect.id] then

                        -- mwse.log(inspect(qualityPower))
                        -- mwse.log(quality)

                        effect.min, effect.duration = formulas.getEffectMagnitudeDuration(effect.id, qualityPower[quality])
                        effect.max = effect.min
                    elseif  effect.object.hasNoMagnitude and not effect.object.hasNoDuration then
                        effect.duration = qualityNoMagnitude[quality]
                    elseif effect.object.hasNoDuration and not effect.object.hasNoMagnitude then
                        effect.min = qualityNoDuration[quality]
                        effect.max = qualityNoDuration[quality]
                    end
                end
                standardPotion[effect.id] = standardPotion[effect.id] or {}
                standardPotion[effect.id][quality] = alch
            end
        end
    end
    -- mwse.log("Standard potion init finished")
    -- mwse.log(inspect(standardPotion))
end

standardPotion.getLowerOrEqual = function(alch)
    if alch:getActiveEffectCount() == 1 then
        local effectId = alch.effects[1].id
        local standardPotionWithEffect = standardPotion[effectId]
        -- mwse.log(effectId)
        -- mwse.log("Standard potions")
        -- mwse.log(inspect(standardPotion[effectId]))
        if standardPotionWithEffect then
            local power = formulas.getEffectPower(alch.effects[1])
            for quality, standardPotionOfQuality in ipairs(standardPotionWithEffect) do
                -- mwse.log("found %s", standardPotionOfQuality)
                local standardPower = formulas.getEffectPower(standardPotionOfQuality.effects[1])
                -- mwse.log("%s, %s", standardPower, power)
                if power >= standardPower then
                    return standardPotionOfQuality
                end
            end
            local standardPotionOfQuality = standardPotionWithEffect[3]
            if standardPotionOfQuality then
                -- mwse.log("found %s", standardPotionOfQuality)
            end
            local standardPower = formulas.getEffectPower(standardPotionOfQuality.effects[1])
            -- mwse.log("%s, %s", standardPower, power)
            if power >= standardPower then
                return standardPotionOfQuality
            end
        end
    end
    -- mwse.log("Failed to find standard potion")
end

return standardPotion