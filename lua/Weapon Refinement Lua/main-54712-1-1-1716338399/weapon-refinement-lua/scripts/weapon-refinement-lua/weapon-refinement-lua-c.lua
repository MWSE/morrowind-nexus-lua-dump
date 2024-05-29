local self = require('openmw.self')
local core = require("openmw.core")

local function EnableActivator(data)
    core.sendGlobalEvent("GiveAnvilActivationInterface",{
        object = self.object
    })
end


return {
    engineHandlers = {
        onActive = EnableActivator
    }
}