---@diagnostic disable: need-check-nil
--[[
allow to choose who to activate between nearby actors
]]

local defaultConfig = {
actorsMenu = false, -- actorsMenu toggle
maxDistance = 72, -- Max distance between actors to classify them as colliding each other
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
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium, 3 = High
}

local author = 'abot'
local modName = 'Smart Activate'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)
--[[
-- fix old typo
if config.idleOnActivete then
	config.idleOnActivate = config.idleOnActivete
	config.idleOnActivete = nil
end
]]

local maxSelectable, allowDead, allowNPC, allowCreature
local allowContainer, allowOrganic, allowDoor, blinkFix
local actorsMenu
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4, logLevel5

local function updateFromConfig()
	assert(config)
	maxSelectable = config.maxSelectable
	allowDead = config.allowDead
	allowNPC = config.allowNPC
	allowCreature = config.allowCreature
	allowContainer = config.allowContainer
	allowOrganic = config.allowOrganic
	allowDoor = config.allowDoor
	blinkFix = config.blinkFix
	actorsMenu = config.actorsMenu
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

	if (j == 0)
	or logLevel2 then
		local msg = "%s: getActiveCellsCulled(ref = %s, maxDistanceFromRef = %s)"
		if j == 0 then
			msg = msg .. " no cells found!"
		end
		mwse.log(msg, modPrefix, ref, maxDistanceFromRef)
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

local dummies = {'dumm', 'mann', 'target', 'invis'}

local function isDummy(mob)
	local mobRef = mob.reference
	local obj = mobRef.baseObject
	if string.multifind(string.lower(obj.name), dummies, 1, true) then
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

local function isDead(mobile)
	if mobile.isDead then
		return true
	end
	local health = mobile.health
	if health
	and health.current
	and (health.current < 3) then
		if (health.normalized <= 0.025)
		and (health.normalized > 0) then
			health.current = 0 -- kill when nearly dead, could be a glitch
		end
		if health.current <= 0 then
			return true
		end
	end
	return false
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
		local aDist = targetRefPos:distance(aRef.position)
		if aDist > range then
			return
		end
		if logLevel5 then
			mwse.log('%s: aRef = "%s" aDist = %s, range = %s',
				funcPrefix, aRef.id, aDist, range)
		end
		if aRef.disabled
		or aRef.deleted then
			return
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
		if ( (objType == tes3_objectType_npc) and allowNPC )
		or ( (objType == tes3_objectType_creature) and allowCreature) then
			local mob = aRef.mobile
			if mob
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

	if mobCount == 0 then -- no actors, no need for special menu
		return {[1] = {ref = targetRef, name = targetRef.object.name, dist = 0}}
	end

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

local function getTimerRef(e)
	local timer = e.timer
	if not timer then
		return
	end
	local data = timer.data
	if not data then
		return
	end
	local handle = data.handle
	if not handle then
		return
	end
	if not handle.valid then -- bah. it happens
		return
	end
	if not handle:valid() then
		return
	end
	local ref = handle:getObject()
	return ref
end

-- reset in loaded() and beforeDestroyMenuDialog()
local skips = 0
---local skips2 = 0

local timer_real = timer.real

local function playerActivate(ref, withSkips)
	if withSkips then
		skips = 1
		if actorsMenu then
			skips = skips + 1
		end
		local mesh = ref.object.mesh
		if string.find(string.lower(mesh), 'ac\\anim_', 1, true) then
			skips = skips + 1
		end
		---skips2 = 1
	end
	player:activate(ref)
end

local function ab01smacPT1(e)
	local ref = getTimerRef(e)
	if not ref then
		return
	end
	if logLevel2 then
		mwse.log('%s: ab01smacPT1() playerActivate("%s")', modPrefix, ref.id, skips)
	end
	playerActivate(ref, true)
end

local function delayedPlayerActivate(targetRef, delaySec)
	local refHandle1 = tes3.makeSafeObjectHandle(targetRef)
	timer.start({ type = timer_real, duration = delaySec, callback = 'ab01smacPT1', data = {handle = refHandle1} })
end


local validTypes = {
[tes3_objectType_npc] = true,
[tes3_objectType_creature] = true,
[tes3_objectType_container] = true,
[tes3_objectType_door] = true,
}

