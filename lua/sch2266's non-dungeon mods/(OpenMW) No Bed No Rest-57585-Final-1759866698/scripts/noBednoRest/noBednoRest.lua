local nearby = require("openmw.nearby")
local I = require("openmw.interfaces")
local self = require("openmw.self")
local storage = require("openmw.storage")
local ui = require('openmw.ui')

I.Settings.registerPage {
    key = "NoBed",
    l10n = "NoBed",
    name = "No Bed, No Rest",
    description = "Disables resting without a bed."
}

I.Settings.registerGroup {
    key = "SettingsNoBed",
    page = "NoBed",
    l10n = "NoBed",
    name = "No Bed, No Rest",
    description = "",
    permanentStorage = true,
    settings = {
        {
            key = "enableRestMod",
            renderer = "checkbox",
            name = "Enable Mod",
            description =
            "If enabled, the mod will disable sleeping away from a bed.",
            default = true
        }

    }
}

local modSettings = storage.playerSection("SettingsNoBed")
local function distanceBetweenPos(vector1, vector2)
    --Quick way to find out the distance between two vectors.
    --Very similar to getdistance in mwscript
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function allowedToSleep()
    if not modSettings:get("enableRestMod") then
        return true
    end
    for index, acti in ipairs(nearby.activators) do
        local record = acti.type.record(acti)
        local scr = record.mwscript
        local dist = distanceBetweenPos(self.position, acti.position)
        local isBed = record.name == "Bed" or scr == "bed_standard"
        if isBed and dist < 250 then
            return true
        end
    end
	if self.cell:hasTag("NoSleep") then
        return true
		
    end


    return false
end
return {
    eventHandlers = {

        UiModeChanged = function(data)
            if data.newMode == "Rest" then
                if not allowedToSleep() then
                    I.UI.setMode()
                end
            end
        end
    }
}