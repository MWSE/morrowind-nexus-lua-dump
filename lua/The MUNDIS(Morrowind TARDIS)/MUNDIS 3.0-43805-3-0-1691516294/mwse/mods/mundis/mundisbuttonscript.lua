
local core = require('openmw.core')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local storage = require("openmw.storage")



local function onActivated(actor)
if string.sub(self.recordId, 1, string.len("mundis_switch_")) == "mundis_switch_" then
print(types.Activator.record(self.recordId).name)
core.sendGlobalEvent("checkButtonText",types.Activator.record(self.recordId).name)
end

end

local function sendSound(sound)
self.mwscript.toPlaySound  = sound

end
return {
     engineHandlers = {
          onActivated = onActivated
     },
     eventHandlers = {
          onMessageSent = onMessageSent,
		  sendSound = sendSound
     }
}