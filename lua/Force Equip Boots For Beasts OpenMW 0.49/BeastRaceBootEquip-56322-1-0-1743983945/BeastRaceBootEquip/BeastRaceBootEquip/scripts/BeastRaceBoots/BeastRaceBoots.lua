local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local input = require('openmw.input')

local isBeast = false
local lastEquippedBootsIndex = -1 -- Start at -1 (no boots equipped)
local raceChecked = false
local pendingCheck = nil

-- Check if the player is a beast race
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

-- Find all boots in inventory
local function getBootsInInventory()
    local bootsList = {}
    print("DEBUG: Scanning inventory...")
    for _, item in ipairs(types.Actor.inventory(self):getAll()) do
        local isBoots = false
        if item.type == types.Armor then
            local armorType = types.Armor.record(item).type
            if armorType == 5 then -- Boots type
                isBoots = true
                print("Detected as boots: " .. item.recordId)
            end
        end
        if isBoots then
            table.insert(bootsList, item)
            print("Found equippable boots/shoes in inventory: " .. item.recordId .. " (Armor (Boots))")
        end
    end
    return bootsList
end

-- Handle key press to cycle boots
local function onKeyPress(key)
    if key.code ~= input.KEY.B then return end
    if not isBeast then
        print("Not a beast race, ignoring key press")
        return
    end

    local bootsList = getBootsInInventory()
    if #bootsList == 0 then
        print("No boots found in inventory")
        return
    end

    local equipment = types.Actor.equipment(self)
    local currentBoots = equipment[types.Actor.EQUIPMENT_SLOT.Boots]
    print("Initial equipment state - Boots: " .. (currentBoots and currentBoots.recordId or "none"))
    print("Current lastEquippedBootsIndex: " .. lastEquippedBootsIndex)

    if currentBoots then
        -- Unequip current boots
        print("Attempted to unequip boots: " .. currentBoots.recordId)
        local newEquipment = {}
        for slot, item in pairs(equipment) do
            if slot ~= types.Actor.EQUIPMENT_SLOT.Boots then
                newEquipment[slot] = item
            end
        end
        types.Actor.setEquipment(self, newEquipment)
        core.sound.playSoundFile3d("item armor down", self)
        pendingCheck = { action = "unequip", expected = nil }
    else
        -- Equip next pair of boots
        lastEquippedBootsIndex = (lastEquippedBootsIndex + 1) % #bootsList
        local nextBoots = bootsList[lastEquippedBootsIndex + 1] -- Lua is 1-indexed
        print("Attempted to equip boots: " .. nextBoots.recordId)
        local newEquipment = {}
        for slot, item in pairs(equipment) do
            newEquipment[slot] = item
        end
        newEquipment[types.Actor.EQUIPMENT_SLOT.Boots] = nextBoots
        types.Actor.setEquipment(self, newEquipment)
        core.sound.playSoundFile3d("item armor up", self)
        pendingCheck = { action = "equip", expected = nextBoots.recordId }
    end
end

-- Verify equipment changes asynchronously
local function onUpdate(dt)
    if pendingCheck then
        local equipment = types.Actor.equipment(self)
        local currentBoots = equipment[types.Actor.EQUIPMENT_SLOT.Boots]
        if pendingCheck.action == "unequip" then
            if currentBoots then
                print("Failed to unequip boots: " .. currentBoots.recordId .. " still equipped")
            else
                print("Successfully unequipped boots")
            end
        elseif pendingCheck.action == "equip" then
            if not currentBoots then
                print("Failed to equip boots: slot is still empty")
            elseif currentBoots.recordId == pendingCheck.expected then
                print("Successfully equipped boots: " .. currentBoots.recordId)
            else
                print("Failed to equip boots: expected " .. pendingCheck.expected .. ", got " .. currentBoots.recordId)
            end
        end
        pendingCheck = nil -- Clear after checking
    end
end

-- Run on script initialization and load
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