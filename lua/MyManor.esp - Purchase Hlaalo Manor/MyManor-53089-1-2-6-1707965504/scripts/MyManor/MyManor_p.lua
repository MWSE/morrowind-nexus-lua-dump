local core = require("openmw.core")
local types = require("openmw.types")
local async = require("openmw.async")
local storage = require("openmw.storage")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
if core.API_REVISION < 54 then
    I.Settings.registerPage {
        key = 'SettingsMyManor',
        l10n = 'MyManor',
        name = 'MyManor',
        description = 'This version of OpenMW is out of date. Update to the latest 0.49 or development release/build.',
    }
    error("This version of OpenMW has no lua quest support. Update to the latest 0.49 or development release/build.")
else
    I.Settings.registerPage {
        key = 'SettingsMyManor',
        l10n = 'MyManor',
        name = 'MyManor',
    }
    I.Settings.registerGroup {
        key = "SettingsMyManor",
        page = "SettingsMyManor",
        l10n = "SettingsMyManor",
        name = 'My Manor',
        description = '',
        permanentStorage = true,
        settings = {
            {
                key = "reCheckOwner",
                renderer = "checkbox",
                name = "Re check Hlaalo Manor Ownership",
                description =
                "Toggle this to re-clear the ownership on the manor.",
                default = true
            },
        }
    }
end
local settings = storage.playerSection("SettingsMyManor")
settings:subscribe(async:callback(function(section, key)
    if key then
        core.sendGlobalEvent("MManor_reRunOwnership")
        ui.showMessage("Reset Ownership")
    elseif not key then
        print("full reset")
    end
end))

local function onQuestUpdate(id,index)
if id == "jsmk_mm" then
    core.sendGlobalEvent("MManor_journalUpdated",index)
end
end
return {
	engineHandlers = {
		onQuestUpdate = onQuestUpdate
	}
}
