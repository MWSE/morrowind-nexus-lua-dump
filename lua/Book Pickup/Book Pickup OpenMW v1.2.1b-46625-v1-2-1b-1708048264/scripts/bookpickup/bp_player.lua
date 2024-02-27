local core = require("openmw.core")
local input = require("openmw.input")

local SettingsBookPickup = require("scripts.bookpickup.bp_settings")

local ambient = require('openmw.ambient')
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
local function playAmbientNoise(name)
    ambient.playSound(name)
end
return {
    engineHandlers = { onKeyPress = onKeyPress, onKeyRelease = onKeyRelease },
    eventHandlers = { playAmbientNoise = playAmbientNoise }
}
