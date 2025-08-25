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

-- cached for speed
local string_find = string.find
local string_format = string.format
local string_gsub = string.gsub
local string_lower = string.lower
local string_multifind = string.multifind
local string_startswith = string.startswith
local string_sub = string.sub
local mwse_log = mwse.log

-- set in modConfigReady
local bumpityLoaded = false

local function getSurroundingCells(cell, logTime)
	local etime = os.clock()
	local cells = {}
	local cellGridX = cell.gridX
	local cellGridY = cell.gridY
	local j = 0
	local logElapsedTime = logTime
		and logLevel1
	local gridX, gridY

	local function getCells()
		for dx = -1, 1 do
			gridX = cellGridX + dx
			for dy = -1, 1 do
				gridY = cellGridY + dy
				local c = tes3.getCell({x = gridX, y = gridY})
				if c then
					j = j + 1
					cells[j] = c
					if j >= 9 then
						return
					end
				end
			end
		end
	end

	getCells()
	if logElapsedTime then
		etime = os.clock() - etime
		mwse_log('%s: getSurroundingCells("%s") elapsed time: %.4f s',
			modPrefix, cell.editorName, etime)
	end
	return cells
end

local function getCellsCulled(ref, maxDistanceFromRef)
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

	local ac = getSurroundingCells(cell, true)
	-- nah on exterior borders it could be less assert(#ac >= 9)

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

	local j = 0
	for i = 1, #ac do
		if not skip[i] then
			j = j + 1
			cells[j] = ac[i]
			---mwse_log("culledCell = %s", ac[i].editorName)
		end
	end

	if (j == 0)
	or logLevel2 then
		local msg = "%s: getCellsCulled(ref = %s, maxDistanceFromRef = %s)"
		if j == 0 then
			msg = msg .. " no cells found!"
		end
		mwse_log(msg, modPrefix, ref, maxDistanceFromRef)
		if j > 0 then
			for i, c in ipairs(cells) do
				mwse_log("culledCell[%s] = %s", i, c.editorName)
			end
		end
	end

	return cells
end

local function byNameAsc(a, b)
	return a.name < b.name
end

local function byDistAsc(a, b)
	return a.dist < b.dist
end

local tes3_objectType = tes3.objectType
local tes3_objectType_npc = tes3_objectType.npc
local tes3_objectType_creature = tes3_objectType.creature
local tes3_objectType_container = tes3_objectType.container
local tes3_objectType_door = tes3_objectType.door

local selectableTypes = {
tes3_objectType_npc, tes3_objectType_creature,
tes3_objectType_container, tes3_objectType_door
}

---local readableObjectTypes = table.invert(tes3_objectType)

local selectables = {} -- e.g. {ref = targetRef, name = targetRef.object.name, dist = 0}}
local msgBtns = {}

local function back2slash(s)
	return string_gsub(s, [[\]], [[/]])
end

local function multifind2(s1, s2, t)
	return string_multifind(s1, t, 1, true)
	or string_multifind(s2, t, 1, true)
end

local dummies = {'dumm', 'mann', 'target', 'invis'}

local function isDummy(mobRef)
	local obj = mobRef.baseObject
	if multifind2(string_lower(obj.id), string_lower(obj.name), dummies) then
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
	if string_multifind(string_lower(back2slash(mesh)), dummies, 1, true) then
		return true
	end
	return false
end

local targetBlacklist = {'roht_mask_compass'}

local function isBlacklisted(obj)
	if string_multifind(string_lower(obj.id), targetBlacklist, 1, true) then
		return true
	end
	return false
end

local tes3_animationState_dying = tes3.animationState.dying
local tes3_animationState_dead = tes3.animationState.dead

