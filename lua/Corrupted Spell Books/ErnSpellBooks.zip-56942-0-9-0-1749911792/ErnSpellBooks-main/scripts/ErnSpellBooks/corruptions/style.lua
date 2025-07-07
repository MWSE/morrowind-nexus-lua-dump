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
local world = require('openmw.world')
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

local stylishHatRecordID = "fur_colovian_helm"

local deleteHatCallback = async:registerTimerCallback('ernDeleteHatCallback',
function(data)
    data['styleHat']:remove()

    if data['oldHat'] ~= nil then
        core.sendGlobalEvent('UseItem', {
            object = data['oldHat'],
            actor = data['target'],
            force = false
        })
    end
end)

-- The function that actually does the thing.
-- data has fields: id, caster, target, spellID, sourceBook
local function applyCorruption(data)
    -- don't do anything if they already have a hat
    local currentHat = types.Actor.getEquipment(data.target, types.Actor.EQUIPMENT_SLOT.Helmet)
    if (currentHat ~= nil) and (currentHat.recordId == stylishHatRecordID) then
        settings.debugPrint("already has a good hat")
        return
    end

    -- create a fur_colovian_helm and make the target wear it.
    -- this is safe for beast races.
    local hatInstance = world.createObject(stylishHatRecordID)
    hatInstance:moveInto(data.target)
    core.sendGlobalEvent('UseItem', {
        object = hatInstance,
        actor = data.target,
        force = true
    })

    -- delete the hat when the spell expires (or after 5 sec)
    local duration = math.max(5, spellUtil.getSpellDuration(data.spellID))
    async:newSimulationTimer(duration, deleteHatCallback, {
        ['styleHat']=hatInstance,
        ['oldHat']=currentHat,
        ['target']=data.target,
    })
end

local id = "style"
-- Register the corruption in the ledger.
interfaces.ErnCorruptionLedger.registerCorruption({
    id = id,
    onApply = applyCorruption,
    minimumLevel = 1,
    prefixName = localization("corruption_" .. tostring(id) .. "_prefix"),
    suffixName = localization("corruption_" .. tostring(id) .. "_suffix"),
    description = localization("corruption_" .. tostring(id) .. "_description")
})
