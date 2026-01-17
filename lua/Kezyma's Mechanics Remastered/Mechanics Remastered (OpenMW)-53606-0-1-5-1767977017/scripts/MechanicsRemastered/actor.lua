--[[
    Kezyma's Mechanics Remastered - Actor Script
    OpenMW Port

    Handles NPC and Creature regeneration.
    1:1 feature parity with MWSE version.
]]

local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local storage = require('openmw.storage')

-- Try to load common module
local commonLoaded, K = pcall(function()
    return require('scripts.MechanicsRemastered.common')
end)

if not commonLoaded then
    K = {
        healthRegenCalculation = function(endurance, speed, timescale)
            return (0.1 * endurance / 3600) * speed * timescale
        end,
        magickaRegenCalculation = function(intelligence, speed, timescale)
            return (0.15 * intelligence / 3600) * speed * timescale
        end
    }
end

-- Setting group keys (same as player script)
local SETTINGS_HEALTH = 'Settings_MechanicsRemastered_Health'
local SETTINGS_MAGIC = 'Settings_MechanicsRemastered_Magic'

-- Configuration with defaults
local config = {
    HealthRegenEnabled = true,
    HealthRegenSpeed = 1.0,
    HealthRegenNPC = true,
    HealthRegenOutOfCombatOnly = true,
    MagickaRegenEnabled = true,
    MagickaRegenSpeed = 1.0,
    MagickaRegenNPC = true,
}

-- Timing variables
local regenAccumulator = 0
local REGEN_INTERVAL = 1.0  -- Match MWSE 1-second timer
local configRefreshTimer = 0
local CONFIG_REFRESH_INTERVAL = 2.0

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local function refreshConfig()
    local success, err = pcall(function()
        -- Use globalSection to read settings set by player script
        local healthSettings = storage.globalSection(SETTINGS_HEALTH)
        local magicSettings = storage.globalSection(SETTINGS_MAGIC)

        local val = healthSettings:get('HealthRegenEnabled')
        if val ~= nil then config.HealthRegenEnabled = val end

        val = healthSettings:get('HealthRegenSpeed')
        if val ~= nil then config.HealthRegenSpeed = val end

        val = healthSettings:get('HealthRegenNPC')
        if val ~= nil then config.HealthRegenNPC = val end

        val = healthSettings:get('HealthRegenOutOfCombatOnly')
        if val ~= nil then config.HealthRegenOutOfCombatOnly = val end

        val = magicSettings:get('MagickaRegenEnabled')
        if val ~= nil then config.MagickaRegenEnabled = val end

        val = magicSettings:get('MagickaRegenSpeed')
        if val ~= nil then config.MagickaRegenSpeed = val end

        val = magicSettings:get('MagickaRegenNPC')
        if val ~= nil then config.MagickaRegenNPC = val end
    end)
    -- Silently ignore config errors for NPCs
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Check if actor is in combat
local function isActorInCombat()
    local success, result = pcall(function()
        local stance = types.Actor.getStance(self.object)
        return stance ~= types.Actor.STANCE.Nothing
    end)
    if success then
        return result
    end
    return false
end

-- Check if actor has Stunted Magicka effect (Atronach birthsign)
local function hasStuntedMagicka()
    local success, result = pcall(function()
        local effects = types.Actor.activeEffects(self.object)
        for _, effect in pairs(effects) do
            if effect.id == 'stuntedmagicka' or effect.affectedSkill == 'stuntedmagicka' then
                return true
            end
        end
        local stuntedEffect = effects:getEffect(core.magic.EFFECT_TYPE.StuntedMagicka)
        if stuntedEffect and stuntedEffect.magnitude > 0 then
            return true
        end
        return false
    end)
    if success then
        return result
    end
    return false
end

-- ============================================================================
-- ACTOR REGENERATION (runs every 1 second like MWSE)
-- ============================================================================

local function doActorRegeneration()
    -- Skip if NPC regen is disabled for both
    if not config.HealthRegenNPC and not config.MagickaRegenNPC then
        return
    end

    local timescale = core.getGameTimeScale() or 30

    -- Skip if dead
    if types.Actor.isDead(self.object) then return end

    -- Health regeneration
    if config.HealthRegenEnabled and config.HealthRegenNPC then
        -- Check combat restriction (matching MWSE: canRegenNPC)
        local canRegenHealth = (not config.HealthRegenOutOfCombatOnly) or (not isActorInCombat())

        if canRegenHealth then
            local health = types.Actor.stats.dynamic.health(self)
            local endurance = types.Actor.stats.attributes.endurance(self)

            if health and endurance then
                local endVal = endurance.modified or endurance.base or 40
                local current = health.current
                local base = health.base

                -- Match MWSE: ref.mobile.health.current > 0
                if current < base and current > 0 then
                    local regen = K.healthRegenCalculation(endVal, config.HealthRegenSpeed, timescale)
                    local newHealth = current + regen
                    if newHealth > base then newHealth = base end
                    health.current = newHealth
                end
            end
        end
    end

    -- Magicka regeneration
    if config.MagickaRegenEnabled and config.MagickaRegenNPC then
        -- Check for Stunted Magicka (Atronach) - matching MWSE npcatronach check
        local hasStunted = hasStuntedMagicka()

        if not hasStunted then
            local magicka = types.Actor.stats.dynamic.magicka(self)
            local intelligence = types.Actor.stats.attributes.intelligence(self)

            if magicka and intelligence then
                local intVal = intelligence.modified or intelligence.base or 40
                local current = magicka.current
                local base = magicka.base

                -- Match MWSE: ref.mobile.health.current > 0 check before magicka regen
                local health = types.Actor.stats.dynamic.health(self)
                local isAlive = health and health.current > 0

                if current < base and isAlive then
                    local regen = K.magickaRegenCalculation(intVal, config.MagickaRegenSpeed, timescale)
                    local newMagicka = current + regen
                    if newMagicka > base then newMagicka = base end
                    magicka.current = newMagicka
                end
            end
        end
    end
end

-- ============================================================================
-- ENGINE HANDLERS
-- ============================================================================

local function onUpdate(dt)
    -- Refresh config periodically
    configRefreshTimer = configRefreshTimer + dt
    if configRefreshTimer >= CONFIG_REFRESH_INTERVAL then
        refreshConfig()
        configRefreshTimer = 0
    end

    -- Accumulate time for 1-second regen ticks (matching MWSE timer behavior)
    regenAccumulator = regenAccumulator + dt
    if regenAccumulator >= REGEN_INTERVAL then
        doActorRegeneration()
        regenAccumulator = regenAccumulator - REGEN_INTERVAL
    end
end

local function onActive()
    refreshConfig()
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onActive = onActive,
    }
}
