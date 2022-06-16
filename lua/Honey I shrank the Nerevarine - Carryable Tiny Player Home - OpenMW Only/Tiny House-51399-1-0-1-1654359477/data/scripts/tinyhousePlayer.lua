local ui = require('openmw.ui')
local util = require('openmw.util')
local cam = require('openmw.interfaces').Camera
local core = require('openmw.core')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local types = require('openmw.types')

local Actor = require('openmw.types').Actor
local function onConsoleCommand(mode, command, selectedObject)
    if  command == "luaadd" then
		Actor.inventory(selectedObject):addNew("Akatosh's Ring",3)
   elseif  command == "luarem" then
		Actor.inventory(selectedObject):remove("Akatosh's Ring",3)
   elseif  command == "luatran" then
		for i, object in ipairs(Actor.inventory(self):getAll()) do

		object:moveInto(Actor.inventory(selectedObject))
		Actor.inventory(self):remove(object)
		end
	elseif command == "luascale" then
 -- ui.showMessage("This is : " .. tostring(selectedObject:setScale(0.5)))
	
	end
end
local function sendMessage(eventData)

	--ui.showMessage(eventData)
    

end
local function recieveActivators(eventdata)
 for i, object in ipairs(nearby.items) do
        if ( object.recordId == "zck_histn_misc_houseunified" ) then
 -- ui.showMessage("This is : " .. tostring(object.position.x))
  core.sendGlobalEvent('eteleportin',object)
	--core.sendGlobalEvent('eteleportOut',object)
        end
    end
end
local function returnActivators ( eventdata)
 for i, object in ipairs(nearby.activators) do
        if ( string.find(object.recordId,"zck_histn_act_")  ) then
	core.sendGlobalEvent('eteleportOut',object)
        end
    end
	 for i, object in ipairs(nearby.containers) do
        if ( string.find(object.recordId,"zck_histn_con_" )) then
	core.sendGlobalEvent('eteleportOut',object)
        end
    end
end
local function onUpdate(dt)
--cam.setBaseThirdPersonDistance(0.1)
 -- cam.disableThirdPersonOffsetControl()
  --cam.disableHeadBobbing()
  --cam.enableStandingPreview()
 -- self.inventory = nil
 -- for i, v in pairs(  self.inventory) do

  --ui.showMessage(i.recordId)
--end
end

return {
    
    eventHandlers = {
        sendMessage = sendMessage,
		returnActivators = returnActivators,
		recieveActivators = recieveActivators,
    },
	
	engineHandlers = {
        onConsoleCommand = onConsoleCommand,
        onUpdate = onUpdate,
    }
}