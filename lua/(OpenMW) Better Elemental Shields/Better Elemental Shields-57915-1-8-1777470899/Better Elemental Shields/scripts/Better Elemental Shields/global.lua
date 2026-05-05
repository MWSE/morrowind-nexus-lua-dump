local types = require('openmw.types')
I = require('openmw.interfaces')
storage = require('openmw.storage')
async = require('openmw.async')
world = require('openmw.world')
util = require('openmw.util')
core = require('openmw.core')
v3 = util.vector3
require "scripts.Better Elemental Shields.settings"

local ACTOR_SCRIPT = 'scripts/Better Elemental Shields/actor.lua'
local TORCH_ID = "BES_dummy_li"
local NUM_LIGHTS = 4
local LIGHT_RADIUS = 75  -- Distance from player
local LIGHT_HEIGHT = 50  -- Height offset

-- Calculate offset positions for lights in a circle
local function getLightOffset(index)
	local angle = (index - 1) * (2 * math.pi / NUM_LIGHTS)
	return v3(
		math.cos(angle) * LIGHT_RADIUS,
		math.sin(angle) * LIGHT_RADIUS,
		LIGHT_HEIGHT
	)
end

local function onObjectActive(object)
	if not types.NPC.objectIsInstance(object) and not types.Creature.objectIsInstance(object) then
		return
	end
	
	local actorId = object.id
	
	object:addScript(ACTOR_SCRIPT)
end

-- Handle unhook request from actor going inactive
local function onUnhookActor(data)
	if data.actor and data.actor:isValid() then
		data.actor:removeScript(ACTOR_SCRIPT)
	end
end

local function onUpdate()
	-- Update torch positions to follow their players
	for playerId, torchData in pairs(saveData.activeTorches) do
		local player = torchData.player
		local torches = torchData.torches
		
		if player and player:isValid() and torches and not torchData.remove then
			if player.cell then
				for i, torch in ipairs(torches) do
					if torch and torch:isValid() then
						local offset = getLightOffset(i)
						torch:teleport(player.cell, player.position + offset)
					end
				end
			end
		elseif not torchData.teleported then
			if torches then
				for _, torch in ipairs(torches) do
					if torch and torch:isValid() then
						torch:teleport(torch.cell, torch.position - v3(0,0,2000))
					end
				end
			end
			torchData.remove = true
			torchData.teleported = true
		else
			-- Clean up invalid entries
			if torches then
				for _, torch in ipairs(torches) do
					if torch and torch:isValid() then
						torch:remove()
					end
				end
			end
			saveData.activeTorches[playerId] = nil
		end
	end
end

local function onLoad(data)
	saveData = data or {
		activeTorches = {} -- indexed by player.id = {player, torches = {}}
	}
end

local function onSave()
	return saveData
end

local function toggleTorch(data)
	local player = data[1]
	local status = data[2] -- bool: true = create torches, false = remove torches
	
	if not player or not player:isValid() then 
		return 
	end
	
	local playerId = player.id
	
	if status then
		-- Create torches if they don't exist for this player
		if not saveData.activeTorches[playerId] then
			local torches = {}
			for i = 1, NUM_LIGHTS do
				local torch = world.createObject(TORCH_ID, 1)
				if torch then
					table.insert(torches, torch)
				end
			end
			
			if #torches > 0 and player.cell then
				saveData.activeTorches[playerId] = {
					player = player,
					torches = torches
				}
			end
		end
	else
		-- Remove torches if they exist
		local torchData = saveData.activeTorches[playerId]
		if torchData then
			torchData.remove = true
		end
	end
end

return {
	engineHandlers = {
		onObjectActive = onObjectActive,
		onUpdate = onUpdate,
		onLoad = onLoad,
		onInit = onLoad,
		onSave = onSave,
	},
	eventHandlers = {
		ElementalShields_unhookActor = onUnhookActor,
		ElementalShields_toggleTorch = toggleTorch,
	}
}