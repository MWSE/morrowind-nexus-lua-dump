local types = require('openmw.types')
local I = require('openmw.interfaces')

I.ItemUsage.addHandlerForType(types.Armor, function(armor, actor)
    -- Sanity checks, then check if we're Imga
    if not armor then return end
    if not types.Player.objectIsInstance(actor) then return end
    local player = types.Player.record(actor)
    if player.race ~= 't_val_imga' then return end

    -- Get the item record
    local record = types.Armor.record(armor)

    -- If it's boots or helmets, send event to actor that equipped it
    if record.type == types.Armor.TYPE.Boots or (record.type == types.Armor.TYPE.Helmet and player.isMale) then
        actor:sendEvent('T_UnequipImga', record.type)
    end

end)

I.ItemUsage.addHandlerForType(types.Clothing, function(clothing, actor)
    -- Sanity checks, then check if we're Imga
    if not clothing then return end
    if not types.Player.objectIsInstance(actor) then return end
    if types.Player.record(actor).race ~= 't_val_imga' then return end

    -- Get the item record
    local record = types.Clothing.record(clothing)

    -- If it's shoes, send event to actor that equipped it
    if record.type == types.Clothing.TYPE.Shoes then
        actor:sendEvent('T_UnequipImga', record.type)
    end

end)
