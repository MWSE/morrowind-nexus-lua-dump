local defaultConfig = {
bumpity = true, -- play bump animation
bump = true, -- bunp
logLevel = 0
}

local author = 'abot'
local modName = 'Bumpity Bump'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)
local bumpity, bump
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4, logLevel5

local function round(x)
	return math.floor(x + 0.5)
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

local tes3_animationState_dying = tes3.animationState.dying
local tes3_animationState_dead = tes3.animationState.dead

local function isDead(mob)
	local result = false
	if mob.isDead then
		result = true
	else
		local actionData = mob.actionData or mob.actionBeforeCombat
		if actionData then
			local animState = actionData.animationAttackState
			if animState then
				if (animState == tes3_animationState_dying)
				or (animState == tes3_animationState_dead) then
					result = true
				end
			end
		end
	end
	local health = mob.health
	if not health then
		return result
	end
	local health_current = health.current
	if not health_current then
		return result
	end
	-- as we are here fix possible health.current glitches
	if result then
		if health_current > 0 then
			health.current = 0
		end
		return true
	end
	if (health.normalized <= 0.025) -- health ratio <= 0.25%
	and (health_current > 0)
	and (health_current < 3)
	and (health.normalized > 0) then
		health.current = 0 -- kill when nearly dead, could be a glitch
		return true
	end
	return result
end

local tes3_actorType_npc = tes3.actorType.npc
local tes3_actorType_player = tes3.actorType.player
-- set in loaded()
local player, mobilePlayer, player1stPerson

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
	if not mob.canMove then
		return false -- dead, knocked down, knocked out, hit stunned, or paralyzed.
	end

	if mob.actorType == tes3_actorType_npc then
		return true
	end

	if mob.actorType == tes3_actorType_player then
		return false
	end

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

local tes3_aiPackage_wander = tes3.aiPackage.wander

-- 0 = invalid, 1 = follower, 2 = companion
local function validFollower(mob)
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
		if not mobRefObj.isGuard then
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

local function inCombat(mob)
	if mob.inCombat then
		return true
	end
	if mob.combatSession then
		return true
	end
	if mob.actionData
	and mob.actionData.target then
		return true
	end
	return false
end

local function getCompanion(ref)
	return getRefVariable(ref, 'companion')
end

local function hasCompanion(ref)
	if getCompanion(ref) then
		return true
	end
	return false
end

local function back2slash(s)
	return string.gsub(s, [[\]], [[/]])
end

local function multifind2(s1, s2, pattern)
	return string.multifind(s1, pattern, 1, true)
	or string.multifind(s2, pattern, 1, true)
end

local dummies = {'dumm', 'mann', 'target', 'invis'}

local function isDummy(mobRef)
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
		if (not mesh)
		or (mesh == '') then
			return true
		end
	end
	mesh = obj.mesh
	if (not mesh)
	or (mesh == '') then
		return false
	end
	if string.multifind(string.lower(back2slash(mesh)),
			dummies, 1, true) then
		if logLevel5 then
			mwse.log('%s: isDummy("%s")', modPrefix, mobRef.id)
		end
		return true
	end
	return false
end

local tes3_animationGroup = tes3.animationGroup
local tes3_animationGroup_turnRight = tes3_animationGroup.turnRight
local tes3_animationGroup_turnLeft = tes3_animationGroup.turnLeft
local tes3_animationGroup_walkForward = tes3_animationGroup.walkForward
local tes3_animationGroup_idle = tes3_animationGroup.idle

local turnAnimDict = {
[tes3_animationGroup_turnRight] = true,
[tes3_animationGroup_turnLeft] = true,
[tes3_animationGroup_walkForward] = true
}

---local tes3_compilerSource_console = tes3.compilerSource.console
local function playGroupIdle(mob)
-- As a special case, tes3.playAnimation{reference = ..., group = 0}
-- returns control to the AI, as the AI knows that is the actor's neutral idle state.
	if logLevel2 then
		mwse.log('%s: playGroupIdle("%s")', modPrefix, mob.reference)
	end
	tes3.playAnimation({reference = mob, group = tes3_animationGroup_idle})
	---tes3.runLegacyScript({reference = mobRef,
		---command = 'PlayGroup idle',
		---source = tes3_compilerSource_console})
