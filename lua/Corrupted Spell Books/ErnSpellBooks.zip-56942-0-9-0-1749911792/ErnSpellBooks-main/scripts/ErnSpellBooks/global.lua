--[[
ErnSpellBooks for OpenMW.
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
]] local settings = require("scripts.ErnSpellBooks.settings")
local world = require('openmw.world')
local types = require("openmw.types")
local core = require("openmw.core")
local spellUtil = require("scripts.ErnSpellBooks.spellUtil")
local storage = require('openmw.storage')
local books = require("scripts.ErnSpellBooks.books")
local interfaces = require('openmw.interfaces')
local vfs = require('openmw.vfs')
local localization = core.l10n(settings.MOD_NAME)

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
end

-- Init settings first to init storage which is used everywhere.
settings.initSettings()

-- calls all scripts under /corruptions/
-- we only want to do this once, ever.
-- we also need to block on it, since the ledger needs
-- to be full before we can process events for corrupted spells.
local function requireCorruptions()
    settings.debugPrint("loading corruptions...")
    -- read all built-in corruption scripts and register them.
    -- these are namespaced by their filename.
    -- workaround for a bunch of restrictions.
    for fileName in vfs.pathsWithPrefix("scripts\\" .. settings.MOD_NAME .. "\\corruptions") do
        local baseName = string.match(fileName, '(%a+)[.]lua')
        if baseName ~= nil then
            settings.debugPrint("requiring " .. baseName)
            require("scripts.ErnSpellBooks.corruptions." .. string.lower(baseName))
        end
    end
end
requireCorruptions()

-- bookTracker should map a couple things:
-- ["actor_" .. actorID .. "_spell_" .. spellID] -> {bookRecordID}
-- - this exists so we can tell if a spell has been corrupted
-- ["book_" .. bookRecordID] -> {spell bag}
-- - this actually holds the metadata for the spell
-- - spell bag has: {spellID: <spellID>, corruption: {prefixID: <corruption id>, suffixID: <corruption id>}}
-- ["spell_" .. spellID .. "_" .. prefixID .. "_" .. suffixID] -> {bookRecordID}
-- - this exists so we can re-use book records for identical spells.

local bookTracker = storage.globalSection(settings.MOD_NAME .. "bookTracker")
bookTracker:setLifeTime(storage.LIFE_TIME.Temporary)

local function saveState()
    return bookTracker:asTable()
end

local function loadState(saved)
    bookTracker:reset(saved)
end

local function safeID(obj)
    if obj == nil then
        return "nil"
    else
        return tostring(obj.id)
    end
end

-- params: actor, bookRecordID
local function learnSpell(data)
    if data.actor == nil then
        error("learnSpell actor is nil")
    end
    if data.bookRecordID == nil then
        error("learnSpell bookRecordID is nil")
    end
    print("learnSpell")

    local spellBag = bookTracker:get("book_" .. data.bookRecordID)
    if spellBag == nil then
        error("no spell book record for " .. data.bookRecordID)
        return
    end

    local spell = core.magic.spells.records[spellBag['spellID']]
    if spell == nil then
        error("unknown spell " .. spellBag['spellID'])
    end

    -- need to mark where the player learned the spell.
    -- this lets us pull corruption info, if any.
    local playerSpellKey = "actor_" .. data.actor.id .. "_spell_" .. spellBag['spellID']
    bookTracker:set(playerSpellKey, data.bookRecordID)

    -- actually add the spell to known spells
    local actorSpells = types.Actor.spells(data.actor)
    actorSpells:add(spell)

    -- notify player
    local spellName = ""
    if spellBag['corruption'] == nil then
        spellName = spellUtil.getSpellName(spell, nil, nil)
    else
        spellName = spellUtil.getSpellName(spell, interfaces.ErnCorruptionLedger
            .getCorruption(spellBag['corruption']['prefixID']), interfaces.ErnCorruptionLedger
            .getCorruption(spellBag['corruption']['suffixID']))
    end

    if (data.actor.type == types.Player) then
        -- data.spellName, data.corruptionName
        data.actor:sendEvent("ernShowLearnMessage", {
            spellName = spellName,
            spellID = spell.id
        })
    end
end