local animBlacklist = {'scamp'}

local function isAnimBlacklisted(mobRef)
	local mesh = mobRef.object.mesh
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
	return false
end

local tes3_aiPackage_follow = tes3.aiPackage.follow
local tes3_aiPackage_wander = tes3.aiPackage.wander
local tes3_aiPackage_escort = tes3.aiPackage.escort
local tes3_actorType_creature = tes3.actorType.creature
local tes3_actorType_npc = tes3.actorType.npc

local function getRefVariable(ref, variableId)
	local script = ref.object.script
	if not script then
		return nil
	end
	local context = ref['context']
	if not context then
		return nil
	end
	local value = context[variableId]
	if value then
		--[[
		assert(value == context[string.lower(variableId)]) -- not case sensitive any more?
		assert(value == context[string.upper(variableId)]) -- not case sensitive any more?
		if logLevel2 then
			mwse.log('%s: getRefVariable("%s", "%s") context["%s"] = %s)',
				modPrefix, ref.id, variableId, variableId, value)
		end
		]]
		return value
	end
	--[[local vd = context:getVariableData()
	local lcVariableId = string.lower(variableId)
	for k, v in pairs(vd) do
		if v then
			if string.lower(k) == lcVariableId then
				return v
			end
		end
	end]]
	return nil
end

local function getCompanion(ref)
	return getRefVariable(ref, 'companion')
end

local function isCompanion(mobRef)
	local companion = getCompanion(mobRef)
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

	if mob.actorType == tes3_actorType_npc then
		return true
	end

	--[[ nah, transport creatures are fine
	local lcId = string.lower(mobRef.object.id)
	if lcId == 'ab01guguarpackmount' then -- this is a good one
		return true
	end
	if string.startswith(lcId, 'ab01') then
-- ab01 prefix, probably some abot's creature having AIEscort package, skip
		return false
	end]]

	local mobObj = mobRef.object
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

local function getOneTimeMove(ref)
	return getRefVariable(ref, 'oneTimeMove')
end

-- 0 = invalid, 1 = follower, 2 = companion
local function validFollower(mob, anyFollower)
	if (not mob.canMove) -- dead, knocked down, knocked out, hit stunned, or paralyzed.
	or (not isValidMobile(mob)) then
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
		and aCompanion then
		-- special case for wandering companions
		local oneTimeMove = getOneTimeMove(mobRef)
		if oneTimeMove
		and ( not (oneTimeMove == 0) ) then
-- assuming a companion scripted to do move-away using temporary aiwander
			return 2
		end
	end

	return 0
end

-- set in initialized()
local improvedAnimationSupport -- needed to safely tes3.playAnimation()

local function aiWander0(mobRef, rst)
	if not rst then
		rst = false
	end
	tes3.setAIWander({reference = mobRef, duration = 0, idles = {0, 0, 0, 0, 0, 0, 0, 0}, reset = rst})
end

local function wanderInPlace(mobRef)
	tes3.setAIWander({ reference = mobRef, duration = 1, idles = {60, 40, 30, 0, 0, 0, 0, 0}, reset = false })
end

local function playGroupIdle(ref)
	tes3.playAnimation({reference = ref, group = 0})
end

local function ab01smacPT5(e)
	local ref = getTimerRef(e)
	if not ref then
		return
	end
	local mob = ref.mobile
	if not mob then
		return
	end
	playGroupIdle(ref)
	aiWander0(ref, true)
end

local talkAnims = {tes3.animationGroup.idle, tes3.animationGroup.idle2,
tes3.animationGroup.idle3, tes3.animationGroup.idle4}

