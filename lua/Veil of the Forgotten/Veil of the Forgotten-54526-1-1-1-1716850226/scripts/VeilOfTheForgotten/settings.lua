local I = require('openmw.interfaces')

local storage = require("openmw.storage")
local settings = storage.globalSection("SettingsVOTF")
local worldLoaded, world = pcall(require, "openmw.world")

if worldLoaded then
    I.Settings.registerGroup {
        key = "SettingsVOTF",
        page = "SettingsVOTF",
        l10n = "SettingsVOTF",
        name = "Main Settings",
        permanentStorage = true,

        settings = {
            {
                key = "healthCaptureThreshold",
                renderer = "number",
                name = "Health Capture threshold",
                description = "The percentage of health an actor must have expended to be captured. If it is at 10 percent, you'll have to have them under 10 percent to capture them initially.",
                default = 50,
                max = 100,
                min = 0
            },
            {
                key = "dropAtFeet",
                renderer = "checkbox",
                description =
                "If enabled, Temporal Globes will drop at the feet of the captured, if not, they will be added to your inventory.",
                name = "Drop at Feet",
                default = false,
            },
        },

    }
end

return {
    getHealthCaptureThreshold = function()
        return settings:get("healthCaptureThreshold") or 50
    end,
    getDropAtFeet = function()
        return settings:get("dropAtFeet") or false
    end,
}
