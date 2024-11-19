local common = require("mer.darkShard.common")
local logger = common.createLogger("Teleporter")

---@class DarkShard.Teleporter.Destination
---@field id string
---@field position tes3vector3
---@field orientation tes3vector3
---@field cell? string

---@class DarkShard.Teleporter
local Teleporter = {}

---@type table<string, DarkShard.Teleporter.Destination>
Teleporter.registeredDestinations = {}

---@param data DarkShard.Teleporter.Destination
function Teleporter.registerDestination(data)
    Teleporter.registeredDestinations[data.id] = {
        id = data.id,
        position = data.position,
        orientation = data.orientation
    }
end

---@param id string
---@return DarkShard.Teleporter.Destination
function Teleporter.getDestination(id)
    return Teleporter.registeredDestinations[id]
end

---@return DarkShard.Teleporter.Destination
function Teleporter.getRandomDestination()
    local keys = table.keys(Teleporter.registeredDestinations)
    local randomKey = keys[math.random(1, #keys)]
    return Teleporter.registeredDestinations[randomKey]
end

---@param e { destination?: DarkShard.Teleporter.Destination, callback?: function, forceAirborn?: boolean }
function Teleporter.teleportToDestination(e)
    local destination = e.destination or Teleporter.getRandomDestination()
    logger:debug("Teleporting to %s: %s", destination.id, destination.position)
    tes3.positionCell{
        reference = tes3.player,
        position = destination.position,
        orientation = destination.orientation,
        cell = destination.cell
    }
    if e.forceAirborn then
        --Hrnchamd magic to prevent the engine from repositioning the player the ground
        ---@diagnostic disable
        local mobilePlayerAddr = mwse.memory.convertFrom.tes3mobileObject(tes3.mobilePlayer)
        mwse.memory.writeByte{ address = mobilePlayerAddr + 0x230, byte = 0 }
        ---@diagnostic enable
    end

    if e.callback then
        logger:debug("Teleport finished, calling callback")
        e.callback()
    end
end

return Teleporter