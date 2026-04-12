local self     = require('openmw.self')
local nearby   = require('openmw.nearby')
local core     = require('openmw.core')
local types    = require('openmw.types')
local util     = require('openmw.util')
local async    = require('openmw.async')
local storage  = require('openmw.storage')
local ui       = require('openmw.ui')
local I        = require('openmw.interfaces')
local v3       = util.vector3

local MODNAME = "HideInBushes"
local EFFECT  = core.magic.EFFECT_TYPE

local bush = require('scripts.hideinbushes.flora')

-- settings

I.Settings.registerPage {
	key = MODNAME,
	l10n = "none",
	name = "Hide In Bushes                                                   ", -- lol
	description = "Immersive stealth mechanic to let you hide in bushes.",
}

I.Settings.registerGroup {
	key = "Settings" .. MODNAME,
	page = MODNAME,
	l10n = "none",
	name = "General",
	description = "",
	permanentStorage = true,
	order = 0,
	settings = {
		{
			key      = "DETECTION_RADIUS",
			name     = "Detection Radius",
			description = "How close to bushes you need to be (in game units)",
			renderer = "number",
			default  = 100,
			argument = { integer = true, min = 15, max = 5000 },
		},
		{
			key      = "CHAMELEON_MAGNITUDE",
			name     = "Chameleon Magnitude",
			description = "Strength of the Chameleon effect applied while hiding",
			renderer = "number",
			default  = 50,
			argument = { integer = true, min = 1, max = 100 },
		},
		{
			key      = "GRACE_DURATION",
			name     = "Grace Duration",
			description = "Seconds the effect lingers after leaving bushes.",
			renderer = "number",
			default  = 0.25,
			argument = { min = 0, max = 10.0 },
		},
		{
			key      = "INTERIOR_TOGGLE",
			name     = "Enable Hiding in Interiors",
			description = "Note that many houseplants are considered bushes because Todd.",
			renderer = "checkbox",
			default  = false,
		},
		{
			key      = "WATER_HIDING",
			name     = "Enable Hiding in Water",
			description = "Grants the Chameleon effect when sneaking while submerged under scum or lily pads.",
			renderer = "checkbox",
			default  = true,
		},
		{
			key      = "DEBUG_MODE",
			name     = "Debug Mode",
			description = "Visualizes the raycasts",
			renderer = "checkbox",
			default  = false,
		},
		{
			key      = "RAY_COUNT",
			name     = "Ray Count",
			description = "Number of directional rays cast in a circle to detect a bush.More rays = more reliable detection but longer sweep time.",
			-- \nOnly one is fired at a time which rotates around x amount of times.\nEach direction fires at two heights, so total rays per sweep = this x2.\n
			renderer = "number",
			default  = 12,
			argument = { integer = true, min = 4, max = 32 },
		},
	},
}

-- live setting values
local settingsSection = storage.playerSection("Settings" .. MODNAME)

local DETECTION_RADIUS
local CHAMELEON_MAGNITUDE
local INTERIOR_TOGGLE
local WATER_HIDING
local RAY_COUNT
local DEBUG_MODE
local GRACE_DURATION

local function readAllSettings()
	DETECTION_RADIUS    = settingsSection:get("DETECTION_RADIUS")
	CHAMELEON_MAGNITUDE = settingsSection:get("CHAMELEON_MAGNITUDE")
	INTERIOR_TOGGLE     = settingsSection:get("INTERIOR_TOGGLE")
	if INTERIOR_TOGGLE == nil then INTERIOR_TOGGLE = true end
	WATER_HIDING        = settingsSection:get("WATER_HIDING") or false
	RAY_COUNT           = settingsSection:get("RAY_COUNT")
	DEBUG_MODE          = settingsSection:get("DEBUG_MODE")
	GRACE_DURATION      = settingsSection:get("GRACE_DURATION") or 1.5
end

readAllSettings()

settingsSection:subscribe(async:callback(function()
	readAllSettings()
end))

-- saveData.ringBuffer     -- [slot] = object.id on hit, or false on miss
-- saveData.buffActive     -- if chameleon is applied
-- saveData.graceRemaining -- seconds until buff removal after leaving bush/water
-- saveData.appliedMag     -- tracked to undo magnitude that is added
-- saveData.waterActive    -- true if a water-surface ray hit scum or a lilypad this cycle
-- saveData.waterRingBuffer -- {[1], [2]} last result of each water ray slot
local scanning       = false   -- true while sneaking and firing rays; false = idle

local RAY_HEIGHT     = 70      -- ray origin offset: roughly waist height
local RAY_HEIGHT_LOW = 45      -- ray origin offset: ankle height for low bushes

-- Water ray lateral offsets: two slightly spread positions for better surface coverage
local WATER_RAY_OFFSETS = { v3(8, 0, 0), v3(-8, 0, 0) }
local WATER_DEPTH_CHECK = -40  -- player must be this far below waterLevel to qualify

