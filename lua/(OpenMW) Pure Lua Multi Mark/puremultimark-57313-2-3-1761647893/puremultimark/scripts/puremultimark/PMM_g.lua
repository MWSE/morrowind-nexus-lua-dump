
local I = require('openmw.interfaces')
world = require('openmw.world')
types = require('openmw.types')
core = require('openmw.core')
local vfs = require('openmw.vfs')

-- TeleportCoordinator
local storage = require('openmw.storage')
local teleportState = storage.globalSection('TeleportCoordinator')

local function loadLoc(data)
	local player = data[1]
	local loc = data[2]
	if loc.cell then
		player:teleport(loc.cell, loc.position, {rotation = loc.rotation})
	else
		player:teleport(world.getExteriorCell(loc.gridX, loc.gridY), loc.position, {rotation = loc.rotation})
	end
end


local function onLoad(data)
	teleportState:reset()
	saveData = data or {
		version = 1,
	}
end

local function onSave()
	return saveData
end

local function onObjectActive(object)
	if types.Actor.objectIsInstance(object) and not types.Actor.isDead(object) then
		object:addScript("scripts/puremultimark/PMM_a.lua")
	end
end

local function unhookObject(object)
	if not object:isValid() then return end
	object:removeScript("scripts/puremultimark/PMM_a.lua")
end



local function catchUpTeleport(data)
	local npc = data[1]
	local player = data[2]

	if not npc:isValid() or not npc.enabled then return end
	
	if types.Actor.isDead(npc) then
		object:removeScript("scripts/puremultimark/PMM_a.lua")
		return
	end
	
	-- Check if already teleporting recently
	local actorId = npc.id
	local currentTime = core.getRealTime()
	local lastTeleport = teleportState:get(actorId)
	
	-- If teleported within last 1 second, skip
	if lastTeleport and (currentTime - lastTeleport) < 1 then
		print("PMM Already teleporting", npc)
		return
	else
		print("PMM teleporting", npc)
	end
	
	-- Mark teleport time and teleport
	teleportState:set(actorId, currentTime)
	npc:teleport(player.cell, player.position)
end

return {
	engineHandlers = { 
		onObjectActive = onObjectActive,
		onLoad = onLoad,
		onInit = onLoad,
		onSave = onSave,
		onUpdate = onUpdate,
	},
	eventHandlers = {
		PMM_loadLoc = loadLoc,
		PMM_catchUpTeleport = catchUpTeleport,
		PMM_unhookObject = unhookObject,
	}
} 