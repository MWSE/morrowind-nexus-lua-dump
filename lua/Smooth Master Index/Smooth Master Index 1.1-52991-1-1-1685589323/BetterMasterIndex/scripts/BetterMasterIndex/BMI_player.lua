local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local async = require("openmw.async")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")


local wasSneaking = false
local function onUpdate(dt)
    if (core.API_REVISION < 38) then
        ui.showMessage("Better Master Index requires a newer version of OpenMW. Please update.")
    end
    local isSneaking = self.controls.sneak
    if (isSneaking ~= wasSneaking) then
        core.sendGlobalEvent("BMISneakUpdate", isSneaking)
    end
    wasSneaking = isSneaking
end
local function BMIShowMessage(message)
ui.showMessage(message)

end
return {
    engineHandlers = { onUpdate = onUpdate },
    eventHandlers = { BMIShowMessage = BMIShowMessage }
}
