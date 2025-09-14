local self = require('openmw.self')
local core = require('openmw.core')


local function onInactive()
    core.sendGlobalEvent("proximityTool:objectInactive", self)
end

local function onActivated()
    if self:isValid() and self.count == 0 then
        core.sendGlobalEvent("proximityTool:objectInactive", self)
    end
end

local function onActive()
    core.sendGlobalEvent("proximityTool:objectActive", self)
end


return {
    engineHandlers = {
        onInactive = onInactive,
        onActivated = onActivated,
        onActive = onActive,
    },
    eventHandlers = {

    },
}