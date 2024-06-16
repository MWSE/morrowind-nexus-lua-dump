local computeBoundingBoxes = false

local storage = require('openmw.storage')
local modData = storage.globalSection('HPBars')
if not modData:get("heightDB") then
	modData:set("heightDB", {})
end

local async = require('openmw.async')
local types = require('openmw.types')
local core = require('openmw.core')
local acti = require("openmw.interfaces").Activation
local util = require('openmw.util')
local world = require('openmw.world')
local I = require("openmw.interfaces")
local playerProgress = {}
local queue = {}
local lastObject = nil
local lastId = nil

	function HPBars_Clear(param)
		if lastObject then 
			lastObject.enabled = false
			lastObject = nil
		end
	end
	
	function HPBars_CreateObject(param)
		if lastObject then 
			lastObject.enabled = false
			lastObject = nil
		end
		local actor= world.createObject(param.recordId)
		actor:teleport(param.cell,param.position)
		lastObject = actor
		resetPos = param.position
		resetCell= param.cell
		lastId =actor.id
		--lastObject:setScale(3)
	end
if computeBoundingBoxes then
	function onUpdate()
		for a,b in pairs(world.activeActors) do
			if not types.Player.objectIsInstance(b) and b~=lastObject then
				--print(a,b)
				b.enabled = false
			end
			if b.id == lastId then
				b.enabled = true
				b:teleport(resetCell,resetPos)
			end
		end
	end
end

return {
engineHandlers = {
		onUpdate = onUpdate,
	},
    eventHandlers = {
		HPBars_CreateObject = HPBars_CreateObject,
		HPBars_Clear = HPBars_Clear,
    }
}

--(-0.25228118896484375, -18.89730072021484375, 91.965118408203125)
--        (170.847442626953125, 81.17101287841796875, 67.776947021484375)