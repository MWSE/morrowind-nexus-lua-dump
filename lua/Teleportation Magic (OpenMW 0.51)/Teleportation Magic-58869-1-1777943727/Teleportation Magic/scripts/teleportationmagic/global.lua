MODNAME = "TeleportationMagic"
I = require('openmw.interfaces')
world = require('openmw.world')
types = require('openmw.types')
core = require('openmw.core')
util = require('openmw.util')
async = require('openmw.async')
v3 = util.vector3
local db = require('scripts.teleportationmagic.tpDatabase')

local destSchool = core.stats.Skill.records.destruction.school
local destHitSound = destSchool and destSchool.hitSound or nil
local destEffect = core.magic.effects.records[core.magic.EFFECT_TYPE.FireDamage]
local destHitVfxModel = destEffect and destEffect.hitStatic and types.Static.records[destEffect.hitStatic].model or nil

local PORTAL_RECORD = "pr_purpleportal"
local PORTAL_SCALE = 0.6
local ARRIVAL_OFFSET = 80 -- units behind
local ARRIVAL_LIFT = 120 -- units up
local TELEPORT_DELAY = 0.1 -- before
local ARRIVAL_LIFETIME = 1.5 -- seconds beforethe arrival portal stays
local DEPARTURE_LIFETIME = 12 -- seconds before unused despawns
local POST_IMPACT_DELAY = 2.1 -- seconds after projectile hit before portal appears

local areaVfxRec = types.Static.records["vfx_mysticismhit"]
local areaVfxModel = areaVfxRec and areaVfxRec.model or nil

local saveData
local activePortalObj = {}
local nextPendingId = 1
local pendingSpawns = {}
local latestPendingByMagic = {}

local function onLoad(data)
	saveData = data or {}
	saveData.portalMagic = saveData.portalMagic or {}
	saveData.activeByPlayer = saveData.activeByPlayer or {}
end

local DESPAWN_VFX_OFFSET = v3(0, 0, -90)

local function playEffectsAt(obj, vfxOffset)
	if not obj or not obj:isValid() then return end
	if destHitSound then
		core.sound.playSound3d(destHitSound, obj)
	end
	if destHitVfxModel then
		local pos = obj.position
		if vfxOffset then pos = pos + vfxOffset end
		world.vfx.spawn(destHitVfxModel, pos)
	end
end

local function handlePortalActivation(portal, actor)
	if portal.recordId ~= PORTAL_RECORD then return end
	local magicId = saveData.portalMagic[portal.id]
	if not magicId then return end -- if not the vfx/portal
	if not types.Player.objectIsInstance(actor) then return false end
	
	local entry = db[magicId]
	if not entry then return false end
	
	playEffectsAt(portal, DESPAWN_VFX_OFFSET)
	
	-- tp the player
	local destCell = entry.cell or ""
	local destYaw = math.rad(entry.yaw or 0)
	actor:teleport(destCell, entry.position, {
		rotation = util.transform.rotateZ(destYaw),
		onGround = false,
	})
	
	-- update camera
	actor:sendEvent("TPM_setLook", {
		yaw = destYaw,
		pitch = entry.pitch and math.rad(entry.pitch - 90) or nil,
	})
	
	saveData.portalMagic[portal.id] = nil
	if saveData.activeByPlayer[actor.id] == portal.id then
		saveData.activeByPlayer[actor.id] = nil
		activePortalObj[actor.id] = nil
	end
	portal:remove()
	
	-- spawn arrival portal after delay
	async:newUnsavableSimulationTimer(TELEPORT_DELAY, function()
		local forward = util.vector3(math.sin(destYaw), math.cos(destYaw), 0)
		local pos = entry.position - forward * ARRIVAL_OFFSET + util.vector3(0, 0, ARRIVAL_LIFT)
		
		local arrival = world.createObject(PORTAL_RECORD)
		arrival:setScale(PORTAL_SCALE)
		arrival:teleport(destCell, pos, {
			rotation = util.transform.rotateZ(destYaw),
		})
		
		I.Activation.addHandlerForObject(arrival, function() return false end)
		playEffectsAt(arrival)
		
		async:newUnsavableSimulationTimer(ARRIVAL_LIFETIME, function()
			if arrival:isValid() then
				playEffectsAt(arrival, DESPAWN_VFX_OFFSET)
				arrival:remove()
			end
		end)
	end)
	
	return false
end

I.Activation.addHandlerForType(types.Activator, handlePortalActivation)

-- events from player
local function spawnPortal(data)
	local player = data.player
	local position = data.position
	local magicId = data.magicId
	local yaw = data.yaw or 0
	local timeToHit = data.timeToHit or 0
	if not player or not player:isValid() then return end
	if not magicId or not db[magicId] then return end
	
	local pendingId = nextPendingId
	nextPendingId = nextPendingId + 1
	local pending = {}
	pendingSpawns[pendingId] = pending
	latestPendingByMagic[magicId] = pendingId
	
	async:newUnsavableSimulationTimer(timeToHit, function()
		if pending.cancelled then return end
		if areaVfxModel then
			world.vfx.spawn(areaVfxModel, position-v3(0,0,79))
		end
	end)
	
	-- portal after the delay unless an actor caught it
	async:newUnsavableSimulationTimer(timeToHit + POST_IMPACT_DELAY, function()
		pendingSpawns[pendingId] = nil
		if latestPendingByMagic[magicId] == pendingId then
			latestPendingByMagic[magicId] = nil
		end
		if pending.cancelled then return end
		if not player:isValid() then return end
		
		-- remove previous portal for this player
		local prevId = saveData.activeByPlayer[player.id]
		if prevId then
			saveData.portalMagic[prevId] = nil
			saveData.activeByPlayer[player.id] = nil
			local prevPortal = activePortalObj[player.id]
			if prevPortal and prevPortal:isValid() then
				playEffectsAt(prevPortal, DESPAWN_VFX_OFFSET)
				prevPortal:remove()
			end
			activePortalObj[player.id] = nil
		end
		
		-- create the departure portal facing the player
		local cellName = (player.cell and player.cell.name) or ""
		local portal = world.createObject(PORTAL_RECORD)
		portal:setScale(PORTAL_SCALE)
		portal:teleport(cellName, position, {
			rotation = util.transform.rotateZ(yaw + math.pi),
		})
		
		saveData.portalMagic[portal.id] = magicId
		saveData.activeByPlayer[player.id] = portal.id
		activePortalObj[player.id] = portal
		
		local portalId = portal.id
		local playerId = player.id
		async:newUnsavableSimulationTimer(DEPARTURE_LIFETIME, function()
			if saveData.portalMagic[portalId] ~= magicId then return end
			if portal:isValid() then
				playEffectsAt(portal, DESPAWN_VFX_OFFSET)
				portal:remove()
			end
			saveData.portalMagic[portalId] = nil
			if saveData.activeByPlayer[playerId] == portalId then
				saveData.activeByPlayer[playerId] = nil
				activePortalObj[playerId] = nil
			end
		end)
	end)
end

-- event from actor's tr_spells handler w a portal effect
local function actorCaught(data)
	local magicId = data and data.magicId
	if not magicId then return end
	local pendingId = latestPendingByMagic[magicId]
	if not pendingId then return end
	local p = pendingSpawns[pendingId]
	if p then p.cancelled = true end
	latestPendingByMagic[magicId] = nil
end

return {
	engineHandlers = {
		onInit = onLoad,
		onLoad = onLoad,
		onSave = function() return saveData end,
	},
	eventHandlers = {
		PurplePortal_spawnPortal = spawnPortal,
		PurplePortal_actorCaught = actorCaught,
	},
}