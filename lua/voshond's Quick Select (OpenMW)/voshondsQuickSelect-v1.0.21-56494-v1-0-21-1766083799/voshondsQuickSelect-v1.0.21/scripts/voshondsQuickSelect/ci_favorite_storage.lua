local core = require("openmw.core")

local self = require("openmw.self")
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')
local util = require('openmw.util')
local async = require('openmw.async')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local settings = storage.playerSection("SettingsVoshondsQuickSelect")

local utility = require("scripts.voshondsquickselect.qs_utility")
local Debug = require("scripts.voshondsquickselect.qs_debug")
local storedItems

local function getFavoriteItems()
    if not storedItems then
        storedItems = {}
        for i = 1, 30, 1 do
            storedItems[i] = { num = i, item = nil }
        end
    end
    return storedItems
end
local function getFavoriteItemData(slot)
    getFavoriteItems()
    return storedItems[slot]
end
local function deleteStoredItemData(slot)
    getFavoriteItems()
    storedItems[slot].spell     = nil
    storedItems[slot].spellType = nil
    storedItems[slot].enchantId = nil
    storedItems[slot].itemId    = nil
    storedItems[slot].item      = nil
end
local function triggerHotbarRedraw()
    -- Do NOT call storage.save() as it doesn't exist in OpenMW API
    -- Remove: storage.save()

    -- First immediate redraw attempt
    if I.QuickSelect_Hotbar then
        Debug.storage("Immediate hotbar redraw triggered")
        local success, err = pcall(function()
            I.QuickSelect_Hotbar.drawHotbar()
        end)
        if not success then
            Debug.error("QuickSelect_Storage", "Error in immediate redraw: " .. tostring(err))
        end
    end

    -- Second delayed redraw to ensure UI is updated
    async:newUnsavableSimulationTimer(0.1, function()
        if I.QuickSelect_Hotbar then
            Debug.storage("Delayed hotbar redraw triggered")
            local success, err = pcall(function()
                -- Clear any existing UI before redrawing
                I.QuickSelect_Hotbar.resetFade()
                I.QuickSelect_Hotbar.drawHotbar()
            end)
            if not success then
                Debug.error("QuickSelect_Storage", "Error in delayed redraw: " .. tostring(err))
            end
        else
            Debug.error("QuickSelect_Storage", "QuickSelect_Hotbar interface not available for redraw")
        end
    end)

    -- Final backup redraw after longer delay
    async:newUnsavableSimulationTimer(0.3, function()
        if I.QuickSelect_Hotbar then
            Debug.storage("Final hotbar redraw triggered")
            local success, err = pcall(function()
                I.QuickSelect_Hotbar.drawHotbar()
            end)
            if not success then
                Debug.error("QuickSelect_Storage", "Error in final redraw: " .. tostring(err))
            end
        end
    end)
end
local function saveStoredItemData(id, slot)
    getFavoriteItems()
    Debug.storage("Saving item " .. tostring(id) .. " to slot " .. tostring(slot))
    deleteStoredItemData(slot)
    storedItems[slot].item = id

    -- Check if the item is in the inventory and has an enchantment
    local realItem = types.Actor.inventory(self):find(id)
    if realItem then
        -- Store record ID for future reference
        storedItems[slot].recordId = realItem.recordId

        -- Check if item has an enchantment
        local record = realItem.type.records[realItem.recordId]
        if record and record.enchant and record.enchant ~= "" then
            -- Store enchantment ID for future reference
            storedItems[slot].itemEnchantId = record.enchant

            -- Try to store charge information if available
            if types.Item.getEnchantmentCharge then
                local charge = types.Item.getEnchantmentCharge(realItem)
                if charge then
                    Debug.storage("Stored charge information from types.Item.getEnchantmentCharge: " .. tostring(charge))
                    storedItems[slot].lastKnownCharge = charge
                end
            elseif types.Item.itemData and types.Item.itemData(realItem) then
                local itemData = types.Item.itemData(realItem)
                if itemData and itemData.charge then
                    Debug.storage("Stored charge information: " .. tostring(itemData.charge))
                    storedItems[slot].lastKnownCharge = itemData.charge
                end
            elseif types.Item.charge then
                local charge = types.Item.charge(realItem)
                if charge then
                    Debug.storage("Stored charge information from types.Item.charge: " .. tostring(charge))
                    storedItems[slot].lastKnownCharge = charge
                end
            end
        end
    end

    triggerHotbarRedraw()
