--[[
ErnSameHat for OpenMW.
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

local MOD_NAME = require("scripts.ErnSameHat.ns")
local world    = require('openmw.world')
local types    = require('openmw.types')

local function onSameHatStart(data)
    if data.applyBonus then
        print("Same hat!")
        types.NPC.modifyBaseDisposition(data.npc, data.player, 20)
    end
    --print("adding hat state")
    world.mwscript.getGlobalVariables(data.player)["ernhassamehat"] = 1
end

local function onSameHatEnd(data)
    --print("removing hat state")
    world.mwscript.getGlobalVariables(data.player)["ernhassamehat"] = 0
end

return {
    eventHandlers = {
        [MOD_NAME .. "onSameHatStart"] = onSameHatStart,
        [MOD_NAME .. "onSameHatEnd"] = onSameHatEnd,
    },
}
