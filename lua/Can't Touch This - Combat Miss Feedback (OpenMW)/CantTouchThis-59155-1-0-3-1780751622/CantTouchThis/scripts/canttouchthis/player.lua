---@omw-context player
local core                        = require('openmw.core')
local types                       = require('openmw.types')
local Constants                   = require('scripts.canttouchthis.helpers.constants')
local SettingsConstants           = require('scripts.canttouchthis.helpers.settings_constants')
local Helpers                     = require('scripts.canttouchthis.helpers.helpers')
local I                           = require('openmw.interfaces')
local storage                     = require('openmw.storage')
local async                       = require('openmw.async')
local self                        = require('openmw.self')
local anim                        = require('openmw.animation')
local getStance                   = types.Actor.getStance
local activeEffects               = self.type.activeEffects(self)
local fatigue                     = self.type.stats.dynamic.fatigue(self)
local random                      = math.random
local isStaggered                 = false
local playMissAnimationsForPlayer = SettingsConstants.playMissAnimationsForPlayerDefault
local playerSection               = storage.playerSection(SettingsConstants.settingsStorageKey)
local stateManager                = require('scripts.canttouchthis.controllers.state').new()


playerSection:subscribe(async:callback(function(groupName, changedKey)
    if changedKey == SettingsConstants.playMissAnimationsForPlayerKey then
        playMissAnimationsForPlayer = SettingsConstants.readSetting(playerSection,
            SettingsConstants.playMissAnimationsForPlayerKey)
    end
end))

I.Combat.addOnHitHandler(function(attack)
    if I.NGardePlayer then return end
    if not playMissAnimationsForPlayer then return end
    stateManager:playMissAnimation(attack)
end)


local function onFrame()
    if I.NGardePlayer then return end
    if core.isWorldPaused() then return end
    stateManager:checkStaggerState()
end

--redirecting the event to the global script, so we can attach/detach actor scripts
local function onCombatTargetChanged(eventData)
    if I.NGardePlayer then return end
    if eventData.actor ~= nil then
        local record = eventData.actor.type.record(eventData.actor)
        if (eventData.actor.type == types.NPC or
                (Helpers.arrayContains(Constants.creatureWhiteList, record.id:lower())) or
                (eventData.actor.type == types.Creature and record.canUseWeapons and
                    not Helpers.arrayContains(Constants.creatureBlackList, record.id:lower()))) then
            core.sendGlobalEvent("canttouchthis_combatTargetChanged", eventData)
        end
    end
end

local function onLoad()
    playMissAnimationsForPlayer = SettingsConstants.readSetting(playerSection,
        SettingsConstants.playMissAnimationsForPlayerKey)
end

local function onInit()
    playMissAnimationsForPlayer = SettingsConstants.readSetting(playerSection,
        SettingsConstants.playMissAnimationsForPlayerKey)
end

return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onFrame = onFrame,
    },
    eventHandlers = {
        OMWMusicCombatTargetsChanged = onCombatTargetChanged,
    }
}
