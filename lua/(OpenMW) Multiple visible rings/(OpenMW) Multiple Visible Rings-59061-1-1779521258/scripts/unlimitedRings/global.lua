local I     = require('openmw.interfaces')
local types = require('openmw.types')

local RING_TYPE = (types.Clothing.Type and types.Clothing.Type.Ring) or 8

local function isRing(item)
    if not types.Clothing.objectIsInstance(item) then return false end
    local ok, rec = pcall(types.Clothing.record, item)
    if not ok or not rec then return false end
    return rec.type == RING_TYPE
end

local function ringHandler(item, actor)
    if not isRing(item) then return end
    if not types.Player.objectIsInstance(actor) then return end
    actor:sendEvent('UnlimitedRings_PromptFinger', { itemId = item.recordId })
    return false
end

-- ─── Registration ─────────────────────────────────────────────────────────────

local registered = false

local function register()
    if registered then return end
    if not I.ItemUsage then
        print('[UnlimitedRings] ItemUsage unavailable')
        return
    end
    registered = true
    I.ItemUsage.addHandlerForType(types.Clothing, ringHandler)
    print('[UnlimitedRings] handler registered via ItemUsage')
end

return {
    engineHandlers = {
        onInit = register,
        onLoad = register,
    },
}
