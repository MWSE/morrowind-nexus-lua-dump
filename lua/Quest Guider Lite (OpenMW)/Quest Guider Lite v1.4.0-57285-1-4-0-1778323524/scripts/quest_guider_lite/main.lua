local async = require('openmw.async')
local world = require('openmw.world')
local types = require('openmw.types')
local time = require('openmw_aux.time')
local core = require("openmw.core")

local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local cacheLib = require("scripts.quest_guider_lite.utils.cache")

local log = require("scripts.quest_guider_lite.utils.log")
local dataHandler = require("scripts.quest_guider_lite.storage.dataHandler")
local questBase = require("scripts.quest_guider_lite.questBase")
local questLib = require("scripts.quest_guider_lite.quest")
local testing = require("scripts.quest_guider_lite.testing.tests")
local questGivers = require("scripts.quest_guider_lite.questGiverTracking")
local trackingGlobal = require("scripts.quest_guider_lite.trackingGlobal")
local cellLib = require("scripts.quest_guider_lite.cell")
local common = require("scripts.quest_guider_lite.common")
local killCounter = require("scripts.quest_guider_lite.killCounter")
local requirementChecker = require("scripts.quest_guider_lite.requirementChecker")
local playerQuests = require('scripts.quest_guider_lite.playerQuests')
local myTypes = require("scripts.quest_guider_lite.types")
local localStorage = require("scripts.quest_guider_lite.storage.localStorage")
local protectedDoor = require("scripts.quest_guider_lite.helpers.protectedDoor")
local cellAdvLib = require("scripts.quest_guider_lite.map.cell")

local l10n = core.l10n(common.l10nKey)


---@class questGuider.main.fillQuestBoxQuestInfo.returnFieldDt
---@field requirements questGuider.quest.getDescriptionDataFromBlock.return[]
---@field index integer

---@alias questGuider.main.fillQuestBoxQuestInfo.returnDt table<string, questGuider.main.fillQuestBoxQuestInfo.returnFieldDt[]> by dia id, sorted by index
---@alias questGuider.main.fillQuestBoxQuestInfo.returnBlock {next : questGuider.main.fillQuestBoxQuestInfo.returnDt?, linked : questGuider.main.fillQuestBoxQuestInfo.returnDt?, objectPositions : table<string, questGuider.quest.getRequirementPositionData.returnData>, diaId : string, diaIndex : integer}

---@alias questGuider.main.fillQuestBoxQuestInfo.return {data : table<integer, questGuider.main.fillQuestBoxQuestInfo.returnBlock>, menuId : string, requestId : string} data by content id


local supportedGiverTypes = {
    [types.NPC] = true,
    [types.Creature] = true,
    [types.Book] = true,
    [types.Miscellaneous] = true,
    [types.Weapon] = true,
    [types.Activator] = true,
}


local function onInit()
    if not localStorage.isPlayerStorageReady() then
        localStorage.initPlayerStorage()
    end
    killCounter.initByStorageData(localStorage.data)
    -- dataHandler.init()
    -- testing.descriptionLines()
end

local function onLoad(data)
    localStorage.initPlayerStorage(data)
    killCounter.initByStorageData(localStorage.data)
    -- dataHandler.init()
    -- testing.printRandomQuestList()
end

local function onSave()
    local data = {}
    localStorage.save(data)
    return data
end


local function sendPlayerEvent(event, data)
    for _, pl in pairs(world.players) do
        pl:sendEvent(event, data)
    end
end


local function onObjectActive(ref)
    if not supportedGiverTypes[ref.type] and ref.type ~= types.Door then return end

    if types.Actor.objectIsInstance(ref) then
        if not ref:hasScript("scripts/quest_guider_lite/actor.lua") then
            ref:addScript("scripts/quest_guider_lite/actor.lua")
        end
    end

    async:newUnsavableSimulationTimer(0.2, function ()
        local dataReady = dataHandler.isReady()

        if dataReady and supportedGiverTypes[ref.type] then
            for _, pl in pairs(world.players) do
                questGivers.createQuestGiverMarker(ref, pl)
            end
        end
        if types.Door.objectIsInstance(ref) and types.Door.isTeleport(ref) then
            if ref.cell.isExterior then
                sendPlayerEvent("QGL:createMarkersForDoor", ref)
            end
            if dataReady then
                for _, pl in pairs(world.players) do
                    questGivers.createQuestGiverMarkerForDoor(ref, pl)
                end
            end
        end
    end)
