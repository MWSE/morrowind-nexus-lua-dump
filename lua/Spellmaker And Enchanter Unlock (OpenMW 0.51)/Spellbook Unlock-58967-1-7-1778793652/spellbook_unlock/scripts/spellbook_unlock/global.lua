--[[
    spellbook_unlock/global.lua  (GLOBAL script)

    Receives events from the player-local script and performs world mutations
    that require openmw.world (which is only available in global scripts):
      - SBU_Inject : creates the temp spell record and adds it to the player
      - SBU_Remove : removes the temp spell from the player

    DIAGNOSTIC BUILD — watch openmw.log for [SpellbookUnlock] lines.
--]]

local core  = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')

local SPELL_TYPE = core.magic.SPELL_TYPE
local magic      = core.magic

print('[SpellbookUnlock][global] Script loaded. API revision: ' .. tostring(core.API_REVISION))

local TEMP_SPELL_ID   = 'spellbook_unlock_temp_omnispell'
local TEMP_SPELL_NAME = '1_temp_spell_spellbook_unlock'

-- Store the full record object returned by world.createRecord.
-- The generated id (e.g. "Generated:0xc92c") is not a reliable removal key,
-- so we pass the record object directly to spells:add and spells:remove.
local registeredRecord = nil

-- ---------------------------------------------------------------------------
-- SBU_Inject
-- data.player  : the player GameObject
-- data.effects : list of MagicEffectWithParams tables built by player.lua
-- ---------------------------------------------------------------------------
local function onInject(data)
    local player = data.player
    local effects = data.effects
    print('[SpellbookUnlock][global] SBU_Inject received. Effects to add: ' .. #effects)

    if not registeredRecord then
        local existingRecord = magic.spells.records[TEMP_SPELL_ID]
        print('[SpellbookUnlock][global] Existing record: ' .. tostring(existingRecord))

        if existingRecord then
            registeredRecord = existingRecord
            print('[SpellbookUnlock][global] Reusing existing record id: ' .. tostring(registeredRecord.id))
        else
            print('[SpellbookUnlock][global] Calling magic.spells.createRecordDraft...')
            local ok, draft = pcall(function()
                return magic.spells.createRecordDraft({
                    id             = TEMP_SPELL_ID,
                    name           = TEMP_SPELL_NAME,
                    type           = SPELL_TYPE.Spell,
                    effects        = effects,
                    cost           = 0,
                    alwaysSucceeds = true,
                    noAutocalc     = true,
                })
            end)
            if not ok then
                print('[SpellbookUnlock][global] ERROR in createRecordDraft: ' .. tostring(draft))
                return
            end
            print('[SpellbookUnlock][global] Draft OK. Calling world.createRecord...')
            local ok2, record = pcall(function()
                return world.createRecord(draft)
            end)
            if not ok2 then
                print('[SpellbookUnlock][global] ERROR in world.createRecord: ' .. tostring(record))
                return
            end
            registeredRecord = record
            print('[SpellbookUnlock][global] world.createRecord succeeded. Registered id: ' .. tostring(record.id))
        end
    else
        print('[SpellbookUnlock][global] Record already registered: ' .. tostring(registeredRecord.id))
    end

    print('[SpellbookUnlock][global] Adding spell "' .. tostring(registeredRecord.id) .. '" to player...')
    local ok3, err3 = pcall(function()
        types.Actor.spells(player):add(registeredRecord)
    end)
    if not ok3 then
        print('[SpellbookUnlock][global] ERROR adding spell: ' .. tostring(err3))
        return
    end
    print('[SpellbookUnlock][global] Spell added successfully.')
end

-- ---------------------------------------------------------------------------
-- SBU_Remove
-- data.player : the player GameObject
-- ---------------------------------------------------------------------------
local function onRemove(data)
    local player = data.player
    print('[SpellbookUnlock][global] SBU_Remove received. Scanning for "' .. TEMP_SPELL_NAME .. '"...')
    local spells = types.Actor.spells(player)
    local removed = 0
    for _, spell in pairs(spells) do
        if spell.name == TEMP_SPELL_NAME then
            print('[SpellbookUnlock][global] Found spell id=' .. tostring(spell.id) .. ', removing...')
            local ok, err = pcall(function() spells:remove(spell.id) end)
            if not ok then
                print('[SpellbookUnlock][global] ERROR removing: ' .. tostring(err))
            else
                removed = removed + 1
            end
        end
    end
    print('[SpellbookUnlock][global] Removed ' .. removed .. ' spell(s).')
end

-- ---------------------------------------------------------------------------
return {
    eventHandlers = {
        SBU_Inject = onInject,
        SBU_Remove = onRemove,
    },
}