end

local function referenceActivated(e)
	local ref = e.reference
	local mob = ref.mobile
	if not mob then
		return
	end
	if not mob.actorType then
		return
	end
	local animationData = ref.animationData
	if animationData then
		assert(ref.attachments)
		assert(ref.attachments.animation)
		assert(ref.attachments.animation == animationData)
		if animationData.hasOverrideAnimations then
			return
		end
	end
	local animationController = mob.animationController
	if not animationController then
		return
	end
	local animGroupMovement = animationController.animGroupMovement
	if not animGroupMovement then
		return
	end
	if turnAnimDict[animGroupMovement] then
		if mob == mobilePlayer then
			return
		end
		playGroupIdle(mob)
	end
end

local validBehaviorStates = table.invert({
tes3.aiBehaviorState.idle, tes3.aiBehaviorState.walk, tes3.aiBehaviorState.undecided
})

local scenicTravelPrefixDict = table.invert({'ab01ss','ab01bo','ab01go','ab01gu'})

local function isScenicTravelCreature(mobRef)
	local s = string.lower(string.sub(mobRef.object.id, 1, 6)) -- get the id prefix
	if scenicTravelPrefixDict[s] then
		return true
	end
	return false
end

local function checkPlayAnimGroup(mob, animGroup)
	if not bumpity then
		return
	end
	if not animGroup then
		return
	end
	local ref = mob.reference
	local animationData = ref.animationData
	---assert(animationData)
	if animationData.hasOverrideAnimations then
		return
	end
	local actionData = mob.actionData or mob.actionBeforeCombat
	if actionData then
		local aiBehaviorState = actionData.aiBehaviorState
		if not validBehaviorStates[aiBehaviorState] then
			return
		end
	end
	local animationController = mob.animationController
	if animationController then
		local animGroupMovement = animationController.animGroupMovement
		if animGroupMovement
		and turnAnimDict[animGroupMovement] then
			return
		end
	end
	if logLevel4 then
		local s = table.find(tes3_animationGroup, animGroup)
		mwse.log([[%s: checkPlayAnimGroup("%s", %s (%s))
tes3.playAnimation({reference = "%s", group = %s (%s), loopCount = 0})]],
			modPrefix, ref, animGroup, s, ref, animGroup, s
		)
	end
	tes3.playAnimation({reference = mob, group = animGroup, loopCount = 0})
end


local blackList = {'rug','stair','step','ramp','house','isl'}
local blackListDict = table.invert(
{'in_dwrv_corr2_01','in_strong_corr2_02','in_sotha_pre2_02'})

local function isBlacklisted(ref, target)
	local result = false
	local targetObj = target.object

	local lcObjId = string.lower(targetObj.id)
	if blackListDict[lcObjId] then
		result = true
	elseif string.multifind(lcObjId, blackList, 1, true) then
		result = true
	elseif string.multifind(string.lower(targetObj.mesh), blackList, 1, true) then
		result = true
	end
	if result
	and logLevel3 then
		mwse.log([[%s: "%s" isBlacklisted(), skip "%s" collision with it]],
			modPrefix, target.id, ref.id)
	end
	return result
end

local tes3_objectType_door = tes3.objectType.door

local function changeAiDistance(activePackage)
	local d = activePackage.distance
	if d > 4096 then
		d = 512
	end
	activePackage.distance = round( ( math.random(1.5) + 0.5 ) * d )
	---activePackage.isDone = true
	---activePackage.isFinalized = true
end

local function getAnimGroup(ref)
	local animationData = ref.animationData
	if not animationData then
		return
	end
	if animationData.hasOverrideAnimations then
		return
	end
	local result
	local animationGroups = animationData.animationGroups
	if animationGroups[tes3_animationGroup_turnRight + 1] then
		result = tes3_animationGroup_turnRight
	elseif animationGroups[tes3_animationGroup_walkForward + 1] then
		-- use walkForward animation in case turnRight is not available
		result = tes3_animationGroup_walkForward
	end
	-- if logLevel5 then
		-- mwse.log('%s: getAnimGroup("%s") = %s (%s)',
			-- modPrefix, ref, result, table.find(tes3_animationGroup, result)
		-- )
	-- end
	return result
