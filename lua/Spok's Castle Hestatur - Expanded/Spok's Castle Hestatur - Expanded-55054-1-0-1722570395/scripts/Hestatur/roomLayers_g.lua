local world = require("openmw.world")
local types = require("openmw.types")
local async = require("openmw.async")
local layers = require("scripts.Hestatur.roomLayers_data")
local I = require("openmw.interfaces")
local layerState = {}
local function checkSuffixAndPrefix(suffix, mainString)
    -- Check if the suffix ends with '*'
    if string.sub(suffix, -1) == '*' then
        -- Remove the '*' from the suffix for comparison
        suffix = string.sub(suffix, 1, -2)
    end

    -- Check if the mainString starts with the modified suffix
    if string.sub(mainString, 1, string.len(suffix)) == suffix then
        return true
    else
        return false
    end
end
local function setMasterLayerState(data)
    layerState = data
end
local function objectShouldBeShown(obj)
    local state = true
    if not layers[obj.cell.id] then
        return true
    end
    for layerId, layer in pairs(layers[obj.cell.id]) do
        if layer.objects then
            local layerState = layerState[obj.cell.id][layerId]
            local lightId = I.Hestatur_Light.getOriginalRecordId(obj.recordId)
            for index, objId in ipairs(layer.objects) do
                if obj.recordId == objId:lower() or (lightId and lightId == objId:lower()) then
                    state = layerState
                elseif (checkSuffixAndPrefix(objId, obj.recordId:lower()) or (lightId and checkSuffixAndPrefix(objId, lightId) ) ) then
                    state = layerState
            
                end
            end
        end
    end
    return state
end
local function setLayerState(cell, layerId, state, layerStateData)
    --print(layerId)
    if not layers[cell.id] or not layers[cell.id][layerId].objects then
        return
    end
    local parentLayer = layers[cell.id][layerId].dependsOn
    if layerStateData and parentLayer and state == true then
        if layerStateData[parentLayer] == true then
        else
            setLayerState(cell, parentLayer, true, layerStateData)
        end
    end
    for index, objId in ipairs(layers[cell.id][layerId].objects) do
        for index, value in ipairs(cell:getAll()) do
            if value.recordId == objId:lower() then
                value.enabled = state
            elseif (checkSuffixAndPrefix(objId, value.recordId:lower())) then
                value.enabled = state
            end
        end
    end
    if state == false then
        for flayerId, layer in pairs(layers[cell.id]) do
            if layer.dependsOn == layerId then
                setLayerState(cell, flayerId, false, layerStateData)
            end
        end
    end
end
local function hideLayersInCell(cellId)
    local data = layers[cellId]
    if not data then
        return
    end
    local cell = world.getCellById(cellId)
    for layerId, layer in pairs(data) do
        setLayerState(cell, layerId, false)
    end
end
local function setLayerInCellToDefault(cellId)
    local data = layers[cellId]
    if not data then
        return
    end
    local cell = world.getCellById(cellId)
    layerState[cell.id] = {}
    for layerId, layer in pairs(data) do
        local state = layer.price == nil
        layerState[cell.id][layerId] = state
        setLayerState(cell, layerId, state)
    end
    world.players[1]:sendEvent("updateLayerState",layerState)
end
local function reEnableAllLayers(cellId)
    local data = layers[cellId]
    if not data then
        return
    end
    local cell = world.getCellById(cellId)
    layerState[cell.id] = {}
    for layerId, layer in pairs(data) do
        local state = true
        layerState[cell.id][layerId] = state
        setLayerState(cell, layerId, state)
    end
    world.players[1]:sendEvent("updateLayerState",layerState)
end

local function hideLightsInCell(cellId)
    local cell = world.getCellById(cellId)
    for index, value in ipairs(cell:getAll(types.Light)) do
        if value.contentFile then
            value.enabled = false
        end
    end
end
local function removeGoldCount(count)
    local player = world.players[1]
    types.Actor.inventory(player):find("gold_001"):remove(count)
end
local function getObjInCell(cell, id)
    for index, value in ipairs(cell:getAll()) do
        if value.recordId == id:lower() then
            return value
        end
    end
end
return {
    interfaceName = "roomLayers",
    interface = {
        objectShouldBeShown = objectShouldBeShown,
    },
    eventHandlers = {
        hideLayersInCell = hideLayersInCell,
        hideLightsInCell = hideLightsInCell,
        removeGoldCount = removeGoldCount,
        setMasterLayerState = setMasterLayerState,
        setLayerState = function(data)
            setLayerState(world.getCellById(data.cellId), data.layerId, data.state, data.layerStateData)
        end,
        reEnableAllLayers = reEnableAllLayers,
        setLayerInCellToDefault = setLayerInCellToDefault,
    },
    engineHandlers = {
        onSave = function()
            return { layerState = layerState }
        end,
        onActivate = function(obj, act)
            if obj.recordId == "zhac_hestat_cube_activat" then
                act:sendEvent("showLayerConfig")
            elseif obj.recordId == "zhac_hidden_button" then
                local state = world.mwscript.getGlobalVariables(world.players[1]).zhac_hestatur_hdoor_state
                local door = getObjInCell(act.cell, "In_impsmall_d_hidden_01_z")
                local trapDoor = getObjInCell(act.cell, "zhac_secret_trapdoor")
                if state == 1 then
                    local rot = math.floor(door.rotation:getAnglesZYX())
                    if rot == -4 then
                        world.mwscript.getGlobalVariables(world.players[1]).zhac_hestatur_hdoor_state = 0
                    else
                        world._runStandardActivationAction(door, world.players[1], true)
                        --close the door again
                        async:newUnsavableSimulationTimer(3, function()
                            if math.floor(door.rotation:getAnglesZYX()) == -4 then
                                world.mwscript.getGlobalVariables(world.players[1]).zhac_hestatur_hdoor_state = 0
                            end
                        end)
                    end
                else
                    local rot = math.floor(door.rotation:getAnglesZYX())
                    if rot ~= -4 then
                        world.mwscript.getGlobalVariables(world.players[1]).zhac_hestatur_hdoor_state = 1
                    else
                        world.mwscript.getGlobalVariables(world.players[1]).zhac_hestatur_hdoor_state = 1
                        world._runStandardActivationAction(door, world.players[1], true)
                        --open the door again
                    end
                end
            end
        end,
        onLoad = function(data)
            if data then
                layerState = data.layerState
            end
        end
    }
}
