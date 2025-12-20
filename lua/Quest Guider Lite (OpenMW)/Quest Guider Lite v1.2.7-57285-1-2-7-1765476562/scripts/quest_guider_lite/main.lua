local async = require('openmw.async')
local world = require('openmw.world')
local types = require('openmw.types')
local time = require('openmw_aux.time')

local config = require("scripts.quest_guider_lite.config")

local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")

local log = require("scripts.quest_guider_lite.utils.log")
local dataHandler = require("scripts.quest_guider_lite.storage.dataHandler")
local questLib = require("scripts.quest_guider_lite.quest")
local testing = require("scripts.quest_guider_lite.testing.tests")
local questGivers = require("scripts.quest_guider_lite.questGiverTracking")
local trackingGlobal = require("scripts.quest_guider_lite.trackingGlobal")
local cellLib = require("scripts.quest_guider_lite.cell")
local common = require("scripts.quest_guider_lite.common")
local killCounter = require("scripts.quest_guider_lite.killCounter")
local requirementChecker = require("scripts.quest_guider_lite.requirementChecker")
local playerQuests = require('scripts.quest_guider_lite.playerQuests')

local l10n = require('openmw.core').l10n(common.l10nKey)


---@class questGuider.main.fillQuestBoxQuestInfo.returnFieldDt
---@field requirements questGuider.quest.getDescriptionDataFromBlock.return[]
---@field index integer

---@alias questGuider.main.fillQuestBoxQuestInfo.returnDt table<string, questGuider.main.fillQuestBoxQuestInfo.returnFieldDt[]> by dia id, sorted by index
---@alias questGuider.main.fillQuestBoxQuestInfo.returnBlock {next : questGuider.main.fillQuestBoxQuestInfo.returnDt?, linked : questGuider.main.fillQuestBoxQuestInfo.returnDt?, objectPositions : table<string, questGuider.quest.getRequirementPositionData.returnData>, diaId : string, diaIndex : integer}

---@alias questGuider.main.fillQuestBoxQuestInfo.return {data : table<integer, questGuider.main.fillQuestBoxQuestInfo.returnBlock>, menuId : string} data by content id


local function onInit()
    -- dataHandler.init()
    -- testing.descriptionLines()
end

local function onLoad()
    -- dataHandler.init()
    -- testing.printRandomQuestList()
end


local function onObjectActive(ref)
    if types.Actor.objectIsInstance(ref) then
        if not ref:hasScript("scripts/quest_guider_lite/actor.lua") then
            ref:addScript("scripts/quest_guider_lite/actor.lua")
        end
    end

    async:newUnsavableSimulationTimer(0.2, function ()
        if (ref.type == types.NPC or ref.type == types.Creature) and config.data.tracking.questGivers then
            questGivers.createQuestGiverMarker(ref)
        end
        if types.Door.objectIsInstance(ref) and types.Door.isTeleport(ref) then
            if ref.cell.isExterior then
                world.players[1]:sendEvent("QGL:createMarkersForDoor", ref)
            end
            if config.data.tracking.questGivers then
                questGivers.createQuestGiverMarkerForDoor(ref)
            end
        end
    end)
end


