local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local input = require('openmw.input')
local bindingTypeEnum = require('Scripts.CustomSpellBindings.bindingTypeEnum')

local _spellHotkeys = {}

local function getAvailableSpellById(id)
    for i, spell in ipairs(types.Actor.spells(self)) do
        if spell.id == id then
            return spell
        end
    end

    return nil
end

local function getSpellHotkeyByKeyCode(keyCode)
    for i, spellHotkey in ipairs(_spellHotkeys) do
        if spellHotkey.keyCode == keyCode then
            return spellHotkey
        end
    end

    return nil
end

local function getSpellHotkeyIndexByKeyCode(keyCode)
    for i, spellHotkey in ipairs(_spellHotkeys) do
        if spellHotkey.keyCode == keyCode then
            return i
        end
    end

    return nil
end

local function addSpellBinding(key, spell, bindingType)
    local existingHotkeyIndex = getSpellHotkeyIndexByKeyCode(key.code)

    if existingHotkeyIndex ~= nil then
        table.remove(_spellHotkeys, existingHotkeyIndex)
    end

    local keySymbol = input.getKeyName(key.code)
    local spellHotkey

    if bindingType == bindingTypeEnum.Spell then
        spellHotkey = {
            keyCode = key.code,
            keySymbol = keySymbol,
            spellId = spell.id,
            spellName = spell.name,
            bindingType = bindingType
        }

        ui.showMessage(string.format('Created a binding for key %s and spell: %s', keySymbol, spellHotkey.spellName))
    else
        local spellRecord = spell.type.record(spell)
        spellHotkey = {
            keyCode = key.code,
            keySymbol = keySymbol,
            spellId = spell.recordId,
            spellName = spellRecord.name,
            bindingType = bindingType
        }

        ui.showMessage(string.format('Created a binding for key %s and enchanted item: %s', keySymbol, spellHotkey.spellName))
    end

    table.insert(_spellHotkeys, spellHotkey)
end

local function removeHotkeyByIndex(hotkeyIndex)
    table.remove(_spellHotkeys, hotkeyIndex)
end

local function selectSpellByKeycode(keyCode)
    local spellHotkey = getSpellHotkeyByKeyCode(keyCode)

    if spellHotkey == nil then
        return
    end

    if spellHotkey.bindingType == nil or spellHotkey.bindingType == bindingTypeEnum.Spell then
        local spell = getAvailableSpellById(spellHotkey.spellId)
        types.Actor.setSelectedSpell(self, spell)
    else
        types.Actor.setSelectedEnchantedItem(self, spellHotkey.spellId)
    end
end

local function getSpellhotkeys()
    return _spellHotkeys
end

local function setSpellhotkeys(spellHotkeys)
    _spellHotkeys = spellHotkeys
end

return {
    removeHotkeyByIndex = removeHotkeyByIndex,
    addSpellBinding = addSpellBinding,
    selectSpellByKeycode = selectSpellByKeycode,
    getSpellHotkeyByKeyCode = getSpellHotkeyByKeyCode,
    getSpellhotkeys = getSpellhotkeys,
    setSpellhotkeys = setSpellhotkeys,
}