--[[
ErnOneStick for OpenMW.
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
local MOD_NAME = require("scripts.ErnOneStick.ns")
local pself = require("openmw.self")
local async = require("openmw.async")
local types = require('openmw.types')
local ui = require("openmw.interfaces").UI
local keytrack = require("scripts.ErnOneStick.keytrack")
local core = require("openmw.core")
local input = require('openmw.input')
local interfaces = require('openmw.interfaces')
local settings = require("scripts.ErnOneStick.settings.settings")
local animation = require('openmw.animation')

---@class ModeWindow
---@field Mode string
---@field Window string

---@type ModeWindow[]
local windowOrder = {}

for _, mode in ipairs({ "Interface", "Journal" }) do
    for window in pairs(interfaces.UI.getWindowsForMode(mode)) do
        table.insert(windowOrder, { Mode = mode, Window = window })
    end
end

input.registerTriggerHandler(settings.menuToggleTriggerName, async:callback(
    function()
        if #interfaces.UI.modes == 0 then
            -- bring up interface mode
            interfaces.UI.setMode(windowOrder[1].Mode, { windows = { windowOrder[1].Window } })
            return
        end

        for idx, mw in ipairs(windowOrder) do
            print("Checking " .. mw.Window)
            if interfaces.UI.isWindowVisible(mw.Window) then
                -- cycle to next window
                if idx == #windowOrder then
                    idx = 1
                else
                    idx = idx + 1
                end
                interfaces.UI.setMode(windowOrder[idx].Mode, { windows = { windowOrder[idx].Window } })
                return
            end
        end
    end))