-- createSpellbook creates a spell book.
-- params: data.spellID, data.corruption, data.container, data.setOwner
local function createSpellbook(data)
    if (data.spellID == nil) or (data.spellID == "") then
        error("createSpellbook() bad spellID")
    end

    if (data.container == nil) then
        error("createSpellbook() nil container")
    end

    -- make sure spell is valid.
    local spell = core.magic.spells.records[data.spellID] -- get by id
    if spell == nil then
        error("invalid spell: " .. data.spellID)
        return
    end

    local spellKey = "spell_" .. data.spellID
    local prefixCorruption = nil
    local suffixCorruption = nil
    if (data.corruption ~= nil) then
        local prefixID = data.corruption['prefixID']
        local suffixID = data.corruption['suffixID']
        if (prefixID ~= nil) and (prefixID ~= "") then
            prefixCorruption = interfaces.ErnCorruptionLedger.getCorruption(data.corruption['prefixID'])
        end
        if (suffixID ~= nil) and (suffixID ~= "") then
            suffixCorruption = interfaces.ErnCorruptionLedger.getCorruption(data.corruption['suffixID'])
        end
        spellKey = "spell_" .. data.spellID .. "_" .. safeID(prefixCorruption) .. "_" ..
        safeID(suffixCorruption)
    end

    -- If we already made a book for this spell + corruption combo, re-use it.
    local bookRecord = nil
    local reusedBook = bookTracker:get(spellKey)
    if reusedBook ~= nil then
        settings.debugPrint("re-using book record for spell " .. spellKey .. ": " .. reusedBook)
        bookRecord = types.Book.record(reusedBook)
        if bookRecord == nil then
            error("expected a book record " .. reusedBook .. " to exist")
            return
        end
    else
        settings.debugPrint("making a new book record for spell " .. spellKey)
        bookRecord = books.createBookRecord(spell, prefixCorruption, suffixCorruption)
        bookTracker:set(spellKey, bookRecord.id)
    end

    local bookInstance = world.createObject(bookRecord.id)

    settings.debugPrint("creating " .. bookRecord.name .. " on " .. data.container.id)

    -- save what the book is attached to.
    bookTracker:set("book_" .. bookRecord.id, {
        ['spellID'] = data.spellID,
        ['corruption'] = data.corruption
    })

    -- put in target inventory
    bookInstance:moveInto(data.container)

    -- special case for shop keepers
    if data.setOwner then
        if (types.Actor.objectIsInstance(data.container)) then
            bookInstance.owner = data.container
        else
            error("data.setOwner is true but the container is not an actor")
        end
    end

    -- special case for wizards
    if (data.actor ~= nil) and ((suffixCorruption ~= nil) or (prefixCorruption ~= nil)) then
        settings.debugPrint("wizard actor learns corrupted spell")
        learnSpell({actor=data.actor, bookRecordID=bookRecord.id})
    end
end

local function getSourceBookForCast(data)
    local playerSpellKey = "actor_" .. data.caster.id .. "_spell_" .. data.spellID
    return bookTracker:get(playerSpellKey)
end

local function getCorruptionsFromBookID(sourceBook)
    local spellBag = bookTracker:get("book_" .. sourceBook)
    if spellBag == nil then
        error("missing book entry for " .. sourceBook)
        return nil
    end
    local corruptions = spellBag['corruption']
    if (corruptions == nil) then
        -- don't do anything for a normal spell
        return nil
    end
    if (corruptions.prefixID == nil) and (corruptions.suffixID == nil) then
        error("corrupted spell book has no corruptions: " .. sourceBook)
        return nil
    end
    settings.debugPrint(
        sourceBook .. " contains corruption prefix " .. tostring(corruptions.prefixID) .. " and suffix " ..
            tostring(corruptions.suffixID))
    return corruptions
end

