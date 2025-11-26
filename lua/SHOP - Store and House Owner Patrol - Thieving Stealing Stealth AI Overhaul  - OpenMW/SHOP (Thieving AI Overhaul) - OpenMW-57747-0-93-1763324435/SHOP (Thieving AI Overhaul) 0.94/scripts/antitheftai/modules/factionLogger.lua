--[[
SHOP - Store & House Owner Patrol (NPC in interiors AI overhaul) for OpenMW.
Copyright (C) 2025 Łukasz Walczak

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
----------------------------------------------------------------------
-- Anti-Theft Guard AI  •  v0.9 PUBLIC TEST  •  OpenMW ≥ 0.49
----------------------------------------------------------------------
-- factionLogger.lua
-- Logs all factions the player is a member of when a game is (re)loaded.

local types = require('openmw.types')          -- gives access to NPC functions
local self  = require('openmw.self')           -- the player, because this is a local script
local ui    = require('openmw.ui')             -- lets us print to the in-game console

local function logPlayerFactions()
    -- Fetch an array with the faction IDs the player is in.
    local factionIds = types.NPC.getFactions(self)   -- returns {} if none

    -- Header
    local header = ('[FactionLogger] Player has joined %d faction(s):'):format(#factionIds)
    print(header)
    ui.printToConsole(header, ui.CONSOLE_COLOR.White)

    -- List each faction on its own line
    for _, id in ipairs(factionIds) do
        local line = '  • ' .. id
        print(line)
        ui.printToConsole(line, ui.CONSOLE_COLOR.White)
    end

    if #factionIds == 0 then
        ui.printToConsole('  (none)', ui.CONSOLE_COLOR.White)
    end
end

-- Run once whenever the save is loaded (or a new game starts)
return {
    engineHandlers = {
        onLoad = logPlayerFactions
    }
}
