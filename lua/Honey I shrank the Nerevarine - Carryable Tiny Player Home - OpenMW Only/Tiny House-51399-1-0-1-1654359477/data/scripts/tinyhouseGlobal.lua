local util = require('openmw.util')
local world = require('openmw.world')
local core = require('openmw.core')

local mainhouse = nil
local function eteleportin(eventData)

targetob = eventData
cell = world.getCellByName("AA_TinyHouseStorage")
allitems = cell:getAll()
--for i, v in pairs(cell:getAll()) do
tcell = targetob.cell.name
for i, object in ipairs(allitems) do

object:teleport(tcell,targetob.position,targetob.rotation)
end
--if ( mainhouse == nil ) then

--end

--end

end

local function eteleportOut(eventData)

targetob = eventData

--end
targetob:teleport("AA_TinyHouseStorage",targetob.position,targetob.rotation)

end
local function eteleportOut2(eventData)

targetob = eventData

--end
targetob:teleport("ToddTest",targetob.position,targetob.rotation)

end
local function PlayerMessage(eventData)
 for i, actor in ipairs(world.activeActors) do
       if ( actor.recordId == "player") then
            actor:sendEvent('returnActivators', eventData)
        end
    end
end
local function PlayerMessageReal(eventData)
 for i, actor in ipairs(world.activeActors) do
       if ( actor.recordId == "player") then
       --     actor:sendEvent('sendMessage', eventData)
        end
    end
end
return {
    eventHandlers = {
        eteleportin = eteleportin,
		eteleportOut = eteleportOut,
		eteleportOut2 = eteleportOut2,
		PlayerMessage = PlayerMessage,
		PlayerMessageReal = PlayerMessageReal
    }
}