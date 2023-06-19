local core = require("openmw.core")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local async = require("openmw.async")
local storage = require("openmw.storage")

I.Settings.registerPage {
    key = "BookPickup",
    l10n = "BookPickup",
    name = "core.modName",
    description = "core.versionString"
}
I.Settings.registerGroup {
    key = "SettingsBookPickup",
    page = "BookPickup",
    l10n = "BookPickup",
    name = 'core.modName',
    description = 'mcm.credits',
    permanentStorage = true,
    settings = {
        {
            key = "PickupByDefault",
            renderer = "checkbox",
            name = "mcm.pickupByDefault.label",
            description =
            "mcm.pickupByDefault.description",
            default = "true"
        }, --This is the only possible setting at the moment, we can't allow stealing an item since moving it via lua would make it free.
    }
}

local SettingsBookPickup = storage.playerSection("SettingsBookPickup")

SettingsBookPickup:subscribe(async:callback(function(section, key)
    if key then
        if (key == "PickupByDefault") then
            core.sendGlobalEvent("BookPickupUpdateSetting", SettingsBookPickup:get("PickupByDefault"))
        end
    end
end))
local function onKeyPress(key)
    if (key.code == input.KEY.LeftShift or key.code == input.KEY.RightShift) then
        core.sendGlobalEvent("BookPickupShiftUpdate", true)
    end
end
local function onKeyRelease(key)
    if (key.code == input.KEY.LeftShift or key.code == input.KEY.RightShift) then
        local keyPressed = not SettingsBookPickup:get("PickupByDefault")

        core.sendGlobalEvent("BookPickupShiftUpdate", false)
    end
end
return {
    engineHandlers = { onKeyPress = onKeyPress, onKeyRelease = onKeyRelease },
}
