local log = include("diject.quest_guider.utils.log")
local tableLib = include("diject.quest_guider.utils.table")
local stringLib = include("diject.quest_guider.utils.string")
local cellLib = include("diject.quest_guider.cell")
local randomLib = include("diject.quest_guider.utils.random")

local config = include("diject.quest_guider.config")

local types = include("diject.quest_guider.types")
local descriptionLines = include("diject.quest_guider.descriptionLines")
local otherTypes = include("diject.quest_guider.Types.other")

local dataHandler = include("diject.quest_guider.dataHandler")
local playerQuests = include("diject.quest_guider.playerQuests")
local requirementChecker = include("diject.quest_guider.requirementChecker")

local this = {}

local weaponTypeNameById = otherTypes.weaponTypeNameById
local magicEffectConsts = otherTypes.magicEffectConsts
local vampireClan = otherTypes.vampireClan

local weatherById = {}

for name, id in pairs(tes3.weather) do
    weatherById[id] = name
end


local disallowedRequirementTypes = {
    -- ["SCR"] = true
}


local filterForHandledReqBlock = {
    [types.requirementType.Dead] = true,
    [types.requirementType.Journal] = true,
    [types.requirementType.RankRequirement] = true,
    [types.requirementType.PlayerRankMinusNPCRank] = true,
    [types.requirementType.Item] = true,
    [types.requirementType.CustomOnDeath] = true,
}



---@param questId string
---@return questDataGenerator.questData|nil
function this.getQuestData(questId)
    return dataHandler.quests[questId:lower()]
end

---@param objectId string
---@return questDataGenerator.objectPosition[]|nil
function this.getObjectPositionData(objectId)
    local objData = dataHandler.questObjects[objectId:lower()]
    if not objData then return end
    return objData.positions
end

---@param objectId string
---@return questDataGenerator.objectInfo
function this.getObjectData(objectId)
    return dataHandler.questObjects[objectId:lower()]
end

function this.removeSpecialCharactersFromJournalText(text)
    return text:gsub("@", ""):gsub("#", "")
end

function this.removeNewLines(text)
    return text:gsub("\n", " ")
end

---@param text string
---@return questDataGenerator.questTopicInfo[]|nil
function this.getQuestInfoByJournalText(text)
    local str = this.removeNewLines(text)
    local strClear = this.removeSpecialCharactersFromJournalText(str)
    return dataHandler.questByText[strClear] or dataHandler.questByText[str] or dataHandler.questByText[str:sub(1, -2)]
end

---@param scriptName string
---@return table<string, questDataGenerator.localVariableData>|nil
function this.getLocalVariableDataByScriptName(scriptName)
    return dataHandler.localVariablesByScriptId[scriptName:lower()]
end

