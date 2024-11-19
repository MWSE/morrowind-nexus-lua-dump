--[[
	Mod: Perfect Placement OpenMW
	Author: Hrnchamd
	Version: 2.2beta
]]--

local async = require('openmw.async')
local core = require('openmw.core')
local util = require('openmw.util')

local itemSound = require('scripts.PerfectPlacement.itemSound')

local movement = nil
local currentObj = nil

return {
	eventHandlers = {
		["PerfectPlacement:Begin"] = function(e)
			currentObj = e.activeObj
			core.sound.playSound3d(itemSound.getPickupSound(e.activeObj), e.activeObj)
		end,
		["PerfectPlacement:Move"] = function(e)
			if currentObj then
				movement = { activeObj = e.activeObj, position = e.newPosition, rotation = e.newRotation }
			end
		end,
		["PerfectPlacement:Drop"] = function(e)
			if currentObj then
				movement = { activeObj = e.activeObj, position = e.newPosition, rotation = e.newRotation }
			end
		end,
		["PerfectPlacement:End"] = function(e)
			currentObj = nil
			core.sound.playSound3d(itemSound.getDropSound(e.activeObj), e.activeObj)
		end,
	},
	engineHandlers = {
		onUpdate = function(dt)
			if movement then
				movement.activeObj:teleport(movement.activeObj.cell, movement.position, movement.rotation)

				-- Workaround for rotation issues in 0.49dev.
				-- Issue: Certain rotations are converted to NaN and cause an object to disappear.
				-- Check if new rotation produces NaNs and reset rotation if required.
				local check = movement.activeObj.rotation * util.vector3(0, 0, 0)
				if check.x ~= check.x then -- isNaN
					movement.rotation = util.transform.identity
				else
					movement = nil
				end
			end
		end,
		onActivate = function(object, actor)
			-- Cancel movement to prevent object duplication, and notify player script.
			if object == currentObj then
				currentObj = nil
				movement = nil
				actor:sendEvent("PerfectPlacement:ObjRemoved", {})
			end
		end
	}
}