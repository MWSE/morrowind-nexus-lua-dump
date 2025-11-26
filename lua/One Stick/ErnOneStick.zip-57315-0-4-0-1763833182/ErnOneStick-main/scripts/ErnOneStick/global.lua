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
local world = require('openmw.world')
local aux_util = require('openmw_aux.util')

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
end

local MOD_NAME = require("scripts.ErnOneStick.ns")

local function onPause()
    world.pause(MOD_NAME)
end

local function onUnpause()
    world.unpause(MOD_NAME)
end

local function onRotate(data)
    data.object:teleport(data.object.cell, data.object.position, data.rotation)
end

local onNextFrame = nil

local function onActivate(data)
    --settings.debugPrint("onActivate(" .. aux_util.deepToString(data, 3) .. ")...")
    if world.isWorldPaused() then
        --settings.debugPrint("paused; scheduling next-frame activate")
        onNextFrame = function()
            --settings.debugPrint("doing next-frame activate")
            data.entity:activateBy(data.player)
        end
    else
        data.entity:activateBy(data.player)
    end
end

local function onUpdate(dt)
    if dt == 0 then
        return
    end
    if onNextFrame ~= nil then
        onNextFrame()
        onNextFrame = nil
    end
end

--[[local function onNewGame()
    if settings.disable() ~= true then
        settings.onNewGame()
    end
    end]]

return {
    eventHandlers = {
        [MOD_NAME .. "onPause"] = onPause,
        [MOD_NAME .. "onUnpause"] = onUnpause,
        [MOD_NAME .. "onRotate"] = onRotate,
        [MOD_NAME .. "onActivate"] = onActivate,
    },
    engineHandlers = {
        onUpdate = onUpdate,
        --onNewGame = onNewGame
    }
}
