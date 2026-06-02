-- iSmith player side: anvil interaction, hammer minigame
local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local camera = require('openmw.camera')
local ambient = require('openmw.ambient')
local ui = require('openmw.ui')
local input = require('openmw.input')
local async = require('openmw.async')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local I = require('openmw.interfaces')

local v3 = util.vector3
local v2 = util.vector2

-- -------------------------------------------------- tunables --------------------------------------------------
local SPOT_INTERVAL       = 1.4  -- seconds between spawns
local SPOT_LIFETIME       = 0.8  -- seconds a spot stays hittable before expiring as a miss
local SPOT_RADIUS_SCREEN  = 0.08 -- hit window (fraction of screen height)
local SPOT_OFFSET_XY      = 22   -- max horizontal jitter from workpiece center
local SPOT_OFFSET_Z       = 6    -- vertical jitter
local ANVIL_HIT_RANGE     = 320  -- max ray distance for a registered hit
local ANVIL_TOP_LIFT      = 0    -- extra z lift above the anvil's bbox top
local MINIGAME_HIT_TARGET = 6    -- successful hits required to finish the craft
local SPOT_POOL_TARGET    = 4    -- prefetched workpiece-surface positions kept ready
local SPOT_POOL_RAYS_PER_FRAME = 1  -- amortise raycast cost across frames
local DEBUG_HITS = true    -- per-swing readout of dist / aim / quality

-- forge anvils by recordid; substring match is unsafe (anvil = cyrodiil city)
local ANVIL_IDS = {
	["furn_anvil00"]             = true,
	["t_com_var_anvil_01"]       = true,
	["pc_m1_anv_gr_sm_anvil"]    = true,
	["ab_furn_daeforge"]         = true,
	--["t_imp_setgc_i_forge_01"]         = true,
}

local ANVIL_OFFSETS = {
	["furn_anvil00"] = v3(0, 15, 0),
	--["t_com_var_anvil_01"]       = v3(),
	["pc_m1_anv_gr_sm_anvil"]    = v3(0, 15, 0),
}

local WORKPIECE_VFX_ID = tostring(self.object.id)
local SPOT_VFX_PREFIX  = "ismith_spot_"
local FEEDBACK_VFX_PREFIX = "ismith_fb_"

-- tooltip
local TOOLTIP_REL_POSITION = v2(0.5, 0.55)
local TOOLTIP_NAME_COLOR   = util.color.rgb(0.85, 0.85, 0.85)
local TOOLTIP_HINT_COLOR   = util.color.rgb(1.00, 0.92, 0.65)

-- VFX definition
local VFX_SPOT     = {
	mesh  = "meshes/e/magic_area_rest.nif",
	z     = -1,
	scale = 0.7,
}
local VFX_PERFECT  = {
	mesh  = "meshes/e/magic_cast_alt.nif",
	z     = 0,
	scale = 0.3,
}
local VFX_GOOD     = {
	mesh  = "meshes/iSmith/steam_lavariver.nif",
	z     = -5,
	scale = 0.1,
}
local VFX_MISS     = {
	mesh  = "meshes/e/magic_hit_dst.nif",
	z     = -10,
	scale = 0.15,
}

-- -------------------------------------------------- state --------------------------------------------------
local pendingAnvil = nil

-- sharedray look target
local lookedAtAnvil = nil
local anvilTooltip  = nil

local minigame = {
	active        = false,
	anvil         = nil,        -- anvil being hammered
	cellName      = nil,
	workpiecePos  = nil,        -- world anchor on the anvil top
	itemModel     = nil,
	spot          = nil,        -- { pos, vfxId, idx, t0 }
	nextSpotAt    = 0,
	spotCounter   = 0,
	workpieceCenter   = nil,
	workpieceHalfSize = nil,
	workpiece         = nil,    -- activator, for ray identity
	hitPool           = {},     -- prefetched surface points
}

-- -------------------------------------------------- helpers --------------------------------------------------
local function getRecipeModel(recipe)
	if recipe.model then return recipe.model end
	local rid = recipe.id
	if not rid then return nil end
	local typesToTry = { types.Weapon, types.Miscellaneous, types.Armor, types.Lockpick, types.Probe, types.Repair }
	for _, t in ipairs(typesToTry) do
		local rec = t.records and t.records[rid]
		if rec and rec.model and rec.model ~= "" then
			return rec.model
		end
	end
	return nil
end

local function spawnVfx(model, pos, opts)
	core.sendGlobalEvent("SpawnVfx", {
		model = model,
		position = pos,
		options = opts or {},
	})
end

local function removeVfx(vfxId)
	core.sendGlobalEvent("RemoveVfx", vfxId)
