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

local function onQuestUpdate(questId, stage)
    if questId == "a2_4_milogone" and stage == 1 then
        print(tostring(questId) .. " = " .. tostring(stage))
        -- caius gave you his house
        core.sendGlobalEvent(MOD_NAME .. "onVacate", {
            player = pself,
            cellID = "balmora, caius cosades' house",
        })
    elseif questId == "mg_killnecro2" and stage == 50 then
        print(tostring(questId) .. " = " .. tostring(stage))
        -- tashpi ashibael goes into hiding
        core.sendGlobalEvent(MOD_NAME .. "onVacate", {
            player = pself,
            cellID = "maar gan, tashpi ashibael's hut",
        })
    elseif questId == "ms_nuccius" and stage == 100 then
        print(tostring(questId) .. " = " .. tostring(stage))
        -- vodunius leaves vvardenfell
        core.sendGlobalEvent(MOD_NAME .. "onVacate", {
            player = pself,
            cellID = "seyda neen, vodunius nuccius' house",
        })
    elseif questId == "pc_m1_mg_cha3" and (stage == 70 or stage == 80) then
        print(tostring(questId) .. " = " .. tostring(stage))
        -- ugenring leaves
        core.sendGlobalEvent(MOD_NAME .. "onVacate", {
            player = pself,
            cellID = "charach, ugenring's house",
        })
    end
end

return {
    engineHandlers = {
        onQuestUpdate = onQuestUpdate,
    },
}
