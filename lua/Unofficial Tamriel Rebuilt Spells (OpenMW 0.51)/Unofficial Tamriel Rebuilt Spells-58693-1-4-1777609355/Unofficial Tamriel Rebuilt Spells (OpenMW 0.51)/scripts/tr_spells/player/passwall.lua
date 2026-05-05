-- Passwall: teleport through a wall/door

local SPELL_ID = "t_com_mys_uni_passwall"
local MAX_RANGE = 25 * trData.FEET_TO_UNITS
local MAX_RANGE_SQ = MAX_RANGE * MAX_RANGE
local VERY_CLOSE_SQ = 11 * 11

local function getActivationVector()
	local cv = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
	return v3(cv.x, cv.y, 0.0):normalize()
end

local function getActivationDistance()
	return core.getGMST("iMaxActivateDist") + 0.1
end

local function getCastPos()
	local rec = types.NPC.record(self)
	local raceH = types.NPC.races.record(rec.race).height
	local h = (rec.isMale and raceH.male or raceH.female) * 134
	return self.position + v3(0, 0, h * 0.7)
end

local function failSound()
	local spellRec = core.magic.spells.records[SPELL_ID]
	if spellRec and spellRec.effects[1] then
		local school = spellRec.effects[1].effect.school
		local skillRec = core.stats.Skill.records[school]
		if skillRec then
			ambient.playSound(skillRec.school.failureSound)
			return
		end
	end
	ambient.playSound("spell failure mysticism")
end

local function isBlockedByWard(obj)
	if obj.recordId:find("t_aid_passwallward_") then
		ui.showMessage("A ward prevents your spell from working.")
		return true
	end
	return false
end

local function isIllegalActivator(obj)
	if not types.Activator.objectIsInstance(obj) then return false end
	local model = types.Activator.records[obj.recordId].model
	for _, pattern in ipairs(trData.PASSWALL_FORBIDDEN_MODELS) do
		if model:find(pattern) then
			ui.showMessage("This surface cannot be passed through.")
			return true
		end
	end
	return false
end

local function isBlocker(rayHit)
	local obj = rayHit.hitObject
	return isBlockedByWard(obj) or isIllegalActivator(obj)
end

local function isForbiddenDoor(obj)
	local name = types.Door.records[obj.recordId].name
	for _, pattern in ipairs(trData.PASSWALL_FORBIDDEN_DOORS) do
		if name:find(pattern) then return true end
	end
	return false
end

local function handleDoor(obj)
	if not types.Door.objectIsInstance(obj) then return false end

	if types.Door.isTeleport(obj) then
		local destCell = types.Door.destCell(obj)
		if destCell.isExterior or destCell.isQuasiExterior then
			ui.showMessage("Passwall cannot transport through exterior doors.")
			failSound()
		else
			local spellRec = core.magic.spells.records[SPELL_ID]
			local vfxStatic = spellRec and spellRec.effects[1] and spellRec.effects[1].effect.hitStatic or nil
			if vfxStatic then
				local vfxRec = types.Static.records[vfxStatic]
				if vfxRec then animation.addVfx(self, vfxRec.model) end
			end
			core.sound.playSound3d("mysticism hit", self)
			core.sendGlobalEvent('TD_Passwall', {
				doorObject = obj,
				destPosition = { types.Door.destPosition(obj).x, types.Door.destPosition(obj).y, types.Door.destPosition(obj).z },
				destCell = destCell.name,
				destRotation = types.Door.destRotation(obj),
			})
		end
		return true
	elseif isForbiddenDoor(obj) then
		failSound()
		return true
	end
	
	return false
end

