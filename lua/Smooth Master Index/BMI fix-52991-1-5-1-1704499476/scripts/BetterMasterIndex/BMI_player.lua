local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local async = require("openmw.async")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local ambient = require('openmw.ambient')
local debug = require('openmw.debug')
if (core.API_REVISION < 44) then
    I.Settings.registerPage {
        key = "SettingsBMI",
        l10n = "SettingsBMI",
        name = "Smooth Master Index",
        description = "Smooth Master Index requires a newer version of OpenMW. Please update."
    }
    error("Smooth Master Index requires a newer version of OpenMW. Please update.")
end
I.Settings.registerPage {
    key = "SettingsBMI",
    l10n = "SettingsBMI",
    name = "Smooth Master Index",
}

I.Settings.registerGroup {
    key = "SettingsBMI",
    page = "SettingsBMI",
    l10n = "AshlanderArchitect",
    name = "Smooth Master Index",
    description = "Corporeal Carryable Containers",
    permanentStorage = false,
    settings = {
        {
            key = "rerunPropylonSwap",
            renderer = "checkbox",
            name = "Rerun Propylon Swap",
            description =
            "If you togle this option, the swap in Rotheran and Falensarano will be re-ran in case it got out of sync.",

            default = true
        },
    }
}
local playerSettings = storage.playerSection("SettingsBMI")
playerSettings:subscribe(async:callback(function(section, key)
    if key then
        if (key == "rerunPropylonSwap") then
            core.sendGlobalEvent("swapBroken", true)
        end
    end
end))
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
local function onLoad()
    core.sendGlobalEvent("setGodModeState", debug.isGodMode())
end
return {
    engineHandlers = {
        onUpdate = onUpdate,
        onLoad = onLoad,

        onConsoleCommand = function()
            async:newUnsavableSimulationTimer(0.1, function()
                onLoad()
            end)
        end,
    },
    eventHandlers = { BMIShowMessage = BMIShowMessage, BMIPlaySound = BMIPlaySound }
}
