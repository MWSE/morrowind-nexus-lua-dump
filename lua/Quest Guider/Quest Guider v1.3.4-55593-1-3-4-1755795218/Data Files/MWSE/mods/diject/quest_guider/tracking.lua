local storage = include("diject.quest_guider.storage.localStorage")
local markerLib = include("diject.mapMarkerLib.interop")
local stringLib = include("diject.quest_guider.utils.string")
local colors = include("diject.quest_guider.Types.gradient")
local dataHandler = include("diject.quest_guider.dataHandler")
local cellLib = include("diject.quest_guider.cell")
local questLib = include("diject.quest_guider.quest")
local playerQuests = include("diject.quest_guider.playerQuests")
local config = include("diject.quest_guider.config")
local otherTypes = include("diject.quest_guider.Types.other")
local randomLib = include("diject.quest_guider.utils.random")
local tooltips = include("diject.quest_guider.UI.tooltips")
local requirementChecker = include("diject.quest_guider.requirementChecker")

local log = include("diject.quest_guider.utils.log")

local storageLabel = "tracking"

local this = {}

this.mapMarkerLibVersion = markerLib and (markerLib.version or 1) or -1

---@class questGuider.tracking.markerImage
---@field path string
---@field pathAbove string|nil
---@field pathBelow string|nil
---@field scale number
---@field alpha number? [0, 1]
---@field shiftX integer
---@field shiftY integer

---@type questGuider.tracking.markerImage
this.localMarkerImageInfo = { path = "diject\\quest guider\\defaultArrow32x32.dds",
        pathAbove = "diject\\quest guider\\defaultArrowUp32x32.dds", pathBelow = "diject\\quest guider\\defaultArrowDown32x32.dds", shiftX = -8, shiftY = 15, scale = 0.5 }
---@type questGuider.tracking.markerImage
this.localDoorMarkerImageInfo = { path = "diject\\quest guider\\defaultDoorArrow32x32.dds",
        pathAbove = "diject\\quest guider\\defaultDoorArrowUp32x32.dds", pathBelow = "diject\\quest guider\\defaultDoorArrowDown32x32.dds", shiftX = -8, shiftY = 15, scale = 0.5 }
---@type questGuider.tracking.markerImage
this.worldMarkerImageInfo = { path = "diject\\quest guider\\defaultArrow32x32.dds",
        pathAbove = "diject\\quest guider\\defaultArrowUp32x32.dds", pathBelow = "diject\\quest guider\\defaultArrowDown32x32.dds", shiftX = -8, shiftY = 15, scale = 0.5 }
---@type questGuider.tracking.markerImage
this.questGiverImageInfo = { path = "diject\\quest guider\\exclamationMark16x32.dds",
        pathAbove = "diject\\quest guider\\exclamationMarkUp32x32.dds", pathBelow = "diject\\quest guider\\exclamationMarkDown32x32.dds", shiftX = -3, shiftY = 12, scale = 0.4 }
---@type questGuider.tracking.markerImage
this.zoneImageInfo = { path = "diject\\quest guider\\circleZoneMarker128x128.dds", shiftX = -64, shiftY = 64, scale = 128 }

---@class questGuider.tracking.storageData
---@field markerByObjectId table<string, questGuider.tracking.objectRecord>?
---@field trackedObjectsByQuestId table<string, {objects : table<string, string[]>, color : number[]}>?
---@field colorId integer?

---@type questGuider.tracking.storageData
this.storageData = {} -- data of quest map markers

---@type table<string, boolean>
this.scannedCellsForTemporaryMarkers = {}

---@type table<string, string> recordId by object id
this.trackedQuestGivers = {}

---@class questGuider.tracking.markerRecord
---@field localMarkerId string|nil
---@field localDoorMarkerId string|nil
---@field worldMarkerId string|nil
---@field disabled boolean?
---@field userDisabled boolean?

---@alias questGuider.tracking.markerData {id : string, index : integer, data : questGuider.tracking.markerRecord, parentObject: string?, itemCount : integer?, actorCount : integer?, handledRequirements : table<string, questDataGenerator.requirementBlock>?}

---@class questGuider.tracking.objectRecord
---@field color number[]
---@field markers table<string, questGuider.tracking.markerData> by quest id
---@field targetCells table<string, string>? parent cell editor name by editor name of cell that have access to the parent

---@type table<string, questGuider.tracking.objectRecord>
this.markerByObjectId = {}

---@type table<string, {objects : table<string, string[]>}>
this.trackedObjectsByQuestId = {}


this.callbackToUpdateMapMenu = nil


---@type table<string, boolean>
this.disabledQuests = {}

---@type markerLib.localMarkerOOP[]
local lastInteriorMarkers = {}

local initialized = false

