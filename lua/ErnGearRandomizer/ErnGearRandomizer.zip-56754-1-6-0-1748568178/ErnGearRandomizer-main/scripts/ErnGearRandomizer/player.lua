--[[
ErnGearRandomizer for OpenMW.
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
local I = require("openmw.interfaces")
local S = require("scripts.ErnGearRandomizer.settings")
local async = require('openmw.async')
local core = require("openmw.core")

I.Settings.registerPage {
    key = S.MOD_NAME,
    l10n = S.MOD_NAME,
    name = "name",
    description = "description"
}

local function reset(section, key)
    -- chance doesn't change tables
    if key ~= "chance" then
        core.sendGlobalEvent("LMresetSwapTables", {})
    end
end

S.settingsStore:subscribe(async:callback(reset))
