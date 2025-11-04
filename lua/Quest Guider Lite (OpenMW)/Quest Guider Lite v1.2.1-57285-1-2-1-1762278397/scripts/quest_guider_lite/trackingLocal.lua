---@diagnostic disable: duplicate-doc-field
local core = require('openmw.core')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local playerRef = require('openmw.self')
local util = require("openmw.util")

local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local itemLib = require("scripts.quest_guider_lite.types.item")
local colors = require("scripts.quest_guider_lite.types.gradient")
local common = require("scripts.quest_guider_lite.common")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")

local storage = require("scripts.quest_guider_lite.storage.localStorage")

local playerDataHandler = require("scripts.quest_guider_lite.storage.playerDataHandler")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local killCounter = require("scripts.quest_guider_lite.killCounter")
local requirementChecker = require("scripts.quest_guider_lite.requirementChecker")

local requirementType = require("scripts.quest_guider_lite.types.requirement")

local config = require("scripts.quest_guider_lite.config")

local l10n = core.l10n(common.l10nKey)

---@type proximityTool
local proximityTool = I.proximityTool

local storageLabel = "tracking"


local this = {}


---@type table<string, {id : string?, groupId : string?, hudId : string}>
local lastInteriorMarkers = {}

---@type table<string, string>
local exteriorDoorHUDMarkers = {}
---@type table<string, any>
local exteriorDoors = {}

---@class questGuider.tracking.markerRecord
---@field localMarkerId string|nil
---@field localDoorMarkerId string|nil
---@field hudMarker string?
---@field disabled boolean?
---@field userDisabled boolean?

---@alias questGuider.tracking.markerData {id : string, index : integer, groupName : string, data : questGuider.tracking.markerRecord, parentObject: string?, itemCount : integer?, actorCount : integer?, handledRequirements : table<string, questDataGenerator.requirementBlock>?}

---@class questGuider.tracking.objectRecord
---@field color number[]?
---@field markers table<string, questGuider.tracking.markerData> by quest id
---@field targetCells table<string, string>? parent cell editor name by editor name of cell that have access to the parent
---@field firstEntranceCells table<string, any>?

---@type table<string, questGuider.tracking.objectRecord>
this.markerByObjectId = {}

---@type table<string, {objects : table<string, string[]>}>
this.trackedObjectsByDiaId = {}

---@type table<string, number[]>
this.lastObjectColor = {}

this.initialized = false

---@return boolean isSuccessful
function this.init()
    proximityTool = I.proximityTool
    if this.initialized then return true end

    this.initialized = false

    if not storage.isPlayerStorageReady() then
        return false
    end

    if not storage.data then return false end
    if not storage.data[storageLabel] then
        storage.data[storageLabel] = {colorId = 1}
    end
    this.storageData = storage.data[storageLabel]

    if not playerDataHandler.data.isReady then return false end

    this.storageData.markerByObjectId = this.storageData.markerByObjectId or {}
    this.storageData.trackedObjectsByQuestId = this.storageData.trackedObjectsByQuestId or {}
    this.storageData.lastObjectColor = this.storageData.lastObjectColor or {}

    this.markerByObjectId = this.storageData.markerByObjectId
    this.trackedObjectsByDiaId = this.storageData.trackedObjectsByQuestId
    this.lastObjectColor = this.storageData.lastObjectColor

    this.scannedCellsForTemporaryMarkers = {}

    this.initialized = true
    return this.initialized
end


---@class questGuider.tracking.addMarker
---@field questId string should be lower
---@field questStage integer
---@field objectId string should be lower
---@field objectName string?
---@field questData questDataGenerator.questData
---@field reqData questGuider.quest.getDescriptionDataFromBlock.returnArr?
---@field positionData questGuider.quest.getRequirementPositionData.returnData
---@field color number[]|nil
---@field priority number?

