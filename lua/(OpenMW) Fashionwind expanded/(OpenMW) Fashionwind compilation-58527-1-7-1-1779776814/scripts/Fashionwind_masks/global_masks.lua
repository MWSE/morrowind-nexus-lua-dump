local I     = require('openmw.interfaces')
local types = require('openmw.types')

local MASKS_RECORD_IDS = {
    ['_rv_ashmask_1']   = true,
    ['_rv_ashmask_2']   = true,
    ['_rv_ashmask_3']   = true,
    ['_rv_daedramask_1'] = true,
    ['_rv_daedramask_2'] = true,
    ['_rv_daedramask_3'] = true,
    ['_rv_daedramask_4'] = true,
    ['_rv_facewrap_1']  = true,
    ['_rv_facewrap_2']  = true,
    ['_rv_facewrap_3']  = true,
    ['_rv_facewrap_4']  = true,
    ['_rv_facewrap_5']  = true,
    ['_rv_facewrap_6']  = true,
    ['_rv_facewrap_7']  = true,
    ['_rv_facewrap_8']  = true,
    ['_rv_orcishmask_1'] = true,
    ['_rv_orcishmask_2'] = true,
}

local function isMaskItem(item)
    local recId
    local ok, rec = pcall(types.Clothing.record, item)
    if ok and rec and rec.id then
        recId = rec.id:lower()
    else
        ok, rec = pcall(types.Armor.record, item)
        if ok and rec and rec.id then recId = rec.id:lower() end
    end
    return recId and MASKS_RECORD_IDS[recId] == true
end

local function maskHandler(item, actor)
    if not isMaskItem(item) then return end
    if not types.Player.objectIsInstance(actor) then return end
    actor:sendEvent('Masks_PromptEquip', { itemId = item.recordId })
    return false  -- cancel the actual equip
end

local registered = false
local function register()
    if registered then return end
    if not I.ItemUsage then
        print('[CosmeticMasks] ItemUsage unavailable')
        return
    end
    registered = true
    I.ItemUsage.addHandlerForType(types.Clothing, maskHandler)
    I.ItemUsage.addHandlerForType(types.Armor,    maskHandler)
    print('[CosmeticMasks] handler registered via ItemUsage')
end

return {
    engineHandlers = {
        onInit = register,
        onLoad = register,
    },
}
