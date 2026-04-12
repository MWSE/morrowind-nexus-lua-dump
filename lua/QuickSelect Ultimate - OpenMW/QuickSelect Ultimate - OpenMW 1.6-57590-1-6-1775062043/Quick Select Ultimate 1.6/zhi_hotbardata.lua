-- Zerkish Hotkeys Improved - zhi_hotbardata.lua
-- This file works with the actual data part of the hotbars

local core = require('openmw.core')
local types = require('openmw.types')
local I = require('openmw.interfaces')

local HOTKEY_TYPE = {
    -- Nothing Bound
    None = 1,

    -- Inventory Item
    Item = 2,

    -- Known spell or power
    Spell = 3,

    -- Spell that comes from an item
    SpellEnchantment = 4,
}

local hotbarData = {}

local function createHotkeyData(hotbarNum, hotbarKey)
    return {
        --hotkeyType = hotkeyType,

        hotbar = {
            hotbarNum = hotbarNum,
            hotbarKey = hotbarKey,
        },
        data = {},
        -- data = {
        --     --id = id,
        --     item = {
        --         recordId = nil,
        --         typeStr = nil,

        --         -- when this is set, we mean to equip the enchantment, not the item.
        --         enchantment = {
        --             id = nil,
        --             type = nil,
        --         }
        --     },
        --     spell = {
        --         spellId = nil,
        --     },
        -- }
    }
end

local function createHotbar(barNum, numKeys)
    local data = {}

    for i=1,numKeys do
        data[i] = createHotkeyData(barNum, i)
    end

    return data
end

local function resetHotkey(hotkeyData)
    hotkeyData.data.id = nil
    hotkeyData.data.item = nil
    hotkeyData.data.spell = nil
end

local function getHotkeyData(bar, key)
    if type(bar) ~= 'number' or type(key) ~= 'number' then return nil end
    if not (hotbarData and hotbarData[bar]) then return nil end

    return hotbarData[bar][key]
end


local function loadHotbarDataV1(loadData)
    if loadData.hotbarData == nil then
        return nil
    end

    local data = {}

    for i=1,I.ZHI.MAX_HOTBARS do
        local numKeys = i == 1 and 10 or 9
        data[i] = createHotbar(i, i == 1 and 10 or 9)
    end

    -- each bar
    for barIdx, bar in ipairs(loadData.hotbarData) do
        for keyIdx, hotkey in ipairs(bar) do
            data[barIdx][keyIdx].data = hotkey.data
            if not hotkey.data.item and not hotkey.data.spell then
                data[barIdx][keyIdx].data.id = nil
            end
        end
    end

    return data
end

return {
    HOTKEY_TYPE = HOTKEY_TYPE,

    createHotkeyData = createHotkeyData,
    getHotkeyData = getHotkeyData,
    resetHotkeyData = resetHotkey,

    -- Empty Initialize hotbars
    initHotbars = function()
        hotbarData = {}

        for i=1,I.ZHI.MAX_HOTBARS do
            hotbarData[i] = createHotbar(i, i == 1 and 10 or 9)
        end
    end,

    foreachHotbar = function(func)
        for i=1, I.ZHI.MAX_HOTBARS do
            if hotbarData[i] then
                func(i)
            end
        end
    end,

    foreachHotkey = function(hotbar, func)
        assert(hotbarData and hotbarData[hotbar])
        local max = hotbar == 1 and 10 or 9
        for i=1, max do
            func(hotbar, i, getHotkeyData(hotbar, i))
        end
    end,

    foreachBarAndKey = function(func)
        for i=1,I.ZHI.MAX_HOTBARS do 
            local max = (i == 1) and 10 or 9

            for j=1,max do
                func(i, j, getHotkeyData(i, j))
            end
        end
    end,

    -- set hotkey from item
    setItemHotkey = function(hotbar, key, item, enchantment)
        local hotkeyData = getHotkeyData(hotbar, key)
        if hotkeyData == nil then
            print('ZHI setSpellHotkey invalid hotbar/key', hotbar, key)
            return
        end
        -- Guard against setting invalid items
        if not (item and types.Item.objectIsInstance(item) and item:isValid()) then
            print('ZHI setItemHotkey failed -  (item and types.Item.objectIsInstance(item)', item)
            return
        end

        resetHotkey(hotkeyData)
        
        hotkeyData.data.id = item.id
        hotkeyData.data.item = {
            recordId = item.recordId,
            typeStr = tostring(item.type),
        }

        if enchantment then
            hotkeyData.data.item.enchantment = {
                id = enchantment.id,
                type = enchantment.type,
            }
        end
    end,

    -- set hotkey from spell (or enchantment)
    setSpellHotkey = function(hotbar, key, spell)
        local hotkeyData = getHotkeyData(hotbar, key)
        if hotkeyData == nil then
            print('ZHI setSpellHotkey invalid hotbar/key', hotbar, key)
            return
         end

        -- Attempt to validate the spellId
        if (not spell) or (not spell.id) or core.magic.spells.records[spell.id].id ~= spell.id then
            print('ZHI setSpellHotkey invalid spell/spellId', spell, spell and spell.id or nil)
            return
        end

        resetHotkey(hotkeyData)

        hotkeyData.data.id = spell.id
        hotkeyData.data.spell = {
            spellId = spell.id
        }
    end,

    saveHotbarData = function(saveData)
        saveData.hotbarData = hotbarData
    end,

    loadHotbarData = function(loadData)
        if (loadData.version == 1) then
            local result = loadHotbarDataV1(loadData)
            if result then
                hotbarData = result
            else
                print('ZHI loadHotbarData got nil back')
            end
        end
    end,


}