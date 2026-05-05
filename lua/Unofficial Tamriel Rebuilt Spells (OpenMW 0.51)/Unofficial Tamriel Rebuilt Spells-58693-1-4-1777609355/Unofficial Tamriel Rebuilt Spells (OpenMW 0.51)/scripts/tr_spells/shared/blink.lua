-- Blink: short ranged teleport but with some fun
-- self - blink where you're looking including verticality, NPCs blink in the direction they're facing
-- self preview - if enabled, while "use" is held in spell stance, suppress cast to display vfx where the player will tp to
-- touch - swap positions between the caster and actor to face each other
-- target - target is pulled to stand in melee range of caster

local EFFECT_ID = "t_mysticism_blink"

local function getCameraDirection()
	local yaw = camera.getYaw()
	local pitch = camera.getPitch()
	local cosPitch = math.cos(pitch)
	return v3(
		math.sin(yaw) * cosPitch,
		math.cos(yaw) * cosPitch,
		-math.sin(pitch)
	):normalize()
end

-- main function
local function computeBlinkDestination(magnitude, onDone)
	local range = magnitude * trData.FEET_TO_UNITS
	local bounds = types.Actor.getPathfindingAgentBounds(self)
	local halfWidth = bounds.halfExtents.x
	local playerHeight = bounds.halfExtents.z * 2 -- =133
	
	local cameraPos = camera.getPosition()
	local dir = getCameraDirection()
	local endPos = cameraPos + dir * range
	if types.Actor.isSwimming(self) then
		cameraPos = cameraPos + v3(0, 0, 30)
	end
	
	-- ward pre-check
	local wardScan = nearby.castRay(cameraPos + dir * camera.getThirdPersonDistance(), endPos, {
		ignore = self,
		collisionType = nearby.COLLISION_TYPE.AnyPhysical + nearby.COLLISION_TYPE.VisualOnly,
	})
	if wardScan.hit then
		local rid = wardScan.hitObject and wardScan.hitObject.recordId
		if rid and (rid:find("t_dae_ward_") or rid:find("t_aid_passwallward_")) then
			local wardDist = (wardScan.hitPos - cameraPos):length()
			range = math.max(0, wardDist - halfWidth - 70)
			endPos = cameraPos + dir * range
		end
	end
	
	nearby.asyncCastRenderingRay(async:callback(function(hit)
		local destination
		if not hit.hit then
			-- air teleport
			destination = endPos
		else
			local hitDist = (hit.hitPos - cameraPos):length()
			local normal = hit.hitNormal
			if normal and normal.z > 0.7 and cameraPos.z > hit.hitPos.z then
				-- flat surface below
				destination = hit.hitPos
			else
				-- fallback: slightly back (in front of wall)
				destination = cameraPos + dir * math.max(0, hitDist - halfWidth - 70)
				-- ledge detection: if hit face is vertical-ish, check for air above
				if normal and math.abs(normal.z) < 0.3 then
					local flatDir = v3(dir.x, dir.y, 0)
					local flen = flatDir:length()
					if flen > 0.01 then
						flatDir = flatDir / flen
						-- ray 2a: from 100 units back along aim, up to above+past the hit
						local probeStart = hit.hitPos - dir * 150
						local probeEnd = hit.hitPos + flatDir * 48 + v3(0, 0, playerHeight)
						local airCheck = nearby.castRay(probeStart, probeEnd, { ignore = self })
						if not airCheck.hit then
							-- ray 2b: straight down from that air point, find the top
							local topEnd = probeEnd - v3(0, 0, playerHeight * 2)
							local ledgeHit = nearby.castRay(probeEnd, topEnd)
							if ledgeHit.hit then
								destination = ledgeHit.hitPos + v3(0, 0, 5)
							end
						end
					end
				end
			end
		end
		
		if (destination - self.position):length() < halfWidth then
			onDone(nil)
			return
		end
		
		-- second async render ray: ground-snap
		nearby.asyncCastRenderingRay(async:callback(function(groundHit)
			local onGround = groundHit.hit
			if onGround then
				destination = groundHit.hitPos + v3(0, 0, 2)
			else
				destination = destination - v3(0, 0, playerHeight)
			end
			onDone(destination, camera.getYaw(), onGround)
		end), destination + v3(0, 0, 2), destination - v3(0, 0, 192))
	end), cameraPos, endPos, {ignore = self})
