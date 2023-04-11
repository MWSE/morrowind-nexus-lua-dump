--[[
allow to choose who to activate between 8 nearby actors
]]

local defaultConfig = {
actorsMenu = true, -- actorsMenu toggle
maxDistance = 72, -- Max distance between actors to classify them as colliding each other
maxSelectable = 8, -- Max number of selectable actors
allowDead = true, -- allow selecting dead actors
allowNPC = true, -- allow selecting NPCs
allowCreature = true, -- allow selecting creatures
allowContainer = false, -- allow selecting containers
allowOrganic = false, -- allow selecting organic containers
allowDoor = true, -- allow selecting 1 door
autoFace = 1, -- 0 = Off, 1 = NPCs, 2 = NPCs & Creatures
minFaceAngle = 15, -- min. degree angle from player to autoface
idleOnActivete = 2, -- 0 = Off, 1 = Followers, 2 = All actors
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium, 3 = High
}

local author = 'abot'
local modName = 'Smart Activate'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

local maxSelectable = config.maxSelectable
local allowDead = config.allowDead
local allowNPC = config.allowNPC
local allowCreature = config.allowCreature
local allowContainer = config.allowContainer
local allowOrganic = config.allowOrganic
local allowDoor = config.allowDoor
local logLevel = config.logLevel
local logLevel1 = logLevel >= 1
local logLevel2 = logLevel >= 2
local logLevel3 = logLevel >= 3
local logLevel4 = logLevel >= 4
local logLevel5 = logLevel >= 5

local AS_DEAD = tes3.animationState.dead
local AS_DYING = tes3.animationState.dying

-- set in loaded()
local player, player1stPerson, mobilePlayer

local function isMobileDead(mobile)
	local health = mobile.health
	if health then
		if health.current then
			if logLevel3 then
				mwse.log('%s: isMobileDead("%s") health.current = %s', modPrefix, mobile.reference.id, health.current)
			end
			if health.current <= 0 then
				return true
			end
		end
	end
	local actionData = mobile.actionData
	if not actionData then
		return false -- it may happen
	end
	local animState = actionData.animationAttackState
	if not animState then
		return false
	end
	if (animState == AS_DEAD)
	or (animState == AS_DYING) then
		return true
	end
	return mobile.isDead
end


-- initialized in loaded()
local inputController

local tes3_scanCode_lAlt = tes3.scanCode.lAlt
local tes3_scanCode_lShift = tes3.scanCode.lShift


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

local selectableTypes = {tes3_objectType_npc, tes3_objectType_creature, tes3_objectType_container, tes3_objectType_door}

---local readableObjectTypes = table.invert(tes3.objectType)

local selectables = {} -- e.g. {ref = targetRef, name = targetRef.object.name, dist = 0}}

local function back2slash(s)
	return string.gsub(s, [[\]], [[/]])
end

local dummies = {'dumm','mann','target', 'invis'}

local function isDummy(mob)
	local mobRef = mob.reference
	local obj = mobRef.object
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

