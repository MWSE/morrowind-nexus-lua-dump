local core = require("openmw.core")

local self = require("openmw.self")
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')
local util = require('openmw.util')
local async = require('openmw.async')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local settings = storage.playerSection("SettingsQuickSelect")
local mouseSettings = storage.playerSection("SettingsQuickSelectMouse")  -- Mouse settings storage
local gamepadSettings = storage.playerSection("SettingsQuickSelectGamepad")
local keyboardSettings = storage.playerSection("SettingsQuickSelectKeyboard")
local utility = require("scripts.QuickSelect.qs_utility")
local storedItems

local function getFavoriteItems()
    if not storedItems then
        storedItems = {}
    end
    -- Ensure we have up to 50 slots for expanded hotbars
    for i = 1, 50, 1 do
        if not storedItems[i] then
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
local function saveStoredItemData(id, slot)
    getFavoriteItems()
    --print(id, slot)
    deleteStoredItemData(slot   )
    storedItems[slot].item      = id
end
local function saveStoredSpellData(spellId, spellType, slot)
    getFavoriteItems()
    deleteStoredItemData(slot   )
    storedItems[slot].spellType = spellType
    storedItems[slot].spell     = spellId
end
local function saveStoredEnchantData(enchantId, itemId, slot)
    getFavoriteItems()
    deleteStoredItemData(slot   )
    storedItems[slot].spellType = "Enchant"
    storedItems[slot].enchantId = enchantId
    storedItems[slot].itemId    = itemId
end
local function findItem(id)
    for index, value in ipairs(types.Actor.inventory(self)) do

    end
end
local function isSlotEquipped(slot)
    local item = getFavoriteItemData(slot)
    if item then
        if item.spell and not item.enchantId then
            local spell = types.Actor.getSelectedSpell(self)
            if not spell then return false end
            return spell == item.spell
        elseif item.enchantId then
            local realItem = types.Actor.inventory(self):find(item.itemId)
            if not realItem then return false end

            -- First check if it's currently selected as the active magic castable
            local selectedEnchant = types.Actor.getSelectedEnchantedItem(self)
            if selectedEnchant and selectedEnchant.recordId == realItem.recordId then
                return true
            end
            
            -- Also check if it's physically equipped on the body (e.g., armor, offhand shield, ring)
            local equip = types.Actor.equipment(self)
            for _, eqItem in pairs(equip) do
                 if eqItem.recordId == realItem.recordId then
                      return true
                 end
            end
            
            return false
        elseif item.item then
            local equip = types.Actor.equipment(self)
            for _, eqItem in pairs(equip) do
                 if eqItem.recordId == item.item then
                      return true
                 end
            end
            return false
        end
    end
    return false
end
local function getEquipped(item)
    local slot = utility.findSlot(item)
    if not slot then return nil end
    local equip = types.Actor.equipment(self)
    if equip[slot] and equip[slot].recordId == item.recordId then
        return slot
    end
    return nil
end
local function equipSlot(slot)
    local item = getFavoriteItemData(slot)
    if item then
        if item.spell and not item.enchantId then
            local currentSpell = types.Actor.getSelectedSpell(self)
            if currentSpell == item.spell then
                if settings:get("unEquipOnHotkey") then
                    types.Actor.clearSelectedCastable(self)
                end
                -- If it's already the spell, returning prevents setSelectedSpell from toggling it off 
                -- and allows Quick Cast mods to fire correctly.
                return
            end

            types.Actor.setSelectedSpell(self, item.spell)
            
            async:newUnsavableSimulationTimer(0.1, function()
                if types.Actor.getStance(self) ~= types.Actor.STANCE.Spell then
                    types.Actor.setStance(self, types.Actor.STANCE.Spell)
                end
            end)
        elseif item.enchantId then
            local equip = types.Actor.equipment(self)
            local realItem = types.Actor.inventory(self):find(item.itemId)
            if not realItem then return end
            
            local currentEnchantedItem = types.Actor.getSelectedEnchantedItem(self)
            if currentEnchantedItem and currentEnchantedItem.id == realItem.id then
                 if settings:get("unEquipOnHotkey") then
                     types.Actor.clearSelectedCastable(self)
                 end
                 return
            end
            
            types.Actor.setSelectedEnchantedItem(self, realItem)

            async:newUnsavableSimulationTimer(0.1, function()
                if types.Actor.getStance(self) ~= types.Actor.STANCE.Spell then
                    types.Actor.setStance(self, types.Actor.STANCE.Spell)
                end
            end)
        elseif item.item then
            local realItem = types.Actor.inventory(self):find(item.item)
            if not realItem then return end
            
            local isWeaponLike = realItem.type == types.Weapon
                or realItem.type == types.Lockpick
                or realItem.type == types.Probe
                
            if isWeaponLike and types.Actor.getStance(self) == types.Actor.STANCE.Spell then
                local previouslySelectedSpell = types.Actor.getSelectedSpell(self)
                
                -- Only unequip and re-equip actual Spells to ensure QuickCast mods don't trigger for enchanted items!
                if previouslySelectedSpell then
                    types.Actor.clearSelectedCastable(self)
                    
                    async:newUnsavableSimulationTimer(0.5, function()
                        types.Actor.setSelectedSpell(self, previouslySelectedSpell)
                    end)
                end
            end
            
            local equipped = getEquipped(realItem)
            if not equipped then
                -- Use GlobalEvent to trigger native OpenMW equip logic
                core.sendGlobalEvent('UseItem', { object = realItem, actor = self })
            elseif equipped then
                if isWeaponLike and types.Actor.getStance(self) ~= types.Actor.STANCE.Weapon then
                    -- already equipped but sheathed — just draw it, stance set below
                elseif settings:get("unEquipOnHotkey") then
                    local equip = types.Actor.equipment(self)
                    equip[equipped] = nil
                    types.Actor.setEquipment(self, equip)
                end
            end
            
            -- Only forcefully set weapon stance if they equipped a physical weapon (not armor/clothing)
            if isWeaponLike then
                async:newUnsavableSimulationTimer(0.3, function()
                    types.Actor.setStance(self, types.Actor.STANCE.Weapon)
                end)
            end
        end
    end

    async:newUnsavableSimulationTimer(0.1, function()
        I.QuickSelect_Hotbar.drawHotbar()
    end)
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
        deleteStoredItemData = deleteStoredItemData,
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
