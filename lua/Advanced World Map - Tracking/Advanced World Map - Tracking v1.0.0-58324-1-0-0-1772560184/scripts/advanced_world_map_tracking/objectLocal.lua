local self = require('openmw.self')
local core = require('openmw.core')
local Item = require("openmw.types").Item


local function onInactive()
    core.sendGlobalEvent("advWMap_tracking:objectInactive", {self, self.id, self.recordId, not self.cell.isExterior and self.cell.id or nil})
end

local function onActivated()
    local object = self.object
    if object:isValid() then
        if Item.objectIsInstance(self) then
            core.sendGlobalEvent("advWMap_tracking:objectInactive",
                {object, object.id, object.recordId, not object.cell.isExterior and object.cell.id or nil})
        else
            core.sendGlobalEvent("advWMap_tracking:checkObjectStatus",
                {object, object.id, object.recordId, not object.cell.isExterior and object.cell.id or nil})
        end
    end
end

local function onActive()
    core.sendGlobalEvent("advWMap_tracking:objectActive", self.object)
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