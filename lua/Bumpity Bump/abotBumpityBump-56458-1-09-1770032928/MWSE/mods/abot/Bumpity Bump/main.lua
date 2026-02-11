local defaultConfig = {
bumpity = true, -- play bump animation
bump = true, -- bump
processCreatures = 1, -- 0 = Off, 1 = Followers, 1 = Companions, 3 = All
skipCreatures = 2, -- 0 = Off, 1 = swimming, 2 = swimming and ab01 prefixed
logLevel = 0
}

local author = 'abot'
local modName = 'Bumpity Bump'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = configName:gsub(' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)
local bumpity, bump, processCreatures, skipCreatures
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4, logLevel5

local function updateFromConfig()
	bumpity = config.bumpity
	bump = config.bump
	processCreatures = config.processCreatures
	skipCreatures = config.skipCreatures
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
	logLevel5 = logLevel >= 5
end
updateFromConfig()

local math_abs, math_floor, math_max, math_min, math_random =
math.abs, math.floor, math.max, math.min, math.random

---@param x number
---@return integer
local function round(x)
	return math_floor(x + 0.5)
end

---@param ref tes3reference
---@param variableId string
---@param newValue number?
---@return number?
local function getSetRefVariable(ref, variableId, newValue)
	local script = ref.object.script
	if not script then
		return
	end
	local script_context = script['context']
	if not script_context then
		return
	end
	local funcPrefix
	if logLevel1 then
		if newValue then
			funcPrefix = ('%s: getSetRefVariable("%s", "%s", %s)'):format(modPrefix, ref.id, variableId, newValue)
		else
			funcPrefix = ('%s: getSetRefVariable("%s", "%s")'):format(modPrefix, ref.id, variableId)
		end
	end
	if ref.attachments then
		if ref.attachments.variables then
			if not ref.attachments.variables.script then
				if logLevel5 then
					mwse.log('%s: "%s".attachments.variables.script = nil', funcPrefix, ref.id)
				end
				return
			end
		else
			if logLevel5 then
				mwse.log('%s: "%s".attachments.variables = nil', funcPrefix, ref.id)
			end
			return
		end
	else
		--[[if logLevel4 then
			mwse.log('%s: "%s".attachments = nil', funcPrefix, ref.id)
		end]]
		return
	end

	if logLevel5 then
		mwse.log(funcPrefix)
	end
-- WARNING!!!
-- ref.object.script.context.variable is only safe to use to detect if variable exists,
-- not to get/set its value!!!
	local success, value = pcall(
		function ()
			return script_context[variableId]
		end
	)
	if not (success and value) then
		if logLevel5 then
			mwse.log('%s: "%s" script_context["%s"] = %s, success = %s',
				funcPrefix, ref.id, variableId, value, success)
		end
		return
	end
	local ref_context = ref['context']
	if not ref_context then
		return value
	end
	if logLevel5 then
		mwse.log('%s: ref_context = %s', funcPrefix, ref_context)
	end
	-- need more safety
	local val = ref_context[variableId]
	if not val then
		return value
	end
	value = val
	if logLevel4 then
		mwse.log('%s: ref_context["%s"] was %s)', funcPrefix, variableId, value)
	end
	if not newValue then
		return value
	end
	local succ2, val2 = pcall(
		function ()
			ref_context[variableId] = newValue
			return ref_context[variableId]
		end
	)
	if not (succ2 and val2) then
		return value
	end
	if logLevel4 then
		mwse.log('%s: context["%s"] is %s)', funcPrefix, variableId, val2)
	end
	return val2
end

---@param ref tes3reference
---@param variableId string
---@return number?
local function getRefVariable(ref, variableId)
	return getSetRefVariable(ref, variableId)
end


-- usage: when you only need to know if the local variable exists
---@param ref tes3reference
---@param variableId string
---@return boolean
local function hasRefVariable(ref, variableId)
	local script = ref.object.script
	if not script then
		return false
	end
	local funcPrefix
	if logLevel1 then
		funcPrefix = ('%s: hasRefVariable("%s", "%s")'):format(modPrefix, ref.id, variableId)
	end
	if logLevel4 then
		mwse.log(funcPrefix)
	end
-- NOTE
-- ref.object.script.context.variable is only safe to use to detect if variable exists,
-- not to get/set its value!!!
-- to get/set the local variable value you need ref.context, but if it is not yet initialized
-- it will get/set 0 as value
	local script_context = script['context']
	if not script_context then
		return false
	end
	if logLevel4 then
		mwse.log('%s: script_context = %s', funcPrefix, script_context)
	end
	---local context = ref['context'] -- not reliable here
	local success, value = pcall(
		function ()
			return script_context[variableId]
		end
	)
	if not (success and value) then
		return false
	end
	if logLevel3 then
		mwse.log('%s: "%s", script_context["%s"] = %s', funcPrefix, ref.id, variableId, value)
	end
	return true
end

---@param s string
local function back2slash(s)
	return s:gsub([[\]], [[/]])
end

---@param s1 string
---@param s2 string
local function multifind2(s1, s2, pattern)
	return s1:multifind(pattern, 1, true)
	or s2:multifind(pattern, 1, true)
end

local dummies = {'_dumm','dumm_','_mann','mann_','_target','target_','invis'}

---@param mobRef tes3reference
---@return boolean
local function isDummy(mobRef)
	local obj = mobRef.baseObject
	if multifind2(obj.id:lower(), obj.name:lower(), dummies) then
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
		or (mesh:len() == 0) then
			return true
		end
	end
	mesh = obj.mesh
	if (not mesh)
	or (mesh:len() == 0) then
		return false
	end
	if back2slash(mesh):lower():multifind(
			dummies, 1, true) then
		if logLevel5 then
			mwse.log('%s: isDummy("%s")', modPrefix, mobRef.id)
		end
		return true
	end
	return false
end

---@param mobRef tes3reference
---@return boolean
local function hasCompanion(mobRef)
	if hasRefVariable(mobRef, 'companion')
	and ( not isDummy(mobRef) ) then
		return true
	end
	return false
end

---@param mobRef tes3reference
---@return boolean
local function isCompanion(mobRef)
	local companion = getRefVariable(mobRef, 'companion')
	if companion
	and (companion == 1)
	and ( not isDummy(mobRef) ) then
		return true
	end
	return false
end

local tes3_aiPackage_follow = tes3.aiPackage.follow
local tes3_aiPackage_escort = tes3.aiPackage.escort
local tes3_aiPackage_wander = tes3.aiPackage.wander
local tes3_aiPackage_activate = tes3.aiPackage.activate

---@param mobRef tes3reference
---@return boolean
local function hasOneTimeMove(mobRef)
-- special case for wandering destinations
-- e.g. companion scripted to do move-away using temporary aiwander
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

--[[
local tes3_animationState_dying = tes3.animationState.dying
local tes3_animationState_dead = tes3.animationState.dead

---@param mob tes3mobileActor
---@return boolean
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
	if (health.normalized <= 0.025) -- health ratio <= 2.5%
	and (health_current > 0)
	and (health_current < 3)
	and (health.normalized > 0) then
		health.current = 0 -- kill when nearly dead, could be a glitch
		return true
	end
	return result
end
]]

-- set in loaded()
local player ---@type tes3reference?
local player1stPerson ---@type tes3reference?
local mobilePlayer ---@type tes3mobilePlayer?

-- set in modConfigReady()
local tes3_game_worldRoot ---@type niNode?

local tes3_actorType_player = tes3.actorType.player
local tes3_actorType_creature = tes3.actorType.creature
---local tes3_actorType_npc = tes3.actorType.npc

--[[
---@param mob tes3mobileActor
---@return boolean
local function isDisabledOrDeleted(mob)
	local mobRef = mob.reference
	if mobRef.disabled then
		return true
	end
	if mobRef.deleted then
		return true
	end
	return false
end
]]

--[[
---@param mob tes3mobileActor
---@return boolean
local function cannotMove(mob)
	if not mob.canMove then
		return true -- dead, knocked down, knocked out, hit stunned, or paralyzed.
	end
	if isDead(mob) then
		return true
	end
	return false
end
]]

--[[
---@param mob tes3mobileActor
---@return boolean
local function isValidMobile(mob)
	local mobRef = mob.reference
	if mobRef.disabled then
		return false
	end
	if mobRef.deleted then
		return false
	end
	if not mob.canMove then
		return false -- dead, knocked down, knocked out, hit stunned, or paralyzed.
	end
	if isDead(mob) then
		return false
	end
	return true
end
]]

--[[
---@param mob tes3mobileActor
---@return boolean
local function isValidPotentialFollower(mob)
	if not isValidMobile(mob) then
		return false
	end
	if mob.actorType == tes3_actorType_npc then
		return true
	end
	if mob.actorType == tes3_actorType_player then
		return false
	end
	if mob.actorType == tes3_actorType_creature then
		local mobRef = mob.reference
		local script = mobRef.object.script
		if script
		and script.id:lower():startswith('ab01') then
			-- ab01 prefix, probably some abot's creatures, skip
			if logLevel3 then
				mwse.log("%s: %s having ab01 script prefix, probably some abot's creature with AIEscort package, skip",
					modPrefix, mobRef.id)
			end
			return false
		end
	end
	return true
end
]]

-- 0 = invalid, 1 = follower, 2 = companion
---@param mob tes3mobileActor
---@return 0|1|2
local function getFollowerType(mob)
	local mobRef = mob.reference
	local aCompanion = hasCompanion(mobRef)
	local ai = tes3.getCurrentAIPackageId({reference = mobRef})
	if (ai == tes3_aiPackage_follow)
	or (ai == tes3_aiPackage_escort) then
		if aCompanion then
			return 2
		end
		if mobRef.baseObject.isGuard then
			return 0 -- skip guards could be temporaru following
		end
		return 1
	elseif (ai == tes3_aiPackage_wander)
		and aCompanion
		and hasOneTimeMove(mobRef) then
		-- special case for temporary wandering destinations
		return 2
	end
	return 0
end

---@param mob tes3mobileActor
---@return boolean
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

--[[
---@param ref tes3reference
---@return true|false
local function hasCompanion(ref)
	if hasRefVariable(ref, 'companion') then
		return true
	end
	return false
end]]

local tes3_animationGroup = tes3.animationGroup
local tes3_animationGroup_turnRight = tes3_animationGroup.turnRight
local tes3_animationGroup_turnLeft = tes3_animationGroup.turnLeft
local tes3_animationGroup_walkForward = tes3_animationGroup.walkForward
---local tes3_animationGroup_idle = tes3_animationGroup.idle

local animationGroupDict = table.invert(tes3_animationGroup)
animationGroupDict[255] = 'unknown'

local turnAnimDict = {
[tes3_animationGroup_turnRight] = true,
[tes3_animationGroup_turnLeft] = true,
[tes3_animationGroup_walkForward] = true
}

local tes3_compilerSource_console = tes3.compilerSource.console
local tes3_animationGroup_idle = tes3.animationGroup.idle

---@param mobRef tes3reference
---@param legacy true|false|nil
local function playGroupIdle(mobRef, legacy)
-- As a special case, tes3.playAnimation{reference = ..., group = 0}
-- returns control to the AI, as the AI knows that is the actor's neutral idle state.
	if logLevel2 then
		mwse.log('%s: playGroupIdle("%s", %s)', modPrefix, mobRef, legacy)
	end
	if legacy then
		tes3.runLegacyScript({reference = mobRef, command = 'PlayGroup idle',
			source = tes3_compilerSource_console})
	else
		-- let's try giving non-console command another chance
		tes3.playAnimation({reference = mobRef, group = tes3_animationGroup_idle})
	end
end

---@param ref tes3reference
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

---@param mob tes3mobileActor
---@return boolean
local function isMobilePlayer(mob)
	return mob.actorType == tes3_actorType_player
end

---@param ref tes3reference
---@return boolean
local function isPlayer(ref)
	assert(tes3.player == player)
	local result = (ref == player)
	assert(result == (ref == player))
	return result
end

local lowerBodyIndex = tes3.animationBodySection.lower + 1

---@param ref tes3reference
local function checkAnim(ref)
	local mob = ref.mobile
	if not mob then
		return
	end
	if not mob.actorType then
		return
	end
	local animationData = getAnimationData(ref)
	if not animationData then
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
	if not turnAnimDict[animGroupLower] then
		return
	end
	if isMobilePlayer(mob) then
		return
	end
	if logLevel4 then
		mwse.log('%s: checkAnim("%s") animGroupLower = %s (%s))',
			modPrefix, ref, animGroupLower, animationGroupDict[animGroupLower])
	end
	if logLevel3 then
		mwse.log('%s: checkAnim("%s") playGroupIdle()', modPrefix, ref)
	end
	playGroupIdle(ref)
end

---@param e referenceActivatedEventData
local function referenceActivated(e)
	checkAnim(e.reference)
end

---@param e mobileActivatedEventData
local function mobileActivated(e)
	checkAnim(e.reference)
end

---@param e activateEventData
local function activate(e)
	if isPlayer(e.activator) then
		---if logLevel1 then
			---mwse.log('%s: player activate("%s")', modPrefix, e.target)
		---end
		checkAnim(e.target)
	end
end

local animAllowedBehaviorStatesDict = table.invert({
tes3.aiBehaviorState.idle, tes3.aiBehaviorState.walk, tes3.aiBehaviorState.undecided
})

local scenicTravelPrefixDict = table.invert({'ab01ss','ab01bo','ab01go','ab01gu'})

---@param mobRef tes3reference
---@result true|false
local function isScenicTravelCreature(mobRef)
	local idPrefix = mobRef.object.id:sub(1, 6):lower()
	if scenicTravelPrefixDict[idPrefix] then
		return true
	end
	return false
end

---@param mobRef tes3reference
---@result true|false
local function isImmersiveTravelPassenger(mobRef)
	if mobRef.data
	and mobRef.data.rfuzzo_invincible then
		-- moving immersive travel actors
		return true
	end
	return false
end

---@param mobRef tes3reference
---@result true|false
local function isSwimmer(mobRef)
	if mobRef.baseObject.swims then
		return true
	end
	return false
end

---@param mob tes3mobileActor
---@param animGroup integer
local function checkPlayAnimGroup(mob, animGroup)
	if not bumpity then
		return
	end
	if (not animGroup)
	or (animGroup == 255) then
		return
	end
	---if getFollowerType(mob) == 0 then
		---return
	---end
	---if hasBlacklistedAnim(mob) then
		---return
	---end
	local ref = mob.reference
	local actionData = mob.actionData
		or mob.actionBeforeCombat
	if actionData then
		local aiBehaviorState = actionData.aiBehaviorState
		if not animAllowedBehaviorStatesDict[aiBehaviorState] then
			return
		end
	end
	local animationController = mob.animationController
	if animationController then
		local animGroupMovement = animationController.animGroupMovement
		if animGroupMovement then
		    if turnAnimDict[animGroupMovement] then
			    return
		    end
			if logLevel4 then
				local animGroupName = animationGroupDict[animGroup]
				mwse.log([[%s: checkPlayAnimGroup("%s", %s (%s))
animGroupMovement = %s (%s)
tes3.playAnimation({reference = "%s", group = %s (%s), loopCount = 0})]],
			        modPrefix, ref, animGroup, animGroupName,
					animGroupMovement, animationGroupDict[animGroupMovement],
					ref.id, animGroup, animGroupName
		        )
	        end
	    end
	end
	tes3.playAnimation({reference = mob, group = animGroup, loopCount = 0})
end


local staticBlacklist = {'rug','stair','step','ramp','house','isl'}
local staticBlacklistDict = table.invert(
{'in_dwrv_corr2_01','in_strong_corr2_02','in_sotha_pre2_02'})

---@param target tes3reference
---@result true|false
local function isBlacklistedStatic(target)
	local result = false
	local targetObj = target.object
	local lcObjId = targetObj.id:lower()
	if staticBlacklistDict[lcObjId] then
		result = true
	elseif lcObjId:multifind(staticBlacklist, 1, true) then
		result = true
	elseif ( targetObj.mesh:lower() ):multifind(staticBlacklist, 1, true) then
		result = true
	end
	return result
end

local tes3_objectType_door = tes3.objectType.door

---@param activePackage tes3aiPackageEscort|tes3aiPackageWander
local function changeAiDistance(activePackage)
	local d = activePackage.distance
	if d > 4096 then
		d = 512
	end
	activePackage.distance = round( ( math_random(1.5) + 0.5 ) * d )
	---activePackage.isDone = true
	---activePackage.isFinalized = true
end

local tes3_actionFlag_useEnabled = tes3.actionFlag.useEnabled

---@param pos tes3vector3
---@param toPos tes3vector3
local function changePos(pos, toPos)
	if toPos.z >= pos.z then
-- move first to the higher point
		pos.z = toPos.z
		pos.x, pos.y = toPos.x, toPos.y
		return
	end
	pos.x, pos.y = toPos.x, toPos.y
-- move to the lower point last
	pos.z = toPos.z
end

---@param mob tes3mobileActor
---@return tes3mobileActor?
local function getMobAiFollowOrEscortTarget(mob)
	local aiPlanner = mob.aiPlanner
	if not aiPlanner then
		return
	end
	local aiPackage = aiPlanner:getActivePackage()
	if not aiPackage then
		return
	end
	if (aiPackage.type == tes3_aiPackage_follow)
	or (aiPackage.type == tes3_aiPackage_escort) then
		return aiPackage.targetActor
	end
end

local animBlacklist = {
'\\am_','/am_','anim_ly','dance',
'hug','kiss','lean','lyin',
'scamp','sitbar','sittin','wait'}

---@param mob tes3mobileActor
---@return boolean
local function hasBlacklistedAnim(mob)
	local mobRef = mob.reference
	local mesh = mobRef.object.mesh
	if not mesh then
		return false
	end
	if mesh:len() == 0 then
		return false
	end
	if not mesh:lower():multifind(animBlacklist, 1, true) then
		return false
	end
	local aiTargetMob = getMobAiFollowOrEscortTarget(mob)
	if aiTargetMob then
		return false -- allow followers/escorters
	end
	local ai = tes3.getCurrentAIPackageId({reference = mobRef})
	if (ai == tes3_aiPackage_wander)
	and isCompanion(mobRef)
	and hasOneTimeMove(mobRef) then
		-- special case for companion temporary wandering
		return false -- allow oneTimeMove companions
	end
	return true
end

local turnRightIndex = tes3_animationGroup_turnRight + 1
local walkForwardIndex = tes3_animationGroup_walkForward + 1

---@param mob tes3mobileActor
---@return integer|nil
local function getNewAnimGroup(mob)
	if hasBlacklistedAnim(mob) then
		return
	end
	local ref = mob.reference
	local animationData = getAnimationData(ref)
	if not animationData then
		return
	end
	local result
	local animationGroups = animationData.animationGroups
	if animationGroups[turnRightIndex] then
		result = tes3_animationGroup_turnRight
	elseif animationGroups[walkForwardIndex] then
		-- use walkForward animation in case turnRight is not available
		result = tes3_animationGroup_walkForward
	end
	-- if logLevel5 then
		-- mwse.log('%s: getAnimGroup("%s") = %s (%s)',
			-- modPrefix, ref, result, animationGroupDict[result])
		-- )
	-- end
	return result
