-- scanner.lua
--[[
    BookWorm for OpenMW
    Copyright (C) 2026 [zerac]

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org>.
--]]
 
local camera = require('openmw.camera')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local async = require('openmw.async')
local self = require('openmw.self')
local input = require('openmw.input') -- Added for Idle check

local scanner = {}

function scanner.findBestBook(maxDist, callback)
    -- OPTIMIZATION: If the player is tabbed out or completely idle, skip the raycast
    if input.isIdle() and camera.getMode() ~= camera.MODE.Preview then 
        return 
    end

    local camPos = camera.getPosition()
    local lookDir = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
    
    -- Reach Adaptation
    local camDist = camera.getThirdPersonDistance()
    local effectiveMax = maxDist + camDist
    local rayEnd = camPos + (lookDir * effectiveMax)

    nearby.asyncCastRenderingRay(
        async:callback(function(result)
            if result.hit and result.hitObject and result.hitObject.type == types.Book then
                callback(result.hitObject)
            else
                callback(nil)
            end
        end),
        camPos,
        rayEnd,
        { ignore = self }
    )
end

return scanner