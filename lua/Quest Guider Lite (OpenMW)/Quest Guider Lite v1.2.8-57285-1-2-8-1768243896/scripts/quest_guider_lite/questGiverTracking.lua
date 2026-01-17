local types = require('openmw.types')
local world = require('openmw.world')
local util = require("openmw.util")

local tes3 = require("scripts.quest_guider_lite.core.tes3")

local stringLib = require("scripts.quest_guider_lite.utils.string")
local tableLib = require("scripts.quest_guider_lite.utils.table")

local commonInfo = require("scripts.quest_guider_lite.common")

local questLib = require("scripts.quest_guider_lite.quest")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")

local cellLib = require("scripts.quest_guider_lite.cell")

local config = require("scripts.quest_guider_lite.config")

local l10n = require('openmw.core').l10n(commonInfo.l10nKey)


local this = {}


---@type table<string, {type : string, markerId : string?, hudMarkerId : string?, refs : table<string, {ref : any, markerId : string?, hudMarkerId : string?}>?}>
this.trackedQuestGivers = {}

this.scaledScreenSize = {x = 1920, y = 1080}



function this.registerTrackedQuestGiver(inputData, markerRecordId, hudMarkerId)
    local objectRecordId = inputData.objectRecordId
    if not this.trackedQuestGivers[objectRecordId] then
        this.trackedQuestGivers[objectRecordId] = {refs = {}}
    end
    if inputData.type == "door" then
        local refDt = this.trackedQuestGivers[objectRecordId].refs[inputData.refId]
        if not refDt then return end

        refDt.markerId = markerRecordId
        refDt.hudMarkerId = hudMarkerId
    else
        local oldMarkerId = this.trackedQuestGivers[objectRecordId].markerId
        local oldHudMarkerId = this.trackedQuestGivers[objectRecordId].hudMarkerId
        if oldMarkerId and oldMarkerId ~= markerRecordId then
            world.players[1]:sendEvent("QGL:removeProximityRecord", {recordId = oldMarkerId})
        end
        if oldHudMarkerId and oldHudMarkerId ~= hudMarkerId then
            world.players[1]:sendEvent("QGL:removeHUDMarker", {id = oldHudMarkerId})
        end

        this.trackedQuestGivers[objectRecordId].markerId = markerRecordId
        this.trackedQuestGivers[objectRecordId].hudMarkerId = hudMarkerId
    end
end


function this.createQuestGiverMarker(ref)
    local recordId = ref.recordId

    do
        local dt = this.trackedQuestGivers[recordId]
        if dt and (dt.hudMarkerId or dt.markerId) then
            this.trackedQuestGivers[recordId].refs[ref.id] = {ref = ref}
            return
        end
    end

    local objectData = questLib.getObjectData(recordId)
    if not objectData or not objectData.starts then return end

    local questNames = {}
    local diaIds = {}

    for _, diaId in pairs(objectData.starts) do
        local diaIdLower = diaId:lower()
        if (playerQuests.getCurrentIndex(diaIdLower) or 0) > 0 then goto continue end

        local questData = questLib.getQuestData(diaIdLower)
        if not questData or not questData.name then goto continue end

        for _, linkId in pairs(questData.links or {}) do
            if (playerQuests.getCurrentIndex(linkId) or 0) > 0 then goto continue end
        end

        local firstIndexStr = questLib.getFirstIndex(questData)
        if not firstIndexStr then goto continue end
        if not questLib.checkConditionsForQuest(diaIdLower, firstIndexStr) then
            goto continue
        end

        questNames[questData.name] = questData.name
        diaIds[diaId] = true

        ::continue::
    end

    questNames = tableLib.values(questNames, true)

    if #questNames <= 0 then return end

    ---@type proximityTool.record
    local recordData = {
        icon = commonInfo.exclamationMarkPath,
        iconRatio = 2,
        iconColor = commonInfo.defaultColorData,
        nameColor = commonInfo.defaultColorData,
        description = {stringLib.getValueEnumString(questNames, config.data.journal.objectNames, l10n("starts").." %s"), l10n("clickForInfo")},
        proximity = config.data.tracking.questGiverProximity * 69.99,
        priority = -100,
        temporary = true,
        options = {hideDead = true},
        userData = {
            type = "questGiver",
            diaIds = tableLib.keys(diaIds),
            objName = (tes3.getObject(recordId) or {}).name or l10n("questGiverU"),
        },
        events = {
            MouseClick = "QGL:questGiverMarkerCallback",
        },
    }

    ---@type proximityTool.hudm?
    local hudMarkerParams
    if config.data.tracking.hudMarkers.enabled then
        local scale = 1.5 * this.scaledScreenSize.y / 1080
        hudMarkerParams = {
            modName = commonInfo.modName,
            version = 6,
            params = {
                icon = commonInfo.hudExclamationMarkPath,
                screenOffset = util.vector2(7 * scale, 0),
                scale = scale,
                raytracing = config.data.tracking.hudMarkers.rayTracing,
                range = config.data.tracking.hudMarkers.range * 3.2808,
                opacity = config.data.tracking.hudMarkers.opacity * 0.01,
                offsetMult = 1,
                offset = util.vector3(0, 0, 25),
                -- boundingBoxCenter = true,
                -- bonusSize = 0,
                color = commonInfo.colorToArray(config.data.ui.defaultColor),
            },
            objectIds = {recordId},
            hideDead = true,
            temporary = true,
        }
    end


    ---@type proximityTool.marker
    ---@diagnostic disable-next-line: missing-fields
    local markerData = {
        objectId = recordId,
        groupName = commonInfo.questGiverGroup,
        temporary = true,
    }

    if not this.trackedQuestGivers[ref.recordId] then
        this.trackedQuestGivers[ref.recordId] = {refs = {}}
    end
    this.trackedQuestGivers[ref.recordId].refs[ref.id] = {ref = ref}

    world.players[1]:sendEvent("QGL:addMarkerForQuestGivers", {
        type = "object",
        questNames = questNames,
        recordData = recordData,
        markerData = markerData,
        objectRecordId = recordId,
        hudMarkerData = hudMarkerParams
    })