local function getSelectablesInProximity(targetRef, range)
	local aDist, aName, mesh, mob, obj, objType, ok
	local i = 0
	local targetRefPos = targetRef.position
	local funcPrefix = string.format('%s: getSelectablesInProximity("%s", %s)', modPrefix, targetRef.id, range)
	local t = {}
	local cell = targetRef.cell
	local mobCount = 0
	local contCount = 0
	local doorCount = 0

	local function processCell()
		for aRef in cell:iterateReferences(selectableTypes) do
			if not (
				(aRef == player)
				or (aRef == player1stPerson)
			) then
				aDist = targetRefPos:distance(aRef.position)
				if aDist <= range then
					if logLevel5 then
						mwse.log('%s: aRef = "%s" aDist = %s, range = %s', funcPrefix, aRef.id, aDist, range)
					end
					if (not aRef.disabled)
					and (not aRef.deleted) then
						obj = aRef.object
						mesh = obj.mesh
						if mesh
						and (not (mesh == '')) then
							if logLevel4 then
								mwse.log('%s: mesh = "%s"', funcPrefix, mesh)
							end
							objType = obj.objectType
							ok = false
							if ( (objType == tes3_objectType_npc)
								and allowNPC )
							or ( (objType == tes3_objectType_creature)
								and allowCreature) then
								mob = aRef.mobile
								if mob then
									if not isDummy(mob) then -- skip mannequins
										if allowDead then
											ok = true
										elseif not isMobileDead(mob) then
											ok = true
										end
										if ok then
											mobCount = mobCount + 1
										end
									end
								end
								if logLevel3 then
									mwse.log('%s: mob = %s, ok = %s', funcPrefix, mob.reference.id, ok)
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
							if ok then
								aName = obj.name
								if logLevel3 then
									mwse.log('aName = "%s"', aName)
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
						end -- if mesh and ...
					end -- if (not aRef.disabled) ...
				end -- if (aDist <= range)
			end -- if not (	(aRef == player) ...
		end -- for aRef
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
		table.sort(t, byDistAsc) -- sort by lesser distance
		local v
		local t2 = {}
		if count > maxSelectable then -- get only first maxSelectable items
			for k = 1, maxSelectable do
				v = t[k]
				t2[k] = v
			end
			t = t2
			count = #t
		end
		if doorCount >= 2 then -- max 1 door
			ok = true
			local j = 0
			t2 = {}
			for k = 1, count do
				v = t[k]
				if v.ref.object.objectType == tes3_objectType_door then
					if ok then
						ok = false
						j = j + 1
						t2[j] = v -- add first door, once
					end
				else
					j = j + 1
					t2[j] = v -- add non-door objects
				end
			end
			t = t2
			count = #t
		end
		if logLevel3  then
			mwse.log('%s: sorted by distance', funcPrefix)
			for k = 1, count do
				v = t[k]
				if logLevel3  then
					mwse.log('%s: t[%s] = {ref = "%s", name = "%s", dist = %s}',
						funcPrefix, k, v.ref.id, v.name, v.dist)
				end
			end
		end
	end
	return t
end

local function getTimerRef(e)
	local timer = e.timer
	---assert(timer)
    local data = timer.data
	---assert(data)
	local handle = data.handle
	if not assert(handle) then
		return
	end
	if not assert(handle:valid()) then
		return
	end
	local ref = handle:getObject()
	return ref
end

local function ab01smacPT1(e)
	local ref = getTimerRef(e)
	if not assert(ref) then
		return
	end
	if logLevel2 then
		mwse.log('%s: delayedPlayerActivate() player:activate("%s")', modPrefix, ref.id)
	end
	player:activate(ref)
end

local function delayedPlayerActivate(targetRef, delaySec)
	timer.start({ duration = delaySec, type = timer.real, callback = 'ab01smacPT1',
		data = {handle = tes3.makeSafeObjectHandle(targetRef)} })
end

local skips = 0 -- reset in loaded()
local activateBtns = {}
local lastButtonIndex = 0

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
---local tes3_actorType_creature = tes3.actorType.creature
local tes3_actorType_npc = tes3.actorType.npc

local function getCompanion(ref)
	local result
	local context = ref.context
	if context then
		result = context.companion
		if not result then
			result = context.Companion
		end
	end
	return result
end

local function isCompanion(mobRef)
	local companion = getCompanion(mobRef)
	if companion
	and (companion == 1) then
		return true
	end
	return false
end

local tes3_animationState_dead = tes3.animationState.dead
local tes3_animationState_dying = tes3.animationState.dying

local function isDead(mobile)
	if mobile.isDead then
		return true
	end
	local health = mobile.health
	if health then
		if health.current then
			if health.current < 3 then
				if health.normalized <= 0.025 then
					if health.normalized > 0 then
						health.current = 0 -- kill when nearly dead, could be a glitch
					end
				end
				if health.current <= 0 then
					return true
				end
			end
		end
	end
	local actionData = mobile.actionData
	if not actionData then -- it may happen
		return false
	end
	local animState = actionData.animationAttackState
	if not animState then
		return false
	end
	if (animState == tes3_animationState_dead)
	or (animState == tes3_animationState_dying) then
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
	local script = mob.object.script
	if script then
		local lcId2 = string.lower(script.id)
		if string.startswith(lcId2, 'ab01') then -- ab01 prefix, probably some abot's creature having AIEscort package, skip
			if logLevel3 then
				mwse.log("%s: %s having ab01 prefix, probably some abot's creature with AIEscort package, skip", modPrefix, mobRef.id)
			end
			return false
		end
	end
	return true
end

local function getOneTimeMove(ref)
	local result
	local context = ref.context
	if context then
		result = context.oneTimeMove
		if not result then
			result = context.OneTimeMove
			if not result then
				result = context.onetimemove
			end
		end
	end
	return result
end

-- 0 = invalid, 1 = follower, 2 = companion
local function validFollower(mob, anyFollower)
	if (not mob.canMove) -- dead, knocked down, knocked out, hit stunned, or paralyzed.
	or (not isValidMobile(mob)) then
		return 0
	end
	local mobRef = mob.reference
	local aCompanion = isCompanion(mobRef)
	local mobRefObj = mobRef.object
	local ai = tes3.getCurrentAIPackageId(mob)
	if (ai == tes3_aiPackage_follow)
	or (ai == tes3_aiPackage_escort) then
		if aCompanion then
			return 2
		end
		if anyFollower then
			if not mobRefObj.isGuard then
				return 1
			end
		end
		return 0
	elseif ai == tes3_aiPackage_wander then
		-- special case for wandering companions
		if aCompanion then
			local oneTimeMove = getOneTimeMove(mobRef)
			if oneTimeMove then
				if not (oneTimeMove == 0) then
-- assuming a companion scripted to do move-away using temporary aiwander
					return 2
				end
			end
		end
	end

	return 0
end

local tes3_animationStartFlag_normal = tes3.animationStartFlag.normal

local function checkPlayAnimation(mob, animGroup, loops, force)
	local mobRef = mob.reference
	if isAnimBlacklisted(mobRef) then
		return
	end
	local idleOnActivete = config.idleOnActivete
	local idleOk
	if idleOnActivete == 1 then
		idleOk = validFollower(mob, true) > 0 -- 0 = invalid, 1 = follower, 2 = companion
	elseif idleOnActivete == 2 then
		idleOk = true
	elseif force then
		idleOk = true
	else
		idleOk = false
	end
	if animGroup then
		if loops then
			local animOk = true
			local animationController = mob.animationController
			if animationController then -- could be nil
				if animationController.animationData.hasOverrideAnimations then
					animOk = false -- skip e.g. a drummer
				end
			end
			if animOk then
				tes3.playAnimation({reference = mobRef, group = animGroup,
					loopCount = loops, startFlag = tes3_animationStartFlag_normal})
			end
		end
	end
	if idleOk then
		tes3.playAnimation({reference = mobRef, group = 0, startFlag = tes3_animationStartFlag_normal})
	end
end

local function resetAnimation(mob)
	checkPlayAnimation(mob)
end

local radStep

local function ab01smacPT2(e)
	local ref = getTimerRef(e)
	if not assert(ref) then
		return
	end
	-- note: the f* mobile.facing is read only!!!
	ref.facing = ref.facing + radStep
end

local skipAnim

local function ab01smacPT3(e)
	local ref = getTimerRef(e)
	if not assert(ref) then
		return
	end
	local mob = ref.mobile
	if not mob then
		return
	end
	if not skipAnim then
		resetAnimation(mob)
	end
	skips = 2
	if logLevel2 then
		mwse.log('%s: faceAndTalk() player:activate("%s")', modPrefix, ref.id)
	end
	player:activate(ref)
end

local function faceAndTalk(mobRef)
	local mob = mobRef.mobile
	skipAnim = isAnimBlacklisted(mobRef)
	local autoFace = config.autoFace
	local ok = true
	if (autoFace == 0)
	or skipAnim
	or (
		(mob.actorType == tes3.actorType.creature)
	and (autoFace < 2)
	) then
		ok = false
	end
	if ok then
		local angleTo = mob:getViewToActor(mobilePlayer)
		local absAngleTo = math.abs(angleTo)
		local degreeStep = 10
		if absAngleTo >= config.minFaceAngle then
			radStep = math.rad(degreeStep)
			local animGroup = tes3.animationGroup.turnRight
			if angleTo < 0 then
				radStep = -radStep
				animGroup = tes3.animationGroup.turnLeft
			end
			local iter = math.max(math.floor((absAngleTo - degreeStep) / degreeStep), 1)
			local loops = math.max(math.floor(iter / 6), 0)
			local secStep = 0.05
			local delayStep = 0.12
			if not skipAnim then
				checkPlayAnimation(mob, animGroup, loops, true)
			end
			local refHandle = tes3.makeSafeObjectHandle(mobRef)
			timer.start({ duration = secStep, iterations = iter, callback = 'ab01smacPT2',
				data = {handle = refHandle} })

			timer.start({duration = iter * delayStep, callback = 'ab01smacPT3',
				data = {handle = refHandle}
			})
			return
		end
	end

	if not skipAnim then
		resetAnimation(mob)
	end
	skips = 2
	if logLevel2 then
		mwse.log('%s: faceAndTalk() player:activate("%s")', modPrefix, mobRef.id)
	end
	player:activate(mobRef)
	---mob:startDialogue()
end

local function canStartDialogueWith(mob)
	local result = mob
	and mob.canMove
	and (not isMobileDead(mob))
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

local lastActivatedRef -- reset in loaded()

local function activate(e)
	local funcPrefix = string.format("%s activate(e)", modPrefix)
	local activator = e.activator
	if not (activator == player) then
		if logLevel3 then
			mwse.log("\n%s: e.activator = %s, skip", funcPrefix, activator)
		end
		return
	end

	if skips > 0 then
		if logLevel2 then
			mwse.log('%s: skips = %s, return', funcPrefix, skips)
		end
		skips = skips - 1
		return
	end

	local target = e.target
	if logLevel2 then
		mwse.log('%s: e.target = "%s"', funcPrefix, target)
	end

	if target == lastActivatedRef then
		if logLevel2 then
			mwse.log('%s: e.target == lastActivatedRef == "%s", skip', funcPrefix, target)
		end
		lastActivatedRef = nil
		return
	end

	local obj = target.object
	local objType = obj.objectType
	if not validTypes[objType] then
		if logLevel2 then
			mwse.log("%s: objType = %s, skip", funcPrefix, mwse.longToString(objType))
		end
		return
	end

	if inputController:isKeyDown(tes3_scanCode_lAlt)
	or inputController:isKeyDown(tes3_scanCode_lShift) then
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
		if not config.actorsMenu then
			if canStartDialogueWith(mobile) then
				-- starting dialog directly is more robust with scripted NPCs than trying to player:activate()
				if logLevel2 then
					mwse.log('%s: faceAndTalk("%s")', funcPrefix, target.id)
				end
				faceAndTalk(target)
				return false
			end
			return
		end
	end

	selectables = getSelectablesInProximity(target, rng)
	if #selectables < 2 then
		if logLevel2 then
			mwse.log("%s: #selectables < 2, skip", funcPrefix)
		end
		if mobile then
			if mobile.actorType then
				if canStartDialogueWith(mobile) then
					faceAndTalk(target)
					return false
				end
			end
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

	activateBtns = {}
	local aName
	local j = 0
	for k = 1, #selectables do
		curr = selectables[k]
		aName = curr.name
		if aName -- better safe than sorry
		 and (j < 8) then -- (9 messageBox buttons max, minus one for Cancel)
			j = j + 1
			if logLevel3 then
				mwse.log('%s: sorted selectables[%s] = {ref = "%s", name = "%s"}\n%s: table.insert(activateBtns, "%s"',
					funcPrefix, j, curr.ref.id, aName, modPrefix, aName)
			end
			table.insert(activateBtns, aName)
		end
	end

	lastButtonIndex = j + 1
	if lastButtonIndex < 2 then -- should not be needed, but again better safe than sorry
		return
	end
	table.insert(activateBtns, 'Cancel')

	-- last better safe than sorry, I promise LOL, but something wrong with messageBox entries could freeze the game
	local size = table.size(activateBtns)
	if size < lastButtonIndex then
		if logLevel1 then
			mwse.log("%s: table.size(activateBtns) = %s\nlastButtonIndex = %s", funcPrefix, size, lastButtonIndex)
		end
		return
	end

	if logLevel2 then
		local btnName
		for k = 1, #activateBtns do
			btnName = activateBtns[k]
			mwse.log("%s: activateBtns[%s] = %s", funcPrefix, k, btnName)
		end
	end

	timer.delayOneFrame(function ()
		tes3.messageBox({
			message = 'Activate:', buttons = activateBtns,
			callback = function (ev)
				---assert(ev.button >= 0)
				local index = ev.button + 1
				if logLevel2 then
					mwse.log("%s: messageBox index = %s, lastButtonIndex = %s", funcPrefix, index, lastButtonIndex)
				end
				if index < lastButtonIndex then
					local sel = selectables[index]
					---assert(sel)
					local activateRef = sel.ref
					local mobi = activateRef.mobile

					if canStartDialogueWith(mobi) then
						-- starting dialog directly is more robust with scripted NPCs than trying to player:activate()
						if logLevel2 then
							mwse.log('%s: faceAndTalk("%s")', funcPrefix, activateRef.id)
						end
						faceAndTalk(activateRef)
					else
						skips = 1
						if activateRef.objectType == tes3_objectType_container then
							local mesh = activateRef.mesh
							if mesh then
								local lcMesh = string.lower(mesh)
								lcMesh = back2slash(lcMesh)
								if string.find(lcMesh, 'ac/anim_', 1, true) then
									if logLevel2 then
										mwse.log("%s: animated container, don't skip", funcPrefix)
									end
									skips = 2
								end
							end
						end
						if logLevel2 then
							mwse.log('%s: delayedPlayerActivate("%s", 0.15)', funcPrefix, activateRef.id)
						end
						delayedPlayerActivate(activateRef, 0.15)
					end
				end
				activateBtns = {}
				selectables = {}
			end
		})
	end)
	return false -- skip this activate
end


local function loaded()
	player = tes3.player
	player1stPerson = tes3.player1stPerson
	mobilePlayer = tes3.mobilePlayer
	lastActivatedRef = nil
	skips = 0
	inputController = tes3.worldController.inputController
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
		maxSelectable = config.maxSelectable
		allowDead = config.allowDead
		allowNPC = config.allowNPC
		allowCreature = config.allowCreature
		allowContainer = config.allowContainer
		allowOrganic = config.allowOrganic
		allowDoor = config.allowDoor
		logLevel = config.logLevel
		logLevel1 = logLevel >= 1
		logLevel2 = logLevel >= 2
		logLevel3 = logLevel >= 3
		logLevel4 = logLevel >= 4
		logLevel5 = logLevel >= 5
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
Enable selection menu to choose who to activate between up to 8 nearby actors/containers/doors.
Very useful in crowded places.
Note: you can also skip the selection menu by pressing Alt or Shift keys while activating.
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
Max number of selectable things.]], 'maxSelectable'),
		variable = createConfigVariable('maxSelectable')
		,min = 2, max = 8
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
Selected actors turn around and face player on activate.]], 'autoFace'),
		variable = createConfigVariable('autoFace'),
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
		label = 'Play idle/reset animation on activate:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','idleOnActivete'),
		variable = createConfigVariable('idleOnActivete'),
	})

	optionList = {'Off', 'Low', 'Medium', 'High', 'Higher', 'Max'}
	controls:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','logLevel'),
		variable = createConfigVariable('logLevel'),
	})

	event.register('loaded', loaded)
	event.register('activate', activate, {priority = 100010}) -- higher priority than smart companions

	timer.register('ab01smacPT1', ab01smacPT1)
	timer.register('ab01smacPT2', ab01smacPT2)
	timer.register('ab01smacPT3', ab01smacPT3)

	mwse.mcm.register(template)
	---logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)
