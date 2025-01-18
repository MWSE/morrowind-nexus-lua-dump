-- Inital Setup --
local config = require("GreaterGhost.STRONGER.config")
----------------------------

-- Register new Effects --

local framework = require("OperatorJack.MagickaExpanded")

tes3.claimSpellEffectId("strongerFeather", 1812)
tes3.claimSpellEffectId("strongerBurden", 1813)

-- Modify Target Encumbrance
local function encumber(target, delta)
    tes3.modStatistic({
        reference = target,
        name = "encumbrance",
        current = delta
    })
end

local function getFeatherDesc(mult)
    return "This effect temporarily reduces the target's encumbrance,"..
    " resulting in a slower loss of fatigue."..
    " The amount of weight removed is ".. tostring(mult) .. " times the magnitude."
end

local function getBurdenDesc(mult)
    return "This effect temporarily increases the weight carried by the victim,"..
    " causing faster fatigue loss."..
    " The amount of weight added is ".. tostring(mult) .." times the magnitude."..
    " When the effect ends, the added weight disappears."
end

local function onTickFeather(e)
    -- Here we use a ME framework function to retrieve the effect object from the onTick event parameter.
    local effect = framework.functions.getEffectFromEffectOnEffectEvent(e, tes3.effect.strongerFeather)
    -- We can then use that effect object to calculate a random magnitude based on the effect configuration.
    local magnitude = framework.functions.getCalculatedMagnitudeFromEffect(effect)
    -- Delta by which to change the target's encumbrance
    local delta = config.multiplier * magnitude

    -- Add Feather Effect
    if (e.effectInstance.state == tes3.spellState.beginning) then
        encumber(e.effectInstance.target.mobile, -1 * delta)
    end

    e:trigger()
    
    -- Remove Feather Effect
    if (e.effectInstance.state == tes3.spellState.ending) then
        encumber(e.effectInstance.target.mobile, delta)
    end

end

local function onTickBurden(e)

    -- Here we use a ME framework function to retrieve the effect object from the onTick event parameter.
    local effect = framework.functions.getEffectFromEffectOnEffectEvent(e, tes3.effect.strongerBurden)
    -- We can then use that effect object to calculate a random magnitude based on the effect configuration.
    local magnitude = framework.functions.getCalculatedMagnitudeFromEffect(effect)
    -- Delta by which to change the target's encumbrance
    local delta = config.multiplier * magnitude

    -- Add Burden Effect
    if (e.effectInstance.state == tes3.spellState.beginning) then
        encumber(e.effectInstance.target.mobile, delta)
    end

    e:trigger()
    
    -- Remove Burden Effect
    if (e.effectInstance.state == tes3.spellState.ending) then
        encumber(e.effectInstance.target.mobile, -1 * delta)
    end

end

local function addEffects()
	framework.effects.alteration.createBasicEffect({
        -- Base information.
        id = tes3.effect.strongerFeather,
        name = "Feather",
        description = getFeatherDesc(config.multiplier),

        -- Basic dials.
        baseCost = 1,

        -- Various flags.
        allowEnchanting = true,
        allowSpellmaking = true,
        canCastTarget = true,
        canCastTouch = true,
        canCastSelf = true,
        isHarmful = false,

        -- Graphics/sounds.
        icon = "s\\tx_s_feather.dds",

        -- Required callbacks.
        onTick = onTickFeather
    })

    framework.effects.alteration.createBasicEffect({
        -- Base information.
        id = tes3.effect.strongerBurden,
        name = "Burden",
        description = getBurdenDesc(config.multiplier),

        -- Basic dials.
        baseCost = 1,

        -- Various flags.
        allowEnchanting = true,
        allowSpellmaking = true,
        canCastTarget = true,
        canCastTouch = true,
        canCastSelf = true,
        isHarmful = true,

        -- Graphics/sounds.
        icon = "s\\tx_s_burden.dds",

        -- Required callbacks.
        onTick = onTickBurden
    })
end

event.register("magicEffectsResolved", addEffects)
-------------------------