end

-- blunt 1h/2h-close named "hammer"; mirrors the CF tool gate
local function holdingHammer()
	local w = types.Actor.getEquipment(self.object, types.Actor.EQUIPMENT_SLOT.CarriedRight)
	if not w or w.type ~= types.Weapon then return false end
	local rec = types.Weapon.record(w)
	if not rec then return false end
	local blunt = rec.type == types.Weapon.TYPE.BluntOneHand
		or rec.type == types.Weapon.TYPE.BluntTwoClose
	local named = rec.id:lower():find("hammer") or rec.name:lower():find("hammer")
	return blunt and named ~= nil
end

-- -------------------------------------------------- minigame lifecycle --------------------------------------------------
local function endSpot(playMissSound)
	if not minigame.spot then return end
	removeVfx(minigame.spot.vfxId)
	if playMissSound then
		ambient.playSound("Weapon Swish", { volume = 0.6, pitch = 0.7 })
		core.sendGlobalEvent("iSmith_recordHit", { quality = 0 })
		spawnVfx(VFX_MISS.mesh, minigame.spot.pos + v3(0, 0, VFX_MISS.z), {
			vfxId = FEEDBACK_VFX_PREFIX .. minigame.spot.idx,
			scale = VFX_MISS.scale,
			useAmbientLight = false,
		})
	end
	minigame.spot = nil
end

local function spawnSpot(now)
	minigame.spotCounter = minigame.spotCounter + 1
	local idx = minigame.spotCounter

	-- reported bbox, else fixed jitter box
	local center, hx, hy, hz
	if minigame.workpieceHalfSize then
		center = minigame.workpieceCenter
		hx = minigame.workpieceHalfSize.x
		hy = minigame.workpieceHalfSize.y
		hz = minigame.workpieceHalfSize.z
	else
		center = minigame.workpiecePos
		hx, hy, hz = SPOT_OFFSET_XY, SPOT_OFFSET_XY, SPOT_OFFSET_Z
	end

	-- prefetched surface point, else naive jitter
	local pos = table.remove(minigame.hitPool, 1)
	if not pos then
		print("[iSmith] no raycasted position")
		local jx = (math.random() * 2 - 1) * hx
		local jy = (math.random() * 2 - 1) * hy
		pos = center + v3(jx, jy, 0)
	end
	local vfxId = SPOT_VFX_PREFIX .. idx

	minigame.spot = {
		pos    = pos,
		vfxId  = vfxId,
		idx    = idx,
		t0     = now,
	}

	spawnVfx(VFX_SPOT.mesh, pos + v3(0, 0, VFX_SPOT.z), {
		vfxId = vfxId,
		scale = VFX_SPOT.scale,
	})
end

local function startMinigame(recipe, duration)
	minigame.active        = true
	minigame.anvil         = pendingAnvil
	minigame.cellName      = pendingAnvil.cell.name
	-- bbox top-center plus per-anvil nudge (anvil-local -> world, yaw only)
	local bbox = pendingAnvil:getBoundingBox()
	local anchor = v3(bbox.center.x, bbox.center.y, bbox.center.z + bbox.halfSize.z + ANVIL_TOP_LIFT)
	local nudge = ANVIL_OFFSETS[(pendingAnvil.recordId or ""):lower()]
	if nudge then
		local yawT = util.transform.rotateZ(pendingAnvil.rotation:getYaw())
		anchor = anchor + yawT:apply(nudge)
	end
	minigame.workpiecePos  = anchor
	minigame.itemModel     = getRecipeModel(recipe)
	minigame.spot              = nil
	minigame.spotCounter       = 0
	minigame.nextSpotAt        = core.getRealTime() + 0.3
	minigame.workpieceCenter   = nil
	minigame.workpieceHalfSize = nil
	minigame.workpiece         = nil
	minigame.hitPool           = {}

	-- back to gameplay; also makes CF destroy its window
	I.UI.setMode()

	-- spawn workpiece
	if minigame.itemModel then
		core.sendGlobalEvent("iSmith_spawnWorkpiece", {
			id = WORKPIECE_VFX_ID,
			cell = minigame.cellName,
			position = minigame.workpiecePos,
			rotation = util.transform.rotateZ(camera.getYaw() + math.pi / 2),
			model = minigame.itemModel,
			player = self.object,
		})
	end
end

local function endMinigame()
	if not minigame.active then return end
	minigame.active = false
	endSpot(false)
	core.sendGlobalEvent("iSmith_despawnWorkpiece", { id = WORKPIECE_VFX_ID })
	pendingAnvil = nil
	minigame.anvil = nil
end

