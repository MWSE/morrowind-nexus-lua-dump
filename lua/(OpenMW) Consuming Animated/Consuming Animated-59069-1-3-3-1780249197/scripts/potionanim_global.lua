local types  = require('openmw.types')
local world  = require('openmw.world')
local I      = require('openmw.interfaces')
local shared = require('scripts.potionanim_shared')

local WATCHER = "scripts/potionanim_watcher.lua"

-- last known NPC settings
local cachedSettings = {
    NPC_ENABLE             = shared.DEFAULTS.NPC_ENABLE,
    NPC_ANIMATION_COOLDOWN = shared.DEFAULTS.NPC_ANIMATION_COOLDOWN,
    NPC_ANIMATION_SPEED    = shared.DEFAULTS.NPC_ANIMATION_SPEED,
    NPC_LOCK_WEAPON        = shared.DEFAULTS.NPC_LOCK_WEAPON,
    NPC_SOUND_ENABLE       = shared.DEFAULTS.NPC_SOUND_ENABLE,
    NPC_SOUND_VOLUME       = shared.DEFAULTS.NPC_SOUND_VOLUME,
    NPC_SOUND_PITCH        = shared.DEFAULTS.NPC_SOUND_PITCH,
}

-- player consecutive-drink lockout
local playerDrinking = false

-- won't work from the inventory
local function blockConsecutiveUsage(item, actor)
    if not types.Player.objectIsInstance(actor) then return end
    if playerDrinking then return false end
end

I.ItemUsage.addHandlerForType(types.Potion, blockConsecutiveUsage)
I.ItemUsage.addHandlerForType(types.Ingredient, blockConsecutiveUsage)

local function onPlayerDrinkStart()
    playerDrinking = true
end

local function onPlayerDrinkEnd()
    playerDrinking = false
end

local function onActorActive(actor)
    if types.Player.objectIsInstance(actor) then return end
    if not actor:hasScript(WATCHER) then
        actor:addScript(WATCHER)
    end
    actor:sendEvent("PotionAnim_SettingsUpdated", cachedSettings)
end

local function onWatcherInactive(data)
    local actor = data and data.actor
    if actor and actor:isValid() and actor:hasScript(WATCHER) then
        actor:removeScript(WATCHER)
    end
end

local function onSettingsUpdated(newSettings)
    if not newSettings then return end
    cachedSettings = newSettings
    for _, actor in ipairs(world.activeActors) do
        if actor:hasScript(WATCHER) then
            actor:sendEvent("PotionAnim_SettingsUpdated", newSettings)
        end
    end
end

return {
    engineHandlers = {
        onActorActive = onActorActive,
    },
    eventHandlers = {
        PotionAnim_WatcherInactive = onWatcherInactive,
        PotionAnim_SettingsUpdated = onSettingsUpdated,
        PotionAnim_PlayerDrinkStart = onPlayerDrinkStart,
        PotionAnim_PlayerDrinkEnd   = onPlayerDrinkEnd,
    },
}