local function genMapRegionNames()
    local cellNameData = {}
    for _, cell in pairs(world.cells) do
        if not cell.isExterior then goto continue end
        if not cell.name or cell.name == "" then goto continue end

        local nameId = stringLib.getBeforeComma(cell.name)

        local cellDt = cellNameData[nameId]
        if not cellDt then
            cellDt = {
                name = stringLib.getBeforeComma(cell.displayName or cell.name), count = 0,
                minX = math.huge, maxX = -math.huge,
                minY = math.huge, maxY = -math.huge,
            }
            cellNameData[nameId] = cellDt
        end

        cellDt.minX = math.min(cell.gridX, cellDt.minX)
        cellDt.minY = math.min(cell.gridY, cellDt.minY)
        cellDt.maxX = math.max(cell.gridX, cellDt.maxX)
        cellDt.maxY = math.max(cell.gridY, cellDt.maxY)
        cellDt.count = cellDt.count + 1

        ::continue::
    end

    local cellNameLines = {}
    local cellNames = {}
    for _, dt in pairs(cellNameData) do
        if dt.count < 1 then goto continue end

        local posX = (dt.minX + (dt.maxX - dt.minX) / 2) * 8192 + 4096
        local posY = (dt.minY + (dt.maxY - dt.minY) / 2) * 8192 + 4096

        local cellDt = {
            name = dt.name,
            count = dt.count,
            posX = posX,
            posY = posY,
        }
        table.insert(cellNames, cellDt)

        local hash = math.floor(posY / 4096)
        for i = -1, 1 do
            local h = hash + i
            cellNameLines[h] = cellNameLines[h] or {}
            table.insert(cellNameLines[h], cellDt)
        end

        ::continue::
    end


    local function processLines(lines, xPosDiff, heightDiff)
        local heightDiffHalf = heightDiff / 2
        for _, lineElems in pairs(lines) do

            table.sort(lineElems, function (a, b)
                return a.posX < b.posX
            end)

            for j = 2, #lineElems do
                local el1 = lineElems[j - 1]
                local el2 = lineElems[j]
                if el2.posX - el1.posX < xPosDiff and math.abs(el2.posY - el1.posY) < heightDiff then
                    if el1.posY > el2.posY then
                        el1.posY = el1.posY + heightDiffHalf
                        el2.posY = el2.posY - heightDiffHalf
                    else
                        el1.posY = el1.posY - heightDiffHalf
                        el2.posY = el2.posY + heightDiffHalf
                    end
                end
            end
        end
    end

    processLines(cellNameLines, 8192 * 6, 4096)

    world.players[1]:sendEvent("QGL:updateCityInfo", cellNames)
end

genMapRegionNames()


local function objectInactive(ref)
    if ref:hasScript("scripts/quest_guider_lite/actor.lua") then
        ref:removeScript("scripts/quest_guider_lite/actor.lua")
    end
end


---@param params {diaId : string, diaIndex : number|string, objectId : string?, priority : number?}
local function addMarkersForQuest(params)

    local questData = questLib.getQuestData(params.diaId)
    if not questData then return end

    local indexStr = tostring(params.diaIndex)
    local indexData = questData[indexStr]
    if not indexData then return end

    local objects = {}

    for i, reqDataBlock in pairs(indexData.requirements or {}) do

        local requirementData = questLib.getDescriptionDataFromDataBlock(reqDataBlock)
        if not requirementData then goto continue end

        for _, requirement in ipairs(requirementData) do
            for objId, posData in pairs(requirement.positionData or {}) do
                if params.objectId and params.objectId ~= objId then goto continue end

                if posData then
                    ---@type questGuider.tracking.addMarker
                    local eventParams = {
                        questId = params.diaId,
                        objectId = objId,
                        objectName = posData.name,
                        positionData = posData,
                        questData = questData,
                        questStage = params.diaIndex,
                        reqData = requirement,
                        priority = params.priority,
                    }
                    world.players[1]:sendEvent("QGL:addMarker", eventParams)

                    objects[objId] = posData.name
                end

                ::continue::
            end
        end

        ::continue::
    end

    return objects
end