end


local function updatePlayerGivers(pl)
    if not pl or not pl.cell then return end

    local function checkCell(cell)
        for objType, _ in pairs(supportedGiverTypes) do
            for _, obj in pairs(cell:getAll(objType)) do
                questGivers.createQuestGiverMarker(obj, pl)
            end
        end
    end

    if pl.cell.isExterior then
        for i = -1 , 1 do
            for j = -1, 1 do
                local c = world.getExteriorCell(pl.cell.gridX + i, pl.cell.gridY + j)
                if c then
                    checkCell(c)
                end
            end
        end
    else
        checkCell(pl.cell)
    end
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

    sendPlayerEvent("QGL:updateCityInfo", cellNames)
end

genMapRegionNames()


local function objectInactive(ref)
    if ref:hasScript("scripts/quest_guider_lite/actor.lua") then
        ref:removeScript("scripts/quest_guider_lite/actor.lua")
    end
end


---@class questGuider.main.addMarkersForQuestParams
---@field questData questDataGenerator.questData?
---@field diaId string
---@field diaIndex number|string
---@field objectId string?
---@field priority number?
---@field player any
---@field protectedActors table<string, any>?
---@field checkRequirements boolean?
---@field config table

---@param params questGuider.main.addMarkersForQuestParams
local function addMarkersForQuest(params)

    local questData = params.questData or questLib.getQuestData(params.diaId)
    if not questData then return end

    local indexStr = tostring(params.diaIndex)
    local indexData = questData[indexStr]
    if not indexData then return end

    local objects = {}

    local shouldAddObjectMarker = params.objectId and true or false

    local addedHashMap = {}

    for i, reqDataBlock in pairs(indexData.requirements or {}) do

        if params.checkRequirements and not requirementChecker.checkBlock(reqDataBlock, {
                    threatErrorsAs = true,
                    ignoredTypes = {
                        [myTypes.requirementType.CustomDialogue] = true,
                        [myTypes.requirementType.CustomActor] = true,
                        [myTypes.requirementType.Item] = true,
                        [myTypes.requirementType.Dead] = true,
                        [myTypes.requirementType.CustomOnDeath] = true,
                    }
                }, params.player) then
            goto continue
        end

        local requirementData = questLib.getDescriptionDataFromDataBlock(reqDataBlock, params.diaId, params.config)
        if not requirementData then goto continue end

        local hasJournalReq = false
        for _, requirement in ipairs(requirementData) do
            if not requirement.positionData then goto continue end

            if not params.objectId and requirement.data.type == myTypes.requirementType.Dead and
                    (requirement.data.operator == myTypes.operator.value.NotEqual and requirement.data.value == 1 or
                    requirement.data.operator == myTypes.operator.value.Equal and requirement.data.value == 0) then
                goto continue
            end

            if not params.objectId and requirement.data.object and (requirement.data.type == myTypes.requirementType.CustomActor or
                    requirement.data.type == myTypes.requirementType.CustomDisposition) and
                    killCounter.getKillCount(requirement.data.object) > 0 then
                goto continue
            end

            local reqHash = {}
            if not params.objectId then
                for _, reqBl in ipairs(requirement.reqDataForHandlingArr or {}) do
                    table.insert(reqHash, myTypes.gerRequirementBlockHash(reqBl))
                end
                table.insert(reqHash, myTypes.gerRequirementBlockHash(requirement.reqDataForHandling))
            end
            reqHash = table.concat(reqHash, "_")

            for objId, posData in pairs(requirement.positionData or {}) do
                if not params.objectId and not posData.foundValidPos then
                    goto continue
                end

                if params.objectId and params.objectId ~= objId or
                        not params.objectId and (posData.isActorAliveReq or
                        params.protectedActors and posData.actorCount and posData.actorCount > 0 and
                        indexData.finished and params.protectedActors[objId]) then
                    goto continue
                end

                if not params.objectId then
                    local hash = string.format("%s_%s_%s_%s_%s_%s", objId, posData.reqType, posData.name, reqHash,
                        posData.itemCount, posData.actorCount)
                    if addedHashMap[hash] then
                        goto continue
                    end
                    addedHashMap[hash] = true
                end

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

                params.player:sendEvent("QGL:addMarker", eventParams)

                shouldAddObjectMarker = false
                -- objects[objId] = posData.name

                ::continue::
            end

            ::continue::
        end

        ::continue::
    end

    -- Since available objects for tracking are formed differently than in this function,
    -- for manual markers it is sometimes necessary to create the required data separately.
    if shouldAddObjectMarker then
        ---@type questDataGenerator.requirementData
        local tempReq = {
            operator = 48,
            type = "TEMP",
            object = params.objectId
        }

        local dt = questLib.getRequirementPositionData(tempReq, params.config, params.diaId)

        if dt and dt[params.objectId] then
            local posData = dt[params.objectId]
            ---@type questGuider.tracking.addMarker
            local eventParams = {
                questId = params.diaId,
                objectId = params.objectId,
                objectName = posData.name,
                positionData = posData,
                questData = questData,
                questStage = params.diaIndex,
                reqData = nil,
                priority = params.priority,
            }

            params.player:sendEvent("QGL:addMarker", eventParams)
        end
    end

    -- Removed:
    -- if this quest has its own requirement blocks, do not track links to not started quests
    -- tr_dbattack 50, a1_v_vivecinformants 1
    -- removed because it can cause issues with some quests like "town_tel_vos"

    return objects
