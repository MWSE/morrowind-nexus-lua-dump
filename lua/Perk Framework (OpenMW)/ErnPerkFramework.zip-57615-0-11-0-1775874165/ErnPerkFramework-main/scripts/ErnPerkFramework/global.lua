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

local function syncGlobalVarsForPlayer(player, noYield)
    local asTable = {}
    local count = 0
    for k, v in pairs(world.mwscript.getGlobalVariables(player)) do
        asTable[k] = v
        count = count + 1
        if not noYield and count % 20 == 0 then
            coroutine.yield()
        end
    end
    mwVars:set(player.id, asTable)
    print("Done saving " .. tostring(count) .. " variables for player " .. tostring(player.id))
end

local function loadState(saved)
    for _, player in ipairs(world.players) do
        syncGlobalVarsForPlayer(player, true)
    end
end

local remainingDT = 1
local pendingCoroutines = {}
local function updateMwVars()
    for _, player in ipairs(world.players) do
        local ok
        if pendingCoroutines[player.id] == nil then
            pendingCoroutines[player.id] = coroutine.create(syncGlobalVarsForPlayer)
            ok = coroutine.resume(pendingCoroutines[player.id], player, false)
        else
            ok = coroutine.resume(pendingCoroutines[player.id])
        end
        if not ok then
            pendingCoroutines[player.id] = nil
        end
    end
end

local function onUpdate(dt)
    remainingDT = remainingDT - dt
    if remainingDT > 0 then
        return
    end
    remainingDT = 3.01
    updateMwVars()
end

return {
    engineHandlers = {
        onPlayerAdded = updateMwVars,
        onUpdate = onUpdate,
        onLoad = loadState,
        onInit = loadState,
    }
}
