local core = require("openmw.core")
local self = require("openmw.self")

local function onInactive()
    core.sendGlobalEvent("ArrowStick_ArrowInactive", self.id)
end

return {
    engineHandlers = {
        onInactive = onInactive
    }
}