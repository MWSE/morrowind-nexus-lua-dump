---@omw-context global
local ACTOR_SCRIPT = 'scripts/canttouchthis/npc.lua'


local function onCombatTargetChanged(eventData)
    local targetScript = ACTOR_SCRIPT
    local scriptString = "ACTOR"

    if targetScript then
        if #eventData.targets > 0 then
            if not eventData.actor:hasScript(targetScript) then
                eventData.actor:addScript(targetScript)
            end
        elseif #eventData.targets == 0 then
            while eventData.actor:hasScript(targetScript) do
                eventData.actor:removeScript(targetScript)
            end
        end
    end
end

return {

    eventHandlers = {
        canttouchthis_combatTargetChanged = onCombatTargetChanged,
    },
}
