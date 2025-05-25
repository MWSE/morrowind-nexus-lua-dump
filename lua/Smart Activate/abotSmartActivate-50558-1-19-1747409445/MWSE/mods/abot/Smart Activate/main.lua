---@diagnostic disable: need-check-nil
--[[
allow to choose who to activate between nearby actors
]]

local defaultConfig = {
actorsMenu = false, -- actorsMenu toggle
maxDistance = 96, -- Max distance between targets to classify them as colliding each other
maxSelectable = 15, -- Max number of selectable targets
allowDead = true, -- allow selecting dead actors
allowNPC = true, -- allow selecting NPCs
allowCreature = true, -- allow selecting creatures
allowContainer = false, -- allow selecting containers
allowOrganic = false, -- allow selecting organic containers
allowDoor = true, -- allow selecting 1 door
autoFace = 2, -- 0 = Off, 1 = NPCs, 2 = NPCs & Creatures
minFaceAngle = 20, -- min. degree angle from player to autoface
blinkFix = true, -- try and fix blinking eyes remaining closed while talking with player
idleOnActivate = 2, -- 0 = Off, 1 = Followers, 2 = All actors
immobileFix = true, -- add some idle animation to animation-less immobile NPCs
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium, 3 = High
}

local author = 'abot'
local modName = 'Smart Activate'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

local maxSelectable, allowDead, allowNPC, allowCreature
local allowContainer, allowOrganic, allowDoor, blinkFix
local actorsMenu, immobileFix
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4, logLevel5

local function updateFromConfig()
	---assert(config)
	maxSelectable = config.maxSelectable
	allowDead = config.allowDead
	allowNPC = config.allowNPC
	allowCreature = config.allowCreature
	allowContainer = config.allowContainer
	allowOrganic = config.allowOrganic
	allowDoor = config.allowDoor
	blinkFix = config.blinkFix
	actorsMenu = config.actorsMenu
	immobileFix = config.immobileFix
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
	logLevel5 = logLevel >= 5
end
updateFromConfig()

-- set in loaded()
local player, player1stPerson, mobilePlayer

-- initialized in loaded()
local inputController

local function getActiveCellsCulled(ref, maxDistanceFromRef)
-- active cells matrix example:
-- ^369
-- |258
-- |147
-- +----->
-- example
-- [1] = -3, -10 [2] = -3, -9 [3] = -3, -8
-- [4] = -2, -10 [5] = -2, -9 [6] = -2, -8
-- [7] = -1, -10 [8] = -1, -9 [9] = -1, -8
-- try marking cells that can be skipped

	local cells = {}

	local cell = ref.cell
	if cell.isInterior then
		cells[1] = cell
		return cells
	end

	if not maxDistanceFromRef then
		maxDistanceFromRef = 11585 -- math.floor(math.sqrt(8192*8192*2) + 0.5)
	elseif maxDistanceFromRef > 34756 then -- math.floor(math.sqrt((3*8192)*(3*8192)*2) + 0.5)
		maxDistanceFromRef = 34756
	end
	---assert(ref)
	local skip = {}
	local x = ref.position.x
	local y = ref.position.y
	local cellGridX = cell.gridX
	local cellGridY = cell.gridY

	local x0 = cellGridX * 8192
	local y0 = cellGridY * 8192
	local x1 = x0 + 8191
	local y1 = y0 + 8191

	-- skip cells depending on distance of target marker from cell borders
	local dx = x1 - x
	if dx > maxDistanceFromRef then
		skip[7] = true
		skip[8] = true
		skip[9] = true
	end

	dx = x - x0
	if dx > maxDistanceFromRef then
		skip[1] = true
		skip[2] = true
		skip[3] = true
	end

	local dy = y1 - y
	if dy > maxDistanceFromRef then
		skip[3] = true
		skip[6] = true
		skip[9] = true
	end
	dy = y - y0
	if dy > maxDistanceFromRef then
		skip[1] = true
		skip[4] = true
		skip[7] = true
	end

	local ac = tes3.getActiveCells()
	local c
	local j = 0
	for i = 1, 9 do
		c = ac[i]
		if not skip[i] then
			j = j + 1
			cells[j] = c
			---mwse.log("culledCell = %s", c.editorName)
		end
	end

	if logLevel2
	or (j == 0) then
		mwse.log('%s: getActiveCellsCulled("%s", %s) %s cells found',
			modPrefix, ref.id, maxDistanceFromRef, j)
	end

	return cells
end

local function byNameAsc(a, b)
	return a.name < b.name
end

local function byDistAsc(a, b)
	return a.dist < b.dist
end

local tes3_objectType_npc = tes3.objectType.npc
local tes3_objectType_creature = tes3.objectType.creature
local tes3_objectType_container = tes3.objectType.container
local tes3_objectType_door = tes3.objectType.door

local selectableTypes = {
tes3_objectType_npc, tes3_objectType_creature,
tes3_objectType_container, tes3_objectType_door
}

---local readableObjectTypes = table.invert(tes3.objectType)

local selectables = {} -- e.g. {ref = targetRef, name = targetRef.object.name, dist = 0}}
local msgBtns = {}

local function back2slash(s)
	return string.gsub(s, [[\]], [[/]])
end

local function multifind2(s1, s2, t)
	return string.multifind(s1, t, 1, true)
	or string.multifind(s2, t, 1, true)
end

local dummies = {'dumm', 'mann', 'target', 'invis'}

local function isDummy(mob)
	local mobRef = mob.reference
	local obj = mobRef.baseObject
	if multifind2(string.lower(obj.id), string.lower(obj.name), dummies) then
		return true
	end
	local mesh
	local race = obj.race
	if race then
		 -- check for invisible race NPC
		local chest = race.maleBody.chest
		if not chest then
			chest = race.femaleBody.chest
		end
		if not chest then
			return true
		end
		mesh = chest.mesh
		if not mesh then
			return true
		end
		if mesh == '' then
			return true
		end
	end
	mesh = obj.mesh
	if not mesh then
		return false
	end
	if mesh == '' then
		return false
	end
	if string.multifind(string.lower(back2slash(mesh)), dummies, 1, true) then
		return true
	end
	return false
end

local targetBlacklist = {'roht_mask_compass'}

local function isBlacklisted(obj)
	if string.multifind(string.lower(obj.id), targetBlacklist, 1, true) then
		return true
	end
	return false
end