---@param params questGuider.tracking.addMarker
---@return questGuider.tracking.objectRecord|nil
function this.addMarker(params)
    if not this.initialized then return end

    local objectId = params.objectId

    local positionData = params.positionData

    local questData = params.questData

    if not questData or not positionData then return end

    if params.reqData and common.forbiddenForTracking[params.reqData.data.type or ""] then return end

    local playerQuestData = playerQuests.getQuestStorageData(questData.name)

    if playerQuestData then
        if not config.data.tracking.trackDisabled and playerQuestData.disabled then
            return
        end
    end

    local qTrackingInfo
    if this.trackedObjectsByDiaId[params.questId] then
        qTrackingInfo = this.trackedObjectsByDiaId[params.questId]
    else
        qTrackingInfo = {objects = {}}
    end

    local objectTrackingData = this.markerByObjectId[objectId]
    if not objectTrackingData then
        local lastColor = this.lastObjectColor[objectId]
        if not lastColor then
            local colorId = math.min(this.storageData.colorId, #colors)

            objectTrackingData = { markers = {}, color = config.data.tracking.colored and colors[colorId] } ---@diagnostic disable-line: missing-fields

            this.lastObjectColor[objectId] = colors[colorId]
            this.storageData.colorId = colorId < #colors and colorId + 1 or 1
        else
            objectTrackingData = { markers = {}, color = config.data.tracking.colored and lastColor } ---@diagnostic disable-line: missing-fields
        end
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

    local text
    local currentIndex = playerQuests.getCurrentIndex(params.questId)
    if currentIndex then
        text = stringLib.removeSpecialCharactersFromJournalText(playerQuests.getJournalText(params.questId, currentIndex))
    end
    if text == questData.name then text = nil end

    local priority = params.priority or 0

    local userData = {
        type = "tracking",
        diaId = params.questId,
        index = params.questStage,
        questName = questData.name,
    }

    ---@type proximityTool.record
    local markerRecordParams = {
        name = positionData.name,
        description = text,
        nameColor = config.data.tracking.colored and objectTrackingData.color,
        proximity = config.data.tracking.proximity * 69.99,
        priority = priority + 10,
        events = {
            MouseClick = "QGL:proximityMarkerCallback",
        },
        options = {
            hideDead = params.reqData and (params.reqData.data.type == requirementType.Dead)
        },
        userData = userData,
    }

    ---@type proximityTool.record
    local doorMarkerRecordParams = {
        name = string.format("%s", positionData.name),
        description = text,
        icon = common.doorMarkPath,
        iconRatio = 1.6,
        iconColor = common.defaultColorData,
        nameColor = config.data.tracking.colored and objectTrackingData.color,
        proximity = config.data.tracking.proximity * 69.99,
        priority = priority,
        events = {
            MouseClick = "QGL:proximityMarkerCallback",
        },
        userData = userData,
    }

    local createProximityMarkers = proximityTool and config.data.tracking.proximityMarkers.enabled and config.data.tracking.proximityMarkers.details.markers
    local createHUDMarkers = proximityTool and config.data.tracking.hudMarkers.enabled and config.data.tracking.hudMarkers.details.markers

    if createProximityMarkers then
        objectMarkerData.localMarkerId = proximityTool.addRecord(markerRecordParams)
        objectMarkerData.localDoorMarkerId = proximityTool.addRecord(doorMarkerRecordParams)
    end


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
        groupName = questData.name,
        data = objectMarkerData,
        itemCount = positionData.itemCount,
        actorCount = positionData.actorCount,
        parentObject = positionData.parentObject,
        handledRequirements = handledReqs,
    }

    local objects = {}
    objects[objectId] = true

    local isItem = itemLib.isItem(objectId)

    local markEntrances = #positionData.positions < config.data.tracking.maxPos

    local positionalMarkers = { record = objectMarkerData.localMarkerId, groupName = questData.name, positions = {} }
    local doorMarkers = { record = objectMarkerData.localDoorMarkerId, groupName = questData.name, positions = {} }

    for _, data in pairs(positionData.positions or {}) do

        if objectMarkerData.localMarkerId then

            local rawData = data.rawData
            if rawData then
                if rawData.id then
                    objects[rawData.id] = true
                end
            end

            if data.position and not data.id then
                table.insert(positionalMarkers.positions, {
                    cell = {
                        isExterior = data.id and false or true,
                        id = data.id,
                    },
                    position = data.position,
                })
            end

        end

        if data.id ~= nil then

            local cell = data.cellPath and data.cellPath[1] or nil
            if cell then

                if markEntrances then
                    local exitPositions = data.entrances

                    if exitPositions and objectMarkerData.localDoorMarkerId then

                        for _, posData in pairs(exitPositions) do
                            ---@type proximityTool.positionData
                            local pos = {position = posData, cell = {isExterior = true}}
                            table.insert(doorMarkers.positions, pos)
                        end
                    end
                end

                if not objectTrackingData.targetCells then
                    objectTrackingData.targetCells = {}
                end
                if not objectTrackingData.firstEntranceCells then
                    objectTrackingData.firstEntranceCells = {}
                end

                objectTrackingData.targetCells[cell.id] = cell.id
                tableLib.copy(data.firstEntranceCellIds or {}, objectTrackingData.firstEntranceCells)
            end
        end
    end

    local listOfObjects = tableLib.keys(objects)

    if createProximityMarkers then
        if next(doorMarkers.positions) then
            proximityTool.addMarker(doorMarkers)
        end

        if next(listOfObjects) then
            if #listOfObjects == 1 then
                proximityTool.addMarker{
                    record = objectMarkerData.localMarkerId,
                    objectId = listOfObjects[1],
                    positions = next(positionalMarkers.positions) and positionalMarkers.positions or nil,
                    groupName = questData.name,
                    itemId = isItem and objectId or nil,
                }
            else
                proximityTool.addMarker{
                    record = objectMarkerData.localMarkerId,
                    objectIds = listOfObjects,
                    positions = next(positionalMarkers.positions) and positionalMarkers.positions or nil,
                    groupName = questData.name,
                    itemId = isItem and objectId or nil,
                }
            end
        end
    end


    if createHUDMarkers then
        local scale = 1.5 * uiUtils.getScaledScreenSize().y / 1080
        ---@type proximityTool.hudm
        local hudMarkerParams = {
            modName = common.modName,
            version = 6,
            params = {
                icon = params.reqData and params.reqData.data.type == requirementType.CustomActor and common.hudQuestionMarkPath
                    or common.hudMarkerPath,
                scale = scale,
                raytracing = config.data.tracking.hudMarkers.rayTracing,
                range = config.data.tracking.hudMarkers.range * 3.28,
                opacity = config.data.tracking.hudMarkers.opacity * 0.01,
                screenOffset = util.vector2(2 * scale, 0),
                offsetMult = 1.0,
                offset = util.vector3(0, 0,
                    params.reqData and params.reqData.data.type == requirementType.CustomActor and 25 or 15
                ),
                -- bonusSize = 10,
                color = config.data.tracking.colored and objectTrackingData.color or common.colorToArray(config.data.ui.defaultColor),
            },
            objectIds = listOfObjects,
            itemId = positionData.parentObject
        }
        objectMarkerData.hudMarker = proximityTool.addHUDM(hudMarkerParams)
    end


    this.markerByObjectId[objectId] = objectTrackingData

    qTrackingInfo.objects[objectId] = listOfObjects

    this.trackedObjectsByDiaId[params.questId] = qTrackingInfo

    if positionData.itemCount then
        this.handlePlayerInventory()
    elseif positionData.actorCount then
        this.handleDeath(objectId)
    elseif handledReqs then
        this.handleTrackingRequirements()
    end

    local storageData = playerQuests.getQuestStorageData(params.questData.name)
    if storageData and storageData.disabled or this.storageData.hideAllMarkers then
        this.setDisableMarkerState{ questId = params.questId, value = true }
    end

    this.updateMarkers()

    return objectTrackingData
