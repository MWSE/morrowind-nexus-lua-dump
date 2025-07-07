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
]] local world = require('openmw.world')
local core = require("openmw.core")
local settings = require("scripts.ErnSpellBooks.settings")
local interfaces = require('openmw.interfaces')
local types = require("openmw.types")
local localization = core.l10n(settings.MOD_NAME)

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
end

-- The function that actually does the thing.
-- data has fields: id, caster, spellID, sourceBook
local function onCast(data)
    if data.caster == nil then
        error("caster is nil")
        return
    end
    local totalCost = core.magic.spells.records[data.spellID].cost

    local restoreSpell = core.magic.spells.records["ErnSpellBooks_restore_magicka"]

    -- restore some amount of magicka less than the total cost of the spell.
    local effectList = {}
    for _, item in ipairs(restoreSpell.effects) do
        if item.duration <= totalCost then
            -- settings.debugPrint("restitution: " .. item.duration)
            local insertAt = math.random(1, 1 + #effectList)
            table.insert(effectList, insertAt, item)
        end
    end

    settings.debugPrint("restitution: restore for " .. effectList[1].duration .. " seconds")
    types.Actor.activeSpells(data.caster):add({
        id = "ErnSpellBooks_restore_magicka",
        effects = {effectList[1].index}
    })
end

local id = "restitution"
-- Register the corruption in the ledger.
interfaces.ErnCorruptionLedger.registerCorruption({
    id = id,
    onCast = onCast,
    minimumLevel = 4,
    prefixName = localization("corruption_" .. tostring(id) .. "_prefix"),
    suffixName = localization("corruption_" .. tostring(id) .. "_suffix"),
    description = localization("corruption_" .. tostring(id) .. "_description")
})