-- target is reachable via navmesh from a position?
local function isReachable(from, targetObj)
	local to = targetObj:getBoundingBox().center
	if (from - to):length2() > 1024 * 1024 then return false end

	local agentBounds = types.Actor.getPathfindingAgentBounds(self)
	local status, path = nearby.findPath(from, to, {
		includeFlags = nearby.NAVIGATOR_FLAGS.Walk,
		destinationTolerance = 0.0,
		agentBounds = agentBounds,
	})

	if status == nearby.FIND_PATH_STATUS.Success or status == nearby.FIND_PATH_STATUS.PartialPath then
		-- verify it reaches the target
		local lastCheck = nearby.castRay(path[#path], to, {
			collisionType = nearby.COLLISION_TYPE.AnyPhysical + nearby.COLLISION_TYPE.VisualOnly,
		})
		if lastCheck.hitObject and lastCheck.hitObject == targetObj then
			return true
		end
		-- fallback distance check for items the ray might miss
		local bottom = v3(to.x - path[#path].x, to.y - path[#path].y, to.z - path[#path].z - targetObj:getBoundingBox().halfSize.z)
		return bottom:length2() < VERY_CLOSE_SQ
	end
	return false
end

-- validate landing spot
local function isPositionIntended(pos)
	if not pos then return false end
	
	for _, obj in ipairs(nearby.doors) do
		if isReachable(pos, obj) then return true end
	end
	for _, obj in ipairs(nearby.actors) do
		if not types.Player.objectIsInstance(obj) then
			if isReachable(pos, obj) then return true end
		end
	end
	for _, obj in ipairs(nearby.activators) do
		if isReachable(pos, obj) then return true end
	end
	for _, obj in ipairs(nearby.containers) do
		if isReachable(pos, obj) then return true end
	end
	-- fallback: nearby items except lights
	for _, obj in pairs(nearby.items) do
		if (pos - obj:getBoundingBox().center):length2() <= MAX_RANGE_SQ then
			if not types.Light.objectIsInstance(obj) then
				if isReachable(pos, obj) then return true end
			end
		end
	end
	return false
end

-- collect ray hits through wall
local function gatherRayHits(startPos, direction, firstHit)
	local hits = { firstHit }
	local limitPos = firstHit.hitPos + direction * MAX_RANGE
	local remaining = MAX_RANGE
	local ignoreList = {}
	
	while remaining > 0 do
		local prev = hits[#hits]
		table.insert(ignoreList, prev.hitObject)
		local hit = nearby.castRay(prev.hitPos, limitPos, {
			collisionType = nearby.COLLISION_TYPE.AnyPhysical + nearby.COLLISION_TYPE.VisualOnly,
			ignore = ignoreList,
		})
		if hit.hitObject then
			table.insert(hits, hit)
			remaining = remaining - (hit.hitPos - prev.hitPos):length()
		else
			break
		end
	end
	
	return hits, limitPos
end

-- raycast through wall, trying to find a navmesh position after each collision
local function findPosition(rayHits, limitPos, direction)
	local stepSize = 19 * 2
	local minDistSq = 108 * 108
	local maxZDiff = 105
	local agentBounds = types.Actor.getPathfindingAgentBounds(self)
	
	local maxDistSq = rayHits[1] and (
		v3(rayHits[1].hitPos.x - limitPos.x, rayHits[1].hitPos.y - limitPos.y, 0):length2()
		+ (160 * 160)
	)
	
	for i = 1, #rayHits do
		if isBlocker(rayHits[i]) then return nil end
		
		local nextPos = (i < #rayHits) and rayHits[i + 1].hitPos or limitPos
		-- growing search extents further from player
		local halfExt = stepSize * 0.7 * i
		
		local distToNext = (nextPos - rayHits[i].hitPos):length()
		local probe = rayHits[i].hitPos + direction * stepSize
		
		while distToNext >= stepSize do
			local navPos = nearby.findNearestNavMeshPosition(probe, {
				includeFlags = nearby.NAVIGATOR_FLAGS.Walk,
				searchAreaHalfExtents = v3(halfExt, halfExt, maxZDiff * 10),
				agentBounds = agentBounds,
			})
			
			if navPos then
				local heightOk = math.abs(self.position.z - navPos.z) < maxZDiff
				local farEnough = heightOk and (self.position - navPos):length2() >= minDistSq
				local notTooFar = farEnough and v3(
					rayHits[1].hitPos.x - navPos.x,
					rayHits[1].hitPos.y - navPos.y, 0
				):length2() <= maxDistSq
				local valid = farEnough and heightOk and notTooFar
				
				if valid then
					valid = isPositionIntended(navPos)
				end
				
				if valid then return navPos end
			end
			
			probe = probe + direction * stepSize
			distToNext = (nextPos - probe):length()
		end
	end
	
	return nil
end

local function executePasswall()
	if self.cell.isExterior then
		ui.showMessage("Passwall cannot be used in exteriors.")
		return failSound()
	end
	if types.Actor.isSwimming(self) then
		ui.showMessage("Passwall cannot be used underwater.")
		return failSound()
	end
	if types.Player.isTeleportingEnabled and not types.Player.isTeleportingEnabled(self) then
		ui.showMessage(core.getGMST("sTeleportDisabled"))
		return failSound()
	end
	
	local castPos = getCastPos()
	local direction = getActivationVector()
	local activateDist = getActivationDistance()
	
	-- initial ray
	local firstHit = nearby.castRay(castPos, castPos + direction * activateDist, {
		ignore = self,
		collisionType = nearby.COLLISION_TYPE.AnyPhysical + nearby.COLLISION_TYPE.VisualOnly,
	})
	
	if not firstHit.hitObject or isBlocker(firstHit) then
		return failSound()
	end
	
	local target = firstHit.hitObject
	
	-- can only pass through statics, activators and doors
	if not (types.Static.objectIsInstance(target) or types.Activator.objectIsInstance(target) or types.Door.objectIsInstance(target)) then
		return failSound()
	end
	
	-- door shortcut
	if handleDoor(target) then return end
	
	-- height check: halfSize.z >= ~93
	local halfHeight = target:getBoundingBox().halfSize.z
	if halfHeight < 93 then return failSound() end
	
	-- gather all ray hits through walls, search for landing spot
	local rayHits, limitPos = gatherRayHits(castPos, direction, firstHit)
	local landingPos = findPosition(rayHits, limitPos, direction)
	
	if landingPos then
		-- FX
		local spellRec = core.magic.spells.records[SPELL_ID]
		local vfxStatic = spellRec and spellRec.effects[1] and spellRec.effects[1].effect.hitStatic or nil
		if vfxStatic then
			local vfxRec = types.Static.records[vfxStatic]
			if vfxRec then animation.addVfx(self, vfxRec.model) end
		end
		core.sound.playSound3d("mysticism hit", self)
		-- Teleport
		core.sendGlobalEvent('TD_Passwall', {
			destination = { landingPos.x, landingPos.y, landingPos.z },
			cellName = self.cell.name,
			rotation = { self.rotation:getYaw() },
			targetObject = target,
		})
	else
		failSound()
	end
end

------------------------- REGISTRATION -------------------------

G.onMgefAdded["t_mysticism_passwall"] = function(key, eff, activeSpell)
	G.scheduleJob(executePasswall)
end