end


---@class questGuider.tracking.disableMarker
---@field questId string? should be lowercase
---@field objectId string? should be lowercase
---@field toggle boolean?
---@field value boolean?
---@field isUserDisabled boolean?
---@field temporary boolean?
---@field update boolean?

---@param params questGuider.tracking.disableMarker
---@return boolean? changed
function this.setDisableMarkerState(params)

    local markerDataHashTable = {}

    local hidden = false
    if params.questId then
        local qName = playerQuests.getQuestNameByDiaId(params.questId)
        if qName then
            local storageData = playerQuests.getQuestStorageData(qName)
            hidden = storageData and storageData.disabled or false
        end
    end

    for objId, objData in pairs(this.markerByObjectId) do
        if params.objectId and objId ~= params.objectId then goto continue end

        for qId, markerData in pairs(objData.markers) do
            if params.questId and qId ~= params.questId then goto continue end

            markerDataHashTable[markerData.data] = true

            ::continue::
        end

        ::continue::
    end

    local changed = false

    ---@param markerData questGuider.tracking.markerRecord
    local function setDisabledState(markerData)
        local disabledState
        local oldState = markerData.disabled

        if params.update then
            disabledState = oldState
            goto endLabel
        elseif params.toggle == false then
            disabledState = markerData.disabled
        elseif params.toggle == true then
            disabledState = not markerData.disabled
        else
            disabledState = params.value
        end

        if params.temporary then
            markerData.disabled = disabledState
        elseif params.isUserDisabled then
            markerData.disabled = disabledState or false
            markerData.userDisabled = markerData.disabled

        elseif markerData.userDisabled ~= nil then
            local userDisabled = markerData.userDisabled
            if userDisabled == (disabledState or hidden) then
                markerData.userDisabled = nil
            end
            markerData.disabled = userDisabled

        else
            markerData.disabled = disabledState or hidden
        end

        if oldState ~= markerData.disabled then
            changed = true
        end

        ::endLabel::

        disabledState = markerData.disabled
        if this.storageData.hideAllMarkers then
            disabledState = true
        end

        if markerData.localDoorMarkerId and proximityTool then
            proximityTool.setVisibility(markerData.localDoorMarkerId, nil, not disabledState)
        end
        if markerData.localMarkerId and proximityTool then
            proximityTool.setVisibility(markerData.localMarkerId, nil, not disabledState)
        end
        if markerData.hudMarker and proximityTool then
            proximityTool.setHUDMvisibility(markerData.hudMarker, not disabledState)
        end
    end

    for markerData, _ in pairs(markerDataHashTable) do
        setDisabledState(markerData)
    end

    return changed
