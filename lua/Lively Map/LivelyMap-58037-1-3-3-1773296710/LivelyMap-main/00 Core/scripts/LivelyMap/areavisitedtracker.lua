--[[
LivelyMap for OpenMW.
Copyright (C) Erin Pentecost 2025

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

local MOD_NAME     = require("scripts.LivelyMap.ns")
local types        = require('openmw.types')
local json         = require('scripts.LivelyMap.json.json')
local mutil        = require('scripts.LivelyMap.mutil')
local core         = require('openmw.core')
local pself        = require("openmw.self")
local util         = require("openmw.util")
local vfs          = require('openmw.vfs')
local aux_util     = require('openmw_aux.util')
local settings     = require("scripts.LivelyMap.settings")
local async        = require("openmw.async")

local cellsVisited = {}

---@param pathEntry PathEntry
local function markCell(pathEntry)
    local x = math.floor(pathEntry.x / mutil.CELL_SIZE)
    local y = math.floor(pathEntry.y / mutil.CELL_SIZE)
    if not cellsVisited[x] then
        cellsVisited[x] = {}
    end
    cellsVisited[x][y] = 1
    for xi = x - 1, x + 1, 2 do
        for yi = y - 1, y + 1, 2 do
            if not cellsVisited[xi] then
                cellsVisited[xi] = {}
            end
            if not cellsVisited[xi][yi] then
                cellsVisited[xi][yi] = 0.5
            end
        end
    end
end

local function onSave()
    return cellsVisited
end

local function onLoad(data)
    if data ~= nil then
        cellsVisited = data
    end
end

print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")

return {
    interfaceName = MOD_NAME .. "AreaVisitedTracker",
    interface = {
        version = 1,
        markCell = markCell,
        cellVisited = function(x, y)
            return cellsVisited[x] and cellsVisited[x][y] or 0
        end
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onInit = function() onLoad(nil) end,
    }
}
