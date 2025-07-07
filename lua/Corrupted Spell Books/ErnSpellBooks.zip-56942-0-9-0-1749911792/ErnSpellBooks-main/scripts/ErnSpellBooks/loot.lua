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
]]
local settings = require("scripts.ErnSpellBooks.settings")
local world = require('openmw.world')
local types = require("openmw.types")
local core = require("openmw.core")
local storage = require('openmw.storage')
local interfaces = require('openmw.interfaces')
local books = require("scripts.ErnSpellBooks.books")
local spellUtil = require("scripts.ErnSpellBooks.spellUtil")
local localization = core.l10n(settings.MOD_NAME)

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
end

local lootTracker = storage.globalSection(settings.MOD_NAME .. "lootTracker")
lootTracker:setLifeTime(storage.LIFE_TIME.Temporary)

-- resetLootAge is one in-game day in seconds.
local resetLootAge = 86400

local function saveState()
    return lootTracker:asTable()
end

local function loadState(saved)
    lootTracker:reset(saved)
end

local wizardClasses = {
    "battlemage",
    "healer",
    "mage",
    "sorcerer",
    "mabrigash",
    "necromancer",
    "priest",
    "warlock",
    "wise woman",
    "witch"
}

local function isBookSeller(npcInstance)
    if (types.NPC.objectIsInstance(npcInstance)) then
        local services = types.NPC.record(npcInstance).servicesOffered
        return services['Books'] or services['books']
    end
    return false
end

local function isWizard(npcInstance)
    if (types.NPC.objectIsInstance(npcInstance)) then
        local npcClass = types.NPC.record(npcInstance).class
        for _, match in ipairs(wizardClasses) do
            if string.match(npcClass, ".*" .. match .. ".*") ~= nil then
                settings.debugPrint("detected a " .. match)
                return true
            end
        end
    end
    return false
end

local function hasScrolls(containerInstance)
    -- types.Actor.inventory(self.object)
    local inventory = types.Container.inventory(containerInstance)
    for _, item in ipairs(inventory:getAll(types.Book)) do
        local bookRecord = types.Book.record(item)
        if bookRecord.enchant ~= nil then
            settings.debugPrint("found scroll " .. bookRecord.name .. " in " .. containerInstance.id)
            return true
        end
    end
    return false
end

local function getHighestPlayerLevel()
    local lvl = 0
    for _, player in pairs(world.players) do
        local currentLevel = player.type.stats.level(player).current
        lvl = math.max(lvl, currentLevel)
    end
    settings.debugPrint("player level: " .. lvl)
    return lvl
end

local function shuffle(collection)
    local randList = {}
    for _, item in pairs(collection) do
        -- get random index to insert into. 1 to size+1.
        -- # is a special op that gets size
        local insertAt = math.random(1, 1 + #randList)
        table.insert(randList, insertAt, item)
    end
    return randList
end

local function getRandomCorruption()
    local corruption = nil
    if settings.corruptionChance() > math.random(0, 99) then
        local randList = interfaces.ErnCorruptionLedger.getRandomCorruptionIDs(getHighestPlayerLevel(), 2)
        if randList == nil then
            error("got a nil corruption list!")
        end
        if #randList ~= 2 then
            error("got " .. tostring(#randList) .. " corruptions, but expected 2")
            return nil
        end
        corruption = {
            ['prefixID'] = randList[1],
        }
        -- roll again for suffix
        if settings.corruptionChance() > math.random(0, 99) then
            corruption['suffixID'] = randList[2]
        end
    end
    return corruption
end

local function deleteBooksFromShop(npcInstance)
    local books = types.Actor.inventory(npcInstance):getAll(types.Book)
    for _, book in ipairs(books) do
        local bookRecord = types.Book.record(book)
        if (bookRecord.enchant ~= nil) and (string.lower(bookRecord.enchant) == "ernspellbooks_learnenchantment") then
            settings.debugPrint("deleting book from shopkeeper: " .. bookRecord.name)
            book:remove()
        end
    end
end

local function insertIntoShop(npcInstance)
    local spellList = spellUtil.getRandomSpells(getHighestPlayerLevel(), math.random(1, 4))
    for _, spell in ipairs(spellList) do
        core.sendGlobalEvent("ernCreateSpellbook", {
            spellID = spell.id,
            corruption = getRandomCorruption(),
            container = npcInstance
        })
    end
end

local function onObjectActive(object)
    local now = world.getGameTime()
    if (object == nil) or (object.id == nil) then
        settings.debugPrint("bad object!")
        return
    end

    local marked = lootTracker:get(object.id)
    if (marked ~= nil) and ((marked == true) or (marked + resetLootAge > now)) then
        -- settings.debugPrint("object activated again")
        return
    end
    -- settings.debugPrint("object activated for the first time")

    if isBookSeller(object) then
        -- Keep book seller spell book inventory stocked.
        deleteBooksFromShop(object)
        insertIntoShop(object)
        -- Mark as done temporarily so we will reset.
        lootTracker:set(object.id, now)
        return
    elseif isWizard(object) then
        -- Roll to insert one random spell book of a spell the wizard knows.
        if settings.spawnChance() > math.random(0, 99) then
            local actorSpells = shuffle(types.Actor.spells(object))
            local placedBook = false
            for _, spell in ipairs(actorSpells) do
                if placedBook == false then
                    local validSpell = spellUtil.getValidSpell(spell)
                    if validSpell ~= nil then
                        settings.debugPrint("found spell on wizard: " .. validSpell.name .. " on wizard " .. object.id)
                        core.sendGlobalEvent("ernCreateSpellbook", {
                            spellID = validSpell.id,
                            corruption = getRandomCorruption(),
                            container = object,
                            actor = object,
                        })
                        
                        placedBook = true
                    end
                end
            end
        end
    elseif (types.Container.objectIsInstance(object)) then
        -- If the container has a scroll, then it makes sense that
        -- maybe there is a spell book there, too.
        local containerRecord = types.Container.record(object)
        if (containerRecord.isOrganic ~= true) and hasScrolls(object) then
            if settings.spawnChance() > math.random(0, 99) then
                -- insert random book
                core.sendGlobalEvent("ernCreateSpellbook", {
                    spellID = spellUtil.getRandomSpells(getHighestPlayerLevel(), 1)[1].id,
                    corruption = getRandomCorruption(),
                    container = object
                })
            end
        end
    else
        -- invalid object, don't mark it.
        return
    end

    -- mark as done permanently so we don't re-insert.
    lootTracker:set(object.id, true)
end

return {
    engineHandlers = {
        onObjectActive = onObjectActive
    }
}
