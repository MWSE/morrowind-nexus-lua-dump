--[[
ErnGlider for OpenMW.
Copyright (C) 2026 Erin Pentecost

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
local settings   = require("scripts.ErnGlider.settings")
local input      = require('openmw.input')
local async      = require("openmw.async")
local interfaces = require("openmw.interfaces")

local function init()
    input.registerTriggerHandler(settings.toggleGlideTriggerKey, async:callback(
        function()
            if interfaces.ErnGliderGlider.isApplied() then
                interfaces.ErnGliderGlider.remove()
            else
                interfaces.ErnGliderSurf.remove()
                interfaces.ErnGliderGlider.apply()
            end
        end))

    input.registerTriggerHandler(settings.toggleSurfTriggerKey, async:callback(
        function()
            if interfaces.ErnGliderSurf.isApplied() then
                interfaces.ErnGliderSurf.remove()
            else
                interfaces.ErnGliderGlider.remove()
                interfaces.ErnGliderSurf.apply()
            end
        end))
end


return {
    engineHandlers = {
        onInit = init,
        onLoad = init,
    },
}