end

local tes3_actionFlag_useEnabled = tes3.actionFlag.useEnabled

--- @param e collisionEventData
local function collision(e)
	if not bump then
		return
	end
	local target = e.target
	if not target then
		return
	end
	local ref = e.reference

	local mob = ref.mobile
	if not mob then
	    assert(mob)
		return
	end
	if not mob.actorType then
		return
	end

	if isScenicTravelCreature(ref) then
		return
	end

	local targetMob = target.mobile
	if targetMob
	and targetMob.actorType
	and isScenicTravelCreature(target) then
		return
	end

	local refIsPlayer = (mob.actorType == tes3_actorType_player)

	if (not mob.canAct)
	or (mob.fatigue.current <= 0)
	or (
		(not refIsPlayer)
		and (
			inCombat(mob)
			or isDead(mob)
			or isDummy(ref)
		)
	) then
		return
	end

	local tempData = ref.tempData
	if tempData then
		if tempData.ab01bmbp then
			tempData.ab01bmbp = nil
-- alternate skip to give the engine more time for collision updates
-- hopefully will eork better with those pesky mesh "oprimizers" mods
-- removing normals from root collision nodes
			return
		end
		tempData.ab01bmbp = 1
	else
		ref.tempData = {}
	end

	local skipRefAnim = false
	local animationData = ref.animationData
	if animationData
	and animationData.hasOverrideAnimations
	and ( not validFollower(mob) ) then
		skipRefAnim = true
	end

	--[[ -- restricted debug only
	if ( not refIsPlayer )
	and (not logLevel3) then
		return
	end]]

	local animGroup
	if not refIsPlayer then
		animGroup = getAnimGroup(ref)
	end

	local skipTargetAnim = false
	if targetMob
	and targetMob.actorType then
		local targetAnimationData = target.animationData
		if targetAnimationData then
			---assert(animationData)
			if (not targetMob.canAct)
			---or targetMob.isFlying
			---or targetMob.isFalling
			or (targetMob.fatigue.current <= 0)
			or (
				inCombat(targetMob)
				and ( not hasCompanion(target) )
			)
			or isDead(targetMob)
			or isDummy(target) then
				return
			end
			if targetAnimationData.hasOverrideAnimations
			and ( not validFollower(targetMob) ) then
				skipTargetAnim = true
			end
		end
	end

	local vecMul = 1.8
	if refIsPlayer then
		vecMul = 1.25
	end
	local vecBackMul = vecMul * 0.75

	local refPos = ref.position
	local targetPos = target.position
	local newPos

	local refSlideVec = ref.rightDirection * vecMul

	local angleToTarget = mob:getViewToPoint(targetPos)
	if angleToTarget > 1 then
		-- target is to the right
		refSlideVec = -refSlideVec -- so we slide left
		if animGroup
		and (animGroup == tes3_animationGroup_turnRight) then
			animGroup = tes3_animationGroup_turnLeft
		end
	elseif angleToTarget > -1 then
		refSlideVec = -ref.forwardDirection * vecMul
	end

	local aiPlanner = mob.aiPlanner
	assert(aiPlanner)
	local activePackage = aiPlanner:getActivePackage()
	if activePackage then
		if activePackage.isMoving
		and (activePackage.type == tes3_aiPackage_wander) then
			changeAiDistance(activePackage)
			---activePackage.isDone = true
			---activePackage.isFinalized = true
			---return
		end
	end

	local skipRefMove = false
	if refIsPlayer then
		skipRefMove = true
	elseif isBlacklisted(ref, target) then
		skipRefMove = true
	end

	if targetMob
	and targetMob.actorType then
		if not (targetMob.actorType == tes3_actorType_player) then
			if not skipTargetAnim then
				local targetAnimGroup = getAnimGroup(target)
				checkPlayAnimGroup(targetMob, targetAnimGroup)
			end
			local refBackVec = ref.forwardDirection * vecBackMul
			if math.abs(angleToTarget) < 90 then
				newPos = targetPos - refSlideVec + refBackVec
			else
				newPos = targetPos - refSlideVec - refBackVec
			end

			if logLevel4
			or (
				logLevel2
				and refIsPlayer
			) then
				mwse.log([[%s: collision() to mob
ref = %s, target = %s, ref.forwardDirection = %s,
target.forwardDirection = %s, refSlideVec = %s,
targetPos before = %s, targetPos after = %s]],
				modPrefix, ref, target, ref.forwardDirection,
				target.forwardDirection, refSlideVec,
				targetPos, newPos)
			end
			targetPos.x, targetPos.y, targetPos.z = newPos.x, newPos.y, newPos.z
		end
	else -- e.g. a colliding static
		if not skipRefMove then
			local refBackVec = -ref.forwardDirection
			local maxDist = 1024
			local boundSize2D = mob.boundSize2D
			if boundSize2D then
				local size = math.max(boundSize2D.y, boundSize2D.x)
				---maxDist = round(size * 0.75)
				maxDist = size * ref.scale
			end
			local rayParams = {
				position = tes3vector3.new(refPos.x, refPos.y, refPos.z + 32),
				direction = ref.forwardDirection,
				maxDistance = maxDist,
				root = tes3.game.worldRoot,
				returnNormal = true,
				ignore = {ref, player, player1stPerson}
			}
			local rayHit = tes3.rayTest(rayParams)
			if (not rayHit)
			or ( not (rayHit.reference == target) ) then
				rayParams.direction = ref.rightDirection
				rayHit = tes3.rayTest(rayParams)
				if (not rayHit)
				or ( not (rayHit.reference == target) ) then
					rayParams.direction = -ref.rightDirection
					rayHit = tes3.rayTest(rayParams)
					if (not rayHit)
					or ( not (rayHit.reference == target) ) then
						rayParams.direction = -ref.forwardDirection
						rayHit = tes3.rayTest(rayParams)
					end
				end
			end
			if not rayHit then
				return
			end
			local intersection, normal
			if rayHit.reference == target then
				intersection = rayHit.intersection
			end
			if not intersection then
				return
			end

			local kz = 16

			normal = rayHit.normal
			if normal.z > 0.5 then
				---refPos.z = refPos.z + kz
				if logLevel5 then
					mwse.log([[%s: collision("%s", "%s"), not steep, skip]],
						modPrefix, ref.id, target.id)
				end
				return -- not steep, skip
			end

			if activePackage
			and activePackage.isMoving then

				-- rotate normal XY by -/+ 90 degrees
				if math.random(100) >= 50 then
					refBackVec = tes3vector3.new(-normal.y, normal.x, 0)
				else
					refBackVec = tes3vector3.new(normal.y, -normal.x, 0)
				end

				local dz = kz
				local bb = target.baseObject.boundingBox
				if bb then
					local mx = bb.max
					local mn = bb.min
					local z = math.max(mx.z - mn.z, mx.x - mn.x)
					z = math.max(z, mx.y - mn.y)
					if z < 72 then
						dz = dz + z
					end
				end
				local mobHeight = mob.height
				local mobHeight2 = mobHeight + kz
				local rayParams2 = {
					position = tes3vector3.new(intersection.x,
						intersection.y, refPos.z + mobHeight),
					direction = player.upDirection,
					maxDistance = math.max(dz, mobHeight2),
					root = tes3.game.worldRoot,
					returnNormal = true,
					ignore = {ref, player, player1stPerson}
				}
				local dzMax = mobHeight2
				local rayHit2 = tes3.rayTest(rayParams2)
				if rayHit2 then
					local intersection2 = rayHit2.intersection
					if intersection2 then
						dzMax = intersection2.z - refPos.z - mobHeight + kz
					end
				end
				dz = math.min(dz, dzMax)
				local jump = dz < mobHeight2
				if not jump then
					refBackVec = refBackVec + tes3vector3.new(normal.x, normal.y, 0)
				end

				refBackVec:normalize()

				refBackVec = refBackVec * vecBackMul
				if logLevel1 then
					mwse.log([[%s: collision() to object
ref = %s, target = %s, ref.forwardDirection = %s, normal = %s,
target.forwardDirection = %s, refBackVec = %s,
targetPos before = %s, intersection = %s]], modPrefix,
						ref, target, ref.forwardDirection, normal,
						target.forwardDirection, refBackVec,
						targetPos, intersection)
				end
				if not skipRefAnim then
					checkPlayAnimGroup(mob, animGroup)
				end
				newPos = refPos + refBackVec
				refPos.x, refPos.y, refPos.z = newPos.x, newPos.y, newPos.z

				if (target.object.objectType == tes3_objectType_door)
				and (not target.destination) then
					if tes3.getLocked({reference = target}) then
						changeAiDistance(activePackage)
						---activePackage.isDone = true
						---activePackage.isFinalized = true
					elseif target:testActionFlag(tes3_actionFlag_useEnabled) then
						tes3.setAIActivate({reference = mob, target = target})
					end
				end
				return
			end -- if activePackage
		end -- if not skipRefMove
	end -- if targetMob

	if skipRefMove then
		return
	end
	newPos = targetPos + refSlideVec - ( ref.forwardDirection * vecBackMul )
	local dist = newPos:distance(targetPos)
	if dist > 3 then
		if logLevel4 then
			mwse.log([[%s: collision("%s", "%s") 3 dist = %s,
targetPos before = %s, targetPos after = %s, ]],
				modPrefix, ref.id, target.id, dist, targetPos, newPos)
		end
		if not skipRefAnim then
			checkPlayAnimGroup(mob, animGroup)
		end
		refPos.x, refPos.y, refPos.z = newPos.x, newPos.y, newPos.z
	end