---@return boolean isSuccessful
function this.init()
    initialized = false
    if not markerLib then return false end
    if not storage.isPlayerStorageReady() then
        storage.initPlayerStorage()
    end
    if not storage.player then return false end

    if not storage.player[storageLabel] then
        storage.player[storageLabel] = {colorId = 1}
    end
    this.storageData = storage.player[storageLabel]
    this.storageData.markerByObjectId = this.storageData.markerByObjectId or {}
    this.storageData.trackedObjectsByQuestId = this.storageData.trackedObjectsByQuestId or {}

    this.markerByObjectId = this.storageData.markerByObjectId
    this.trackedObjectsByQuestId = this.storageData.trackedObjectsByQuestId

    this.scannedCellsForTemporaryMarkers = {}
    this.trackedQuestGivers = {}

    initialized = true
    return initialized
end

function this.reset()
    initialized = false
    this.callbackToUpdateMapMenu = nil
    this.markerByObjectId = {}
    this.trackedObjectsByQuestId = {}
    this.scannedCellsForTemporaryMarkers = {}
    this.trackedQuestGivers = {}
    lastInteriorMarkers = {}
end

function this.isInit()
    if not initialized then
        return this.init()
    end
    return true
end

local function runCallbacks()
    if this.callbackToUpdateMapMenu then
        this.callbackToUpdateMapMenu()
    end
end

---@class questGuider.tracking.addMarker
---@field questId string should be lower
---@field questStage integer
---@field objectId string should be lower
---@field reqData questGuider.quest.getDescriptionDataFromBlock.returnArr?
---@field positionData questGuider.quest.getRequirementPositionData.returnData
---@field color number[]|nil
---@field associatedNumber number|nil not used

