--[[
ErnSlowMagickaRegen for OpenMW.
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
local settings = require("scripts.ErnSlowMagickaRegen.settings")
local world = require('openmw.world')

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
end

-- Init settings first to init storage which is used everywhere.
settings.initSettings()

-- deltaTime tracks how long since we've last regenerated.
local deltaTime = 0.0

local pendingActors = {}

local function onUpdate(dt)
    deltaTime = deltaTime + dt
    if #pendingActors == 0 then
        if deltaTime < 2 then
            return
        end

        for _, actor in ipairs(world.activeActors) do
            table.insert(pendingActors, actor)
        end
    end


    local simTime = world.getSimulationTime()
    local gameTime = world.getGameTime()
    local simTimeScale = world.getSimulationTimeScale()

    local actor = table.remove(pendingActors)

    settings.debugPrint("Sending event to " .. actor.id)
    actor:sendEvent("regenMagicka", {
        deltaTime = deltaTime,
        simTime = simTime,
        gameTime = gameTime,
        simTimeScale = simTimeScale
    })

    deltaTime = 0.0
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}
