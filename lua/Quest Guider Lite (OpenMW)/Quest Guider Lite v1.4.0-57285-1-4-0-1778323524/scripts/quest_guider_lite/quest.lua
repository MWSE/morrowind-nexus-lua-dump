local world = require('openmw.world')
local types = require('openmw.types')
local util = require('openmw.util')

local log = require("scripts.quest_guider_lite.utils.log")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local cellLib = require("scripts.quest_guider_lite.cell")
local cellAdvLib = require("scripts.quest_guider_lite.map.cell")
local cacheLib = require("scripts.quest_guider_lite.utils.cache")

local myTypes = require("scripts.quest_guider_lite.types")
local descriptionLines = require("scripts.quest_guider_lite.descriptionLines")
local otherTypes = require("scripts.quest_guider_lite.types.other")

local dataHandler = require("scripts.quest_guider_lite.storage.dataHandler")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local requirementChecker = require("scripts.quest_guider_lite.requirementChecker")

local tes = require("scripts.quest_guider_lite.core.tes3")
local questBase = require("scripts.quest_guider_lite.questBase")
local getObject = require("scripts.quest_guider_lite.core.getObject")
local isItemType = require("scripts.quest_guider_lite.types.item").isItemType
local isActorType = require("scripts.quest_guider_lite.types.actor").isActorType

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
    [myTypes.requirementType.CustomDialogueChoiceLink] = true
}


local filterForHandledReqBlock = {
    [myTypes.requirementType.Dead] = true,
    [myTypes.requirementType.Journal] = true,
    [myTypes.requirementType.RankRequirement] = true,
    [myTypes.requirementType.PlayerRankMinusNPCRank] = true,
    [myTypes.requirementType.Item] = true,
    [myTypes.requirementType.CustomOnDeath] = true,
}

local filterForDeadReqs = {
    [myTypes.requirementType.Dead] = true,
    [myTypes.requirementType.CustomOnDeath] = true,
}

local cellRequirementTypes = {
    [myTypes.requirementType.NotActorCell] = true,
    [myTypes.requirementType.CustomActorCell] = true,
    [myTypes.requirementType.CustomPCCell] = true,
}

