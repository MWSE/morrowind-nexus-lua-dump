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
local interfaces = require("openmw.interfaces")
local world = require('openmw.world')
local settings = require("scripts.ErnBurglary.settings")

local function onStolenCallback(stolenItemsData)
    for _, data in ipairs(stolenItemsData) do
        if data.caught == false then
            local xp = data.itemRecord.value * data.count
            if xp > 0 then
                data.player:sendEvent(settings.MOD_NAME .. "xpOnStolenCallback", xp)
            end
        end
    end
end

interfaces.ErnBurglary.onStolenCallback(onStolenCallback)
