local include = require("scripts.quest_guider_lite.utils.include")

local tableLib = require("scripts.quest_guider_lite.utils.table")
local requirementChecker = require("scripts.quest_guider_lite.requirementChecker")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local myTypes = require("scripts.quest_guider_lite.types")
local cacheLib = require("scripts.quest_guider_lite.utils.cache")

local dataHandler
if include("openmw.self") then
    dataHandler = require("scripts.quest_guider_lite.storage.playerDataHandler")
else
    dataHandler = require("scripts.quest_guider_lite.storage.dataHandler")
end


local topicTestScripts = {
    ["t_sctest_topicstr1"] = true,
    ["t_sctest_topicstr2"] = true,
    ["t_sctest_topicstr3"] = true,
    ["t_sctest_topicstr4"] = true,
}


local this = {}



---@param questData string|questDataGenerator.questData
---@return integer[]|nil
function this.getIndexes(questData)
    if not questData then return end
    if type(questData) == "string" then
        questData = dataHandler.getQuestData(questData) ---@diagnostic disable-line: cast-local-type
    end
    if not questData then return end

    local indexes = {}
    for ind, _ in pairs(questData) do
        local indInt = tonumber(ind)
        if indInt then
            table.insert(indexes, indInt)
        end
    end
    table.sort(indexes)
    return indexes
end

---@param questData string|questDataGenerator.questData
---@return integer|nil
function this.getFirstIndex(questData)
    local indexes = this.getIndexes(questData)
    if not indexes or #indexes == 0 then return end

    return indexes[1]
end

