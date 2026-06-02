local I = require("openmw.interfaces")
local input = require("openmw.input")
local modInfo = require("scripts/sitDownPlease/world/modRegistry")

pcall(function()
    input.registerTrigger {
        key = "SitDownPleaseOpenCalibrationMenu",
        name = "Open Sit Down Please Calibration Menu",
        l10n = modInfo.L10N,
    }
end)

I.Settings.registerPage {
    key = modInfo.SETTINGS_PAGE,
    l10n = modInfo.L10N,
    name = "page_name",
    description = "page_description",
}
