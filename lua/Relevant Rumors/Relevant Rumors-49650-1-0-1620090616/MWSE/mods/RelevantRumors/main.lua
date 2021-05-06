local config = {}
local cache = require("RelevantRumors.cache")
local checks = require("RelevantRumors.checks")
local debug = require("RelevantRumors.debug")

local RUMOR_CHANCE = 50
local DEBUG = false

local MOD_NAME = 'Relevant Rumors.esp'
local QUEST_COMPLETED_INDEX = 100
local shouldInvalidateCache = false
local prevResponseGlobalVarName = nil

local responseLastUsedAt = {}

local function printDebugMessage(title, value, skipNilValue)
    if (not DEBUG) then
        return
    end

    print("[Relevant Rumors] " .. title)

    if (value == nil and skipNilValue) then
        return
    end

    print(debug.to_string(value) .. "\n")
end

local function getQuestRumor(questId, filters)
    local responsesPool = config.responses[questId]

    for responseIndex, responseMeta in pairs(responsesPool) do
        local responseMatches = true
        for index, condition in pairs(responseMeta.conditions) do
            local checkType = condition.type
            local conditionMatches = false
            if (checkType == 'cell') then
                conditionMatches = checks.checkCell(condition, filters.actorCell)
            elseif (checkType == 'faction') then
                local actorFaction = nil
                if (filters.actor.faction) then
                    actorFaction = filters.actor.faction.id
                end
                conditionMatches = checks.checkFaction(condition, actorFaction)
            elseif (checkType == 'dead') then
                conditionMatches = checks.checkDead(condition)
            elseif (checkType == 'questCompleted') then
                conditionMatches = checks.checkQuestCompleted(condition)
            elseif (checkType == 'journal') then
                conditionMatches = checks.checkJournalStage(condition)
            elseif (checkType == 'pcSex') then
                conditionMatches = checks.checkPCSex(condition)
            elseif (checkType == 'pcRank') then
                conditionMatches = checks.checkPCRank(condition)
            elseif (checkType == 'pcRankDifference') then
                conditionMatches = checks.checkPCRankDifference(condition, filters.actor)
            else
            end
            -- printDebugMessage("Check '" .. checkType .. "':", conditionMatches)
            responseMatches = responseMatches and conditionMatches
        end

        if (responseMatches == true) then
            printDebugMessage("Matching response for " .. responseMeta.id .. ":", responseIndex)
            return responseIndex
        end
    end

    return nil
end

local function getGlobalVarName(questId)
    return "RE_" .. questId .. "_Response"
end

local function randomizeResponse(responseCandidates)
    if (not responseCandidates) then
        return nil
    end

    local leastRecentUsageTime = os.clock()
    local selectedResponseIndex = nil

    for idx, responseCandidate in pairs(responseCandidates) do
        local lastUsageTime = responseLastUsedAt[getGlobalVarName(responseCandidate.questId)]

        if (lastUsageTime == nil) then
            lastUsageTime = 0
        end

        if (lastUsageTime <= leastRecentUsageTime) then
            leastRecentUsageTime = lastUsageTime
            selectedResponseIndex = idx
        end
    end

    printDebugMessage("Response candidates", responseCandidates)
    printDebugMessage("Last usage time", responseLastUsedAt)
    printDebugMessage("Least recent response index", selectedResponseIndex)

    if (selectedResponseIndex == nil) then
        selectedResponseIndex = math.random(table.size(responseCandidates))
    end

    return responseCandidates[selectedResponseIndex]
end

local function getResponseCandidates(mobileActor)
    local responseCandidates = {}
    local responseCandidatesCount = 1
    local actorCell = mobileActor.cell.id

    for questId, questResponses in pairs(config.responses) do
        local isCompleted = tes3.getJournalIndex({
            id = questId
        }) >= QUEST_COMPLETED_INDEX

        if (isCompleted) then
            local questRumorIndex = getQuestRumor(questId, {
                actor = mobileActor.object,
                actorCell = actorCell
            })
            if (questRumorIndex) then
                responseCandidates[responseCandidatesCount] = {}
                responseCandidates[responseCandidatesCount].index = questRumorIndex
                responseCandidates[responseCandidatesCount].questId = questId
                responseCandidatesCount = responseCandidatesCount + 1
            end
        end
    end

    return responseCandidates
end

local function resetGlobals()
    for questId, questResponses in pairs(config.responses) do
        tes3.setGlobal(getGlobalVarName(questId), 0)
    end
end

local function onLoaded(e)
    resetGlobals()
    shouldInvalidateCache = true
end

local function onJournalUpdate(e)
    if (e.index >= QUEST_COMPLETED_INDEX) then
        shouldInvalidateCache = true
    end
end

local function pickRandomRumor(e)
    if (not e.newlyCreated) then
        return
    end

    if (prevResponseGlobalVarName) then
        tes3.setGlobal(prevResponseGlobalVarName, 0)
        prevResponseGlobalVarName = nil
    end

    if (shouldInvalidateCache) then
        cache.invalidate()
        shouldInvalidateCache = false
    end

    -- Only show random rumors with a set probability
    if (math.random(100) > RUMOR_CHANCE) then
        return nil
    end

    local menuDialog = e.element
    local mobileActor = menuDialog:getPropertyObject("PartHyperText_actor")
    local actorId = mobileActor.object.id

    local selectedResponse = nil

    if (cache.getResponsesPoolFromCache(actorId) == nil) then
        local responseCandidates = getResponseCandidates(mobileActor)

        cache.storeResponsesPoolInCache(actorId, responseCandidates)
    end

    selectedResponse = randomizeResponse(cache.getResponsesPoolFromCache(actorId))

    printDebugMessage("Selected response:", selectedResponse)

    if (selectedResponse) then
        local globalVarName = getGlobalVarName(selectedResponse.questId)
        prevResponseGlobalVarName = globalVarName
        tes3.setGlobal(globalVarName, selectedResponse.index)
    end
end

local function updateLastUsedResponse(e)
    if (e.info.sourceMod == MOD_NAME and prevResponseGlobalVarName) then
        responseLastUsedAt[prevResponseGlobalVarName] = os.clock()
    end
end

local function initialized()
    event.register("loaded", onLoaded)
    event.register("journal", onJournalUpdate)
    event.register("uiActivated", pickRandomRumor, {
        filter = "MenuDialog"
    })
    event.register("infoGetText", updateLastUsedResponse)

    printDebugMessage("Initializing...", nil, true)

    config = json.loadfile("mods/RelevantRumors/config")

    printDebugMessage("Initialized!", nil, true)
end

event.register("initialized", initialized)