local function isDead(mobile)
	local result = false
	if mobile.isDead then
		result = true
	else
		local actionData = mobile.actionData
		if actionData then
			local animState = actionData.animationAttackState
			if animState then
				if (animState == tes3.animationState.dying)
				or (animState == tes3.animationState.dead) then
					result = true
				end
			end
		end
	end
	local health = mobile.health
	if health
	and health.current then
		if result then
			if health.current > 0 then
				health.current = 0
			end
		else
			if (health.normalized <= 0.025) -- health ratio <= 0.25%
			and (health.current > 0)
			and (health.current < 3)
			and (health.normalized > 0) then
				health.current = 0 -- kill when nearly dead, could be a glitch
				result = true
			end
		end
	end
	return result
end

local function getSelectablesInProximity(targetRef, range)
	local i = 0
	local targetRefPos = targetRef.position
	local funcPrefix = string.format('%s: getSelectablesInProximity("%s", %s)',
		modPrefix, targetRef.id, range)
	local t = {}
	local cell = targetRef.cell
	local mobCount = 0
	local contCount = 0
	local doorCount = 0

	local function processRef(aRef)
		if (aRef == player)
		or (aRef == player1stPerson) then
			return
		end
		if aRef.disabled
		or aRef.deleted then
			return
		end
		local aDist = targetRefPos:distance(aRef.position)
		if aDist > range then
			if logLevel5 then
				mwse.log('%s: aRef = "%s" aDist = %s > range = %s',
					funcPrefix, aRef.id, aDist, range)
			end
			return
		end
		if logLevel4 then
			mwse.log('%s: aRef = "%s" aDist = %s, range = %s',
				funcPrefix, aRef.id, aDist, range)
		end
		local obj = aRef.baseObject
		local mesh = obj.mesh
		if not mesh then
			return
		end
		if mesh == '' then
			return
		end
		if logLevel4 then
			mwse.log('%s: aRef = "%s", mesh = "%s"', funcPrefix, aRef.id, mesh)
		end
		local objType = obj.objectType
		local ok = false

		local function checkMob()
			local mob = aRef.mobile
			if mob
			and ( not isBlacklisted(obj) )
			and ( not isDummy(mob) ) then -- skip mannequins
				if allowDead then
					ok = true
				elseif not isDead(mob) then
					ok = true
				end
				if ok then
					mobCount = mobCount + 1
				end
			end
			if logLevel3 then
				mwse.log('%s: mob = %s, ok = %s', funcPrefix, aRef.id, ok)
			end
		end

		if objType == tes3_objectType_npc then
			if allowNPC then
				checkMob()
			end
		elseif objType == tes3_objectType_creature then
			if allowCreature then
				checkMob()
			end
		elseif objType == tes3_objectType_container then
			if obj.organic then
				ok = allowOrganic
			else
				ok = allowContainer
			end
			if ok then
				contCount = contCount + 1
			end
		elseif objType == tes3_objectType_door then
			ok = allowDoor
			if ok then
				doorCount = doorCount + 1
			end
		end
		local aName = obj.name
		if ok then
			if logLevel3 then
				mwse.log('%s: aName = "%s"', funcPrefix, aName)
			end
			if (not aName)
			or (aName == '') then
				-- important! the messageBox may freeze on empty button text!
				-- e.g. invisible tiny sonar race NPCs could have no name
				ok = false
			end
		end
		if ok then
			i = i + 1
			if i > maxSelectable then
				return t
			end
			if logLevel2 then
				mwse.log('%s: t[%s] = {ref = "%s", name = "%s", dist = %s}',
					funcPrefix, i, aRef.id, aName, aDist)
			end
			--[[
			for j = 1, #t do
				local v = t[j]
				if v.name == aName then
					aName = aRef.id -- use reference ids if object name does not appear only once
					break
				end
			end]]
			t[i] = {ref = aRef, name = aName, dist = aDist}
		end
	end

	local function processCell()
		for aRef in cell:iterateReferences(selectableTypes) do
			processRef(aRef)
		end
	end

	if cell.isInterior then
		if logLevel3 then
			mwse.log('%s: processing "%s" interior', funcPrefix, cell.editorName)
		end
		processCell()
	else
		local culledCells = getActiveCellsCulled(targetRef, range)
		for j = 1, #culledCells do
			cell = culledCells[j]
			if logLevel3 then
				mwse.log('%s: processing culledCells[%s] = %s', funcPrefix, j, cell.editorName)
			end
			processCell()
		end
	end

	--[[if mobCount == 0 then -- no actors, no need for special menu
		return {[1] = {ref = targetRef, name = targetRef.object.name, dist = 0}}
	end]]

	local count = #t
	if count > 1 then
		table.sort(t, byDistAsc) -- sort by lesser distance (the activation target should be first)
		local t2 = {}
		if count > maxSelectable then -- get only first maxSelectable items
			for k = 1, maxSelectable do
				local v = t[k]
				t2[k] = v
			end
			t = t2
			count = #t
		end
		if doorCount >= 2 then -- max 1 door
			local ok = true
			local j = 0
			t2 = {}
			for k = 1, count do
				local v = t[k]
				if v.ref.object.objectType == tes3_objectType_door then
					if ok then
						ok = false
						j = j + 1
						t2[j] = v -- add first door, once
					end
				else
					j = j + 1
					t2[j] = v -- add rest of non-door objects
				end
			end
			t = t2
			count = #t
		end
		if logLevel3  then
			mwse.log('%s: sorted by distance', funcPrefix)
			for k = 1, count do
				local v = t[k]
				if logLevel3  then
					mwse.log('%s: t[%s] = {ref = "%s", name = "%s", dist = %s}',
						modPrefix, k, v.ref.id, v.name, v.dist)
				end
			end
		end
	end
	return t
end

local function handleToRef(handle)
	if not handle then
		return
	end
	if not handle.valid then
		return
	end
	if not handle:valid() then
		return
	end
	local ref = handle:getObject()
	return ref
end

local function getTimerRef(e)
	local timer = e.timer
	local data = timer.data
	local handle = data.handle
	local ref = handleToRef(handle)
	return ref
end

-- reset in loaded() and beforeDestroyMenuDialog()
local skips = 0

local aiPackageTypes = table.invert(tes3.aiPackage)

