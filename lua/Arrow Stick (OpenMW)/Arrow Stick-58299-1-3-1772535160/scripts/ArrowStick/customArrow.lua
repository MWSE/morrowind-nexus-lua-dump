local core = require("openmw.core")
local self = require("openmw.self")

local function onInactive()
    core.sendGlobalEvent("arrowInactive", self.id)
end

return {
    engineHandlers = {
        onInactive = onInactive
    }
}