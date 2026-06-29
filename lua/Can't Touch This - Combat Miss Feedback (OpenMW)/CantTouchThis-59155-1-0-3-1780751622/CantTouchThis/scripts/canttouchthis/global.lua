---@omw-context global
local ACTOR_SCRIPT = 'scripts/canttouchthis/npc.lua'
local I = require('openmw.interfaces')


local function onCombatTargetChanged(eventData)
    if I.NGardeGlobal then return end
    if ACTOR_SCRIPT then
        if #eventData.targets > 0 then
            if not eventData.actor:hasScript(ACTOR_SCRIPT) then
                eventData.actor:addScript(ACTOR_SCRIPT)
                eventData.actor:sendEvent("canttouchthis_scriptAttached", eventData)
            end
        elseif #eventData.targets == 0 then
            if eventData.actor:hasScript(ACTOR_SCRIPT) then
                eventData.actor:sendEvent("canttouchthis_prepareDetach", eventData)
            end
        end
    end
end

local function onActorCleanedUp(eventData)
    while eventData.actor:hasScript(ACTOR_SCRIPT) do
        eventData.actor:removeScript(ACTOR_SCRIPT)
    end
end

return {
    eventHandlers = {
        canttouchthis_combatTargetChanged = onCombatTargetChanged,
        canttouchthis_actorCleanedUp = onActorCleanedUp,
    },
}
