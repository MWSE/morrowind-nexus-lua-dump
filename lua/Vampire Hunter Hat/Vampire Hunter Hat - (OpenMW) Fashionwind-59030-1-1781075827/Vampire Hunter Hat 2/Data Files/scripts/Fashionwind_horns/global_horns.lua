local I     = require('openmw.interfaces')
local types = require('openmw.types')

local HORNS_RECORD_IDS = {
    ['_rv_antlers_1'] = true,
    ['_rv_antlers_2'] = true,
    ['_rv_ears_1']    = true,
    ['_rv_ears_2']    = true,
    ['_rv_horns_1']   = true,
    ['_rv_horns_2']   = true,
    ['_rv_horns_3']   = true,
    ['_vampire_hat'] = true,
}

local function isHornsItem(item)
    local recId
    local ok, rec = pcall(types.Clothing.record, item)
    if ok and rec and rec.id then
        recId = rec.id:lower()
    else
        ok, rec = pcall(types.Armor.record, item)
        if ok and rec and rec.id then recId = rec.id:lower() end
    end
    return recId and HORNS_RECORD_IDS[recId] == true
end

local function hornsHandler(item, actor)
    if not isHornsItem(item) then return end
    if not types.Player.objectIsInstance(actor) then return end
    actor:sendEvent('Horns_PromptEquip', { itemId = item.recordId })
    return false  
end

local registered = false
local function register()
    if registered then return end
    if not I.ItemUsage then
        print('[CosmeticHorns] ItemUsage unavailable')
        return
    end
    registered = true
    I.ItemUsage.addHandlerForType(types.Clothing, hornsHandler)
    I.ItemUsage.addHandlerForType(types.Armor,    hornsHandler)
    print('[CosmeticHorns] handler registered via ItemUsage')
end

return {
    engineHandlers = {
        onInit = register,
        onLoad = register,
    },
}
