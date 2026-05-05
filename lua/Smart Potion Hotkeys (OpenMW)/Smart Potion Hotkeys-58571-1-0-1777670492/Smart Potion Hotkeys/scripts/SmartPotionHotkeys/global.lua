-- Smart Potion Hotkeys - Global Script
-- Handles potion consumption requests from the player script.
-- The player script uses the built-in UseItem event directly,
-- so this script serves as a validation intermediary and future hook point.

local core = require('openmw.core')
local types = require('openmw.types')

local MODNAME = "SmartPotionHotkeys"

local function onSmartPotionUse(data)
    local item = data.object
    local actor = data.actor

    if not item or not item:isValid() then return end
    if not actor or not actor:isValid() then return end
    if item.count < 1 then return end
    if not types.Potion.objectIsInstance(item) then return end
    if item.parentContainer ~= actor then return end

    core.sendGlobalEvent('UseItem', {
        object = item,
        actor = actor,
        force = true,
    })
end

return {
    engineHandlers = {},
    eventHandlers = {
        SmartPotionHotkeys_UsePotion = onSmartPotionUse,
    },
}
