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
local interfaces = require("openmw.interfaces")
local settings = require("scripts.ErnSpellBooks.settings")
local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")
local animation = require('openmw.animation')
local storage = require('openmw.storage')

local bookTracker = storage.globalSection(settings.MOD_NAME .. "bookTracker")

-- You learn a spell by casting the spell book.
-- This prevents you from just reading spell books without actually fully
-- controlling them. It also adds intention behind the action.
-- If you learn spells automatically, you might do it on accident.

local function handleLearn(actor, bookRecord)
    settings.debugPrint("Learn Spell: " .. actor.id .. " learns " .. bookRecord.name)
    core.sendGlobalEvent("ernLearnSpell", {
        actor = actor,
        bookRecordID = bookRecord.id
    })
end

-- isSpellBook returns true if a cast spell is from a book
local function isSpellBook(item)
    if (item ~= nil) and (item.type == types.Book) then
        local bookRecord = types.Book.record(item)
        if (bookRecord ~= nil) and (bookRecord.enchant ~= nil) then
            return bookTracker:get("book_" .. bookRecord.id) ~= nil
        end
    end
    return false
end

interfaces.AnimationController.addTextKeyHandler("spellcast", function(group, key)
    if key == "self start" or key == "touch start" or key == "target start" then
        settings.debugPrint("spellcast start for actor " .. self.id .. ": " .. key)
        local enchantedItem = types.Actor.getSelectedEnchantedItem(self)
        if isSpellBook(enchantedItem) then
            handleLearn(self, types.Book.record(enchantedItem))
            -- TODO: interrupt rest of the cast?
            return false
        end
    end
end)
