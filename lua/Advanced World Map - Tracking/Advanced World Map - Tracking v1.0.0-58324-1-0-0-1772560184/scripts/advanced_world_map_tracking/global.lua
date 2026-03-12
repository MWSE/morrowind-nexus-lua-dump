local async = require("openmw.async")
local types = require("openmw.types")
local world = require("openmw.world")

local commonData = require("scripts.advanced_world_map_tracking.common")
local supportedObjectTypes = require("scripts.advanced_world_map_tracking.supportedObjectTypes")


---@type table<string, boolean>
local availableCellIdsMap = {}

for _, cell in pairs(world.cells) do
    if cell.id then
        availableCellIdsMap[cell.id] = true
    end
end


local function sendEventToPlayers(eventStr, data)
    for _, pl in pairs(world.players) do
        pl:sendEvent(eventStr, data)
    end
end


local function onObjectActiveGlobal(object)
    if supportedObjectTypes[object.type] then
        if not object:hasScript(commonData.objectScriptPath) then

            sendEventToPlayers("advWMap_tracking:addActiveObject", object)
            object:addScript(commonData.objectScriptPath)

        end
    end
end

local function onObjectActive(object)
    sendEventToPlayers("advWMap_tracking:addActiveObject", object)
end

local function objectInactive(objectData)
    local object = objectData[1]
    sendEventToPlayers("advWMap_tracking:removeActiveObject", objectData)
    if object:isValid() and object:hasScript(commonData.objectScriptPath) then
        object:removeScript(commonData.objectScriptPath)
    end
end

local function checkObjectStatus(objectData)
    local object = objectData[1]
    if not object:isValid() then
        sendEventToPlayers("advWMap_tracking:removeActiveObject", objectData)
        return
    end

    if not object.cell or not object.enabled then
        sendEventToPlayers("advWMap_tracking:removeActiveObject", objectData)
        if object:hasScript(commonData.objectScriptPath) then
            object:removeScript(commonData.objectScriptPath)
        end
    end
end


local function requestObjectsFromCell(cell)
    for objType, _ in pairs(supportedObjectTypes) do
        for _, obj in pairs(cell:getAll(objType)) do
            sendEventToPlayers("advWMap_tracking:tempObjectRequest", obj)
        end
    end
end


---@param region AdvancedWorldMap.MapWidget.Region
local function getObjectsFromRegion(region)
    for x = math.ceil(region.left / 8192), math.ceil(region.right / 8192) do
        for y = math.ceil(region.bottom / 8192), math.ceil(region.top / 8192) do
            local cellId = commonData.getCellIdByGrid(x, y)
            if not availableCellIdsMap[cellId] then goto continue end
            local cell = world.getExteriorCell(x, y)
            if not cell then goto continue end

            requestObjectsFromCell(cell)

            ::continue::
        end
    end
end


local function getObjectsFromCell(cellId)
    if not availableCellIdsMap[cellId] then return end
    local cell = world.getCellById(cellId)
    if not cell then return end

    requestObjectsFromCell(cell)
end


return {
    engineHandlers = {
        onObjectActive = async:callback(onObjectActiveGlobal),
        onItemActive = async:callback(onObjectActiveGlobal),
    },
    eventHandlers = {
        ["advWMap_tracking:objectInactive"] = objectInactive,
        ["advWMap_tracking:objectActive"] = onObjectActive,
        ["advWMap_tracking:checkObjectStatus"] = checkObjectStatus,
        ["advWMap_tracking:requestObjects"] = function (data)
            if data.cellId then
                getObjectsFromCell(data.cellId)
            elseif data.region then
                getObjectsFromRegion(data.region)
            end
        end,
    },
}