end

-- Player-only preview state
local previewDest = nil
local previewYaw = nil
local previewCalcInFlight = false
local previewVisible = false

local function hidePreviewVfx()
	if previewVisible then
		previewVisible = false
		core.sendGlobalEvent("TD_BlinkPreviewHide", {})
	end
end

local function clearPreview()
	previewDest = nil
	previewYaw = nil
	hidePreviewVfx()
end

-- PLAYER self-cast
local function executeBlinkPlayer(magnitude)
	if previewDest then
		local dest, yaw = previewDest, previewYaw
		previewDest = nil
		previewYaw = nil
		hidePreviewVfx()
		core.sendGlobalEvent('TD_BlinkPlayer', {
			destination = dest,
			rotation    = util.transform.rotateZ(camera.getYaw()) * util.transform.rotateX(camera.getPitch()),
		})
		return
	end
	
	-- how did this happen?
	computeBlinkDestination(magnitude, function(dest, yaw)
		if not dest then return end
		core.sendGlobalEvent('TD_BlinkPlayer', {
			destination = dest,
			rotation    = util.transform.rotateZ(camera.getYaw()) * util.transform.rotateX(camera.getPitch()),
		})
	end)
end

-- NPC self-cast
local function executeBlinkActor(magnitude)
	local dist = magnitude * trData.FEET_TO_UNITS
	local bounds = types.Actor.getPathfindingAgentBounds(self)
	local halfWidth = bounds.halfExtents.x
	local actorHeight = bounds.halfExtents.z * 2
	local eyeHeight = bounds.halfExtents.z * 1.8
	local eyePos = self.position + v3(0, 0, eyeHeight)
	local yaw = self.rotation:getYaw()
	local dir = v3(math.sin(yaw), math.cos(yaw), 0)
	
	-- simple obstacle check
	local hit = nearby.castRay(eyePos, eyePos + dir * dist, { ignore = self })
	if hit.hit then
		dist = math.max(0, (hit.hitPos - eyePos):length() - halfWidth - 16)
	end
	
	if dist <= 0 then return end
	
	local destination = eyePos + dir * dist
	
	-- ground snap
	local groundHit = nearby.castRay(
		destination + v3(0, 0, actorHeight),
		destination - v3(0, 0, actorHeight),
		{ ignore = self }
	)
	if groundHit.hit then
		destination = groundHit.hitPos + v3(0, 0, 5)
	end
	
	-- headroom validation
	local ceilingHit = nearby.castRay(
		destination,
		destination + v3(0, 0, actorHeight),
		{ ignore = self }
	)
	if ceilingHit.hit and (ceilingHit.hitPos - destination):length() < actorHeight * 0.5 then
		return
	end
	
	core.sendGlobalEvent('TD_BlinkActor', {
		actor       = self.object,
		destination = destination,
		yaw = yaw,
	})
end

local FRONT_OFFSET = 128

------------------------- REGISTRATION -------------------------

