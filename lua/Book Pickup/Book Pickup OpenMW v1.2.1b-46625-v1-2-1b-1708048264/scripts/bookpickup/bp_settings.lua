local core = require("openmw.core")
local I = require("openmw.interfaces")
local async = require("openmw.async")
local storage = require("openmw.storage")
if (core.API_REVISION < 54) then
    I.Settings.registerPage {
        key = "BookPickup",
        l10n = "BookPickup",
        name = "core.modName",
        description = "Book pickup is enabled, but your engine version is too old. Please download a new version of OpenMW Develpment or 0.49+.(Newer than Feb 15, 2024)"
    }
    error("Newer version of OpenMW is required")
end
I.Settings.registerPage {
    key = "BookPickup",
    l10n = "BookPickup",
    name = "core.modName",
    description = "core.versionString"
}
local SettingsBookPickup = storage.playerSection("SettingsBookPickup")


return SettingsBookPickup