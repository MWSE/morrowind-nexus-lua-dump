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
local settings = require("scripts.ErnOneStick.settings")
local pself = require("openmw.self")

local latched = true

local function hasLowFatigue()
    local min = settings.runMinimumFatigue
    if min <= 0 then
        return false
    end
    if min >= 100 then
        -- 100% can be used to disable auto-run.
        return true
    end
    if latched then
        min = min + 10
    end
    min = math.min(min, 100)

    local fatigueStat = pself.type.stats.dynamic.fatigue(pself)
    local current = math.ceil(100 * fatigueStat.current / fatigueStat.base)

    if current < min then
        latched = true
        return true
    else
        latched = false
        return false
    end
end

return {
    hasLowFatigue = hasLowFatigue,
}
