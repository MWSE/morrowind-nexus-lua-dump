local util = require("openmw.util")
local core = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")
local nearby = require("openmw.nearby")
local ui = require("openmw.ui")

local function ZHAC_ShowMessage(message)
ui.showMessage(message)

end
local function onActive()
core.sendGlobalEvent("sendToMWScript")
end
return {
    eventHandlers = {
        ZHAC_ShowMessage = ZHAC_ShowMessage,
    },
engineHandlers = {onActive = onActive}
}
