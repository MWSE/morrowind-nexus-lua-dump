--[[
ErnFatigueFix for OpenMW.
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
local pself = require("openmw.self")

local function onActive()
    local fatigueStat            = pself.type.stats.dynamic.fatigue(pself)
    local healthStat            = pself.type.stats.dynamic.health(pself)

    --print(pself.recordId..": before fatigue "..tostring(fatigueStat.current).."/"..tostring(fatigueStat.base + fatigueStat.modifier)..", health: "..tostring(healthStat.base))
    fatigueStat.base = math.min(fatigueStat.base, 5*healthStat.base)
    fatigueStat.current = math.min(fatigueStat.base+fatigueStat.modifier, fatigueStat.current)
    --print(pself.recordId..": after fatigue "..tostring(fatigueStat.current).."/"..tostring(fatigueStat.base + fatigueStat.modifier)..", health: "..tostring(healthStat.base))
end


return {
    engineHandlers = {
        onActive = onActive
    }
}
