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

local tes3_animationState_dying = tes3.animationState.dying
local tes3_animationState_dead = tes3.animationState.dead

local function isDead(mob)
	local result = false
	if mob.isDead then
		result = true
	else
		local actionData = mob.actionData
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

local function getAnimGroupMovement(mob)
	local animationController = mob.animationController
	if not animationController then
		return
	end
	return animationController.animGroupMovement -- 255 if none
end

local tes3_animationGroup_turnRight = tes3.animationGroup.turnRight
local tes3_animationGroup_turnLeft = tes3.animationGroup.turnLeft
local tes3_animationGroup_idle = tes3.animationGroup.idle
local tes3_aiPackage_wander = tes3.aiPackage.wander


local function referenceActivated(e)
	local ref = e.reference
	local mob = ref.mobile
	if not mob then
		return
	end
	if not mob.actorType then
		return
	end
	local animGroup = getAnimGroupMovement(mob)
	if (not animGroup)
	or (animGroup == tes3_animationGroup_idle)
	or (animGroup == 255) then
		return
	end
	tes3.playAnimation({reference = mob,
		group = tes3_animationGroup_idle, loopCount = 0})
end

local function playGroup(mob, animGroup)
	if not bumpity then
		return
	end
	if mob.isTurningRight
	and (animGroup == tes3_animationGroup_turnRight) then
		return
	end
	if mob.isTurningLeft
	and (animGroup == tes3_animationGroup_turnLeft) then
		return
	end
	--[[if not animGroup then
		animGroup = getAnimGroupMovement(mob)
	end]]
	if not animGroup then
	---or (animGroup == 255) then
		animGroup = tes3_animationGroup_idle
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
		mwse.log([[%s: getAngleTo("%s","%s") = %.2f]],
			modPrefix, ref.id, target.id, math.deg(angleTo))
	end
	return angleTo
