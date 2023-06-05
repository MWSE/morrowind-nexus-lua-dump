local ui = require('openmw.ui')
local util = require('openmw.util')
local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local storage = require('openmw.storage')

local swapData = {
    {
        adultItem = "common_shirt_02",
        teenItem = "2rtbc_shirt_com_02"
    }
}
local swappingItem = nil
local newItem = nil
local oldEq = nil
local oldkey = 0
local function startsWith(string, prefix)
    return string.sub(string, 1, string.len(prefix)) == prefix
end

local function checkStringForKid(string,level)
    --1rtbc is teen, 2rtbc is kids
    local vanillaStart = { "1em", "1rt" }
    for index, value in ipairs(vanillaStart) do
        if (startsWith(string, value)) then
            return true
        end
    end
    if(level ~= nil) then
        return false
    end
    table.insert(vanillaStart,"2rt")
    table.insert(vanillaStart,"2em")
    for index, value in ipairs(vanillaStart) do
        if (startsWith(string, value)) then
            return true
        end
    end
    return false
end
local function checkStringForAdult(string)
    local vanillaStart = { "common", "expensive", "exquisite", "extravagant" }
    for index, value in ipairs(vanillaStart) do
        if (startsWith(string, value)) then
            return true
        end
    end
    return false
end
local function findMatchingClothing(oldItemID)
    local oldRecord = types.Clothing.record(oldItemID)
    local ret = {}
    for index, record in ipairs(types.Clothing.records) do
        if (record.icon == oldRecord.icon and record.model == oldRecord.model  and record.id ~= oldRecord.id and record.enchant == oldRecord.enchant and checkStringForKid(record.id,true)) then
            table.insert(ret, record.id )
        end
    end
    if(#ret == 0) then
        for index, record in ipairs(types.Clothing.records) do
            if (record.icon == oldRecord.icon and record.id ~= oldRecord.id and record.enchant == oldRecord.enchant and checkStringForKid(record.id)) then
                table.insert(ret, record.id )
            end
        end
    end

    return ret
end
local function raceCheck()
    local raceName = types.NPC.record(self).race
    local endsWithTeen = string.sub(raceName, -4) == "teen"
    local endsWithTeens = string.sub(raceName, -5) == "teens"
    
    return endsWithTeen or endsWithTeens
end

local function compareEquip(eq1, eq2)
    for key, value in pairs(eq1) do
        if (eq2 == nil or eq2[key] ~= value) then
            if(raceCheck() == false) then
                return false
            end
            local record = nil
            for indexx, valuex in ipairs(types.Clothing.records) do
                if valuex.id == value then
                    record = valuex
                end
            end
            if(record == nil) then
               
            else
            if (types.Clothing.record(value) ~= nil and (types.Clothing.record(value).type == types.Clothing.TYPE.Pants or types.Clothing.record(value).type == types.Clothing.TYPE.Skirt or types.Clothing.record(value).type == types.Clothing.TYPE.Shirt)) then
                
                local isAdult = checkStringForAdult(eq1[key])
                local isKid = checkStringForKid(eq1[key])
                if(isKid) then
               --     ui.showMessage("Added Kid's " .. eq1[key])
                elseif(isAdult) then
                    local kidClothes = findMatchingClothing(eq1[key])

                    if(#kidClothes > 0) then
                        swappingItem = eq1[key]
                        newItem = kidClothes[1]
                        oldkey = key
                        oldEq = eq2
                        core.sendGlobalEvent("itemSwapEvent",
                            { actorToRemove = self, newItem = newItem, swappingItem = swappingItem })
                        return false
                    elseif(#kidClothes > 1) then
                        for index, value in ipairs(kidClothes) do
                            print(value)
                        end
                   -- ui.showMessage("Added Adult's " .. eq1[key] .. " with ".. tostring(#kidClothes) .. " matches" )
                    end
                end
                for index, tableItem in ipairs(swapData) do
                    if (tableItem.adultItem == eq1[key]) then
                        swappingItem = tableItem.adultItem
                        newItem = tableItem.teenItem
                        oldkey = key
                        oldEq = eq2
                  --      ui.showMessage("Swapping to " .. tableItem.teenItem)
                        core.sendGlobalEvent("itemSwapEvent",
                            { actorToRemove = self, newItem = newItem, swappingItem = swappingItem })
                        return false
                    end
                end
            end
        end
            return false
        end
    end
    for key, value in pairs(eq2) do
        if (eq1 == nil or eq1[key] ~= value) then
         --   ui.showMessage("Removed " .. eq2[key])
            return false
        end
    end
    return true
end
local function findSlot(item)
    if item.type == types.Armor then
        if (types.Armor.record(item).type == types.ArmorTYPE.RGauntlet) then
            return types.Actor.EQUIPMENT_SLOT.RightGauntlet
        elseif (types.Armor.record(item).type == types.ArmorTYPE.LGauntlet) then
            return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
        end
    elseif item.type == types.Book then
        return types.Book.record(item).enchant
    elseif item.type == types.Clothing then
        if (types.Clothing.record(item).type == types.Clothing.TYPE.Amulet) then
            return types.Actor.EQUIPMENT_SLOT.Amulet
        elseif (types.Clothing.record(item).type == types.Clothing.TYPE.Skirt) then
            return types.Actor.EQUIPMENT_SLOT.Skirt
        elseif (types.Clothing.record(item).type == types.Clothing.TYPE.Shirt) then
            return types.Actor.EQUIPMENT_SLOT.Shirt
        elseif (types.Clothing.record(item).type == types.Clothing.TYPE.Shoes) then
            return types.Actor.EQUIPMENT_SLOT.Boots
        elseif (types.Clothing.record(item).type == types.Clothing.TYPE.Robe) then
            return types.Actor.EQUIPMENT_SLOT.Robe
        elseif (types.Clothing.record(item).type == types.Clothing.TYPE.Pants) then
            return types.Actor.EQUIPMENT_SLOT.Pants
        end
    elseif item.type == types.Weapon then
        return types.Actor.EQUIPMENT_SLOT.CarriedRight
    end
    print("Couldn't find slot for " .. item.recordId)
    return false
end

local function equipItem(itemId)
    if (itemId == nil) then return nil end
    if (itemId.recordId ~= nil) then itemId = itemId.recordId end
    local inv = types.Actor.inventory(self)
    local item = inv:find(itemId)
    local slot = findSlot(item)
    if (slot) then
        local equip = types.Actor.getEquipment(self)
        equip[slot] = item
        types.Actor.setEquipment(self, equip)
    end
end

local function equipNewItem(newItemOb)
    equipItem(newItem)
    --local equipment = types.Actor.getEquipment(self)
    --equipment[findSlot(newItemOb)] = newItemOb

    -- types.Actor.setEquipment(equipment)
end
local function getSerializableEquip(eq)
    local ret = {}
    for key, value in pairs(eq) do
        if value.type == types.Clothing then
        ret[key] = value.recordId
        end
    end
    return ret
end

local lastEquip = nil


local function onFrame(dt)
    local equip = getSerializableEquip(types.Actor.getEquipment(self))

    if (lastEquip ~= nil) then
        if (compareEquip(equip, lastEquip) == false) then
            --      ui.showMessage("Equipment changed")
        end
    end

    lastEquip = equip
end

return {
    interfaceName = "ClothingSwap",
    interface = {
        version = 1,
        findMatchingClothing = findMatchingClothing,
        raceCheck = raceCheck,
    },
    engineHandlers = {
        onFrame = onFrame

    },
    eventHandlers = { equipNewItem = equipNewItem,
    }
}
