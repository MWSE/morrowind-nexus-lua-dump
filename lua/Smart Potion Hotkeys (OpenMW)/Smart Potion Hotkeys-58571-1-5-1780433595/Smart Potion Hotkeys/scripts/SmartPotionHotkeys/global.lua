-- Smart Potion Hotkeys - Global Script
-- Retains a small compatibility event for external callers. The player script
-- now dispatches OpenMW's standard UseItem event directly when drinking potions.

local core = require('openmw.core')
local types = require('openmw.types')

local function getValidPotionAndActor(data)
    local item = data and (data.object or data.potion)
    local actor = data and data.actor

    if not item or not item:isValid() then return nil, nil end
    if not actor or not actor:isValid() then return nil, nil end
    if (item.count or 1) < 1 then return nil, nil end
    if not types.Potion.objectIsInstance(item) then return nil, nil end
    if item.parentContainer ~= actor then return nil, nil end

    return item, actor
end

local function onSmartPotionUse(data)
    local item, actor = getValidPotionAndActor(data)
    if not item then return end

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
