local self = require("openmw.self")

require("scripts.MeritsOfService.utils.consts")
require("scripts.MeritsOfService.logic.quests")
require("scripts.MeritsOfService.logic.stats")

local factions = require("scripts.MeritsOfService.utils.factionParser")

local function onQuestUpdate(questId, stage)
    local factionName = GetFactionName(factions, questId)

    -- init faction if it's a new one
    if factionName and not CompletedQuests[factionName] then
        CompletedQuests[factionName] = {
            count = 0,
            quests = {}
        }
    end

    if not QuestFinished(questId, self)
        or not factionName
        or CompletedQuests[factionName].quests[questId]
    then
        return
    end

    AddCompletedQuest(CompletedQuests, factionName, questId)
    GrantStats(self, factions, factionName, CompletedQuests[factionName].count)
end

local function onSave()
    return CompletedQuests
end

local function onLoad(saveData)
    CompletedQuests = saveData
end

local function retroactiveUpdate()
    for questId, _ in pairs(self.type.quests(self)) do
        onQuestUpdate(questId, nil)
    end
end

return {
    engineHandlers = {
        onQuestUpdate = onQuestUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
    interfaceName = "MeritsOfService",
    interface = {
        version = 1,
        RetroactiveUpdate = retroactiveUpdate,
    },
}