end


---@class questGuider.tracking.getDisabledState
---@field questId string? should be lowercase
---@field objectId string should be lowercase

---@param params questGuider.tracking.getDisabledState
---@return boolean?
---@return boolean? userDisabled
function this.getDisabledState(params)
    if not params or not params.objectId then return end

    if params.questId then
        local disabledState = false
        local objData = this.markerByObjectId[params.objectId]
        local objQuestTrackingData = objData and objData.markers[params.questId]
        disabledState = objQuestTrackingData and objQuestTrackingData.data.disabled
        return disabledState or false
    else
        local objData = this.markerByObjectId[params.objectId]
        local found = false
        for qId, trackingData in pairs((objData or {}).markers) do
            found = true
            if not trackingData.data.disabled then
                return false
            end
        end
        if found then
            return true
        end
    end
    return false
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
            changed = this.setDisableMarkerState{ objectId = objectId, questId = markerData.id, value = true }
        end
    elseif res == true then
        protectedState = true
        if markerData.data.disabled ~= false then
            changed = this.setDisableMarkerState{ objectId = objectId, questId = markerData.id, value = false }
        end
    end

    return changed, protectedState
end


function this.handlePlayerInventory()
    if not this.initialized then return end
    local changed = false

    for objId, data in pairs(this.markerByObjectId) do
        local protected = false
        for _, markerData in pairs(data.markers) do

            if markerData.handledRequirements then -- and config.data.tracking.hideFinActors
                local hChanged, hProtected = checkHandledRequirements(objId, markerData, protected)
                changed = changed or hChanged
                protected = protected or hProtected
            end

            if markerData.itemCount then -- and config.data.tracking.hideObtained
                local palyerItemCount = types.Actor.inventory(playerRef):countOf(markerData.parentObject)
                if markerData.itemCount <= palyerItemCount then
                    if markerData.data.disabled ~= true and not protected then
                        changed = this.setDisableMarkerState{ objectId = objId, questId = markerData.id, value = true } or changed
                    end
                else
                    protected = true
                    if markerData.data.disabled ~= false then
                        changed = this.setDisableMarkerState{ objectId = objId, questId = markerData.id, value = false } or changed
                    end
                end
            end

        end
    end

    if changed and not playerRef.cell.isExterior then
        this.addMarkersForInteriorCell(playerRef.cell)
    end

    if changed and playerRef.cell.isExterior then
        this.updateMarkersForExteriorDoors()
    end

    if changed then
        this.updateMarkers()
    end

    return changed