local function isDead(mobile)
	local result = false
	if mobile.isDead then
		result = true
	else
		local actionData = mobile.actionData
		if actionData then
			local animState = actionData.animationAttackState
			if animState then
				if (animState == tes3_animationState_dead)
				or (animState == tes3_animationState_dying) then
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
			if (health.normalized <= 0.025) -- health ratio <= 2.5%
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
	local funcPrefix = string_format('%s: getSelectablesInProximity("%s", %s)',
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
				mwse_log('%s: aRef = "%s" aDist = %s > range = %s',
					funcPrefix, aRef.id, aDist, range)
			end
			return
		end
		if logLevel4 then
			mwse_log('%s: aRef = "%s" aDist = %s, range = %s',
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
			mwse_log('%s: aRef = "%s", mesh = "%s"', funcPrefix, aRef.id, mesh)
		end
		local objType = obj.objectType
		local ok = false

		local function checkMob()
			local mob = aRef.mobile
			if mob
			and ( not isBlacklisted(obj) )
			and ( not isDummy(aRef) ) then -- skip mannequins
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
				mwse_log('%s: mob = %s, ok = %s', funcPrefix, aRef.id, ok)
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
				mwse_log('%s: aName = "%s"', funcPrefix, aName)
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
				mwse_log('%s: t[%s] = {ref = "%s", name = "%s", dist = %s}',
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
			mwse_log('%s: processing "%s" interior', funcPrefix, cell.editorName)
		end
		processCell()
	else
		local culledCells = getCellsCulled(targetRef, range)
		for j = 1, #culledCells do
			cell = culledCells[j]
			if logLevel3 then
				mwse_log('%s: processing culledCells[%s] = %s', funcPrefix, j, cell.editorName)
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
			mwse_log('%s: sorted by distance', funcPrefix)
			for k = 1, count do
				local v = t[k]
				if logLevel3  then
					mwse_log('%s: t[%s] = {ref = "%s", name = "%s", dist = %s}',
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
	mwse_log(aiPackageMsgFrmt,
modPrefix, mob.reference, p.type, aiPackageTypes[p.type],
p.destinationCell, p.distance, p.hourOfDay, p.duration,
p.isDone, p.isFinalized, p.isMoving, p.isReset, p.isStarted,
p.mobile.reference, p.startGameHour, p.activateTarget,
targetActorId, json.encode(p.targetPosition),
chances)
end

local tes3_aiPackage_none = tes3.aiPackage.none
local tes3_aiPackage_travel = tes3.aiPackage.travel

local function getActiveAIpackage(mob)
	local aiPlanner = mob.aiPlanner
	if not aiPlanner then
		return
	end
	local p = aiPlanner:getActivePackage()
	if logLevel3
	and p then
		logAIpackage(mob, p)
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
		mwse_log('%s: isAImoving("%s") = true',
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
	if isDummy(ref) then
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

local function getAnimationData(ref)
--[[ 3 different places/addresses for this
ref.attachments.animation
mob.animationController.animationData
ref.animationData
]]
	local attachments = ref.attachments
	if not attachments then
		return
	end
	return attachments.animation
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
	local animationData = getAnimationData(ref)
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
		mwse_log('%s: fixImmobile("%s") idles to %s', modPrefix, ref.id, s)
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
	local lcMesh
	if mesh then
		lcMesh = string_lower(mesh)
	end
	if withSkips then
		if skips < 1 then
			skips = 1 -- important! at least 1, 0 may loop
		end
	else
		skips = 0
	end
	if actorsMenu
	or (
		lcMesh
		and string_find(lcMesh, 'ac\\anim_', 1, true)
	) then
		skips = skips + 1
	end
	if immobileFix
	and lcMesh
	and ( not string_multifind(lcMesh, immobileFixMeshBlacklist, 1, true) ) then
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
		mwse_log('%s: ab01smactiPT1() playerActivate("%s")', modPrefix, ref.id)
	end
	skips = 2
	playerActivate(ref, true)
end

local timer_real = timer.real

local function delayedPlayerActivate(targetRef, delaySec)
	local refHandle1 = tes3.makeSafeObjectHandle(targetRef)
	timer.start({ type = timer_real, duration = delaySec, callback = 'ab01smactiPT1',
		data = {handle = refHandle1} })
end


local validTypes = {
[tes3_objectType_npc] = true,
[tes3_objectType_creature] = true,
[tes3_objectType_container] = true,
[tes3_objectType_door] = true,
}

local animBlacklist = {'scamp','sitting','lean'}
local actorIdBlacklist = {'hrsct','1m_cat'}

local function isAnimBlacklisted(mobRef)
	local obj = mobRef.object
	local mesh = obj.mesh
	if not mesh then
		return false
	end
	if mesh == '' then
		return false
	end
	local s = string_lower(back2slash(mesh))
	if string_sub(s, 1, 3) == 'am/' then -- path starting with "am/", probably Antares' animation
		return true
	end
	if string_find(s, 'am_', 1, true) then -- am_ prefix somewhere in path, probably Antares'
		return true
	end
	if string_multifind(s, animBlacklist, 1, true) then
		return true
	end
	s = string_lower(obj.id)
	if string_multifind(s, actorIdBlacklist, 1, true) then
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
		mwse_log('%s: getRefVariable("%s", "%s") context = %s',
			modPrefix, ref.id, variableId, context)
	end
	-- need more safety
	local value = context[variableId]
	if value then
		if logLevel3 then
			mwse_log('%s: getRefVariable("%s", "%s") context["%s"] = %s)',
				modPrefix, ref.id, variableId, variableId, value)
		end
		return value
	end
	return nil
end

local function getCompanionVar(ref)
	local result = getRefVariable(ref, 'companion')
	if logLevel4 then
		mwse_log('%s: getCompanionVar("%s") = %s', modPrefix, ref.id, result)
	end
	return result
end

local function isCompanion(mobRef)
	local result = false
	local companion = getCompanionVar(mobRef)
	if companion
	and (companion == 1)
	and ( not isDummy(mobRef) ) then
		result = true
	end
	if logLevel4 then
		mwse_log('%s: isCompanion("%s") = %s', modPrefix, mobRef.id, result)
	end
	return result
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
		local lcSourceMod = string_lower(sourceMod)
		if string_startswith(lcSourcemod, 'abotwaterlife')
		or string_startswith(lcSourcemod, 'abotwhereareallbirds') then
			return false
		end
	end]]
	local script = mobObj.script
	if script then
		local lcId2 = string_lower(script.id)
		if string_startswith(lcId2, 'ab01') then
			-- ab01 prefix, probably some abot's creature having AIEscort package, skip
			if logLevel3 then
				mwse_log("%s: %s having ab01 prefix, probably some abot's creature with AIEscort package, skip",
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

local tes3_compilerSource_console = tes3.compilerSource.console
local tes3_animationGroup_idle = tes3.animationGroup.idle

local function playGroupIdle(mobRef, legacy)
-- As a special case, tes3.playAnimation{reference = ..., group = 0}
-- returns control to the AI, as the AI knows that is the actor's neutral idle state.
	if logLevel2 then
		mwse_log('%s: playGroupIdle("%s", %s)', modPrefix, mobRef, legacy)
	end
	if legacy then
		tes3.runLegacyScript({reference = mobRef, command = 'PlayGroup idle',
			source = tes3_compilerSource_console})
	else
		-- let's try giving non-console command another chance
		tes3.playAnimation({reference = mobRef, group = tes3_animationGroup_idle})
	end
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
	playGroupIdle(ref, true)
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
	local lowAnimGroupOk
	if idleOnActivate == 1 then -- followers
		-- 0 = invalid, 1 = follower, 2 = companion
		lowAnimGroupOk = validFollower(mob, true) > 0
	elseif idleOnActivate == 2 then -- all actors
		lowAnimGroupOk = isValidMobile(mob)
	else
		lowAnimGroupOk = false
	end
	local animOk = false
	if animGroup
	and loops then
		animOk = true
		local animationData = getAnimationData(ref)
		if animationData
		and animationData.hasOverrideAnimations then
			animOk = false -- skip e.g. a drummer
		end
		if animOk then
			local randGroup = talkAnims[math.random(1, #talkAnims)]
			local params = {reference = ref, group = randGroup, loopCount = loops}
			--- nope , startFlag = tes3.animationStartFlag.normal}
			if improvedAnimationSupport then
				if lowAnimGroupOk then
					params['lower'] = animGroup
				end
				if logLevel3 then
					mwse_log('%s: tes3.playAnimation({reference = "%s", group = %s, lower = %s, loopCount = %s})',
						modPrefix, ref.id, randGroup, animGroup, loops)
				end
			else
				if logLevel3 then
					mwse_log('%s: tes3.playAnimation({reference = "%s", group = %s, loopCount = %s})',
						modPrefix, ref.id, randGroup, animGroup, loops)
				end
			end
			tes3.playAnimation(params)
		end
	end
	---if lowAnimGroupOk then
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

local pi = math.pi
local double_pi = pi + pi

local function normalizedAngle(angle)
	local a = angle % double_pi
	if a > pi then
		a = a - double_pi
	elseif a < -pi then
		a = a + double_pi
	end
	return a
end

local function getAngleTo(ref, target)
	local angleTo
	local mob = ref.mobile
	if mob
	and mob.actorType then
		-- this one keeps the sign and works better
		angleTo = math.rad(mob:getViewToPoint(target.position))
	else
		angleTo = ref:getAngleTo(target)
	end
	if logLevel3 then
		mwse_log([[%s: getAngleTo("%s","%s") = %.2f]],
			modPrefix, ref.id, target.id, math.deg(angleTo))
	end
	return angleTo
end

local function getFacingAngle(ref, target)
	local angleTo = getAngleTo(ref, target)
	local refAngle = normalizedAngle(ref.facing)
	local facingAngle = refAngle + angleTo
	facingAngle = normalizedAngle(facingAngle)
	if logLevel3 then
		mwse_log([[%s: getFacingAngle("%s","%s")
refAngle = %.2f, angleToTarget = %.2f, facingAngle = %.2f]],
			modPrefix, ref.id, target.id, math.deg(ref.facing),
			math.deg(angleTo), math.deg(facingAngle))
	end
	return facingAngle
end

local function face(ref, target)
	ref.facing = getFacingAngle(ref, target)
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

	local function cancel()
		timer:cancel()
		faceAndTalkBusy = false
		ref.mobile.activeAI = true
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
		mwse_log('%s: ab01smactiPT2("%s") i = %s',
			modPrefix, ref.id, i)
	end
	if i >= iterations then
		faceAndTalkBusy = false
		if iterations >= 0 then
			face(ref, player)
		end
		return
	end
	ref.facing = ref.facing + data.radStp
	-- note: mobile.facing is read only!!!
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

local tes3_objectType_armor = tes3_objectType.armor
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
			mwse_log('%s: checkBlinkFix("%s") head covered by full helmet, skip',
				modPrefix, ref.id)
		end
		return
	end
	local animationData = getAnimationData(ref)
	if not animationData then
		return
	end
	-- should be automatically set to 0 while blinking
	local timeToNextBlink = animationData.timeToNextBlink
	if not timeToNextBlink then -- it happens
		return
	end
	local blinkMorphStartTime = animationData.blinkMorphStartTime
	local blinkMorphEndTime = animationData.blinkMorphEndTime
	local blinkDuration = blinkMorphEndTime - blinkMorphStartTime

	if timeToNextBlink > (blinkDuration * 0.25) then
		if logLevel3 then
			mwse_log('%s: checkBlinkFix("%s") timeToNextBlink = %s, skip',
				modPrefix, ref, timeToNextBlink)
		end
		return -- blink animation not playing, skip
	end
	animationData.headMorphTiming = 0
	animationData.timeToNextBlink = math.round( (blinkMorphStartTime + blinkMorphEndTime) * 0.5, 2 )
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

	if blinkFix then
		if checkBlinkFix(mob) then
			delayedPlayerActivate(ref, 0.1)
			return
		end
	end
	-- blink fix disabled or blink not playing
	if logLevel2 then
		mwse_log('%s: ab01smactiPT3() playerActivate("%s", true)', modPrefix, ref.id)
	end
	playerActivate(ref, true)
	---mob:startDialogue()
end

local scenicTravelPrefixDict = table.invert({'ab01ss','ab01bo','ab01go','ab01gu'})

local function isScenicTravelCreature(mobRef)
	local s = string_lower(string.sub(mobRef.object.id, 1, 6)) -- get the id prefix
	if scenicTravelPrefixDict[s] then
		return true
	end
	return false
end

local tes3_actorType_creature = tes3.actorType.creature

--[[local function getCurrentAnimationGroup(mob)
	local actionData = mob.actionData or mob.actionBeforeCombat
	if actionData then
		return actionData.currentAnimationGroup
	end
end]]

local tes3_animationGroup = tes3.animationGroup
local tes3_animationGroup_turnRight = tes3_animationGroup.turnRight
local tes3_animationGroup_turnLeft = tes3_animationGroup.turnLeft
local tes3_animationGroup_walkForward = tes3_animationGroup.walkForward

local turnAnimDict = {
[tes3_animationGroup_turnRight] = true,
[tes3_animationGroup_turnLeft] = true,
[tes3_animationGroup_walkForward] = true
}

local animationGroupDict = table.invert(tes3_animationGroup)

local lowerBodyIndex = tes3.animationBodySection.lower + 1

local function checkAnim(ref)
	local mob = ref.mobile
	if not mob then
		return
	end
	if not mob.actorType then
		return
	end
	local animationData = ref.animationData
	if not animationData then
		return
	end
	if animationData.hasOverrideAnimations then
		return
	end
	local currentAnimGroups = animationData.currentAnimGroups
	if not currentAnimGroups then
		return
	end
	local animGroupLower = currentAnimGroups[lowerBodyIndex]
	if not animGroupLower then
		return
	end
	if logLevel2 then
		local s = animationGroupDict[animGroupLower]
		mwse_log('%s: checkAnim("%s") animGroupLower = %s (%s))',
			modPrefix, ref, animGroupLower, s)
	end
	if turnAnimDict[animGroupLower] then
		if mob == mobilePlayer then
			return
		end
		if logLevel1 then
			mwse_log('%s: checkAnim("%s") playGroupIdle()', modPrefix, ref)
		end
		playGroupIdle(ref)
	end
end

local function referenceActivated(e)
	checkAnim(e.reference)
end

local function mobileActivated(e)
	checkAnim(e.reference)
end

local function faceAndTalk(mobRef)
	if faceAndTalkBusy then
		if logLevel3 then
			mwse_log('%s faceAndTalk(): faceAndTalkBusy, return', modPrefix)
		end
		faceAndTalkBusy = false
		return
	end
	local mob = mobRef.mobile
	if not mob then
		return
	end
	skipAnim = isAnimBlacklisted(mobRef)
	or isDummy(mobRef)

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
			doFace = not isScenicTravelCreature(mobRef)
		end
	end

	local isMoving = isAImoving(mob)
	if doFace
	and isMoving then
		skipAnim = true
	end

	local activationDelay = 0
	local doResetAnim = true
	if doFace then
		--[[ -- nope does not work
		if mob.actionData
		and mob.actionData.walkDestination then
			mob.actionData.walkDestination = mob.position:copy() -- so actor stops walking away
		end]]

		local angleTo = math.deg(getAngleTo(mobRef, player))

		local absAngleTo = math.abs(angleTo)
		local degreeStep = 9

		local animGroup

		local animationData = getAnimationData(mobRef)
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
				local refHandle2 = tes3.makeSafeObjectHandle(mobRef)
				-- start facing rotations
				faceAndTalkBusy = true

				if logLevel4 then
					mwse_log('%s: ab01smactiPT2("%s") radStep = %s (%s deg), iterations = %s',
						modPrefix, mobRef.id, radStep, math.deg(radStep), iters)
				end
				if isMoving then
					mob.activeAI = false
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
		local refHandle3 = tes3.makeSafeObjectHandle(mobRef)
		timer.start({type = timer_real, duration = activationDelay, callback = 'ab01smactiPT3', data = {handle = refHandle3} })
		return
	elseif doFace
	and (not skipAnim) then
		face(mobRef, player)
	end

	if blinkFix then
		if checkBlinkFix(mob) then
			delayedPlayerActivate(mobRef, 0.1)
			return
		end
	end

	if logLevel2 then
		mwse_log('%s: faceAndTalk() playerActivate("%s")', modPrefix, mobRef.id)
	end
	playerActivate(mobRef, true)
	---mob:startDialogue() -- nope
end

local function canStartDialogueWith(mob)
	local result = mob
	and mob.canMove
	and (not isDead(mob))
	and ( not string_find(string_lower(mob.reference.object.id), 'summon', 1, true) )
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
	local activator = e.activator
	if not (activator == player) then
		if logLevel3 then
			mwse_log("%s: e.activator = %s, skip", funcPrefix, activator)
		end
		return
	end

	local target = e.target
	if logLevel2 then
		mwse_log('%s: e.target = "%s"', funcPrefix, target)
	end

	if skips > 0 then
		if logLevel3 then
			mwse_log('%s: skips = %s, return', funcPrefix, skips)
		end
		skips = skips - 1
		return
	end

	local obj = target.baseObject
	local objType = obj.objectType
	if not validTypes[objType] then
		if logLevel2 then
			mwse_log("%s: objType = %s, skip", funcPrefix, mwse.longToString(objType))
		end
		return
	end

	if inputController:isAltDown()
	or inputController:isShiftDown() then
		if logLevel2 then
			mwse_log("%s: Alt or Shift pressed, skip", funcPrefix)
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
					mwse_log("%s: max range set to %s, min bound size = %s", funcPrefix, target.id, rng)
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
				if string_multifind(string_lower(obj.id), faceBlacklist, 1, true)
				or string_multifind(string_lower(obj.mesh), faceMeshBlacklist, 1, true) then
					e.claim = true
					return
				end
				-- starting dialog directly is more robust with scripted NPCs than trying to player:activate()
				if skips == 0 then
					e.block = true
					e.claim = true
					faceAndTalk(target)
				elseif not bumpityLoaded then
					checkAnim(target)
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
			mwse_log("%s: #selectables < 2, skip", funcPrefix)
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
					mwse_log('%s: activate() playerActivate("%s")', modPrefix, target.id)
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
				idCount = idCount + 1
				prev.name = string_format('%s %s', prev.name, idCount)
				idCount = idCount + 1
				curr.name = string_format('%s %s', curr.name, idCount)
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
				mwse_log('%s: sorted selectables[%s] = {ref = "%s", name = "%s"})',
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
								mwse_log('%s: activate btn callback "%s"', funcPrefix, aRef.id)
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
								local lcMesh = string_lower(mesh)
								lcMesh = back2slash(lcMesh)
								if string_find(lcMesh, 'ac/anim_', 1, true) then
									if logLevel2 then
										mwse_log("%s: animated container", funcPrefix)
									end
								end
							end
						end
						if logLevel2 then
							mwse_log('%s: delayedPlayerActivate("%s", 0.15)', funcPrefix, aRef.id)
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

local registerOnce = false

local function loaded()
	skips = 0
	player = tes3.player
	player1stPerson = tes3.player1stPerson
	mobilePlayer = tes3.mobilePlayer
	inputController = tes3.worldController.inputController
	
	if not bumpityLoaded then
		local lastLoadedFile = tes3.dataHandler.nonDynamicData.lastLoadedFile
		if lastLoadedFile then -- nil on new game
			local cell = player.cell
			if cell.displayName == lastLoadedFile.cellName then
				if logLevel1 then
					mwse.log('%s: loaded in same "%s" cell, checking actors animations',
						modPrefix, lastLoadedFile.cellName)
				end
				for _, ref in pairs(cell.actors) do
					checkAnim(ref)
				end
			end	
		end
	end
	
	if registerOnce then
		return
	end
	registerOnce = true
	-- higher priority than Smart Companions, Animated Containers
	event.register('activate', activate, {priority = 100010})
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

-- local function createConfigVariable(varId)
	-- return mwse.mcm.createTableVariable{id = varId,	table = config}
-- end

--[[
local function logConfig(cfg, options)
	mwse_log(json.encode(cfg, options))
end
]]

local function onClose()
	updateFromConfig()
	mwse.saveConfig(configName, config, {indent = true})
end

local function modConfigReady()

	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})


	local sideBarPage = template:createSideBarPage({
		label = modName,
		showHeader = false,
		showReset = true,
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	})

	sideBarPage:createYesNoButton({
		label = 'Enable selection menu',
		description = [[
Enable selection menu to choose what to activate between nearby actors/containers/doors.
Note: MWSE-Lua recently greatly improved skinned meshes targeting precision, making this option almost obsolete.
It may still be useful/worth enabling it in some crowded places.
You can also skip the selection menu by pressing Alt or Shift keys while activating.]],
		configKey = 'actorsMenu'
	})

	sideBarPage:createYesNoButton({
		label = 'Allow NPCs',
		description = [[Allow selecting NPCs in menu.]],
		configKey = 'allowNPC'
	})

	sideBarPage:createYesNoButton({
		label = 'Allow Creatures',
		description = [[Allow selecting creatures in menu.]],
		configKey = 'allowCreature'
	})

	sideBarPage:createYesNoButton({
		label = 'Allow dead actors',
		description = [[Allow selecting dead actors in menu.
Useful if you want to loot a dead creature or NPC.]],
		configKey = 'allowDead'
	})

	sideBarPage:createYesNoButton({
		label = 'Allow containers',
		description = [[Allow selecting containers in menu.
Useful if you want to loot a container in a crowded place.]],
		configKey = 'allowContainer'
	})
	sideBarPage:createYesNoButton({
		label = 'Allow organic containers',
		description = [[Allow selecting organic/respawning containers
(e.g. plants, guild chests) in menu.]],
		configKey = 'allowOrganic'
	})

	sideBarPage:createYesNoButton({
		label = 'Allow doors',
		description = [[Allow selecting one door in menu.
Useful if you want to open a door in a crowded place.
(Only one door because often loading doors are near each other so better to avoid activating the linked one)]],
		configKey = 'allowDoor'
	})

	sideBarPage:createSlider({
		label = 'Max distance',
		description = [[Max distance between things to classify them as colliding each other.]],
		configKey = 'maxDistance'
		,min = 32, max = 192
	})

	sideBarPage:createSlider({
		label = 'Max selectable',
		description = [[Max number of selectable targets.]],
		configKey = 'maxSelectable'
		,min = 2, max = 30
	})

	local optionList = {'Off', 'NPCs', 'NPCs & Creatures'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string_format("%s. %s", i - 1, optionList[i]), value = i - 1}
		end
		return options
	end
	--[[
	local function getDropDownDescription(frmt, variableId)
		local i = defaultConfig[variableId]
		return string_format(frmt, string_format('%s. %s', i, optionList[i+1]))
	end]]

	sideBarPage:createDropdown({
		label = 'Auto facing:',
		options = getOptions(),
		description = [[Selected actors slowly turns around and face player on activate.]],
		configKey = 'autoFace'
	})

	sideBarPage:createYesNoButton({
		label = 'Blink Fix',
		description = [[Try and reduce actor blinking eyes remaining closed while talking with player (in 1st person view).]],
		configKey = 'blinkFix'
	})

	sideBarPage:createYesNoButton({
		label = 'Immobile actors fix',
		description = [[Give actors standing immobile some idle animation on activate.]],
		configKey = 'immobileFix'
	})

	sideBarPage:createSlider({
		label = 'Min autofacing angle %s',
		description = [[Minimun angle from player to trigger autofacing on activate.
Effective only with Auto facing enabled.]],
		configKey = 'minFaceAngle'
		,min = 5, max = 150
	})

	optionList = {'Off', 'Only Followers', 'All Actors'}
	sideBarPage:createDropdown({
		label = 'Play lower animation when facing player on activate:',
		options = getOptions(),
		configKey = 'idleOnActivate',
	})

	optionList = {'Off', 'Low', 'Medium', 'High', 'Higher', 'Max'}
	sideBarPage:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		configKey = 'logLevel'
	})

	mwse.mcm.register(template)
	---logConfig(config, {indent = false})

	bumpityLoaded = tes3.getFileExists("MWSE\\mods\\abot\\Bumpity Bump\\main.lua")
	if not bumpityLoaded then
		event.register('referenceActivated', referenceActivated)
		event.register('mobileActivated', mobileActivated)
	end
end
event.register('modConfigReady', modConfigReady)

event.register('initialized',
function ()
	improvedAnimationSupport = tes3.hasCodePatchFeature(tes3.codePatchFeature.improvedAnimationSupport)
	timer.register('ab01smactiPT1', ab01smactiPT1)
	timer.register('ab01smactiPT2', ab01smactiPT2)
	timer.register('ab01smactiPT3', ab01smactiPT3)
	---timer.register('ab01smactiPT4', ab01smactiPT4)
	timer.register('ab01smactiPT5', ab01smactiPT5)
	---timer.register('ab01smactiPT6', ab01smactiPT6)
	event.register('loaded', loaded)
	event.register('uiActivated', uiActivatedMenuDialog, {filter = 'MenuDialog'})
end, {doOnce = true}
)

