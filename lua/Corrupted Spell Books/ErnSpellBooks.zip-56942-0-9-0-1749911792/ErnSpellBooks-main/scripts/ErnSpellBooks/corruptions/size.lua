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

local actorChanged = {}

local restoreSizeCallback = async:registerTimerCallback('ernRestoreSizeCallback',
function(data)
    if types.Actor.isDead(data['target']) then
        return
    end
    data.target:setScale(data.originalScale) 
    actorChanged[data.target.id] = false
end)


local function getCorruption(sizeMod)
    -- The function that actually does the thing.
    -- data has fields: id, caster, target, spellID, sourceBook
    return (function (data)
        if actorChanged[data.target.id] then
            return
        end
        actorChanged[data.target.id] = true

        local originalScale = data.target.scale
        data.target:setScale(originalScale * sizeMod)

        -- restore size when the spell expires (or after 5 sec)
        local duration = math.max(5, spellUtil.getSpellDuration(data.spellID))
        async:newSimulationTimer(duration, restoreSizeCallback, {
            ['originalScale']=originalScale,
            ['target']=data.target,
        })
    end)
end

-- Register the corruption in the ledger.
interfaces.ErnCorruptionLedger.registerCorruption({
    id = "gnome",
    onApply = getCorruption(0.5),
    minimumLevel = 1,
    prefixName = localization("corruption_" .. "gnome" .. "_prefix"),
    suffixName = localization("corruption_" .. "gnome" .. "_suffix"),
    description = localization("corruption_" .. "gnome" .. "_description")
})

-- Register the corruption in the ledger.
interfaces.ErnCorruptionLedger.registerCorruption({
    id = "giant",
    onApply = getCorruption(1.5),
    minimumLevel = 1,
    prefixName = localization("corruption_" .. "giant" .. "_prefix"),
    suffixName = localization("corruption_" .. "giant" .. "_suffix"),
    description = localization("corruption_" .. "giant" .. "_description")
})