local function logAIpackage(mob, p)
	local targetActorId = ''
	if p.targetActor then
		targetActorId = p.targetActor.reference.id
	end
	local chances = '{}'
	local idles = p.idles
	if idles then
		chances = '{' .. idles[1].chance
		for i = 2, #idles do
			chances = chances .. ', ' .. idles[i].chance
		end
		chances = chances .. '}'
	end
	local aiPackageMsgFrmt = [[%s: logAIpackage("%s") = %s (%s)
destinationCell = "%s", distance = "%s", hourOfDay = "%s", duration = "%s",
isDone = %s, isFinalized = %s, isMoving = %s, isReset = %s, isStarted = %s,
mobile = "%s", startGameHour = %s, activateTarget = "%s",
targetActor = "%s", targetPosition = %s,
idle chances = %s]]
	mwse.log(aiPackageMsgFrmt,
modPrefix, mob.reference.id, p.type, aiPackageTypes[p.type],
p.destinationCell, p.distance, p.hourOfDay, p.duration,
p.isDone, p.isFinalized, p.isMoving, p.isReset, p.isStarted,
p.mobile.reference.id, p.startGameHour, p.activateTarget,
targetActorId, json.encode(p.targetPosition), chances)
end

local tes3_aiPackage_none = tes3.aiPackage.none
local tes3_aiPackage_travel = tes3.aiPackage.travel

local function getActiveAIpackage(mob)
	local aiPlanner = mob.aiPlanner
	if not aiPlanner then
		return
	end
	local p = aiPlanner:getActivePackage()
	if logLevel3 then
		if p then
			logAIpackage(mob, p)
		end
	end
	return p
end

local function isAImoving(mob)
	local ai = tes3.getCurrentAIPackageId({reference = mob})
	if ai == tes3_aiPackage_travel then
		return true
	end
	local p = getActiveAIpackage(mob)
	if not p then
		return false
	end
	local aiType = p.type
	if aiType == tes3_aiPackage_none then
		return false
	end
	if p.isDone
	or p.isFinalized then
		return false
	end
	--[[if not p.isStarted then
		return false
	end]]
	if aiType == tes3_aiPackage_travel then
		return true
	end
	if not p.isMoving then
		return false
	end
	if logLevel3  then
		mwse.log('%s: isAImoving("%s") = true',
			modPrefix, mob.reference.id)
	end
	return true
end

local tes3_actorType_npc = tes3.actorType.npc

local function getValidMobile(ref)
	local mob = ref.mobile
	if not mob then
		return
	end
	local actorType = mob.actorType
	if not actorType then
		return
	end
	if not (actorType == tes3_actorType_npc) then
		return
	end
	if isDead(mob) then
		return
	end
	if isDummy(mob) then
		return
	end
	return mob
end

local tes3_aiPackage_wander = tes3.aiPackage.wander

---local immobileFixBlacklist = {'aa_latte_comp01'}
local immobileFixMeshBlacklist = {'anim_johnny','anim_synda','va_sitting.nif','roo_papcre'}

local function round(x)
	return math.floor(x + 0.5)
end

local function fixImmobile(ref)
	local mob = getValidMobile(ref)
	if not mob then
		return
	end
	local p = getActiveAIpackage(mob)
	if not p then
		return
	end
	local aiType = p.type
	if not (aiType == tes3_aiPackage_wander) then
		return
	end
	if p.isReset
	or p.isStarted
	or p.isDone
	or p.isFinalized
	or p.isMoving
	or (p.distance >= 1)
	then
		return
	end
	local idles = p.idles
	if not idles then
		return
	end
	local chances = {60, 40, 30, 20}
	local animationData = ref.attachments.animation
	if animationData
	and animationData.hasOverrideAnimations then
		chances = {60, 40, 0, 0}
	end
	for i = 1, #chances do
		local idle = idles[i]
		local chance = chances[i]
		if chance == 0 then
			idle.chance = 0
		elseif idle.chance < 1 then
			idle.chance = math.random( round(chance * 0.5), round(chance) )
		else
			break
		end
	end
	if logLevel3  then
		local s = '{'
		local count = #idles
		local idle, s2
		for i = 1, count do
			idle = idles[i]
			if i == count then
				s2 = '}'
			else
				s2 = ', '
			end
			s = s .. idle.chance .. s2
		end
		mwse.log('%s: fixImmobile("%s") idles to %s', modPrefix, ref.id, s)
	end
end

local function playerActivate(ref, withSkips)
	---assert(player)
	---assert(player == tes3.player)
	--[[if tes3.dataHandler.nonDynamicData.isSavingOrLoading then
		return -- safety in case player is not up to date /abot
	end]]
	local obj = ref.object
	local mesh = obj.mesh
	if withSkips then
		if skips < 1 then
			skips = 1 -- important! at least 1, 0 may loop
		end
	else
		skips = 0
	end
	if actorsMenu
	or (
		mesh
		and string.find(string.lower(mesh), 'ac\\anim_', 1, true)
	) then
		skips = skips + 1
	end
	if immobileFix
	---and ( not string.multifind(string.lower(obj.id), immobileFixBlacklist, 1, true) )
	and ( not string.multifind(string.lower(mesh), immobileFixMeshBlacklist, 1, true) ) then
		fixImmobile(ref)
	end
	player:activate(ref)
end

local function ab01smactiPT1(e)
	local ref = getTimerRef(e)
	if not ref then
		return
	end
	if logLevel2 then
		mwse.log('%s: ab01smactiPT1() playerActivate("%s", true)', modPrefix, ref.id)
	end
	playerActivate(ref, true)
end

local timer_real = timer.real

local function delayedPlayerActivate(targetRef, delaySec)
	local refHandle1 = tes3.makeSafeObjectHandle(targetRef)
	timer.start({ type = timer_real, duration = delaySec, callback = 'ab01smactiPT1', data = {handle = refHandle1} })
end


local validTypes = {
[tes3_objectType_npc] = true,
[tes3_objectType_creature] = true,
[tes3_objectType_container] = true,
[tes3_objectType_door] = true,
}

local animBlacklist = {'scamp','sitting','lean'}
local actorIdBlacklist = {'hrsct'}

local function isAnimBlacklisted(mobRef)
	local obj = mobRef.object
	local mesh = obj.mesh
	if not mesh then
		return false
	end
	if mesh == '' then
		return false
	end
	local s = string.lower(back2slash(mesh))
	if string.sub(s, 1, 3) == 'am/' then -- path starting with "am/", probably Antares' animation
		return true
	end
	if string.find(s, 'am_', 1, true) then -- am_ prefix somewhere in path, probably Antares'
		return true
	end
	if string.multifind(s, animBlacklist, 1, true) then
		return true
	end
	s = string.lower(obj.id)
	if string.multifind(s, actorIdBlacklist, 1, true) then
		return true
	end
	return false
end

