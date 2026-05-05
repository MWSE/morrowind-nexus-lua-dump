--[[
ErnInheritTheHouse for OpenMW.
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

local MOD_NAME = require("scripts.ErnInheritTheHouse.ns")
local core     = require('openmw.core')
local pself    = require("openmw.self")
local houses   = require("scripts.ErnInheritTheHouse.houses.load")

local function onQuestUpdate(questId, stage)
    for _, inheritInfo in ipairs(houses) do
        if questId == inheritInfo.quest and stage == inheritInfo.stage then
            core.sendGlobalEvent(MOD_NAME .. "onVacate", {
                player = pself,
                cellID = inheritInfo.cell,
            })
            break
        end
    end
end

return {
    engineHandlers = {
        onQuestUpdate = onQuestUpdate,
    },
}
