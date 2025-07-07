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
local world = require("openmw.world")
local types = require("openmw.types")
local settings = require("scripts.ErnSpellBooks.settings")
local spellUtil = require("scripts.ErnSpellBooks.spellUtil")
local core = require("openmw.core")
local localization = core.l10n(settings.MOD_NAME)

local bookShapes = {{
    ['icon'] = "icons\\m\\tx_book_04.dds",
    ['model'] = "meshes\\m\\text_octavo_05.nif"
}, {
    ['icon'] = "icons\\m\\tx_octavo_03.dds",
    ['model'] = "meshes\\m\\text_octavo_03.nif"
}, {
    ['icon'] = "icons\\m\\tx_folio_03.dds",
    ['model'] = "meshes\\m\\text_folio_03.nif"
}}

-- spell is a core.Magic.Spell.
local function createBookRecord(spell, prefixCorruption, suffixCorruption)
    if spell == nil then
        error("createBookRecord(): spell is nil")
    end

    local spellName = spellUtil.getSpellName(spell, prefixCorruption, suffixCorruption)

    local bookName = localization("book_name", {spellName = spellName})

    local bookBody = ""

    local corruptionCostMod = 0

    local prefixDescription = "nil"
    if prefixCorruption ~= nil then
        corruptionCostMod = (3 * prefixCorruption.minimumLevel) + math.random(5, 10)
        prefixDescription = prefixCorruption.description
    end
    local suffixDescription = "nil"
    if suffixCorruption ~= nil then
        corruptionCostMod = (3 * suffixCorruption.minimumLevel) + math.random(5, 10)
        suffixDescription = suffixCorruption.description
    end

    if (prefixCorruption ~= nil) or (suffixCorruption ~= nil) then
        bookBody = localization("bookCorrupt_body", {
            spellName = spellName,
            corruptionPrefixDescription = prefixDescription,
            corruptionSuffixDescription = suffixDescription
        })
    else
        bookBody = localization("book_body", {
            spellName = spellName,
        })
    end

    -- ErnSpellBooks_LearnEnchantment
    local shape = bookShapes[math.random(1, 3)]
    local recordFields = {
        enchant = "ErnSpellBooks_LearnEnchantment",
        enchantCapacity = 1,
        icon = shape["icon"],
        isScroll = false,
        model = shape["model"],
        name = bookName,
        skill = nil,
        text = bookBody,
        value = math.max(1,
            settings.costScale() * math.ceil(math.min(3000, 20 + corruptionCostMod + (spell.cost ^ 1.5)))),
        weight = math.random(2, 4)
    }
    local draftRecord = types.Book.createRecordDraft(recordFields)
    return world.createRecord(draftRecord)
end

return {
    createBookRecord = createBookRecord
}
