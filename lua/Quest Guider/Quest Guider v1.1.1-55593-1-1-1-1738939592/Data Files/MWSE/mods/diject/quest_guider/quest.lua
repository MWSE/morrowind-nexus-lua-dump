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

---@param questId string
---@return { name: string, [string]: questDataGenerator.stageData }|nil
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
---@return string[]|nil
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
---@return string|nil
function this.getFirstIndex(questData)
    local indexes = this.getIndexes(questData)
    if not indexes or #indexes == 0 then return end

    return indexes[1]
end

---@param questData string|questDataGenerator.questData
---@param questIndex integer|string
---@return string[]|nil
function this.getNextIndexes(questData, questIndex)
    if not questData then return end
    if type(questData) == "string" then
        questData = this.getQuestData(questData)
    end
    if not questData then return end
    local tpData = questData[tostring(questIndex)]
    if not tpData then return end

    local nextIndexes = {}
    local foundNextIndex = false
    if tpData.next then
        for _, ind in pairs(tpData.next) do
            nextIndexes[ind] = true
            foundNextIndex = true
        end
    end
    if not foundNextIndex and tpData.nextIndex then
        nextIndexes[tpData.nextIndex] = true
    end

    nextIndexes = table.keys(nextIndexes)

    if #nextIndexes == 0 then return end

    table.sort(nextIndexes)

    return nextIndexes
end

---@param objectData string|questDataGenerator.objectInfo?
---@return integer?
function this.getObjectCount(objectData)
    if objectData and type(objectData) == "string" then
        objectData = this.getObjectData(objectData)
    end

    if not objectData then return end

    local count = objectData.inWorld

    for _, linkId in pairs(objectData.links or {}) do
        local linkData = this.getObjectData(linkId)
        if linkData then
            count = count + (linkData.inWorld or 0)
        end
    end

    return count
end

---@param tb string[] table with object ids
---@return table<string, string> out name by object id
---@return integer count
function this.getObjectNamesFromTable(tb)
    local out = {}
    local count = 0
    for _, id in pairs(tb or {}) do
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

---@class questGuider.quest.getDescriptionDataFromBlock.returnArr
---@field str string
---@field priority number
---@field objects table<string, string>|nil
---@field positionData table<string, questGuider.quest.getRequirementPositionData.returnData>?
---@field data questDataGenerator.requirementData

---@alias questGuider.quest.getDescriptionDataFromBlock.return questGuider.quest.getDescriptionDataFromBlock.returnArr[]

---@param reqBlock table<integer, questDataGenerator.requirementData>
---@param questId string?
---@return questGuider.quest.getDescriptionDataFromBlock.return|nil
function this.getDescriptionDataFromDataBlock(reqBlock, questId)
    if not reqBlock then return end

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

    local objectObj

    ---@param requirement questDataGenerator.requirementData
    local function processRequirement(requirement)
        if disallowedRequirementTypes[requirement.type] then goto continue end

        if requirement.type == types.requirementType.Journal and requirement.variable == questId then
            goto continue
        end

        ---@type questGuider.quest.getDescriptionDataFromBlock.returnArr
        local reqOut = {str = "", priority = 0, data = requirement}

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
            objectObj = objectObj,
            variableObj = nil,
            valueObj = nil,
            variableQuestName = "???",
            valueStr = "???",
            variableStr = "???",
            weaponTypeName = weaponTypeNameById,
            magicEffectConsts = magicEffectConsts,
        }
        if object then
            objectObj = tes3.getObject(object)
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
                            local objs, count = this.getObjectNamesFromTable(scrData.links)

                            if count > 0 then
                                res = stringLib.getValueEnumString(objs, config.data.journal.objectNames, "%s")
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
                            local objs, count = this.getObjectNamesFromTable(scrData.contains)

                            if count > 0 then
                                res = stringLib.getValueEnumString(objs, config.data.journal.objectNames, "%s")
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
            reqOut.str = tableLib.tableToStrLine(requirement) or "???"
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
                for _, id in pairs(scrData.links) do
                    local linkData = dataHandler.questObjects[id]
                    if linkData and (linkData.type <= 2) then
                        objects[id] = id
                    end
                end
            end
        end

        if table.size(objects) > 0 then
            reqOut.objects = objects
        end

        reqOut.positionData = this.getRequirementPositionData(requirement)

        table.insert(out, reqOut)

        if requirement.type == types.requirementType.CustomScript and environment.script then
            local scrData = dataHandler.questObjects[environment.script]
            if scrData and scrData.contains then
                local objs, count = this.getObjectNamesFromTable(scrData.contains)

                if count > 0 then
                    processRequirement({type = "SCR1", operator = 48, value = environment.script})
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
        diaOutData.isFinished = dialogue.journalIndex and storageData[tostring(dialogue.journalIndex)].finished or nil

        -- TODO
        -- diaOutData.isReachable = math.random() > 0.25 and true or false

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
---@field id string? cell id
---@field position tes3vector3?
---@field exitPos tes3vector3?
---@field doorPath tes3travelDestinationNode[]?
---@field cellPath tes3cell[]?
---@field rawData questDataGenerator.objectPosition?
---@field isExitEx boolean?

