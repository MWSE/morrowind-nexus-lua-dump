--[[

Mod: Random Load Doors
Author: Pharis

--]]

local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local types = require("openmw.types")
local world = require("openmw.world")

local modInfo = require("Scripts.Pharis.RandomLoadDoors.modinfo")

local generalSettings = storage.globalSection("SettingsPlayer" .. modInfo.name)
local gameplaySettings = storage.globalSection("SettingsPlayer" .. modInfo.name .. "Gameplay")

local random = math.random

local Door = types.Door
local Lockable = types.Lockable
local Player = types.Player

local teleportDoors = {}

local function getTeleportDoors()
	for _, cell in ipairs(world.cells) do
		for _, door in ipairs(cell:getAll(Door)) do
			if (Door.isTeleport(door)) then teleportDoors[#teleportDoors + 1] = door end
		end
	end
end

local function doorActivationHandler(object, actor)
	if (not generalSettings:get("modEnable"))
		or (not Player.objectIsInstance(actor))
		or (not Door.isTeleport(object))
		or (Lockable.isLocked(object))
		or (actor.cell.name == "Seyda Neen, Census and Excise Office") then return true end

	if (random() <= gameplaySettings:get("randomizeChance")) then
		local destDoor = teleportDoors[random(1, #teleportDoors)]
		actor:teleport(Door.destCell(destDoor), Door.destPosition(destDoor), {rotation = Door.destRotation(destDoor), onGround = true})
		return false
	end
	return true
end

I.Activation.addHandlerForType(Door, doorActivationHandler)

local function onLoad(data)
	getTeleportDoors()
	math.randomseed(os.time())
end

return {
	engineHandlers = {
		onLoad = onLoad
	}
}
