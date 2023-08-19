local core = require('openmw.core')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local storage = require("openmw.storage")



local function onActivated(actor)
     print("onActivate")
     --Pretty sure this isn't even used since the door activator is nameless
     if (self.recordId == "mundis_3_exitdoor") then
          core.sendGlobalEvent("exitMundisFunc", { 2, actor })
     end
end


return {
     engineHandlers = {
          onActivated = onActivated
     },
     eventHandlers = {
          --  onMessageSent = onMessageSent
     }
}