local forbiddenCells = {
    ["toddtest"] = true,
    ["t_test_hf"] = true,
    ["t_test_hr"] = true,
    ["t_test_pc"] = true,
    ["t_test_pi"] = true,
    ["t_test_shotn"] = true,
    ["t_test_skyskiff"] = true,
    ["t_test_tr"] = true,
    ["t_test_wolli"] = true,
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


this.getIndexes = questBase.getIndexes


this.getFirstIndex = questBase.getFirstIndex


this.getNextIndexes = questBase.getNextIndexes


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
---@field reqDataForHandling questDataGenerator.requirementBlock? requirement block that can be used for handling quest marker visibility
---@field reqDataForHandlingArr questDataGenerator.requirementBlock[]? alternative requirement blocks. Added to preserve old handling method.

---@alias questGuider.quest.getDescriptionDataFromBlock.return questGuider.quest.getDescriptionDataFromBlock.returnArr[]

---@param reqBlock questDataGenerator.requirementBlock
---@param questId string?
---@param customConfig questGuider.config?
---@return questGuider.quest.getDescriptionDataFromBlock.return|nil
---@return table<string, {index: integer, qData: questDataGenerator.questData}>? linkedQuests
function this.getDescriptionDataFromDataBlock(reqBlock, questId, customConfig)
    if not reqBlock then return end

    local blockHash = myTypes.gerRequirementBlockHash(reqBlock)
    local cachedVal = cacheLib.get("reqBlockDescrData", blockHash)
    if cachedVal then
        return table.unpack(cachedVal) ---@diagnostic disable-line: redundant-return-value
    end

    local configData = customConfig
    if not configData then
        log("Error: config data is required for getDescriptionDataFromDataBlock")
        return
    end
    ---@type table<string, {index: integer, qData: questDataGenerator.questData}>?
    local linkedQuests

    local function getName(obj, default)
        if obj and obj.id == "player" then
            return l10n("thePlayer_l")
        elseif obj and obj.name then
            return obj.name
        end
        return default or "???"
    end

    local cellRestrictions = {}
    local posReqs = myTypes.getReqirementsByTypeFromBlock(reqBlock, myTypes.requirementType.CustomActorCell)
    if posReqs then
        for _, req in pairs(posReqs) do
            cellRestrictions[req.value or ""] = true
        end
    end
    posReqs = myTypes.getReqirementsByTypeFromBlock(reqBlock, myTypes.requirementType.NotActorCell)
    if posReqs then
        for _, req in pairs(posReqs) do
            cellRestrictions[req.variable or ""] = false
        end
    end
    cellRestrictions = next(cellRestrictions) and cellRestrictions or nil

    ---@type questGuider.quest.getDescriptionDataFromBlock.return
    local out = {}

    ---@type table<string, boolean>
    local checkedDialogObjects = {}

    local processedReqs = {}

    ---@param requirement questDataGenerator.requirementData
    ---@param reqBlockForHandling questDataGenerator.requirementBlock?
    local function processRequirement(requirement, additionalPriority, skipNested, reqBlockForHandling)
        if disallowedRequirementTypes[requirement.type] then goto continue end

        if requirement.type == myTypes.requirementType.Journal and requirement.variable == questId then
            goto continue
        elseif requirement.type == myTypes.requirementType.CustomScript and requirement.script then
            local scrData = dataHandler.questObjects[requirement.script]
            if scrData and scrData.links then
                for _, dt in pairs(scrData.links) do
                    if dt[2] == nil then goto continue end

                    local objDt = this.getObjectData(dt[1])
                    if not objDt or objDt.type > 2 then goto continue end

                    processRequirement({type = "SCR2", operator = 48, variable = dt[1], script = requirement.script}, (additionalPriority or 0) - 10000)

                    ::continue::
                end
                return
            end
        end

        local recHash = myTypes.getRequirementHash(requirement)
        if processedReqs[recHash] then goto continue end
        processedReqs[recHash] = true

        ---@type questGuider.quest.getDescriptionDataFromBlock.returnArr
        local reqOut = {str = "", priority = additionalPriority or 0, data = requirement}

        if reqBlockForHandling then
            reqOut.reqDataForHandling = reqBlockForHandling
        elseif requirement.type == myTypes.requirementType.CustomActor then
            local blockCopy = tableLib.copy(reqBlock)
            local objData = dataHandler.getObjectData(requirement.object)
            if objData and (objData.total or 0) < 2 then
                table.insert(blockCopy, {
                    type = myTypes.requirementType.Dead,
                    operator = myTypes.operator.value.Equal,
                    value = 0,
                    object = requirement.object,
                })
            end
            reqOut.reqDataForHandling = requirementChecker.getFilterredRequirementBlock(blockCopy, filterForHandledReqBlock)
        elseif requirement.type == myTypes.requirementType.Journal then

            local isAddedNotStartedQuest = false
            if requirement.type == myTypes.requirementType.Journal
                    and not ((requirement.operator == myTypes.operator.value.Equal or requirement.operator == myTypes.operator.value.LessOrEqual) and requirement.value == 0)
                    and not (requirement.operator == myTypes.operator.value.Less and requirement.value == 1) then

                local index = playerQuests.getCurrentIndex(requirement.variable or "")
                if not index or index == 0 then
                    local qDt = this.getQuestData(requirement.variable)
                    if qDt and qDt.givers then
                        local firstIndex = this.getFirstIndex(qDt)

                        local id = 1
                        for _, giverId in pairs(qDt.givers) do
                            local giverDt = dataHandler.questObjects[giverId]
                            if not giverDt or (giverDt.type > 2 and giverDt.type ~= 4) then goto continue end

                            reqOut.reqDataForHandlingArr = reqOut.reqDataForHandlingArr or {}
                            reqOut.reqDataForHandlingArr[id] = reqOut.reqDataForHandlingArr[id] or {}
                            if giverDt.type <= 2 then
                                local objData = dataHandler.getObjectData(requirement.object)
                                if objData and (objData.total or 0) < 2 then
                                    table.insert(reqOut.reqDataForHandlingArr[id], {
                                        type = myTypes.requirementType.Dead,
                                        operator = myTypes.operator.value.Equal,
                                        value = 0,
                                        object = giverId,
                                    })
                                end
                            end
                            table.insert(reqOut.reqDataForHandlingArr[id], {
                                type = myTypes.requirementType.Journal,
                                operator = myTypes.operator.value.Less,
                                value = firstIndex or 0,
                                variable = requirement.variable,
                            })
                            id = id + 1

                            isAddedNotStartedQuest = true

                            ::continue::
                        end
                    end
                end
            end

            if not isAddedNotStartedQuest then
                local req = tableLib.copy(requirement)
                reqOut.reqDataForHandling = reqOut.reqDataForHandling or {}
                tableLib.addValues(requirementChecker.getFilterredRequirementBlock({req}, filterForHandledReqBlock), reqOut.reqDataForHandling)
            end

        elseif requirement.type == "SCR2" then
            local filteredBlock = requirementChecker.getFilterredRequirementBlock(reqBlock, filterForDeadReqs, true)
            for _, req in pairs(filteredBlock or {}) do
                req.object = requirement.variable
            end
            reqOut.reqDataForHandling = filteredBlock

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

                if cellRequirementTypes[requirement.type] then
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

                if cellRequirementTypes[requirement.type] then
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

        local posData, linkedQuestFromPos = this.getRequirementPositionData(requirement, configData, questId, not skipNested and {
            cellRestrictions = cellRestrictions
        } or nil)
        reqOut.positionData = posData

        if linkedQuestFromPos then
            linkedQuests = linkedQuests or {}
            tableLib.copy(linkedQuestFromPos, linkedQuests)
        end

        table.insert(out, reqOut)

        if not skipNested and requirement.type == myTypes.requirementType.CustomLocal and requirement.variable and requirement.value then

            local function process(objectId, scriptId, addPriority)
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
                if scriptId then
                    scriptIds[scriptId] = true
                end
                for _, req in pairs(reqs) do
                    local isNew = true
                    for _, r in pairs(reqBlock) do
                        if myTypes.areRequirementsEqual(req, r) then
                            isNew = false
                            break
                        end
                    end

                    if isNew then
                        local reqCopy = tableLib.copy(req)
                        processRequirement(req, addPriority - 9000, true, {myTypes.invertRequirement(reqCopy)})
                        if req.script then
                            scriptIds[req.script] = true
                        end
                    end
                end

                for scrId, _ in pairs(scriptIds) do
                    processRequirement({type = myTypes.requirementType.CustomScript, operator = 48, variable = scrId, script = scrId}, addPriority - 10000, true, reqs)
                end
            end

            if requirement.object or requirement.script then
                local id = requirement.object or requirement.script

                process(id, requirement.script)
                local qObjData = this.getObjectData(id)
                if qObjData and qObjData.contains then
                    for _, dt in ipairs(qObjData.contains) do
                        if dt[2] ~= nil then break end
                        local linkedObjData = this.getObjectData(dt[1])
                        if linkedObjData and linkedObjData.type == 4 then
                            process(dt[1], dt[1])
                        end
                    end
                end
            else
                local foundScripts = {}
                local varData = this.getObjectData(requirement.variable)
                -- TODO: dehardcode limit
                if varData and varData.links and (varData.total or 0) <= 10 then
                    local linkCount = #varData.links
                    if linkCount < 10 then
                        for _, dt in ipairs(varData.links) do
                            if dt[2] ~= nil then break end

                            if not foundScripts[dt[1]] then
                                local objData = this.getObjectData(dt[1])
                                if objData and objData.type == 4 then
                                    foundScripts[dt[1]] = objData
                                end
                            end
                        end
                    end
                end

                local foundValid = false
                for scrId, scrObjDt in pairs(foundScripts) do
                    local total = varData.total or 0
                    local linkCount = #(varData.links or {})
                    if total == 0 or linkCount == 1 then
                        process(scrId, scrId)
                        foundValid = true
                    else
                        for _, dt in pairs(scrObjDt.stages or {}) do
                            if dt.id == questId then
                                process(scrId, scrId)
                                foundValid = true
                                break
                            end
                        end
                    end
                end

                if not foundValid then
                    for i, req in pairs(reqBlock) do
                        if req.type == myTypes.requirementType.CustomActor and req.object then
                            process(req.object, nil, -i * 10000)
                        end
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

        ::continue::
    end

    for _, requirement in pairs(reqBlock) do
        processRequirement(requirement)
    end

    table.sort(out, function (a, b)
        return a.priority > b.priority
    end)

    cacheLib.set("reqBlockDescrData", blockHash, {out, linkedQuests})

    return out, linkedQuests
end


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


---@param arr questGuider.quest.getRequirementPositionData.positionData[]
---@param objData questDataGenerator.objectInfo
---@param cellRestrictions table<string, boolean>?
---@return boolean? foundValidPos
local function addPosData(arr, objData, ownerId, configData, object, cellRestrictions)
    if not objData then return end

    if not objData.positions then
        return
    end

    local foundValidPos = false

    local isDoActorChecks = object and (object.servicesOffered ~= nil and objData.total and objData.total < 5)
    local function getNotFoundFlag(cell)
        if not isDoActorChecks then return end

        for _, ref in pairs(cell:getAll(object.isMale ~= nil and types.NPC or types.Creature)) do
            if ref.recordId == object.id then
                if ref.enabled then
                    return nil
                end
            end
        end
        return true
    end

    local function checkRestrictions(cellId)
        if not cellRestrictions then return true end

        for cId, val in pairs(cellRestrictions) do
            if string.sub(cellId, 1, #cId):lower() == cId then
                if val then
                    return true
                end
            elseif not val then
                return true
            end
        end

        return false
    end

    local useAdvCell = cellAdvLib.isReady()
    local findExitPosFunc
    local findExitPositionsFunc
    local findNearestDoorFunc
    if useAdvCell then
        findExitPosFunc = cellAdvLib.findExitPos
        findExitPositionsFunc = cellAdvLib.findExitPositions
        findNearestDoorFunc = cellAdvLib.findNearestDoor
    else
        findExitPosFunc = cellLib.findExitPos
        findExitPositionsFunc = cellLib.findExitPositions
        findNearestDoorFunc = cellLib.findNearestDoor
    end

    for i, posDt in ipairs(objData.positions) do
        local x = posDt.pos[1]
        local y = posDt.pos[2]
        local z = posDt.pos[3]

        if posDt.name then
            if not checkRestrictions(posDt.name) then goto continue end

            local cell = tes.getCell{id = posDt.name}
            if cell and cell.id then
                if forbiddenCells[cell.id] or cell.id:find("t_test") then goto continue end

                local notFoundFlag = getNotFoundFlag(cell)

                local newPosData = tableLib.copy(posDt)
                if ownerId then
                    newPosData.type = 2
                    newPosData.id = ownerId
                else
                    newPosData.type = 1
                end

                local exCellPos, doorPath, cellPath, isExterior, checkedCells = findExitPosFunc(useAdvCell and cell.id or cell)

                if exCellPos then

                    local exits = {}
                    local firstEntranceCellIds = {}
                    local exitPositions, _, entranceCells, lowestDepth = findExitPositionsFunc(useAdvCell and cell.id or cell)
                    if exitPositions then
                        for _, pDt in pairs(exitPositions) do
                            if pDt.depth <= lowestDepth + 2 then
                                local nearestDoor = findNearestDoorFunc(pDt.pos)
                                if nearestDoor then
                                    table.insert(exits, useAdvCell and nearestDoor.pos or nearestDoor.position)
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

                    foundValidPos = foundValidPos or not notFoundFlag
                    table.insert(arr, {id = cell.id, position = util.vector3(x, y, z), entrances = exits,  firstEntranceCellIds = firstEntranceCellIds,
                        exitPos = exCellPos, isExitEx = isExterior, doorPath = doorPath, cellPath = cellPath, rawData = newPosData, notFound = notFoundFlag})

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

                    foundValidPos = foundValidPos or not notFoundFlag
                    table.insert(arr, {description = descr or posDt.name, id = cell.id, position = util.vector3(x, y, z), rawData = newPosData, notFound = notFoundFlag})
                end
            end
        elseif posDt.grid then
            local cell = tes.getCell{x = posDt.grid[1], y = posDt.grid[2]}
            if cell then
                if not checkRestrictions(cell.name or "123") then goto continue end

                local notFoundFlag = getNotFoundFlag(cell)

                local descr = tes.getCellData(cell).name

                local pos = util.vector3(x, y, z)
                local newPosData = tableLib.copy(posDt)
                if ownerId then
                    newPosData.type = 2
                    newPosData.id = ownerId
                else
                    newPosData.type = 1
                end

                foundValidPos = foundValidPos or not notFoundFlag
                table.insert(arr, {description = descr, id = nil, position = pos, exitPos = pos, isExitEx = true, rawData = newPosData, notFound = notFoundFlag})
            end
        end

        ::continue::
    end

    return foundValidPos
end


local function addCellData(cell, id, arr, configData)
    if not cell.id then return end

    local useAdvCell = cellAdvLib.isReady()
    local findExitPosFunc
    local findExitPositionsFunc
    local findNearestDoorFunc
    if useAdvCell then
        findExitPosFunc = cellAdvLib.findExitPos
        findExitPositionsFunc = cellAdvLib.findExitPositions
        findNearestDoorFunc = cellAdvLib.findNearestDoor
    else
        findExitPosFunc = cellLib.findExitPos
        findExitPositionsFunc = cellLib.findExitPositions
        findNearestDoorFunc = cellLib.findNearestDoor
    end

    if not cell.isExterior then
        local exCellPos, doorPath, cellPath, isExterior, checkedCells = findExitPosFunc(useAdvCell and cell.id or cell)

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
            local exitPositions, _, entranceCells, lowestDepth = findExitPositionsFunc(useAdvCell and cell.id or cell)
            if exitPositions then
                for _, pDt in pairs(exitPositions) do
                    if pDt.depth <= lowestDepth + 1 then
                        local nearestDoor = findNearestDoorFunc(pDt.pos)
                        if nearestDoor then
                            table.insert(exits, useAdvCell and nearestDoor.pos or nearestDoor.position)
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


---@param objectData questDataGenerator.objectInfo
---@param outD questGuider.quest.getRequirementPositionData.returnData?
---@return boolean? foundValidPos
local function fillLinkPositionData(posArr, objectData, configData, outD)
    if not objectData.links then return end

    local foundDirectLinks
    local foundValidPos = false

    for _, linkData in ipairs(objectData.links or {}) do
        local objId = linkData[1]
        local objChance = linkData[2]

        local objDt = this.getObjectData(objId)
        if not objDt then goto continue end

        if objDt.type <= 2 then
            if (objChance or 0) >= configData.tracking.minChance * 0.01 then
                local obj = tes.getObject(objId)
                if not obj then goto continue end

                local hasValidPos = addPosData(posArr, objDt, objId, configData, obj)
                foundValidPos = foundValidPos or hasValidPos
                foundDirectLinks = true

                if outD then
                    outD.inWorld = (outD.inWorld or 0) + (objDt.inWorld or 0)
                end
            end
        elseif objDt.type == 6 then
            if not objDt.links then goto continue end
            for _, lDt in pairs(objDt.links) do
                if (lDt[2] or 0) < configData.tracking.minChance * 0.01 then goto continue end

                local lObjDt = this.getObjectData(lDt[1])
                if not lObjDt or lObjDt.type > 2 then goto continue end

                local obj = tes.getObject(lDt[1])
                if not obj then goto continue end

                local hasValidPos = addPosData(posArr, lObjDt, lDt[1], configData, obj)
                foundValidPos = foundValidPos or hasValidPos
                foundDirectLinks = foundDirectLinks or false

                if outD then
                    outD.inWorld = (outD.inWorld or 0) + (lObjDt.inWorld or 0)
                end

                ::continue::
            end
        end

        if outD and foundDirectLinks == false then
            outD.disableInventoryTracking = true
        end

        ::continue::
    end

    return foundValidPos
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
---@field notFound boolean? true, if the object is not found in the game world

---@class questGuider.quest.getRequirementPositionData.returnData
---@field reqType string requirement type
---@field name string name of the object
---@field inWorld integer? number of instances of the object in the game world
---@field parentObject string?
---@field itemCount integer? item count from *types.requirementType.Item*
---@field disableInventoryTracking boolean? disables checking for the object in the object inventory if true, because the object is not directly linked to the requirement
---@field actorCount integer? kill count from *types.requirementType.Dead*
---@field isActorAliveReq boolean? true if the requirement is to have the actor alive
---@field positions questGuider.quest.getRequirementPositionData.positionData[]
---@field foundValidPos boolean true if at least one valid position is found for the requirement

---@param requirement questDataGenerator.requirementData
---@param customConfig questGuider.config?
---@param questId string
---@param params {cellRestrictions: table<string, boolean>?}?
---@return table<string, questGuider.quest.getRequirementPositionData.returnData>? ret by object id
---@return table<string, {index: integer, qData: questDataGenerator.questData}>? linkedQuests
function this.getRequirementPositionData(requirement, customConfig, questId, params)

    local reqHash = myTypes.getRequirementHash(requirement)
    local cachedVal = cacheLib.get("requirementPosData", reqHash)
    if cachedVal then
        return table.unpack(cachedVal) ---@diagnostic disable-line: redundant-return-value
    end

    local configData = customConfig
    if not configData then
        log("Error: no config data provided for getRequirementPositionData")
        return
    end
    local trackingConfig = configData.tracking

    if requirement.type == myTypes.requirementType.CustomDialogue or
            requirement.type == myTypes.requirementType.CustomPos then
        return
    end

    local linkedQuests = {}

    ---@type table<string, questGuider.quest.getRequirementPositionData.returnData>
    local out = {}

    local objects = {}
    ---@type table<tes3cell, string>
    local cells = {}

    local requirements = {requirement}


    local function fillDataForScriptByTableName(scriptId, tableName)
        local scrData = dataHandler.questObjects[scriptId]
        if not scrData or not scrData[tableName] then return end

        if scrData and scrData[tableName] then
            for _, linkDt in pairs(scrData[tableName]) do
                if linkDt[2] ~= nil and linkDt[2] >= configData.tracking.minChance * 0.01 then
                    local objData = dataHandler.questObjects[linkDt[1]]
                    if objData and objData.type <= 2 then
                        local obj, tp = tes.getObject(linkDt[1])
                        if obj then
                            objects[linkDt[1]] = {obj, tp}
                        end
                    end
                end
            end
        end
    end

    if requirement.type == myTypes.requirementType.Journal
            and not ((requirement.operator == myTypes.operator.value.Equal or requirement.operator == myTypes.operator.value.LessOrEqual) and requirement.value == 0)
            and not (requirement.operator == myTypes.operator.value.Less and requirement.value == 1) then
        local index = playerQuests.getCurrentIndex(requirement.variable or "")
        if not index or index == 0 then
            local qDt = this.getQuestData(requirement.variable)
            if qDt and qDt.givers then
                linkedQuests = linkedQuests or {}
                linkedQuests[requirement.variable] = linkedQuests[requirement.variable] or {
                    index = this.getFirstIndex(qDt),
                    qData = qDt
                }

                for _, giverId in pairs(qDt.givers) do
                    local giverData = dataHandler.questObjects[giverId]
                    if giverData then
                        if giverData.type <= 2 then
                            local obj, tp = tes.getObject(giverId)
                            if obj then
                                objects[giverId] = {obj, tp}
                            end
                        elseif giverData.type == 4 then
                            fillDataForScriptByTableName(giverId, "links")
                        end
                    end
                end
            end
        end
    end


    if requirement.type == myTypes.requirementType.CustomActor and requirement.object then
        local obj, tp = tes.getObject(requirement.object)
        if obj then
            objects[requirement.object] = {obj, tp}
        end

    elseif requirement.type == myTypes.requirementType.CustomScript and (requirement.script or requirement.variable) then
        fillDataForScriptByTableName(requirement.script or requirement.variable, "links")

    elseif requirement.type == myTypes.requirementType.CustomLocal and (not requirement.object and not requirement.script) then
        local foundScripts = {}
        local foundDias = {}
        local varData = this.getObjectData(requirement.variable)

        -- TODO: dehardcode limit
        if varData and varData.links and (varData.total or 0) <= 10 and #varData.links <= 10 then
            for _, dt in ipairs(varData.links) do
                if dt[2] ~= nil then break end

                local objData = this.getObjectData(dt[1])
                if objData then
                    if objData.type == 4 then
                        foundScripts[dt[1]] = objData
                    elseif objData.type == 3 then
                        foundDias[dt[1]] = objData
                    end
                end
            end
        end

        local foundValid = false
        for scrId, scrObjDt in pairs(foundScripts) do
            for _, dt in pairs(scrObjDt.stages or {}) do
                if dt.id == questId then
                    for _, linkDt in ipairs(scrObjDt.links or {}) do
                        if linkDt[2] ~= nil then break end

                        if not objects[linkDt[1]] then
                            local objData = this.getObjectData(linkDt[1])
                            if objData and objData.type <= 2 then
                                local obj, tp = tes.getObject(linkDt[1])
                                if obj then
                                    objects[linkDt] = {obj, tp}
                                end
                            end
                        end
                    end

                    foundValid = true
                    break
                end
            end
        end

    elseif requirement.type == "SCR1" and requirement.value then
        fillDataForScriptByTableName(requirement.value, "contains")

    else
        for _, req in pairs(requirements) do

            if req.type == myTypes.requirementType.CustomScript and req.variable then
                fillDataForScriptByTableName(req.variable, "links")
            end

            for name, value in pairs(req) do
                if value == "" then goto continue end

                if type(value) ~= "string" then
                    goto continue
                end

                local obj, tp = tes.getObject(value)
                if obj then
                    objects[value] = {obj, tp}
                    goto continue
                end

                if cellRequirementTypes[req.type] then
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
                                local obj1, tp1 = tes.getObject(linkId)
                                if obj1 then
                                    objects[linkId] = {obj1, tp1}
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

    for id, objectDt in pairs(objects) do
        local positions = {}
        local object = objectDt[1]

        local objectData = this.getObjectData(id)
        if not objectData then goto continue end

        local foundValidPos = addPosData(positions, objectData, nil, configData, object, params and params.cellRestrictions)

        if not out[id] then
            out[id] = {reqType = requirement.type, name = object.name or object.id or "", positions = {}, foundValidPos = foundValidPos or false}
        end

        local outD = out[id]
        if outD then
            outD.inWorld = objectData.inWorld or 0
        end

        foundValidPos = foundValidPos or fillLinkPositionData(positions, objectData, configData, outD)

        outD.positions = positions
        outD.foundValidPos = foundValidPos

        ::continue::
    end

    for cell, id in pairs(cells) do
        if not out[id] then
            out[id] = {reqType = requirement.type, name = cell.displayName or cell.name or cell.id or "", positions = {}, foundValidPos = false}
        end
        addCellData(cell, id, out[id].positions, configData)
        out[id].foundValidPos = next(out[id].positions) and true or false
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
                    if data.actorCount == nil then
                        data.isActorAliveReq = true
                    end
                    data.itemCount = nil
                end
            end
        end

    elseif requirement.type == myTypes.requirementType.CustomScript then
        for id, data in pairs(out) do
            local objDt = objects[id]
            if not objDt then goto continue end

            local obj = objDt[1]
            local objTp = objDt[2]

            if isItemType(objTp) then
                data.parentObject = id
                data.itemCount = 1
            end

            ::continue::
        end
    end

    cacheLib.set("requirementPosData", reqHash, {out, linkedQuests})

    return out, linkedQuests
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
    if objectId == "" then return {} end
    if not params then params = {} end

    local configData = params.customConfig
    if not configData then
        log("Error: no config data provided for getPositions")
        return
    end

    local trackingConfig = configData.tracking

    ---@type questGuider.quest.getRequirementPositionData.positionData[]
    local positions = {}

    local objectData = this.getObjectData(objectId)

    if not objectData then
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

        return
    end

    local object = tes.getObject(objectId)
    addPosData(positions, objectData, nil, configData, object)

    local linkPositions
    if params.findLinks then
        linkPositions = {}

        fillLinkPositionData(linkPositions, objectData, configData)

        if params.includeLinks then
            tableLib.addValues(linkPositions, positions)
        end
    end

    return positions, linkPositions
end


this.checkConditionsForQuest = questBase.checkConditionsForQuest


---@param objData questDataGenerator.objectInfo
---@param maxNames integer
---@param configData table
---@return string[]
function this.getObjectPositionDescription(objData, maxNames, configData)
    local approxEnabled = configData.tracking.approx.enabled

    local descriptions = {}
    for _, posDt in pairs(objData.positions) do
        local x = posDt.pos[1]
        local y = posDt.pos[2]
        local z = posDt.pos[3]

        local descr

        if posDt.name then
            local cell = tes.getCell{id = posDt.name}
            if cell then
                local exCellPos, doorPath, cellPath, isExterior, checkedCells = cellLib.findExitPos(cell)

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