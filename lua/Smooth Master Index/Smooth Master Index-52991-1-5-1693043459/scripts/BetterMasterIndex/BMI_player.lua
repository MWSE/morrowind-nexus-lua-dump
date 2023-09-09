local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local async = require("openmw.async")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local ambient = require('openmw.ambient')
if (core.API_REVISION < 44) then

I.Settings.registerPage {
    key = "SettingsBMI",
    l10n = "SettingsBMI",
    name = "Smooth Master Index",
    description = "Smooth Master Index requires a newer version of OpenMW. Please update."
}
    error("Smooth Master Index requires a newer version of OpenMW. Please update.")
end

local wasSneaking = false
local function onUpdate(dt)
    
    local isSneaking = self.controls.sneak
    if (isSneaking ~= wasSneaking) then
        core.sendGlobalEvent("BMISneakUpdate", isSneaking)
    end
    wasSneaking = isSneaking
end
local function BMIShowMessage(message)
ui.showMessage(message)

end
local function BMIPlaySound(soundID)
    ambient.playSound(soundID)
end
return {
    engineHandlers = { onUpdate = onUpdate },
    eventHandlers = { BMIShowMessage = BMIShowMessage,BMIPlaySound = BMIPlaySound }
}
