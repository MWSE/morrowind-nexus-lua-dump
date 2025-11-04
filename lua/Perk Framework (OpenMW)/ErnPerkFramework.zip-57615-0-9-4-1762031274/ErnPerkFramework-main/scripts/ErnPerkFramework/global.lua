--[[
ErnPerkFramework for OpenMW.
Copyright (C) 2025 Erin Pentecost and ownlyme

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
local MOD_NAME = "ErnPerkFramework"
local world = require('openmw.world')
local storage = require('openmw.storage')

local mwVars = storage.globalSection(MOD_NAME .. "_mwVars")
mwVars:setLifeTime(storage.LIFE_TIME.Temporary)

local function updateMwVars()
    for _, player in ipairs(world.players) do
        local globalVars = world.mwscript.getGlobalVariables(player)
        local asTable = {}
        local count = 0
        for k, v in pairs(globalVars) do
            asTable[k] = v
            count = count + 1
        end
        mwVars:set(player.id, asTable)
        print("Saved " .. tostring(count) .. " variables for player " .. tostring(player.id))
    end
end

local function loadState(saved)
    updateMwVars()
end

local delta = 31
local function onUpdate(dt)
    delta = delta - dt
    if delta > 0 then
        return
    end
    delta = 31
    updateMwVars()
end

return {
    engineHandlers = {
        onPlayerAdded = updateMwVars,
        onUpdate = onUpdate,
        onLoad = loadState,
    }
}