---@param questData string|questDataGenerator.questData
---@return integer[]|nil
function this.getIndexes(questData)
    if not questData then return end
    if type(questData) == "string" then
        questData = this.getQuestData(questData)
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
---@return string[]?
---@return table<string, {index: integer, qData: questDataGenerator.questData}>?
function this.getNextIndexes(questData, quesId, questIndex, params)
    if not params then params = {} end
    if not questData then return end
    if type(questData) == "string" then
        questData = this.getQuestData(questData)
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
            local linkData = this.getQuestData(linkedId)
            if not linkData then goto continue end

            local firstIndex = this.getFirstIndex(linkData)
            if not firstIndex then goto continue end
            local linkRequirements = linkData[tostring(firstIndex)]
            if not linkRequirements then goto continue end

            if params.findCompleted == false and playerQuests.getCurrentIndex(linkedId) ~= 0 then
                goto continue
            end

            local valid = false
            for _, block in pairs(linkRequirements.requirements) do
                valid = valid or requirementChecker.checkBlock(block, {
                    allowedTypes = {
                        [types.requirementType.Journal] = true,
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

    nextIndexes = table.keys(nextIndexes)

    if #nextIndexes == 0 then return nil, linkedNext end

    table.sort(nextIndexes)

    return nextIndexes, linkedNext
end


---@param tb {[1] : string} table with object ids
---@return table<string, string> out name by object id
---@return integer count
function this.getObjectNamesFromLinkTable(tb)
    local out = {}
    local count = 0
    for _, tbDt in pairs(tb or {}) do
        local id = tbDt[1]
        local dt = dataHandler.questObjects[id]
        if dt and (dt.type <= 2) then
            local obj = tes3.getObject(id)
            if obj and obj.name then
                out[id] = obj.name
            else
                out[id] = id
            end
            count = count + 1
        end
    end

    return out, count
end



--#################################################################################################

---@param dialogue tes3dialogue
---@return boolean?
local function isDialogueAvailable(dialogue)
    if not tes3.mobilePlayer then return end
    for _, dia in pairs(tes3.mobilePlayer.dialogueList) do
        if dialogue == dia then
            return true
        end
    end
    return false
end


---@class questGuider.quest.getDescriptionDataFromBlock.returnArr
---@field str string description
---@field priority number
---@field objects table<string, string>|nil index and value are the same
---@field positionData table<string, questGuider.quest.getRequirementPositionData.returnData>?
---@field data questDataGenerator.requirementData
---@field reqDataForHandling questDataGenerator.requirementBlock? for requirementType.CustomActor type

---@alias questGuider.quest.getDescriptionDataFromBlock.return questGuider.quest.getDescriptionDataFromBlock.returnArr[]

---@param reqBlock questDataGenerator.requirementBlock
---@param questId string?
---@param customConfig questGuider.config?
---@return questGuider.quest.getDescriptionDataFromBlock.return|nil
function this.getDescriptionDataFromDataBlock(reqBlock, questId, customConfig)
    if not reqBlock then return end

    local configData = customConfig or config.data

    local function getName(obj, default)
        if obj and obj.id == "player" then
            return "the player"
        elseif obj and obj.name then
            return obj.name
        end
        return default or "???"
    end

    ---@type questGuider.quest.getDescriptionDataFromBlock.return
    local out = {}

    ---@type table<string, boolean>
    local checkedDialogObjects = {}

    ---@param requirement questDataGenerator.requirementData
    local function processRequirement(requirement)
        if disallowedRequirementTypes[requirement.type] then goto continue end

        if requirement.type == types.requirementType.Journal and requirement.variable == questId then
            goto continue
        end

        ---@type questGuider.quest.getDescriptionDataFromBlock.returnArr
        local reqOut = {str = "", priority = 0, data = requirement}

        if requirement.type == types.requirementType.CustomActor then
            reqOut.reqDataForHandling = requirementChecker.getFilterredRequirementBlock(reqBlock, filterForHandledReqBlock)
        elseif requirement.type == types.requirementType.Journal then
            local req = table.copy(requirement)
            req.operator = types.operator.value.Equal
            req.value = 0
            reqOut.reqDataForHandling = requirementChecker.getFilterredRequirementBlock({req}, filterForHandledReqBlock)
        elseif requirement.type == "DIAP" then
            reqOut.reqDataForHandling = requirementChecker.getFilterredRequirementBlock(
                {{operator = 49, type = types.requirementType.CustomDialogue, variable = requirement.variable}}
            )
        end

        local object = requirement.object
        local value = requirement.value
        local variable = requirement.variable
        local operator = requirement.operator
        local skill = requirement.skill
        local attribute = requirement.attribute
        local script = requirement.script
        local environment = {
            object = object,
            value = value,
            variable = variable,
            operator = operator,
            script = script,
            skill = skill,
            attribute = attribute,
            objectObj = nil,
            variableObj = nil,
            valueObj = nil,
            variableQuestName = "???",
            valueStr = "???",
            variableStr = "???",
            weaponTypeName = weaponTypeNameById,
            magicEffectConsts = magicEffectConsts,
        }
        if object then
            local objectObj = tes3.getObject(object)
            environment.objectObj = objectObj
        end
        if value then
            if type(value) == "string" then
                local obj = tes3.getObject(value)
                if obj then
                    environment.valueObj = obj
                    goto done
                end
                local cell = tes3.getCell{id = value}
                if cell then
                    environment.valueObj = cell
                    goto done
                end
                local region = tes3.findRegion{id = value}
                if region then
                    environment.valueObj = region
                    goto done
                end
                local faction = tes3.getFaction(value)
                if faction then
                    environment.valueObj = faction
                    goto done
                end
                local class = tes3.findClass(value)
                if class then
                    environment.valueObj = class
                    goto done
                end
                ::done::
            end
            environment.valueStr = tostring(value)
        end
        if variable then
            if type(variable) == "string" then
                local obj = tes3.getObject(variable)
                if obj then
                    environment.variableObj = obj
                    goto done
                end
                local cell = tes3.getCell{id = variable}
                if cell then
                    environment.variableObj = cell
                    goto done
                end
                local region = tes3.findRegion{id = variable}
                if region then
                    environment.variableObj = region
                    goto done
                end
                local faction = tes3.getFaction(variable)
                if faction then
                    environment.variableObj = faction
                    goto done
                end
                if dataHandler.quests[variable] then
                    environment.variableQuestName = dataHandler.quests[variable].name or "???"
                end
                ::done::
            end
            environment.variableStr = tostring(variable)
        end

        local reqStrDescrData = descriptionLines[requirement.type]
        if reqStrDescrData then
            local str = reqStrDescrData.str
            local mapped = {}
            for codeStr in string.gmatch(reqStrDescrData.str, "#(.-)#") do
                local pattern = "#"..codeStr.."#"
                if codeStr == "object" then
                    mapped[pattern] = tostring(environment.object or "???")
                elseif codeStr == "variable" then
                    mapped[pattern] = environment.variableStr
                elseif codeStr == "value" then
                    mapped[pattern] = environment.valueStr
                elseif codeStr == "varQuestName" then
                    mapped[pattern] = environment.variableQuestName
                elseif codeStr == "objectName" then
                    mapped[pattern] = getName(environment.objectObj)
                elseif codeStr == "valueName" then
                    mapped[pattern] = getName(environment.valueObj)
                elseif codeStr == "varName" then
                    mapped[pattern] = getName(environment.variableObj)
                elseif codeStr == "skillName" then
                    mapped[pattern] = environment.skill and (tes3.skillName[environment.skill] or "???") or "???"
                elseif codeStr == "attributeName" then
                    mapped[pattern] = environment.attribute and (tes3.attributeName[environment.attribute] or "???") or "???"
                elseif codeStr == "weaponType" then
                    mapped[pattern] = environment.value and (weaponTypeNameById[environment.value] or "???") or "???"
                elseif codeStr == "magicEffect" then
                    mapped[pattern] = magicEffectConsts[environment.variable] and tes3.getMagicEffect(magicEffectConsts[environment.variable]).name or environment.variable
                elseif codeStr == "classVar" then
                    mapped[pattern] = tes3.findClass(environment.variable) and tes3.findClass(environment.variable).name or environment.variable
                elseif codeStr == "classVal" then
                    mapped[pattern] = tes3.findClass(environment.value) and tes3.findClass(environment.value).name or environment.value
                elseif codeStr == "rankName" then
                    mapped[pattern] = environment.variableObj and environment.variableObj:getRankName(environment.value) or environment.value
                elseif codeStr == "vampClanVal" then
                    mapped[pattern] = vampireClan[environment.value] and vampireClan[environment.value] or tostring(environment.value)
                elseif codeStr == "weatherIdVal" then
                    mapped[pattern] = weatherById[environment.value] and weatherById[environment.value] or tostring(environment.value)
                elseif codeStr == "varNameOrTheActor" then
                    mapped[pattern] = getName(environment.variableObj, "the actor")
                elseif codeStr == "objNameOrTheActor" then
                    mapped[pattern] = getName(environment.objectObj, "the actor")
                elseif codeStr == "raceByIntValue" then
                    local race = tes3.dataHandler.nonDynamicData.races[environment.value]
                    mapped[pattern] = race and race.name or "???"
                elseif codeStr == "dialogueVariable" then
                    mapped[pattern] = environment.variableStr:sub(7)
                elseif codeStr == "dialogueValue" then
                    mapped[pattern] = environment.valueStr:sub(7)
                elseif codeStr == "operator" then
                    mapped[pattern] = types.operator.name[environment.operator]
                elseif codeStr == "notContr" then
                    mapped[pattern] = (value ~= nil and type(value) == "number") and
                        (((value==0 and operator==48) or (value==1 and operator==49) or (value==1 and operator==52) or (value==0 and operator==53)) and "n't" or "")
                        or ""
                elseif codeStr == "negNotContr" then
                    mapped[pattern] = (value ~= nil and type(value) == "number") and
                        (((value==1 and operator==48) or (value==0 and operator==49) or (value==0 and operator==50)) and "n't" or "")
                        or ""
                elseif codeStr == "scriptObjects" then
                    local res = ""
                    if environment.script then
                        local scrData = dataHandler.questObjects[environment.script]
                        if scrData and scrData.links then
                            local objs, count = this.getObjectNamesFromLinkTable(scrData.links)

                            if count > 0 then
                                res = stringLib.getValueEnumString(objs, configData.journal.objectNames, "%s")
                            end
                        end
                    end

                    if res == "" then
                        res = "???"
                    end
                    mapped[pattern] = res
                elseif codeStr == "objectsInScript" then
                    local res = ""
                    if environment.value then
                        local scrData = dataHandler.questObjects[environment.value]
                        if scrData and scrData.contains then
                            local objs, count = this.getObjectNamesFromLinkTable(scrData.contains)

                            if count > 0 then
                                res = stringLib.getValueEnumString(objs, configData.journal.objectNames, "%s")
                            end
                        end
                    end

                    if res == "" then
                        res = "???"
                    end
                    mapped[pattern] = res
                end
            end
            for pattern, ret in pairs(mapped) do
                str = str:gsub(pattern:gsub("%(", "."):gsub("%)", "."), ret)
            end

            local mapped = {}
            for codeStr in string.gmatch(str, "@(.-)@") do
                local pattern = "@"..codeStr.."@"
                local f, err = load("return "..codeStr, nil, nil, environment)
                if err then
                    log("pattern error", err, pattern, requirement)
                else
                    local fSuccess, fRet = pcall(f)
                    if not fSuccess then
                        log("pattern error", pattern, requirement)
                        fRet = "<error>"
                    end
                    mapped[pattern] = fRet or "???"
                end
            end
            for pattern, ret in pairs(mapped) do
                str = str:gsub(pattern:gsub("%(", "."):gsub("%)", "."), ret)
            end

            reqOut.str = str:gsub("^%l", string.upper)

            if reqStrDescrData.priority then
                reqOut.priority = reqStrDescrData.priority
            end
        else
            local reqCopy = table.copy(requirement)
            for reqDescr, reqId in pairs(types.requirementType) do
                if reqCopy.type == reqId then
                    reqCopy.type = reqDescr
                    break;
                end
            end
            reqCopy.operator = types.operator.name[reqCopy.operator] or reqCopy.operator
            reqOut.str = tableLib.tableToStrLine(reqCopy) or "???"
        end

        local objects = {}
        if environment.objectObj and environment.object then
            objects[environment.object] = environment.object
        end
        if environment.variableObj and environment.variable then
            objects[environment.variable] = environment.variable
        end
        if environment.valueObj and environment.value then
            objects[environment.value] = environment.value
        end
        if environment.script then
            local scrData = dataHandler.questObjects[environment.script]
            if scrData and scrData.links then
                for _, idDt in pairs(scrData.links) do
                    local linkData = dataHandler.questObjects[idDt[1]]
                    if linkData and (linkData.type <= 2) then
                        objects[idDt[1]] = idDt[1]
                    end
                end
            end
        end

        if table.size(objects) > 0 then
            reqOut.objects = objects
        end

        reqOut.positionData = this.getRequirementPositionData(requirement, configData)

        table.insert(out, reqOut)

        if requirement.type == types.requirementType.CustomScript and environment.script then
            local scrData = dataHandler.questObjects[environment.script]
            if scrData and scrData.contains then
                local objs, count = this.getObjectNamesFromLinkTable(scrData.contains)

                if count > 0 then
                    processRequirement({type = "SCR1", operator = 48, value = environment.script})
                end
            end
        end

        local function addDialogueData(objId)
            if not objId or checkedDialogObjects[objId] then return end
            checkedDialogObjects[objId] = true

            local objData = dataHandler.questObjects[objId]
            if not objData or objData.type > 2 then return end

            for _, linkDt in pairs(objData.links or {}) do
                local linkName = linkDt[1]
                local linkData = dataHandler.questObjects[linkName]
                if not linkData then goto continue end

                if linkData.type == 3 then
                    if requirement.type == types.requirementType.Item then
                        processRequirement({type = "DIAO", operator = operator, object = variable, variable = linkName, value = value})
                    else
                        processRequirement({type = "DIAO", operator = operator, variable = linkName})
                    end
                end

                ::continue::
            end
        end

        if requirement.type ~= "DIAO" then
            addDialogueData(environment.object)
            addDialogueData(environment.value)
            addDialogueData(environment.variable)
        end

        if requirement.type == types.requirementType.CustomDialogue and environment.variable then
            local foundData = {}

            local function findParentDialogues(recId, parentId, depth, dataChain)
                if depth <= 0 then return end

                if not dataChain then dataChain = {} end

                local recData = this.getObjectData(recId)
                if not recData then return end

                if recData.type == 3 then
                    local dialogue = tes3.findDialogue{ topic = string.sub(recId, 7) }
                    if not dialogue or dialogue.type ~= tes3.dialogueType.topic then return end

                    if not isDialogueAvailable(dialogue) then
                        for _, linkInfo in pairs(recData.links or {}) do
                            local chainDepth, chain = findParentDialogues(linkInfo[1], recId, depth - 1)
                            if chainDepth then
                                table.insert(foundData, {chainDepth, chain})
                            end
                        end
                    else
                        local chain = table.copy(dataChain)
                        table.insert(chain, {variable = parentId, value = recId})
                        return depth, chain
                    end
                elseif recData.type == 6 then
                    for _, linkInfo in pairs(recData.links or {}) do
                        local chainDepth, chain = findParentDialogues(linkInfo[1], parentId, depth - 1)
                        if chainDepth then
                            table.insert(foundData, {chainDepth, chain})
                        end
                    end
                end
            end

            local dialogue = tes3.findDialogue{ topic = string.sub(environment.variable, 7) }
            if not dialogue or dialogue.type ~= tes3.dialogueType.topic then goto continue end

            if not isDialogueAvailable(dialogue) then
                findParentDialogues(environment.variable, environment.variable, 6)

                if #foundData == 0 then goto continue end
                table.sort(foundData, function (a, b)
                    return a[1] < b[1]
                end)

                local minDepth = foundData[1][1]
                local addedDialogues = {}

                for _, data in pairs(foundData) do
                    if data[1] <= minDepth then
                        for _, chainDt in pairs(data[2]) do
                            if not addedDialogues[chainDt.variable] then
                                processRequirement({type = "DIAP", operator = 48, variable = chainDt.variable, value = chainDt.value})
                                addedDialogues[chainDt.variable] = true
                            end
                        end
                    else
                        break
                    end
                end
            end
        end

        ::continue::
    end

    for _, requirement in pairs(reqBlock) do
        processRequirement(requirement)
    end

    table.sort(out, function (a, b)
        return a.priority > b.priority
    end)

    return out
end


---@class questGuider.quest.getPlayerQuestData.returnArr
---@field id string
---@field name string|nil
---@field activeStage integer|nil
---@field isFinished boolean|nil
---@field isReachable boolean|nil

---@alias questGuider.quest.getPlayerQuestData.return questGuider.quest.getPlayerQuestData.returnArr[]

---@return questGuider.quest.getPlayerQuestData.return
function this.getPlayerQuestData()
    local out = {}

    local dialogueData = tes3.dataHandler.nonDynamicData.dialogues

    for _, dialogue in pairs(dialogueData) do
        if dialogue.type ~= tes3.dialogueType.journal then goto continue end

        local dialogueId = dialogue.id:lower()
        local storageData = dataHandler.quests[dialogueId]

        if not storageData then goto continue end

        ---@type questGuider.quest.getPlayerQuestData.returnArr
        local diaOutData = {} ---@diagnostic disable-line: missing-fields

        diaOutData.id = dialogueId
        diaOutData.name = storageData.name
        diaOutData.activeStage = dialogue.journalIndex
        diaOutData.isFinished = dialogue.journalIndex and storageData[tostring(dialogue.journalIndex)] and storageData[tostring(dialogue.journalIndex)].finished or nil

        table.insert(out, diaOutData)

        ::continue::
    end

    return out
end


---@param reqBlock table<integer, questDataGenerator.requirementData>
---@return boolean
function this.isContainsLocalVariableRequirement(reqBlock)
    for _, req in pairs(reqBlock) do
        if req.type == types.requirementType.CustomLocal then
            return true
        end
    end
    return false
end


---@class questGuider.quest.getRequirementPositionData.positionData
---@field description string 
---@field id string? cell id of the position
---@field position tes3vector3? coordinates of the position
---@field exitPos tes3vector3? coordinates in the game world of the entrance to the exterior cell that leads to the position
---@field doorPath tes3travelDestinationNode[]? list of doors to exit from the position
---@field cellPath tes3cell[]? list of cells to exit from the position
---@field rawData questDataGenerator.objectPosition|{id : string}|nil *id* is injected owner id, if it exists
---@field isExitEx boolean? true, if the exit is in an exterior cell

---@class questGuider.quest.getRequirementPositionData.returnData
---@field name string name of the object
---@field inWorld integer? number of instances of the object in the game world
---@field parentObject string?
---@field itemCount integer? item count from *types.requirementType.Item*
---@field actorCount integer? kill count from *types.requirementType.Dead*
---@field positions questGuider.quest.getRequirementPositionData.positionData[]

---@param requirement questDataGenerator.requirementData
---@param customConfig questGuider.config?
---@return table<string, questGuider.quest.getRequirementPositionData.returnData>? ret by object id
function this.getRequirementPositionData(requirement, customConfig)

    local configData = customConfig or config.data

    local trackingConfig = configData.tracking

    if requirement.type == types.requirementType.CustomDialogue then
        return
    end

    ---@type table<string, questGuider.quest.getRequirementPositionData.returnData>
    local out = {}

    local objects = {}
    ---@type table<tes3cell, string>
    local cells = {}

    local requirements = {requirement}

    if requirement.type == types.requirementType.Journal and playerQuests.isInitialized()
            and not ((requirement.operator == types.operator.value.Equal or requirement.operator == types.operator.value.LessOrEqual) and requirement.value == 0)
            and not (requirement.operator == types.operator.value.Less and requirement.value == 1) then
        local index = playerQuests.getCurrentIndex(requirement.variable or "")
        if not index or index == 0 then
            local qDt = this.getQuestData(requirement.variable)
            if qDt then
                local firstIndex = this.getFirstIndex(qDt)
                local stageData = qDt[tostring(firstIndex)]

                if stageData then
                    for _, block in pairs(stageData.requirements or {}) do
                        local isReqsValid = requirementChecker.checkBlock(block, {
                            threatErrorsAs = true,
                            allowedTypes = {
                                [types.requirementType.Journal] = true,
                                [types.requirementType.CustomPCFaction] = true,
                                [types.requirementType.CustomPCRank] = true,
                            }
                        })
                        if isReqsValid then
                            for _, req in pairs(block) do
                                table.insert(requirements, req)
                            end
                        end
                    end
                end
            end
        end
    end

    local function fillDataForScriptByTableName(scriptId, tableName)
        local scrData = dataHandler.questObjects[scriptId]
        if not scrData or not scrData[tableName] or not tes3.getScript(scriptId) then return end

        for _, linkDt in pairs(scrData[tableName]) do
            local linkData = dataHandler.questObjects[linkDt[1]]
            if linkData and (linkData.type <= 2) then
                local obj = tes3.getObject(linkDt[1])
                if obj then
                    objects[obj] = linkDt[1]
                end
            end
        end
    end

    if requirement.type == types.requirementType.CustomActor and requirement.object then
        local obj = tes3.getObject(requirement.object)
        if obj then
            objects[obj] = requirement.object
        end
    elseif requirement.type == types.requirementType.CustomScript and requirement.script then
        fillDataForScriptByTableName(requirement.script, "links")

    elseif requirement.type == "SCR1" and requirement.value then
        fillDataForScriptByTableName(requirement.value, "contains")

    else
        for _, req in pairs(requirements) do
            for name, value in pairs(req) do
                if type(value) ~= "string" then
                    goto continue
                end

                local obj = tes3.getObject(value)
                if obj then
                    objects[obj] = value
                    goto continue
                end

                local cell = tes3.getCell{id = value}
                if cell then
                    cells[cell] = value
                    goto continue
                end

                if string.sub(value, 1, 6) == "#dia: " then

                    local function findDiaData(recordId, depth)
                        if depth <= 0 then return end

                        local diaData = this.getObjectData(recordId)
                        for _, linkInfo in pairs((diaData or {}).links or {}) do
                            local linkId = linkInfo[1]
                            local linkData = this.getObjectData(linkId)
                            if not linkData then goto continue end

                            if linkData.type == 6 then
                                findDiaData(linkId, depth - 1)
                            elseif linkData.type <= 2 then
                                local obj1 = tes3.getObject(linkId)
                                if obj1 then
                                    objects[obj1] = linkId
                                end
                            end

                            ::continue::
                        end
                    end

                    findDiaData(value, 2)

                    goto continue
                end

                ::continue::
            end
        end
    end

    ---@param objId string
    ---@param obj any
    ---@param dt questGuider.quest.getRequirementPositionData.positionData
    local function add(objId, obj, dt)
        if not out[objId] then
            out[objId] = {name = obj.editorName or obj.name or obj.id or "", positions = {}}
        end
        table.insert(out[objId].positions, dt)
    end

    for object, id in pairs(objects) do

        ---@param objData questDataGenerator.objectInfo
        local function addPosData(objData, ownerId)
            if not objData then return end

            if not objData.positions then
                return
            end

            for _, posDt in pairs(objData.positions) do
                local x = posDt.pos[1]
                local y = posDt.pos[2]
                local z = posDt.pos[3]

                if posDt.name then
                    local cell = tes3.getCell{id = posDt.name}
                    if cell then
                        local newPosData = table.copy(posDt)
                        if ownerId then
                            newPosData.type = 2
                            newPosData.id = ownerId
                        else
                            newPosData.type = 1
                        end

                        local exCellPos, doorPath, cellPath, isExterior, checkedCells = cellLib.findExitPos(cell)
                        if exCellPos then

                            local descr
                            if cellPath then
                                for i = #cellPath, 1, -1 do
                                    descr = descr and string.format("%s => \"%s\"", descr, cellPath[i].editorName) or
                                        string.format("\"%s\"", cellPath[i].editorName)
                                end
                            end

                            add(id, object, {description = descr, id = posDt.name, position = tes3vector3.new(x, y, z),
                                exitPos = exCellPos, isExitEx = isExterior, doorPath = doorPath, cellPath = cellPath, rawData = newPosData})

                        else
                            local descr
                            if cellPath then
                                local list = {}
                                local count = 0
                                for cl, _ in pairs(checkedCells) do
                                    table.insert(list, cl.name)
                                    count = count + 1
                                end
                                table.shuffle(list, count)
                                descr = stringLib.getValueEnumString(list, configData.journal.objectNames, "Reachable from %s")
                            end
                            add(id, object, {description = descr or posDt.name, id = posDt.name, position = tes3vector3.new(x, y, z), rawData = newPosData})
                        end
                    end
                elseif posDt.grid then
                    local cell = tes3.getCell{x = posDt.grid[1], y = posDt.grid[2]}
                    if cell then
                        local descr = cell.editorName
                        local pos = tes3vector3.new(x, y, z)
                        local newPosData = table.copy(posDt)
                        if ownerId then
                            newPosData.type = 2
                            newPosData.id = ownerId
                        else
                            newPosData.type = 1
                        end
                        add(id, object, {description = descr, id = nil, position = pos, exitPos = pos, isExitEx = true, rawData = newPosData})
                    end
                end

                ::continue::
            end
        end

        local objectData = this.getObjectData(id)
        if not objectData then goto continue end

        addPosData(objectData)
        local outD = out[id]
        if outD then
            outD.inWorld = objectData.inWorld
        end

        for _, linkData in pairs(objectData.links or {}) do
            local obj = tes3.getObject(linkData[1])
            local objDt = this.getObjectData(linkData[1])
            if obj and objDt and (objDt.type <= 2) and linkData[2] >= trackingConfig.minChance then
                addPosData(objDt, linkData[1])
                outD = out[id]
                if outD then
                    outD.inWorld = (outD.inWorld or 0) + objectData.inWorld
                end
            end
        end

        ::continue::
    end

    for cell, id in pairs(cells) do
        if cell.isInterior then
            local exCellPos, doorPath, cellPath, isExterior, checkedCells = cellLib.findExitPos(cell)
            if exCellPos then

                local descr
                if cellPath then
                    for i = #cellPath, 1, -1 do
                        descr = descr and string.format("%s => \"%s\"", descr, cellPath[i].editorName) or
                            string.format("\"%s\"", cellPath[i].editorName)
                    end
                end

                add(id, cell, {description = descr, id = cell.name, exitPos = exCellPos, isExitEx = isExterior, doorPath = doorPath, cellPath = cellPath})

            else
                local descr
                if cellPath then
                    local list = {}
                    local count = 0
                    for cl, _ in pairs(checkedCells) do
                        table.insert(list, cl.name)
                        count = count + 1
                    end
                    table.shuffle(list, count)
                    descr = stringLib.getValueEnumString(list, configData.journal.objectNames, "Reachable from %s")
                end

                add(id, cell, {description = descr or cell.name, id = cell.name, })
            end
        else
            local descr = cell.editorName
            add(id, cell, {description = descr, id = nil, exitPos = tes3vector3.new(cell.gridX * 8192 + 4000, cell.gridY * 8192 + 4000, 0)})
        end

        ::continue::
    end

    if table.size(out) == 0 then
        return nil
    end

    if requirement.type == types.requirementType.Item or requirement.type == types.requirementType.Dead or
            (requirement.type == "DIAO" and requirement.value) then

        for _, data in pairs(out) do
            if requirement.value then
                data.parentObject = requirement.type == "DIAO" and requirement.object or requirement.variable

                if requirement.operator == types.operator.value.Greater then
                    data.itemCount = requirement.value + 1
                elseif requirement.operator == types.operator.value.Less then
                    data.itemCount = math.max(0, requirement.value - 1)
                elseif requirement.operator == types.operator.value.NotEqual then
                    if requirement.value == 0 then
                        data.itemCount = requirement.value + 1
                    else
                        data.itemCount = math.max(0, requirement.value - 1)
                    end
                else
                    data.itemCount = requirement.value
                end

                if data.itemCount == 0 then data.itemCount = nil end

                if requirement.type == types.requirementType.Dead then
                    data.actorCount = data.itemCount
                    data.itemCount = nil
                end
            end
        end
    end



    local approxConfig = trackingConfig.approx
    if not approxConfig.enabled then return out end

    local function changePosition(pos, radius)
        radius = radius * 0.8

        randomLib.changeVectorPosByRandomInRadius(pos, radius)
    end

    for id, data in pairs(out) do
        randomLib.setSeedByStringHash(id)

        for i, posData in ipairs(data.positions or {}) do

            posData.doorPath = nil

            if posData.position then
                if posData.id then
                    changePosition(posData.position, approxConfig.interior.radius)
                    if posData.exitPos then
                        changePosition(posData.exitPos, approxConfig.worldMap.radius)
                    end
                else
                    changePosition(posData.position, approxConfig.worldMap.radius)
                end
            end

            local descr
            if posData.cellPath then

                if #posData.cellPath > 0 and posData.isExitEx then
                    local lastIndex = #posData.cellPath
                    if #posData.cellPath > 1 then
                        local regionName = posData.cellPath[lastIndex].displayName
                        regionName = regionName == "" and "???" or regionName
                        descr = string.format("\"%s\"", regionName)
                        descr = descr .. string.format(" => \"%s\"", posData.cellPath[lastIndex - 1].editorName)
                    else
                        descr = string.format("\"%s\"", posData.cellPath[1].editorName)
                    end
                end

            elseif posData.isExitEx then
                local cell = tes3.getCell{position = posData.position}
                if cell then
                    descr = string.format("\"%s\"", cell.displayName)
                end

            end

            posData.description = descr
        end
    end
    randomLib.resetRandomSeed()

    return out
end


---@param object tes3npc|tes3creature
---@param questId string
---@param questIndex integer|string
---@return boolean?
function this.checkConditionsForQuestGiver(object, questId, questIndex)
    if not object then return end
    local questData = this.getQuestData(questId)
    if not questData then return end

    local indexStr = tostring(questIndex)
    local stageData = questData[indexStr]
    if not stageData then return end

    local requirements = stageData.requirements or {}

    if #requirements == 0 then return true end

    local allowedTypes = {
        [types.requirementType.Journal] = true,
        [types.requirementType.CustomActorFaction] = true,
        [types.requirementType.CustomPCFaction] = true,
        [types.requirementType.RankRequirement] = true,
        [types.requirementType.CustomPCRank] = true,
    }

    for _, reqBlock in pairs(stageData.requirements or {}) do
        local ret = requirementChecker.checkBlock(reqBlock, {
            allowedTypes = allowedTypes,
            object = object,
            threatErrorsAs = true,
        })

        if ret then
            return true
        end
    end

    return false
end


---@param objData questDataGenerator.objectInfo
---@param maxNames integer
---@return string[]
function this.getObjectPositionDescription(objData, maxNames)
    local approxEnabled = config.data.tracking.approx.enabled

    local descriptions = {}
    for _, posDt in pairs(objData.positions) do
        local x = posDt.pos[1]
        local y = posDt.pos[2]
        local z = posDt.pos[3]

        local descr

        if posDt.name then
            local cell = tes3.getCell{id = posDt.name}
            if cell then
                local exCellPos, doorPath, cellPath, isExterior, checkedCells = cellLib.findExitPos(cell)
                if exCellPos then

                    if cellPath then

                        if not approxEnabled then
                            for i = #cellPath, 1, -1 do
                                descr = descr and string.format("%s => \"%s\"", descr, cellPath[i].editorName) or
                                    string.format("\"%s\"", cellPath[i].editorName)
                            end
                        else
                            local lastIndex = #cellPath
                            if #cellPath > 1 then
                                local regionName = cellPath[lastIndex].displayName
                                regionName = regionName == "" and "???" or regionName
                                descr = string.format("\"%s\"", regionName)
                                descr = descr .. string.format(" => \"%s\"", cellPath[lastIndex - 1].editorName)
                            else
                                descr = string.format("\"%s\"", cellPath[1].editorName)
                            end
                        end
                    end

                else
                    if cellPath then

                        if not approxEnabled then
                            local list = {}
                            local count = 0
                            for cl, _ in pairs(checkedCells) do
                                table.insert(list, cl.name)
                                count = count + 1
                            end
                            table.shuffle(list, count)
                            descr = string.format("\"%s\", %s", cell.displayName, stringLib.getValueEnumString(list, maxNames, "Reachable from %s"))
                        else
                            descr = string.format("\"%s\"", cell.displayName)
                        end
                    end
                end
            end
        elseif posDt.grid then
            local cell = tes3.getCell{x = posDt.grid[1], y = posDt.grid[2]}
            if cell then
                descr = approxEnabled and cell.displayName or cell.editorName
            end
        end

        if descr then
            table.insert(descriptions, descr)
        end
    end

    return descriptions
end

return this