-- Ring Buffer
-- one ray fires per frame for a sweep
local raySchedule       = {}  -- list of {type, height, dirIndex} or {type="water", offsetIndex}
local ringSize          = 0   -- total slots = (RAY_COUNT x2) [+ 2 if WATER_HIDING]
local bushRingSize      = 0   -- bush-only slots = RAY_COUNT x2
local callbackSlot      = 1   -- next bush ring slot to write (wraps 1..bushRingSize)
local waterCallbackSlot = 1   -- next water ring slot to write (wraps 1..2)
local castingSlot       = 1   -- which schedule slot fires this frame (wraps 1..ringSize)

local rayDirs        = {}   -- unit direction vectors, evenly spaced in a circle
local builtForCount  = 0    -- last RAY_COUNT we built the schedule for (rebuild guard)
local builtWithWater = false -- whether the schedule was built with WATER_HIDING on

local function rebuildSchedule()
	if RAY_COUNT == builtForCount and WATER_HIDING == builtWithWater then return end
	builtForCount  = RAY_COUNT
	builtWithWater = WATER_HIDING

	-- horizontal direction vectors
	rayDirs = {}
	local step = (2 * math.pi) / RAY_COUNT
	for i = 1, RAY_COUNT do
		local angle = step * (i - 1)
		rayDirs[i] = v3(math.sin(angle), math.cos(angle), 0)
	end

	-- for each direction, fire waist-height then ankle-height
	-- {N-high, N-low, NE-high, NE-low, E-high, E-low}
	raySchedule = {}
	for i = 1, RAY_COUNT do
		raySchedule[#raySchedule + 1] = { type = "bush", height = RAY_HEIGHT,     dirIndex = i }
		raySchedule[#raySchedule + 1] = { type = "bush", height = RAY_HEIGHT_LOW, dirIndex = i }
		-- First water slot fires halfway through the bush sweep
		if WATER_HIDING and i == math.floor(RAY_COUNT / 2) then
			raySchedule[#raySchedule + 1] = { type = "water", offsetIndex = 1 }
		end
	end

	-- Second water slot at the end of the sweep
	if WATER_HIDING then
		raySchedule[#raySchedule + 1] = { type = "water", offsetIndex = 2 }
	end

	ringSize        = #raySchedule
	bushRingSize    = RAY_COUNT * 2
	castingSlot     = 1
	callbackSlot    = 1
	waterCallbackSlot = 1
	-- saveData.waterRingBuffer = { false, false }
	-- for i = 1, ringSize do saveData.ringBuffer[i] = false end -- NOT resetting results to not lose invisibility when saving
end

local function clearRing()
	for i = 1, ringSize do saveData.ringBuffer[i] = false end
	saveData.waterRingBuffer[1] = false
	saveData.waterRingBuffer[2] = false
	saveData.waterActive = false
end

local function isBush(obj)
	if not obj or not obj:isValid() then return false end
	return bush[obj.recordId] == true
end

-- caching
local uniqueBushIds = {}

-- full ring scan for distinct bushes
local function countUniqueBushes()
	for k in pairs(uniqueBushIds) do uniqueBushIds[k] = nil end
	local count = 0
	for i = 1, bushRingSize do
		local id = saveData.ringBuffer[i]
		if id and not uniqueBushIds[id] then
			uniqueBushIds[id] = true
			count = count + 1
		end
	end
	return count
end

local function applyBuff()
	if saveData.buffActive then return end
	local mag = CHAMELEON_MAGNITUDE
	types.Actor.activeEffects(self):modify(mag, EFFECT.Chameleon)
	saveData.appliedMag = mag
	saveData.buffActive = true
end

local function removeBuff()
	if not saveData.buffActive then return end
	types.Actor.activeEffects(self):modify(-saveData.appliedMag, EFFECT.Chameleon)
	saveData.appliedMag = 0
	saveData.buffActive = false
end

-- Bush Ray Callback
local rayCallback = async:callback(function(result)
	-- Write to ring
	if result.hit and isBush(result.hitObject) then
		if DEBUG_MODE then
			print(result.hit, result.hitObject, result.hitPos)
			if result.hit then
				core.sendGlobalEvent("SpawnVfx", {
					model = "meshes/e/magic_hit_conjure.nif",
					position = result.hitPos,
					options = {scale = 0.3}
				})
			end
		end
		saveData.ringBuffer[callbackSlot] = result.hitObject.id
	else
		saveData.ringBuffer[callbackSlot] = false
	end
	callbackSlot = (callbackSlot % bushRingSize) + 1

	-- how many distinct bushes are in the ring
	local bushCount = countUniqueBushes()
	if bushCount > 0 or saveData.waterActive then
		-- 2+ distinct bushes = player is between cover, so increase grace window
		if bushCount > 0 then
			saveData.graceRemaining = (bushCount >= 2) and (GRACE_DURATION * 2) or GRACE_DURATION
		end
		saveData.graceRemaining = (bushCount >= 2) and (GRACE_DURATION * 2) or GRACE_DURATION
		-- if setting changed mid-buff, re-apply at new value
		if saveData.buffActive and saveData.appliedMag ~= CHAMELEON_MAGNITUDE then
			removeBuff()
			applyBuff()
		else
			applyBuff()
		end
	end
end)

-- Water Ray Callback
local waterRayCallback = async:callback(function(result)
	local cell       = self.cell
	local waterLevel = cell and cell.waterLevel
	local submerged  = waterLevel and (self.position.z < waterLevel + WATER_DEPTH_CHECK)


	local hit = submerged and result.hitObject
	if hit then
		local rid = hit.recordId
		if DEBUG_MODE then
			print("water object:", hit.recordId)
		end
		hit = rid:find("scum") or rid:find("lilypad")
	end

	saveData.waterRingBuffer[waterCallbackSlot] = hit or false
	saveData.waterActive = saveData.waterRingBuffer[1] or saveData.waterRingBuffer[2]
	waterCallbackSlot = (waterCallbackSlot % 2) + 1

	if saveData.waterActive then
		saveData.graceRemaining = GRACE_DURATION
		if saveData.buffActive and saveData.appliedMag ~= CHAMELEON_MAGNITUDE then
			removeBuff()
		end
		applyBuff()
	end
end)

local function onUpdate(dt)
	if core.isWorldPaused() then return end

	rebuildSchedule()

	if types.Actor.isDead(self) then
		removeBuff()
		saveData.graceRemaining = 0
		saveData.waterActive = false
		scanning = false
		return
	end

	local cell = self.cell
	if cell and not cell.isExterior and not INTERIOR_TOGGLE then
		removeBuff()
		saveData.graceRemaining = 0
		saveData.waterActive = false
		scanning = false
		return
	end

	if not self.controls.sneak then
		removeBuff()
		clearRing()
		saveData.graceRemaining = 0
		scanning = false
		return
	end

	scanning = true

	-- Tick grace; remove buff when it runs out
	if saveData.graceRemaining > 0 then
		saveData.graceRemaining = saveData.graceRemaining - dt
	elseif saveData.buffActive then
		removeBuff()
	end

	-- fire one ray this frame
	-- hysteresis: while buffed, cast further so player must walk away to lose cover
	local radius = saveData.buffActive and (DETECTION_RADIUS * 1.5) or DETECTION_RADIUS

	local entry    = raySchedule[castingSlot]
	local slotType = entry and entry.type or "bush"

	-- ── Cast: water slot ─────────────────────────────────────────────────────
	if slotType == "water" then
		-- Always fire a ray (even a dummy) so the water callback counter stays in sync.
		-- If the cell has no water we point the ray straight up — it won't hit scum.
		local waterLevel = cell and cell.waterLevel
		local origin, target

		if waterLevel then
			local offset = WATER_RAY_OFFSETS[entry.offsetIndex]
			local ox = self.position.x + offset.x
			local oy = self.position.y + offset.y
			origin = v3(ox, oy, waterLevel + 15)
			target = v3(ox, oy, waterLevel - 15)
		else
			-- dummy: short upward ray that won't hit anything surface-like
			origin = self.position
			target = self.position + v3(0, 0, 5)
		end

		if DEBUG_MODE and waterLevel then
			core.sendGlobalEvent("SpawnVfx", {
				model = "meshes/e/magic_hit_conjure.nif",
				position = origin,
				options = {scale = 0.05}
			})
		end

		nearby.asyncCastRenderingRay(waterRayCallback, origin, target, {ignore = self})

	-- ── Cast: bush slot ──────────────────────────────────────────────────────
	else
		local direction = rayDirs[entry.dirIndex]
		local height    = entry.height

		local origin    = self.position + v3(0, 0, height)
		local target    = origin + direction * radius

		if DEBUG_MODE then
			core.sendGlobalEvent("SpawnVfx", {
				model = "meshes/e/magic_hit_conjure.nif",
				position = origin,
				options = {scale = 0.01}
			})
			core.sendGlobalEvent("SpawnVfx", {
				model = "meshes/e/magic_hit_conjure.nif",
				position = target,
				options = {scale = 0.05}
			})
		end

		nearby.asyncCastRenderingRay(rayCallback, origin, target, {ignore = self})
	end

	-- Advance to next slot (wraps around to 1 after ringSize)
	castingSlot = (castingSlot % ringSize) + 1
end

local function onLoad(data)
	saveData = data or {}
	saveData.ringBuffer     = saveData.ringBuffer     or {}
	saveData.graceRemaining = saveData.graceRemaining or 0
	saveData.appliedMag     = saveData.appliedMag     or 0
	saveData.waterActive    = saveData.waterActive    or false
	saveData.waterRingBuffer = saveData.waterRingBuffer or { false, false }
end

local function onSave()
	return saveData
end

return {
	engineHandlers = {
		onUpdate = onUpdate,
		onLoad   = onLoad,
		onInit   = onLoad,
		onSave   = onSave,
	},
}