end


---@return boolean? changed
function this.handleDeath(objectId)
    if not this.initialized then return end
    if not objectId then return end

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

        if markerData.actorCount then
            local killCount = killCounter.getKillCount(markerData.parentObject or objectId)

            if killCount >= markerData.actorCount then
                if markerData.data.disabled ~= true and not protected then
                    changed = this.setDisableMarkerState{ objectId = objectId, questId = markerData.id, value = true } or changed
                end
            else
                protected = true
                if markerData.data.disabled ~= false then
                    changed = this.setDisableMarkerState{ objectId = objectId, questId = markerData.id, value = false } or changed
                end
            end
        end
    end

    if changed and not playerRef.cell.isExterior then
        this.addMarkersForInteriorCell(playerRef.cell)
    end

    if changed and playerRef.cell.isExterior then
        this.updateMarkersForExteriorDoors()
    end

    if changed then
        this.updateMarkers()
    end

    return changed
end


---@return boolean?
function this.handleTrackingRequirements()
    if not this.initialized then return end
    local changed = false
    local protected = false

    for objectId, data in pairs(this.markerByObjectId) do
        for _, markerData in pairs(data.markers) do

            local hChanged, hProtected = checkHandledRequirements(objectId, markerData, protected)
            changed = changed or hChanged
            protected = protected or hProtected

        end
    end

    if changed and not playerRef.cell.isExterior then
        this.addMarkersForInteriorCell(playerRef.cell)
    end

    if changed and playerRef.cell.isExterior then
        this.updateMarkersForExteriorDoors()
    end

    return changed
end


---@param params questGuider.tracking.removeMarker
local function removeMarker(params)
    local recordIdsToRemove = {}
    local hudmMarkersToRemove = {}

    ---@param rec questGuider.tracking.markerRecord
    local function addToRemove(rec)
        recordIdsToRemove[rec.localDoorMarkerId or ""] = true
        recordIdsToRemove[rec.localMarkerId or ""] = true
        hudmMarkersToRemove[rec.hudMarker or ""] = true
    end

    for objId, objData in pairs(this.markerByObjectId) do
        if params.objectId and objId ~= params.objectId then goto continue end

        for qId, markerData in pairs(objData.markers) do
            if params.questId and qId ~= params.questId then goto continue end

            addToRemove(markerData.data)
            objData.markers[qId] = nil

            ::continue::
        end

        if not next(objData.markers) then
            this.markerByObjectId[objId] = nil
        end

        ::continue::
    end

    for qId, qData in pairs(this.trackedObjectsByDiaId) do
        if params.questId and params.questId ~= qId then goto continue end

        for objId, _ in pairs(qData.objects) do
            if params.objectId and objId ~= params.objectId then goto continue end

            qData.objects[objId] = nil

            ::continue::
        end

        if not next(qData.objects) then
            this.trackedObjectsByDiaId[qId] = nil
        end

        ::continue::
    end

    local removed = false

    if proximityTool then
        recordIdsToRemove[""] = nil
        for id, _ in pairs(recordIdsToRemove) do
            proximityTool.removeRecord(id)
            removed = true
        end

        hudmMarkersToRemove[""] = nil
        for id, _ in pairs(hudmMarkersToRemove) do
            proximityTool.removeHUDM(id)
            removed = true
        end
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
    if not this.initialized then return end
    if not params.questId and not params.objectId then return end

    local res = false

    if params.removeLinked and params.questId then
        local qData = playerQuests.getQuestDataByDiaId(params.questId)
        if not qData then return end
        for diaId, _ in pairs(qData.records or {}) do
            res = removeMarker{ questId = diaId, objectId = params.objectId } or res
        end
    end
    res = removeMarker(params) or res

    return res
