local core = require("openmw.core")
local I = require("openmw.interfaces")
local async = require("openmw.async")
local storage = require("openmw.storage")
if (core.API_REVISION < 43) then
    I.Settings.registerPage {
        key = "EnhancedInns",
        l10n = "EnhancedInns",
        name = "Enhanced Inns",
        description = "Enhanced Inns is enabled, but your engine version is too old. Please download a new version of OpenMW Develppment or 0.49+.(Newer than Jan 20, 2024)"
    }
    error("Newer version of OpenMW is required")
end
I.Settings.registerPage {
    key = "EnhancedInns",
    l10n = "EnhancedInns",
    name = "Enhanced Inns",
    description = "Replaced the vanilla Inn mechanic with a dynamic, more useful mechanic."
}

local SettingsEnhancedInns = storage.playerSection("SettingsEnhancedInns")

SettingsEnhancedInns:subscribe(async:callback(function(section, key)
    if key then
        core.sendGlobalEvent("SettingsEnhancedInnsUpdate", {value = SettingsEnhancedInns:get(key), key = key})
        
    end
end))