local function checkPlayAnimation(mob, animGroup, loops, force)
	local mobRef = mob.reference
	if not mobRef then
		return
	end
	if isAnimBlacklisted(mobRef) then
		return
	end
	local idleOnActivate = config.idleOnActivate
	local idleOk
	if idleOnActivate == 1 then -- followers
		-- 0 = invalid, 1 = follower, 2 = companion
		idleOk = validFollower(mob, true) > 0
	elseif idleOnActivate == 2 then -- all actors
		idleOk = true
	elseif force then
		idleOk = true
	else
		idleOk = false
	end
	local animOk = false
	if animGroup
	and loops then
		animOk = true
		local animationController = mob.animationController
		if animationController -- could be nil
		and animationController.animationData.hasOverrideAnimations then
			animOk = false -- skip e.g. a drummer
		end
		if animOk then
			local randGroup = talkAnims[math.random(1, #talkAnims)]
			local params = {reference = mobRef, group = randGroup, loopCount = loops}
			if improvedAnimationSupport then
				if idleOk then
					params['lower'] = animGroup
				end
				if logLevel3 then
					mwse.log('%s: tes3.playAnimation({reference = "%s", group = %s, lower = %s, loopCount = %s})',
						modPrefix, mobRef.id, randGroup, animGroup, loops)
				end
			else
				if logLevel3 then
					mwse.log('%s: tes3.playAnimation({reference = "%s", group = %s, loopCount = %s})',
						modPrefix, mobRef.id, randGroup, animGroup, loops)
				end
			end
			tes3.playAnimation(params)
		end
	end
	---if idleOk then
		if animOk
		and (loops > 0) then
			local delay = loops * 0.7
			local refHandle5 = tes3.makeSafeObjectHandle(mobRef)
			---aiWander0(mobRef)
			timer.start({duration = delay, callback = 'ab01smacPT5',
				data = {handle = refHandle5}
			})
			return
		end
	---end
	---wanderInPlace(mobRef)
end

local radStep

local faceAndTalkBusy = false

local function ab01smacPT2(e)
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
	local nextFacing = ref.facing + radStep
	if logLevel5 then
		mwse.log('%s: ab01smacPT2("%s") radStep = %s (%s deg), i = %s, iterations = %s',
			modPrefix, ref.id, radStep, math.deg(radStep), i, iterations)
	end

	if i >= iterations then
		nextFacing = player.facing - math.pi
		faceAndTalkBusy = false
	end
	-- note: mobile.facing is read only!!!
	ref.facing = nextFacing
end


local ab01smacPT4timer -- link to persistent timer

local function ab01smacPT4(e)
	local timer = e.timer
	if not timer then
		return
	end

	local function cancel()
		timer:cancel()
		ab01smacPT4timer = nil
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
	local animationController = mob.animationController
	if not animationController then
		cancel()
		return
	end
	local animationData = animationController.animationData
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
			mwse.log('%s: ab01smacPT4() "%s" i = %s, iterations = %s',
				modPrefix, ref.id, data.i, iterations)
		end
		return
	end
	-- blinking done
	if logLevel4 then
		mwse.log('%s: ab01smacPT4() playerActivate("%s") timeToNextBlink = %s, headMorphTiming = %s',
			modPrefix, ref.id, timeToNextBlink, animationData.headMorphTiming)
	end
	cancel()
	playerActivate(ref, true)
	---mob:startDialogue()
end

local function checkBlinkFix(mob)
	--[[
	if ab01smacPT4timer then
		return -- busy already, skip
	end
	if not blinkFix then
		return
	end
	]]
	local mobRef = mob.reference
	if not mobRef then
		return
	end
	local animationController = mob.animationController
	if not animationController then
		return
	end
	local animationData = animationController.animationData
	local timeToNextBlink = animationData.timeToNextBlink
	if not (timeToNextBlink == 0) then
		if logLevel3 then
			mwse.log('%s: checkBlinkFix("%s") timeToNextBlink = %s, skip',
				modPrefix, mobRef.id, timeToNextBlink)
		end
		return -- blink animation not playing, skip
	end
	local blinkMorphStartTime = animationData.blinkMorphStartTime
	local blinkMorphEndTime = animationData.blinkMorphEndTime
	local blinkMorphDuration = blinkMorphEndTime - blinkMorphStartTime + 0.1
	if logLevel3 then
		mwse.log('%s: checkBlinkFix("%s") blinkMorphStartTime = %s, blinkMorphEndTime = %s, blinkMorphDuration = %s',
			modPrefix, mobRef.id, blinkMorphStartTime, blinkMorphEndTime, blinkMorphDuration)
	end
	local dur = 0.1
	local iters = math.ceil(blinkMorphDuration / dur + 0.5)
	local refHandle4 = tes3.makeSafeObjectHandle(mobRef)
	if logLevel2 then
		mwse.log([[%s: checkBlinkFix("%s") ab01smacPT4timer = timer.start({type = timer_real, duration = %s, iterations = %s, callback = 'ab01smacPT4'})]],
			modPrefix, mobRef.id, dur, iters)
	end
	ab01smacPT4timer = timer.start({type = timer_real, duration = dur, iterations = iters,
		callback = 'ab01smacPT4', data = {handle = refHandle4, i = 0, iterations = iters} })
	return true
end

local skipAnim -- set in faceAndTalk()

local function ab01smacPT3(e)
	local mobRef = getTimerRef(e)
	if not mobRef then
		return
	end
	local mob = mobRef.mobile
	if not mob then
		return
	end
	---mob.activeAI = true
	if not skipAnim then
		checkPlayAnimation(mob)
	end
	if blinkFix
	and ( not tes3.is3rdPerson() )
	and (not ab01smacPT4timer)
	and checkBlinkFix(mob) then
		return
	end
	-- blink fix disabled or blink not playing
	if logLevel2 then
		mwse.log('%s: ab01smacPT3() playerActivate("%s")', modPrefix, mobRef.id)
	end
	playerActivate(mobRef, true)
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

local function faceAndTalk(mobRef)
	if faceAndTalkBusy then
		if logLevel3 then
			mwse.log('%s faceAndTalk(): faceAndTalkBusy, return', modPrefix)
		end
		faceAndTalkBusy = false
		return
	end
	--[[if skips2 > 0 then
		if logLevel3 then
			mwse.log('%s faceAndTalk(): skips2 = %s, return', modPrefix, skips2)
		end
		skips2 = skips2 - 1
		return
	end]]
	local mob = mobRef.mobile
	if not mob then
		return
	end
	skipAnim = isAnimBlacklisted(mobRef)
	or isDummy(mob)

	local autoFace = config.autoFace
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

	local activationDelay = 0
	local doResetAnim = true

	if doFace then
		--[[ -- nope does not work
		if mob.actionData
		and mob.actionData.walkDestination then
			mob.actionData.walkDestination = mob.position:copy() -- so actor stops walking away
		end
		]]
-- [-180, 180] degree angle between provided actor and the front side of the actor on whom the method was called.
-- 0 degrees is directly in front of the actor, the negative values are on the actor's left side,
-- and positive values on the actor's right.
		local angleTo = mob:getViewToActor(mobilePlayer)
		local absAngleTo = math.abs(angleTo)
		local degreeStep = 9
		if absAngleTo >= config.minFaceAngle then
			radStep = math.rad(degreeStep)
			local animGroup = tes3.animationGroup.turnRight
			if angleTo < 0 then
				radStep = -radStep
				animGroup = tes3.animationGroup.turnLeft
			end
			local iters = math.max(math.floor((absAngleTo - degreeStep) / degreeStep), 1)
			local loops = math.max(math.floor(iters / 9), 1)
			local secStep = 0.05
			local delayStep = 0.131
			if not skipAnim then
				local force = config.idleOnActivate > 1
				checkPlayAnimation(mob, animGroup, loops, force)
				doResetAnim = false
			end
			local refHandle2 = tes3.makeSafeObjectHandle(mobRef)
			-- start facing rotations
			faceAndTalkBusy = true
			---aiWander0(mobRef)
			wanderInPlace(mobRef)
			timer.start({ type = timer_real, duration = secStep, iterations = iters,
				callback = 'ab01smacPT2', data = {handle = refHandle2, i = 0, iterations = iters} })
			---timer.start({ duration = secStep, iterations = iters,
				---callback = 'ab01smacPT2', data = {handle = refHandle2, i = 0, iterations = iters} })
			activationDelay = iters * delayStep

		end
	end

	if doResetAnim then
		checkPlayAnimation(mob)
	end

	if activationDelay > 0 then
		-- delayed player:activate(mobRef)
		---mob.activeAI = false -- try to make them walk away less

		local refHandle3 = tes3.makeSafeObjectHandle(mobRef)
		timer.start({type = timer_real, duration = activationDelay, callback = 'ab01smacPT3', data = {handle = refHandle3} })
		return
	end

	if blinkFix
	and ( not tes3.is3rdPerson() )
	and (not ab01smacPT4timer)
	and checkBlinkFix(mob) then
		return
	end

	if logLevel2 then
		mwse.log('%s: faceAndTalk() playerActivate("%s")', modPrefix, mobRef.id)
	end
	playerActivate(mobRef, true)
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
				if isScenicTravelCreature(target) then
					e.claim = true
					return
				end
				if ( not isCompanion(target) )
				and (obj.id == 'aa_latte_comp01') then
					e.claim = true
					return
				end
				-- starting dialog directly is more robust with scripted NPCs than trying to player:activate()
				if skips == 0 then
					faceAndTalk(target)
					return false
				end
			end
			return
		end
	end

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
			if isScenicTravelCreature(target) then
				playerActivate(target)
				return false
			end
			faceAndTalk(target)
			return false
		end
		return
	end

	table.sort(selectables, byNameAsc)

	local curr, currId, prev, prevId
	local modified = false
	local idCount = 0
	for j = 1, #selectables do
		curr = selectables[j]
		if prev then
			currId = curr.ref.id
			prevId = prev.ref.id
			if curr.name == prev.name then
				if currId == prevId then -- probably not yet cloned containers
					idCount = idCount + 1
					prev.name = string.format('%s %s', prev.name, idCount)
					idCount = idCount + 1
					curr.name = string.format('%s %s', curr.name, idCount)
				else
					prev.name = string.format('%s %s', prev.name, string.sub(prevId, -8))
					curr.name = string.format('%s %s', curr.name, string.sub(currId, -8))
				end
				modified = true
			end
		end
		prev = curr
	end

	if modified then
		table.sort(selectables, byNameAsc)
	end

	local aName

	for k = 1, #selectables do
		curr = selectables[k]
		local aRef = curr.ref
		aName = curr.name
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
							if isScenicTravelCreature(aRef) then
								playerActivate(aRef)
								return false
							end
							-- starting dialog directly is more robust with scripted NPCs than trying to player:activate()
							if logLevel2 then
								mwse.log('%s: activate btn callback "%s"', funcPrefix, aRef.id)
							end
							faceAndTalk(aRef)
							msgBtns = {}
							selectables = {}
							return false
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

	timer.delayOneFrame(
		function ()
			tes3ui.showMessageMenu({id = 'ab01smacMenu', buttons = msgBtns,
				cancels = true, header = 'Activate:'})
		end
	)

	return false -- skip this activate!!!
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
	player = tes3.player
	player1stPerson = tes3.player1stPerson
	mobilePlayer = tes3.mobilePlayer
	skips = 0
	---skips2 = 0
	inputController = tes3.worldController.inputController
	initOnce()
end

local function beforeDestroyMenuDialog()
	skips = 0 -- ensure next actor dialog activate is not skipped
		---skips2 = 0 -- ensure next actor dialog activate is not skipped
	local mob = tes3ui.getServiceActor()
	if mob then
		local ref = mob.reference
		---playGroupIdle(ref)
		aiWander0(ref, true) -- reset actor ai scheduling
	end
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

	local template = mwse.mcm.createTemplate(mcmName)

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

	---local controls = preferences:createCategory{label = mcmName}
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

	controls:createSlider({
		label = 'Min autofacing angle %s',
		description = getDescription([[Default: %s degrees.
Minimun angle from player to trigger autofacing on activate.
Effective only with Auto facing enabled.]], 'minFaceAngle'),
		variable = createConfigVariable('minFaceAngle')
		,min = 0, max = 150
	})

	optionList = {'Off', 'Only Followers', 'All Actors'}
	controls:createDropdown({
		label = 'Play rotation/reset animation on activate:',
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
end
event.register('modConfigReady', modConfigReady)

event.register('initialized',
function ()
	improvedAnimationSupport = tes3.hasCodePatchFeature(tes3.codePatchFeature.improvedAnimationSupport)
	timer.register('ab01smacPT1', ab01smacPT1)
	timer.register('ab01smacPT2', ab01smacPT2)
	timer.register('ab01smacPT3', ab01smacPT3)
	timer.register('ab01smacPT4', ab01smacPT4)
	timer.register('ab01smacPT5', ab01smacPT5)
	event.register('loaded', loaded)
	event.register('uiActivated', uiActivatedMenuDialog, {filter = 'MenuDialog'})
end, {doOnce = true}
)