end


function this.updateQuestGiverMarkers()

    for objId, markerData in pairs(this.trackedQuestGivers) do
        world.players[1]:sendEvent("QGL:removeProximityRecord", {recordId = markerData.markerId})
        world.players[1]:sendEvent("QGL:removeHUDMarker", {id = markerData.hudMarkerId})
        markerData.markerId = nil
        markerData.hudMarkerId = nil

        local found = false
        for refId, refDt in pairs(markerData.refs) do
            if refDt.ref:isValid() then
                found = true
                if refDt.hudMarkerId or refDt.markerId then
                    world.players[1]:sendEvent("QGL:updateHUDMarkerVisibility", {id = refDt.hudMarkerId})
                    world.players[1]:sendEvent("QGL:updateProximityMarkerVisibility", {recordId = refDt.markerId})
                else
                    this.createQuestGiverMarker(refDt.ref)
                end
            else
                markerData.refs[refId] = nil
            end
        end

        if not found then
            this.trackedQuestGivers[objId] = nil
        end
    end
end


function this.createQuestGiverMarkerForDoor(ref)
    if not types.Door.isTeleport(ref) then return end

    local destCell = types.Door.destCell(ref)
    if not destCell then return end

    local destCellData = tes3.getCellData(destCell)

    local cellsData = cellLib.findReachableCellsByNode({cell = destCell}) ---@diagnostic disable-line: missing-fields

    ---@type table<string, {data : questDataGenerator.objectInfo, ref : any}>
    local giverIdsWithData = {}

    local function checkObj(ref)
        local recordId = ref.recordId
        if giverIdsWithData[recordId] then return end

        local objectData = questLib.getObjectData(recordId)
        if not objectData or not objectData.starts then return end
        giverIdsWithData[recordId] = {ref = ref, data = objectData}
    end

    for _, cellData in pairs(cellsData or {}) do
        local cell = cellData.cell
        for _, obj in pairs(cell:getAll(types.NPC)) do
            checkObj(obj)
        end
        for _, obj in pairs(cell:getAll(types.Creature)) do
            checkObj(obj)
        end
    end

    local questNames = {}
    local diaIds = {}

    for objId, giverData in pairs(giverIdsWithData) do
        local objectData = giverData.data
        local giverRef = giverData.ref
        for _, diaId in pairs(objectData.starts) do
            local diaIdLower = diaId:lower()
            if (playerQuests.getCurrentIndex(diaIdLower) or 0) > 0 then goto continue end

            local questData = questLib.getQuestData(diaIdLower)
            if not questData or not questData.name then goto continue end

            for _, linkId in pairs(questData.links or {}) do
                if (playerQuests.getCurrentIndex(linkId) or 0) > 0 then goto continue end
            end

            local firstIndexStr = questLib.getFirstIndex(questData)
            if not firstIndexStr then goto continue end
            if not questLib.checkConditionsForQuest(diaIdLower, firstIndexStr) then
                goto continue
            end

            local currentIndex = playerQuests.getCurrentIndex(diaId)
            if not currentIndex or currentIndex > 0 then
                goto continue
            end

            questNames[questData.name] = questData.name
            diaIds[diaId] = true

            ::continue::
        end
    end

    questNames = tableLib.values(questNames, true)

    if #questNames <= 0 then return end

    ---@type proximityTool.record
    local recordData = {
        name = destCell.displayName or destCell.name or "???",
        icon = commonInfo.doorExclMarkPath,
        iconColor = commonInfo.defaultColorData,
        nameColor = commonInfo.defaultColorData,
        description = {stringLib.getValueEnumString(questNames, config.data.journal.objectNames, l10n("doorGiverMessage")), l10n("clickForInfo")},
        proximity = 400,
        priority = 0,
        userData = {
            type = "doorQuestGiver",
            diaIds = tableLib.keys(diaIds),
            objName = destCellData and destCellData.name or l10n("questGiversU"),
        },
        events = {
            MouseClick = "QGL:questGiverMarkerCallback",
        },
        shortTerm = true,
    }


    ---@type proximityTool.marker
    ---@diagnostic disable-next-line: missing-fields
    local markerData = {
        object = ref,
        groupName = commonInfo.questGiverGroup,
        shortTerm = true,
    }

    if not this.trackedQuestGivers[ref.recordId] then
        this.trackedQuestGivers[ref.recordId] = {refs = {}}
    end
    this.trackedQuestGivers[ref.recordId].refs[ref.id] = {ref = ref}

    world.players[1]:sendEvent("QGL:addMarkerForQuestGivers", {
        type = "door",
        objectRecordId = ref.recordId,
        refId = ref.id,
        questNames = questNames,
        recordData = recordData,
        markerData = markerData,
    })
end


return this