end
local function saveStoredSpellData(spellId, spellType, slot)
    getFavoriteItems()
    deleteStoredItemData(slot)
    storedItems[slot].spellType = spellType
    storedItems[slot].spell     = spellId

    triggerHotbarRedraw()
end
local function saveStoredEnchantData(enchantId, itemId, slot)
    getFavoriteItems()
    deleteStoredItemData(slot)
    storedItems[slot].spellType = "Enchant"
    storedItems[slot].enchantId = enchantId
    storedItems[slot].itemId    = itemId
    Debug.storage("Saving enchanted item " .. tostring(itemId) .. " to slot " .. tostring(slot))

    triggerHotbarRedraw()
end
local function findItem(id)
    for index, value in ipairs(types.Actor.inventory(self)) do

    end
end
local function isSlotEquipped(slot)
    local item = getFavoriteItemData(slot)
    if not item then return false end

    -- Log slot being checked for equipped status
    Debug.storage("Checking if slot " .. slot .. " is equipped")

    -- First, handle spells
    if item.spell and not item.enchantId then
        local spell = types.Actor.getSelectedSpell(self)
        if not spell then return false end

        -- Log the comparison
        local isMatched = (spell.id == item.spell)
        Debug.storage("Spell comparison: " ..
            tostring(spell.id) .. " == " .. tostring(item.spell) .. " is " .. tostring(isMatched))
        return isMatched

        -- Then handle enchanted items
    elseif item.enchantId then
        Debug.storage("Checking enchanted item in slot " .. slot)
        local enchantedItem = types.Actor.getSelectedEnchantedItem(self)
        if not enchantedItem then return false end

        local realItem = types.Actor.inventory(self):find(item.itemId)
        if not realItem then return false end

        local isMatched = (enchantedItem.recordId == realItem.recordId)
        Debug.storage("Enchanted item comparison: " ..
            tostring(enchantedItem.recordId) .. " == " .. tostring(realItem.recordId) .. " is " .. tostring(isMatched))
        return isMatched

        -- Finally handle regular items
    elseif item.item then
        local equip = types.Actor.equipment(self)
        local realItem = types.Actor.inventory(self):find(item.item)
        if not realItem then
            Debug.storage("Item not found in inventory: " .. tostring(item.item))
            return false
        end

        -- Special handling for Lockpicks, Probes, and Lights
        if realItem.type == types.Lockpick or realItem.type == types.Probe or realItem.type == types.Light then
            -- Check if the item is equipped in any slot
            for slotName, equippedItem in pairs(equip) do
                if equippedItem == realItem then
                    Debug.storage("Item " .. tostring(item.item) .. " is equipped in slot " .. tostring(slotName))
                    return true
                end
            end
            Debug.storage("Item " .. tostring(item.item) .. " is not equipped in any slot")
            return false
        else
            -- Normal handling for other item types
            local itemSlot = utility.findSlot(realItem)
            if not itemSlot then
                Debug.storage("No equipment slot found for item: " .. tostring(item.item))
                return false
            end

            local isEquipped = (equip[itemSlot] == realItem)
            Debug.storage("Item " ..
                tostring(item.item) .. " equipped in slot " .. tostring(itemSlot) .. ": " .. tostring(isEquipped))
            return isEquipped
        end
    end

    return false
end
local function getEquipped(item)
    local equip = types.Actor.equipment(self)
    for index, value in pairs(equip) do
        if value == item then
            return index
        end
    end
    return nil
