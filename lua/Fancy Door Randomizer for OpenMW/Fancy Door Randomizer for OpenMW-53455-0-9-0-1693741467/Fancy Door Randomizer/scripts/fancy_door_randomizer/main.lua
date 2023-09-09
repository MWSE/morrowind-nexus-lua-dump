local doorLib = require("scripts.fancy_door_randomizer.door")
local storage = require("scripts.fancy_door_randomizer.storage")

local Door = require('openmw.types').Door
local Lockable = require('openmw.types').Lockable
local Activation = require('openmw.interfaces').Activation
local async = require('openmw.async')
local core = require('openmw.core')
local world = require('openmw.world')

local config = require("scripts.fancy_door_randomizer.config")
local configData = config.data

local doorsData = nil

local function onInit()
    math.randomseed(os.time())
    doorLib.init(storage)
    doorsData = doorLib.fingDoors(storage, config)
end

local function onSave()
    return {storage = storage.data, config = config.data}
end

local function updateSettings()
    async:newUnsavableSimulationTimer(0.5, function()
        if #world.players > 0 then
            world.players[1]:sendEvent("fdrbd_updateSettings", {configData = config.data})
        else
            updateSettings()
        end
    end)
end

local function onLoad(data)
    storage.data = data.storage or {}
    config.loadData(data.config or {})
    updateSettings()
    doorLib.init(storage)
    doorsData = doorLib.fingDoors(storage, config)
end

local function onNewGame()
    updateSettings()
end

local function chooseDoorByConfigData(doorData, doorConfig)
    local table = {}
    local number = 0
    for name, val in pairs(doorConfig) do
        if val then
            local varName = name:sub(3)
            if doorData[varName] then
                number = number + #doorData[varName]
                table[varName] = number
            end
        end
    end
    if number > 0 then
        local rnd = math.random(1, number)
        for name, num in pairs(table) do
            if rnd <= num then
                return doorData[name][1 + num - rnd]
            end
        end
    end
end

local function chooseNewDoor(door)
    local doorConfig = config.getDoorConfigTable(doorLib.isExterior(door.cell), doorLib.isExterior(Door.destCell(door)))
    if not doorConfig then return end
    if configData.mode == config.modes[1] then
        ---@type fdr.doorDB|nil
        local db = doorLib.findDoorsInRange(door.cell, configData.radius, storage, config)
        if not db then return end
        return chooseDoorByConfigData(db, doorConfig)
    elseif configData.mode == config.modes[2] then
        local newDoor
        for i = 1, 20 do
            local dr = chooseDoorByConfigData(doorsData, doorConfig)
            if not dr then goto continue end
            local bdr = doorLib.getBackDoor(dr)
            if not bdr then goto continue end
            if config.data.allowLockedExit or not Lockable.isLocked(dr) then
                newDoor = dr
                break
            end
            ::continue::
        end
        return newDoor
    end
end

local function changeDoorDestinationAndTeleport(old, new, actor)
    local pos = Door.destPosition(new)
    local rot = Door.destRotation(new)
    local cell = Door.destCell(new)
    storage.setData(old.id, pos, rot, cell)
    if configData.swap then
        storage.setData(new.id, Door.destPosition(old), Door.destRotation(old), Door.destCell(old))
    end
    if configData.exitDoor then
        local toMainDoor = doorLib.getBackDoor(old)
        local targetDoor = doorLib.getBackDoor(new)
        if config.data.unlockLockedExit then
            async:newUnsavableSimulationTimer(2, function()
                Lockable.unlock(targetDoor)
            end)
        end
        if config.data.untrapExit then
            async:newUnsavableSimulationTimer(2, function()
                Lockable.setTrapSpell(targetDoor, nil)
            end)
        end
        storage.setData(targetDoor.id, Door.destPosition(toMainDoor), Door.destRotation(toMainDoor), Door.destCell(toMainDoor))
        if configData.swap then
            storage.setData(toMainDoor.id, Door.destPosition(targetDoor), Door.destRotation(targetDoor), Door.destCell(targetDoor))
        end
    end
    actor:teleport(cell, pos, {onGround = true, rotation = rot})
end

Activation.addHandlerForType(Door,
    async:callback(function(door, actor)
        if configData.enabled and Door.isTeleport(door) and not Lockable.isLocked(door) and not Lockable.getTrapSpell(door) and
                not doorLib.forbiddenDoorIds[door.recordId] then
            local storageData = storage.getData(door.id)
            local timeExpired = storageData and storageData.timestamp + configData.interval * 3600 < world.getGameTime()
            if storageData and not timeExpired then
                actor:teleport(storageData.cell, storageData.pos, {onGround = true, rotation = storageData.rotAngle})
                -- return false
            else
                local success = configData.chance * 0.01 >= math.random()
                if success then
                    local newDestinationDoor = chooseNewDoor(door)
                    if not newDestinationDoor then return end
                    changeDoorDestinationAndTeleport(door, newDestinationDoor, actor)
                    -- return false
                elseif configData.saveOnFailure then
                    storage.setData(door.id, Door.destPosition(door), Door.destRotation(door), Door.destCell(door))
                    if configData.exitDoor then
                        local toMainDoor = doorLib.getBackDoor(door)
                        storage.setData(toMainDoor.id, Door.destPosition(toMainDoor), Door.destRotation(toMainDoor), Door.destCell(toMainDoor))
                    end
                end
            end
        end
    end)
)

local function loadConfigData(data)
    config.loadData(data)
end

return {
    engineHandlers = {
        onInit = async:callback(onInit),
        onSave = async:callback(onSave),
        onLoad = async:callback(onLoad),
        onNewGame = async:callback(onNewGame),
    },
    eventHandlers = {
        fdrbd_loadConfigData = async:callback(loadConfigData),
    },
}