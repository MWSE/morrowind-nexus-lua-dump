local self = require('openmw.self')
local types = require('openmw.types')

local M = {}

local VAMPIRISM_NAME = 'vampirism'
local VAMPIRE_SPELL_IDS = {
    'vampirism',
    'vampire blood aundae',
    'vampire blood berne',
    'vampire blood quarra',
    'vampire_blood_aundae',
    'vampire_blood_berne',
    'vampire_blood_quarra',
    'vampire aundae specials',
    'vampire berne specials',
    'vampire quarra specials',
    'vampire_aundae_specials',
    'vampire_berne_specials',
    'vampire_quarra_specials',
    'vampire_sun_damage',
}
local VAMPIRE_SPELL_ID_LOOKUP = {}
for _, spellId in ipairs(VAMPIRE_SPELL_IDS) do
    VAMPIRE_SPELL_ID_LOOKUP[spellId] = true
end

local function normalizeKey(value)
    if value == nil then
        return ''
    end
    local text = tostring(value)
    text = text:gsub('^%s+', ''):gsub('%s+$', '')
    return string.lower(text)
end

local function isVampireText(value)
    local text = normalizeKey(value)
    if text == '' then
        return false
    end
    return VAMPIRE_SPELL_ID_LOOKUP[text] == true
end

local function isVampireSpellEntry(entry)
    if type(entry) == 'string' then
        return isVampireText(entry)
    end
    if type(entry) ~= 'table' and type(entry) ~= 'userdata' then
        return false
    end

    local function readEntryField(fieldName)
        local ok, value = pcall(function()
            return entry[fieldName]
        end)
        if ok then
            return value
        end
        return nil
    end

    local entryName = normalizeKey(readEntryField('name'))
    if entryName == VAMPIRISM_NAME then
        return true
    end

    local entryId = readEntryField('id')
    local entryRecordId = readEntryField('recordId')
    local entrySpellId = readEntryField('spellId')
    local nestedSpell = readEntryField('spell')
    if type(nestedSpell) == 'table' or type(nestedSpell) == 'userdata' then
        local okNestedId, nestedId = pcall(function()
            return nestedSpell.id
        end)
        if okNestedId and isVampireText(nestedId) then
            return true
        end
        local okNestedRecordId, nestedRecordId = pcall(function()
            return nestedSpell.recordId
        end)
        if okNestedRecordId and isVampireText(nestedRecordId) then
            return true
        end
        local okNestedName, nestedName = pcall(function()
            return nestedSpell.name
        end)
        if okNestedName and isVampireText(nestedName) then
            return true
        end
    end

    return isVampireText(entryId)
        or isVampireText(entryName)
        or isVampireText(entryRecordId)
        or isVampireText(entrySpellId)
end

local function containerHasVampireSpell(container)
    if container == nil then
        return false
    end

    for _, spellId in ipairs(VAMPIRE_SPELL_IDS) do
        local okLookup, value = pcall(function()
            return container[spellId]
        end)
        if okLookup and value ~= nil then
            return true
        end
    end

    local okCount, count = pcall(function()
        return #container
    end)
    if okCount and type(count) == 'number' and count > 0 then
        for i = 1, count do
            if isVampireSpellEntry(container[i]) then
                return true
            end
        end
    end

    local okPairs, found = pcall(function()
        for key, spell in pairs(container) do
            if isVampireSpellEntry(key) or isVampireSpellEntry(spell) then
                return true
            end
        end
        return false
    end)
    return okPairs and found == true
end

function M.isPlayerVampire()
    local playerObject = self
    if type(types.Actor.objectIsInstance) ~= 'function' or not types.Actor.objectIsInstance(playerObject) then
        playerObject = self.object
        if playerObject == nil or not types.Actor.objectIsInstance(playerObject) then
            return false
        end
    end

    if type(types.NPC.objectIsInstance) == 'function'
        and types.NPC.objectIsInstance(playerObject)
        and type(types.NPC.isVampire) == 'function' then
        local okIsVampire, isVampire = pcall(function()
            return types.NPC.isVampire(playerObject)
        end)
        if okIsVampire and isVampire == true then
            return true
        end
    end

    if type(types.Actor.activeSpells) == 'function' then
        local okActiveSpells, activeSpells = pcall(function()
            return types.Actor.activeSpells(playerObject)
        end)
        if okActiveSpells and activeSpells ~= nil then
            if containerHasVampireSpell(activeSpells) then
                return true
            end
            if type(activeSpells.isSpellActive) == 'function' then
                for _, spellId in ipairs(VAMPIRE_SPELL_IDS) do
                    local okActive, isActive = pcall(function()
                        return activeSpells:isSpellActive(spellId)
                    end)
                    if okActive and isActive == true then
                        return true
                    end
                end
            end
        end
    end

    if type(types.Actor.spells) == 'function' then
        local okSpells, knownSpells = pcall(function()
            return types.Actor.spells(playerObject)
        end)
        if okSpells and containerHasVampireSpell(knownSpells) then
            return true
        end
    end

    return false
end

return M
