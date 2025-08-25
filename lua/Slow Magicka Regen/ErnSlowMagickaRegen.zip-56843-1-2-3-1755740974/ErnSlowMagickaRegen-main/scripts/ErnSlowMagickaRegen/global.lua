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
local totalPartitions = 8
local partition = 0

local function onUpdate(dt)
    -- Don't run the full check every frame.
    deltaTime = deltaTime + dt
    if deltaTime < 0.5 then
        return
    end
    -- We only send events to actors 1 out of totalPartitions times.
    -- This prevents frame drops when there are a ton of actors.
    partition = (partition + 1) % totalPartitions

    local simTime = world.getSimulationTime()
    local gameTime = world.getGameTime()
    local simTimeScale = world.getSimulationTimeScale()

    for _, actor in ipairs(world.activeActors) do
        local myPartition = string.byte(string.sub(actor.id, -1)) % totalPartitions
        if myPartition == partition then
            settings.debugPrint("Sending event to " .. actor.id .. " (" .. tostring(myPartition) .. ")")
            actor:sendEvent("regenMagicka", {
                deltaTime = deltaTime,
                simTime = simTime,
                gameTime = gameTime,
                simTimeScale = simTimeScale
            })
        end
    end

    deltaTime = 0.0
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}
