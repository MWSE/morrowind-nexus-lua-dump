local I     = require('openmw.interfaces')
local types = require('openmw.types')

local SCARVES_RECORD_IDS = {
    ['_rv_scarf01'] = true,
    ['_rv_scarf02'] = true,
    ['_rv_scarf03'] = true,
    ['_rv_scarf04'] = true,
    ['_rv_scarf05'] = true,
    ['_rv_scarf06'] = true,
    ['_rv_scarf07'] = true,
    ['_rv_scarf08'] = true,
    ['_rv_scarf09'] = true,
    ['_rv_scarf10'] = true,
    ['_rv_scarf11'] = true,
    ['_rv_scarf12'] = true,
    ['_rv_scarf13'] = true,
    ['_rv_scarf14'] = true,
    ['_rv_scarf15'] = true,
    ['_rv_scarf16'] = true,
}

local function isScarfItem(item)
    if types.Armor.objectIsInstance(item) then
        local ok, rec = pcall(types.Armor.record, item)
        if ok and rec and rec.id then
            return SCARVES_RECORD_IDS[rec.id:lower()] == true
        end
    elseif types.Clothing.objectIsInstance(item) then
        local ok, rec = pcall(types.Clothing.record, item)
        if ok and rec and rec.id then
            return SCARVES_RECORD_IDS[rec.id:lower()] == true
        end
    end
    return false
end

local function scarfHandler(item, actor)
    if not isScarfItem(item) then return end
    if not types.Player.objectIsInstance(actor) then return end
    actor:sendEvent('Scarves_PromptEquip', { itemId = item.recordId })
    return false  -- cancel the actual equip
end

local registered = false
local function register()
    if registered then return end
    if not I.ItemUsage then
        print('[CosmeticScarves] ItemUsage unavailable')
        return
    end
    registered = true
    I.ItemUsage.addHandlerForType(types.Clothing, scarfHandler)
    I.ItemUsage.addHandlerForType(types.Armor,    scarfHandler)
    print('[CosmeticScarves] handler registered via ItemUsage')
end

return {
    engineHandlers = {
        onInit = register,
        onLoad = register,
    },
}
