local self = require('openmw.self')
local core = require('openmw.core')

return {
    engineHandlers = {
        onInactive = function()
            print("Actor " .. self.recordId .. " has become inactive.")
            core.sendGlobalEvent('MarjoStartup')
        end
    }
}