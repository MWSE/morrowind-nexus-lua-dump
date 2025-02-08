local questLib = include("diject.quest_guider.quest")
local playerQuests = include("diject.quest_guider.playerQuests")
local config = include("diject.quest_guider.config")

local stringLib = include("diject.quest_guider.utils.string")

local this = {}

local objectTooltipMenu = {
    block = "qGuider_objectTooltip_block",
    involvedLabel = "qGuider_objectTooltip_involvedLabel",
    startsLabel = "qGuider_objectTooltip_startsLabel",
}

local doorTooltipMenu = {
    block = "qGuider_doorTooltip_block",
    startersLabel = "qGuider_doorTooltip_starters",
    npcsLabel = "qGuider_doorTooltip_npcs",
    objectsLabel = "qGuider_doorTooltip_objects",
}

---@param parent tes3uiElement
---@param objectId string
---@return boolean|nil
function this.drawObjectTooltip(parent, objectId)
    objectId = objectId:lower()
    local objectInfo = questLib.getObjectData(objectId)
    if not objectInfo then return end

    local involvedQuests = {}

    local involvedNames = {}
    for _, stageData in pairs(objectInfo.stages or {}) do
        local oldIndex = involvedQuests[stageData.id] or 0
        involvedQuests[stageData.id] = math.max(oldIndex, stageData.index)
    end

    if objectInfo.total and objectInfo.total <= config.data.tooltip.tracking.maxPositions then
        for _, objId in pairs(objectInfo.contains or {}) do

            local objDt = questLib.getObjectData(objId)
            if not objDt or objDt.type > 3 then goto continue end

            if objDt.total > config.data.tooltip.tracking.maxPositions then goto continue end

            for _, stageData in pairs(objDt.stages or {}) do
                local oldIndex = involvedQuests[stageData.id] or 0
                involvedQuests[stageData.id] = math.max(oldIndex, stageData.index)
            end

            ::continue::
        end
    end

    for questId, maxIndex in pairs(involvedQuests) do
        local questData = questLib.getQuestData(questId)
        if not questData or not questData.name then goto continue end

        local playerData = playerQuests.getQuestData(questId)
        if not playerData or (config.data.tracking.giver.hideStarted and playerData.index >= maxIndex) then goto continue end

        table.insert(involvedNames, questData.name)

        ::continue::
    end

    local startsNames = {}
    if objectInfo.starts then
        for _, questId in pairs(objectInfo.starts) do
            local questData = questLib.getQuestData(questId)
            if not questData or not questData.name then goto continue end

            local playerData = playerQuests.getQuestData(questId)
            if not playerData or (config.data.tracking.giver.hideStarted and playerData.index > 0) then goto continue end

            table.insert(startsNames, questData.name)

            ::continue::
        end
    end


    local involvedQuestNamesStr = stringLib.getValueEnumString(involvedNames, config.data.tooltip.object.invNamesMax, " (%s)")
    local involvedCount = #involvedNames
    local startsQuestNamesStr = stringLib.getValueEnumString(startsNames, config.data.tooltip.object.startsNamesMax, " (%s)")
    local startsCount = #startsNames

    if involvedCount <= 0 and startsCount <= 0 then return end


    local block = parent:createBlock{ id = objectTooltipMenu.objectTooltipMenu }
    block.flowDirection = tes3.flowDirection.topToBottom
    block.autoHeight = true
    block.autoWidth = true
    block.maxWidth = config.data.tooltip.width

    if startsCount > 0 then
        local text = string.format("Starts %d quest%s%s.", startsCount, startsCount == 1 and "" or "s", startsQuestNamesStr)

        local label = block:createLabel{
            id = objectTooltipMenu.startsLabel,
            text = text,
        }
        label.wrapText = true
        label.borderTop = 3
    end

    if involvedCount > 0 then
        local text = string.format("Involved in %d quest%s%s.", involvedCount, involvedCount == 1 and "" or "s", involvedQuestNamesStr)

        local label = block:createLabel{
            id = objectTooltipMenu.involvedLabel,
            text = text,
        }
        label.wrapText = true
        label.borderTop = 3
    end

    return true
end