end


---@param params {menuId : string, useCurrentIndex : boolean?, data: table<string, {diaId : string, index : integer, contentIndex : integer}>, player : any, requestId : string, config: table}
local function fillQuestBoxQuestInfo(params)
    local player = params.player or world.players[1]
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
            questNextIndexes, linkedIndexData = questLib.getNextIndexes(qData, diaId, diaInfo.index, {findCompleted = false, findInLinked = true}, player)
        end
        if not questNextIndexes and not linkedIndexData then goto continue end

        local function getData(qData, index, arr)
            local indexStr = tostring(index)
            local indexData = qData[indexStr]
            if not indexData then return end

            arr.index = tonumber(index)

            for i, reqDataBlock in pairs(indexData.requirements or {}) do
                local requirementData, linkedQuests = questLib.getDescriptionDataFromDataBlock(reqDataBlock, diaInfo.diaId, params.config)
                if not requirementData then goto continue end

                if linkedQuests then
                    linkedIndexData = linkedIndexData or {}
                    tableLib.copy(linkedQuests, linkedIndexData)
                end

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
                local currentIndex = playerQuests.getCurrentIndex(dId, player)
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
        if cellAdvLib.isReady() then
            cellAdvLib.fillDistanceToPlayer(dt.positions, player)
        else
            cellLib.fillDistanceToPlayer(dt.positions, player)
        end

        table.sort(dt.positions, function (a, b)
            return (a.distanceToPlayer or math.huge) < (b.distanceToPlayer or math.huge)
        end)
    end

    if next(out) then
        player:sendEvent("QGL:fillQuestBoxQuestInfo", {data = out, menuId = params.menuId, requestId = params.requestId})
    end
end


local function showTrackingMessage(player, objects)
    if next(objects) then
        local names = {}
        for id, name in pairs(objects) do
            if name and name ~= "" then
                table.insert(names, name)
            end
        end

        if #names > 0 then
                player:sendEvent("QGL:showTrackingMessage", {message = stringLib.getValueEnumString(names, 3, l10n("startedTracking").." %s.")})
        end

        player:sendEvent("QGL:updateMarkers", {})
    end
end


local function updateQuestMenu(player)
    player:sendEvent("QGL:updateQuestMenu", {})
end


local function updateTime(pl)
    local vars = world.mwscript.getGlobalVariables(pl)

    local day = vars["Day"]
    local month = vars["Month"]
    local year = vars["Year"]
    if not year  or not month or not day then return end

    pl:sendEvent("QGL:requestTimeUpdate", {day = day, month = month, year = year})
