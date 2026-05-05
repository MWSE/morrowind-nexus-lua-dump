local I = require("openmw.interfaces")
local async = require("openmw.async")
local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local storage = require("openmw.storage")

I.Settings.registerPage{
    key = "TrapHandling",
    l10n = "TrapHandling",
    name = "Spells of Morrowind: Trap Handling",
    description = "Configure Trap Handling Mod settings.",
}

I.Settings.registerGroup{
    key = "Settings_TrapHandling_Debug",
    page = "TrapHandling",
    l10n = "TrapHandling",
    name = "Debug Settings",
    permanentStorage = true,
    settings = {
        {
            key = "debugMode",
            default = false,
            renderer = "checkbox",
            name = "Enable Debug Logging",
            description = "If enabled, logs will be printed to the console.",
        },
    },
}

I.Settings.registerGroup{
    key = "Settings_TrapHandling_Gameplay",
    page = "TrapHandling",
    l10n = "TrapHandling",
    name = "Gameplay Settings",
    permanentStorage = true,
    settings = {
        {
            key = "trapMultiplier",
            default = 1.4,
            renderer = "number",
            name = "Trap Level Multiplier",
            description = "Default is 1.4. Ie. Trap of Level 10 will be Level 14. Setting it to 1.0 will make it Trap Cost vs Spell Magnitude",
        },
    },
}

local function updateSettings()
    local debugMode = storage.playerSection("Settings_TrapHandling_Debug"):get("debugMode")
    local trapMultiplier = storage.playerSection("Settings_TrapHandling_Gameplay"):get("trapMultiplier")
    core.sendGlobalEvent("DisarmTrap_UpdateSettings", { 
        debugMode = debugMode,
        trapMultiplier = trapMultiplier
    })
end

storage.playerSection("Settings_TrapHandling_Debug"):subscribe(async:callback(updateSettings))
storage.playerSection("Settings_TrapHandling_Gameplay"):subscribe(async:callback(updateSettings))

return {
    engineHandlers = {
        onActive = function()
            updateSettings()
        end
    }
}
