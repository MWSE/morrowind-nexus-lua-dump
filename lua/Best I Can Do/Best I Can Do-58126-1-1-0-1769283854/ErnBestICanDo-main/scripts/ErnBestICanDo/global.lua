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

local MOD_NAME = require("scripts.ErnBestICanDo.ns")

if require("openmw.core").API_REVISION < 111 then
    error("OpenMW 0.51 or newer is required!")
    return
end

local function getBaseBarterGold(npc)
    return npc.type.records[npc.recordId].baseGold
end

local function limitGold(data)
    local currentGold = data.npc.type.getBarterGold(data.npc)

    -- save off original amount before we start messing with it.
    local originalGold = getBaseBarterGold(data.npc)

    if not originalGold then
        return
    end

    local newMax = 0
    if data.additionalOnlyGold then
        newMax = data.maxGold + originalGold
    else
        newMax = math.min(originalGold, data.maxGold)
    end

    if currentGold > newMax then
        print(data.npc.recordId .. "- current: " ..
            tostring(currentGold) ..
            ", original: " .. tostring(originalGold) .. ", max: " .. tostring(newMax))
        data.npc.type.setBarterGold(data.npc, newMax)
        -- notify player to re-open window
        data.player:sendEvent(MOD_NAME .. "onReOpenBarterWindow", {
            target = data.npc,
        })
    end
end

local function onBarterStart(data)
    if not data.npc then
        print("no npc in data")
        return
    end
    limitGold(data)
end

return {
    eventHandlers = {
        [MOD_NAME .. "onBarterStart"] = onBarterStart,
    },
}