local function getRefVariable(ref, variableId)
	local script = ref.object.script

	if not script then
		return nil
	end
	local context = script['context'] -- will this work better?
	---local context = ref['context']
	if not context then
		return nil
	end

	if ref.attachments
	and ref.attachments.variables
	and not ref.attachments.variables.script then
		return nil
	end

	if logLevel4 then
		mwse.log('%s: getRefVariable("%s", "%s") context = %s',
			modPrefix, ref.id, variableId, context)
	end
	-- need more safety
	local value = context[variableId]
	if value then
		if logLevel3 then
			mwse.log('%s: getRefVariable("%s", "%s") context["%s"] = %s)',
				modPrefix, ref.id, variableId, variableId, value)
		end
		return value
	end
	return nil
end

local function isCompanion(mobRef)
	local companion = getRefVariable(mobRef, 'companion')
	if companion
	and (companion == 1) then
		return true
	end
	return false
end

local function isValidMobile(mob)
	local mobRef = mob.reference
	if mobRef.disabled then
		return false
	end
	if mobRef.deleted then
		return false
	end
	if isDead(mob) then
		return false
	end
	if mob == mobilePlayer then
		return false
	end
	if not mob.canMove then
		return false -- dead, knocked down, knocked out, hit stunned, or paralyzed.
	end

	if mob.actorType == tes3_actorType_npc then
		return true
	end
	local mobObj = mobRef.object
	--[[local sourceMod = mobObj.sourceMod
	if sorceMod then
		local lcSourceMod = string.lower(sourceMod)
		if string.startswith(lcSourcemod, 'abotwaterlife')
		or string.startswith(lcSourcemod, 'abotwhereareallbirds') then
			return false
		end
	end]]
	local script = mobObj.script
	if script then
		local lcId2 = string.lower(script.id)
		if string.startswith(lcId2, 'ab01') then
			-- ab01 prefix, probably some abot's creature having AIEscort package, skip
			if logLevel3 then
				mwse.log("%s: %s having ab01 prefix, probably some abot's creature with AIEscort package, skip",
					modPrefix, mobRef.id)
			end
			return false
		end
	end
	return true
end

local tes3_aiPackage_follow = tes3.aiPackage.follow
local tes3_aiPackage_escort = tes3.aiPackage.escort

-- special case for wandering destinations
-- e.g. companion scripted to do move-away using temporary aiwander
local function hasOneTimeMove(mobRef)
-- used by many companion scripts
	local result = getRefVariable(mobRef, 'oneTimeMove')
	if not result then
-- used by Striders Nest dests scripts
		result = getRefVariable(mobRef, 'c_move')
	end
	if not result then
-- used by some CMPartners scripts
		result = getRefVariable(mobRef, 'f_move')
	end
	if result
	and ( not (result == 0) ) then
		return true
	end
 -- used by some Lokken scripts
	result = getRefVariable(mobRef, 'wandertimer')
	if result
	and (result > 1) then
		return true
	end
	return false
end

-- 0 = invalid, 1 = follower, 2 = companion
local function validFollower(mob, anyFollower)
	if not isValidMobile(mob) then
		return 0
	end
	local mobRef = mob.reference
	local aCompanion = isCompanion(mobRef)
	local mobRefObj = mobRef.baseObject
	local ai = tes3.getCurrentAIPackageId(mob)

	if (ai == tes3_aiPackage_follow)
	or (ai == tes3_aiPackage_escort) then
		if aCompanion then
			return 2
		end
		if anyFollower
		and (not mobRefObj.isGuard) then
			return 1
		end
		return 0
	elseif (ai == tes3_aiPackage_wander)
	and aCompanion
	and hasOneTimeMove(mobRef) then
		-- special case for wandering destinations
		return 2
	end
	return 0
end

-- needed to safely tes3.playAnimation() lower
local improvedAnimationSupport

local function playGroupIdle(mobRef)
-- As a special case, tes3.playAnimation{reference = ..., group = 0}
-- returns control to the AI, as the AI knows that is the actor's neutral idle state.
	tes3.playAnimation({reference = mobRef, group = 0})
end

local function ab01smactiPT5(e)
	local ref = getTimerRef(e)
	if not ref then
		return
	end
	local mob = ref.mobile
	if not mob then
		return
	end
	---aiWanderOn(mob)
	playGroupIdle(ref)
end

local talkAnims = {tes3.animationGroup.idle, tes3.animationGroup.idle2,
tes3.animationGroup.idle3, tes3.animationGroup.idle4}

