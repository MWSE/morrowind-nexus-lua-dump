local core = require("openmw.core")

function QuestFinished(questId, player)
    return player.type.quests(player)[questId].finished
end

function GetFactionName(factions, questId)
    local questName = core.dialogue.journal.records[questId].questName

    -- weird, but ok
    if not questName then return nil end

    for factionName, _ in pairs(factions) do
        if string.find(questName, "^" .. factionName .. ":") then
            return factionName
        end
    end
    return nil
end

function AddCompletedQuest(completedQuests, factionName, questId, player)    
    if not completedQuests[factionName] then
        completedQuests[factionName] = {
            count = 0,
            quests = {}
        }
    end

    completedQuests[factionName].quests[questId] = true
    completedQuests[factionName].count = completedQuests[factionName].count + 1

    -- not used in the mod itself
    -- made for other mods to track if they need to
    local eventData = {
        player = player,
        factionName = factionName,
        questId = questId,
        questCount = completedQuests[factionName].count,
    }
    player:sendEvent("MoS_newFactionQuestCompleted", eventData)
    core.sendGlobalEvent("MoS_newFactionQuestCompleted", eventData)
end
