--[[
    Kezyma's Mechanics Remastered - Player Script
    OpenMW Port

    Handles player settings registration and player regeneration.
    1:1 feature parity with MWSE version.
]]

local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

-- Try to load common module
local commonLoaded, K = pcall(function()
    return require('scripts.MechanicsRemastered.common')
end)

if not commonLoaded then
    print('[Mechanics Remastered] Failed to load common module: ' .. tostring(K))
    K = {
        healthPerSecond = function(endurance, speed)
            return (0.1 * endurance / 3600) * speed
        end,
        healthRegenCalculation = function(endurance, speed, timescale)
            return (0.1 * endurance / 3600) * speed * timescale
        end,
        healthRegenForHours = function(endurance, speed, hours)
            return (0.1 * endurance / 3600) * speed * 3600 * hours
        end,
        magickaPerSecond = function(intelligence, speed)
            return (0.15 * intelligence / 3600) * speed
        end,
        magickaRegenCalculation = function(intelligence, speed, timescale)
            return (0.15 * intelligence / 3600) * speed * timescale
        end,
        magickaRegenForHours = function(intelligence, speed, hours)
            return (0.15 * intelligence / 3600) * speed * 3600 * hours
        end
    }
end

-- Setting group keys
local SETTINGS_HEALTH = 'Settings_MechanicsRemastered_Health'
local SETTINGS_MAGIC = 'Settings_MechanicsRemastered_Magic'

-- Configuration with defaults matching MWSE config.lua
local config = {
    -- Health Regen Settings
    HealthRegenEnabled = true,
    HealthRegenSpeed = 1.0,
    HealthRegenNPC = true,
    HealthRegenOutOfCombatOnly = true,
    HealthRegenWhileWaiting = true,

    -- Magicka Regen Settings
    MagickaRegenEnabled = true,
    MagickaRegenSpeed = 1.0,
    MagickaRegenNPC = true,
    MagickaRegenWhileWaiting = true,
}

-- Timing variables
local regenAccumulator = 0
local REGEN_INTERVAL = 1.0  -- Match MWSE 1-second timer
local configRefreshTimer = 0
local CONFIG_REFRESH_INTERVAL = 2.0

-- Wait/rest detection
local lastGameTime = nil
local TIME_SKIP_THRESHOLD = 60  -- Seconds of game time to consider a "skip" (wait/rest)

-- ============================================================================
-- SETTINGS REGISTRATION
-- ============================================================================

I.Settings.registerPage({
    key = 'MechanicsRemastered',
    l10n = 'MechanicsRemastered',
    name = 'MechanicsRemastered',
    description = 'Modernized mechanics for Morrowind by Kezyma'
})

I.Settings.registerGroup({
    key = SETTINGS_HEALTH,
    page = 'MechanicsRemastered',
    l10n = 'MechanicsRemastered',
    name = 'HealthRegenTitle',
    permanentStorage = true,
    settings = {
        {
            key = 'HealthRegenEnabled',
            renderer = 'checkbox',
            name = 'HealthRegeneration',
            description = 'HealthRegenerationDesc',
            default = true
        },
        {
            key = 'HealthRegenSpeed',
            renderer = 'number',
            name = 'HealthRegenSpeed',
            description = 'HealthRegenSpeedDesc',
            default = 1.0,
            argument = {
                min = 0.01,
                max = 10.0
            }
        },
        {
            key = 'HealthRegenNPC',
            renderer = 'checkbox',
            name = 'HealthRegenNPC',
            description = 'HealthRegenNPCDesc',
            default = true
        },
        {
            key = 'HealthRegenOutOfCombatOnly',
            renderer = 'checkbox',
            name = 'HealthRegenOutOfCombatOnly',
            description = 'HealthRegenOutOfCombatOnlyDesc',
            default = true
        },
        {
            key = 'HealthRegenWhileWaiting',
            renderer = 'checkbox',
            name = 'HealthRegenWhileWaiting',
            description = 'HealthRegenWhileWaitingDesc',
            default = true
        }
    }
})

