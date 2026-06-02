---@omw-context player
local core      = require('openmw.core')
local types     = require('openmw.types')
local Constants = require('scripts.canttouchthis.helpers.constants')
local Helpers   = require('scripts.canttouchthis.helpers.helpers')


--redirecting the event to the global script, so we can attach/detach actor scripts
local function onCombatTargetChanged(eventData)
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

return {
    eventHandlers = {
        OMWMusicCombatTargetsChanged = onCombatTargetChanged,
    }
}
