local I     = require('openmw.interfaces')
local types = require('openmw.types')

local GLASSES_RECORD_IDS = {
    ['_rv_blindfold1']  = true,
    ['_rv_eyepatch1l']  = true,
    ['_rv_eyepatch1r']  = true,
    ['_rv_glasses1']    = true,
    ['_rv_glasses1s']   = true,
    ['_rv_glasses2']    = true,
    ['_rv_glasses2s']   = true,
    ['_rv_glasses3']    = true,
    ['_rv_glasses4']    = true,
    ['_rv_glasses4s']   = true,
    ['_rv_goggles1']    = true,
    ['_rv_goggles2']    = true,
    ['_rv_goggles3']    = true,
    ['_rv_goggles4']    = true,
    ['_rv_goggles5']    = true,
    ['_rv_goggles6']    = true,
    ['_rv_goggles7']    = true,
    ['_rv_goggles8']    = true,
    ['_rv_lenses1']     = true,
    ['_rv_lenses2']     = true,
}

local function isGlassesItem(item)
    if types.Armor.objectIsInstance(item) then
        local ok, rec = pcall(types.Armor.record, item)
        if ok and rec and rec.id then
            return GLASSES_RECORD_IDS[rec.id:lower()] == true
        end
    elseif types.Clothing.objectIsInstance(item) then
        local ok, rec = pcall(types.Clothing.record, item)
        if ok and rec and rec.id then
            return GLASSES_RECORD_IDS[rec.id:lower()] == true
        end
    end
    return false
end

local function glassesHandler(item, actor)
    if not isGlassesItem(item) then return end
    if not types.Player.objectIsInstance(actor) then return end
    actor:sendEvent('Glasses_PromptEquip', { itemId = item.recordId })
    return false  -- cancel the actual equip
end

local registered = false
local function register()
    if registered then return end
    if not I.ItemUsage then
        print('[CosmeticGlasses] ItemUsage unavailable')
        return
    end
    registered = true
    I.ItemUsage.addHandlerForType(types.Clothing, glassesHandler)
    I.ItemUsage.addHandlerForType(types.Armor,    glassesHandler)
    print('[CosmeticGlasses] handler registered via ItemUsage')
end

return {
    engineHandlers = {
        onInit = register,
        onLoad = register,
    },
}