---@param params questGuider.tracking.addMarker
---@return questGuider.tracking.objectRecord|nil
function this.addMarker(params)
    if not initialized then return end

    local approxConfig = config.data.tracking.approx

    local objectId = params.objectId

    local positionData = params.positionData

    local questData = questLib.getQuestData(params.questId)

    if not questData or not positionData then return end

    if params.reqData and params.reqData.data.type == "DIAO" then return end

    local qTrackingInfo
    if this.trackedObjectsByQuestId[params.questId] then
        qTrackingInfo = this.trackedObjectsByQuestId[params.questId]
    else
        qTrackingInfo = {objects = {}}
    end

    local objectTrackingData = this.markerByObjectId[objectId]
    if not objectTrackingData then
        local colorId = math.min(this.storageData.colorId, #colors)

        objectTrackingData = { markers = {}, color = colors[colorId] } ---@diagnostic disable-line: missing-fields

        this.storageData.colorId = colorId < #colors and colorId + 1 or 1
    end

    if objectTrackingData.markers[params.questId] then
        local oldData = objectTrackingData.markers[params.questId]
        if oldData.actorCount or positionData.actorCount then
            oldData.actorCount = math.max(oldData.actorCount or 0, positionData.actorCount or 0)
        end
        if oldData.itemCount or positionData.itemCount then
            oldData.itemCount = math.max(oldData.itemCount or 0, positionData.itemCount or 0)
        end
        if positionData.parentObject then
            oldData.parentObject = positionData.parentObject
        end
        if params.reqData and params.reqData.reqDataForHandling then
            local hash = ""
            for _, r in pairs(params.reqData.reqDataForHandling) do
                hash = hash..r.type..tostring(r.operator)..tostring(r.value)..tostring(r.variable)..tostring(r.object)
            end
            if not oldData.handledRequirements then oldData.handledRequirements = {} end
            oldData.handledRequirements[hash] = params.reqData.reqDataForHandling
        end
        return
    end

    ---@type questGuider.tracking.markerRecord
    local objectMarkerData = {}

    local localImageInfo = approxConfig.enabled and this.zoneImageInfo or this.localMarkerImageInfo
    local alpha = approxConfig.enabled and config.data.tracking.marker.zoneAlpha or config.data.tracking.marker.alpha
    objectMarkerData.localMarkerId = objectMarkerData.localMarkerId or markerLib.addRecord{
        path = localImageInfo.path,
        pathAbove = localImageInfo.pathAbove,
        pathBelow = localImageInfo.pathBelow,
        color = objectTrackingData.color,
        textureShiftX = localImageInfo.shiftX,
        textureShiftY = localImageInfo.shiftY,
        scale = approxConfig.enabled and -2 * approxConfig.interior.radius or localImageInfo.scale,
        alpha = alpha,
        name = positionData.name,
        description = {string.format("Quest: \"%s\"", questData.name or ""), ""},
        userData = {questId = params.questId, index = params.questStage, action = "jText"},
    }
    local worldImageInfo = approxConfig.enabled and this.zoneImageInfo or this.worldMarkerImageInfo
    objectMarkerData.worldMarkerId = objectMarkerData.worldMarkerId or markerLib.addRecord{
        path = worldImageInfo.path,
        color = objectTrackingData.color,
        textureShiftX = worldImageInfo.shiftX,
        textureShiftY = worldImageInfo.shiftY,
        scale = approxConfig.enabled and -2 * approxConfig.worldMap.radius or worldImageInfo.scale,
        alpha = alpha,
        name = positionData.name,
        description = {string.format("Quest: \"%s\"", questData.name or ""), ""},
        userData = {questId = params.questId, index = params.questStage, action = "jText"},
    }
    local doorImageInfo = this.localDoorMarkerImageInfo
    objectMarkerData.localDoorMarkerId = objectMarkerData.localDoorMarkerId or markerLib.addRecord{
        path = doorImageInfo.path,
        pathAbove = doorImageInfo.pathAbove,
        pathBelow = doorImageInfo.pathBelow,
        color = objectTrackingData.color,
        textureShiftX = doorImageInfo.shiftX,
        textureShiftY = doorImageInfo.shiftY,
        scale = doorImageInfo.scale,
        alpha = config.data.tracking.marker.alpha,
        name = positionData.name,
        description = {string.format("Quest: \"%s\"", questData.name or ""), ""},
        userData = {questId = params.questId, index = params.questStage, action = "jText"},
    }

    if not objectMarkerData.localMarkerId and not objectMarkerData.worldMarkerId then return end

    if not objectTrackingData.markers then objectTrackingData.markers = {} end
    local handledReqs = params.reqData and params.reqData.reqDataForHandling
    if handledReqs then
        local hash = ""
        for _, r in pairs(handledReqs) do
            hash = hash..r.type..tostring(r.operator)..tostring(r.value)..tostring(r.variable)..tostring(r.object)
        end
        handledReqs = {[hash] = handledReqs}
    end
    objectTrackingData.markers[params.questId] = {
        id = params.questId,
        index = params.questStage,
        data = objectMarkerData,
        itemCount = positionData.itemCount,
        actorCount = positionData.actorCount,
        parentObject = positionData.parentObject,
        handledRequirements = handledReqs,
    }

    local allowWorldMarkers = #positionData.positions <= config.data.tracking.maxPositions

    local objects = {}
    objects[objectId] = true

    local allowToTagNameForLocal = true

    for _, data in pairs(positionData.positions or {}) do

        if objectMarkerData.localMarkerId then

            local rawData = data.rawData

            if rawData then
                if rawData.id then
                    objects[rawData.id] = true
                end
            elseif not approxConfig.enabled or (data.id and approxConfig.interior.enabled) then
                allowToTagNameForLocal = false
                markerLib.addLocalMarker{
                    record = objectMarkerData.localMarkerId,
                    cell = data.id,
                    position = data.position,
                    trackOffscreen = not approxConfig.enabled,
                    insertBefore = approxConfig.enabled,
                }
            end
        end

        if data.id == nil then

            if allowWorldMarkers then
                if objectMarkerData.worldMarkerId then
                    markerLib.addWorldMarker{
                        record = objectMarkerData.worldMarkerId,
                        x = data.exitPos.x,
                        y = data.exitPos.y,
                        insertBefore = approxConfig.enabled,
                    }
                end
            end
        else
            local cell = tes3.getCell(data) ---@diagnostic disable-line: param-type-mismatch
            if cell then

                if data.isExitEx and allowWorldMarkers then
                    local exitPos, path = data.exitPos, data.doorPath

                    if exitPos then
                        if objectMarkerData.worldMarkerId then
                            markerLib.addWorldMarker{
                                record = objectMarkerData.worldMarkerId,
                                x = exitPos.x,
                                y = exitPos.y,
                            }
                        end

                        if path then
                            if objectMarkerData.localDoorMarkerId then
                                local exitPositions = cellLib.findExitPositions(cell)
                                if exitPositions then
                                    for _, pos in pairs(exitPositions) do
                                        local nearestDoor = cellLib.findNearestDoor(pos)
                                        markerLib.addLocalMarker{
                                            record = objectMarkerData.localDoorMarkerId,
                                            position = nearestDoor and nearestDoor.position or pos,
                                            trackOffscreen = true,
                                            replace = true,
                                        }
                                    end
                                end

                                if not objectTrackingData.targetCells then
                                    objectTrackingData.targetCells = {}
                                end

                                objectTrackingData.targetCells[cell.editorName] = cell.editorName
                            end
                        end
                    end
                end

                if not objectTrackingData.targetCells then
                    objectTrackingData.targetCells = {}
                end

                objectTrackingData.targetCells[cell.editorName] = cell.editorName
            end
        end
    end

    if objectMarkerData.localMarkerId then

        for objId, _ in pairs(objects) do

            if not approxConfig.enabled then
                markerLib.addLocalMarker{
                    record = objectMarkerData.localMarkerId,
                    objectId = objId,
                    trackOffscreen = true,
                }

            else
                local objectPoss = questLib.getObjectPositionData(objId)
                if not objectPoss then goto continue end

                randomLib.setSeedByStringHash(objId)
                for _, posData in pairs(objectPoss) do
                    if posData.name then
                        local pos = tes3vector3.new(posData.pos[1], posData.pos[2], posData.pos[3])
                        randomLib.changeVectorPosByRandomInRadius(pos, approxConfig.interior.radius * 0.8)
                        markerLib.addLocalMarker{
                            record = objectMarkerData.localMarkerId,
                            cell = posData.name,
                            position = pos,
                            insertBefore = approxConfig.enabled,
                        }
                        allowToTagNameForLocal = false
                    end
                end

            end

            ::continue::
        end

        if approxConfig.enabled then
            randomLib.resetRandomSeed()
        end
    end

    if this.mapMarkerLibVersion >= 3 and allowToTagNameForLocal and objectMarkerData.localMarkerId then
        local rec = markerLib.getRecord(objectMarkerData.localMarkerId)
        if rec then
            rec.name = "#objectName#"
        end
    end

    this.markerByObjectId[objectId] = objectTrackingData

    qTrackingInfo.objects[objectId] = table.keys(objects)

    this.trackedObjectsByQuestId[params.questId] = qTrackingInfo

    if positionData.itemCount then
        this.handlePlayerInventory(true)
    end
    if positionData.actorCount then
        this.handleDeath(objectId)
    end

    if this.disabledQuests[params.questId] then
        this.setDisableMarkerState{ questId = params.questId, value = true }
    end

    return objectTrackingData
end

---@class questGuider.tracking.addMarkersForQuest
---@field questId string should be lowercase
---@field questIndex integer|string

---@param params questGuider.tracking.addMarkersForQuest
---@return table<string, boolean>? objects object ids
function this.addMarkersForQuest(params)

    local questData = questLib.getQuestData(params.questId)
    if not questData then return end

    local indexStr = tostring(params.questIndex)
    local indexData = questData[indexStr]
    if not indexData then return end

    local out = {}

    for i, reqDataBlock in pairs(indexData.requirements or {}) do

        local requirementData = questLib.getDescriptionDataFromDataBlock(reqDataBlock)
        if not requirementData then goto continue end

        for _, requirement in ipairs(requirementData) do
            for objId, posData in pairs(requirement.positionData or {}) do

                this.addMarker{ objectId = objId, questId = params.questId, questStage = params.questIndex,
                    positionData = posData, reqData = requirement }

                out[objId] = true

                ::continue::
            end
        end

        ::continue::
    end

    if tes3.player.cell.isInterior then
        this.addMarkersForInteriorCell(tes3.player.cell)
    end

    return out
end


local function removeMarker(params)
    local recordIdsToRemove = {}

    ---@param rec questGuider.tracking.markerRecord
    local function addToRemove(rec)
        recordIdsToRemove[rec.localDoorMarkerId or ""] = true
        recordIdsToRemove[rec.localMarkerId or ""] = true
        recordIdsToRemove[rec.worldMarkerId or ""] = true
    end

    for objId, objData in pairs(this.markerByObjectId) do
        if params.objectId and objId ~= params.objectId then goto continue end

        for qId, markerData in pairs(objData.markers) do
            if params.questId and qId ~= params.questId then goto continue end

            addToRemove(markerData.data)
            objData.markers[qId] = nil

            ::continue::
        end

        if table.size(objData.markers) == 0 then
            this.markerByObjectId[objId] = nil
        end

        ::continue::
    end

    for qId, qData in pairs(this.trackedObjectsByQuestId) do
        if params.questId and params.questId ~= qId then goto continue end

        for objId, _ in pairs(qData.objects) do
            if params.objectId and objId ~= params.objectId then goto continue end

            qData.objects[objId] = nil

            ::continue::
        end

        if table.size(qData.objects) == 0 then
            this.trackedObjectsByQuestId[qId] = nil
        end

        ::continue::
    end

    local removed = false

    recordIdsToRemove[""] = nil
    for id, _ in pairs(recordIdsToRemove) do
        markerLib.removeRecord(id)
        removed = true
    end

    return removed
end


---@class questGuider.tracking.removeMarker
---@field questId string|nil should be lowercase
---@field objectId string|nil should be lowercase
---@field removeLinked boolean?

---@param params questGuider.tracking.removeMarker
---@return boolean?
function this.removeMarker(params)
    if not params.questId and not params.objectId then return end

    local res = false

    if params.removeLinked and params.questId then
        local qData = questLib.getQuestData(params.questId)
        if not qData then return end
        for _, qId in pairs(qData.links or {}) do
            res = removeMarker{ questId = qId, objectId = params.objectId } or res
        end
    end
    res = removeMarker(params) or res

    return res
end


function this.removeMarkers()
    local questIds = table.keys(this.trackedObjectsByQuestId)

    for _, qId in pairs(questIds) do
        this.removeMarker{ questId = qId }
    end
    table.clear(this.trackedObjectsByQuestId)
    table.clear(this.markerByObjectId)
end

---@param trackedObjectId string
---@param priority number?
---@return boolean|nil
function this.changeObjectMarkerColor(trackedObjectId, color, priority)
    local data = this.markerByObjectId[trackedObjectId]
    if not data then return end

    for qId, markerInfo in pairs(data.markers) do
        local markerData = markerInfo.data
        if markerData.localMarkerId then
            local record = markerLib.getRecord(markerData.localMarkerId)
            if record then
                record.color = table.copy(color)
                if priority then
                    record.priority = priority
                end
            end
        end

        if markerData.worldMarkerId then
            local record = markerLib.getRecord(markerData.worldMarkerId)
            if record then
                record.color = table.copy(color)
                if priority then
                    record.priority = priority
                end
            end
        end

        if markerData.localDoorMarkerId then
            local record = markerLib.getRecord(markerData.localDoorMarkerId)
            if record then
                record.color = table.copy(color)
                if priority then
                    record.priority = priority
                end
            end
        end
    end

    return true
end


function this.updateMarkers(callbacks)
    if callbacks then
        runCallbacks()
    end
    markerLib.updateWorldMarkers(true)
    markerLib.updateLocalMarkers(true)
end


---@param questId string should be lowercase
function this.getQuestData(questId)
    return this.trackedObjectsByQuestId[questId]
end

---@param objectId string should be lowercase
function this.getObjectData(objectId)
    return this.markerByObjectId[objectId]
end


---@param cell tes3cell
function this.createQuestGiverMarkers(cell)
    if this.scannedCellsForTemporaryMarkers[cell.editorName] then return end
    this.scannedCellsForTemporaryMarkers[cell.editorName] = true

    for ref in cell:iterateReferences{ tes3.objectType.npc, tes3.objectType.creature } do
        local objectId = ref.baseObject.id:lower()

        if this.trackedQuestGivers[objectId] then goto continue end

        local objectData = questLib.getObjectData(objectId)
        if not objectData or not objectData.starts then goto continue end

        local questNames = {}

        for _, questId in pairs(objectData.starts) do
            local questIdLower = questId:lower()
            local questData = questLib.getQuestData(questIdLower)
            if not questData or not questData.name then goto continue end

            if config.data.tracking.giver.filter then
                local firstIndexStr = questLib.getFirstIndex(questData)
                if not firstIndexStr then goto continue end
                if not questLib.checkConditionsForQuestGiver(ref.object, questIdLower, firstIndexStr) then
                    goto continue
                end
            end

            local playerData = playerQuests.getQuestData(questId)
            if not playerData or (config.data.tracking.giver.hideStarted and playerData.index > 0) then
                goto continue
            end

            table.insert(questNames, questData.name)

            ::continue::
        end

        if #questNames <= 0 then goto continue end

        local recordId = markerLib.addRecord{
            path = this.questGiverImageInfo.path,
            pathAbove = this.questGiverImageInfo.pathAbove,
            pathBelow = this.questGiverImageInfo.pathBelow,
            color = tes3ui.getPalette(tes3.palette.normalColor),
            textureShiftX = this.questGiverImageInfo.shiftX,
            textureShiftY = this.questGiverImageInfo.shiftY,
            scale = this.questGiverImageInfo.scale,
            priority = -100,
            temporary = true,
            name = ref.baseObject.name,
            description = stringLib.getValueEnumString(questNames, config.data.tracking.giver.namesMax,
                (config.data.main.helpLabels and this.mapMarkerLibVersion >= 3) and "Starts %s. Click for info." or "Starts %s"),
            onClickCallback = function (e)
                include("diject.quest_guider.UI.questListOfObject").show{ objectId = objectId, showInvolved = false }
            end
        }

        markerLib.addLocalMarker{
            record = recordId,
            objectId = objectId,
            temporary = true,
            trackOffscreen = true,
        }

        this.trackedQuestGivers[objectId] = recordId

        ::continue::
    end
end


function this.updateQuestGiverMarkers()
    for objId, recordId in pairs(this.trackedQuestGivers) do
        local objectData = questLib.getObjectData(objId)

        local valid = false

        for _, questId in pairs((objectData or {}).starts or {}) do
            local questData = questLib.getQuestData(questId)
            if not questData or not questData.name then goto continue end

            if config.data.tracking.giver.filter then
                local firstIndexStr = questLib.getFirstIndex(questData)
                if not firstIndexStr then goto continue end
                if not questLib.checkConditionsForQuestGiver(tes3.getObject(objId), questId, firstIndexStr) then
                    goto continue
                end
            end

            local playerData = playerQuests.getQuestData(questId)
            if not playerData or (config.data.tracking.giver.hideStarted and playerData.index > 0) then
                goto continue
            end

            valid = true
            if valid then
                break;
            end

            ::continue::
        end

        if not valid then
            markerLib.removeRecord(recordId)
            this.trackedQuestGivers[objId] = nil
        end
    end
end


---@param questId string should be lowercase
---@param e journalEventData
function this.trackQuestFromCallback(questId, e)
    local shouldUpdate = false

    if this.removeMarker{ questId = questId } then
        shouldUpdate = true
    end

    local isFinished = e.info and e.info.isQuestFinished or false

    local questNextIndexes, linkedIndexData = questLib.getNextIndexes(questId, questId, e.index, {findCompleted = false, findInLinked = true})

    if isFinished then
        this.removeMarker{ questId = questId, removeLinked = isFinished }
        shouldUpdate = true
    end

    local objects = {}
    if questNextIndexes and (not isFinished or config.data.tracking.quest.finished) then
        for _, indexStr in pairs(questNextIndexes) do
            local objs = this.addMarkersForQuest{ questId = questId, questIndex = indexStr }
            table.copy(objs, objects)
        end
        shouldUpdate = true
    end

    if linkedIndexData then
        for qId, dt in pairs(linkedIndexData) do
            local objs = this.addMarkersForQuest{ questId = qId, questIndex = dt.index }
            table.copy(objs, objects)
        end
        shouldUpdate = true
    end

    if table.size(objects) > 0 then
        local names = {}
        for id, _ in pairs(objects) do
            local obj = tes3.getObject(id)
            if obj and obj.name then
                table.insert(names, obj.name)
            end
        end

        if #names > 0 then
            tes3ui.showNotifyMenu(stringLib.getValueEnumString(names, config.data.journal.requirements.pathDescriptions, "Started tracking %s."))
        end
    end

    if shouldUpdate then
        if tes3.player.cell.isInterior then
            this.addMarkersForInteriorCell(tes3.player.cell)
        end

        this.updateMarkers(true)
    end
end

---@param questId string should be lowercase
function this.trackQuestsbyQuestId(questId)
    local shouldUpdate = false

    if this.removeMarker{ questId = questId, removeLinked = true } then
        shouldUpdate = true
    end

    local index = playerQuests.getCurrentIndex(questId)
    if not index then return end

    local questNextIndexes, linkedIndexData = questLib.getNextIndexes(questId, questId, index, {findCompleted = false, findInLinked = true})

    local objects = {}

    if questNextIndexes then
        for _, indexStr in pairs(questNextIndexes) do
            local objs = this.addMarkersForQuest{ questId = questId, questIndex = indexStr }
            table.copy(objs, objects)
        end
        shouldUpdate = true
    end

    if linkedIndexData then
        for qId, dt in pairs(linkedIndexData) do
            local objs = this.addMarkersForQuest{ questId = qId, questIndex = dt.index }
            table.copy(objs, objects)
        end
        shouldUpdate = true
    end

    if table.size(objects) > 0 then
        local names = {}
        for id, _ in pairs(objects) do
            local obj = tes3.getObject(id)
            if obj and obj.name then
                table.insert(names, obj.name)
            end
        end

        if #names > 0 then
            tes3ui.showNotifyMenu(stringLib.getValueEnumString(names, config.data.journal.requirements.pathDescriptions, "Started tracking %s."))
        end
    end

    if shouldUpdate then
        if tes3.player.cell.isInterior then
            this.addMarkersForInteriorCell(tes3.player.cell)
        end

        this.updateMarkers(true)
    end
end


---@param cell tes3cell
function this.addMarkersForInteriorCell(cell)
    if not cell or not cell.isInterior then return end

    for _, marker in pairs(lastInteriorMarkers) do
        marker:remove()
    end
    lastInteriorMarkers = {}

    ---@type table<tes3reference, {cells : table<string, { cell: tes3cell, depth: integer }>?, hasExit : any, ref : tes3reference}>
    local doors = {}

    for doorRef in cell:iterateReferences(tes3.objectType.door) do
        if doorRef.destination and not doorRef.deleted and not doorRef.disabled then
            local reachableCells, hasExit = cellLib.findReachableCellsByNode(doorRef.destination, {[cell.editorName] = {cell = cell, depth = 0}})
            reachableCells[cell.editorName] = nil

            doors[doorRef] = {cells = reachableCells, hasExit = hasExit, ref = doorRef}
        end
    end

    ---@type table<string, table<tes3reference, { cell: tes3cell, depth: integer }[]>>
    local doorByObjId = {}

    for objId, objData in pairs(this.markerByObjectId) do
        for qId, markerInfo in pairs(objData.markers) do
            local markerData = markerInfo.data
            if not markerData.localDoorMarkerId then goto continue end

            for cellId, parentCellId in pairs(objData.targetCells or {}) do
                for doorRef, doorData in pairs(doors) do
                    local targetCellDt = doorData.cells[parentCellId]
                    if targetCellDt then
                        if not doorByObjId[objId] then doorByObjId[objId] = {} end
                        if not doorByObjId[objId][doorRef] then doorByObjId[objId][doorRef] = {} end

                        table.insert(doorByObjId[objId][doorRef], targetCellDt)
                    end
                end
            end
        end
        ::continue::
    end

    for objId, objDoorDt in pairs(doorByObjId) do
        local depthHashTable = {}

        for doorRef, doorDt in pairs(objDoorDt) do
            for _, depthData in pairs(doorDt) do
                depthHashTable[depthData.depth] = true
            end
        end

        local depths = table.keys(depthHashTable, true)

        if #depths == 0 or depths[1] == 0 then goto continue end

        local lowestDepthHashTable = {}
        if depths[1] == 1 then
            lowestDepthHashTable[1] = true
        else
            local lowestDepth = depths[1]
            for i = 1, math.clamp(#depths, 1, config.data.tracking.approx.enabled and 1 or config.protected.tracking.interior.depthConut) do
                if lowestDepth + config.protected.tracking.interior.depthMaxDifference >= depths[i] then
                    lowestDepthHashTable[depths[i]] = true
                end
            end
        end

        for doorRef, doorDt in pairs(objDoorDt) do
            local shouldCreateMarker = false

            local lowestDepth = 999
            for _, depthData in pairs(doorDt) do
                if lowestDepthHashTable[depthData.depth] then
                    shouldCreateMarker = true
                    if lowestDepth > depthData.depth then
                        lowestDepth = depthData.depth
                    end
                end
            end

            if config.data.tracking.approx.enabled and config.data.tracking.approx.interior.minCellDepth > lowestDepth then
                shouldCreateMarker = false
            end

            if shouldCreateMarker then
                local objData = this.markerByObjectId[objId]
                if not objData then goto continue end

                for qId, markerInfo in pairs(objData.markers) do
                    local markerData = markerInfo.data
                    if markerData and markerData.localDoorMarkerId then
                        local marker = markerLib.localMarker.new{
                            record = markerData.localDoorMarkerId,
                            cell = doorRef.cell.isInterior == true and doorRef.cell.name or nil,
                            position = doorRef.position,
                            shortTerm = true,
                        }
                        if marker then
                            table.insert(lastInteriorMarkers, marker)
                        end

                        local infoRecordId, recordData = markerLib.duplicateRecord(markerData.localDoorMarkerId)
                        if infoRecordId and recordData then
                            recordData.userData = nil
                            recordData.temporary = true
                            recordData.priority = -1000

                            recordData.description = string.format("%s is %d cell%s away", recordData.name or "???", lowestDepth, lowestDepth == 1 and "" or "s")
                            recordData.color = tes3ui.getPalette(tes3.palette.journalFinishedQuestOverColor)

                            recordData.name = nil

                            local infoMarker = markerLib.localMarker.new{
                                record = infoRecordId,
                                cell = doorRef.cell.isInterior == true and doorRef.cell.name or nil,
                                position = doorRef.position,
                                shortTerm = true,
                            }
                            if infoMarker then
                                table.insert(lastInteriorMarkers, infoMarker)
                            end
                        end
                    end
                end
            end
        end

        ::continue::
    end
end


---@class questGuider.tracking.disableMarker
---@field questId string? should be lowercase
---@field objectId string? should be lowercase
---@field toggle boolean?
---@field value boolean?
---@field isUserDisabled boolean?
---@field temporary boolean?

---@param params questGuider.tracking.disableMarker
function this.setDisableMarkerState(params)
    if not (params.isUserDisabled or params.temporary) and
        params.questId and this.disabledQuests[params.questId] then
            return
    end

    local markerDataHashTable = {}

    for objId, objData in pairs(this.markerByObjectId) do
        if params.objectId and objId ~= params.objectId then goto continue end

        for qId, markerData in pairs(objData.markers) do
            if params.questId and qId ~= params.questId then goto continue end

            markerDataHashTable[markerData.data] = true

            ::continue::
        end

        ::continue::
    end

    ---@param markerData questGuider.tracking.markerRecord
    local function setDisabledState(markerData)
        local disabledState = params.toggle == true and not markerData.disabled or params.value

        if params.temporary then
            markerData.disabled = disabledState
        elseif params.isUserDisabled then
            markerData.disabled = disabledState
            if markerData.disabled == nil then markerData.disabled = false end
            markerData.userDisabled = markerData.disabled

        elseif markerData.userDisabled ~= nil then
            local userDisabled = markerData.userDisabled
            if userDisabled == disabledState then
                markerData.userDisabled = nil
            end
            markerData.disabled = userDisabled

        else
            markerData.disabled = disabledState
        end


        if this.mapMarkerLibVersion >= 3 then
            local localDoorMarkerRec = markerLib.record.get(markerData.localDoorMarkerId)
            local localMarkerRec = markerLib.record.get(markerData.localMarkerId)
            local worldMarkerRec = markerLib.record.get(markerData.worldMarkerId)

            if localDoorMarkerRec then localDoorMarkerRec:hide(markerData.disabled) end
            if localMarkerRec then localMarkerRec:hide(markerData.disabled) end
            if worldMarkerRec then worldMarkerRec:hide(markerData.disabled) end
        end
    end

    for markerData, _ in pairs(markerDataHashTable) do
        setDisabledState(markerData)
    end
end


---@class questGuider.tracking.getDisabledState
---@field questId string should be lowercase
---@field objectId string should be lowercase

---@param params questGuider.tracking.getDisabledState
---@return boolean?
function this.getDisabledState(params)
    if not params or not params.objectId or not params.questId then return end

    local objData = this.markerByObjectId[params.objectId]
    local objQuestTrackingData = objData and objData.markers[params.questId]
    local disabledState = objQuestTrackingData and objQuestTrackingData.data.disabled

    return disabledState or false
end


function this.recreateMarkers()
    local questIds = table.keys(this.trackedObjectsByQuestId)
    this.removeMarkers()
    for _, questId in pairs(questIds) do
        this.trackQuestsbyQuestId(questId)
    end
end


---@param menu tes3uiElement
---@param objectId string
function this.changeObjectTooltipTitle(menu, objectId)
    local objectData = this.markerByObjectId[objectId:lower()]
    if not objectData then return end

    local enabled = false
    for _, dt in pairs(objectData.markers) do
        if not dt.data.disabled then
            enabled = true
            break
        end
    end

    if enabled then
        tooltips.changeTooltipTitleColor(menu, tes3ui.getPalette(tes3.palette.miscColor))
    end
end


---@param markerData questGuider.tracking.markerData
local function checkHandledRequirements(objectId, markerData, protectedState)
    if not protectedState then protectedState = false end
    local changed = false
    if not markerData.handledRequirements then return end

    local res = false

    for _, reqBlock in pairs(markerData.handledRequirements) do
        local reqRes = requirementChecker.checkBlock(reqBlock, {threatErrorsAs = true})
        res = res or reqRes
    end

    if res == false then
        if markerData.data.disabled ~= true and not protectedState then
            this.setDisableMarkerState{ objectId = objectId, questId = markerData.id, value = true }
            changed = true
        end
    elseif res == true then
        protectedState = true
        if markerData.data.disabled ~= false then
            this.setDisableMarkerState{ objectId = objectId, questId = markerData.id, value = false }
            changed = true
        end
    end

    return changed, protectedState
end


local handlePlayerInventory_lastUpdate = nil
---@param force boolean?
---@return boolean? changed
function this.handlePlayerInventory(force)
    local timestamp = os.time()
    if not force and handlePlayerInventory_lastUpdate == timestamp then
        return
    else
        handlePlayerInventory_lastUpdate = timestamp
    end

    if this.mapMarkerLibVersion < 3 or (not config.data.tracking.hideObtained and not config.data.tracking.hideFinActors) then return end

    local mobile = tes3.mobilePlayer
    if not mobile then return end

    local changed = false

    for objId, data in pairs(this.markerByObjectId) do
        local protected = false
        for _, markerData in pairs(data.markers) do

            if markerData.handledRequirements and config.data.tracking.hideFinActors then
                local hChanged, hProtected = checkHandledRequirements(objId, markerData, protected)
                changed = changed or hChanged
                protected = protected or hProtected
            end

            if markerData.itemCount and config.data.tracking.hideObtained then
                if markerData.itemCount <= tes3.getItemCount{ reference = mobile, item = markerData.parentObject or objId } then
                    if markerData.data.disabled ~= true and not protected then
                        this.setDisableMarkerState{ objectId = objId, questId = markerData.id, value = true }
                        changed = true
                    end
                else
                    protected = true
                    if markerData.data.disabled ~= false then
                        this.setDisableMarkerState{ objectId = objId, questId = markerData.id, value = false }
                        changed = true
                    end
                end
            end

        end
    end

    if changed and tes3.player.cell.isInterior then
        this.addMarkersForInteriorCell(tes3.player.cell)
    end

    return changed
end


---@return boolean? changed
function this.handleDeath(objectId)
    if this.mapMarkerLibVersion < 3 or (not config.data.tracking.hideKilled and not config.data.tracking.hideFinActors) then return end

    if not objectId then return end
    objectId = objectId:lower()
    local objData = this.markerByObjectId[objectId]
    if not objData then return end

    local changed = false

    local protected = false
    for _, markerData in pairs(objData.markers) do

        if markerData.handledRequirements and config.data.tracking.hideFinActors then
            local hChanged, hProtected = checkHandledRequirements(objectId, markerData, protected)
            changed = changed or hChanged
            protected = protected or hProtected
        end

        if markerData.actorCount and config.data.tracking.hideKilled then
            local killCount = tes3.getKillCount{ actor = markerData.parentObject or objectId }

            if killCount >= markerData.actorCount then
                if markerData.data.disabled ~= true and not protected then
                    this.setDisableMarkerState{ objectId = objectId, questId = markerData.id, value = true }
                    changed = true
                end
            else
                protected = true
                if markerData.data.disabled ~= false then
                    this.setDisableMarkerState{ objectId = objectId, questId = markerData.id, value = false }
                    changed = true
                end
            end
        end
    end

    if changed and tes3.player.cell.isInterior then
        this.addMarkersForInteriorCell(tes3.player.cell)
    end

    return changed
end


---@return boolean?
function this.handleTrackingRequirements()

    if this.mapMarkerLibVersion < 3 or not config.data.tracking.hideFinActors then return end

    local changed = false
    local protected = false

    for objectId, data in pairs(this.markerByObjectId) do
        for _, markerData in pairs(data.markers) do

            local hChanged, hProtected = checkHandledRequirements(objectId, markerData, protected)
            changed = changed or hChanged
            protected = protected or hProtected

        end
    end

    if changed and tes3.player.cell.isInterior then
        this.addMarkersForInteriorCell(tes3.player.cell)
    end

    return changed
end


return this