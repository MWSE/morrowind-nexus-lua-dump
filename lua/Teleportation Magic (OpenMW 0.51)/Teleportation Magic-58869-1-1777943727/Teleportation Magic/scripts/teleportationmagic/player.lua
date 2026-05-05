MODNAME = "TeleportationMagic"
I = require('openmw.interfaces')
types = require('openmw.types')
core = require('openmw.core')
self = require('openmw.self')
camera = require('openmw.camera')
nearby = require('openmw.nearby')
util = require('openmw.util')
async = require('openmw.async')
ui = require('openmw.ui')

local db = require('scripts.teleportationmagic.tpDatabase') -- db[effId]

local FLOOR_NORMAL_THRESHOLD = 0.7
local FLOOR_OFFSET = 120
local WALL_OFFSET = 50
local FLOOR_PROBE_DEPTH = 10000
local FAIL_SOUND = "Spell Failure Mysticism"

-- engine projectile constants
-- launch z-offset = halfExtents.z * 2 * TorsoHeight (0.75); ~96 for default-sized player
local LAUNCH_Z_OFFSET = 96
-- fTargetSpellMaxSpeed default at 1
local PROJECTILE_SPEED = 1000
-- engine despawn distance
local PROJECTILE_MAX_RANGE = 72000

I.SkillProgression.addSkillUsedHandler(function(skillid, params)
	if skillid ~= "mysticism" then return end
	if params.useType ~= I.SkillProgression.SKILL_USE_TYPES.Spellcast_Success then return end
	local spell = types.Player.getSelectedSpell(self)
	if not spell then return end
	local entry, magicId
	for _, eff in ipairs(spell.effects) do
		if db[eff.id] then
			entry = db[eff.id]
			magicId = eff.id
			break
		end
	end
	if not entry then return end
	
	local startPos = self.position + util.vector3(0, 0, LAUNCH_Z_OFFSET)
	local rot = self.rotation
	local rotYaw = rot:getYaw()
	local rotPitch = rot:getPitch()
	local cosPitch = math.cos(rotPitch)
	local direction = util.vector3(
		math.sin(rotYaw) * cosPitch,
		math.cos(rotYaw) * cosPitch,
		-math.sin(rotPitch)
	)
	local endPos = startPos + direction * PROJECTILE_MAX_RANGE
	local castYaw = camera.getYaw()
	
	local function sendSpawn(spawnPos, timeToHit)
		core.sendGlobalEvent("PurplePortal_spawnPortal", {
			player = self,
			position = spawnPos,
			magicId = magicId,
			yaw = castYaw,
			timeToHit = timeToHit,
		})
	end
	
	-- engine feature: raycast against heightmap can miss
	local CT = nearby.COLLISION_TYPE
	local solidMask = util.bitOr(CT.World, CT.Door, CT.Actor)
	local solidRay = nearby.castRay(startPos, endPos, { ignore = self, collisionType = solidMask })
	local terrainRay = nearby.castRay(startPos, endPos, { collisionType = CT.HeightMap, radius = 10 })
	
	local ray
	if solidRay.hit and terrainRay.hit then
		local dSolid = (solidRay.hitPos - startPos):length2()
		local dTerrain = (terrainRay.hitPos - startPos):length2()
		ray = (dSolid < dTerrain) and solidRay or terrainRay
	else
		ray = solidRay.hit and solidRay or terrainRay
	end
	
	if not ray.hit or not ray.hitPos or not ray.hitNormal then
		core.sound.playSound3d(FAIL_SOUND, self)
		return
	end
	local hitPos = ray.hitPos
	local timeToHit = (hitPos - startPos):length() / PROJECTILE_SPEED
	
	if ray.hitNormal.z >= FLOOR_NORMAL_THRESHOLD then
		sendSpawn(hitPos + util.vector3(0, 0, FLOOR_OFFSET), timeToHit)
		return
	end
	
	local spawnPos = hitPos + ray.hitNormal * WALL_OFFSET
	local probeEnd = spawnPos - util.vector3(0, 0, FLOOR_PROBE_DEPTH)
	local downSolid = nearby.castRay(spawnPos, probeEnd, { ignore = self, collisionType = solidMask })
	local downTerrain = nearby.castRay(spawnPos, probeEnd, { collisionType = CT.HeightMap, radius = 10 })
	local downRay
	if downSolid.hit and downTerrain.hit then
		downRay = (downSolid.hitPos.z > downTerrain.hitPos.z) and downSolid or downTerrain
	else
		downRay = downSolid.hit and downSolid or downTerrain
	end
	if downRay.hit and downRay.hitPos then
		local minZ = downRay.hitPos.z + FLOOR_OFFSET
		if spawnPos.z < minZ then
			spawnPos = util.vector3(spawnPos.x, spawnPos.y, minZ)
		end
	end
	sendSpawn(spawnPos, timeToHit)
end)

local function setLook(data)
	if data.yaw then camera.setYaw(data.yaw) end
	if data.pitch then camera.setPitch(data.pitch) end
end

local tomesRegistered = false
local function onStart()
	async:newUnsavableSimulationTimer(0.001, function()
		if tomesRegistered then return end
		if not I.SpellTomes or not I.SpellTomes.registerTome then return end
		tomesRegistered = true
		for _, entry in pairs(db) do
			I.SpellTomes.registerTome({
				tomeId = "spelltome_" .. entry.spell,
				spellId = entry.spell,
			--	distributeToClasses = false,
			--	allowRestockWhenKnown = false,
				weight = 0.8,
			})
		end
	end)
end

local function onConsoleCommand(mode, command)
	local cmd = command:lower():gsub("^lua%s+", ""):gsub("^%s+", ""):gsub("%s+$", "")
	if cmd ~= "pp_giveall" then return end
	
	local list = types.Actor.spells(self)
	local count = 0
	for _, entry in pairs(db) do
		list:add(entry.spell)
		count = count + 1
	end
	ui.printToConsole("Teleportation Magic added " .. count .. " teleport spells.", ui.CONSOLE_COLOR.Success)
end

return {
	engineHandlers = {
		onInit = onStart,
		onLoad = onStart,
		onConsoleCommand = onConsoleCommand,
	},
	eventHandlers = {
		TPM_setLook = setLook,
	},
}