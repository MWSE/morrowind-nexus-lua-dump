local util = require('openmw.util')
local core = require('openmw.core')
local self = require('openmw.self')

local nearby = require('openmw.nearby')
local function onActive(dt)
if ( self.recordId == "zck_histn_misc_houseunified") then

 for i, actor in ipairs(nearby.actors) do
        if actor.recordId == "player" then
            actor:sendEvent('recieveActivators', self)
            actor:sendEvent('sendMessage', "active " .. self.recordId)
        end
    end
end
	
end
 function onActivated( actor)

--if ( self.recordId == "zck_histn_misc_houseUnified") then

 for i, actor in ipairs(nearby.actors) do
        local dist = (self.position - actor.position):length()
        if dist < 5000 then
       if ( actor.recordId == "player") then
            actor:sendEvent('sendMessage', self.recordId)
			end
        end
    end
--end
end
local function onInactive(dt)
if ( self.recordId == "zck_histn_misc_houseunified") then

	core.sendGlobalEvent('PlayerMessage',self.recordId)
end
end
return {
    engineHandlers = {
        onActive = onActive,
        onInactive = onInactive,
		onActivated = onActivated,
    }
}