-- -------------------------------------------------- attack handling --------------------------------------------------
local function attemptHit()
	if not minigame.active or not minigame.spot then return end

	local s = minigame.spot
	local r = SPOT_RADIUS_SCREEN

	-- spot in viewport px, normalised by screen height; v.z<=0 = behind camera
	local v = camera.worldToViewportVector(s.pos)
	local screen = ui.screenSize()
	local dx = (v.x - screen.x * 0.5) / screen.y
	local dy = (v.y - screen.y * 0.5) / screen.y
	local dist = math.sqrt(dx * dx + dy * dy)
	local outOfReach = v.z <= 0 or v.z > ANVIL_HIT_RANGE

	if outOfReach or dist > r then
		-- missed the spot
		ambient.playSound("Weapon Swish", { volume = 0.7, pitch = 0.9 })
		core.sendGlobalEvent("iSmith_recordHit", { quality = 0 })
		spawnVfx(VFX_MISS.mesh, s.pos + v3(0, 0, VFX_MISS.z), {
			vfxId = FEEDBACK_VFX_PREFIX .. s.idx,
			scale = VFX_MISS.scale,
			useAmbientLight = false,
		})
		removeVfx(s.vfxId)
		minigame.spot = nil
		if DEBUG_HITS then
			print(string.format(
				"[iSmith] miss  d=%.3f r=%.3f%s",
				dist, r, outOfReach and "  (out of reach)" or ""
			))
		end
		return
	end

	-- closer to center = better
	local aim = 1 - (dist / r)
	local quality = math.max(0, math.min(1, aim))

	-- perfect/good bucket
	local vfx, soundId, pitch
	if quality >= 0.75 then
		vfx = VFX_PERFECT
		soundId = "Item Weapon Up"
		pitch = 1.4
		ambient.playSound(soundId, { volume = 0.9, pitch = pitch })
		spawnVfx(vfx.mesh, s.pos + v3(0, 0, vfx.z), {
			vfxId = FEEDBACK_VFX_PREFIX .. s.idx,
			scale = vfx.scale,
			useAmbientLight = false,
		})
	end
	vfx = VFX_GOOD
	soundId = "Heavy Armor Hit"
	pitch = 0.9 + quality * 0.4

	ambient.playSound(soundId, { volume = 0.9, pitch = pitch })
	spawnVfx(vfx.mesh, s.pos + v3(0, 0, vfx.z), {
		vfxId = FEEDBACK_VFX_PREFIX .. s.idx,
		scale = vfx.scale,
		useAmbientLight = false,
	})
	core.sendGlobalEvent("iSmith_recordHit", { quality = quality })
	-- advance CF manual progress
	I.CraftingFramework.advanceManualCrafting(true, 1 / MINIGAME_HIT_TARGET)

	removeVfx(s.vfxId)
	minigame.spot = nil

	if DEBUG_HITS then
		print(string.format(
			"[iSmith] hit  q=%.2f  aim=%.2f  d=%.3f/%.3f",
			quality, aim, dist, r
		))
	end
end

-- -------------------------------------------------- craft start hook --------------------------------------------------
local function CraftingFramework_craftStarted(data)
	print("started", data.recipe.profession)
	if not data or not data.recipe then return end
	if data.recipe.profession ~= "iSmith" then return end
	-- wipe stale hits
	core.sendGlobalEvent("iSmith_resetHits", {})
		print(pendingAnvil)
	if pendingAnvil and pendingAnvil:isValid() then
		startMinigame(data.recipe, data.duration)
	end
end

-- CF abort: movement | health | station | ingredients | disabled
local function CraftingFramework_craftInterrupted(data)
	if not minigame.active then return end
	if data and data.profession and data.profession ~= "iSmith" then return end
	print("iSmith interrupted", data and data.reason)
	endMinigame()
end

