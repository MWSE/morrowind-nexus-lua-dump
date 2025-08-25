
local I = require('openmw.interfaces')
world = require('openmw.world')
types = require('openmw.types')
core = require('openmw.core')
local vfs = require('openmw.vfs')


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
	saveData = data or {
		version = 1,
	}
end

local function onSave()
	return saveData
end

local function onObjectActive(object)
if types.Actor.objectIsInstance(object) then
 object:addScript("scripts/puremultimark/PMM_a.lua")
 end
end

local function unhookObject(object)
 object:removeScript("scripts/puremultimark/PMM_a.lua")
end

local function catchUpTeleport(data)
	local npc = data[1]
	local player = data[2]
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