---@param params {menuId : string, useCurrentIndex : boolean?, data: table<string, {diaId : string, index : integer, contentIndex : integer}>}
local function fillQuestBoxQuestInfo(params)
    ---@type table<integer, questGuider.main.fillQuestBoxQuestInfo.returnBlock>
    local out = {}

    local function getDtArr(t, diaId, index)
        if not t[diaId] then t[diaId] = {} end
        local isNew = false
        local indexStr = tostring(index)
        if not t[diaId][indexStr] then
            t[diaId][indexStr] = {
                requirements = {},
            }
            isNew = true
        end
        return t[diaId][indexStr], isNew
    end

    local function removeDtArr(t, diaId, index)
        local indexStr = tostring(index)
        if t[diaId][indexStr] then
            t[diaId][indexStr] = nil
        end
        if not next(t[diaId]) then
            t[diaId] = nil
        end
    end

    for _, diaInfo in pairs(params.data) do
        local diaId = diaInfo.diaId
        local qData = questLib.getQuestData(diaId)
        if not qData then goto continue end

        local questNextIndexes, linkedIndexData
        if params.useCurrentIndex then
            questNextIndexes = {diaInfo.index}
        else
            questNextIndexes, linkedIndexData = questLib.getNextIndexes(qData, diaId, diaInfo.index, {findCompleted = false, findInLinked = true})
        end
        if not questNextIndexes and not linkedIndexData then goto continue end

        local function getData(qData, index, arr)
            local indexStr = tostring(index)
            local indexData = qData[indexStr]
            if not indexData then return end

            arr.index = tonumber(index)

            for i, reqDataBlock in pairs(indexData.requirements or {}) do
                local requirementData = questLib.getDescriptionDataFromDataBlock(reqDataBlock)
                if not requirementData then goto continue end

                table.insert(arr.requirements, requirementData)

                ::continue::
            end
        end

        ---@type questGuider.main.fillQuestBoxQuestInfo.returnBlock
        local res = out[diaInfo.contentIndex] or {
            diaId = diaId,
            diaIndex = diaInfo.index,
            next = {},
            linked = {},
        }

        local function fillRes(qData, tb, diaId, index)
            local arr, created = getDtArr(tb, diaId, index)
            if created then
                getData(qData, index, arr)

                if not next(arr.requirements) then
                    removeDtArr(tb, diaId, index)
                end
            end
        end

        if questNextIndexes then
            for _, index in pairs(questNextIndexes) do
                fillRes(qData, res.next, diaId, index)
            end

            if not next(res.next) then
                res.next = nil
            else
                for dId, dt in pairs(res.next) do
                    res.next[dId] = tableLib.values(dt, function (a, b)
                        return a.index > b.index
                    end)
                end
            end
        end

        if linkedIndexData then
            for dId, dt in pairs(linkedIndexData) do
                local currentIndex = playerQuests.getCurrentIndex(dId)
                if currentIndex and currentIndex >= dt.index then goto continue end

                local linkedQuestData = questLib.getQuestData(dId)
                if not linkedIndexData then goto continue end

                fillRes(linkedQuestData, res.linked, dId, dt.index)

                ::continue::
            end

            if not next(res.linked) then
                res.linked = nil
            else
                for dId, dt in pairs(res.linked) do
                    res.linked[dId] = tableLib.values(dt, function (a, b)
                        return a.index > b.index
                    end)
                end
            end
        end

        if next(res) then
            out[diaInfo.contentIndex] = res
        end

        ::continue::
    end

    ---@type table<string, questGuider.quest.getRequirementPositionData.returnData>
    local objectPositions = {}
    local function processPosData(posData)
        for _, diaDt in pairs(posData or {}) do
            for _, reqsDt in pairs(diaDt) do
                for _, reqs in pairs(reqsDt.requirements or {}) do
                    for _, reqDt in pairs(reqs) do
                        if reqDt.positionData then
                            tableLib.copy(reqDt.positionData, objectPositions)
                        end
                    end
                end
            end
        end
    end

    for id, dt in pairs(out) do
        processPosData(dt.next)
        processPosData(dt.linked)

        out[id].objectPositions = objectPositions
    end

    for _, dt in pairs(objectPositions) do
        cellLib.fillDistanceToPlayer(dt.positions, world.players[1])

        table.sort(dt.positions, function (a, b)
            return a.distanceToPlayer < b.distanceToPlayer
        end)
    end

    if next(out) then
        world.players[1]:sendEvent("QGL:fillQuestBoxQuestInfo", {data = out, menuId = params.menuId})
    end
end


local function showTrackingMessage(objects)
    if tableLib.size(objects) > 0 then
        local names = {}
        for id, name in pairs(objects) do
            if name and name ~= "" then
                table.insert(names, name)
            end
        end

        if #names > 0 then
                world.players[1]:sendEvent("QGL:showTrackingMessage", {message = stringLib.getValueEnumString(names, 3, l10n("startedTracking").." %s.")})
        end

        world.players[1]:sendEvent("QGL:updateMarkers", {})
    end
end


local function updateQuestMenu()
    world.players[1]:sendEvent("QGL:updateQuestMenu", {})
end


time.runRepeatedly(function ()
    world.players[1]:sendEvent("QGL:updateTime", {time = world.getGameTime()})
end, time.minute, {type = time.GameTime})
world.players[1]:sendEvent("QGL:updateTime", {time = world.getGameTime()})


