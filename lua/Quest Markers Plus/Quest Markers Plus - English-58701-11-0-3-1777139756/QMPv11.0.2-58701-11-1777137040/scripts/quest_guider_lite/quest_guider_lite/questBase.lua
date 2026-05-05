local include = require("scripts.quest_guider_lite.utils.include")

local tableLib = require("scripts.quest_guider_lite.utils.table")
local requirementChecker = require("scripts.quest_guider_lite.requirementChecker")
local dialogueChecker = require("scripts.quest_guider_lite.dialogueChecker")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local myTypes = require("scripts.quest_guider_lite.types")

local dataHandler
if include("openmw.self") then
    dataHandler = require("scripts.quest_guider_lite.storage.playerDataHandler")
else
    dataHandler = require("scripts.quest_guider_lite.storage.dataHandler")
end


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
function this.getNextIndexes(questData, quesId, questIndex, params)
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

    local plIndex = params.findCompleted == false and playerQuests.getCurrentIndex(quesId or "") or -1
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

            if params.findCompleted == false and (playerQuests.getCurrentIndex(linkedId) or 0) ~= 0 then
                goto continue
            end

            local valid = false
            for _, block in pairs(linkRequirements.requirements) do
                valid = valid or requirementChecker.checkBlock(block, {
                    allowedTypes = {
                        [myTypes.requirementType.Journal] = true,
                    },
                    threatErrorsAs = true,
                })
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
        for i, index in ipairs(this.getIndexes(questData) or {}) do
            if intQuestIndex and index > intQuestIndex then
                tpData = questData[tostring(index)]
                break
            end
        end
        if not tpData or tpData.finished then return end
    end

    if not tpData then return nil, linkedNext end

    local nextIndexes = {}
    local foundNextIndex = false
    if tpData.next then
        for _, ind in pairs(tpData.next) do
            if plIndex < ind then
                nextIndexes[ind] = true
                foundNextIndex = true
            end
        end
    end
    if not foundNextIndex and tpData.nextIndex and not (plIndex >= tpData.nextIndex) then
        nextIndexes[tpData.nextIndex] = true
    end

    -- adds the next sequential index if its requirements are met
    if tableLib.count(nextIndexes) == 1 and not nextIndexes[tpData.nextIndex] then
        ---@type questDataGenerator.stageData
        local nextIndexData = questData[tostring(tpData.nextIndex)]
        if nextIndexData then
            local valid = false
            for _, block in pairs(nextIndexData.requirements) do
                valid = valid or requirementChecker.checkBlock(block, {
                    ignoredTypes = {
                        [myTypes.requirementType.CustomDisposition] = true,
                        [myTypes.requirementType.CustomDialogue] = true,
                    },
                    threatErrorsAs = true,
                })
                if valid then break end
            end

            if valid then
                nextIndexes[tpData.nextIndex] = true
            end
        end
    end

    local nextIndexKeys = tableLib.keys(nextIndexes)

    if #nextIndexKeys == 0 then return nil, linkedNext end

    table.sort(nextIndexKeys)

    return nextIndexKeys, linkedNext
end


---@param questId string
---@param questIndex integer|string
---@param ref any?
---@param player any?
---@return boolean?
function this.checkConditionsForQuest(questId, questIndex, ref, player)
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
            }, player)

            if ret then return true end

            -- if ret then
            --     local foundDiaReq = false
            --     for _, req in pairs(reqBlock) do
            --         if req.type == myTypes.requirementType.CustomDialogue then
            --             foundDiaReq = true
            --             local diaId = stringLib.convertDialogueName(req.variable)
            --             local infoId = req.value

            --             local checkerRes = dialogueChecker.isDialogueTopicAvailable(ref, diaId, infoId, {
            --                 skipDisposition = true,
            --                 checkBlockOptions = {
            --                     ignoredTypes = ignoredTypes,
            --                     typeTruthTable = truthTable,
            --                     threatErrorsAs = false,
            --                 }
            --             })

            --             if checkerRes then return true end
            --             break
            --         end
            --     end

            --     if not foundDiaReq then
            --         return true
            --     end
            -- end
        end

    end

    return false
end


---@return table<string, boolean>?
function this.getGiverQuests(object, player)
    local objectData = dataHandler.getObjectData(object.recordId)
    if not objectData or not objectData.starts then return end

    local diaIds = {}

    for _, diaId in pairs(objectData.starts) do
        local diaIdLower = diaId:lower()
        if (playerQuests.getCurrentIndex(diaIdLower, player) or 0) > 0 then goto continue end

        local questData = dataHandler.getQuestData(diaIdLower)
        if not questData or not questData.name then goto continue end

        for _, linkId in pairs(questData.links or {}) do
            if (playerQuests.getCurrentIndex(linkId, player) or 0) > 0 then goto continue end
        end

        local firstIndexStr = this.getFirstIndex(questData)
        if not firstIndexStr then goto continue end
        if not this.checkConditionsForQuest(diaIdLower, firstIndexStr, object, player) then
            goto continue
        end

        diaIds[diaId] = true

        ::continue::
    end

    if not next(diaIds) then return end
    return diaIds
end


return this