end


function this.removeAll()
    for diaId, objects in pairs(this.trackedObjectsByDiaId) do
        this.removeMarker{questId = diaId}
    end
end


---@class questGuider.tracking.addMarkersForQuest
---@field questId string should be lowercase
---@field questIndex integer|string

---@param params questGuider.tracking.addMarkersForQuest
---@return table<string, boolean>? objects object ids
function this.addMarkersForQuest(params)
    if not this.initialized then return end

    core.sendGlobalEvent("QGL:getTrackingData", {questId = params.questId, index = params.questIndex})

    if not playerRef.cell.isExterior then
        this.addMarkersForInteriorCell(playerRef.cell)
    else
        this.updateMarkersForExteriorDoors()
    end
end


function this.trackQuest(questId, index)
    local shouldUpdate = false

    if this.removeMarker{ questId = questId } then
        shouldUpdate = true
    end

    local isFinished = playerQuests.isFinished(questId)

    if isFinished then
        this.removeMarker{ questId = questId, removeLinked = true }
        this.updateMarkers()

    else
        core.sendGlobalEvent("QGL:trackQuest", {
            questId = questId,
            index = index,
            finished = isFinished,
            shouldUpdate = shouldUpdate,
            params = {findCompleted = false, findInLinked = true}
        })
    end
end


---@param params {objectId : string, diaId : string, index : integer}
function this.trackObject(params)
    if not this.initialized then return end
    this.removeMarker{ questId = params.diaId, objectId = params.objectId}

    core.sendGlobalEvent("QGL:trackObject", {
        diaId = params.diaId,
        objectId = params.objectId,
        index = params.index,
    })
end


function this.addTrackingMarker(recordData, markerData)
    if not this.initialized or not proximityTool then return end
    if not recordData or not markerData then return end

    local recordId = proximityTool.addRecord(recordData)
    markerData.record = recordId

    local markerId, markerGroupId = proximityTool.addMarker(markerData)

    return recordId, markerId, markerGroupId
end


function this.addHUDMarker(markerData)
    if not this.initialized or not proximityTool then return end
    return proximityTool.addHUDM(markerData)
end


local interiorHUDMoffsetData = {offset = 0, step = 0}
local interiorHUDMobjectOffset = {}
function this.addMarkersForInteriorCell(cell)
    if not this.init() or not proximityTool then return end

    for id, markerData in pairs(lastInteriorMarkers) do
        if markerData.id then
            proximityTool.removeMarker(markerData.id, markerData.groupId)
        elseif markerData.hudId then
            proximityTool.removeHUDM(markerData.hudId)
        end
        lastInteriorMarkers[id] = nil
    end

    interiorHUDMoffsetData.offset = 0
    interiorHUDMoffsetData.step = 0
    interiorHUDMobjectOffset = {}
    core.sendGlobalEvent("QGL:addMarkersForInteriorCell", {
        cellId = cell.id,
        markerByObjectId = this.markerByObjectId,
    })
end


