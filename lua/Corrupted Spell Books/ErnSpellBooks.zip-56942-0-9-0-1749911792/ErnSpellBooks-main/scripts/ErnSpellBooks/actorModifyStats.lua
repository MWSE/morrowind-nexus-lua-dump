--[[
ErnSpellBooks for OpenMW.
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
]] local types = require("openmw.types")
local settings = require("scripts.ErnSpellBooks.settings")
local core = require("openmw.core")
local self = require("openmw.self")

local function modifyStats(data)
    if (data.modHealth == nil) and (data.modMagicka == nil) and (data.modFatigue == nil) then
        error("modifyStats() data is bad")
        return
    end
    settings.debugPrint("modStats for actor " .. self.id .. ": health " .. tostring(data.modHealth) .. ", magicka " ..
                            tostring(data.modMagicka) .. ", fatigue " .. tostring(data.modFatigue))

    if data.modHealth ~= nil then
        local healthStat = self.type.stats.dynamic.health(self)
        healthStat.current = healthStat.current + data.modHealth
    end
    if data.modMagicka ~= nil then
        local magickaStat = self.type.stats.dynamic.magicka(self)
        magickaStat.current = magickaStat.current + data.modMagicka
    end
    if data.modFatigue ~= nil then
        local fatigueStat = self.type.stats.dynamic.fatigue(self)
        fatigueStat.current = fatigueStat.current + data.modFatigue
    end
end

return {
    eventHandlers = {
        ernModifyStats = modifyStats
    }
}
