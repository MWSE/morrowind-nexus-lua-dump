--[[
ErnGearRandomizer for OpenMW.
Copyright (C) 2025 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

local core = require("openmw.core")
local T = require("openmw.types")
local V = require("openmw.vfs")
local S = require("scripts.ErnGearRandomizer.settings")
local U = require("scripts.ErnGearRandomizer.uniques")

local storage = require("openmw.storage")

local function lookupTable()
    return storage.globalSection(S.MOD_NAME .. "_swap_tables")
end

armorWeightSplit = {
    -- just take the heaviest light armor's weight
    [T.Armor.TYPE.Boots] = 8,
    [T.Armor.TYPE.Cuirass] = 18,
    [T.Armor.TYPE.Greaves] = 9,
    [T.Armor.TYPE.Helmet] = 3,
    [T.Armor.TYPE.LBracer] = 3,
    [T.Armor.TYPE.LGauntlet] = 3,
    [T.Armor.TYPE.LPauldron] = 4,
    [T.Armor.TYPE.RBracer] = 4,
    [T.Armor.TYPE.RGauntlet] = 4,
    [T.Armor.TYPE.RPauldron] = 4,
    [T.Armor.TYPE.Shield] = 9
}

local function quantize(num, size)
    return (size * math.floor(tonumber(num) / size))
end

local function enchantedFlag(record)
    if record.enchant == nil then
        return ""
    else
        return "m"
    end
end

local function bucket(num)
    -- Armor and weapon prices are really wacky, with lots of low-end armor
    -- and fewer types of high-end armor that are extremely expensive.
    if num <= 100 then
        return quantize(num, 50)
    else
        -- This smushes high-end armors closer together.
        return 100 + math.floor(math.log(num))
    end
end

-- lookupArmorTableName returns the lookuptable containing similar armors.
local function lookupArmorTableName(record)
    if S.extraRandom() then
        return S.MOD_NAME .. "a" .. record.type
    end
    -- include bucketed weight in the table name so we try to pair
    -- armors of similar skills.
    weightBucket = "!"
    weightBucketDivisor = armorWeightSplit[record.type]
    if weightBucketDivisor == false then
        weightBucket = "!"
    else
        weightBucket = quantize(record.weight, weightBucketDivisor)
    end

    -- https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_types.html##(Armor).TYPE
    return S.MOD_NAME ..
        "a" .. record.type ..
        "e" .. quantize(record.enchantCapacity, 2) ..
        "w" .. weightBucket ..
        "c" .. bucket(tonumber(record.value)) ..
        enchantedFlag(record)
end

-- lookupClothingTableName returns the lookuptable containing similar clothing.
local function lookupClothingTableName(record)
    if S.extraRandom() then
        return S.MOD_NAME .. "c" .. record.type
    end
    -- https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_types.html##(Clothing).TYPE
    return S.MOD_NAME ..
        "c" .. record.type ..
        "e" .. quantize(record.enchantCapacity, 2) ..
        "c" .. quantize(record.value, 20) ..
        enchantedFlag(record)
end


-- lookupWeaponTableName returns the lookuptable containing similar weapons.
local function lookupWeaponTableName(record)
    if S.extraRandom() then
        return S.MOD_NAME .. "w" .. record.type
    end
    -- https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_types.html##(Weapon).TYPE
    return S.MOD_NAME ..
        "w" .. record.type ..
        "e" .. quantize(record.enchantCapacity, 2) ..
        "c" .. bucket(tonumber(record.value)) ..
        enchantedFlag(record)
end

local function addToTable(tableKey, recordID)
    if lookupTable():get(tableKey) == nil then
        lookupTable():set(tableKey, {})
        lookupTable():set("COUNT" .. tableKey, 0)
    end
    list = lookupTable():getCopy(tableKey)
    table.insert(list, recordID)
    lookupTable():set(tableKey, list)
    -- count of the list
    count = lookupTable():get("COUNT" .. tableKey)
    lookupTable():set("COUNT" .. tableKey, count + 1)

    --S.debugPrint("table " .. tableKey .. " added " .. recordID)
end

local function filter(record)
    if U.uniqueID(record.id) == true then
        return false
    end
    if S.enchanted() == false and record.enchant ~= nil then
        return false
    end
    if string.find(string.lower(record.id), ".*fake.*") ~= nil then
        return false
    end
    if string.find(string.lower(record.id), ".*theater.*") ~= nil then
        return false
    end
    if string.find(string.lower(record.id), ".*unique.*") ~= nil then
        return false
    end
    if string.find(string.lower(record.id), ".*dummy.*") ~= nil then
        return false
    end
    if string.find(string.lower(record.id), ".*reward.*") ~= nil then
        return false
    end
    if string.find(string.lower(record.id), ".*curse.*") ~= nil then
        return false
    end

    for itemPattern in S.itemBan() do
        if string.find(string.lower(record.id), itemPattern) ~= nil then
            S.debugPrint("Banned item " .. record.id)
            return false
        end
    end

    return true
end

local function meshOk(record)
    -- Check if path defined.
    if not V.fileExists(record.model) then
        S.debugPrint("Bad mesh " .. record.id .. " : missing file " .. record.model)
        return false
    end
    -- Try to load it.
    -- Note: This doesn't actually find any errors!
    --[[
    fileHandle, errMsg = V.open(record.model)
    if errMsg ~= nil then
        S.debugPrint("Bad mesh " .. record.id .. " : failed to open " .. record.model)
        return false
    end
    fileHandle:close()
    ]]
    return true
end

lastUpdateTime =  core.getRealTime() - 5
-- initTables builds the swap tables.
local function initTables()
    now = core.getRealTime()
    if now < 1 + lastUpdateTime then
        return
    end
    lastUpdateTime = now

    print("Loading swap tables.")
    lookupTable():reset()

    S.debugPrint("loading armors tables")
    for i, record in pairs(T.Armor.records) do
        recordID = string.lower(record.id)
        if filter(record) and meshOk(record) then
            tableKey = lookupArmorTableName(record)
            addToTable(tableKey, recordID)
        end
    end

    S.debugPrint("loading clothing tables")
    for i, record in pairs(T.Clothing.records) do
        recordID = string.lower(record.id)
        if filter(record) and meshOk(record) then
            tableKey = lookupClothingTableName(record)
            addToTable(tableKey, recordID)
        end
    end

    S.debugPrint("loading weapons tables")
    for i, record in pairs(T.Weapon.records) do
        recordID = string.lower(record.id)
        if filter(record) and meshOk(record) then
            tableKey = lookupWeaponTableName(record)
            addToTable(tableKey, recordID)
        end
    end

    lookupTable():setLifeTime(storage.LIFE_TIME.GameSession)

    print("Done loading swap tables.")
end

function pickNewRecordFromTable(lookupKey)
    size = lookupTable():get("COUNT" .. lookupKey)
    if size == nil then
        -- we shouldn't get here unless settings changed or
        -- new item records were created procedurally.
        S.debugPrint("bad table " .. lookupKey)
        return nil
    end
    if size <= 1 then
        S.debugPrint("small table " .. lookupKey)
        return nil
    end

    randIndex = math.random(1, size)
    return lookupTable():get(lookupKey)[randIndex]
end

-- returns record id if replacement needed.
-- returns nil if no replacement.
function getArmorRecordID(armorItem)
    -- https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_core.html##(GameObject)
    if S.armor() ~= true then
        S.debugPrint("armor swap disabled")
        return nil
    end
    if filter(armorItem) == false then
        S.debugPrint("armor filtered")
        return nil
    end
    if S.chance() < math.random(0, 99) then
        S.debugPrint("die roll failed")
        return nil
    end

    lookupKey = lookupArmorTableName(T.Armor.record(armorItem))
    return pickNewRecordFromTable(lookupKey)
end

-- returns record id if replacement needed.
-- returns nil if no replacement.
function getClothingRecordID(clothingItem)
    -- https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_core.html##(GameObject)
    if S.clothes() ~= true then
        return nil
    end
    if filter(clothingItem) == false then
        return nil
    end
    if S.chance() < math.random(0, 99) then
        return nil
    end

    lookupKey = lookupClothingTableName(T.Clothing.record(clothingItem))
    return pickNewRecordFromTable(lookupKey)
end

-- returns record id if replacement needed.
-- returns nil if no replacement.
function getWeaponRecordID(weaponItem)
    -- https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_core.html##(GameObject)
    if S.weapons() ~= true then
        return nil
    end
    if filter(weaponItem) == false then
        return nil
    end
    if S.chance() < math.random(0, 99) then
        return nil
    end

    lookupKey = lookupWeaponTableName(T.Weapon.record(weaponItem))
    return pickNewRecordFromTable(lookupKey)
end


return {
    initTables = initTables,
    getArmorRecordID = getArmorRecordID,
    getClothingRecordID = getClothingRecordID,
    getWeaponRecordID = getWeaponRecordID
}
