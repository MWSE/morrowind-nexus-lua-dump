-- devilish_wabbajack_creature.lua
-- Path: scripts/devilish_wabbajack_creature.lua

local self  = require('openmw.self')
local types = require('openmw.types')
local time  = require('openmw_aux.time')
local core  = require('openmw.core')

local knockback = require('scripts.detd_wabbajack_knockback').init{
    magnitude = 90,
    verticalFactor = 2.95,
    bounceAmount = 0.28,
    maxBounces = 0,
    adjustByAttackPower = false,
    airborneThreshold = 80,
    landedEventName = 'detd_KnockbackLanded',
    radius = 24,
    indoorRadius = 12,
    outdoorRayMultiplier = 3.0,
    indoorRayMultiplier = 1.15,
    indoorMagnitudeMultiplier = 0.45,
    indoorVerticalMultiplier = 0.85,
}

local POLL_INTERVAL = 0.25 * time.second
local doOnce = false
local wasTransformed = false

local function disableSelf()
    core.sendGlobalEvent('detd_DisableActor', { obj2 = self })
end

local function rollEffect()
    return math.random(7)
end

local function isWabbaActive()
    return types.Actor.activeSpells(self):isSpellActive('T_Dae_UNI_Wabbajack')
end

local function handleScaleOption()
    local s = self.scale

    if s < 0.75 then
        core.sendGlobalEvent('detd_StartGradualGrow', { obj = self })
    elseif s > 1.50 then
        core.sendGlobalEvent('detd_StartGradualNormalize', { obj = self })
    elseif s >= 0.95 and s <= 1.05 then
        if math.random() < 0.5 then
            core.sendGlobalEvent('detd_StartGradualShrink', { obj = self })
        else
            core.sendGlobalEvent('detd_StartGradualEnlarge', { obj = self })
        end
    elseif s < 1.0 then
        core.sendGlobalEvent('detd_StartGradualShrink', { obj = self })
    else
        core.sendGlobalEvent('detd_StartGradualEnlarge', { obj = self })
    end
end

local function applyKnockbackLandingPenalty(data)
    local riseAmount = 0

    if data and data.riseAmount then
        riseAmount = data.riseAmount
    end

    if riseAmount <= 0 then
        return
    end

    types.Actor.stats.dynamic.fatigue(self).current = -10
    types.Actor.stats.dynamic.health(self).current =
        types.Actor.stats.dynamic.health(self).current - 45
end

local function castWeatherOrFallback()
    if self.cell and self.cell.isExterior then
        core.sendGlobalEvent('detd_WabbaRandomWeather', { obj = self })
    else
        -- Indoors, weather cannot happen.
        -- For now just do nothing.
        print("[WABBA CREATURE] weather rolled indoors, no effect")
    end
end

local function castObjectTransformPlaceholder()
    -- Placeholder for future "transform into object" effect
    print("[WABBA CREATURE] object transform placeholder")
end

local function castWabbaEffect()
    local option = rollEffect()
    print("[WABBA CREATURE] option = " .. tostring(option))

    if option == 1 then
        -- transform creature
        core.sendGlobalEvent('detd_WabbaEvent', { obj = self })
        core.sendGlobalEvent('detd_SmallifyActorWabba', { obj2 = self })
        types.Actor.stats.dynamic.fatigue(self).current = 0
        types.Actor.stats.dynamic.health(self).current = 0
        types.Actor.spells(self):add('detd_wabbakillinvis')
        wasTransformed = true

    elseif option == 2 then
        -- paralysis
        types.Actor.activeSpells(self):add{ id = 'Paralysis', effects = { 0 } }

    elseif option == 3 then
        -- heal
        types.Actor.activeSpells(self):add{ id = 'hearth heal', effects = { 0 } }

    elseif option == 4 then
        -- scale
        handleScaleOption()

    elseif option == 5 then
        -- knockback
        print("[WABBA CREATURE] starting knockback")
        knockback.start()

    elseif option == 6 then
        -- weather
        castWeatherOrFallback()

    elseif option == 7 then
        -- future object transformation placeholder
        castObjectTransformPlaceholder()
    end
end

time.runRepeatedly(function()
    if wasTransformed and types.Actor.isDeathFinished(self) then
        disableSelf()
        return
    end

    local hasWabba = isWabbaActive()

    if not hasWabba then
        doOnce = false
        return
    end

    if doOnce then
        return
    end

    castWabbaEffect()
    doOnce = true
end, POLL_INTERVAL)

return {
    engineHandlers = knockback.engineHandlers,
    eventHandlers = {
        detd_TELE_DONE = knockback.eventHandlers.detd_TELE_DONE,
        detd_KnockbackLanded = applyKnockbackLandingPenalty,
    }
}