I.Settings.registerGroup({
    key = SETTINGS_MAGIC,
    page = 'MechanicsRemastered',
    l10n = 'MechanicsRemastered',
    name = 'MagickaRegenTitle',
    permanentStorage = true,
    settings = {
        {
            key = 'MagickaRegenEnabled',
            renderer = 'checkbox',
            name = 'MagickaRegeneration',
            description = 'MagickaRegenerationDesc',
            default = true
        },
        {
            key = 'MagickaRegenSpeed',
            renderer = 'number',
            name = 'MagickaRegenSpeed',
            description = 'MagickaRegenSpeedDesc',
            default = 1.0,
            argument = {
                min = 0.01,
                max = 10.0
            }
        },
        {
            key = 'MagickaRegenNPC',
            renderer = 'checkbox',
            name = 'MagickaRegenNPC',
            description = 'MagickaRegenNPCDesc',
            default = true
        },
        {
            key = 'MagickaRegenWhileWaiting',
            renderer = 'checkbox',
            name = 'MagickaRegenWhileWaiting',
            description = 'MagickaRegenWhileWaitingDesc',
            default = true
        }
    }
})

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local function refreshConfig()
    local success, err = pcall(function()
        local healthSettings = storage.playerSection(SETTINGS_HEALTH)
        local magicSettings = storage.playerSection(SETTINGS_MAGIC)

        -- Health settings
        local val = healthSettings:get('HealthRegenEnabled')
        if val ~= nil then config.HealthRegenEnabled = val end

        val = healthSettings:get('HealthRegenSpeed')
        if val ~= nil then config.HealthRegenSpeed = val end

        val = healthSettings:get('HealthRegenNPC')
        if val ~= nil then config.HealthRegenNPC = val end

        val = healthSettings:get('HealthRegenOutOfCombatOnly')
        if val ~= nil then config.HealthRegenOutOfCombatOnly = val end

        val = healthSettings:get('HealthRegenWhileWaiting')
        if val ~= nil then config.HealthRegenWhileWaiting = val end

        -- Magicka settings
        val = magicSettings:get('MagickaRegenEnabled')
        if val ~= nil then config.MagickaRegenEnabled = val end

        val = magicSettings:get('MagickaRegenSpeed')
        if val ~= nil then config.MagickaRegenSpeed = val end

        val = magicSettings:get('MagickaRegenNPC')
        if val ~= nil then config.MagickaRegenNPC = val end

        val = magicSettings:get('MagickaRegenWhileWaiting')
        if val ~= nil then config.MagickaRegenWhileWaiting = val end
    end)

    if not success then
        print('[Mechanics Remastered] Player config error: ' .. tostring(err))
    end
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Check if player is in combat
-- In OpenMW, we check the stance or if there are nearby hostile actors
local function isPlayerInCombat()
    local success, result = pcall(function()
        local stance = types.Actor.getStance(self.object)
        -- Stance 1 = Weapon, Stance 2 = Spell - but not necessarily in combat
        -- Better check: see if any actor is targeting the player
        -- For simplicity, use stance as approximation (weapon/spell drawn = combat ready)
        return stance ~= types.Actor.STANCE.Nothing
    end)
    if success then
        return result
    end
    return false
end

