local this = {}
local common = require("FortifyMAX.common")

local sT = "spellTick"

local function setCurAtr(atr, value)
    tes3.setStatistic{
        reference = tes3.player,
        attribute = atr,
        current = value,
    }
end

-- Cycles through all magic effects on the player and adds up the total magnitude of a particular effect with a
-- particular attribute, with a source that's a permanent ability. This isn't ideal because it happens every tick of a
-- Restore Attribute effect on the player. If anyone knows a better way to do this, please let me know.
local function getPermAtrEffectMag(effect, atr)
    local mag = 0
    local activeEffect = tes3.mobilePlayer.activeMagicEffects

    for _ = 1, tes3.mobilePlayer.activeMagicEffectCount do
        activeEffect = activeEffect.next

        if activeEffect.effectId == effect
        and activeEffect.attributeId == atr then
            local instance = activeEffect.instance

            if instance.sourceType == tes3.magicSourceType.spell
            and instance.source.castType == tes3.spellType.ability then
                mag = mag + activeEffect.magnitude
            end
        end
    end

    return mag
end

local function getAtrEffectMag(effect, atr)
    return tes3.getEffectMagnitude{
        reference = tes3.player,
        effect = effect,
        attribute = atr,
    }
end

function this.onSpellTick(e)
    if e.target ~= tes3.player then
        return
    end

    local effect = e.effect
    local effectId = effect.id

    --[[ When the player is under a Restore Attribute effect and the attribute reaches max (or is already at max), the
    attribute will no longer change, but the game will continue to recalculate magicka/fatigue every tick of the effect
    if applicable. Therefore, once the attribute reaches max, we end the effect, to avoid magicka/fatigue being reset to
    vanilla. ]]--
    if effectId == tes3.effect.restoreAttribute then
        local atrId = effect.attribute
        local atrIdMob = atrId + 1
        local curAtr = tes3.mobilePlayer.attributes[atrIdMob].currentRaw
        local baseAtr = tes3.mobilePlayer.attributes[atrIdMob].base

        -- We can't just use totalFortAtrMag, because the player might have a permanent ability that fortifies this
        -- attribute, which increases .base *and* contributes to totalFortAtrMag, which means it would be taken into
        -- account twice and the limit would be wrong.
        local totalFortAtrMag = getAtrEffectMag(tes3.effect.fortifyAttribute, atrId)
        local permFortAtrMag = getPermAtrEffectMag(tes3.effect.fortifyAttribute, atrId)
        local fortAtrMag = totalFortAtrMag - permFortAtrMag

        -- We're assuming the player is using the MCP bugfix patches related to Fortify/Drain/Restore Attribute. If not,
        -- this won't work properly when under a fortify effect.
        local limit = baseAtr + fortAtrMag

        if curAtr >= limit then
            local atrName = tes3.attributeName[atrId]
            local atrNameCap = string.gsub(atrName, "%l", string.upper, 1)
            local drainAtrMag = getAtrEffectMag(tes3.effect.drainAttribute, atrId)

            --[[ When a Drain Attribute effect ends, the attribute will be increased by the drain magnitude, up to its
            maximum (the base value plus any fortify magnitude for that attribute). If the attribute has already been
            restored up to max, it will not change when the drain effect ends, but the game will still recalculate
            magicka/fatigue if it's a relevant attribute. So we need to ensure that the attribute never gets restored up
            to max while under a drain effect (to ensure it changes when the effect ends, and therefore this mod will
            detect it and do its thing). Otherwise magicka/fatigue could be reset to vanilla. ]]--
            if drainAtrMag > 0 then
                local target = limit - 1

                -- Wait a frame to give the restore effect time to end and make sure the attribute changes each tick of
                -- the effect.
                timer.delayOneFrame(function()
                    setCurAtr(atrId, target)

                    local newAtr = tes3.mobilePlayer.attributes[atrIdMob].currentRaw
                    common.logMsg(sT, string.format("Player is under a Drain %s effect, and current %s has reached max. Setting current %s to 1 less than max.", atrNameCap, atrName, atrName))
                    common.logMsg(sT, string.format("Drain %s magnitude: %f", atrNameCap, drainAtrMag))
                    common.logMsg(sT, string.format("Target: %f", target))
                    common.logMsg(sT, string.format("New %s: %f", atrName, newAtr))
                end)
            end

            common.logMsg(sT, string.format("Player is under a Restore %s effect and current %s is at max. Ending effect.", atrNameCap, atrName))
            common.logMsg(sT, string.format("Current %s: %f", atrName, curAtr))
            common.logMsg(sT, string.format("Base %s: %f", atrName, baseAtr))
            common.logMsg(sT, string.format("Total Fortify %s magnitude: %f", atrNameCap, totalFortAtrMag))
            common.logMsg(sT, string.format("Permanent Fortify %s magnitude: %f", atrNameCap, permFortAtrMag))
            common.logMsg(sT, string.format("Relevant Fortify %s magnitude: %f", atrNameCap, fortAtrMag))
            common.logMsg(sT, string.format("Limit: %f", limit))

            e.effectInstance.state = tes3.spellState.ending
        end

    -- When an attribute is damaged to 0, further Damage Attribute ticks will not change the attribute further, but the
    -- game will recalculate magicka/fatigue anyway every tick. To prevent that we end the effect once the attribute
    -- reaches 0.
    elseif effectId == tes3.effect.damageAttribute then
        local atrId = effect.attribute
        local atrIdMob = atrId + 1
        local curAtr = tes3.mobilePlayer.attributes[atrIdMob].currentRaw

        if curAtr <= 0 then
            local atrName = tes3.attributeName[atrId]
            local atrNameCap = string.gsub(atrName, "%l", string.upper, 1)
            common.logMsg(sT, string.format("Player is under a Damage %s effect and current %s is 0. Ending effect.", atrNameCap, atrName))
            common.logMsg(sT, string.format("Current %s: %f", atrName, curAtr))

            e.effectInstance.state = tes3.spellState.ending
        end
    end
end

return this