end
local function equipSlot(slot)
    local item = getFavoriteItemData(slot)
    if item then
        if item.spell and not item.enchantId then
            types.Actor.clearSelectedCastable(self)
            types.Actor.setSelectedSpell(self, item.spell)
            -- Always set stance to Spell when selecting a spell
            types.Actor.setStance(self, types.Actor.STANCE.Spell)
            Debug.storage("Set selected spell to " .. tostring(item.spell))
        elseif item.enchantId then
            -- This is now handled in QuickSelect_P.lua's onInputAction function
            -- This code is kept for compatibility with other parts of the code that may call equipSlot directly
            local realItem = types.Actor.inventory(self):find(item.itemId)
            if not realItem then return end
            types.Actor.setSelectedEnchantedItem(self, realItem)
            -- Always set stance to Spell when selecting an enchanted item
            types.Actor.setStance(self, types.Actor.STANCE.Spell)
            Debug.storage("Set selected enchanted item to " .. tostring(item.itemId))
        elseif item.item then
            local realItem = types.Actor.inventory(self):find(item.item)
            if not realItem then return end
            local equipped = getEquipped(realItem)

            if not equipped then
                -- Equip the item
                Debug.storage("Equipping item " .. tostring(item.item))
                core.sendGlobalEvent('UseItem', { object = realItem, actor = self })

                if realItem.type == types.Weapon or realItem.type == types.Lockpick or realItem.type == types.Probe then
                    async:newUnsavableSimulationTimer(0.1, function()
                        types.Actor.setStance(self, types.Actor.STANCE.Weapon)
                    end)
                end
            else
                -- Item is already equipped
                if realItem.type == types.Light then
                    -- For lights, always unequip when already equipped
                    Debug.storage("Unequipping light " .. tostring(item.item))
                    local equip = types.Actor.equipment(self)
                    equip[equipped] = nil
                    types.Actor.setEquipment(self, equip)
                elseif realItem.type == types.Weapon or realItem.type == types.Lockpick or realItem.type == types.Probe then
                    -- Toggle weapon stance for weapons, lockpicks, and probes
                    if types.Actor.getStance(self) == types.Actor.STANCE.Weapon then
                        Debug.storage("Setting stance to Nothing")
                        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
                    else
                        Debug.storage("Setting stance to Weapon")
                        types.Actor.setStance(self, types.Actor.STANCE.Weapon)
                    end

                    -- If autoUnequipSheathedWeapons is enabled and we're in Nothing stance, unequip
                    if settings:get("autoUnequipSheathedWeapons") and types.Actor.getStance(self) == types.Actor.STANCE.Nothing then
                        Debug.storage("Unequipping weapon due to autoUnequipSheathedWeapons setting")
                        local equip = types.Actor.equipment(self)
                        equip[equipped] = nil
                        types.Actor.setEquipment(self, equip)
                    end
                elseif realItem.type == types.Armor or realItem.type == types.Clothing then
                    -- For armor and clothing, check toggleEquipment setting
                    if settings:get("toggleEquipment") then
                        Debug.storage("Unequipping equipment " .. tostring(item.item) .. " due to toggleEquipment setting")
                        local equip = types.Actor.equipment(self)
                        equip[equipped] = nil
                        types.Actor.setEquipment(self, equip)
                    else
                        Debug.storage("Equipment already equipped and toggleEquipment is disabled, doing nothing")
                    end
                end
            end
        end
    end

    -- Force multiple redraws to ensure UI updates correctly
    Debug.storage("Starting redraw sequence after equip action")
    triggerHotbarRedraw()
end
return {

    interfaceName = "QuickSelect_Storage",
    interface = {
        saveStoredItemData    = saveStoredItemData,
        getFavoriteItemData   = getFavoriteItemData,
        getFavoriteItems      = getFavoriteItems,
        saveStoredSpellData   = saveStoredSpellData,
        equipSlot             = equipSlot,
        saveStoredEnchantData = saveStoredEnchantData,
        isSlotEquipped        = isSlotEquipped,
        deleteStoredItemData  = deleteStoredItemData,
    },
    engineHandlers = {
        onSave = function()
            return { storedItems = storedItems }
        end,
        onLoad = function(data)
            storedItems = data.storedItems
        end,
    }
}