function this.addMarkerForInteriorCellFromGlobal(data)
    if not proximityTool or this.storageData.hideAllMarkers then return end

    local markerData = data.markerData
    local description = data.description
    local doors = data.doors
    local disabled = data.disabled
    local objectId = data.objId

    if markerData and markerData.record and description then

        local recordData = proximityTool.getMarkerData(markerData.record)
        if recordData and config.data.tracking.proximityMarkers.enabled
                and config.data.tracking.proximityMarkers.details.markers then

            local newRecordData = tableLib.deepcopy(recordData)
            newRecordData.description = {newRecordData.description, data.description}

            markerData.record = newRecordData

            local id, groupId = proximityTool.addMarker(markerData)
            if id and groupId then
                lastInteriorMarkers[id] = { id = id, groupId = groupId }
            end
        end

    end


    if config.data.tracking.hudMarkers.enabled and config.data.tracking.hudMarkers.details.markers then
        local scale = 2 * uiUtils.getScaledScreenSize().y / 1080
        local offset = interiorHUDMobjectOffset[objectId] or interiorHUDMoffsetData.offset

        if not interiorHUDMobjectOffset[objectId] then
            interiorHUDMoffsetData.offset = math.floor(1 + interiorHUDMoffsetData.step / 2) * 6
            if interiorHUDMoffsetData.step % 2 == 1 then
                interiorHUDMoffsetData.offset = -interiorHUDMoffsetData.offset
            end
            interiorHUDMoffsetData.step = interiorHUDMoffsetData.step + 1
        end

        interiorHUDMobjectOffset[objectId] = offset

        ---@type proximityTool.hudm
        local hudDoorMarkerParams = {
            modName = common.modName,
            version = 6,
            params = {
                icon = common.doorMarkPath,
                scale = scale,
                raytracing = config.data.tracking.hudMarkers.rayTracing,
                range = config.data.tracking.hudMarkers.range * 3.28,
                opacity = config.data.tracking.hudMarkers.opacity * 0.01,
                screenOffset = util.vector2(offset * scale, 0),
                boundingBoxCenter = true,
                offset = util.vector3(0, 0, 25),
                -- offsetMult = 0.3,
                bonusSize = 10,
                color = data.color and data.color or common.colorToArray(config.data.ui.defaultColor),
            },
            objects = doors,
            shortTerm = true,
            hidden = disabled,
        }
        local hudMarkerId = proximityTool.addHUDM(hudDoorMarkerParams)
        if hudMarkerId then
            lastInteriorMarkers[hudMarkerId] = { hudId = hudMarkerId }
        end
    end
end


function this.createMarkersForExteriorDoor(ref)
    if not this.initialized or not proximityTool then return end
    if not (config.data.tracking.hudMarkers.enabled and config.data.tracking.hudMarkers.details.markers) then
        return
    end

    if not types.Door.objectIsInstance(ref) or not types.Door.isTeleport(ref) then
        return
    end
    local destCell = types.Door.destCell(ref)
    if not destCell or destCell.isExterior then return end

    exteriorDoors[ref.id] = ref

    if this.storageData.hideAllMarkers then return end

    local cellId = destCell.id

    local i = -1
    for objId, data in pairs(this.markerByObjectId) do
        if not data.firstEntranceCells or not data.firstEntranceCells[cellId]
                or not next(data.markers) or this.getDisabledState{objectId = objId} then
            goto continue
        end

        local offset = math.floor(1 + i / 2) * 6
        if i % 2 == 1 then
            offset = -offset
        end
        i = i + 1

        local scale = 2 * uiUtils.getScaledScreenSize().y / 1080
        ---@type proximityTool.hudm
        local hudDoorMarkerParams = {
            modName = common.modName,
            version = 6,
            params = {
                icon = common.doorMarkPath,
                scale = scale,
                raytracing = config.data.tracking.hudMarkers.rayTracing,
                range = config.data.tracking.hudMarkers.range * 3.28,
                opacity = config.data.tracking.hudMarkers.opacity * 0.01,
                screenOffset = util.vector2(offset * scale, 0),
                boundingBoxCenter = true,
                offset = util.vector3(0, 0, 25),
                -- offsetMult = 0.3,
                bonusSize = 10,
                color = data.color and data.color or common.colorToArray(config.data.ui.defaultColor),
            },
            objects = {ref},
            shortTerm = true,
        }
        local hudMarkerId = proximityTool.addHUDM(hudDoorMarkerParams)
        if hudMarkerId then
            exteriorDoorHUDMarkers[hudMarkerId] = hudMarkerId
        end

        ::continue::
    end
