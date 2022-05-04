local util = require('openmw.util')
local world = require('openmw.world')
local core = require('openmw.core')

local mainhouse = nil


local function teleportInBridge(eventData)

targetob = eventData[1]
posid = eventData[2]
cell = world.getCellByName("AA_SoulStorage")
allitems = cell:getAll()
--for i, v in pairs(cell:getAll()) do
tcell = targetob.cell.name
for i, object in ipairs(allitems) do
newpos = util.vector3(targetob.position.x,targetob.position.y,posid)

object:teleport(tcell,newpos,targetob.rotation)
end
end
return {
    eventHandlers = {
        teleportInBridge = teleportInBridge,
    }
}