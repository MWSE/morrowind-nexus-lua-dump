local core = require("openmw.core")

require("scripts.DeadMerTellNoTales.utils.consts")

local function onQuestUpdate(questId, stage)
    local questMovedNPC = NPCMovedInsteadOfDisabled[questId]
    if not (questMovedNPC and stage >= questMovedNPC.stage) then return end
    core.sendGlobalEvent("recordDead", questMovedNPC.actor)
end

return {
    engineHandlers = {
        onQuestUpdate = onQuestUpdate
    }
}
