local I     = require('openmw.interfaces')
local types = require('openmw.types')

local EARRINGS_RECORD_IDS = {
    ['_earrings_01']  = true,
    ['_earrings_02']  = true,
    ['_earrings_03']  = true,
    ['_earrings_03a'] = true,
    ['_kd_femgdia']   = true,
    ['_kd_femgem']    = true,
    ['_kd_femgru']    = true,
    ['_kd_femgsa']    = true,
    ['_kd_femsdia']   = true,
    ['_kd_femsem']    = true,
    ['_kd_femsru']    = true,
    ['_kd_femssa']    = true,
    ['_kd_g01']       = true,
    ['_kd_g01r']      = true,
    ['_kd_g02']       = true,
    ['_kd_g02r']      = true,
    ['_kd_g03']       = true,
    ['_kd_g03r']      = true,
    ['_kd_g04']       = true,
    ['_kd_g04r']      = true,
    ['_kd_g05']       = true,
    ['_kd_g05r']      = true,
    ['_kd_g06']       = true,
    ['_kd_g06r']      = true,
    ['_kd_s01']       = true,
    ['_kd_s01r']      = true,
    ['_kd_s02']       = true,
    ['_kd_s02r']      = true,
    ['_kd_s03']       = true,
    ['_kd_s03r']      = true,
    ['_kd_s04']       = true,
    ['_kd_s04r']      = true,
    ['_kd_s05']       = true,
    ['_kd_s05r']      = true,
    ['_kd_s06']       = true,
    ['_kd_s06r']      = true,
}

local function isEarringsItem(item)
    local recId
    local ok, rec = pcall(types.Clothing.record, item)
    if ok and rec and rec.id then
        recId = rec.id:lower()
    else
        ok, rec = pcall(types.Armor.record, item)
        if ok and rec and rec.id then recId = rec.id:lower() end
    end
    return recId and EARRINGS_RECORD_IDS[recId] == true
end

local function earringsHandler(item, actor)
    if not isEarringsItem(item) then return end
    if not types.Player.objectIsInstance(actor) then return end
    actor:sendEvent('Earrings_PromptEquip', { itemId = item.recordId })
    return false
end

local registered = false
local function register()
    if registered then return end
    if not I.ItemUsage then
        print('[CosmeticEarrings] ItemUsage unavailable')
        return
    end
    registered = true
    I.ItemUsage.addHandlerForType(types.Clothing, earringsHandler)
    I.ItemUsage.addHandlerForType(types.Armor,    earringsHandler)
    print('[CosmeticEarrings] handler registered via ItemUsage')
end

return {
    engineHandlers = {
        onInit = register,
        onLoad = register,
    },
}
