local types = require('openmw.types')
local world = require('openmw.world')
local util = require("openmw.util")

local tes3 = require("scripts.quest_guider_lite.core.tes3")
local protectedDoor = require("scripts.quest_guider_lite.helpers.protectedDoor")

local stringLib = require("scripts.quest_guider_lite.utils.string")
local tableLib = require("scripts.quest_guider_lite.utils.table")

local commonInfo = require("scripts.quest_guider_lite.common")

local questBase = require("scripts.quest_guider_lite.questBase")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")

local cellLib = require("scripts.quest_guider_lite.cell")

local l10n = require('openmw.core').l10n(commonInfo.l10nKey)


local this = {}


---@type table<string, string[]> by object id, dia list
this.activeGivers = {}


---@type table<string, {type : string, player : any, markerId : string?, hudMarkerId : string?, refs : table<string, {ref : any, markerId : string?, hudMarkerId : string?}>?}>
this.trackedQuestGivers = {}

this.scaledScreenSize = {x = 1920, y = 1080}



local function getTrackedId(player, objRecordId)
    return string.format("%s_%s", player.id, objRecordId)
end


function this.registerTrackedQuestGiver(inputData, markerRecordId, hudMarkerId, player)
    local id = getTrackedId(player, inputData.objectRecordId)
    if not this.trackedQuestGivers[id] then
        this.trackedQuestGivers[id] = {refs = {}, player = player}
    end
    if inputData.type == "door" then
        local refDt = this.trackedQuestGivers[id].refs[inputData.refId]
        if not refDt then return end

        refDt.markerId = markerRecordId
        refDt.hudMarkerId = hudMarkerId
    else
        local oldMarkerId = this.trackedQuestGivers[id].markerId
        local oldHudMarkerId = this.trackedQuestGivers[id].hudMarkerId
        if oldMarkerId and oldMarkerId ~= markerRecordId then
            player:sendEvent("QGL:removeProximityRecord", {recordId = oldMarkerId})
        end
        if oldHudMarkerId and oldHudMarkerId ~= hudMarkerId then
            player:sendEvent("QGL:removeHUDMarker", {id = oldHudMarkerId})
        end

        this.trackedQuestGivers[id].markerId = markerRecordId
        this.trackedQuestGivers[id].hudMarkerId = hudMarkerId
    end
end


function this.createQuestGiverMarker(ref, player)
    if not ref.enabled then return end

    local recordId = ref.recordId
    local trackedId = getTrackedId(player, recordId)

    do
        local dt = this.trackedQuestGivers[trackedId]
        if dt and (dt.hudMarkerId or dt.markerId) then
            this.trackedQuestGivers[trackedId].refs[ref.id] = {ref = ref}
            return
        end
    end

    local diaIds, _, activatedByScript = questBase.getGiverQuests(ref, player)
    if not diaIds then return end

    local questNames = {}
    for diaId in pairs(diaIds) do
        local qName = playerQuests.getQuestNameByDiaId(diaId)
        if qName then
            questNames[qName] = qName
        end
    end

    questNames = tableLib.values(questNames, true)

    if #questNames <= 0 then return end

    ---@type proximityTool.record
    local recordData = {
        icon = commonInfo.exclamationMarkPath,
        iconRatio = 2,
        iconColor = commonInfo.defaultColorData,
        nameColor = commonInfo.defaultColorData,
        description = "",
        proximity = 0,
        priority = -100,
        temporary = true,
        options = {hideDead = not activatedByScript},
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
    do
        local scale = 1.5 * this.scaledScreenSize.y / 1080
        hudMarkerParams = {
            modName = commonInfo.modName,
            version = 6,
            params = {
                icon = commonInfo.hudExclamationMarkPath,
                screenOffset = util.vector2(7 * scale, 0),
                scale = scale,
                raytracing = false,
                range = 1,
                opacity = 0,
                offsetMult = 1,
                offset = util.vector3(0, 0, 25),
                -- boundingBoxCenter = true,
                -- bonusSize = 0,
                -- color = commonInfo.colorToArray(config.data.ui.defaultColor),
            },
            objectIds = {recordId},
            hideDead = not activatedByScript,
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

    if not this.trackedQuestGivers[trackedId] then
        this.trackedQuestGivers[trackedId] = {refs = {}, player = player}
    end
    this.trackedQuestGivers[trackedId].refs[ref.id] = {ref = ref}

    player:sendEvent("QGL:addMarkerForQuestGivers", {
        type = "object",
        questNames = questNames,
        recordData = recordData,
        markerData = markerData,
        objectRecordId = recordId,
        hudMarkerData = hudMarkerParams
    })
end


function this.updateQuestGiverMarkers(player)

    for trId, markerData in pairs(this.trackedQuestGivers) do
        if markerData.player.id ~= player.id then goto continue end

        markerData.player:sendEvent("QGL:removeProximityRecord", {recordId = markerData.markerId})
        markerData.player:sendEvent("QGL:removeHUDMarker", {id = markerData.hudMarkerId})
        markerData.markerId = nil
        markerData.hudMarkerId = nil

        local found = false
        for refId, refDt in pairs(markerData.refs) do
            if refDt.ref:isValid() then
                found = true
                if refDt.hudMarkerId or refDt.markerId then
                    markerData.player:sendEvent("QGL:updateHUDMarkerVisibility", {id = refDt.hudMarkerId})
                    markerData.player:sendEvent("QGL:updateProximityMarkerVisibility", {recordId = refDt.markerId})
                else
                    this.createQuestGiverMarker(refDt.ref, markerData.player)
                end
            else
                markerData.refs[refId] = nil
            end
        end

        if not found then
            this.trackedQuestGivers[trId] = nil
        end

        ::continue::
    end
end


function this.createQuestGiverMarkerForDoor(ref, player)
    if not types.Door.isTeleport(ref) or not ref.enabled then return end

    local destCell = protectedDoor.destCell(ref)
    if not destCell then return end

    local destCellData = tes3.getCellData(destCell)

    local cellsData = cellLib.findReachableCellsByNode({cell = destCell}, nil, nil, 2, {[ref.cell.id] = true}) ---@diagnostic disable-line: missing-fields

    local diaIds = {}

    local isGiver = false
    local function checkObj(r)
        local dIds, isGiv = questBase.getGiverQuests(r, player)
        isGiver = isGiver or isGiv
        if not dIds then return end
        tableLib.copy(dIds, diaIds)
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
    for diaId in pairs(diaIds) do
        local qName = playerQuests.getQuestNameByDiaId(diaId)
        if qName then
            questNames[qName] = qName
        end
    end

    questNames = tableLib.values(questNames, true)

    if #questNames <= 0 then
        if isGiver then
            player:sendEvent("QGL:updateMapMarkerForQuestGivers", {
                ref = ref,
            })
        end
        return
    end

    ---@type proximityTool.record
    local recordData = {
        name = destCell.displayName or destCell.name or "???",
        icon = commonInfo.doorExclMarkPath,
        iconColor = commonInfo.defaultColorData,
        nameColor = commonInfo.defaultColorData,
        description = "",
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

    local trackedId = getTrackedId(player, ref.recordId)
    if not this.trackedQuestGivers[trackedId] then
        this.trackedQuestGivers[trackedId] = {refs = {}, player = player}
    end
    this.trackedQuestGivers[trackedId].refs[ref.id] = {ref = ref}

    player:sendEvent("QGL:addMarkerForQuestGivers", {
        type = "door",
        objectRecordId = ref.recordId,
        refId = ref.id,
        ref = ref,
        questNames = questNames,
        recordData = recordData,
        markerData = markerData,
    })
end


return this