G.onMgefAdded[EFFECT_ID] = function(key, eff, activeSpell)
	local caster = activeSpell.caster
	-- SELF-CAST
	local mag = eff.magnitudeThisFrame or math.random(eff.minMagnitude or 50, eff.maxMagnitude or 50)
	if not caster or caster == self.object then
		if isPlayer then
			G.scheduleJob(function() executeBlinkPlayer(mag) end)
		else
			executeBlinkActor(mag)
		end
		return
	end
	
	-- someone else casted blink on us
	local range
	local spellRec = core.magic.spells.records[activeSpell.id]
	if spellRec then
		for _, se in ipairs(spellRec.effects) do
			if se.index == eff.index then
				range = se.range
				break
			end
		end
	end
	if range == core.magic.RANGE.Touch then
		-- swap positions
		local delta = caster.position - self.position
		local yawToCaster = math.atan2(delta.x, delta.y)
		core.sendGlobalEvent('TD_BlinkSwap', {
			a = {
				actor       = self.object,
				destination = caster.position,
				yaw         = yawToCaster + math.pi,
			},
			b = {
				actor       = caster,
				destination = self.position,
				yaw         = yawToCaster,
			},
		})
	elseif range == core.magic.RANGE.Target then
		-- teleport target in front of the caster (scaled chance)
		local casterLevel = eff.magnitudeThisFrame
		local targetLevel = types.Actor.stats.level(self).current
		local chance = math.max(0.1, math.min(0.95, 0.6 + (casterLevel - targetLevel) / 15))
		if math.random() > chance then
			caster:sendEvent('ShowMessage', {
				message = "The target resisted your spell"
			})
			return
		end
		local casterYaw = caster.rotation:getYaw()
		local forward = v3(math.sin(casterYaw), math.cos(casterYaw), 0)
		core.sendGlobalEvent('TD_BlinkActor', {
			actor       = self.object,
			destination = caster.position + forward * FRONT_OFFSET,
			yaw         = casterYaw + math.pi,
		})
	end
end

------------------------- PLAYER PREVIEW INPUT HOOK -------------------------

local function getReadiedBlinkMagnitude()
	if types.Actor.getStance(self) ~= types.Actor.STANCE.Spell then return nil end
	if I.UI.getMode() then return nil end
	local spell = types.Actor.getSelectedSpell(self)
	if not spell then return nil end
	local found = false
	local mag = 0
	for _, e in ipairs(spell.effects) do
		if e.effect.id == EFFECT_ID and e.range == core.magic.RANGE.Self then
			found = true
			if (e.magnitudeMax or 0) > mag then mag = e.magnitudeMax end
		end
	end
	if found then return mag end
	return nil
end

if isPlayer then
	-- Local held flag so the async calc callback can bail if the user
	-- Released before it returned.
	local held = false
	
	G.registerPreviewAction({
		id = "TD_blinkPreview",
		isReady = getReadiedBlinkMagnitude,
		
		onHold = function(mag, dt)
			held = true
			if previewCalcInFlight then return end
			previewCalcInFlight = true
			computeBlinkDestination(mag, function(dest, yaw, onGround)
				previewCalcInFlight = false
				if not dest or not held then
					-- no valid spot
					clearPreview()
					return
				end
				previewDest = dest
				previewYaw = yaw
				previewVisible = true
				-- update preview
				core.sendGlobalEvent("TD_BlinkPreviewShow", {
					position = dest,
					model    = BLINK_PREVIEW_VFX_MODEL,
					scale    = BLINK_PREVIEW_VFX_SCALE,
					offset   = onGround and BLINK_PREVIEW_VFX_OFFSET_GROUND or BLINK_PREVIEW_VFX_OFFSET,
					
					model2   = onGround and BLINK_PREVIEW_VFX_MODEL2 or nil,
					scale2   = onGround and BLINK_PREVIEW_VFX_SCALE2 or nil,
					offset2  = onGround and BLINK_PREVIEW_VFX_OFFSET2 or nil,
				})
			end)
		end,
		
		onRelease = function(mag)
			held = false
			async:newUnsavableSimulationTimer(0.000001, function()
				core.sendGlobalEvent("TD_BlinkPreviewHide", {})
			end)
			if previewDest then
				-- start casting
				core.sendGlobalEvent("SpawnVfx", {
					model = "meshes/e/magic_cast_myst.nif",
					position = previewDest - v3(0, 0, 35),
					options = {scale = 1}
				})
				-- meshes/td/td_vfx_blink_indicator.nif in the poison song update
                -- meshes/td/td_vfx_blink_ground.nif in the poison song update
				return true
			end
			return false
		end,
		
		onCancel = function()
			held = false
			clearPreview()
		end,
	})
end