local function handleSpellCast(data)
    if data.caster == nil then
        error("handleSpellApply caster is nil")
        return
    end
    if data.spellID == nil then
        error("handleSpellApply spellID is nil")
        return
    end

    local sourceBook = getSourceBookForCast(data)

    if sourceBook == nil then
        settings.debugPrint("spell cast, but wasn't learned from a book")
        return
    end

    settings.debugPrint("handleSpellCast from " .. sourceBook)

    local corruption = getCorruptionsFromBookID(sourceBook)

    if corruption == nil then
        -- not corrupted, don't do anything else.
        return
    end

    -- ok, have some corruption ids at this point.
    -- apply them!
    -- id, caster, spellID, bookRecordID
    if corruption.prefixID ~= nil then
        local prefix = interfaces.ErnCorruptionLedger.getCorruption(corruption.prefixID)
        if prefix.onCast ~= nil then
            print("Running corruption " .. corruption.prefixID .. ".onCast() with spell " .. data.spellID .. ".")
            prefix.onCast({
                id = corruption.prefixID,
                caster = data.caster,
                spellID = data.spellID,
                bookRecordID = sourceBook
            })
        end
    end
    if corruption.suffixID ~= nil then
        local suffix = interfaces.ErnCorruptionLedger.getCorruption(corruption.suffixID)
        if suffix.onCast ~= nil then
            print("Running corruption " .. corruption.suffixID .. ".onCast() with spell " .. data.spellID .. ".")
            suffix.onCast({
                id = corruption.suffixID,
                caster = data.caster,
                spellID = data.spellID,
                bookRecordID = sourceBook
            })
        end
    end
end

local function handleSpellApply(data)
    if data.caster == nil then
        error("handleSpellApply caster is nil")
        return
    end
    if data.target == nil then
        error("handleSpellApply target is nil")
        return
    end
    if data.spellID == nil then
        error("handleSpellApply spellID is nil")
        return
    end

    local sourceBook = getSourceBookForCast(data)

    if sourceBook == nil then
        settings.debugPrint("spell cast, but wasn't learned from a book")
        return
    end

    settings.debugPrint("handleSpellApply from " .. sourceBook)

    local corruption = getCorruptionsFromBookID(sourceBook)

    if corruption == nil then
        -- not corrupted, don't do anything else.
        return
    end

    -- ok, have some corruption ids at this point.
    -- apply them!
    -- id, caster, target, spellID, bookRecordID
    if corruption.prefixID ~= nil then
        local prefix = interfaces.ErnCorruptionLedger.getCorruption(corruption.prefixID)
        if prefix.onApply ~= nil then
            print("Running corruption " .. corruption.prefixID .. ".onApply() with spell " .. data.spellID .. ".")
            prefix.onApply({
                id = corruption.prefixID,
                caster = data.caster,
                target = data.target,
                spellID = data.spellID,
                bookRecordID = sourceBook
            })
        end
    end
    if corruption.suffixID ~= nil then
        local suffix = interfaces.ErnCorruptionLedger.getCorruption(corruption.suffixID)
        if suffix.onApply ~= nil then
            print("Running corruption " .. corruption.suffixID .. ".onApply() with spell " .. data.spellID .. ".")
            suffix.onApply({
                id = corruption.suffixID,
                caster = data.caster,
                target = data.target,
                spellID = data.spellID,
                bookRecordID = sourceBook
            })
        end
    end
end

local function selectSpell(data)
    if (data.spellID == nil) or (data.caster == nil) then
        error("selectSpell() bad data")
        return
    end
    local sourceBook = getSourceBookForCast(data)
    if sourceBook == nil then
        settings.debugPrint("spell selected, but wasn't learned from a book")
        return
    end

    local spell = core.magic.spells.records[data.spellID]
    if spell == nil then
        error("unknown spell " .. data.spellID)
    end

    settings.debugPrint("selectSpell from " .. sourceBook)

    local corruption = getCorruptionsFromBookID(sourceBook)

    if corruption == nil then
        -- not corrupted, don't do anything else.
        return
    end

    local prefix = interfaces.ErnCorruptionLedger.getCorruption(corruption.prefixID)
    local suffix = interfaces.ErnCorruptionLedger.getCorruption(corruption.suffixID)

    local spellName = spellUtil.getSpellName(spell, prefix, suffix)

    if (data.caster.type == types.Player) then
        data.caster:sendEvent("ernShowSelectMessage", {
            spellName = spellName,
        })
    end
end

return {
    eventHandlers = {
        ernCreateSpellbook = createSpellbook,
        ernHandleSpellApply = handleSpellApply,
        ernHandleSpellCast = handleSpellCast,
        ernLearnSpell = learnSpell,
        ernSelectSpell = selectSpell,
    },
    engineHandlers = {
        onSave = saveState,
        onLoad = loadState
    }
}