---@class questGuider.quest.getRequirementPositionData.returnData
---@field name string
---@field inWorld integer?
---@field positions questGuider.quest.getRequirementPositionData.positionData[]

---@param requirement questDataGenerator.requirementData
---@return table<string, questGuider.quest.getRequirementPositionData.returnData>? ret by object id
function this.getRequirementPositionData(requirement)

    local approxConfig = config.data.tracking.approx

    if requirement.type == types.requirementType.CustomDialogue then
        return
    end

    ---@type table<string, questGuider.quest.getRequirementPositionData.returnData>
    local out = {}

    local objects = {}
    ---@type table<tes3cell, string>
    local cells = {}

    local requirements = {requirement}

    if requirement.type == types.requirementType.Journal and playerQuests.isInitialized() then
        local index = playerQuests.getCurrentIndex(requirement.variable or "")
        if not index or index == 0 then
            local qDt = this.getQuestData(requirement.variable)
            if qDt then
                local stageData = qDt["1"]
                if not stageData then
                    local keys = {}
                    for n, _ in pairs(qDt) do
                        local num = tonumber(n)
                        if num then
                            table.insert(keys, num)
                        end
                    end
                    table.sort(keys)
                    stageData = qDt[tostring(keys[1])]
                end

                if stageData then
                    for _, block in pairs(stageData.requirements or {}) do
                        for _, req in pairs(block) do
                            table.insert(requirements, req)
                        end
                    end
                end
            end
        end
    end

    local function fillDataForScriptByTableName(scriptId, tableName)
        local scrData = dataHandler.questObjects[scriptId]
        if not scrData or not scrData[tableName] or not tes3.getScript(scriptId) then return end

        for _, id in pairs(scrData[tableName]) do
            local linkData = dataHandler.questObjects[id]
            if linkData and (linkData.type <= 2) then
                local obj = tes3.getObject(id)
                if obj then
                    objects[obj] = id
                end
            end
        end
    end

    if requirement.type == types.requirementType.CustomScript and requirement.script then
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
                end
                local cell = tes3.getCell{id = value}
                if cell then
                    cells[cell] = value
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
                                descr = stringLib.getValueEnumString(list, config.data.journal.objectNames, "Reachable from %s")
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

        for _, linkId in pairs(objectData.links or {}) do
            local obj = tes3.getObject(linkId)
            local objDt = this.getObjectData(linkId)
            if obj and objDt and (objDt.type <= 3) then
                addPosData(objDt, linkId)
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
                    descr = stringLib.getValueEnumString(list, config.data.journal.objectNames, "Reachable from %s")
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


---@param questId string
---@param questIndex integer|string
---@return boolean?
function this.checkConditionsForPlayer(questId, questIndex)
    local questData = this.getQuestData(questId)
    if not questData then return end

    local indexStr = tostring(questIndex)
    local stageData = questData[indexStr]
    if not stageData then return end

    local operator = types.operator
    local requirements = stageData.requirements or {}

    if #requirements == 0 then return true end

    for _, reqBlock in pairs(stageData.requirements or {}) do
        local ret = true

        for _, req in pairs(reqBlock) do

            if req.type == types.requirementType.Journal then
                local plIndex = playerQuests.getCurrentIndex(req.variable) or 0
                if not operator.check(plIndex, req.value, req.operator) then
                    ret = false
                    break
                end

            elseif (req.type == types.requirementType.CustomActorFaction or req.type == types.requirementType.CustomPCFaction) and req.object == "player" then
                local faction = tes3.getFaction(req.value)
                if not operator.check(faction, req.value, req.operator) then
                    ret = false
                    break
                end

            elseif (req.type == types.requirementType.RankRequirement or req.type == types.requirementType.CustomPCRank) and req.object == "player" then
                local faction = tes3.getFaction(req.variable)
                if not operator.check(faction, req.value, req.operator) then
                    ret = false
                    break
                end
            end

        end

        if ret then
            return true
        end
    end

    return false
end

return this