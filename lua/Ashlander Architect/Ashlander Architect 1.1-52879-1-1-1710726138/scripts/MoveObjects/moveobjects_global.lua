local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local acti = require("openmw.interfaces").Activation
local settlementList = {}
local time = require('openmw_aux.time')
local myModData = storage.globalSection("AASettlements")
local treeData = {}
local config = require("scripts.MoveObjects.config")
if not config.isUpdated then
    error("Your OpenMW version is too old!" )
end

local function getTData()
    return treeData
end
local function dropOne(object)
    if (object.count ~= nil and object.count > 1) then
        object:remove(1)
        local newItem = world.createObject(object.recordId)
        newItem:teleport(object.cell, object.position, object.rotation)
    else
        print("Can't split")
    end
end
local function cleanBreezehome(cell)
for index, value in ipairs(cell:getAll()) do
    
end

end
local function addTree(object)
    for index, value in ipairs(treeData) do
        if (value.id == object.id) then
            return --already have this tree
        end
    end
    local growTime = core.getGameTime() + time.day + math.random(0, time.day)
    local data = {
        id = object.id,
        plantTime = core.getGameTime(),
        growTime = growTime,
        cellName = object.cell.name,
        cellx = object.cell.gridX,
        celly = object.cell.gridY
    }
    table.insert(treeData, data)
end
local function removeTree(object)
    for index, value in ipairs(treeData) do
        if (value.id == object.id) then
            core.sendGlobalEvent("replaceOb_AA", { newObId = "zhac_aa_treedone_gl", oldObject = object })
            table.remove(treeData, index)
            return
        end
    end
end
local player = nil
local function onUpdate()
    if (player == nil) then
        player = I.ZackUtilsAA.getPlayer()
    end

    if (player == nil) then
        return
    end
    for index, data in ipairs(treeData) do
        if (data.cellName == player.cell.name) then
            if (core.getGameTime() > data.growTime) then
                for index, object in ipairs(player.cell:getAll(types.Activator)) do
                    if (object.id == data.id) then
                        removeTree(object)
                    end
                end
            end
        end
    end
end
local function onSave()
    return { treeData = treeData }
end
local function onLoad(data)
    treeData = data.treeData
end
return {
    interfaceName = "AA_Global",
    interface = {
        version = 1,
        getTData = getTData
    },
    eventHandlers = {
        addTree = addTree,
        dropOne = dropOne,
    },
    engineHandlers = { onInit = onInit, onSave = onSave, onLoad = onLoad, onUpdate = onUpdate, }
}