---@param parent tes3uiElement
---@param reference tes3reference
---@return boolean|nil
function this.drawDoorTooltip(parent, reference)
    if not reference or not reference.destination or
            reference.destination.cell.isOrBehavesAsExterior then
        return
    end

    local tooltipConfig = config.data.tooltip
    local markerCellName = reference.cell.editorName
    local innerCells = {  }

    ---@param cell tes3cell
    local function findInnerCells(cell)
        if cell.isOrBehavesAsExterior or cell.editorName == markerCellName then
            return
        end

        if not innerCells[cell.editorName] then
            innerCells[cell.editorName] = cell
        else
            return
        end

        for doorRef in cell:iterateReferences(tes3.objectType.door) do
            if doorRef.destination then
                findInnerCells(doorRef.destination.cell)
            end
        end
    end

    findInnerCells(reference.destination.cell)

    local startsQuest = {}
    ---@type table<string, questDataGenerator.objectInfo>
    local questObjects = {}

    for _, cell in pairs(innerCells) do
        for ref in cell:iterateReferences() do
            local objId = ref.baseObject.id:lower()
            local objData = questLib.getObjectData(objId)
            if not objData then goto continue end

            if objData.starts then
                startsQuest[objId] = objData.starts
            end

            if objData.total > config.data.tooltip.tracking.maxPositions then goto continue end

            local valid = false

            if config.data.tracking.giver.hideStarted then
                local quests = {}
                for _, stage in pairs(objData.stages) do
                    local oldIndex = quests[stage.id] or 0
                    quests[stage.id] = math.max(oldIndex, stage.index)
                end
                for qId, maxIndex in pairs(quests) do
                    local playerData = playerQuests.getQuestData(qId)
                    if not playerData or playerData.index <= maxIndex then
                        valid = true
                        break
                    end
                end
            else
                valid = true
            end

            if not valid then goto continue end

            questObjects[objId] = objData
            for _, oId in pairs(objData.contains or {}) do

                local objDt = questLib.getObjectData(oId)
                if not objDt then goto continue end

                if objDt.starts then
                    startsQuest[oId] = objDt.starts
                end

                if objDt.total > config.data.tooltip.tracking.maxPositions then goto continue end

                questObjects[oId] = objData

                ::continue::
            end

            ::continue::
        end
    end

    local startsQuestCount = table.size(startsQuest)
    local questObjectsCount = table.size(questObjects)

    if startsQuestCount <= 0 and questObjectsCount <= 0 then return end

    local block = parent:createBlock{ id = doorTooltipMenu.block }
    block.flowDirection = tes3.flowDirection.topToBottom
    block.autoHeight = true
    block.autoWidth = true
    block.maxWidth = tooltipConfig.width

    if startsQuestCount > 0 then
        local questHTable = {}
        local npcNames = {}
        for objId, quests in pairs(startsQuest) do
            for _, qId in pairs(quests) do
                questHTable[qId] = true
            end

            local obj = tes3.getObject(objId)
            if not obj then goto continue end

            npcNames[obj] = obj.name
            ::continue::
        end

        local questNames = {}
        for qId, _ in pairs(questHTable) do
            local questData = questLib.getQuestData(qId)
            if not questData or not questData.name then goto continue end

            local playerData = playerQuests.getQuestData(qId)
            if not playerData or (config.data.tracking.giver.hideStarted and playerData.index > 0) then goto continue end

            questNames[questData.name] = questData.name
            ::continue::
        end

        local npcsStr = stringLib.getValueEnumString(npcNames, tooltipConfig.door.starterNames, " (%s)")
        local questStr = stringLib.getValueEnumString(questNames, tooltipConfig.door.starterQuestNames, " (%s)")

        local label = block:createLabel{
            id = doorTooltipMenu.startersLabel,
            text = string.format("%d NPC%s%s that can start a quest%s.",
                startsQuestCount, startsQuestCount == 1 and "" or "s", npcsStr, questStr),
        }
        label.wrapText = true
        label.borderTop = 3
    end

    if questObjectsCount > 0 then

        local qObjectsNameTable = {}
        local qNPCsNameTable = {}
        for objId, data in pairs(questObjects) do

            local obj = tes3.getObject(objId)
            if not obj then goto continue end
            if obj.objectType == tes3.objectType.npc or obj.objectType == tes3.objectType.creature then
                qNPCsNameTable[obj.id] = obj.name
            else
                qObjectsNameTable[obj.id] = obj.name
            end

            ::continue::
        end

        local qObjectsCount = table.size(qObjectsNameTable)
        local qObjestsStr = stringLib.getValueEnumString(qObjectsNameTable, tooltipConfig.door.objectNames, " (%s)")

        local npcsCount = table.size(qNPCsNameTable)
        if npcsCount > 0 then
            local npcsStr = stringLib.getValueEnumString(qNPCsNameTable, tooltipConfig.door.npcNames, " (%s)")

            local label = block:createLabel{
                id = doorTooltipMenu.npcsLabel,
                text = string.format("%d quest NPC%s%s.",
                npcsCount, npcsCount == 1 and "" or "s", npcsStr)
            }
            label.wrapText = true
            label.borderTop = 3
        end

        if qObjectsCount > 0 then
            local label = block:createLabel{
                id = doorTooltipMenu.objectsLabel,
                text = string.format("%d different quest object%s%s.",
                qObjectsCount, qObjectsCount == 1 and "" or "s", qObjestsStr)
            }
            label.wrapText = true
            label.borderTop = 3
        end
    end

    return true
end

return this