end

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
		return
	end
	if not mob.actorType then
		return
	end
	if (not mob.canAct)
	or mob.isFlying
	or mob.isFalling
	or inCombat(mob) then
		return
	end

	local player = tes3.player
	local refIsPlayer = (ref == player)

	--[[ -- restricted debug only
	if ( not refIsPlayer )
	and (not logLevel3) then
		return
	end]]

	local targetMob = target.mobile
	if targetMob
	and targetMob.actorType then
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
	end

	local vecMul = 1.8
	if refIsPlayer then
		vecMul = 1.25
	end

	local refPos = ref.position
	local targetPos = target.position
	local newPos

	local refSlideVec = ref.rightDirection * vecMul
	local animGroup = tes3_animationGroup_turnRight

	local angleToTarget = getAngleTo(ref, target)
	if angleToTarget > 0 then
		-- target is to the right
		refSlideVec = -refSlideVec -- so we slide left
		animGroup = tes3_animationGroup_turnLeft
	elseif angleToTarget == 0 then
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
		if not (target == player) then
			playGroup(targetMob, animGroup)
			newPos = targetPos - refSlideVec - (ref.forwardDirection * vecMul)
			if logLevel2
			or (
				logLevel1
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
			local from = targetPos
			local to = newPos
			from.x, from.y, from.z = to.x, to.y, to.z
		end
	else -- e.g. a colliding static
		if not skipRefMove then
			local refBackVec = -ref.forwardDirection
			local maxDist = 1024
			local boundSize2D = mob.boundSize2D
			if boundSize2D then
				local size = math.max(boundSize2D.y, boundSize2D.x)
				---maxDist = round(size * 0.75)
				maxDist = size
			end
			local rayParams = {
				position = tes3vector3.new(refPos.x, refPos.y, refPos.z + 32),
				direction = ref.forwardDirection,
				maxDistance = maxDist,
				root = tes3.game.worldRoot,
				returnNormal = true,
				ignore = {ref, tes3.player1stPerson, player}
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
			normal = rayHit.normal
			if normal.z > 0.5 then
				ref.position.z = intersection.z + 24
				if logLevel5 then
					mwse.log([[%s: collision("%s", "%s"), not steep, skip]],
						modPrefix, ref.id, target.id)
				end
				return -- not steep, a little jump and skip
			end

			if activePackage
			and activePackage.isMoving then

				-- rotate normal by -/+ 90 degrees
				if math.random(100) >= 50 then
					refBackVec = tes3vector3.new(-normal.y, normal.x, 0)
				else
					refBackVec = tes3vector3.new(normal.y, -normal.x, 0)
				end

				local dz = 20
				local bb = target.baseObject.boundingBox
				if bb then
					local mx = bb.max
					local mn = bb.min
					local z = math.max(mx.z - mn.z, mx.x - mn.x)
					z = math.max(dz, mx.y - mn.y)
					if z < 72 then
						dz = dz + z
					end
				end
				local mobHeight = mob.height
				rayParams.position = tes3vector3.new(intersection.x,
					intersection.y, refPos.z + mobHeight)
				rayParams.direction = player.upDirection
				local mobHeight2 = mobHeight + 20
				rayParams.maxDistance = math.max(dz, mobHeight2)
				local dzMax = mobHeight2
				local rayHit = tes3.rayTest(rayParams)
				if rayHit then
					local intersection = rayHit.intersection
					if intersection then
						dzMax = intersection.z - refPos.z - mobHeight + 20
					end
				end
				dz = math.min(dz, dzMax)
				local jump = dz < mobHeight2
				if not jump then
					refBackVec = refBackVec + tes3vector3.new(normal.x, normal.y, 0)
				end

				refBackVec:normalize()

				refBackVec = refBackVec * vecMul
				if jump then
					if not ref.tempData.ab01bubu then
						ref.tempData.ab01bubu = true
						refBackVec.z = dz
					end
				end

				if logLevel1 then
					mwse.log([[%s: collision() to object
ref = %s, target = %s, ref.forwardDirection = %s, normal = %s,
target.forwardDirection = %s, refBackVec = %s,
targetPos before = %s, intersection = %s]], modPrefix,
						ref, target, ref.forwardDirection, normal,
						target.forwardDirection, refBackVec,
						targetPos, intersection)
				end

				playGroup(mob)
				newPos = ref.position + refBackVec

				local from = ref.position
				local to = newPos
				from.x, from.y, from.z = to.x, to.y, to.z

				if (target.object.objectType == tes3_objectType_door)
				and (not target.destination) then
					if tes3.getLocked({reference = target}) then
						changeAiDistance(activePackage)
						---activePackage.isDone = true
						---activePackage.isFinalized = true
					else
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
	newPos = targetPos + refSlideVec - (ref.forwardDirection * vecMul)
	local dist = newPos:distance(targetPos)
	if dist > 3 then
		if logLevel3 then
			mwse.log([[%s: collision("%s", "%s") 3 dist = %s,
targetPos before= %s, targetPos after = %s, ]],
				modPrefix, ref.id, target.id, dist, targetPos, newPos)
		end
		playGroup(mob, animGroup)
		local from = ref.position
		local to = newPos
		from.x, from.y, from.z = to.x, to.y, to.z
	end
end

local function setCollisionEvent()
	if not tes3.player then
		return
	end
	if event.isRegistered('collision', collision) then
		if bump then
			return
		end
		event.unregister('collision', collision)
		return
	end
	if bump then
		event.register('collision', collision)
	end
end

local function updateFromConfig()
	bumpity = config.bumpity
	if not (config.bump == bump) then
		bump = config.bump
		setCollisionEvent()
	end
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
	logLevel5 = logLevel >= 5
end
updateFromConfig()

local function loaded()
	setCollisionEvent()
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId, table = config}
end

local function modConfigReady()

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		updateFromConfig()
		mwse.saveConfig(configName, config, {indent = false})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label="Info",
		postCreate = function(self)
			-- total width must be 2
			local block = self.elements.sideToSideBlock
			block.children[1].widthProportional = 1.3
			block.children[2].widthProportional = 0.7
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo({text = [[Makes actors shift it.]]})

	---local controls = preferences:createCategory{label = mcmName}
	local controls = preferences:createCategory({})

	local yesOrNo = {[false] = 'No', [true] = 'Yes'}

	local function getYesNoDescription(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	---local function getDescription(frmt, variableId)
		---return string.format(frmt, defaultConfig[variableId])
	---end

	controls:createYesNoButton({
		label = 'Bump',
		description = getYesNoDescription([[Default: %s.
Actors bump away toggle. Basically enables/disables the mod effects.]], 'bump'),
		variable = createConfigVariable('bump')
	})

	controls:createYesNoButton({
		label = 'Bumpity',
		description = getYesNoDescription([[Default: %s.
Visible Bump walk animation toggle. Effective only when "Bump" option is enabled.]], 'bumpity'),
		variable = createConfigVariable('bumpity')
	})

	local optionList = {'Off', 'Low', 'Medium', 'High', 'Very High', 'Max'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s", i - 1,
				optionList[i]), value = i - 1}
		end
		return options
	end

	local function getDropDownDescription(frmt, variableId)
		local i = defaultConfig[variableId]
		return string.format(frmt, string.format('%s. %s', i, optionList[i+1]))
	end

	controls:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		variable = createConfigVariable('logLevel'),
		description = getDropDownDescription('Default: %s','logLevel'),
	})

	mwse.mcm.register(template)
	event.register('loaded', loaded)
	event.register('referenceActivated', referenceActivated)
end
event.register('modConfigReady', modConfigReady)


