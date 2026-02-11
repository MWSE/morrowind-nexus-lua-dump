--[[
ErnBestICanDo for OpenMW.
Copyright (C) Erin Pentecost 2026

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

-- This file is in charge of tracking and exposing path information.
-- Interact with it via the interface it exposes.

local MOD_NAME   = require("scripts.ErnBestICanDo.ns")
local types      = require('openmw.types')
local core       = require('openmw.core')
local pself      = require("openmw.self")
local interfaces = require("openmw.interfaces")
local settings   = require("scripts.ErnBestICanDo.settings")
local async      = require("openmw.async")


local settingCache = {
    constGold = settings.main.constGold,
    mercMultGold = settings.main.mercMultGold,
    mercSquareMultGold = settings.main.mercSquareMultGold,
    additionalOnlyGold = settings.main.additionalOnlyGold
}
settings.main.subscribe(async:callback(function(_, key)
    settingCache[key] = settings.main[key]
end))

local function messageData(npc)
    local mercSkill = pself.type.stats.skills.mercantile(pself).modified
    return {
        npc = npc,
        player = pself,
        maxGold = math.ceil(settingCache.constGold + mercSkill * settingCache.mercMultGold +
            mercSkill * mercSkill * settingCache.mercSquareMultGold),
        additionalOnlyGold = settingCache.additionalOnlyGold,
    }
end

local function UiModeChanged(data)
    if not data.arg then
        return
    end
    -- need to change gold before the barter window actually comes up.
    if (data.newMode == "Barter") then
        core.sendGlobalEvent(MOD_NAME .. "onBarterStart", messageData(data.arg))
    end
end

local function onReOpenBarterWindow(data)
    interfaces.UI.removeMode('Barter')
    interfaces.UI.addMode('Barter', data)
end

return {
    eventHandlers = {
        [MOD_NAME .. "onReOpenBarterWindow"] = onReOpenBarterWindow,
        UiModeChanged = UiModeChanged
    },
}
