local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("Loadout")
local ItemList = require("mer.chargenScenarios.component.ItemList")

---@class ChargenScenarios.Loadouts
local Loadouts = {
    ---@type table<string, fun():ChargenScenarios.ItemList>
    registeredLoadouts = {}
}

event.register("loaded", function()
    logger:debug("Resetting active flag on loadouts")
    --reset active flag on load
    for _, callback in pairs(Loadouts.registeredLoadouts) do
        local itemList = callback()
        itemList.active = itemList.defaultActive
    end
end)

---@param e { id: string, itemList?:ChargenScenarios.ItemListInput, callback?: fun():ChargenScenarios.ItemList }
function Loadouts.register(e)
    logger:debug("Registering loadout %s", e.id)
    local itemList
    if e.itemList then
        itemList = ItemList:new(e.itemList)
    end
    Loadouts.registeredLoadouts[e.id] = function()
        if itemList then
            return itemList
        end
        return e.callback()
    end
end

---Get a loadout by id
---@param id string
---@return ChargenScenarios.ItemList?
function Loadouts.get(id)
    return Loadouts.registeredLoadouts[id]()
end

---@return ChargenScenarios.ItemList[]
function Loadouts.getLoadouts()
    logger:debug("Getting loadouts")
    local loadouts = {}
    for _, callback in pairs(Loadouts.registeredLoadouts) do
        table.insert(loadouts, callback())
    end
    logger:debug("- Returned %s loadouts", #loadouts)
    return loadouts
end

---Higher priority goes first
---@param a ChargenScenarios.ItemList
---@param b ChargenScenarios.ItemList
local function sortLoadoutsByPriority(a, b)
    return a.priority > b.priority
end

function Loadouts.doItems()
    logger:debug("Adding loadout items")
    local loadouts = Loadouts.getLoadouts()
    table.sort(loadouts, sortLoadoutsByPriority)
    for _, itemList in ipairs(loadouts) do
        itemList:doItems()
    end
    logger:debug("Added loadout items")
end


local function playerRaceCanEquip(item)
    if tes3.player.object.race.isBeast then
        return item.isUsableByBeasts ~= false
    else
        return true
    end
end

---@param item ChargenScenarios.ItemPickItem
local function isEquippableType(item)
    return item.objectType == tes3.objectType.armor
        or item.objectType == tes3.objectType.clothing
        or item.objectType == tes3.objectType.weapon
end

---@param item ChargenScenarios.ItemPickItem
local function playerCanEquip(item)
    return isEquippableType(item)
        and playerRaceCanEquip(item)
end

---@param armor tes3armor
local function getArmorValue(armor)
    return armor.armorRating
end

---@param item ChargenScenarios.ItemPickItem
local function getOtherValue(item)
    return item.value
end

local function getWeaponValue(weapon)
    return weapon.chopMax + weapon.slashMax + weapon.thrustMax
end

function Loadouts.getBestItemInSlot(targetItemType, slot)
    local bestItem = nil
    local bestValue = 0
    for _, stack in pairs(tes3.player.object.inventory) do
        local validSlot = slot == nil or stack.object.slot == slot
        if validSlot then
            local itemType = stack.object.objectType
            if itemType == targetItemType then
                local value = 0
                if itemType == tes3.objectType.armor then
                    value = getArmorValue(stack.object)
                elseif itemType == tes3.objectType.weapon then
                    value = getWeaponValue(stack.object)
                else
                    value = getOtherValue(stack.object)
                end
                if value > bestValue then
                    bestItem = stack.object
                    bestValue = value
                end
            end
        end
    end
    return bestItem
end

function Loadouts.equipBestItemForEachSlot()
    logger:debug("Equipping best item for each slot")

    local itemsToEquip = {}

    --clothing
    for _, slot in pairs(tes3.clothingSlot) do
        local item = Loadouts.getBestItemInSlot(tes3.objectType.clothing, slot)
        if item then
            if playerCanEquip(item) then
                logger:debug("Adding best armor %s to equip list", item.id)
                table.insert(itemsToEquip, item)
            else
                logger:debug("Beast - cannot equip best clothing %s", item.id)
            end
        end
    end
    --armor
    for _, slot in pairs(tes3.armorSlot) do
        local item = Loadouts.getBestItemInSlot(tes3.objectType.armor, slot)
        if item then
            local isShield = item.objectType == tes3.objectType.armor
                and item.slot == tes3.armorSlot.shield

            if playerCanEquip(item) and not isShield then
                logger:debug("Adding best armor %s to equip list", item.id)
                table.insert(itemsToEquip, item)
            else
                logger:debug("not equipping armor %s", item.id)
            end
        end
    end
    --weapon
    local item = Loadouts.getBestItemInSlot(tes3.objectType.weapon)
    if item then
        logger:debug("Adding best weapon %s to equip list", item.id)
        table.insert(itemsToEquip, item)
    end

    --Stagger tes3.equip, one item at a time
    local function processItem(item, index)
        if item then
            logger:debug("Equipping item %s", item.id)
            tes3.equip{ reference = tes3.player, item = item.id }
            timer.delayOneFrame(function()
                if index < #itemsToEquip then
                    processItem(itemsToEquip[index + 1], index + 1)
                else
                    logger:debug("Finished equipping items")
                end
            end)
        else
            logger:debug("Finished equipping items")
        end
    end
    if #itemsToEquip > 0 then
        logger:debug("Equipping %s items", #itemsToEquip)
        processItem(itemsToEquip[1], 1)
    else
        logger:debug("No items to equip")
    end
end

local commonClothing = {
    {
        id = "common_pants_01",
        objectType = tes3.objectType.clothing,
        slot = tes3.clothingSlot.pants,
    },
    {
        id = "common_shoes_01",
        objectType = tes3.objectType.clothing,
        slot = tes3.clothingSlot.shoes,
        alt = {
            objectType = tes3.objectType.armor,
            slot = tes3.armorSlot.boots
        }
    },
    {
        id = "common_shirt_01",
        objectType = tes3.objectType.clothing,
        slot = tes3.clothingSlot.shirt,
    }
}

---Removes default clothing from the player
function Loadouts.removeCommonClothing()
    logger:debug("Removing common clothing")
    for _, item in ipairs(commonClothing) do
        tes3.removeItem{
            reference = tes3.player,
            item = item.id,
            playSound = false
        }
    end
end

return Loadouts