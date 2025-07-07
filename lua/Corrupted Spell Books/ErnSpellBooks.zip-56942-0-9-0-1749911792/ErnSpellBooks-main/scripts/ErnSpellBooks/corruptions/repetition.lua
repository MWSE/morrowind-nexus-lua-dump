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
local spellUtil = require("scripts.ErnSpellBooks.spellUtil")
local async = require('openmw.async')
local localization = core.l10n(settings.MOD_NAME)

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
end

local repeatCallback = async:registerTimerCallback('ernRepeatCallback', function(data)
    if data['target'] == nil then
        error("ernRepeatCallback: nil target")
        return
    end
    local spell = core.magic.spells.records[data['spellID']]
    if spell == nil then
        error("ernRepeatCallback: can't find spell")
        return
    end
    if types.Actor.isDead(data['target']) then
        return
    end

    local castSound = nil
    -- need a list of indices
    local indices = {}
    for _, effect in ipairs(spell.effects) do
        -- don't mix self and not-self effects.
        if data['self'] == (effect.range == core.magic.RANGE.Self) then
            table.insert(indices, effect.index)
        end
        if effect.effect.castSound ~= nil then
            castSound = effect.effect.castSound
        end
    end

    if castSound ~= nil then
        core.sound.playSound3d(castSound, data['caster'], {
            loop = false,
            volume = 1.0,
            pitch = 1.0
        })
    end

    spellUtil.applySpellFX(data['target'], data['spellID'], nil)

    -- Apply spell effects again
    settings.debugPrint("Applying repeated " .. data['spellID'])
    types.Actor.activeSpells(data['target']):add({
        id = data['spellID'],
        effects = indices
    })

end)

-- The function that actually does the thing.
-- data has fields: id, caster, target, spellID, sourceBook
local function onApply(data)
    -- repeat later
    local duration = 0.1 + math.random(0.3) + spellUtil.getSpellDuration(data.spellID)
    async:newSimulationTimer(duration, repeatCallback, {
        ['spellID'] = data.spellID,
        ['target'] = data.target,
        ['caster'] = data.caster,
        ['self'] = data.caster.id == data.target.id
    })
end

local id = "repetition"
-- Register the corruption in the ledger.
interfaces.ErnCorruptionLedger.registerCorruption({
    id = id,
    onApply = onApply,
    minimumLevel = 10,
    prefixName = localization("corruption_" .. tostring(id) .. "_prefix"),
    suffixName = localization("corruption_" .. tostring(id) .. "_suffix"),
    description = localization("corruption_" .. tostring(id) .. "_description"),
})
