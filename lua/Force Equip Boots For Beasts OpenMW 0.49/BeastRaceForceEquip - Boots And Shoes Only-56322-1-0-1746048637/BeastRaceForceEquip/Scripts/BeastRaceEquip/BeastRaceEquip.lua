local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local input = require('openmw.input')

local isBeast = false
local lastEquippedBootsIndex = -1
local lastEquippedShoesIndex = -1
local raceChecked = false
local pendingCheck = nil
local clothingDebugged = false

local function checkBeastRace()
    if types.NPC.objectIsInstance(self) then
        local record = types.NPC.record(self)
        local race = record and record.race and record.race:lower() or 'unknown'
        isBeast = (race == 'khajiit' or race == 'argonian')
        if not raceChecked then
            print("checkBeastRace - Player race: " .. race .. ", isBeast: " .. tostring(isBeast))
            raceChecked = true
        end
    end
end

local function debugClothingTypes()
    print("DEBUG: Scanning clothing items...")
    for _, item in ipairs(types.Actor.inventory(self):getAll()) do
        if item.type == types.Clothing then
            local record = types.Clothing.record(item)
            print("Clothing item: " .. item.recordId .. ", name: " .. (record.name or "unknown") .. ", type: " .. tostring(record.type))
        end
    end
    clothingDebugged = true
end

local function getBootsInInventory()
    local bootsList = {}
    print("DEBUG: Scanning inventory for boots...")
    for _, item in ipairs(types.Actor.inventory(self):getAll()) do
        local isBoots = false
        if item.type == types.Armor then
            local armorType = types.Armor.record(item).type
            if armorType == 5 then -- Boots
                isBoots = true
                print("Detected as boots: " .. item.recordId)
            end
        end
        if isBoots then
            table.insert(bootsList, item)
            print("Found equippable boots: " .. item.recordId .. " (Armor (Boots))")
        end
    end
    return bootsList
end

local function getShoesInInventory()
    local shoesList = {}
    print("DEBUG: Scanning inventory for shoes...")
    for _, item in ipairs(types.Actor.inventory(self):getAll()) do
        local isShoes = false
        if item.type == types.Clothing then
            local clothingType = types.Clothing.record(item).type
            if clothingType == 1 then -- Adjusted to type 1 based on log
                isShoes = true
                print("Detected as shoes: " .. item.recordId .. ", name: " .. (types.Clothing.record(item).name or "unknown") .. ", type: " .. tostring(clothingType))
            end
        end
        if isShoes then
            table.insert(shoesList, item)
            print("Found equippable shoes: " .. item.recordId .. " (Clothing (Shoes))")
        end
    end
    if #shoesList == 0 and not clothingDebugged then
        debugClothingTypes()
    end
    return shoesList
end

local function onKeyPress(key)
    if not isBeast then
        print("Not a beast race, ignoring key press")
        return
    end

    local itemList, index, slot, itemType, indexVar
    if key.code == input.KEY.B then
        itemList = getBootsInInventory()
        index = lastEquippedBootsIndex
        slot = types.Actor.EQUIPMENT_SLOT.Boots
        itemType = "boots"
        indexVar = "lastEquippedBootsIndex"
    elseif key.code == input.KEY.M then
        itemList = getShoesInInventory()
        index = lastEquippedShoesIndex
        slot = types.Actor.EQUIPMENT_SLOT.Boots
        itemType = "shoes"
        indexVar = "lastEquippedShoesIndex"
    else
        return
    end

    if #itemList == 0 then
        print("No " .. itemType .. " found in inventory")
        return
    end

    local equipment = types.Actor.equipment(self)
    local currentItem = equipment[slot]
    print("Initial equipment state - " .. itemType .. ": " .. (currentItem and currentItem.recordId or "none"))
    print("Current " .. indexVar .. ": " .. index)

    if currentItem then
        print("Attempted to unequip " .. itemType .. ": " .. currentItem.recordId)
        local newEquipment = {}
        for equipSlot, equipItem in pairs(equipment) do
            if equipSlot ~= slot then
                newEquipment[equipSlot] = equipItem
            end
        end
        types.Actor.setEquipment(self, newEquipment)
        core.sound.playSoundFile3d("item armor down", self)
        pendingCheck = { action = "unequip", expected = nil, slot = slot }
    else
        index = (index + 1) % #itemList
        local nextItem = itemList[index + 1] -- Lua is 1-indexed
        print("Attempted to equip " .. itemType .. ": " .. nextItem.recordId)
        local newEquipment = {}
        for equipSlot, equipItem in pairs(equipment) do
            newEquipment[equipSlot] = equipItem
        end
        newEquipment[slot] = nextItem
        types.Actor.setEquipment(self, newEquipment)
        core.sound.playSoundFile3d("item armor up", self)
        pendingCheck = { action = "equip", expected = nextItem.recordId, slot = slot }
        if itemType == "boots" then
            lastEquippedBootsIndex = index
        elseif itemType == "shoes" then
            lastEquippedShoesIndex = index
        end
    end
end

local function onUpdate(dt)
    if pendingCheck then
        local equipment = types.Actor.equipment(self)
        local currentItem = equipment[pendingCheck.slot]
        if pendingCheck.action == "unequip" then
            if currentItem then
                print("Failed to unequip item: " .. currentItem.recordId .. " still equipped")
            else
                print("Successfully unequipped item")
            end
        elseif pendingCheck.action == "equip" then
            if not currentItem then
                print("Failed to equip item: slot is still empty")
            elseif currentItem.recordId == pendingCheck.expected then
                print("Successfully equipped item: " .. currentItem.recordId)
            else
                print("Failed to equip item: expected " .. pendingCheck.expected .. ", got " .. currentItem.recordId)
            end
        end
        pendingCheck = nil
    end
end

local function onInit()
    checkBeastRace()
end

local function onLoad()
    checkBeastRace()
end

return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onKeyPress = onKeyPress,
        onUpdate = onUpdate
    }
}