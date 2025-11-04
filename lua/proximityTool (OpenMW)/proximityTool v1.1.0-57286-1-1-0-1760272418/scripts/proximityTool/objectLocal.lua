local self = require('openmw.self')
local core = require('openmw.core')
local Item = require("openmw.types").Item


local function onInactive()
    core.sendGlobalEvent("proximityTool:objectInactive", {self, self.id, self.recordId})
end

local function onActivated()
    if self:isValid() then
        if Item.objectIsInstance(self) then
            core.sendGlobalEvent("proximityTool:objectInactive", {self, self.id, self.recordId})
        else
            core.sendGlobalEvent("proximityTool:checkObjectStatus", {self, self.id, self.recordId})
        end
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