end

local VEC3UP = tes3vector3.new(0, 0, 1)
local VEC3DOWN = tes3vector3.new(0, 0, -1)

---@param mob tes3mobileActor
---@return boolean
local function isCreatureToSkip2(mob)
	local ref = mob.reference
	local obj = ref.object
	local lcId = obj.id:lower()
	if lcId == 'ab01guguarpackmount' then -- this is a good one
		return false
	end
	if skipCreatures >= 2 then -- 0 = Off, 1 = swimming, 2 = swimming and ab01 prefixed
		if isSwimmer(ref) then
			if logLevel3 then
				mwse.log('%s: isSwimmer("%s"), skip', modPrefix, ref.id)
			end
			return true
		end
		if lcId:startswith('ab01') then
-- ab01 prefix, probably some abot's creature having AIEscort/AIFollow package, skip
			if logLevel3 then
				mwse.log("%s: %s having ab01 prefix, probably some abot's creature with AIFollow/AIEscort package, skip", modPrefix, ref.id)
			end
			return true
		end
		local script = obj.script
		if script
		and script.id:lower():startswith('ab01') then
-- ab01 prefix, probably some abot's creature having AIEscort/AIFollow package, skip
			if logLevel3 then
				mwse.log("%s: %s having ab01 script prefix, probably some abot's creature with AIFollow/AIEscort package, skip", modPrefix, ref.id)
			end
			return true
		end
	elseif skipCreatures >= 1 then
		if isSwimmer(ref) then
			if logLevel3 then
				mwse.log('%s: isSwimmer("%s"), skip', modPrefix, ref.id)
			end
			return true
		end
	end
	return false
