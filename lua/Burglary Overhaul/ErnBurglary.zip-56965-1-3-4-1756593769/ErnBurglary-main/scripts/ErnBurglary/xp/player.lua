--[[
ErnBurglary for OpenMW.
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
local settings   = require("scripts.ErnBurglary.settings")
local interfaces = require("openmw.interfaces")
local core       = require("openmw.core")

local function xpOnStolenCallback(data)
    -- don't go over 3, ever.
    local scaled = math.min(3, settings.sneakXPScale() * math.log(data / 10))

    if scaled > 0 then
        interfaces.SkillProgression.skillUsed(core.stats.Skill.records.sneak.id,
            {
                scale = scaled,
                useType = interfaces.SkillProgression.SKILL_USE_TYPES
                    .Sneak_PickPocket,
                manual = true
            })
    end
end

return {
    eventHandlers = {
        [settings.MOD_NAME .. "xpOnStolenCallback"] = xpOnStolenCallback,
    }
}
