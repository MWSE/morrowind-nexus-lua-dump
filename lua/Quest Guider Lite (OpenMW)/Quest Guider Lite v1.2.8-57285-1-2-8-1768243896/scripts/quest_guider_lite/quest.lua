local world = require('openmw.world')
local types = require('openmw.types')
local util = require('openmw.util')

local log = require("scripts.quest_guider_lite.utils.log")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local cellLib = require("scripts.quest_guider_lite.cell")

local config = require("scripts.quest_guider_lite.config")

local myTypes = require("scripts.quest_guider_lite.types")
local descriptionLines = require("scripts.quest_guider_lite.descriptionLines")
local otherTypes = require("scripts.quest_guider_lite.types.other")

local dataHandler = require("scripts.quest_guider_lite.storage.dataHandler")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local requirementChecker = require("scripts.quest_guider_lite.requirementChecker")
local dialogueChecker = require("scripts.quest_guider_lite.dialogueChecker")

local tes = require("scripts.quest_guider_lite.core.tes3")
local getObject = require("scripts.quest_guider_lite.core.getObject")

local commonData = require("scripts.quest_guider_lite.common")
local core = require('openmw.core')
local l10n = core.l10n(commonData.l10nKey)

local this = {}

local weaponTypeNameById = otherTypes.weaponTypeNameById
local magicEffectConsts = otherTypes.magicEffectConsts
local vampireClan = otherTypes.vampireClan

local weatherById = {}

for name, id in pairs(tes.weather) do
    weatherById[id] = name
end


local disallowedRequirementTypes = {
    -- ["SCR"] = true
}