return {
    interfaceName = common.interfaceName,
    interface = {
        version = 3,
        getQuestsData = function ()
            return dataHandler.quests or {}
        end,
        getObjectsData = function ()
            return dataHandler.questObjects or {}
        end,
        getLocalVarialesData = function ()
            return dataHandler.localVariablesByScriptId or {}
        end,
        questLib = questLib,
        requirementChecker = requirementChecker,
        dialogueChecker = require("scripts.quest_guider_lite.dialogueChecker"),
        types = require("scripts.quest_guider_lite.types"),
    },
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onObjectActive = onObjectActive,
    },
    eventHandlers = {
        ["QuestGuiderLite:ObjectInactive"] = objectInactive,

        ["QGL:Interop:DataReady"] = function (data)
            dataHandler.load(data)
        end,
        ["QGL:trackQuest"] = function (data)
            local questNextIndexes, linkedIndexData = questLib.getNextIndexes(data.questId, data.questId, data.index, data.params)

            local objects = {}

            if questNextIndexes and not data.finished then
                for _, indexStr in pairs(questNextIndexes) do
                    local objs = addMarkersForQuest{diaId = data.questId, diaIndex = indexStr}
                    tableLib.copy(objs, objects)
                end
                data.shouldUpdate = true
            end

            if linkedIndexData and config.data.tracking.autoTrackSideBranches then
                for qId, dt in pairs(linkedIndexData) do
                    if not config.data.tracking.autoTrackOneEntryDialogues then
                        local indexes = questLib.getIndexes(dt.qData) or {}
                        if #indexes <= 1 then goto continue end
                    end

                    local currentIndex = playerQuests.getCurrentIndex(qId)
                    if currentIndex and currentIndex >= dt.index then goto continue end

                    local objs = addMarkersForQuest{diaId = qId, diaIndex = dt.index, priority = -100}
                    tableLib.copy(objs, objects)

                    ::continue::
                end
                data.shouldUpdate = true
            end

            if next(objects) then
                showTrackingMessage(objects)
            end
            updateQuestMenu()
        end,

        ["QGL:trackObject"] = function (data)
            local objects = addMarkersForQuest{diaId = data.diaId, diaIndex = data.index, objectId = data.objectId}
            showTrackingMessage(objects)
            updateQuestMenu()
        end,

        ["QGL:drawQuestBlockInJournalMenu"] = function (data)
            local questId = data.questId

            local out = {}

            out.questId = data.questId
            out.questData = questLib.getQuestData(questId)
            if not out.questData then return end

            world.players[1]:sendEvent("QGL:drawQuestBlockInJournalMenu", out)
        end,

        ["QGL:getPositionsForTrackingMenu"] = function (data)
            local objIds = data.objectIds

            local positionsByObjectId = {}
            for _, id in pairs(objIds or {}) do
                local positions = questLib.getPositions(id, {findLinks = true, includeLinks = true})
                if not positions then goto continue end

                cellLib.fillDistanceToPlayer(positions, world.players[1])

                table.sort(positions, function (a, b)
                    return a.distanceToPlayer < b.distanceToPlayer
                end)

                positionsByObjectId[id] = positions

                ::continue::
            end

            local out = {positions = positionsByObjectId, menuId = data.menuId}

            world.players[1]:sendEvent("QGL:getPositionsForTrackingMenu", out)
        end,

        ["QGL:questGiverMarkerCallback"] = function (data)
            local recordId = data.record
            local hudMarkerId = data.hudMarkerId
            questGivers.registerTrackedQuestGiver(data.inputData, recordId, hudMarkerId)
        end,

        ["QGL:updateQuestGiverMarkers"] = function ()
            questGivers.updateQuestGiverMarkers()
        end,

        ["QGL:addMarkersForInteriorCell"] = function (data)
            trackingGlobal.addMarkersForInteriorCell(data.cellId, data.markerByObjectId)
        end,

        ["QGL:fillQuestBoxQuestInfo"] = function (data)
            fillQuestBoxQuestInfo(data)
        end,

        ["QGL:registerActorDeath"] = function (data)
            killCounter.registerKill(data.object)
            world.players[1]:sendEvent("QGL:registerActorDeath", data)
        end,

        ["QGL:updateKillCounter"] = function (data)
            killCounter.init(data)
        end,

        ["QGL:updateConfigData"] = function (data)
            tableLib.applyChanges(config.data, data)
        end,

        ["QGL:setScaledScreenSize"] = function (data)
            questGivers.scaledScreenSize = data
        end
    },
}