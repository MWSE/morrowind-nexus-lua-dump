local self = require("openmw.self")
local core = require("openmw.core")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local function findSlot(item)
    if (item == nil) then
        return
    end
    --Finds a equipment slot for an inventory item, if it has one,
    if item.type == types.Armor then
        if (types.Armor.records[item.recordId].type == types.Armor.TYPE.RGauntlet) then
            return types.Actor.EQUIPMENT_SLOT.RightGauntlet
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.LGauntlet) then
            return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Boots) then
            return types.Actor.EQUIPMENT_SLOT.Boots
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Cuirass) then
            return types.Actor.EQUIPMENT_SLOT.Cuirass
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Greaves) then
            return types.Actor.EQUIPMENT_SLOT.Greaves
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.LBracer) then
            return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.RBracer) then
            return types.Actor.EQUIPMENT_SLOT.RightGauntlet
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.RPauldron) then
            return types.Actor.EQUIPMENT_SLOT.RightPauldron
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.LPauldron) then
            return types.Actor.EQUIPMENT_SLOT.LeftPauldron
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Helmet) then
            return types.Actor.EQUIPMENT_SLOT.Helmet
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Shield) then
            return types.Actor.EQUIPMENT_SLOT.CarriedLeft
        end
    elseif item.type == types.Clothing then
        if (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Amulet) then
            return types.Actor.EQUIPMENT_SLOT.Amulet
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Belt) then
            return types.Actor.EQUIPMENT_SLOT.Belt
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.LGlove) then
            return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.RGlove) then
            return types.Actor.EQUIPMENT_SLOT.RightGauntlet
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Ring) then
            return types.Actor.EQUIPMENT_SLOT.RightRing
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Skirt) then
            return types.Actor.EQUIPMENT_SLOT.Skirt
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Shirt) then
            return types.Actor.EQUIPMENT_SLOT.Shirt
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Shoes) then
            return types.Actor.EQUIPMENT_SLOT.Boots
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Robe) then
            return types.Actor.EQUIPMENT_SLOT.Robe
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Pants) then
            return types.Actor.EQUIPMENT_SLOT.Pants
        end
    elseif item.type == types.Weapon then
        if (item.type.records[item.recordId].type == types.Weapon.TYPE.Arrow or item.type.records[item.recordId].type == types.Weapon.TYPE.Bolt) then
            return types.Actor.EQUIPMENT_SLOT.Ammunition
        end
        return types.Actor.EQUIPMENT_SLOT.CarriedRight
    elseif item.type == types.Light then
        return types.Actor.EQUIPMENT_SLOT.CarriedLeft
    end
    -- ----print("Couldn't find slot for " .. item.recordId)
    return nil
end
local function equipItem(itemId)
    local inv = types.Actor.inventory(self)
    local item = inv:find(itemId)
end
local function Died()
    core.sendGlobalEvent("onActorDiedHest",self)
end
local function evalEquipment()
    local equip = types.Actor.getEquipment(self)
    for index, item in ipairs(types.Actor.inventory(self):getAll()) do
    
        local slot = findSlot(item)
        if slot then
            
        equip[slot] = item
        end
    end
    types.Actor.setEquipment(self, equip)
end

return {
    eventHandlers = {
        Died = Died,
        evalEquipment = evalEquipment,
    }
}