end



return {
    interfaceName = common.interfaceName,
    interface = {
        version = 6,
        getQuestsData = function ()
            return dataHandler.quests or {}
        end,
        getObjectsData = function ()
            return dataHandler.questObjects or {}
        end,
        getLocalVarialesData = function ()
            return dataHandler.localVariablesByScriptId or {}
        end,
        questBaseLib = questBase,
        questLib = questLib,
        requirementChecker = requirementChecker,
        types = require("scripts.quest_guider_lite.types"),
    },
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onSave = onSave,
        onObjectActive = onObjectActive,
    },
    eventHandlers = {
        ["QuestGuiderLite:ObjectInactive"] = objectInactive,

        ["QGL:Interop:DataReady"] = function (data)
            dataHandler.load(data)
        end,
        ---@param data questGuider.tracking.trackQuest.eventArgument
        ["QGL:trackQuest"] = function (data)
            local player = data.player or world.players[1]
            local questNextIndexes, linkedIndexData, validLinked
            if not data.params.useCurrentIndex then
                questNextIndexes, linkedIndexData, validLinked = questLib.getNextIndexes(data.questId, data.questId, data.index, data.params, player)
            else
                questNextIndexes = {data.index}
            end

            local objects = {}

            local questData = questLib.getQuestData(data.questId)
            if questData and questNextIndexes and not data.finished then
                local stageFlags = {}

                -- check if stage has any finished requirements that do not require killing an actor,
                -- if so, do suppress tracking for requiremnts that require killing an actor
                local protectedFinActors = {}
                local deadFinReqActors = {}
                local aliveFinReqActors = {}
                for _, index in pairs(questNextIndexes) do
                    local stageData = questData[tostring(index)]
                    if not stageData then goto continue end

                    if stageData.finished then
                        for _, reqBlock in pairs(stageData.requirements or {}) do
                            for _, req in pairs(reqBlock) do
                                if req.type == myTypes.requirementType.CustomActor then
                                    if req.object then
                                        protectedFinActors[req.object] = true
                                    end

                                elseif req.type == myTypes.requirementType.Dead then
                                    if req.variable then
                                        if myTypes.operator.check(req.value or 0, 1, req.operator or 48) then
                                            deadFinReqActors[req.variable] = true
                                        else
                                            aliveFinReqActors[req.variable] = true
                                        end
                                    end

                                end
                            end
                        end
                    end

                    ::continue::
                end

                for objId, _ in pairs(deadFinReqActors) do
                    if aliveFinReqActors[objId] then
                        protectedFinActors[objId] = true
                    end
                end

                for _, indexStr in pairs(questNextIndexes) do
                    local objs = addMarkersForQuest{questData = questData, diaId = data.questId, diaIndex = indexStr, player = player,
                        protectedActors = protectedFinActors, config = data.config}
                    tableLib.copy(objs, objects)
                end
                data.shouldUpdate = true
            end

            if linkedIndexData then
                for qId, dt in pairs(linkedIndexData) do
                    if not data.config.tracking.autoTrackOneEntryDialogues then
                        local indexes = questLib.getIndexes(dt.qData) or {}
                        if #indexes <= 1 then goto continue end
                    end

                    -- do not auto track dialogues that have "kill" in their id, as those are likely to be fail state entries
                    if string.sub(qId, -4):lower() == "kill" then
                        goto continue
                    end

                    local currentIndex = playerQuests.getCurrentIndex(qId, player)
                    if currentIndex and currentIndex >= dt.index then goto continue end

                    local isValidLinkedToTrack = validLinked and validLinked[qId]

                    local objs = addMarkersForQuest{
                        diaId = qId,
                        diaIndex = dt.index,
                        priority = -100,
                        checkRequirements = not (data.config.tracking.autoTrackSideBranches or isValidLinkedToTrack),
                        config = data.config,
                        player = player
                    }
                    tableLib.copy(objs, objects)

                    data.shouldUpdate = true

                    ::continue::
                end
            end

            if next(objects) then
                showTrackingMessage(player, objects)
            end
            updateQuestMenu(player)
        end,

        ["QGL:trackObject"] = function (data)
            local player = data.player or world.players[1]
            local objects = addMarkersForQuest{diaId = data.diaId, diaIndex = data.index, objectId = data.objectId,
                config = data.config, player = player}
            showTrackingMessage(player, objects)
            updateQuestMenu(player)
        end,

        ["QGL:getPositionsForTrackingMenu"] = function (data)
            local player = data.player or world.players[1]
            local objIds = data.objectIds

            local positionsByObjectId = {}
            for _, id in pairs(objIds or {}) do
                local positions = questLib.getPositions(id, {findLinks = true, includeLinks = true, customConfig = data.config})
                if not positions then goto continue end

                if cellAdvLib.isReady() then
                    cellAdvLib.fillDistanceToPlayer(positions, player)
                else
                    cellLib.fillDistanceToPlayer(positions, player)
                end

                table.sort(positions, function (a, b)
                    return (a.distanceToPlayer or math.huge) < (b.distanceToPlayer or math.huge)
                end)

                positionsByObjectId[id] = positions

                ::continue::
            end

            local out = {positions = positionsByObjectId, menuId = data.menuId, advWMapMode = data.advWMapMode}

            player:sendEvent("QGL:getPositionsForTrackingMenu", out)
        end,

        ["QGL:questGiverMarkerCallback"] = function (data)
            local player = data.player or world.players[1]
            local recordId = data.record
            local hudMarkerId = data.hudMarkerId
            questGivers.registerTrackedQuestGiver(data.inputData, recordId, hudMarkerId, player)
        end,

        ["QGL:updateQuestGiverMarkers"] = function (data)
            if not data.player then return end

            updatePlayerGivers(data.player)
            questGivers.updateQuestGiverMarkers(data.player)
        end,

        ["QGL:addMarkersForInteriorCell"] = function (data)
            local player = data.player or world.players[1]
            trackingGlobal.addMarkersForInteriorCell(data.cellId, data.markerByObjectId, player)
        end,

        ["QGL:fillQuestBoxQuestInfo"] = function (data)
            fillQuestBoxQuestInfo(data)
        end,

        ["QGL:getQuestsNearby"] = function (data)
            local pl = data.player
            local cell = pl.cell

            local objectIds = {}
            local function processCell(c, depth)
                depth = depth - 1

                for tp, _ in pairs(supportedGiverTypes) do
                    for _, obj in pairs(c:getAll(tp)) do
                        objectIds[obj.recordId] = true
                        local rec = obj.type.record(obj)
                        if rec and rec.mwscript and rec.mwscript ~= "" then
                            objectIds[rec.mwscript] = true
                        end
                    end
                end

                if depth <= 0 then return end
                for _, obj in pairs(c:getAll(types.Door)) do
                    if types.Door.isTeleport(obj) then
                        local cc = protectedDoor.destCell(obj)
                        if cc and cc.id then
                            processCell(cc, depth)
                        end
                    end
                end
            end

            if cell.isExterior then
                for i = -1, 1 do
                    for j = -1, 1 do
                        local c = world.getExteriorCell(cell.gridX + i, cell.gridY + j)
                        if c then
                            processCell(c, 2)
                        end
                    end
                end
            else
                processCell(cell, 2)
            end

            local diaIds = {}
            for objId, _ in pairs(objectIds) do
                local dt = questLib.getObjectData(objId)
                if dt and dt.starts then
                    for _, diaId in pairs(dt.starts) do
                        diaIds[diaId] = true
                    end
                end
            end

            data.diaIds = tableLib.keys(diaIds)
            pl:sendEvent("QGL:questsNearby", data)
        end,

        ["QGL:registerActorDeath"] = function (data)
            killCounter.registerKill(data.object)
        end,

        ["QGL:setScaledScreenSize"] = function (data)
            questGivers.scaledScreenSize = data
        end,

        ["QGL:requestTimeUpdate"] = updateTime,

        ["QGL:clearCache"] = function ()
            cacheLib.clear()
        end,
    },
}