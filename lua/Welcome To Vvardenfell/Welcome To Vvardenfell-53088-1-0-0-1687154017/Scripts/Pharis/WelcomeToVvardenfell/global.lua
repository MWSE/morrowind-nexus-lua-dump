--[[

Mod: Welcome To Vvardenfell
Author: Pharis

--]]

local storage = require("openmw.storage")
local types = require("openmw.types")
local util = require("openmw.util")
local world = require("openmw.world")

-- Mod info
local modInfo = require("Scripts.Pharis.WelcomeToVvardenfell.modinfo")
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- Settings
local generalSettings = storage.globalSection("SettingsPlayer" .. modName)
local gameplaySettings = storage.globalSection("SettingsPlayer" .. modName .. "Gameplay")

local Actor = types.Actor

local vec3 = util.vector3
local random = math.random
local twoPi = 2 * math.pi
local actorWhitelist = require("Scripts.Pharis.WelcomeToVvardenfell.actorwhitelist")

local function randomPositionAround(position)
	local maxHorizontalOffset = gameplaySettings:get("maxHorizontalOffset")
	local minVerticalOffset = gameplaySettings:get("minVerticalOffset")
	local maxVerticalOffset = math.max(minVerticalOffset, gameplaySettings:get("maxVerticalOffset"))

	local offsetX = random(-maxHorizontalOffset, maxHorizontalOffset)
	local offsetY = random(-maxHorizontalOffset, maxHorizontalOffset)
	local offsetZ = random(minVerticalOffset, maxVerticalOffset)

	return vec3(position.x + offsetX, position.y + offsetY, position.z + offsetZ)
end

local function randomRotation()
	return vec3(random() * twoPi, random() * twoPi, random() * twoPi)
end

local function onCreatureDeath(data)
	data.object:removeScript("Scripts/Pharis/WelcomeToVvardenfell/actor.lua")

	if (not generalSettings:get("modEnable")) then return end

	for i = 1, gameplaySettings:get("spawnsPerDeath") do
		local newSpawn = world.createObject(data.object.recordId)
		local spawnPos = data.deathPosition
		local spawnRot = data.deathRotation

		if (gameplaySettings:get("randomizeSpawnPosition")) then
			spawnPos = randomPositionAround(spawnPos)
		end

		if (gameplaySettings:get("randomizeSpawnRotation")) then
			spawnRot = randomRotation()
		end

		newSpawn:teleport("", spawnPos, {rotation = spawnRot, onGround = false})
	end
end

local function onActorActive(actor)
	if (not actorWhitelist[actor.recordId])
		or (Actor.stats.dynamic.health(actor).current <= 0)
		or (actor:hasScript("Scripts/Pharis/WelcomeToVvardenfell/actor.lua")) then return end

	actor:addScript("Scripts/Pharis/WelcomeToVvardenfell/actor.lua")
end

return {
	engineHandlers = {
		onActorActive = onActorActive
	},
	eventHandlers = {
		PharisRecursiveCreaturesOnCreatureDeath = onCreatureDeath
	}
}