---@param questData string|questDataGenerator.questData
---@param quesId string?
---@param questIndex integer|string
---@param params {findInLinked: boolean?, findCompleted: boolean?}?
---@return integer[]?
---@return table<string, {index: integer, qData: questDataGenerator.questData}>?
---@return table<string, integer>?
function this.getNextIndexes(questData, quesId, questIndex, params, player)
    if not params then params = {} end
    if not questData then return end
    if type(questData) == "string" then
        questData = dataHandler.getQuestData(questData) ---@diagnostic disable-line: cast-local-type
    end
    if not questData then return end

    local tpData = questData[tostring(questIndex)]

    if tpData and tpData.finished then
        return
    end

    local plIndex = params.findCompleted == false and playerQuests.getCurrentIndex(quesId or "", player) or -1
    plIndex = plIndex or -1

    ---@type table<string, {index: integer, qData: questDataGenerator.questData}>
    local linkedNext

    if params.findInLinked and questData.links then
        for _, linkedId in pairs(questData.links) do
            local linkData = dataHandler.getQuestData(linkedId)
            if not linkData then goto continue end

            local firstIndex = this.getFirstIndex(linkData)
            if not firstIndex then goto continue end
            local linkRequirements = linkData[tostring(firstIndex)]
            if not linkRequirements then goto continue end

            if params.findCompleted == false and (playerQuests.getCurrentIndex(linkedId, player) or 0) ~= 0 then
                goto continue
            end

            local valid = false
            for _, block in pairs(linkRequirements.requirements) do
                valid = valid or requirementChecker.checkBlock(block, {
                    allowedTypes = {
                        [myTypes.requirementType.Journal] = true,
                    },
                    threatErrorsAs = true,
                }, player)
                if valid then break end
            end

            if valid then
                linkedNext = linkedNext or {}
                linkedNext[linkedId] = {index = firstIndex, qData = linkData}
            end

            ::continue::
        end
    end

    if not tpData and not linkedNext then
        local intQuestIndex = tonumber(questIndex)
        if intQuestIndex then
            local indexes = this.getIndexes(questData) or {}
            for i = #indexes, 1, -1 do
                local index = indexes[i]
                if index and index < intQuestIndex then
                    tpData = questData[tostring(index)]
                    break
                end
            end
        end
        if not tpData or tpData.finished then return end
    end

    if not tpData then return nil, linkedNext end

    local linkedMap = {}
    local checkedIndexes = {}
    local function checkIndex(ind, advancedChecks)
        if checkedIndexes[ind] ~= nil then return checkedIndexes[ind] end

        local dt = questData[tostring(ind)]
        if dt then
            local isPossible = not next(dt.requirements) and true or false
            for _, bl in pairs(dt.requirements or {}) do
                if not requirementChecker.isBlockCompletionPossible(bl, nil, player) then
                    isPossible = isPossible or false
                else
                    for _, linkDt in pairs(dt.linked or {}) do
                        linkedMap[linkDt[1]] = math.min(linkedMap[linkDt[1]] or math.huge, linkDt[2])
                    end

                    if advancedChecks then
                        local res = requirementChecker.checkBlock(bl, {
                            threatErrorsAs = true,
                            allowedTypes = {
                                [myTypes.requirementType.Journal] = true,
                                [myTypes.requirementType.RankRequirement] = true,
                                [myTypes.requirementType.CustomPCRank] = true,
                                [myTypes.requirementType.CustomPCFaction] = true,
                            }
                        }, player)

                        isPossible = res or false
                    else
                        isPossible = true
                    end
                end

                if isPossible then
                    checkedIndexes[ind] = true
                    return true
                end
            end

            if not isPossible then
                checkedIndexes[ind] = false
                return false
            end
        end

        checkedIndexes[ind] = false
        return false
    end

    local nextIndexes = {}
    if tpData.next then
        for _, ind in pairs(tpData.next) do
            if plIndex < ind and checkIndex(ind) then
                nextIndexes[ind] = true
            end
        end
    end

    if tpData.nextIndex and plIndex < tpData.nextIndex and checkIndex(tpData.nextIndex, true) then
        nextIndexes[tpData.nextIndex] = true
    end

    if not next(nextIndexes) then
        checkedIndexes = {}
        local indexes = this.getIndexes(questData)

        for _, ind in ipairs(indexes) do
            if ind > plIndex and checkIndex(ind) then
                nextIndexes[ind] = true
                break
            end
        end
    end

    -- for cases where there are requirements with dialogues that are impossible to obtain
    if dataHandler.info.version >= 8 then
        for ind, _ in pairs(nextIndexes) do
            local dt = questData[tostring(ind)]
            if not dt then goto continue end

            for _, bl in pairs(dt.requirements or {}) do
                local diaId = myTypes.getActorDialogueIdFromBlock(bl)
                if not diaId then goto continue end

                local diaDt = dataHandler.getObjectData(diaId)
                if diaDt then
                    if diaDt.links and (#diaDt.links > 1 or not topicTestScripts[diaDt.links[1][1] or ""]) then
                        goto continue
                    end
                else
                    goto continue
                end
            end

            for _, nInd in pairs(dt.next or {}) do
                if plIndex < nInd and not checkedIndexes[nInd] and checkIndex(nInd) then
                    nextIndexes[nInd] = true
                end
            end
            if dt.nextIndex and plIndex < dt.nextIndex and not checkedIndexes[dt.nextIndex] and checkIndex(dt.nextIndex) then
                nextIndexes[dt.nextIndex] = true
            end

            ::continue::
        end
    end

    local nextIndexKeys = tableLib.keys(nextIndexes)

    if #nextIndexKeys == 0 then return nil, linkedNext end

    table.sort(nextIndexKeys)

    return nextIndexKeys, linkedNext, linkedMap
end


---@param questId string
---@param questIndex integer|string
---@param ref any?
---@param player any?
---@param params {handleCustomActorReq: boolean?}?
---@return boolean?
function this.checkConditionsForQuest(questId, questIndex, ref, player, params)
    params = params or {}
    local questData = dataHandler.getQuestData(questId)
    if not questData then return end

    local indexStr = tostring(questIndex)
    local stageData = questData[indexStr]
    if not stageData then return end

    local requirements = stageData.requirements or {}

    if #requirements == 0 then return true end

    if not ref then

        local allowedTypes = {
            [myTypes.requirementType.Journal] = true,
            [myTypes.requirementType.CustomPCFaction] = true,
            [myTypes.requirementType.CustomPCRank] = true,
            [myTypes.requirementType.CustomGlobal] = true,
            [myTypes.requirementType.Dead] = true,
            [myTypes.requirementType.CustomOnDeath] = true,
            [myTypes.requirementType.Item] = true,
        }

        for _, reqBlock in pairs(stageData.requirements or {}) do
            local ret = requirementChecker.checkBlock(reqBlock, {
                allowedTypes = allowedTypes,
                threatErrorsAs = true,
            }, player)

            if ret then
                return true
            end
        end

    else
        local ignoredTypes = {
            [myTypes.requirementType.CustomDisposition] = true,
            [myTypes.requirementType.CustomDialogue] = true,
            [myTypes.requirementType.CustomDisposition] = true,
            [myTypes.requirementType.NPCReputation] = true,
        }

        local truthTable = {
            [myTypes.requirementType.PreviousDialogChoice] = true,
        }

        for _, reqBlock in pairs(stageData.requirements or {}) do
            local ret = requirementChecker.checkBlock(reqBlock, {
                ignoredTypes = ignoredTypes,
                threatErrorsAs = true,
                reference = ref,
                handleCustomActorReq = params.handleCustomActorReq,
            }, player)

            if ret then return true end
        end

    end

    return false
end


---@param diaId string
---@return table<string, questDataGenerator.questData>
function this.getQuestMainDialogueIdsMap(diaId)
    local diaIdLower = diaId:lower()

    local cachedVal = cacheLib.get("mainDiaIds", diaId)
    if cachedVal ~= nil then return cachedVal end

    local questData = dataHandler.getQuestData(diaIdLower)
    if not questData then return {} end

    local out = {}

    if not questData.links then
        out[diaId] = questData
        cacheLib.set("mainDiaIds", diaId, out)
        return out
    end

    local questDias = {}

    local function addDia(id, qDt)
        local indexes = this.getIndexes(qDt) or {}
        local indCnt = #indexes

        table.insert(questDias, {id = id, qd = qDt, ind = indexes, indCnt = indCnt})
    end

    addDia(diaIdLower, questData)

    for _, link in pairs(questData.links) do
        local linkDt = dataHandler.getQuestData(link)
        if not linkDt then goto continue end

        addDia(link, linkDt)

        ::continue::
    end

    local diaCount = #questDias
    if diaCount == 1 then
        out[questDias[1].id] = questDias[1].qd
        cacheLib.set("mainDiaIds", diaId, out)
        return out
    end

    table.sort(questDias, function (a, b)
        return a.indCnt > b.indCnt
    end)

    local hasFinished = false
    local firstStageCount

    for i, dt in ipairs(questDias) do
        local first = dt.qd[tostring(dt.ind[1] or "")]
        if first and first.restart and dt.indCnt > 1 then
            out[dt.id] = dt.qd
        else
            firstStageCount = firstStageCount or dt.indCnt
        end
    end

    firstStageCount = firstStageCount or 0

    for i = diaCount, 1, -1 do
        local dt = questDias[i]
        if dt then
            if dt.indCnt * 2 <= firstStageCount or dt.indCnt <= 1 then
                questDias[i] = nil
            else
                hasFinished = dt.qd.hasFinished or hasFinished
            end
        end
    end

    diaCount = #questDias
    if diaCount == 1 then
        out[questDias[1].id] = questDias[1].qd
        cacheLib.set("mainDiaIds", diaId, out)
        return out
    end

    if hasFinished then
        for _, dt in pairs(questDias) do
            if dt.qd.hasFinished then
                out[dt.id] = dt.qd
            end
        end
    else
        for _, dt in pairs(questDias) do
            out[dt.id] = dt.qd
        end
    end


    cacheLib.set("mainDiaIds", diaId, out)
    return out
end


---@return table<string, boolean>?
---@return boolean? isGiver
---@return boolean? activatedByScript
function this.getGiverQuests(ref, player)
    local diaIds = {}
    local activatedByScript
    local isGiver = false

    local function checkId(id, byScript)
        if not id then return end

        local objectData = dataHandler.getObjectData(id)
        if not objectData or not objectData.starts then return end

        isGiver = true

        for _, diaId in pairs(objectData.starts) do
            local diaIdLower = diaId:lower()

            if not this.getQuestMainDialogueIdsMap(diaIdLower)[diaIdLower] then goto continue end

            if (playerQuests.getCurrentIndex(diaIdLower, player) or 0) > 0 then goto continue end

            local questData = dataHandler.getQuestData(diaIdLower)
            if not questData or not questData.name then goto continue end

            for _, linkId in pairs(questData.links or {}) do
                if (playerQuests.getCurrentIndex(linkId, player) or 0) > 0 then goto continue end
            end

            local firstIndexStr = this.getFirstIndex(questData)
            if not firstIndexStr then goto continue end
            if not this.checkConditionsForQuest(diaIdLower, firstIndexStr, ref, player, {handleCustomActorReq = true}) then
                goto continue
            end

            diaIds[diaId] = true
            if byScript then
                activatedByScript = true
            end

            ::continue::
        end
    end

    checkId(ref.recordId)
    local object = ref.type.record(ref.recordId)
    if object and object.mwscript and object.mwscript ~= "" then
        checkId(object.mwscript, true)
    end

    if not next(diaIds) then return nil, isGiver, activatedByScript end
    return diaIds, true, activatedByScript
end


---@param reqBlock questDataGenerator.requirementBlock
---@return string? diaId
---@return string? index
---@return string? actorId
---@return string[]? indexChain
function this.getReqBlockPrimeDialogueId(reqBlock)
    local links = {}
    local mainDiaId
    local mainDiaIndex
    local actorId
    for _, req in pairs(reqBlock) do
        if req.type == myTypes.requirementType.CustomDialogue then
            mainDiaId = stringLib.convertDialogueName(req.variable)
            mainDiaIndex = req.value
        elseif req.type == myTypes.requirementType.CustomDialogueChoiceLink then
            links[req.value] = req.variable
        elseif req.type == myTypes.requirementType.CustomActor then
            actorId = req.object
        end
    end

    if not mainDiaId or not mainDiaIndex then return end

    local indexChain = {mainDiaIndex}

    local function findFirst(depth)
        if depth <= 0 then return end
        depth = depth - 1

        if links[mainDiaIndex] then
            mainDiaIndex = links[mainDiaIndex]
            table.insert(indexChain, mainDiaIndex)
            findFirst(depth)
        end
    end
    findFirst(10)

    return mainDiaId, mainDiaIndex, actorId, indexChain ---@diagnostic disable-line: return-type-mismatch
end


---@param diaId string
---@param index string|integer|nil
---@return {diaId: string, topicId: string, actorId: string?, indexChain: string[]?}[]?
function this.getQuestDiaPrimeDialogueIds(diaId, index)
    local questData = dataHandler.getQuestData(diaId)
    if not questData then return end

    local out = {}
    local ind = index or this.getFirstIndex(questData)
    if not ind then return end

    local indexData = questData[tostring(ind)]
    if not indexData then return end

    for _, reqBlock in pairs(indexData.requirements or {}) do
        local mainDiaId, mainDiaIndex, actorId, indexChain = this.getReqBlockPrimeDialogueId(reqBlock)
        if mainDiaId and mainDiaIndex then
            table.insert(out, {diaId = mainDiaId, topicId = mainDiaIndex, actorId = actorId, indexChain = indexChain})
        end
    end

    if not next(out) then return end

    return out
end



return this