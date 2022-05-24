local logging = false

local mod = "Attribute Effect Tweaks"
local version = "1.0"
local modDisplay = string.format("[%s %s]", mod, version)

local interop = require("AttributeEffectTweaks.interop")

local function logMsg(message)
    if logging then
        mwse.log("%s %s", modDisplay, message)
    end
end

local function setCurAtr(atr, value)
    tes3.setStatistic{
        reference = tes3.player,
        attribute = atr,
        current = value,
    }
end

-- Cycles through all magic effects on the player and adds up the total magnitude fortifying a particular attribute with
-- a source that's a permanent ability. This isn't ideal because it can happen every frame under some circumstances. If
-- anyone knows a better way to do this, please let me know.
local function getAbilityMag(atr)
    local mag = 0
    local activeEffect = tes3.mobilePlayer.activeMagicEffects

    for _ = 1, tes3.mobilePlayer.activeMagicEffectCount do
        local instance, source
        activeEffect = activeEffect.next

        if activeEffect.effectId ~= tes3.effect.fortifyAttribute then
            goto continue
        end

        if activeEffect.attributeId ~= atr then
            goto continue
        end

        instance = activeEffect.instance

        if instance.sourceType ~= tes3.magicSourceType.spell then
            goto continue
        end

        source = instance.source

        if source.castType ~= tes3.spellType.ability then
            goto continue
        end

        mag = mag + activeEffect.magnitude

        ::continue::
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

local function onSpellTick(e)
    if e.target ~= tes3.player then
        return
    end

    local effect = e.effect
    local effectId = effect.id

    --[[ When the player is under a Restore Attribute effect and the attribute reaches max (or is already at max), the
    attribute will no longer change, but the game will continue to recalculate derived values (e.g. magicka, fatigue,
    and encumbrance) every tick of the effect if applicable. Therefore, once the attribute reaches max, we end the
    effect, to avoid derived values being recalculated without the relevant attribute actually changing. This is
    required by certain mods that change how the derived values are calculated, to avoid them being reset to vanilla
    values. ]]--
    if effectId == tes3.effect.restoreAttribute then
        local atrId = effect.attribute
        local atrIdMob = atrId + 1
        local curAtr = tes3.mobilePlayer.attributes[atrIdMob].currentRaw
        local baseAtr = tes3.mobilePlayer.attributes[atrIdMob].base

        -- We can't just use totalFortAtrMag, because the player might have a permanent ability that fortifies this
        -- attribute, which increases .base *and* contributes to totalFortAtrMag, which means it would be taken into
        -- account twice and the limit would be wrong.
        local totalFortAtrMag = getAtrEffectMag(tes3.effect.fortifyAttribute, atrId)
        local fortAtrMag, permFortAtrMag

        if totalFortAtrMag > 0 then
            permFortAtrMag = getAbilityMag(atrId)
            fortAtrMag = totalFortAtrMag - permFortAtrMag
        else
            permFortAtrMag = 0
            fortAtrMag = totalFortAtrMag
        end

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
            applicable derived values. So we need to ensure that the attribute never gets restored up to max while under
            a drain effect (to ensure it changes when the effect ends). This way mods that change how the derived values
            are calculated will detect the change and do their thing. Otherwise the derived value could be reset to
            vanilla. ]]--
            if drainAtrMag > 0 then
                local target = limit - 1

                -- Wait a frame to give the restore effect time to end and make sure the attribute changes each tick of
                -- the effect.
                timer.delayOneFrame(function()
                    setCurAtr(atrId, target)

                    local newAtr = tes3.mobilePlayer.attributes[atrIdMob].currentRaw
                    logMsg(string.format("Player is under a Drain %s effect, and current %s has reached max. Setting current %s to 1 less than max.", atrNameCap, atrName, atrName))
                    logMsg(string.format("Drain %s magnitude: %f", atrNameCap, drainAtrMag))
                    logMsg(string.format("Target: %f", target))
                    logMsg(string.format("New %s: %f", atrName, newAtr))
                end)
            end

            logMsg(string.format("Player is under a Restore %s effect and current %s is at max. Ending effect.", atrNameCap, atrName))
            logMsg(string.format("Current %s: %f", atrName, curAtr))
            logMsg(string.format("Base %s: %f", atrName, baseAtr))
            logMsg(string.format("Total Fortify %s magnitude: %f", atrNameCap, totalFortAtrMag))
            logMsg(string.format("Permanent Fortify %s magnitude: %f", atrNameCap, permFortAtrMag))
            logMsg(string.format("Relevant Fortify %s magnitude: %f", atrNameCap, fortAtrMag))
            logMsg(string.format("Limit: %f", limit))

            e.effectInstance.state = tes3.spellState.ending
        end

    -- When an attribute is damaged to 0, further Damage Attribute ticks will not change the attribute further, but the
    -- game will recalculate derived values anyway every tick. To prevent that we end the effect once the attribute
    -- reaches 0.
    elseif effectId == tes3.effect.damageAttribute then
        local atrId = effect.attribute
        local atrIdMob = atrId + 1
        local curAtr = tes3.mobilePlayer.attributes[atrIdMob].currentRaw

        if curAtr <= 0 then
            local atrName = tes3.attributeName[atrId]
            local atrNameCap = string.gsub(atrName, "%l", string.upper, 1)
            logMsg(string.format("Player is under a Damage %s effect and current %s is 0. Ending effect.", atrNameCap, atrName))
            logMsg(string.format("Current %s: %f", atrName, curAtr))

            e.effectInstance.state = tes3.spellState.ending
        end
    end
end

local function onInitialized()
    local buildDate = mwse.buildDate
    local tooOld = string.format("%s MWSE is too out of date. Update MWSE to use this mod.", modDisplay)

    if not buildDate
    or buildDate < 20210518 then
        tes3.messageBox(tooOld)
        mwse.log(tooOld)
        return
    end

    mwse.log("%s initialized.", modDisplay)
    event.register("spellTick", onSpellTick)
    interop.enabled = true
end

event.register("initialized", onInitialized)