-- Check if actor has Stunted Magicka effect (Atronach birthsign)
local function hasStuntedMagicka(actor)
    local success, result = pcall(function()
        local effects = types.Actor.activeEffects(actor)
        -- Effect ID for Stunted Magicka is 136 in Morrowind
        -- In OpenMW Lua, we need to iterate effects
        for _, effect in pairs(effects) do
            if effect.id == 'stuntedmagicka' or effect.affectedSkill == 'stuntedmagicka' then
                return true
            end
        end
        -- Alternative: check by effect name/id
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
-- PLAYER REGENERATION (runs every 1 second like MWSE)
-- ============================================================================

local function doPlayerRegeneration()
    local timescale = core.getGameTimeScale() or 30

    -- Skip if dead
    if types.Actor.isDead(self.object) then return end

    -- Health regeneration
    if config.HealthRegenEnabled then
        -- Check combat restriction
        local canRegenHealth = (not config.HealthRegenOutOfCombatOnly) or (not isPlayerInCombat())

        if canRegenHealth then
            local health = types.Actor.stats.dynamic.health(self)
            local endurance = types.Actor.stats.attributes.endurance(self)

            if health and endurance then
                local endVal = endurance.modified or endurance.base or 40
                local current = health.current
                local base = health.base

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
    if config.MagickaRegenEnabled then
        -- Check for Stunted Magicka (Atronach)
        local hasStunted = hasStuntedMagicka(self.object)

        if not hasStunted then
            local magicka = types.Actor.stats.dynamic.magicka(self)
            local intelligence = types.Actor.stats.attributes.intelligence(self)

            if magicka and intelligence then
                local intVal = intelligence.modified or intelligence.base or 40
                local current = magicka.current
                local base = magicka.base

                if current < base then
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
-- WAIT/REST REGENERATION
-- Detects time skips (from waiting/resting) and applies bulk regeneration
-- ============================================================================

local function handleTimeSkip(hoursSkipped)
    -- Skip if dead
    if types.Actor.isDead(self.object) then return end

    -- Health regeneration while waiting
    if config.HealthRegenEnabled and config.HealthRegenWhileWaiting then
        local health = types.Actor.stats.dynamic.health(self)
        local endurance = types.Actor.stats.attributes.endurance(self)

        if health and endurance then
            local endVal = endurance.modified or endurance.base or 40
            local current = health.current
            local base = health.base

            if current < base and current > 0 then
                local totalRegen = K.healthRegenForHours(endVal, config.HealthRegenSpeed, hoursSkipped)
                local newHealth = current + totalRegen
                if newHealth > base then newHealth = base end
                health.current = newHealth
            end
        end
    end

    -- Magicka regeneration while waiting
    if config.MagickaRegenEnabled and config.MagickaRegenWhileWaiting then
        local hasStunted = hasStuntedMagicka(self.object)

        if not hasStunted then
            local magicka = types.Actor.stats.dynamic.magicka(self)
            local intelligence = types.Actor.stats.attributes.intelligence(self)

            if magicka and intelligence then
                local intVal = intelligence.modified or intelligence.base or 40
                local current = magicka.current
                local base = magicka.base

                if current < base then
                    local totalRegen = K.magickaRegenForHours(intVal, config.MagickaRegenSpeed, hoursSkipped)
                    local newMagicka = current + totalRegen
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

    -- Get current game time
    local currentGameTime = core.getGameTime()

    -- Detect time skips (waiting/resting)
    if lastGameTime ~= nil then
        local expectedAdvance = dt * (core.getGameTimeScale() or 30)
        local actualAdvance = currentGameTime - lastGameTime

        -- If time advanced significantly more than expected, it's a time skip
        if actualAdvance > TIME_SKIP_THRESHOLD and actualAdvance > expectedAdvance * 2 then
            local hoursSkipped = actualAdvance / 3600
            handleTimeSkip(hoursSkipped)
        end
    end
    lastGameTime = currentGameTime

    -- Accumulate time for 1-second regen ticks (matching MWSE timer behavior)
    regenAccumulator = regenAccumulator + dt
    if regenAccumulator >= REGEN_INTERVAL then
        doPlayerRegeneration()
        regenAccumulator = regenAccumulator - REGEN_INTERVAL
    end
end

local function onInit()
    print('[Mechanics Remastered] Player script initialized')
    refreshConfig()
    lastGameTime = core.getGameTime()
end

local function onLoad()
    refreshConfig()
    lastGameTime = core.getGameTime()
end

local function onSave()
    return {
        lastGameTime = lastGameTime
    }
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInit = onInit,
        onLoad = onLoad,
        onSave = onSave,
    }
}