end


---@param mob tes3mobileActor
---@return boolean
local function isCreatureToSkip(mob)
	if not (mob.actorType == tes3_actorType_creature) then
		return false
	end
-- 0 = Off, 1 = Followers, 2 = Companions, 3 = All
	if processCreatures == 3 then
		if isCreatureToSkip2(mob) then
			return true
		end
	elseif processCreatures == 0 then
		return true
	end
	local followerType = getFollowerType(mob)
	if processCreatures >= 2 then
		if followerType == 2 then  -- follower with companion variable
			return false
		end
		if isCreatureToSkip2(mob) then
			return true
		end
	elseif processCreatures >= 1 then
		if isCreatureToSkip2(mob) then
			return true
		end
		if followerType >= 1 then -- follower
			return false
		end
	end
	return false
end

---@param mob tes3mobileNPC|tes3mobileCreature|tes3mobilePlayer
---@return boolean
local function offersAnyService(mob)
	local object = mob.object
	local aiConfig = object.aiConfig
	if not aiConfig then
		return false
	end
	if aiConfig.travelDestinations
	and (#aiConfig.travelDestinations > 0) then
		return true
	end
	if aiConfig.offersBartering
	or aiConfig.offersEnchanting
	or aiConfig.offersRepairs
	or aiConfig.offersSpellmaking
	or aiConfig.offersSpells
	or aiConfig.offersTraining then
		return true
	end
	return false
end

---@param e collisionEventData
local function collision(e)
	if not bump then
		return
	end
	if tes3.menuMode() then
		return
	end
	local target = e.target
	if not target then
		return
	end
	local ref = e.reference
	local mob = ref.mobile
	assert(mob)
	local actorType = mob.actorType
	if not actorType then
		return
	end
	if (not mob.canMove) -- dead, knocked down, knocked out, hit stunned, or paralyzed.
	or (mob.fatigue.current <= 0)
	then
		return
	end
	assert(player)
	if player.data.ab01travelType
	and (player.data.ab01travelType > 0) then
		return -- skip while Smart Companions travelling
	end
	local mobIsMobilePlayer = isMobilePlayer(mob)
	if not mobIsMobilePlayer then
		if isCreatureToSkip(mob) then
			return
		end
		---or inCombat(mob)
		if hasBlacklistedAnim(mob)
		or isDummy(ref)
		or isImmersiveTravelPassenger(ref)
		or isScenicTravelCreature(ref) then
			return
		end
	end

	local skipTargetAnim = false
	local targetMob = target.mobile

	if targetMob
	and targetMob.actorType then
		if isCreatureToSkip(targetMob) then
			return
		end
		if (not targetMob.canMove) -- dead, knocked down, knocked out, hit stunned, or paralyzed.
		or isImmersiveTravelPassenger(target)
		or isScenicTravelCreature(target) then
			return
		end
		local targetAnimationData = getAnimationData(target)
		---assert(targetAnimationData)
		if not targetAnimationData

-- dead, knocked down, knocked out, hit stunned, paralyzed,
-- drawing/sheathing their weapon, attacking,
-- casting magic or using a lockpick or probe
		or (not targetMob.canAct)

		or hasBlacklistedAnim(targetMob)
		---or targetMob.isFlying
		---or targetMob.isFalling
		or (targetMob.fatigue.current <= 0)
		or (
			inCombat(targetMob)
			---and ( not hasCompanion(target) )
		)
		or isDummy(target) then
			skipTargetAnim = true
		end
		---return
	end

	local skipRefAnim = false
	local vecMul = 1.8
	if mobIsMobilePlayer then
		vecMul = 1.25
	end
	local vecBackMul = vecMul * 0.75

	local refPos = ref.position
	local targetPos = target.position
	local newPos

	local refSlideVec = ref.rightDirection * vecMul -- slide right by default

	local animGroup
	if not mobIsMobilePlayer then
		animGroup = getNewAnimGroup(mob)
	end

	local angleToTarget = mob:getViewToPoint(targetPos)
	if angleToTarget > 1 then
		-- target is to the right
		refSlideVec = -refSlideVec -- so we slide left
		if animGroup
		and (animGroup == tes3_animationGroup_turnRight) then
			animGroup = tes3_animationGroup_turnLeft
		end
	elseif angleToTarget > -1 then
		-- else back
		refSlideVec = -ref.forwardDirection * vecMul
	end

	local activePackage

	if not mobIsMobilePlayer then
		local aiPlanner = mob.aiPlanner
		assert(aiPlanner)
		activePackage = aiPlanner:getActivePackage()
		if activePackage then
			if activePackage.type == tes3_aiPackage_wander then
				if activePackage.isMoving
				and (  not ( math.abs(activePackage.distance) < 0.01 )  )
				and (  not ( ref == tes3.getPlayerTarget() )  )
				and ( not offersAnyService(mob) ) then
					changeAiDistance(activePackage)
					---activePackage.isDone = true
					---activePackage.isFinalized = true
					---return
				end
			elseif activePackage.type == tes3_aiPackage_activate then
				local tempData = ref.tempData
				if tempData.ab01bmbp2 then
					if tempData.ab01bmbp2 > 0 then
						tempData.ab01bmbp2 = tempData.ab01bmbp2 - 1
					else
						tempData.ab01bmbp2 = nil
						activePackage.isDone = true
						activePackage.isFinalized = true
					end
				else
					local secondsPassed = math_max( math_abs(tes3.worldController.deltaTime), 0.0001 )
					local fps = math_max(1 / secondsPassed, 7)
					tempData.ab01bmbp2 = fps * 10 -- stop trying after about 10 sec
				end
			end
		end
	end

	local skipRefMove = false
	if mobIsMobilePlayer then
		skipRefMove = true
	end

	local blacklistedStatic = false
	if isBlacklistedStatic(target) then
		if logLevel4 then
			mwse.log([[%s: "%s" is blacklistedStatic, skip "%s" collision with it]],
				modPrefix, target.id, ref.id)
		end
		blacklistedStatic = true
		skipRefMove = true
	end

	local targetMobIsMobilePlayer = false


	if targetMob
	and targetMob.actorType then

		-- process target actor
		targetMobIsMobilePlayer = isMobilePlayer(targetMob)
		if not targetMobIsMobilePlayer then
			if not skipTargetAnim then
				local targetAnimGroup = getNewAnimGroup(targetMob)
				checkPlayAnimGroup(targetMob, targetAnimGroup)
			end
			local refBackVec = ref.forwardDirection * vecBackMul
			if math_abs(angleToTarget) < 90 then
				newPos = targetPos - refSlideVec + refBackVec
			else
				newPos = targetPos - refSlideVec - refBackVec
			end

			if logLevel4
			or (
				logLevel2
				and mobIsMobilePlayer
			) then
				mwse.log([[%s: collision() to mob
ref = %s, target = %s, ref.forwardDirection = %s,
target.forwardDirection = %s, refSlideVec = %s,
targetPos before = %s, targetPos after = %s]],
				modPrefix, ref, target, ref.forwardDirection,
				target.forwardDirection, refSlideVec,
				targetPos, newPos)
			end
assert( not isPlayer(target) )
			changePos(targetPos, newPos - targetMob.velocity)
		end -- if not targetMobIsMobilePlayer

	else -- target is not an actor e.g. a static
		if (logLevel4) --  or true for temp testing
		and (not mobIsMobilePlayer )
		and (not targetMobIsMobilePlayer ) then
			if skipRefMove then
				if blacklistedStatic then
					mwse.log(
						[[%s: skipRefMove, skip "%s" collision with blacklistedStatic "%s"]],
						modPrefix, ref.id, target.id
					)
				else
					mwse.log(
						[[%s: skipRefMove, skip "%s" collision with "%s"]],
						modPrefix, ref.id, target.id
					)
				end
			else
				mwse.log([[%s: "%s" collision with "%s"]], modPrefix, ref.id, target.id)
			end
		end

		if skipRefMove then
			return
		end

		assert(ref.supportsLuaData)
		local tempData = ref.tempData
		assert(tempData)
		if tempData.ab01bmbp then
			tempData.ab01bmbp = nil
-- alternate skip to give the engine more time for collision updates
-- hopefully will work better with those pesky mesh "optimizers" mods
-- removing normals from root collision nodes
			return
		end
		tempData.ab01bmbp = 1

		---@type tes3.rayTest.params
		local rayParams = {
			position = refPos:copy(),
			direction = VEC3DOWN,
			maxDistance = 32,
			root = tes3_game_worldRoot,
			useModelBounds = false,
			returnNormal = true,
			ignore = {ref, player, player1stPerson}
		}
		local normal
		local rayHit = tes3.rayTest(rayParams)
		if rayHit
		and (rayHit.reference == target) then
			normal = rayHit.normal
			if normal.z > 0.75 then
				if logLevel4 then
					mwse.log([[%s: mesh surface collision("%s", "%s") normal = %s, skip]],
						modPrefix, ref.id, target.id, normal)
				end
				return -- ignore vertical down collision
			end
			if logLevel3 then
				mwse.log([[%s: mesh surface collision("%s", "%s") normal = %s]],
					modPrefix, ref.id, target.id, normal)
			end
		end

		local refBackVec = -ref.forwardDirection
		local maxDist = 1024
		local boundSize2D = mob.boundSize2D
		if boundSize2D then
			local size = math_max(boundSize2D.y, boundSize2D.x)
			---maxDist = round(size * 0.75)
			maxDist = size * ref.scale
		end

		rayParams.position = tes3vector3.new(refPos.x, refPos.y, refPos.z + 32)
		rayParams.direction = ref.forwardDirection:copy()
		rayParams.maxDistance = maxDist

		rayHit = tes3.rayTest(rayParams)
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

		if logLevel3 then
			mwse.log([[%s: collision("%s", "%s") rayHit]],
				modPrefix, ref.id, target.id)
		end

		local intersection
		if rayHit.reference == target then
			intersection = rayHit.intersection
		end
		if not intersection then
			return
		end

		normal = rayHit.normal
		local kz = 16

		if normal.z > 0.5 then
			---refPos.z = refPos.z + kz
			if logLevel3 then
				mwse.log([[%s: collision("%s", "%s") normal = %s, not steep, skip]],
					modPrefix, ref.id, target.id, normal)
			end
			return -- not steep, skip
		end

		if logLevel4 then
			mwse.log([[%s: collision("%s", "%s") normal = %s]],
				modPrefix, ref.id, target.id, normal)
		end

		if activePackage
		and (activePackage.isMoving) then
			if (math_abs(normal.x) > 0.9)
			and (math_abs(normal.y) > 0.9) then
				-- some randomness for perpendicular collision
				if math_random(100) >= 50 then
					normal.x = normal.x * 0.75
				else
					normal.y = normal.y * 0.75
				end
			end
			-- rotate XY normal by 90 degrees with some randomness
			if math_random(100) > 80 then
				refBackVec = tes3vector3.new(-normal.y, normal.x, 0) -- counterclockwise
			else
				refBackVec = tes3vector3.new(normal.y, -normal.x, 0) -- clockwise
			end

			local dz = kz
			local bb = target.baseObject.boundingBox
			if bb then
				local mx = bb.max
				local mn = bb.min
				local z = math_max(mx.z - mn.z, mx.x - mn.x)
				z = math_max(z, mx.y - mn.y)
				if z < 72 then
					dz = dz + z
				end
			end
			local mobHeight = mob.height
			local mobHeight2 = mobHeight + kz
			local rayParams2 = {
				position = tes3vector3.new(intersection.x,
					intersection.y, refPos.z + mobHeight),
				direction = VEC3UP,
				maxDistance = math_max(dz, mobHeight2),
				root = tes3_game_worldRoot,
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
			dz = math_min(dz, dzMax)
			local jump = dz < mobHeight2
			if not jump then
				refBackVec = refBackVec + tes3vector3.new(normal.x, normal.y, 0)
			end

			refBackVec:normalize()

			refBackVec = refBackVec * vecBackMul
			if logLevel3 then
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

assert( not isPlayer(ref) )
			changePos(refPos, newPos - mob.velocity)

			if (target.object.objectType == tes3_objectType_door)
			and (not target.destination)
			and (not ref.tempData.ab01bmbp2) then
				if activePackage then
					if activePackage.type == tes3_aiPackage_activate then
						return
					end
					if activePackage.type == tes3_aiPackage_wander then
						if tes3.getLocked({reference = target}) then
							changeAiDistance(activePackage)
						end
					end
					---activePackage.isDone = true
					---activePackage.isFinalized = true
					return
				end
				if target:testActionFlag(tes3_actionFlag_useEnabled)
				and ( not tes3.getLocked({reference = target}) ) then
					-- make actor open the door
					tes3.setAIActivate({reference = mob, target = target})
				end
			end

			return

		end -- if activePackage

	end -- target static processing


	if skipRefMove
	or mobIsMobilePlayer then
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
assert( not isPlayer(ref) )
		changePos(refPos, newPos - mob.velocity)
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

local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	player1stPerson = tes3.player1stPerson
	setCollisionEvent()
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
			collectgarbage()
		end
	end

end

local function onClose()
	updateFromConfig()
	player = tes3.player -- ensure player is initialized
	if player then
		mobilePlayer = tes3.mobilePlayer
		player1stPerson = tes3.player1stPerson
		-- call it only if player is initialized
		setCollisionEvent()
	end
	mwse.saveConfig(configName, config,	{indent = true})
end

local function modConfigReady()

	tes3_game_worldRoot = tes3.game.worldRoot

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

	local optionList = {'Off', 'Only Companions', 'Followers', 'All'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = ("%s. %s"):format(i - 1, optionList[i]), value = i - 1}
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
		label = 'Process Creatures:',
		options = getOptions(),
		description = [[Process selected creatures.
Decreasing it could use less processing power in areas where creatures are most frequent.]],
		configKey = 'processCreatures'
	})

	optionList = {'Off', 'Swimming', 'Swimming and ab01 prefixed'}
	category:createDropdown({
		label = 'Skip Creatures:',
		options = getOptions(),
		description = [[Skip selected creatures.
increasing it could use less processing power in areas where creatures are most frequent.]],
		configKey = 'skipCreatures'
	})

	optionList = {'Off', 'Low', 'Medium', 'High', 'Very High', 'Max'}
	category:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		description = [[Enables various levels of debug information written to the Morrowind\MWSE.log file.

Should be kept to 0 during normal gameplay, but if you encounter a problem with  the mod, you could try and save the game right before the problem happens, crank the Log level up, exit the game and reload.

When the problem happens again, exit the game, and send the Morrowind\MWSE.log file with your error report to mod author.]],
		configKey = 'logLevel'
	})

	mwse.mcm.register(template)

	event.register('loaded', loaded)
	event.register('referenceActivated', referenceActivated)
	event.register('mobileActivated', mobileActivated)
	event.register('activate', activate)
end
event.register('modConfigReady', modConfigReady)