local function checkPlayAnimation(mob, animGroup, loops)
	local ref = mob.reference
	if not ref then
		return
	end
	if isAnimBlacklisted(ref) then
		return
	end
	local idleOnActivate = config.idleOnActivate
	local idleOk
	if idleOnActivate == 1 then -- followers
		-- 0 = invalid, 1 = follower, 2 = companion
		idleOk = validFollower(mob, true) > 0
	elseif idleOnActivate == 2 then -- all actors
		idleOk = isValidMobile(mob)
	else
		idleOk = false
	end
	local animOk = false
	if animGroup
	and loops then
		animOk = true
		local animationData = ref.attachments.animation
		if animationData
		and animationData.hasOverrideAnimations then
			animOk = false -- skip e.g. a drummer
		end
		if animOk then
			local randGroup = talkAnims[math.random(1, #talkAnims)]
			local params = {reference = ref, group = randGroup, loopCount = loops}
			--- nope , startFlag = tes3.animationStartFlag.normal}
			if improvedAnimationSupport then
				if idleOk then
					params['lower'] = animGroup
				end
				if logLevel3 then
					mwse.log('%s: tes3.playAnimation({reference = "%s", group = %s, lower = %s, loopCount = %s})',
						modPrefix, ref.id, randGroup,
						table.find(tes3.animationGroup, animGroup), loops)
				end
			else
				if logLevel3 then
					mwse.log('%s: tes3.playAnimation({reference = "%s", group = %s, loopCount = %s})',
						modPrefix, ref.id, randGroup, animGroup, loops)
				end
			end
			tes3.playAnimation(params)
		end
	end
	---if idleOk then
	if not animOk then
		return
	end
	if not loops then
		return
	end
	if loops < 1 then
		loops = 1
	end
	local delay = loops * 0.7
	local refHandle5 = tes3.makeSafeObjectHandle(ref)
	timer.start({duration = delay, callback = 'ab01smactiPT5',
		data = {handle = refHandle5}
	})
end

local function normalizedAngle(angle)
	local a = angle % 360
	if a > 180 then
		a = a - 360
	elseif a < -180 then
		a = a + 360
	end
	return a
end

local function getAngleTo(ref, target)
	local angleTo
	local mob = ref.mobile
	if mob
	and mob.actorType then
		-- this one keeps the sign and works better
		angleTo = mob:getViewToPoint(target.position)
	else
		angleTo = math.deg(ref:getAngleTo(target))
	end
	if logLevel3 then
		mwse.log([[%s: getAngleTo("%s","%s") = %.2f]],
			modPrefix, ref.id, target.id, angleTo)
	end
	return angleTo
end

local function getFacingAngle(ref, target)
	local angleTo = getAngleTo(ref, target)
	local degFacing = math.deg(ref.facing)
	local facingAngle = normalizedAngle(degFacing + angleTo)
	if logLevel3 then
		mwse.log([[%s: getFacingAngle("%s","%s")
refAngle = %.2f, angleToTarget = %.2f, facingAngle = %.2f]],
			modPrefix, ref.id, target.id,
			degFacing, angleTo, facingAngle)
	end
	return facingAngle
end

local function face(mob, target)
	local ref = mob.reference
	local diff = target.position - ref.position
	diff.z = 0 -- only XY coordinates
	if #diff < 32 then
		return -- XY distance too low, skip
	end
	local facingAngle = getFacingAngle(ref, target)
	if logLevel3 then
		mwse.log([[%s: face("%s", "%s") facingAngle = %.2f]],
			modPrefix, ref.id, target.id, facingAngle)
	end
	ref.facing = math.rad(facingAngle)
end

local radStep

local faceAndTalkBusy = false

local function ab01smactiPT2(e)
	local ref = getTimerRef(e)
	if not ref then
		return
	end
	local timer = e.timer
	if not timer then
		return
	end
	local mob = ref.mobile
	
	local function cancel()
		timer:cancel()
		faceAndTalkBusy = false
		mob.activeAI = true
	end

	local data = timer.data
	if not data then
		cancel()
		return
	end

	local i = data.i
	if not i then
		cancel()
		return
	end

	local iterations = data.iterations
	if not iterations then
		cancel()
		return
	end

	i = i + 1
	data.i = i
	if logLevel5 then
		mwse.log('%s: ab01smactiPT2("%s") i = %s',
			modPrefix, ref.id, i)
	end

	if i < iterations then
		-- note: mobile.facing is read only!!!
		ref.facing = ref.facing + data.radStp -- range of [-PI, PI] for actors
		return
	end
	
	cancel()
	face(mob, player)
	
end


local ab01smactiPT4timer -- link to persistent timer

local function ab01smactiPT4(e)
	local timer = e.timer
	if not timer then
		return
	end

	local function cancel()
		timer:cancel()
		ab01smactiPT4timer = nil
	end

	local data = timer.data
	if not data then
		cancel()
		return
	end
	local iterations = data.iterations
	if not iterations then
		cancel()
		return
	end
	local i = data.i
	if not i then
		cancel()
		return
	end
	local ref = getTimerRef(e)
	if not ref then
		cancel()
		return
	end
	local mob = ref.mobile
	if not mob then
		cancel()
		return
	end
	local animationData = ref.attachments.animation
	if not animationData then
		cancel()
		return
	end
	local timeToNextBlink = animationData.timeToNextBlink
-- time in seconds until the next blink.
-- Fixed at 0 while the blink animation plays.
	if timeToNextBlink
	and (timeToNextBlink == 0)
	and (i < iterations) then
	-- wait for the blinking animation to end, but limited for safety
		data.i = i + 1
		if logLevel5 then
			mwse.log('%s: ab01smactiPT4() "%s" i = %s, iterations = %s',
				modPrefix, ref.id, data.i, iterations)
		end
		return
	end
	-- blinking done
	if logLevel4 then
		mwse.log('%s: ab01smactiPT4() playerActivate("%s", true) timeToNextBlink = %s, headMorphTiming = %s',
			modPrefix, ref.id, timeToNextBlink, animationData.headMorphTiming)
	end
	cancel()
	face(mob, player)
	playerActivate(ref, true)
	---mob:startDialogue()
end

local tes3_activeBodyPart_head = tes3.activeBodyPart.head

local function isFullHeadCover(stack)
	if not stack then
		return false
	end
	local item = stack.object
	if not item then
		return false
	end
	local parts = item.parts
	for i = 1, #parts do
		local part = parts[i]
		if part.type == tes3_activeBodyPart_head then
			return true
		end
	end
	return false
end

local tes3_objectType_armor = tes3.objectType.armor
local tes3_armorSlot_helmet = tes3.armorSlot.helmet

local function fullHeadCovered(ref)
	local stack = tes3.getEquippedItem({actor = ref,
		objectType = tes3_objectType_armor, slot = tes3_armorSlot_helmet})
	return isFullHeadCover(stack)
end

local function checkBlinkFix(mob)
	local ref = mob.reference
	if not ref then
		return
	end
	if fullHeadCovered(ref) then
		if logLevel3 then
			mwse.log('%s: checkBlinkFix("%s") head covered by full helmet, skip',
				modPrefix, ref.id)
		end
		return
	end
	local animationData = ref.attachments.animation
	if not animationData then
		return
	end
	local timeToNextBlink = animationData.timeToNextBlink
	if not (timeToNextBlink == 0) then
		if logLevel3 then
			mwse.log('%s: checkBlinkFix("%s") timeToNextBlink = %s, skip',
				modPrefix, ref.id, timeToNextBlink)
		end
		return -- blink animation not playing, skip
	end
	local blinkMorphStartTime = animationData.blinkMorphStartTime
	local blinkMorphEndTime = animationData.blinkMorphEndTime
	local blinkMorphDuration = blinkMorphEndTime - blinkMorphStartTime + 0.1
	if logLevel3 then
		mwse.log('%s: checkBlinkFix("%s") blinkMorphStartTime = %s, blinkMorphEndTime = %s, blinkMorphDuration = %s',
			modPrefix, ref.id, blinkMorphStartTime, blinkMorphEndTime, blinkMorphDuration)
	end
	local dur = 0.1
	local iters = math.ceil(blinkMorphDuration / dur + 0.5)
	local refHandle4 = tes3.makeSafeObjectHandle(ref)
	if logLevel2 then
		mwse.log([[%s: checkBlinkFix("%s") ab01smactiPT4timer = timer.start({type = timer_real, duration = %s, iterations = %s, callback = 'ab01smactiPT4'})]],
			modPrefix, ref.id, dur, iters)
	end
	ab01smactiPT4timer = timer.start({type = timer_real, duration = dur, iterations = iters,
		callback = 'ab01smactiPT4', data = {handle = refHandle4, i = 0, iterations = iters} })
	return true
end

local skipAnim -- set in faceAndTalk()

local function ab01smactiPT3(e)
	local ref = getTimerRef(e)
	if not ref then
		return
	end
	local mob = ref.mobile
	if not mob then
		return
	end

	if blinkFix
	and ( not tes3.is3rdPerson() )
	and (not ab01smactiPT4timer)
	and checkBlinkFix(mob) then
		return
	end
	face(mob, player)
	-- blink fix disabled or blink not playing
	if logLevel2 then
		mwse.log('%s: ab01smactiPT3() playerActivate("%s", true)', modPrefix, ref.id)
	end
	playerActivate(ref, true)
	---mob:startDialogue()
end

local scenicTravelPrefixDict = table.invert({'ab01ss','ab01bo','ab01go','ab01gu'})

local function isScenicTravelCreature(mobRef)
	local s = string.lower(string.sub(mobRef.object.id, 1, 6)) -- get the id prefix
	if scenicTravelPrefixDict[s] then
		return true
	end
	return false
end

local tes3_actorType_creature = tes3.actorType.creature

local function getCurrentAnimationGroup(mob)
	local actionData = mob.actionData or mob.actionBeforeCombat
	if actionData then
		return actionData.currentAnimationGroup
	end
end

local tes3_animationGroup_turnRight = tes3.animationGroup.turnRight
local tes3_animationGroup_turnLeft = tes3.animationGroup.turnLeft
local tes3_animationGroup_walkForward = tes3.animationGroup.walkForward
local tes3_animationGroup_idle = tes3.animationGroup.idle

local turnAnimDict = {
[tes3_animationGroup_turnRight] = true,
[tes3_animationGroup_turnLeft] = true,
[tes3_animationGroup_walkForward] = true
}

local function referenceActivated(e)
	local ref = e.reference
	local mob = ref.mobile
	if not mob then
		return
	end
	if not mob.actorType then
		return
	end
	if mob.isTurningRight
	or mob.isTurningLeft then
		return
	end
	local animGroup = getCurrentAnimationGroup(mob)
	if not animGroup then
		return
	end
	if (animGroup == tes3_animationGroup_idle)
	or (animGroup == 255) then
		return
	end
	if turnAnimDict[animGroup] then
		playGroupIdle(ref)
	end
end

local function faceAndTalk(ref)
	if faceAndTalkBusy then
		if logLevel3 then
			mwse.log('%s faceAndTalk(): faceAndTalkBusy, return', modPrefix)
		end
		faceAndTalkBusy = false
		return
	end
	local mob = ref.mobile
	if not mob then
		return
	end
	skipAnim = isAnimBlacklisted(ref)
	or isDummy(mob)

	local autoFace = config.autoFace -- 0 = Off, 1 = NPCs, 2 = NPCs & Creatureslocal
	local doFace = true
	if (autoFace == 0)
	or skipAnim then
		doFace = false
	end
	if doFace
	and (mob.actorType == tes3_actorType_creature) then
		if autoFace < 2 then
			doFace = false
		else
			doFace = not isScenicTravelCreature(ref)
		end
	end

	local isMoving = isAImoving(mob)
	if doFace
	and isMoving then
		skipAnim = true
		mob.activeAI = false
	end

	local activationDelay = 0
	local doResetAnim = true
	if doFace then
		--[[ -- nope does not work
		if mob.actionData
		and mob.actionData.walkDestination then
			mob.actionData.walkDestination = mob.position:copy() -- so actor stops walking away
		end]]

		local angleTo = mob:getViewToPoint(player.position)
		local absAngleTo = math.abs(angleTo)
		local degreeStep = 9
		if angleTo < 0 then
			degreeStep = -degreeStep
		end
		local animGroup

		local animationData = ref.attachments.animation
		if animationData then
			local animationGroups = animationData.animationGroups
			if animationGroups[tes3_animationGroup_turnRight + 1] then
				animGroup = tes3_animationGroup_turnRight
			elseif animationGroups[tes3_animationGroup_walkForward + 1] then
				animGroup = tes3_animationGroup_walkForward
			end
		end

		if absAngleTo >= config.minFaceAngle then
			radStep = math.rad(degreeStep)
			if angleTo < 0 then -- player is to the left of actor
				radStep = -radStep
				if animGroup == tes3_animationGroup_turnRight then
					animGroup = tes3_animationGroup_turnLeft
				end
			end
			local iters = math.max(math.floor((absAngleTo - degreeStep) / degreeStep), 0)
			if iters > 0 then
				local loops = math.max(math.floor(iters / 12), 1)
				local secStep = 0.05
				local delayStep = 0.13

				if not skipAnim then
					checkPlayAnimation(mob, animGroup, loops)
					doResetAnim = false
				end
				local refHandle2 = tes3.makeSafeObjectHandle(ref)
				-- start facing rotations
				faceAndTalkBusy = true

				if logLevel4 then
					mwse.log('%s: ab01smactiPT2("%s") radStep = %s (%s deg), iterations = %s',
						modPrefix, ref.id, radStep, math.deg(radStep), iters)
				end
				timer.start({ type = timer_real, duration = secStep, iterations = iters,
					callback = 'ab01smactiPT2', data = {handle = refHandle2, i = 0, iterations = iters, radStp = radStep} })
				---timer.start({ duration = secStep, iterations = iters,
					---callback = 'ab01smactiPT2', data = {handle = refHandle2, i = 0, iterations = iters} })
				activationDelay = iters * delayStep
			end
		end
	end

	if activationDelay > 0 then
		local refHandle3 = tes3.makeSafeObjectHandle(ref)
		timer.start({type = timer_real, duration = activationDelay, callback = 'ab01smactiPT3', data = {handle = refHandle3} })
		return
	elseif doFace
	and (not skipAnim) then
		face(mob, player)
	end

	if blinkFix
	and (not isMoving)
	and ( not tes3.is3rdPerson() )
	and (not ab01smactiPT4timer)
	and checkBlinkFix(mob) then
		return
	end

	if logLevel2 then
		mwse.log('%s: faceAndTalk() playerActivate("%s")', modPrefix, ref.id)
	end
	playerActivate(ref, true)
	---mob:startDialogue() -- nope
end

local function canStartDialogueWith(mob)
	local result = mob
	and mob.canMove
	and (not isDead(mob))
	and ( not string.find(string.lower(mob.reference.object.id), 'summon', 1, true) )
	and (
		(not mobilePlayer.isSneaking)
		or config.skipActivatingFollowerWhileSneaking
	)
	if result then
		return true
	end
	return false
end

local faceBlacklist = {'aa_latte_comp01'}
local faceMeshBlacklist = {'va_sitting.nif','roo_papcre'}

local function activate(e)
	local funcPrefix = modPrefix..' activate()'
	if skips > 0 then
		if logLevel3 then
			mwse.log('%s: skips = %s, return', funcPrefix, skips)
		end
		skips = skips - 1
		return
	end
	local activator = e.activator
	if not (activator == player) then
		if logLevel3 then
			mwse.log("%s: e.activator = %s, skip", funcPrefix, activator)
		end
		return
	end

	local target = e.target
	if logLevel2 then
		mwse.log('%s: e.target = "%s"', funcPrefix, target)
	end

	local obj = target.baseObject
	local objType = obj.objectType
	if not validTypes[objType] then
		if logLevel2 then
			mwse.log("%s: objType = %s, skip", funcPrefix, mwse.longToString(objType))
		end
		return
	end

	if inputController:isAltDown()
	or inputController:isShiftDown() then
		if logLevel2 then
			mwse.log("%s: Alt or Shift pressed, skip", funcPrefix)
		end
		return -- skip if Alt or Shift pressed
	end

	local mobile = target.mobile
	---assert(mobile) -- nope, it may be nil
	local rng = config.maxDistance

	if mobile then
		local boundSize = mobile.boundSize
		if boundSize then
			local boundMin = math.min(boundSize.x, boundSize.y)
			if boundMin > rng then
				rng = boundMin -- increase collision range for big creatures
				if logLevel2 then
					mwse.log("%s: max range set to %s, min bound size = %s", funcPrefix, target.id, rng)
				end
			end
		end
		if not actorsMenu then
			if canStartDialogueWith(mobile) then
				if (mobile.actorType == tes3_actorType_creature)
				and isScenicTravelCreature(target) then
					e.claim = true
					return
				end
				if string.multifind(string.lower(obj.id), faceBlacklist, 1, true)
				or string.multifind(string.lower(obj.mesh), faceMeshBlacklist, 1, true) then
					e.claim = true
					return
				end
				-- starting dialog directly is more robust with scripted NPCs than trying to player:activate()
				if skips == 0 then
					e.block = true
					e.claim = true
					faceAndTalk(target)
				end
			end
			return
		end -- if not actorsMenu
	end -- if mobile

	local numSelectables = 0
	if actorsMenu then
		selectables = getSelectablesInProximity(target, rng)
		numSelectables = #selectables
	end
	if numSelectables < 2 then
		if logLevel5 then
			mwse.log("%s: #selectables < 2, skip", funcPrefix)
		end
		if numSelectables == 1 then
			target = selectables[1].ref
			mobile = target.mobile
		end
		if mobile
		and mobile.actorType
		and canStartDialogueWith(mobile) then
			e.block = true
			e.claim = true
			if mobilePlayer.isSneaking
			or (
				(mobile.actorType == tes3_actorType_creature)
				and isScenicTravelCreature(target)
			) then
				if logLevel2 then
					mwse.log('%s: activate() playerActivate("%s")', modPrefix, target.id)
				end
				playerActivate(target)
			else
				faceAndTalk(target)
			end
		end
		return
	end

	table.sort(selectables, byNameAsc)

	local curr, prev ---, currId, prevId
	local modified = false
	local idCount = 0
	for j = 1, #selectables do
		curr = selectables[j]
		if prev then
			---currId = curr.ref.id
			---prevId = prev.ref.id
			if curr.name == prev.name then
				---if currId == prevId then -- probably not yet cloned references
					idCount = idCount + 1
					prev.name = string.format('%s %s', prev.name, idCount)
					idCount = idCount + 1
					curr.name = string.format('%s %s', curr.name, idCount)
				---else
					---prev.name = string.format('%s %s', prev.name, string.sub(prevId, -8))
					---curr.name = string.format('%s %s', curr.name, string.sub(currId, -8))
				---end
				modified = true
			end
		end
		prev = curr
	end

	if modified then
		table.sort(selectables, byNameAsc)
	end

	for k = 1, #selectables do
		curr = selectables[k]
		local aRef = curr.ref
		local aName = curr.name
		if aRef -- better safe than sorry
		and aName then
			if logLevel3 then
				mwse.log('%s: sorted selectables[%s] = {ref = "%s", name = "%s"})',
					funcPrefix, k, aRef.id, aName)
			end
			-- bah probably I don't understand how showMessageMenu buttons callbackParams are supposed to work
			msgBtns[k] = {text = aName,
				callback = function ()
					if aRef then
						local mobi = aRef.mobile
						if mobi
						and canStartDialogueWith(mobi) then
							if (mobi.actorType == tes3_actorType_creature)
							and isScenicTravelCreature(aRef) then
								playerActivate(aRef)
								return
							end
							-- starting dialog directly is more robust with scripted NPCs than trying to player:activate()
							if logLevel2 then
								mwse.log('%s: activate btn callback "%s"', funcPrefix, aRef.id)
							end
							msgBtns = {}
							selectables = {}
							faceAndTalk(aRef)
							return
						end

						---skips = 1
						local baseObj = aRef.baseObject
						if baseObj.objectType == tes3_objectType_container then
							local mesh = baseObj.mesh
							if mesh then
								local lcMesh = string.lower(mesh)
								lcMesh = back2slash(lcMesh)
								if string.find(lcMesh, 'ac/anim_', 1, true) then
									if logLevel2 then
										mwse.log("%s: animated container", funcPrefix)
									end
								end
							end
						end
						if logLevel2 then
							mwse.log('%s: delayedPlayerActivate("%s", 0.15)', funcPrefix, aRef.id)
						end
						delayedPlayerActivate(aRef, 0.15)
					end -- if aRef

					msgBtns = {}
					selectables = {}
				end -- function ()
			}

		end
	end

	-- important to skip this activate!
	e.block = true
	e.claim = true

	timer.delayOneFrame(
		function ()
			tes3ui.showMessageMenu({id = 'ab01smactiMenu', buttons = msgBtns,
				cancels = true, header = 'Activate:'})
		end
	)
end


local initDone = false
local function initOnce()
	if initDone then
		return
	end
	initDone = true
	-- higher priority than Smart Companions, Animated Containers
	event.register('activate', activate, {priority = 100010})
end

local function loaded()
	skips = 0
	player = tes3.player
	player1stPerson = tes3.player1stPerson
	mobilePlayer = tes3.mobilePlayer
	inputController = tes3.worldController.inputController
	initOnce()
end

local function beforeDestroyMenuDialog()
	skips = 0 -- ensure next actor dialog activate is not skipped
end

local function uiActivatedMenuDialog(e)
	if e.newlyCreated then
		local menu = e.element
		menu:registerBefore('destroy', beforeDestroyMenuDialog)
	end
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

--[[
local function logConfig(cfg, options)
	mwse.log(json.encode(cfg, options))
end
]]

local function modConfigReady()

	local template = mwse.mcm.createTemplate({name = mcmName})

	template.onClose = function()
		updateFromConfig()
		mwse.saveConfig(configName, config, {indent = true})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage({
		label = 'Preferences',
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	})

	local sidebar = preferences.sidebar
	sidebar:createInfo({text = ''})

	local controls = preferences:createCategory({})

	local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end

	local yesOrNo = {[false] = 'No', [true] = 'Yes'}

	local function getYesNoDescription(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	controls:createYesNoButton({
		label = 'Enable selection menu',
		description = getYesNoDescription([[Default: %s.
Enable selection menu to choose what to activate between nearby actors/containers/doors.
Note: MWSE-Lua recently greatly improved skinned meshes targeting precision, making this option almost obsolete.
It may still be useful/worth enabling it in some crowded places.
You can also skip the selection menu by pressing Alt or Shift keys while activating.
]], 'actorsMenu'),
		variable = createConfigVariable('actorsMenu')
	})

	controls:createYesNoButton({
		label = 'Allow NPCs',
		description = getYesNoDescription([[Default: %s.
Allow selecting NPCs in menu.]], 'allowNPC'),
		variable = createConfigVariable('allowNPC')
	})

	controls:createYesNoButton({
		label = 'Allow Creatures',
		description = getYesNoDescription([[Default: %s.
Allow selecting creatures in menu.]], 'allowCreature'),
		variable = createConfigVariable('allowCreature')
	})

	controls:createYesNoButton({
		label = 'Allow dead actors',
		description = getYesNoDescription([[Default: %s.
Allow selecting dead actors in menu.
Useful if you want to loot a dead creature or NPC.]], 'allowDead'),
		variable = createConfigVariable('allowDead')
	})

	controls:createYesNoButton({
		label = 'Allow containers',
		description = getYesNoDescription([[Default: %s.
Allow selecting containers in menu.
Useful if you want to loot a container in a crowded place.]], 'allowContainer'),
		variable = createConfigVariable('allowContainer')
	})
	controls:createYesNoButton({
		label = 'Allow organic containers',
		description = getYesNoDescription([[Default: %s.
Allow selecting organic/respawning containers
(e.g. plants, guild chests) in menu.]],	'allowOrganic'),
		variable = createConfigVariable('allowOrganic')
	})

	controls:createYesNoButton({
		label = 'Allow doors',
		description = getYesNoDescription([[Default: %s.
Allow selecting one door in menu.
Useful if you want to open a door in a crowded place.
(Only one door because often loading doors are near each other so better to avoid activating the linked one)
]], 'allowDoor'),
		variable = createConfigVariable('allowDoor')
	})

	controls:createSlider({
		label = 'Max distance',
		description = getDescription([[Default: %s.
Max distance between things to classify them as colliding each other.]], 'maxDistance'),
		variable = createConfigVariable('maxDistance')
		,min = 32, max = 192
	})

	controls:createSlider({
		label = 'Max selectable',
		description = getDescription([[Default: %s.
Max number of selectable targets.]], 'maxSelectable'),
		variable = createConfigVariable('maxSelectable')
		,min = 2, max = 30
	})

	local optionList = {'Off', 'NPCs', 'NPCs & Creatures'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s", i - 1, optionList[i]), value = i - 1}
		end
		return options
	end
	local function getDropDownDescription(frmt, variableId)
		local i = defaultConfig[variableId]
		return string.format(frmt, string.format('%s. %s', i, optionList[i+1]))
	end

	controls:createDropdown({
		label = 'Auto facing:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s.
Selected actor slowly turns around and face player on activate.]], 'autoFace'),
		variable = createConfigVariable('autoFace'),
	})

	controls:createYesNoButton({
		label = 'Blink Fix',
		description = getYesNoDescription([[Default: %s.
Try and reduce actor blinking eyes remaining closed while talking with player (in 1st person view).]], 'blinkFix'),
		variable = createConfigVariable('blinkFix')
	})

	controls:createYesNoButton({
		label = 'Immobile actors fix',
		description = getYesNoDescription([[Default: %s.
Give actors standing immobile some idle animation on activate.]], 'immobileFix'),
		variable = createConfigVariable('immobileFix')
	})

	controls:createSlider({
		label = 'Min autofacing angle %s',
		description = getDescription([[Default: %s degrees.
Minimun angle from player to trigger autofacing on activate.
Effective only with Auto facing enabled.]], 'minFaceAngle'),
		variable = createConfigVariable('minFaceAngle')
		,min = 5, max = 150
	})

	optionList = {'Off', 'Only Followers', 'All Actors'}
	controls:createDropdown({
		label = 'Play upper idle animation when rotating on activate:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','idleOnActivate'),
		variable = createConfigVariable('idleOnActivate'),
	})

	optionList = {'Off', 'Low', 'Medium', 'High', 'Higher', 'Max'}
	controls:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','logLevel'),
		variable = createConfigVariable('logLevel'),
	})

	mwse.mcm.register(template)
	---logConfig(config, {indent = false})

	event.register('referenceActivated', referenceActivated)

end
event.register('modConfigReady', modConfigReady)

event.register('initialized',
function ()
	improvedAnimationSupport = tes3.hasCodePatchFeature(tes3.codePatchFeature.improvedAnimationSupport)
	timer.register('ab01smactiPT1', ab01smactiPT1)
	timer.register('ab01smactiPT2', ab01smactiPT2)
	timer.register('ab01smactiPT3', ab01smactiPT3)
	timer.register('ab01smactiPT4', ab01smactiPT4)
	timer.register('ab01smactiPT5', ab01smactiPT5)
	event.register('loaded', loaded)
	event.register('uiActivated', uiActivatedMenuDialog, {filter = 'MenuDialog'})
end, {doOnce = true}
)

