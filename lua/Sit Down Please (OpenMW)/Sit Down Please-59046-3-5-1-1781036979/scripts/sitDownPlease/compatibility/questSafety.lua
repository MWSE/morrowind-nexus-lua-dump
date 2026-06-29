-- compatibility/questSafety.lua
---@omw-context none
-- Quest-sensitive actor exclusions for vanilla/scripted actors that are unsafe
-- only while a specific quest handoff or teleport routine is active.

local M = {}

local QUEST_ACTOR_RULES = {
    ["mehra milo"] = {
        questId = "A2_4_MiloGone",
        minStage = 1,
        maxStageExclusive = 50,
        reason = "quest_travel_actor",
    },
    ["varvur sarethi"] = {
        questId = "HR_RescueSarethi",
        minStage = 0,
        maxStageExclusive = 70,
        blockWhenStageMissing = true,
        reason = "quest_rescue_actor",
    },
    ["drarayne thelas"] = {
        questId = "FG_RatHunt",
        minStage = 0,
        maxStageExclusive = 100,
        blockWhenStageMissing = true,
        reason = "quest_rat_hunt_actor",
    },
}

local function normalizeId(value)
    if value == nil then return nil end
    local text = string.lower(tostring(value))
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return nil end
    return text
end

local function actorRecordId(actor)
    return normalizeId(actor and (actor.recordId or actor.id))
end

function M.questStage(typesApi, player, questId)
    if not (typesApi and typesApi.Player and type(typesApi.Player.quests) == "function" and player and questId) then
        return nil
    end
    local ok, quests = pcall(typesApi.Player.quests, player)
    if not ok or quests == nil then return nil end
    local quest = nil
    pcall(function() quest = quests[questId] end)
    if quest == nil then
        pcall(function() quest = quests[string.lower(tostring(questId))] end)
    end
    local stage = quest and tonumber(quest.stage)
    return stage
end

function M.questActorRuleReason(recordId, typesApi, player)
    local rule = QUEST_ACTOR_RULES[normalizeId(recordId)]
    if not rule then return nil end

    local stage = M.questStage(typesApi, player, rule.questId)
    if stage == nil then
        return rule.blockWhenStageMissing == true and (rule.reason or "quest_travel_actor") or nil
    end

    local minStage = tonumber(rule.minStage) or 0
    local maxStage = tonumber(rule.maxStageExclusive)
    if stage < minStage then return nil end
    if maxStage and stage >= maxStage then return nil end
    return rule.reason or "quest_travel_actor"
end

function M.questActorReason(actor, typesApi, player)
    return M.questActorRuleReason(actorRecordId(actor), typesApi, player)
end

return M