-- -------------------------------------------------- frame loop --------------------------------------------------
local function onFrame(dt)
	-- look target + tooltip, off during minigame/menus
	local suppress = minigame.active or (I.UI.getMode() ~= nil) or not I.UI.isHudVisible()
	local target = nil
	if not suppress then
		local result = I.SharedRay and I.SharedRay.get and I.SharedRay.get()
		local hit = result and result.hitObject
		if hit and ANVIL_IDS[hit.recordId or ""] then
			target = hit
		end
	end
	if target ~= lookedAtAnvil then
		lookedAtAnvil = target
		if anvilTooltip then
			anvilTooltip:destroy()
			anvilTooltip = nil
		end
		if target then
			-- activator name, else "Anvil"
			local rec = types.Activator.records[target.recordId]
			local label = (rec and rec.name and rec.name ~= "") and rec.name or "Anvil"

			-- name line
			local nameLine = {
				type = ui.TYPE.Text,
				props = {
					text = label,
					textColor = TOOLTIP_NAME_COLOR,
					textShadow = true,
					textSize = 18,
				},
			}
			-- action hint
			local hintLine = {
				type = ui.TYPE.Text,
				props = {
					text = "[Activate]  Forge item",
					textColor = TOOLTIP_HINT_COLOR,
					textShadow = true,
					textSize = 22,
				},
			}
			-- centred vertical flex
			anvilTooltip = ui.create({
				layer = "HUD",
				type = ui.TYPE.Flex,
				props = {
					relativePosition = TOOLTIP_REL_POSITION,
					anchor = v2(0.5, 0),
					horizontal = false,
					autoSize = true,
					arrange = ui.ALIGNMENT.Center,
				},
				content = ui.content{ nameLine, hintLine },
			})
		end
	end

	if not minigame.active then return end

	local now = core.getRealTime()

	-- anvil gone mid-craft
	if not minigame.anvil or not minigame.anvil:isValid() then
		endMinigame()
		return
	end

	-- amortised hit-pool refill, capped per frame
	if #minigame.hitPool < SPOT_POOL_TARGET
		and minigame.workpiece and minigame.workpiece:isValid()
		and minigame.workpieceHalfSize
	then
		local c = minigame.workpieceCenter
		local hsz = minigame.workpieceHalfSize
		for _ = 1, SPOT_POOL_RAYS_PER_FRAME do
			local jx = (math.random() * 2 - 1) * hsz.x
			local jy = (math.random() * 2 - 1) * hsz.y
			local from = v3(c.x + jx, c.y + jy, c.z + hsz.z + 16)
			local to   = v3(c.x + jx, c.y + jy, c.z - hsz.z - 8)
			local r = nearby.castRenderingRay(from, to)
			if r.hit and r.hitObject and r.hitObject == minigame.workpiece then
				minigame.hitPool[#minigame.hitPool + 1] = r.hitPos
			end
			if #minigame.hitPool >= SPOT_POOL_TARGET then break end
		end
	end

	-- expire stale spot
	if minigame.spot and now - minigame.spot.t0 >= SPOT_LIFETIME then
		endSpot(true)
		minigame.nextSpotAt = now + SPOT_INTERVAL
	end

	-- spawn next spot when slot free
	if not minigame.spot and now >= minigame.nextSpotAt then
		spawnSpot(now)
		minigame.nextSpotAt = now + SPOT_INTERVAL
	end
end

-- -------------------------------------------------- input --------------------------------------------------

local throttleHits = 0
I.AnimationController.addTextKeyHandler("", function(groupname, key)
	if not minigame.active then return end
	if not key:find("hit") then return end
	local now = core.getSimulationTime()
	if now <= throttleHits + 0.3 then return end
	-- hammer-only
	if not holdingHammer() then
		if DEBUG_HITS then print("[iSmith] swing ignored: no hammer equipped") end
		return
	end
	throttleHits = now
	attemptHit()
end)

-- activate anvil -> crafting window
input.registerTriggerHandler("Activate", async:callback(function()
	if minigame.active then return end
	if not lookedAtAnvil or not lookedAtAnvil:isValid() then return end
	pendingAnvil = lookedAtAnvil
	I.CraftingFramework.openCraftingWindow("iSmith")
end))

-- -------------------------------------------------- finished hook --------------------------------------------------
local function onFinished(data)
	endMinigame()
	if not data then return end
	local count = data.hitCount or 0
	if count == 0 then return end
	local avg = data.minigameAverage or 0
	local label = "rough"
	if avg >= 0.85 then label = "masterwork"
	elseif avg >= 0.65 then label = "fine"
	elseif avg >= 0.4 then label = "decent"
	end
	ui.showMessage("iSmith: " .. label .. " (" .. math.floor(avg * 100) .. "%)")
	print("iSmith: " .. label .. " (" .. math.floor(avg * 100) .. "%)")
end


return {
	engineHandlers = {
		onFrame = onFrame,
		onConsoleCommand = onConsoleCommand,
	},
	eventHandlers = {
		iSmith_finished = onFinished,
		iSmith_workpieceBox = function(data)
			if not minigame.active then return end
			if data.id ~= WORKPIECE_VFX_ID then return end
			minigame.workpieceCenter   = data.center
			minigame.workpieceHalfSize = data.halfSize
			minigame.workpiece         = data.object
			print("iSmith bbox", "center=", data.center, "half=", data.halfSize)
		end,
		CraftingFramework_craftStarted = CraftingFramework_craftStarted,
		CraftingFramework_craftInterrupted = CraftingFramework_craftInterrupted,
	},
}