end


function this.updateMarkersForExteriorDoors()
    if not this.initialized or not proximityTool then return end
    local foundOldMarkers = false
    for _, markerId in pairs(exteriorDoorHUDMarkers) do
        foundOldMarkers = proximityTool.removeHUDM(markerId) or foundOldMarkers
    end
    if foundOldMarkers then
        this.updateHUDM()
    end

    for doorId, door in pairs(exteriorDoors) do
        if not door:isValid() then
            exteriorDoors[doorId] = nil
            goto continue
        end

        this.createMarkersForExteriorDoor(door)

        ::continue::
    end
end


function this.updateTemporaryMarkers()
    if not this.initialized then return end
    local plCell = playerRef.cell
    if plCell.isExterior then
        this.updateMarkersForExteriorDoors()
    else
        this.addMarkersForInteriorCell(plCell)
    end
end


---@param params {diaId : string?, objectId : string}
---@return boolean
function this.isObjectTracked(params)
    if params.diaId then
        local dt = this.trackedObjectsByDiaId[params.diaId]
        if not dt then return false end

        if not dt.objects[params.objectId] then return false end
    else
        if not this.markerByObjectId[params.objectId] then return false end
    end

    return true
end


---@param params {diaId : string}
---@return boolean
function this.isDialogueHasTracked(params)
    local dia = this.trackedObjectsByDiaId[params.diaId]
    if not dia then return false end
    if not next(dia.objects) then return false end

    return true
end


---@return table<string, string[]>?
function this.getDiaTrackedObjects(diaId)
    if this.trackedObjectsByDiaId[diaId] then
        return this.trackedObjectsByDiaId[diaId].objects or {}
    end
    return nil
end


---@param objId string
---@return questGuider.tracking.objectRecord?
function this.getTrackedObjectData(objId)
    return this.markerByObjectId[objId]
end


function this.removeProximityRecord(id)
    if not proximityTool then return end
    return proximityTool.removeRecord(id)
end


function this.removeProximityMarker(id, groupId)
    if not proximityTool then return end
    return proximityTool.removeMarker(id, groupId)
end


function this.removeHUDMarker(id)
    if not proximityTool then return end
    return proximityTool.removeHUDM(id)
end


function this.updateMarkers()
    if not proximityTool then return end
    proximityTool.update()
    proximityTool.updateHUDM()
end


function this.updateHUDM()
    if not proximityTool then return end
    proximityTool.updateHUDM()
end


function this.updateProximityMarkers()
    if not proximityTool then return end
    proximityTool.update()
end


---@param params {recordId : string?, markerId : string?, groupId : string?, value : boolean}
function this.setProximityMarkerVisibility(params)
    if not proximityTool then return end
    if params.recordId then
        proximityTool.setVisibility(params.recordId, nil, params.value)
    else
        proximityTool.setVisibility(params.markerId, params.groupId, params.value)
    end
end


---@param params {markerId : string?, value : boolean}
function this.setHUDMarkerVisibility(params)
    if not proximityTool then return end
    proximityTool.setHUDMvisibility(params.markerId, params.value)
end


function this.getMarkersVisibility()
    if not this.initialized then return end
    return not this.storageData.hideAllMarkers or false
end


---@param params {toggle : boolean?, value : boolean?, includeQuestGivers : boolean?}
function this.setMarkersVisibility(params)
    if not this.initialized then return end

    if params.value ~= nil then
        this.storageData.hideAllMarkers = params.value
    elseif params.toggle == true then
        this.storageData.hideAllMarkers = not this.storageData.hideAllMarkers
    end

    for objId, _ in pairs(this.markerByObjectId) do
        this.setDisableMarkerState{
            objectId = objId,
            update = true
        }
    end

    this.updateTemporaryMarkers()

    if params.includeQuestGivers then
        core.sendGlobalEvent("QGL:updateQuestGiverMarkers")
    end

    this.updateMarkers()
end


return this