local filterForHandledReqBlock = {
    [myTypes.requirementType.Dead] = true,
    [myTypes.requirementType.Journal] = true,
    [myTypes.requirementType.RankRequirement] = true,
    [myTypes.requirementType.PlayerRankMinusNPCRank] = true,
    [myTypes.requirementType.Item] = true,
    [myTypes.requirementType.CustomOnDeath] = true,
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
        questData = this.getQuestData(questData) ---@diagnostic disable-line: cast-local-type
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
        questData = this.getQuestData(questData) ---@diagnostic disable-line: cast-local-type
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
            local obj = getObject(id)
            if obj and obj.name then
                out[id] = string.format("\"%s\" (%s)", obj.name, id)
            else
                out[id] = string.format("(%s)", id)
            end
            count = count + 1
        end
    end

    return out, count
end



--#################################################################################################

---@param dialogue any
---@return boolean?
local function isDialogueAvailable(dialogue)
    -- if not tes3.mobilePlayer then return end
    -- for _, dia in pairs(tes3.mobilePlayer.dialogueList) do
    --     if dialogue == dia then
    --         return true
    --     end
    -- end
    return false
end


---@param cellName string
---@return string
local function getNameByCellName(cellName)
    local name
    local cell = tes.getCell{id = cellName}
    if cell then
        local dt = tes.getCellData(cell)
        name = dt.name
    end
    if not name then
        cell = tes.getCell{name = cellName}
        if cell then
            local dt = tes.getCellData(cell)
            name = dt.name
        end
    end

    return name or cellName
end


---@class questGuider.quest.getDescriptionDataFromBlock.returnArr
---@field str string description
---@field priority number
---@field objects table<string, string>|nil index is id, value is name
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
            return l10n("thePlayer_l")
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
    local function processRequirement(requirement, additionalPriority, skipNested)
        if disallowedRequirementTypes[requirement.type] then goto continue end

        if requirement.type == myTypes.requirementType.Journal and requirement.variable == questId then
            goto continue
        end

        ---@type questGuider.quest.getDescriptionDataFromBlock.returnArr
        local reqOut = {str = "", priority = additionalPriority or 0, data = requirement}

        if requirement.type == myTypes.requirementType.CustomActor then
            reqOut.reqDataForHandling = requirementChecker.getFilterredRequirementBlock(reqBlock, filterForHandledReqBlock)
        elseif requirement.type == myTypes.requirementType.Journal then
            local req = tableLib.copy(requirement)
            req.operator = myTypes.operator.value.Equal
            req.value = 0
            reqOut.reqDataForHandling = requirementChecker.getFilterredRequirementBlock({req}, filterForHandledReqBlock)
        elseif requirement.type == "DIAP" then
            reqOut.reqDataForHandling = requirementChecker.getFilterredRequirementBlock(
                {{operator = 49, type = myTypes.requirementType.CustomDialogue, variable = requirement.variable}}
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
            local objectObj = getObject(object)
            environment.objectObj = objectObj
        end
        if value then
            if type(value) == "string" then
                local obj = getObject(value)
                if obj then
                    environment.valueObj = obj
                    goto done
                end
                local cell = tes.getCell{id = value}
                if cell then
                    environment.valueObj = cell
                    goto done
                end
                local exCell = tes.getCell{name = value}
                if exCell then
                    environment.valueObj = exCell
                    goto done
                end
                -- local faction = tes3.getFaction(value)
                -- if faction then
                --     environment.valueObj = faction
                --     goto done
                -- end
                local class = types.NPC.classes.record(value)
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
                local obj = getObject(variable)
                if obj then
                    environment.variableObj = obj
                    goto done
                end
                local cell = tes.getCell{id = variable}
                if cell then
                    environment.variableObj = cell
                    goto done
                end
                local exCell = tes.getCell{name = value}
                if exCell then
                    environment.variableObj = exCell
                    goto done
                end
                -- local faction = tes3.getFaction(variable)
                -- if faction then
                --     environment.variableObj = faction
                --     goto done
                -- end
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
                elseif codeStr == "script" then
                    mapped[pattern] = environment.script or "???"
                elseif codeStr == "varQuestName" then
                    mapped[pattern] = environment.variableQuestName
                elseif codeStr == "objectName" then
                    mapped[pattern] = getName(environment.objectObj, l10n("theObject_l"))
                elseif codeStr == "valueName" then
                    mapped[pattern] = getName(environment.valueObj, environment.value)
                elseif codeStr == "varName" then
                    mapped[pattern] = getName(environment.variableObj, environment.variable)
                elseif codeStr == "skillName" then
                    mapped[pattern] = environment.skill and (tes.skillName[environment.skill] or "???") or "???"
                elseif codeStr == "attributeName" then
                    mapped[pattern] = environment.attribute and (tes.attributeName[environment.attribute] or "???") or "???"
                elseif codeStr == "valCellName" then
                    mapped[pattern] = getNameByCellName(environment.value)
                elseif codeStr == "weaponType" then
                    mapped[pattern] = environment.value and (weaponTypeNameById[environment.value] or "???") or "???"
                elseif codeStr == "magicEffect" then
                    mapped[pattern] = magicEffectConsts[environment.variable] and tes.getMagicEffect(magicEffectConsts[environment.variable]).name or environment.variable
                elseif codeStr == "classVar" then
                    mapped[pattern] = tes.findClass(environment.variable) and tes.findClass(environment.variable).name or environment.variable
                elseif codeStr == "classVal" then
                    mapped[pattern] = tes.findClass(environment.value) and tes.findClass(environment.value).name or environment.value
                elseif codeStr == "rankName" then
                    local faction = core.factions.records[environment.variable or ""]
                    local rank = faction and faction.ranks[environment.value]
                    mapped[pattern] = rank and rank.name or environment.value
                elseif codeStr == "vampClanVal" then
                    mapped[pattern] = vampireClan[environment.value] and vampireClan[environment.value] or tostring(environment.value)
                elseif codeStr == "weatherIdVal" then
                    mapped[pattern] = weatherById[environment.value] and weatherById[environment.value] or tostring(environment.value)
                elseif codeStr == "varNameOrTheActor" then
                    mapped[pattern] = getName(environment.variableObj, l10n("theActor_l"))
                elseif codeStr == "objNameOrTheActor" then
                    mapped[pattern] = getName(environment.objectObj, l10n("theActor_l"))
                elseif codeStr == "maleFemaleValue" then
                    mapped[pattern] = environment.value == 0 and l10n("male_l") or l10n("female_l")
                elseif codeStr == "trueFalseValue" then
                    mapped[pattern] = environment.value == 1 and l10n("true_l") or l10n("false_l")
                elseif codeStr == "isBeforeValue" then
                    mapped[pattern] = environment.value == 0 and l10n("before_l") or ""
                elseif codeStr == "raceByIntValue" then
                    local race
                    pcall(function ()
                        race = types.NPC.races.records[environment.value]
                    end)
                    mapped[pattern] = race and race.name or "???"
                elseif codeStr == "factionValue" then
                    local faction = core.factions.records[environment.value or ""]
                    mapped[pattern] = faction and faction.name or environment.value
                elseif codeStr == "factionVar" then
                    local faction = core.factions.records[environment.variable or ""]
                    mapped[pattern] = faction and faction.name or environment.variable
                elseif codeStr == "varSpellName" then
                    local spell = core.magic.spells.records[environment.variable]
                    mapped[pattern] = spell and spell.name or environment.variable
                elseif codeStr == "dialogueVariable" then
                    mapped[pattern] = environment.variableStr:sub(7)
                elseif codeStr == "dialogueValue" then
                    mapped[pattern] = environment.valueStr:sub(7)
                elseif codeStr == "operator" then
                    mapped[pattern] = myTypes.operator.name[environment.operator]
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
                                res = stringLib.getValueEnumString(objs, configData.journal.objectNames, "%s", nil, nil, "%s")
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
                                res = stringLib.getValueEnumString(objs, configData.journal.objectNames, "%s", nil, nil, "%s")
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

            -- local mapped = {}
            -- for codeStr in string.gmatch(str, "@(.-)@") do
            --     local pattern = "@"..codeStr.."@"
            --     local f, err = load("return "..codeStr, nil, nil, environment)
            --     if err then
            --         log("pattern error", err, pattern, requirement)
            --     else
            --         local fSuccess, fRet = pcall(f)
            --         if not fSuccess then
            --             log("pattern error", pattern, requirement)
            --             fRet = "<error>"
            --         end
            --         mapped[pattern] = fRet or "???"
            --     end
            -- end
            -- for pattern, ret in pairs(mapped) do
            --     str = str:gsub(pattern:gsub("%(", "."):gsub("%)", "."), ret)
            -- end

            reqOut.str = str:gsub("^%l", string.upper)

            if reqStrDescrData.priority then
                reqOut.priority = reqOut.priority + reqStrDescrData.priority
            end
        else
            local reqCopy = tableLib.copy(requirement)
            for reqDescr, reqId in pairs(myTypes.requirementType) do
                if reqCopy.type == reqId then
                    reqCopy.type = reqDescr
                    break;
                end
            end
            reqCopy.operator = myTypes.operator.name[reqCopy.operator] or reqCopy.operator
            reqOut.str = tableLib.tableToStrLine(reqCopy) or "???"
        end

        local objects = {}
        if environment.objectObj and environment.object then
            objects[environment.object] = environment.objectObj and (environment.objectObj.name or "") or ""
        end
        if environment.variableObj and environment.variable then
            objects[environment.variable] = environment.variableObj and (environment.variableObj.name or "") or ""
        end
        if environment.valueObj and environment.value then
            objects[environment.value] = environment.valueObj and (environment.valueObj.name or "") or ""
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

        objects["player"] = nil

        if tableLib.size(objects) > 0 then
            reqOut.objects = objects
        end

        reqOut.positionData = this.getRequirementPositionData(requirement, configData)

        table.insert(out, reqOut)

        if requirement.type == myTypes.requirementType.CustomScript and environment.script then
            local scrData = dataHandler.questObjects[environment.script]
            if scrData and scrData.contains then
                local objs, count = this.getObjectNamesFromLinkTable(scrData.contains)

                if count > 0 then
                    processRequirement({type = "SCR1", operator = 48, value = environment.script}, additionalPriority)
                end
            end

        elseif not skipNested and requirement.type == myTypes.requirementType.CustomLocal and requirement.variable and requirement.value then

            local function process(objectId, addPriority)
                if not addPriority then addPriority = 0 end

                local localVarDt = dataHandler.localVariablesByScriptId[objectId]
                if not localVarDt then return end
                localVarDt = localVarDt[requirement.variable]
                if not localVarDt then return end
                ---@type questDataGenerator.requirementBlock[]
                local resReqBlock = localVarDt.results[tostring(requirement.value)]
                if not resReqBlock then return end
                if not next(resReqBlock) then return end

                -- currently only the first requirement block is used
                -- TODO: Implement support for multiple requirement blocks
                local reqs = resReqBlock[1]

                local scriptIds = {}
                for _, req in pairs(reqs) do
                    local isNew = true
                    for _, r in pairs(reqBlock) do
                        if myTypes.areRequirementsEqual(req, r) then
                            isNew = false
                            break
                        end
                    end

                    if isNew then
                        processRequirement(req, addPriority - 9000, true)
                        if req.script then
                            scriptIds[req.script] = true
                        end
                    end
                end

                for scrId, _ in pairs(scriptIds) do
                    processRequirement({type = myTypes.requirementType.CustomScript, operator = 48, variable = scrId, script = scrId}, addPriority - 10000, true)
                end
            end

            if requirement.object then
                process(requirement.object)

            else
                for i, req in pairs(reqBlock) do
                    if req.type == myTypes.requirementType.CustomActor and req.object then
                        process(req.object, -i * 10000)
                    end
                end
            end

        end

        local function addDialogueData(objId)
            if not objId or checkedDialogObjects[objId] then return end
            checkedDialogObjects[objId] = true

            local objData = dataHandler.questObjects[objId]
            if not objData or objData.type > 2 then return end

            if not tes.getObject(objId) then return end

            for _, linkDt in pairs(objData.links or {}) do
                local linkName = linkDt[1]
                local linkData = dataHandler.questObjects[linkName]
                if not linkData then goto continue end

                if linkData.type == 3 then
                    if requirement.type == myTypes.requirementType.Item then
                        processRequirement({type = "DIAO", operator = operator, object = variable, variable = linkName, value = value}, additionalPriority)
                    else
                        processRequirement({type = "DIAO", operator = operator, variable = linkName}, additionalPriority)
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

        -- if requirement.type == myTypes.requirementType.CustomDialogue and environment.variable then
        --     local foundData = {}

        --     local function findParentDialogues(recId, parentId, depth, dataChain)
        --         if depth <= 0 then return end

        --         if not dataChain then dataChain = {} end

        --         local recData = this.getObjectData(recId)
        --         if not recData then return end

        --         if recData.type == 3 then
        --             local dialogue = tes3.findDialogue{ topic = string.sub(recId, 7) }
        --             if not dialogue or dialogue.type ~= tes3.dialogueType.topic then return end

        --             if not isDialogueAvailable(dialogue) then
        --                 for _, linkInfo in pairs(recData.links or {}) do
        --                     local chainDepth, chain = findParentDialogues(linkInfo[1], recId, depth - 1)
        --                     if chainDepth then
        --                         table.insert(foundData, {chainDepth, chain})
        --                     end
        --                 end
        --             else
        --                 local chain = tableLib.copy(dataChain)
        --                 table.insert(chain, {variable = parentId, value = recId})
        --                 return depth, chain
        --             end
        --         elseif recData.type == 6 then
        --             for _, linkInfo in pairs(recData.links or {}) do
        --                 local chainDepth, chain = findParentDialogues(linkInfo[1], parentId, depth - 1)
        --                 if chainDepth then
        --                     table.insert(foundData, {chainDepth, chain})
        --                 end
        --             end
        --         end
        --     end

        --     local dialogue = tes3.findDialogue{ topic = string.sub(environment.variable, 7) }
        --     if not dialogue or dialogue.type ~= tes3.dialogueType.topic then goto continue end

        --     if not isDialogueAvailable(dialogue) then
        --         findParentDialogues(environment.variable, environment.variable, 6)

        --         if #foundData == 0 then goto continue end
        --         table.sort(foundData, function (a, b)
        --             return a[1] < b[1]
        --         end)

        --         local minDepth = foundData[1][1]
        --         local addedDialogues = {}

        --         for _, data in pairs(foundData) do
        --             if data[1] <= minDepth then
        --                 for _, chainDt in pairs(data[2]) do
        --                     if not addedDialogues[chainDt.variable] then
        --                         processRequirement({type = "DIAP", operator = 48, variable = chainDt.variable, value = chainDt.value})
        --                         addedDialogues[chainDt.variable] = true
        --                     end
        --                 end
        --             else
        --                 break
        --             end
        --         end
        --     end
        -- end

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

-- ---@return questGuider.quest.getPlayerQuestData.return
-- function this.getPlayerQuestData()
--     local out = {}

--     local dialogueData = tes3.dataHandler.nonDynamicData.dialogues

--     for _, dialogue in pairs(dialogueData) do
--         if dialogue.type ~= tes3.dialogueType.journal then goto continue end

--         local dialogueId = dialogue.id:lower()
--         local storageData = dataHandler.quests[dialogueId]

--         if not storageData then goto continue end

--         ---@type questGuider.quest.getPlayerQuestData.returnArr
--         local diaOutData = {} ---@diagnostic disable-line: missing-fields

--         diaOutData.id = dialogueId
--         diaOutData.name = storageData.name
--         diaOutData.activeStage = dialogue.journalIndex
--         diaOutData.isFinished = dialogue.journalIndex and storageData[tostring(dialogue.journalIndex)] and storageData[tostring(dialogue.journalIndex)].finished or nil

--         table.insert(out, diaOutData)

--         ::continue::
--     end

--     return out
-- end


---@param reqBlock table<integer, questDataGenerator.requirementData>
---@return boolean
function this.isContainsLocalVariableRequirement(reqBlock)
    for _, req in pairs(reqBlock) do
        if req.type == myTypes.requirementType.CustomLocal then
            return true
        end
    end
    return false
end


local findExitPosCache = {}

---@param objData questDataGenerator.objectInfo
local function addPosData(arr, objData, ownerId, configData)
    if not objData then return end

    if not objData.positions then
        return
    end

    for _, posDt in pairs(objData.positions) do
        local x = posDt.pos[1]
        local y = posDt.pos[2]
        local z = posDt.pos[3]

        if posDt.name then
            local cell = tes.getCell{id = posDt.name}
            if cell then
                local newPosData = tableLib.copy(posDt)
                if ownerId then
                    newPosData.type = 2
                    newPosData.id = ownerId
                else
                    newPosData.type = 1
                end

                local exCellPos, doorPath, cellPath, isExterior, checkedCells
                if findExitPosCache[cell.id] then
                    exCellPos, doorPath, cellPath, isExterior, checkedCells = table.unpack(findExitPosCache[cell.id])
                else
                    exCellPos, doorPath, cellPath, isExterior, checkedCells = cellLib.findExitPos(cell)
                    findExitPosCache[cell.id] = {exCellPos, doorPath, cellPath, isExterior, checkedCells}
                end

                if exCellPos then

                    local exits = {}
                    local firstEntranceCellIds = {}
                    local exitPositions, _, entranceCells, lowestDepth = cellLib.findExitPositions(cell)
                    if exitPositions then
                        for _, pDt in pairs(exitPositions) do
                            if pDt.depth <= lowestDepth + 2 then
                                local nearestDoor = cellLib.findNearestDoor(pDt.pos)
                                if nearestDoor then
                                    table.insert(exits, nearestDoor.position)
                                else
                                    table.insert(exits, pDt.pos)
                                end
                            end
                        end
                        for cellId, depth in pairs(entranceCells or {}) do
                            if depth <= lowestDepth + 2 then
                                firstEntranceCellIds[cellId] = cellId
                            end
                        end
                    end

                    table.insert(arr, {id = posDt.name, position = util.vector3(x, y, z), entrances = exits,  firstEntranceCellIds = firstEntranceCellIds,
                        exitPos = exCellPos, isExitEx = isExterior, doorPath = doorPath, cellPath = cellPath, rawData = newPosData})

                else
                    local descr
                    if cellPath then
                        local list = {}
                        local count = 0
                        for _, cl in pairs(checkedCells) do
                            local cellData = tes.getCellData(cl)
                            table.insert(list, cellData.name or "???")
                            count = count + 1
                        end
                        tableLib.shuffle(list, count)
                        descr = stringLib.getValueEnumString(list, configData.journal.objectNames, l10n("reachableFrom").." %s")
                    end
                    table.insert(arr, {description = descr or posDt.name, id = posDt.name, position = util.vector3(x, y, z), rawData = newPosData})
                end
            end
        elseif posDt.grid then
            local cell = tes.getCell{x = posDt.grid[1], y = posDt.grid[2]}
            if cell then
                local descr = tes.getCellData(cell).name
                local pos = util.vector3(x, y, z)
                local newPosData = tableLib.copy(posDt)
                if ownerId then
                    newPosData.type = 2
                    newPosData.id = ownerId
                else
                    newPosData.type = 1
                end
                table.insert(arr, {description = descr, id = nil, position = pos, exitPos = pos, isExitEx = true, rawData = newPosData})
            end
        end

        ::continue::
    end
end


local function addCellData(cell, id, arr, configData)
    if not cell.isExterior then
        local exCellPos, doorPath, cellPath, isExterior, checkedCells
        if findExitPosCache[cell.id] then
            exCellPos, doorPath, cellPath, isExterior, checkedCells = table.unpack(findExitPosCache[cell.id])
        else
            exCellPos, doorPath, cellPath, isExterior, checkedCells = cellLib.findExitPos(cell)
            findExitPosCache[cell.id] = {exCellPos, doorPath, cellPath, isExterior, checkedCells}
        end

        if exCellPos then

            -- local descr
            -- if cellPath then
            --     for i = #cellPath, 1, -1 do
            --         descr = descr and string.format("%s => \"%s\"", descr, cellPath[i].name) or
            --             string.format("\"%s\"", cellPath[i].name)
            --     end
            -- end

            local exits = {}
            local firstEntranceCellIds = {}
            local exitPositions, _, entranceCells, lowestDepth = cellLib.findExitPositions(cell)
            if exitPositions then
                for _, pDt in pairs(exitPositions) do
                    if pDt.depth <= lowestDepth + 1 then
                        local nearestDoor = cellLib.findNearestDoor(pDt.pos)
                        if nearestDoor then
                            table.insert(exits, nearestDoor.position)
                        else
                            table.insert(exits, pDt.pos)
                        end
                    end
                end
                for cellId, depth in pairs(entranceCells or {}) do
                    if depth <= lowestDepth + 1 then
                        firstEntranceCellIds[cellId] = cellId
                    end
                end
            end

            table.insert(arr, {id = cell.name, exitPos = exCellPos, entrances = exits, firstEntranceCellIds = firstEntranceCellIds,
                isExitEx = isExterior, doorPath = doorPath, cellPath = cellPath})

        else
            local descr
            if cellPath then
                local list = {}
                local count = 0
                for _, cl in pairs(checkedCells) do
                    local cellData = tes.getCellData(cl)
                    table.insert(list, cellData.name or "???")
                    count = count + 1
                end
                tableLib.shuffle(list, count)
                descr = stringLib.getValueEnumString(list, configData.journal.objectNames, l10n("reachableFrom").." %s")
            end

            table.insert(arr, {description = descr or cell.displayName or cell.name or "???", id = cell.name, })
        end
    else
        local cellDt = tes.getCellData(cell)
        table.insert(arr, {description = cellDt.name, id = nil, exitPos = util.vector3(cell.gridX * 8192 + 4000, cell.gridY * 8192 + 4000, 0)})
    end
end



---@class questGuider.quest.getRequirementPositionData.positionData
---@field description string?
---@field descriptionBackward string?
---@field id string? cell id of the position
---@field position tes3vector3? coordinates of the position
---@field distanceToPlayer number?
---@field pathFromPlayer string[]? cell names
---@field exitPos tes3vector3? coordinates in the game world of the entrance to the exterior cell that leads to the position
---@field entrances tes3vector3[]?
---@field firstEntranceCellIds table<string, any>?
---@field doorPath tes3travelDestinationNode[]? list of doors to exit from the position
---@field cellPath tes3cellData[]? list of cells to exit from the position
---@field rawData questDataGenerator.objectPosition|{id : string}|nil *id* is injected owner id, if it exists
---@field isExitEx boolean? true, if the exit is in an exterior cell

---@class questGuider.quest.getRequirementPositionData.returnData
---@field reqType string requirement type
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

    if requirement.type == myTypes.requirementType.CustomDialogue then
        return
    end

    ---@type table<string, questGuider.quest.getRequirementPositionData.returnData>
    local out = {}

    local objects = {}
    ---@type table<tes3cell, string>
    local cells = {}

    local requirements = {requirement}
    if requirement.type == myTypes.requirementType.Journal
            and not ((requirement.operator == myTypes.operator.value.Equal or requirement.operator == myTypes.operator.value.LessOrEqual) and requirement.value == 0)
            and not (requirement.operator == myTypes.operator.value.Less and requirement.value == 1) then
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
                                [myTypes.requirementType.Journal] = true,
                                [myTypes.requirementType.CustomPCFaction] = true,
                                [myTypes.requirementType.CustomPCRank] = true,
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
        if not scrData or not scrData[tableName] then return end

        for _, linkDt in pairs(scrData[tableName]) do
            local linkData = dataHandler.questObjects[linkDt[1]]
            if linkData and (linkData.type <= 2) then
                local obj = tes.getObject(linkDt[1])
                if obj then
                    objects[obj] = linkDt[1]
                end
            end
        end
    end

    if requirement.type == myTypes.requirementType.CustomActor and requirement.object then
        local obj = tes.getObject(requirement.object)
        if obj then
            objects[obj] = requirement.object
        end
    elseif requirement.type == myTypes.requirementType.CustomScript and requirement.script then
        fillDataForScriptByTableName(requirement.script, "links")

    elseif requirement.type == "SCR1" and requirement.value then
        fillDataForScriptByTableName(requirement.value, "contains")

    else
        for _, req in pairs(requirements) do
            for name, value in pairs(req) do
                if type(value) ~= "string" then
                    goto continue
                end

                local obj = tes.getObject(value)
                if obj then
                    objects[obj] = value
                    goto continue
                end

                local cell = tes.getCell{id = value}
                if cell then
                    cells[cell] = value
                    goto continue
                end

                local exCell = tes.getCell{name = value}
                if exCell then
                    cells[exCell] = value
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
                                local obj1 = tes.getObject(linkId)
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
            out[objId] = {reqType = requirement.type, name = obj.editorName or obj.name or obj.id or "", positions = {}}
        end
        table.insert(out[objId].positions, dt)
    end

    for object, id in pairs(objects) do
        local positions = {}

        local objectData = this.getObjectData(id)
        if not objectData then goto continue end

        addPosData(positions, objectData, nil, configData)

        if not out[id] then
            out[id] = {reqType = requirement.type, name = object.editorName or object.name or object.id or "", positions = {}}
        end

        local outD = out[id]
        if outD then
            outD.inWorld = objectData.inWorld
        end

        for _, linkData in pairs(objectData.links or {}) do
            local obj = tes.getObject(linkData[1])
            local objDt = this.getObjectData(linkData[1])
            if obj and objDt and (objDt.type <= 2) and linkData[2] >= trackingConfig.minChance * 0.01 then
                addPosData(positions, objDt, linkData[1], configData)
                outD = out[id]
                if outD then
                    outD.inWorld = (outD.inWorld or 0) + objectData.inWorld
                end
            end
        end

        outD.positions = positions

        ::continue::
    end

    for cell, id in pairs(cells) do
        if not out[id] then
            out[id] = {reqType = requirement.type, name = cell.displayName or cell.name or cell.id or "", positions = {}}
        end
        addCellData(cell, id, out[id].positions, configData)
    end

    if tableLib.size(out) == 0 then
        return nil
    end

    if requirement.type == myTypes.requirementType.Item or requirement.type == myTypes.requirementType.Dead or
            (requirement.type == "DIAO" and requirement.value) then

        for _, data in pairs(out) do
            if requirement.value then
                data.parentObject = requirement.type == "DIAO" and requirement.object or requirement.variable

                if requirement.operator == myTypes.operator.value.Greater then
                    data.itemCount = requirement.value + 1
                elseif requirement.operator == myTypes.operator.value.Less then
                    data.itemCount = math.max(0, requirement.value - 1)
                elseif requirement.operator == myTypes.operator.value.NotEqual then
                    if requirement.value == 0 then
                        data.itemCount = requirement.value + 1
                    else
                        data.itemCount = math.max(0, requirement.value - 1)
                    end
                else
                    data.itemCount = requirement.value
                end

                if data.itemCount == 0 then data.itemCount = nil end

                if requirement.type == myTypes.requirementType.Dead then
                    data.actorCount = data.itemCount
                    data.itemCount = nil
                end
            end
        end
    end

    return out
end


---@class questGuider.quest.getPositions.params
---@field findLinks boolean?
---@field includeLinks boolean?
---@field customConfig questGuider.config?

---@param objectId string
---@param params questGuider.quest.getPositions.params?
---@return questGuider.quest.getRequirementPositionData.positionData[]? positions
---@return questGuider.quest.getRequirementPositionData.positionData[]? links
function this.getPositions(objectId, params)
    if not params then params = {} end

    local configData = params.customConfig or config.data

    local trackingConfig = configData.tracking

    ---@type questGuider.quest.getRequirementPositionData.positionData[]
    local positions = {}

    local cell = tes.getCell{id = objectId}
    if cell then
        addCellData(cell, objectId, positions, configData)
        return positions
    end

    local exCell = tes.getCell{name = objectId}
    if exCell then
        addCellData(exCell, objectId, positions, configData)
        return positions
    end

    local objectData = this.getObjectData(objectId)
    if not objectData then return end

    addPosData(positions, objectData, nil, configData)

    local linkPositions
    if params.findLinks then
        linkPositions = {}

        for _, linkData in pairs(objectData.links or {}) do
            local obj = tes.getObject(linkData[1])
            local objDt = this.getObjectData(linkData[1])
            if obj and objDt and (objDt.type <= 2) and linkData[2] >= trackingConfig.minChance * 0.01 then
                addPosData(linkPositions, objDt, linkData[1], configData)
            end
        end

        if params.includeLinks then
            tableLib.addValues(linkPositions, positions)
        end
    end

    return positions, linkPositions
end


---@param questId string
---@param questIndex integer|string
---@return boolean?
function this.checkConditionsForQuest(questId, questIndex, ref)
    local questData = this.getQuestData(questId)
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
            })

            if ret then
                return true
            end
        end

    else
        local ignoredTypes = {
            [myTypes.requirementType.CustomDisposition] = true,
            [myTypes.requirementType.CustomDialogue] = true,
        }

        local truthTable = {
            [myTypes.requirementType.PreviousDialogChoice] = true,
        }

        for _, reqBlock in pairs(stageData.requirements or {}) do
            local ret = requirementChecker.checkBlock(reqBlock, {
                ignoredTypes = ignoredTypes,
                threatErrorsAs = true,
                reference = ref,
            })

            if ret then
                local foundDiaReq = false
                for _, req in pairs(reqBlock) do
                    if req.type == myTypes.requirementType.CustomDialogue then
                        foundDiaReq = true
                        local diaId = stringLib.convertDialogueName(req.variable)
                        local infoId = req.value

                        local checkerRes = dialogueChecker.isDialogueTopicAvailable(ref, diaId, infoId, {
                            skipDisposition = true,
                            checkBlockOptions = {
                                ignoredTypes = ignoredTypes,
                                typeTruthTable = truthTable,
                                threatErrorsAs = false,
                            }
                        })

                        if checkerRes then return true end
                        break
                    end
                end

                if not foundDiaReq then
                    return true
                end
            end
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
            local cell = tes.getCell{id = posDt.name}
            if cell then
                local exCellPos, doorPath, cellPath, isExterior, checkedCells
                if findExitPosCache[cell.id] then
                    exCellPos, doorPath, cellPath, isExterior, checkedCells = table.unpack(findExitPosCache[cell.id])
                else
                    exCellPos, doorPath, cellPath, isExterior, checkedCells = cellLib.findExitPos(cell)
                    findExitPosCache[cell.id] = {exCellPos, doorPath, cellPath, isExterior, checkedCells}
                end
                if exCellPos then

                    if cellPath then

                        if not approxEnabled then
                            for i = #cellPath, 1, -1 do
                                descr = descr and string.format("%s => \"%s\"", descr, cellPath[i].id) or
                                    string.format("\"%s\"", cellPath[i].id)
                            end
                        else
                            local lastIndex = #cellPath
                            if #cellPath > 1 then
                                local regionName = cellPath[lastIndex].name
                                regionName = regionName == "" and "???" or regionName
                                descr = string.format("\"%s\"", regionName)
                                descr = descr .. string.format(" => \"%s\"", cellPath[lastIndex - 1].id)
                            else
                                descr = string.format("\"%s\"", cellPath[1].id)
                            end
                        end
                    end

                else
                    if cellPath then

                        if not approxEnabled then
                            local list = {}
                            local count = 0
                            for _, cl in pairs(checkedCells) do
                                local cellData = tes.getCellData(cl)
                                table.insert(list, cellData.name or "???")
                                count = count + 1
                            end
                            tableLib.shuffle(list, count)
                            descr = string.format("\"%s\", %s", cell.displayName, stringLib.getValueEnumString(list, maxNames, l10n("reachableFrom").." %s"))
                        else
                            descr = string.format("\"%s\"", cell.displayName)
                        end
                    end
                end
            end
        elseif posDt.grid then
            local cell = tes.getCell{x = posDt.grid[1], y = posDt.grid[2]}
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