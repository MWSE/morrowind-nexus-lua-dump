local I     = require('openmw.interfaces')
local types = require('openmw.types')

local BACKPACKS_RECORD_IDS = {
    ['aa_backpack_a']     = true,
    ['aa_backpack_af']    = true,
    ['aa_backpack_bn']    = true,
    ['aa_backpack_comp']  = true,
    ['aa_backpack_dummy'] = true,
    ['aa_backpack_fw']    = true,
    ['aa_backpack_ian']   = true,
    ['aa_backpack_nom']   = true,
}

local function isBackpackItem(item)
    local recId
    local ok, rec = pcall(types.Clothing.record, item)
    if ok and rec and rec.id then
        recId = rec.id:lower()
    else
        ok, rec = pcall(types.Armor.record, item)
        if ok and rec and rec.id then recId = rec.id:lower() end
    end
    return recId and BACKPACKS_RECORD_IDS[recId] == true
end

local function backpackHandler(item, actor)
    if not isBackpackItem(item) then return end
    if not types.Player.objectIsInstance(actor) then return end
    actor:sendEvent('Backpacks_PromptEquip', { itemId = item.recordId })
    return false
end

local registered = false
local function register()
    if registered then return end
    if not I.ItemUsage then
        print('[CosmeticBackpacks] ItemUsage unavailable')
        return
    end
    registered = true
    I.ItemUsage.addHandlerForType(types.Clothing, backpackHandler)
    I.ItemUsage.addHandlerForType(types.Armor,    backpackHandler)
    print('[CosmeticBackpacks] handler registered via ItemUsage')
end

return {
    engineHandlers = {
        onInit = register,
        onLoad = register,
    },
}