end

local collisionRegistered = false
local function setCollisionEvent()
	if collisionRegistered then
		if not bump then
			collisionRegistered = false
			event.unregister('collision', collision)
		end
	elseif bump then
		collisionRegistered = true
		event.register('collision', collision)
	end
end

local function updateFromConfig()
	bumpity = config.bumpity
	bump = config.bump
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
	logLevel5 = logLevel >= 5
end
updateFromConfig()

local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	player1stPerson = tes3.player1stPerson
	setCollisionEvent()
end

local function onClose()
	updateFromConfig()
	player = tes3.player
	if player then
		mobilePlayer = tes3.mobilePlayer
		player1stPerson = tes3.player1stPerson
		setCollisionEvent()
	end
	mwse.saveConfig(configName, config, {indent = true})
end

local function modConfigReady()

	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})

	local sideBarPage = template:createSideBarPage({
		label = modName,
		showHeader = false,
		description = [[Makes actors shift it.]],
		showReset = true,
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.1
			self.elements.sideToSideBlock.children[2].widthProportional = 0.9
		end
	})

	local category = sideBarPage:createCategory({})

	local optionList = {'Off', 'Low', 'Medium', 'High', 'Very High', 'Max'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s", i - 1,
				optionList[i]), value = i - 1}
		end
		return options
	end

	--[[local function getDropDownDescription(variableId)
		local i = defaultConfig[variableId]
		return string.format('Default: %s. %s', i, optionList[i+1])
	end]]

	category:createYesNoButton({
		label = 'Bump',
		description = [[Actors bump away toggle. Basically enables/disables the mod effects.]],
		configKey = 'bump'
	})

	category:createYesNoButton({
		label = 'Bumpity',
		description = [[Visible Bump walk animation toggle. Effective only when "Bump" option is enabled.]],
		configKey = 'bumpity'
	})

	category:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		---showDefaultSetting = false,
		description = [[Enables various levels of debug information written to the Morrowind\MWSE.log file.

Should be kept to 0 during normal gameplay, but if you encounter a problem with  the mod, you could try and save the game right before the problem happens, crank the Log level up, exit the game and reload.

When the problem happens again, exit the game, and send the Morrowind\MWSE.log file with your error report to mod author.]],
		configKey = 'logLevel'
	})

	mwse.mcm.register(template)

	event.register('loaded', loaded)
	event.register('referenceActivated', referenceActivated)
end
event.register('modConfigReady', modConfigReady)

