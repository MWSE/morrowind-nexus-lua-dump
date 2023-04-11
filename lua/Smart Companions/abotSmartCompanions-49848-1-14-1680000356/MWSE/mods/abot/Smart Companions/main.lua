---@diagnostic disable: undefined-field
--[[
Smart Companions
by abot

see modConfigReady() / MCM panel definition for features
]]

-- begin configurable parameters
local defaultConfig = {
allowLooting = 1, -- 0 = No, 1 = Yes, No Overburdening, 2 = Yes, Overburdening
minValueWeightRatio = 5,
alwaysLootOrganic = true, -- always loot from organic containers (e.g. plants) regardless of value/weight ratio
maxDistance = 384,
allowProbes = true,
allowLockpicks = true,
allowMagic = true,
fixAlarm = true, -- followers are given 0 Alarm
fixAcrobatics = true, -- follower NPCs are given high acrobatics
fixWaterBreathing = true, -- follower NPCs are given water breathing
fixAthletics = true, -- follower NPCs are given high athletics
skipActivatingFollowerWhileSneaking = true, -- self explaining
AIfixOnActivate = 2, -- 0 = No, 1 = Companions, 2 = All followers, 3 = All actors
transparencyFixOnActivate = false, -- try and fix follower transparency on activate
scenicTravelling = 2, -- 0 = No, 1 = Companions, 2 = All followers
autoWarp = 2, -- 0 = No, 1 = Companions, 2 = All followers
warpDistance = 680,
warpFightingCompanions = false,
warpWaterWalk = 2, -- 0 = No, 1 = Companions, 2 = All followers
warpLevitate = 1, -- 0 = No, 1 = Companions, 2 = All followers
autoAttack = 1, -- 0. No - 1. Yes, Only current companions - 2. Yes, Any follower
ignoreMannequinAttacks = true, -- ignore attacks from creatures/npc emulating mannequins/targets/practice dummies
autoBurden = false, -- burden non-companion followers on combat start
autoMoveCC = true, -- automove followers on cell change
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium 3 = High, 4 = Max
}
-- end configurable parameters

local author = 'abot'
local modName = 'Smart Companions'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

--[[local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end]]

-- note the or defaultConfig is mostly to avoid Visual Studio Code false problems detection
local config = mwse.loadConfig(configName, defaultConfig)
---assert(config)

-- to be reset in loaded()
local inputController, audioController
local player
local mobilePlayer
local lastCompanionRef
local lastTargetRef
local tes3gmst_fPickLockMult, tes3gmst_fTrapCostMult

local tes3_scanCode_lAlt = tes3.scanCode.lAlt
local tes3_scanCode_rAlt = tes3.scanCode.rAlt

local function isAltDown()
	return inputController:isKeyDown(tes3_scanCode_lAlt)
		or inputController:isKeyDown(tes3_scanCode_rAlt)
end

local T3OT = tes3.objectType
local BOOK_T = T3OT.book
local CONT_T = T3OT.container
local DOOR_T = T3OT.door
local LIGH_T = T3OT.light
local LKPK_T = T3OT.lockpick
local PROB_T = T3OT.probe

local validLootTypes = {
[T3OT.alchemy] = true, [T3OT.ammunition] = true, [T3OT.apparatus] = true,
[T3OT.armor] = true, [BOOK_T] = true, [T3OT.clothing] = true,
[CONT_T] = true, [DOOR_T] = true, [T3OT.ingredient] = true,
[LIGH_T] = true, [LKPK_T] = true, [T3OT.miscItem] = true,
[PROB_T] = true, [T3OT.repairItem] = true, [T3OT.weapon] = true,
}

---local readableObjectTypes = table.invert(T3OT)

-- refreshed in modConfigReady()
local logLevel = config.logLevel
local autoWarp = config.autoWarp
local autoAttack = config.autoAttack
local autoBurden = config.autoBurden
local ignoreMannequinAttacks = config.ignoreMannequinAttacks
local warpFightingCompanions = config.warpFightingCompanions
local warpWaterWalk = config.warpWaterWalk
local warpLevitate = config.warpLevitate
local autoMoveCC = config.autoMoveCC

if config.warpWaterWalking
or (config.warpWaterWalking == false) then
	config.warpWaterWalking = nil -- clear legacy value
end

local function getValidObjLootType(obj)
	local ot = obj.objectType
	if logLevel >= 3 then
		mwse.log("%s: %s obj.objectType = %s", modPrefix, obj.id, mwse.longToString(ot))
	end
	if validLootTypes[ot] then
		return ot
	end
	return nil
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

local tes3_aiPackage_follow = tes3.aiPackage.follow
local tes3_aiPackage_wander = tes3.aiPackage.wander
local tes3_aiPackage_escort = tes3.aiPackage.escort
local tes3_actorType_creature = tes3.actorType.creature
local tes3_actorType_npc = tes3.actorType.npc

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

	local lcId = string.lower(mobRef.object.id)
	if lcId == 'ab01guguarpackmount' then -- this is a good one
		return true
	end
	if string.startswith(lcId, 'ab01') then
-- ab01 prefix, probably some abot's creature having AIEscort package, skip
		return false
	end
	local script = mob.object.script
	if script then
		local lcId2 = string.lower(script.id)
		if string.startswith(lcId2, 'ab01') then -- ab01 prefix, probably some abot's creature having AIEscort package, skip
			if logLevel >= 3 then
				mwse.log("%s: %s having ab01 prefix, probably some abot's creature with AIEscort package, skip", modPrefix, mobRef.id)
			end
			return false
		end
	end
	return true
end


-- mobile.inCombat alone is not reliable /abot
local function inCombat(mob)
	if mob.inCombat then
		return true
	end
	if mob.combatSession then
		return true
	end
	if mob.actionData then
		if mob.actionData.target then
			return true
		end
	end
	--[[if mob.isAttackingOrCasting then
		return true
	end]]
	return false
end

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

local function isCompanion(mobRef)
	local companion = getCompanion(mobRef)
	if companion
	and (companion == 1) then
		return true
	end
	return false
end

-- 0 = invalid, 1 = follower, 2 = companion
local function validFollower(mob, anyFollower, checkWarpFightingCompanions)
	if (not mob.canMove) -- dead, knocked down, knocked out, hit stunned, or paralyzed.
	or (not isValidMobile(mob)) then
		return 0
	end
	local mobRef = mob.reference
	local aCompanion = isCompanion(mobRef)
	local mobRefObj = mobRef.object
	if checkWarpFightingCompanions then
		if not warpFightingCompanions then
			if aCompanion
			or string.find(string.lower(mobRefObj.id), 'summon', 1, true) then
				if (not mob.canAct) -- drawing/sheathing their weapon, attacking, casting magic or using a lockpick or probe
				or inCombat(mob) then
					return 0
				end
			end
		end
	end

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

local function isValidScenicFollower(mob)
	local anyFollower = config.scenicTravelling >= 2
	if validFollower(mob, anyFollower) > 0 then
		local mobRef = mob.reference
		local boundSize_y = mob.boundSize.y * mobRef.scale
		if boundSize_y > 80 then -- skip big mesh actors
			if logLevel >= 2 then
				mwse.log("%s: %s, boundSize.y %s, skipped", modPrefix, mobRef.id, boundSize_y)
			end
			return false
		end
		if logLevel >= 3 then
			mwse.log("%s: %s", modPrefix, mobRef.id)
		end
		return true
	end
	return false
end

local function getSpreads(mob) -- out spread, nospread
	local spread = nil
	local nospread = nil
	if not mob.canMove then
-- dead, knocked down, knocked out, hit stunned, or paralyzed
		return spread, nospread
	end
	local mobRef = mob.reference
	if mobRef.disabled
	or mobRef.deleted
	or isDead(mob) then
		return spread, nospread
	end
	local context = mobRef.context
	if context then
		spread = context.spread
		nospread = context.nospread
		if logLevel >= 3 then
			mwse.log("%s: %s, spread = %s, nospread = %s", modPrefix, mobRef.id, spread, nospread)
		end
	end
	return spread, nospread
end

local travelType = 0 -- 0 = none, 1 = boat, 2 = strider, 3 = gondola

local function getVec3FromTable3(t)
	return tes3vector3.new(t[1], t[2], t[3])
end

local function getTable3FromVec3(v)
	return {math.floor(v.x + 0.5), math.floor(v.y + 0.5), math.floor(v.z + 0.5)}
end

 -- reset in loaded()
local travellers = {} -- e.g. travellers[id] = {mob = mob, inv = mob.invisibility, acro = mob.acrobatics.current, ns = tns} -- store mob, invisibility, acrobatics,
local numTravellers = 0
local doPackTravellers = false

local function packTravellers()
	doPackTravellers = true
	local t = {}
	numTravellers = 0
	local mobRef
	for id, v in pairs(travellers) do
		if v then
			if v.mob then
				mobRef = tes3.getReference(id)
				if mobRef then
					t[id] = v
					numTravellers = numTravellers + 1
					travellers[id] = nil
				end
			end
		end
	end
	travellers = t
	doPackTravellers = false
end

local function cleanTravellers()
	numTravellers = 0
	for k, v in pairs(travellers) do
		if v then
			if v.mob then
				v.mob = nil
			end
			if v.inv then
				v.inv = nil
			end
			if v.acro then
				v.acro = nil
			end
			if v.ns then
				v.ns = nil
			end
			travellers[k] = nil
		end
	end
	travellers = {}
end


local warpers = {} -- e.g. warpers[mobId] = speed
local doPackWarpers = false

local function packWarpers()
	doPackWarpers = true
	local t = {}
	local mobRef
	for id, speed in pairs(warpers) do
		if speed then
			mobRef = tes3.getReference(id)
			if mobRef then
				t[id] = speed
				warpers[id] = nil
			end
		end
	end
	warpers = t
	doPackWarpers = false
end

local function cleanWarpers()
	for k, v in pairs(warpers) do
		if v then
			warpers[k] = nil
		end
	end
	warpers = {}
end

local maxSavedPlayerPositions = 30
local lastPlayerPositions = {} -- e.g. lastPlayerPositions[i] = {cellId = v.cellId, pos = getVec3FromTable3(v.pos)}

local doPackLastPlayerPositions = false

local function packLastPlayerPositions()
	doPackLastPlayerPositions = true
	local t = {}
	local j = 0
	for i, v in pairs(lastPlayerPositions) do
		if v
		and v.pos then
			j = j + 1
			t[j] = v
			lastPlayerPositions[i] = nil
		end
	end
	lastPlayerPositions = t
	doPackLastPlayerPositions = false
end

local function cleanLastPlayerPositions()
	for i, v in pairs(lastPlayerPositions) do
		if v then
			if v.cellId then
				v.cellId = nil
			end
			if v.pos then
				v.pos = nil
			end
			lastPlayerPositions[i] = nil
		end
	end
	lastPlayerPositions = {}
end

local scenicTravelAvailable
local ab01ssDest, ab01boDest, ab01goDest

 -- cached globals, found in modConfigReady
local ab01ssDestGlob, ab01boDestGlob, ab01goDestGlob, ab01goAngleGlob, NPCVoiceDistanceGlob

local function roundInt(x)
	return math.floor(x + 0.5)
end

local function initScenicTravelAvailable()
	if ab01boDestGlob then
		ab01boDest = roundInt(ab01boDestGlob.value)
	end
	if ab01ssDestGlob then
		ab01ssDest = roundInt(ab01ssDestGlob.value)
	end
	if ab01goDestGlob then
		ab01goDest = roundInt(ab01goDestGlob.value)
	end
	if ab01boDest then
		scenicTravelAvailable = true
	elseif ab01ssDest then
		scenicTravelAvailable = true
	elseif ab01goDest then
		scenicTravelAvailable = true
	---elseif tes3.getGlobal('ab01compMounted') then
		---scenicTravelAvailable = true
	else
		scenicTravelAvailable = false
	end
end

local travelParams = {
	[1] = {spell = 'ab01boSailAbility', spread = 29, maxInLine = 5}, -- boat
	[2] = {spell = 'ab01ssMountAbility', spread = 29, maxInLine = 5}, -- strider
	[3] = {spell = 'water walking (unique)', spread = 22, maxInLine = 1}, -- gondola
}

local travelRadStep = 0 -- updated in startMoveTravellers()

local function getCosSin(a, radStep)
	local radStep2 = radStep * 2
	local cosa = {
		[1] = math.cos(a),
		[2] = math.cos(a - radStep),
		[3] = math.cos(a + radStep),
		[4] = math.cos(a - radStep2),
		[5] = math.cos(a + radStep2),
	}
	local sina = {
		[1] = math.sin(a),
		[2] = math.sin(a - radStep),
		[3] = math.sin(a + radStep),
		[4] = math.sin(a - radStep2),
		[5] = math.sin(a + radStep2),
	}
	return cosa, sina
end

local function alignToPlayerZ(mobRef)
	local pcCell = player.cell
	local playerPos = player.position
	local mobPos = mobRef.position
	if pcCell.isInterior then
		mobPos.z = playerPos.z + 8
	else
		mobPos.z = playerPos.z + 16 -- even higher in exteriors/no ceiling
	end
end

local movingTravellers = false

local function moveTravellers()
	if tes3ui.menuMode() then
		return
	end
	if travelType <= 0 then
		return
	end
	if doPackTravellers then
		return
	end
	local tp = travelParams[travelType]
	local dist = tp.spread
	local maxInLine = tp.maxInLine
	local a1, a2
	if travelType == 3 then -- gondola
		a1 = ab01goAngleGlob.value
		a1 = math.rad(a1)
		a2 = a1 --- + math.pi
	else
		a1 = mobilePlayer.facing
		a2 = a1
	end

	local dd = dist
	local cosa, sina = getCosSin(a1, travelRadStep)
	local mob, mobPos, mobRef
	local invalid
	local angleIndex = 1
	local playerPos = player.position
	for id, t in pairs(travellers) do
		invalid = true
		if t then-- needed safety
			mob = t.mob
			if mob then
				mobRef = mob.reference
				if mobRef then
					if tes3.getReference(mobRef.id) then -- safety as any fake summon npc could disappear
						mobPos = mob.position
						if mobPos then
							invalid = false
							mobPos.z = playerPos.z
							-- move behind the player to not interfere with player scenic view
							mobPos.x = playerPos.x - (dist * sina[angleIndex])
							mobPos.y = playerPos.y - (dist * cosa[angleIndex])
							mob.facing = a2 -- look front
							---mwse.log("angleIndex = %d, dist = %d, x = %s, y = %s", angleIndex, dist, mobPos.x, mobPos.y)
							if angleIndex < maxInLine then
								angleIndex = angleIndex + 1
							else
								angleIndex = 1
								dist = dist + dd -- if more than maxInLine one more step behind and reset angle
								---mwse.log("angleIndex = %d, dist = %d, dd = %s", angleIndex, dist, dd)
							end
						end -- if mobPos
					end -- if tes3.getReference
				end -- if mobRef
			end -- if mob
		end -- if t
		if invalid then
			if numTravellers > 0 then
				numTravellers = numTravellers - 1
			end
			travellers[id].mob = nil
			doPackTravellers = true
		end
	end -- for
	if doPackTravellers then
		packTravellers()
	end
end

local tes3_effect_slowFall = tes3.effect.slowFall
local tes3_effect_levitate = tes3.effect.levitate
local tes3_effect_waterWalking = tes3.effect.waterWalking
local tes3_effect_burden = tes3.effect.burden

local levitateSpell, waterWalkSpell, burdenSpell -- created in modConfigReady()

---local slowFallAmount = 1 -- updated in modConfigReady()

local function isMount(mobRef)
	if string.multifind(string.lower(mobRef.id), {'guar', 'horse', 'mount'}, 1, true) then
		return true
	end
	return false
end

local ab01mountNPCAbility = tes3.getObject('ab01mountNPCAbility')

local function isStayOutside(mob)
	local mobRef = mob.reference
	if mobRef then
		local context = mobRef.context
		if context then
			local stayOutside = context.stayOutside
				or context.stayoutside
				or context.StayOutside
			if stayOutside then
				if stayOutside == 1 then
					return true
				end
			end
		end
	end
	return false
end

local function warpFollowers()
	if autoWarp <= 0 then
		return
	end
	if doPackWarpers then
		return
	end
	if doPackLastPlayerPositions then
		return
	end
	local stepDist = 64
	local minDist = 72
	local dist = 62
	local dd = 58
	local anyFollower = autoWarp >= 2
	local warpDist = config.warpDistance

	local mobRef, mobId, mobPos, d, mobCell, notInPlayerCell, ori
	local boundSize_y, mobSpeed, newMobSpeed, ok

	local funcPrefix = string.format('%s %s', modPrefix, 'warpFollowers()')

	local function sameCellOrExterior(cell_1_id, cell_2)
		return (cell_1_id == cell_2.id)
		or (
			(cell_1_id == '') -- stored cell_1_id == '' means cell1 is exterior
		and (not cell_2.isInterior)
		)
	end

	local logLevel4 = logLevel >= 4
	local angleIndex = 1
	local ab01bsy
	local newPosFound
	local mob, valid
	local validFollowers = {}

	local pcCell = player.cell
	local playerHasSlowfall = tes3.isAffectedBy({reference = mobilePlayer, effect = tes3_effect_slowFall})
	local playerLevitate = mobilePlayer.levitate
	local friendlyActors = mobilePlayer.friendlyActors
	local k = 0
	for j = 1, #friendlyActors do
		mob = friendlyActors[j]
		valid = validFollower(mob, anyFollower, true)
		if valid > 0 then
			k = k + 1
			validFollowers[k] = mob
		end
	end
	local warpRadStep = math.rad(60 * 5 / k)
	local maxAfterWarpDist = math.floor((dd * k / 5) + minDist + 0.5)
	local pcAngleZ = mobilePlayer.facing
	local cosa, sina = getCosSin(pcAngleZ, warpRadStep)
	local playerPos = player.position

	for j = 1, #validFollowers do
		mob = validFollowers[j]
		mobRef = mob.reference

		ok = true
		if playerHasSlowfall then
			if mob.actorType == tes3_actorType_creature then
				if isMount(mobRef) then
					ok = false
				end
			else
				if (ab01mountNPCAbility
				and tes3.isAffectedBy({reference = mobRef,
---@diagnostic disable-next-line: assign-type-mismatch
					effect = tes3_effect_slowFall, object = ab01mountNPCAbility})
				) then
					-- e.g. npc riding a ab01guguarpackmount, as we are here, try and reduce bounding box so guar can be activated
					if not mobRef.data then
						mobRef.data = {}
					end
					if not mobRef.data.ab01bsy then
						mobRef.data.ab01bsy = mob.boundSize.y
						mob.boundSize.y = 16
					end
				elseif mobRef.data then
					ab01bsy = mobRef.data.ab01bsy
					if ab01bsy then
						mob.boundSize.y = ab01bsy
						mobRef.data.ab01bsy = nil
					end
				end
			end
		end -- if playerHasSlowfall

		if ok then
			mobId = string.lower(mobRef.id)
			mobPos = mobRef.position:copy()
			if (playerLevitate > 0)
			and (not movingTravellers) then
				if valid >= warpLevitate then
					if not mob:isAffectedByObject(levitateSpell) then
						tes3.addSpell({reference = mobRef, spell = levitateSpell})
					end
					alignToPlayerZ(mobRef)
				end
			elseif mob:isAffectedByObject(levitateSpell) then
				alignToPlayerZ(mobRef)
				tes3.removeSpell({reference = mobRef, spell = levitateSpell})
				if mob.levitate < 0 then
					mob.levitate = 0 -- fix some glitches
				end
			end

			--- check for waterwalking
			if mob:isAffectedByObject(waterWalkSpell) then
				if mobilePlayer.waterWalking <= 0 then
					tes3.removeSpell({reference = mobRef, spell = waterWalkSpell})
				end
			elseif mobilePlayer.waterWalking == 1 then
-- comparison with standard 1 is important as it may be used as flag with different walues e.g. in guar mod
				if valid >= warpWaterWalk then
					if mob.waterWalking == 0 then
						tes3.addSpell({reference = mobRef, spell = waterWalkSpell})
					end
				end
			end

			if not mob:isAffectedByObject(burdenSpell) then

				if not warpers[mobId] then
					mobSpeed = mob.speed.current
					newMobSpeed = mobilePlayer.speed.current * 1.3
					if newMobSpeed > 200 then
						newMobSpeed = 200
					elseif newMobSpeed < 40 then
						newMobSpeed = 40
					end
					if mobSpeed < newMobSpeed then
						warpers[mobId] = mobSpeed
						tes3.setStatistic({reference = mob, name = 'speed', current = newMobSpeed})
					end
				end

				d = mobPos:distance(playerPos)
				if d > warpDist then
					-- check for levitation

					mobCell = mob.cell
					notInPlayerCell = not (mobCell == pcCell)
					ori = mobRef.orientation
					if notInPlayerCell then
						ori = ori:copy()
					else
						mobRef.facing = pcAngleZ
					end
					ori.z = pcAngleZ
					boundSize_y = mob.boundSize.y * mobRef.scale
					if boundSize_y > 64 then
						dist = dist + dd -- double for big mesh actors
					end

					newPosFound = 0
					doPackLastPlayerPositions = false
					local v, v_pos
					local size = table.size(lastPlayerPositions)
					for i = size, 1, -1 do
						v = lastPlayerPositions[i]
						if v then
							v_pos = v.pos
							if v_pos then
								if sameCellOrExterior(v.cellId, pcCell) then
									d = v_pos:distance(playerPos)
									if d >= minDist then -- too far, warp
										if d <= maxAfterWarpDist then -- only if at least half way
											if math.abs(mobilePlayer:getViewToPoint(v_pos)) > 105 then -- behind player
												if tes3.testLineOfSight({position1 = v_pos, position2 = playerPos}) then -- in a clear place
													mobPos.x = v_pos.x
													mobPos.y = v_pos.y
													mobPos.z = v_pos.z
													newPosFound = 2
													if logLevel >= 3 then
														mwse.log('%s: newPosFound = %s, dist = %s', funcPrefix, newPosFound, d)
													end
													v.pos = nil
													doPackLastPlayerPositions = true
													break
												elseif logLevel4 then
													mwse.log('%s: not tes3.testLineOfSight({position1 = v_pos, position2 = playerPos}), skip', funcPrefix)
													v.pos = nil
													doPackLastPlayerPositions = true
												end
											elseif logLevel4 then
												mwse.log('%s: math.abs(mobilePlayer:getViewToPoint(v_pos)) <= 105, skip', funcPrefix)
												v.pos = nil
												doPackLastPlayerPositions = true
											end
										elseif logLevel4 then
											mwse.log('%s: v_pos:distance(playerPos) = %s > maxAfterWarpDist = %s, skip', funcPrefix, d, maxAfterWarpDist)
										v.pos = nil
										doPackLastPlayerPositions = true
										end -- if d <= warpDist
									elseif logLevel4 then
										mwse.log('%s: v_pos:distance(playerPos) = %s < minDist = %s, skip', funcPrefix, d, minDist)
										v.pos = nil
										doPackLastPlayerPositions = true
									end -- if d >= stepDist
								else
									if logLevel >= 3 then
										mwse.log('%s: not sameCellOrExterior("%s", "%s")', funcPrefix, v.cellId, pcCell.id)
									end
									v.pos = nil
									doPackLastPlayerPositions = true
								end -- if v.cellId
							end -- if v.pos
						else
							if logLevel >= 2 then
								mwse.log('%s: not lastPlayerPositions[%s]', funcPrefix, i)
							end
							doPackLastPlayerPositions = true
						end -- if v
					end -- for i

					if doPackLastPlayerPositions then
						packLastPlayerPositions()
					end

					if newPosFound > 0 then
						if notInPlayerCell then
							if pcCell.isInterior then
								if mobCell.isOrBehavesAsExterior then
									if isStayOutside(mob) then
										newPosFound = 0
									end
								end
								if newPosFound > 0 then
									if logLevel >= 2 then
										mwse.log('%s: newPosFound = %s notInPlayerCell pcCell.isInterior tes3.positionCell({mobRef = "%s", mobPos = %s, ori.z = %s, cell = "%s"})',
											funcPrefix, newPosFound, mobRef, mobPos, ori.z, pcCell.name)
									end
									tes3.positionCell({reference = mob, position = mobPos, orientation = ori, cell = pcCell})
								end
							else
								if logLevel >= 2 then
									mwse.log('%s: newPosFound = %s notInPlayerCell tes3.positionCell({mobRef = "%s", pos = %s, ori.z = %s, cell = "%s"})', funcPrefix, newPosFound, mobRef, mobPos, ori.z, pcCell.editorname)
								end
								tes3.positionCell({reference = mob, position = mobPos, orientation = ori, cell = pcCell})
							end -- if pcCell.isInterior
						else
							if logLevel >= 2 then
								mwse.log('%s: newPosFound = %s InPlayerCell mobRef = "%s", pos = %s, ori.z = %s', funcPrefix, newPosFound, mobRef, mobPos, ori.z)
							end
						end -- if notInPlayerCell
					else -- newPosFound == 0 here
						alignToPlayerZ(mobRef)
						mobPos.x = playerPos.x - (dist * sina[angleIndex])
						mobPos.y = playerPos.y - (dist * cosa[angleIndex])
						if math.abs(mobilePlayer:getViewToPoint(mobPos)) > 105 then -- only if at player shoulders
							if tes3.testLineOfSight({position1 = mobPos, position2 = playerPos}) then -- in a clear place
								mob.position = mobPos
								newPosFound = 1
							end
						end
					end -- if newPosFound

					if newPosFound == 0 then
						if angleIndex < 5 then
							angleIndex = angleIndex + 1
						else
							angleIndex = 1
							dist = dist + dd -- if more than maxInLine one more step behind and reset angle
							if boundSize_y > 64 then
								dist = dist + dd -- double for big mesh actors
							end
							---mwse.log("angleIndex = %d, dist = %d, dd = %s", angleIndex, dist, dd)
						end -- if angleIndex < 5
					end

				end -- if d > warpDist

			end -- if not mob:isAffectedByObject(burdenSpell)

		else -- not ok
			mobSpeed = warpers[mobId]
			if mobSpeed then
				tes3.setStatistic({reference = mob, name = 'speed', current = mobSpeed})
				warpers[mobId] = nil
				doPackWarpers = true
			end
		end -- if ok
	end -- for mob

	if doPackWarpers then
		packWarpers()
	end

	local size = table.size(lastPlayerPositions)
	local i = 0
	if size >= maxSavedPlayerPositions then
		if logLevel4 then
			mwse.log('%s: %s > maxSavedPlayerPositions (%s)', funcPrefix, i, maxSavedPlayerPositions)
		end
		local v, v2
		i = 0
		for j = 2, size do
			v = lastPlayerPositions[j]
			if v then
				if v.pos then
					i = i + 1
					if logLevel4 then
						if i == 1 then
							v2 = lastPlayerPositions[i]
							mwse.log('%s: 1 lastPlayerPositions[%s] = {cellId = "%s", pos = %s} removed',
								funcPrefix, i, v2.cellId, v2.pos)
						end
						mwse.log('%s: 2 lastPlayerPositions[%s] = {cellId = "%s", pos = %s} added',
							funcPrefix, i, v.cellId, v.pos)
					end
					lastPlayerPositions[i] = v
				end
			end
		end
	end
	local good = false
	if i > 1 then
		local prevPP = lastPlayerPositions[i]
		if prevPP then
			local lastPos = prevPP.pos
			if lastPos then
				d = playerPos:distance(lastPos)
				if d >= stepDist then
					if d <= warpDist then
						good = true
						if logLevel >= 3 then
							mwse.log('%s: good lastPos: %s, playerPos: %s, playerPos:distance(lastPos) = %s', funcPrefix, lastPos, playerPos, d)
						end
					end
				end
			end
		end
	else
		good = true
	end
	if good then
		i = i + 1
		if logLevel4 then
			mwse.log('%s: 3 lastPlayerPositions[%s] = {cellId = "%s", pos = %s}', funcPrefix, i, pcCell.id, playerPos)
		end
		-- store good previous player position
		local cid = ''
		if pcCell.isInterior then
			cid = pcCell.id
		end
		lastPlayerPositions[i] = {cellId = cid, pos = playerPos:copy()} -- important to use a :copy() here
	end
end


local travelStopped = false -- set in travelStop(), used in timedTravelProcess to skip

local function startMoveTravellers()
	travelRadStep = math.rad(170 / numTravellers)
	if logLevel >= 2 then
		mwse.log("%s: startMoveTravellers() numTravellers = %s", modPrefix, numTravellers)
	end
	movingTravellers = true
	if event.isRegistered('simulate', moveTravellers) then
		return
	end
	event.register('simulate', moveTravellers)
end


local function stopMoveTravellers()
	if logLevel >= 2 then
		mwse.log("%s: stopMoveTravellers()", modPrefix)
	end
	movingTravellers = false
	if event.isRegistered('simulate', moveTravellers) then
		event.unregister('simulate', moveTravellers)
	end
end

local tes3_effect_chameleon = tes3.effect.chameleon
local tes3_effect_invisibility = tes3.effect.invisibility

local function resetTransparency(mob)
	tes3.applyMagicSource({ -- apply a short chameleon/invisibility to try and fix appearance sometimes buggy after travelling with setinvisible
		reference = mob,
		name = "Negate Invisibility",
		effects = {  {id = tes3_effect_invisibility, duration = 1}, {id = tes3_effect_chameleon, duration = 2, min = 1, max = 1}, },
		bypassResistances = true
	})
---@diagnostic disable-next-line: redundant-parameter
	local mobHandle = tes3.makeSafeObjectHandle(mob)
	timer.start({duration = 2.75,
		callback = function ()
			if not mobHandle then
				return
			end
			if not mobHandle:valid() then
				return
			end
			local mob1 = mobHandle:getObject()
			if not mob1 then
				return
			end
			mob1.invisibility = 0
---@diagnostic disable-next-line: undefined-field
			mob1:updateOpacity()
		end
	})
end

local function travelEnd()
	if logLevel >= 3 then
		mwse.log("%s: travelEnd()", modPrefix)
	end
	stopMoveTravellers()
	local ability, mob, mobRef
	if travelType > 0 then
		local tp = travelParams[travelType]
		ability = tp.spell
	end
	for id, t in pairs(travellers) do
		if t then -- needed safety
			mob = t.mob
			if mob then
				mobRef = mob.reference
				if mobRef then
					if ability then
						if logLevel >= 2 then
							mwse.log("%s: tes3.removeSpell({reference = %s, spell = %s}), invisibility = %s, acrobatics = %s, nospread = %s",
								modPrefix, id, ability, t.inv, t.acro, t.ns)
						end
						tes3.removeSpell({reference = mob, spell = ability}) -- remove travelling spell
						---mwscript.removeSpell({reference = mob, spell = ability}) -- remove travelling spell
					end
					resetTransparency(mob)
					mob.invisibility = t.inv -- reset invisibility
					mob.blind = 0 -- oh well I guess curing them from blindness anyway is not bad
					mob:updateOpacity()
					mob.acrobatics.current = t.acro -- reset acrobatics
					---mob.movementCollision = true
					if t.ns > 0 then
						local context = mobRef.context
						if context then
							if context.nospread then
								if logLevel >= 3 then
									mwse.log("%s: %s nospread reset to 0", modPrefix, mobRef.id)
								end
								context.nospread = 0
							end
						end
					end
					tes3.setAIFollow({reference = mob, target = player, reset = true})
				end
			end
		end
	end
	resetTransparency(mobilePlayer)
	cleanTravellers()
	travelType = 0
	initScenicTravelAvailable()
	travelStopped = false
end

local function travelStop()
	if logLevel >= 2 then
		mwse.log("%s: travelStop()", modPrefix)
	end
	local ppos = player.position:copy()
	local pori = player.orientation
	local pcell = player.cell
	local cellId = pcell.id
	local doLog = logLevel >= 2
	for id, t in pairs(travellers) do
		if t then -- needed safety
			if doLog then
				mwse.log("%s: tes3.positionCell({reference = %s, cell = %s})", modPrefix, id, cellId)
			end
			tes3.positionCell({reference = t.mob.reference, position = ppos, orientation = pori, cell = pcell}) -- ensure followers move to player cell
		end
	end
	-- small delay before removing spells/resetting acrobatics so followers are still positioned behind player by travel script
	-- and they don't get damaged from falling
	travelStopped = true

	timer.start({duration = 1, callback = 'ab01SmartCompTravelEnd'})
end

local function timedTravelProcess()
	if travelStopped then
		return
	end
	local boDest = 0
	if ab01boDestGlob then
		boDest = roundInt(ab01boDestGlob.value)
	end
	local ssDest = 0
	if ab01ssDestGlob then
		ssDest = roundInt(ab01ssDestGlob.value)
	end
	local goDest = 0
	if ab01goDestGlob then
		goDest = roundInt(ab01goDestGlob.value)
	end
	local stop = false
	if travelType == 1 then -- boat
		if boDest <= 0 then
			if ab01boDest then
				if ab01boDest > 0 then
					stop = true
				end
			end
		end
	elseif travelType == 2 then -- strider
		if ssDest <= 0 then
			if ab01ssDest then
				if ab01ssDest > 0 then
					stop = true
				end
			end
		end
	elseif travelType == 3 then -- gondola
		if goDest <= 0 then
			if ab01goDest then
				if ab01goDest > 0 then
					stop = true
				end
			end
		end
	end

	if stop then
		travelStop()
		return
	end

	if travelType == 0 then
		if ab01boDest then
			if not (boDest == ab01boDest) then
				ab01boDest = boDest
				travelType = 1 -- boat
			end
		end
	end
	if travelType == 0 then
		if ab01ssDest then
			if not (ssDest == ab01ssDest) then
				ab01ssDest = ssDest
				travelType = 2 -- strider
			end
		end
	end
	if travelType == 0 then
		if ab01goDest then
			if not (goDest == ab01goDest) then
				ab01goDest = goDest
				travelType = 3 -- gondola
				ab01goAngleGlob.value = 10000 -- reset it
			end
		end
	end

	if travelType == 0 then
		-- invalid
		return
	end

	local dist, id
	local maxDist = 8192
	local playerPos = player.position
	numTravellers = 0
	local mob, mobRef, tns, traveller, spread, nospread
	local friendlyActors = mobilePlayer.friendlyActors
	for i = 1, #friendlyActors do
		mob = friendlyActors[i]
		mobRef = mob.reference
		if mob.actorType == tes3_actorType_npc then
			if isValidScenicFollower(mob) then
				spread, nospread = getSpreads(mob)
				tns = 0
				if spread then -- companion script already providing scenic travelling
					if nospread then
						tns = 1
						mobRef.context.nospread = 1 -- set nospread to 1 in the local companion script so vanilla travelling code is skipped
					end
				end

				dist = mob.position:distance(playerPos)
				if dist <= maxDist then
					id = mobRef.id
					traveller = travellers[id]
					if (not traveller)
					or (not traveller.monile) then
						tes3.setAIWander({reference = mob, range = 0, idles = {30, 20, 10, 0, 0, 0, 0, 0}, reset = true}) -- hopefully local NPC script will stop warping in wander mode
						if logLevel >= 2 then
							mwse.log("%s: %s, dist = %s added to travellers", modPrefix, id, dist)
						end
						travellers[id] = {mob = mob, inv = mob.invisibility, acro = mob.acrobatics.current, ns = tns} -- store mob, invisibility, acrobatics, nospread of follower
						numTravellers = numTravellers + 1
					end
				end
			end
		end
	end
	if numTravellers > 0 then
		local ability = travelParams[travelType].spell
		local mob1
		for id2, t in pairs(travellers) do
			if t then -- needed safety
				mob1 = t.mob
				if logLevel >= 2 then
					mwse.log("%s: mwscript.addSpell({reference = %s, spell = %s}), invisibility = 1, acrobatics = 200, blind = 100", modPrefix, id2, ability)
				end
				---mwscript.addSpell({reference = mob, spell = ability})
				tes3.addSpell({reference = mob1, spell = ability})
				mob1.invisibility = 1 -- setInvisible to avoid aggro cliffracers
				mob1.blind = 100 -- blind to avoid aggro
				mob1.acrobatics.current = 200 -- high acrobatics to avoid damage if cell changed
				---mob1.movementCollision = false -- this works better especially with multiple guards but not while levitating
				mob1.facing = mobilePlayer.facing
				tes3.playAnimation({reference = mob1.reference, group = 0}) -- reset animation
			end
		end
		startMoveTravellers()
	end
end

local function fixWeight(w)
	if w then
		if w < 0 then
 -- try to avoid negative weights, could be fake items
 -- from mods trying to fix player negative encumbrance
			w = 10000000
		else
			if w < 0.0001 then
				w = 0.0001
			else
				w = math.round(w, 4)
			end
		end
	else
		w = 0.0001
	end
	return w
end

local function getRefWeight(mobRef)
	local weight = mobRef.baseObject.weight
	weight = fixWeight(weight)
	local count = mobRef.stackSize
	if not count then
		count = 1
	end
	weight = weight * count
	return weight
end

local function isLootable(obj, script)
	local skip = false
	local objType = obj.objectType
	--[[
	-- not sure how to use testActionFlag without a proper reference
	if not mobRef:testActionFlag(tes3_actionFlag_useEnabled) then
		return -- onactivate block present, skip disabling event on scripted activate
	end
	]]
	if not script then
		if type(obj) == 'table' then
-- hopefully this will avoid those pesky WARNING: An unknown object type was identified with a virtual table address of
			if logLevel >= 3 then
				mwse.log('%s: isLootable("%s") type(obj) == "table", obj.script = "%s"', obj.id, obj.script)
			end
			script = obj.script
		end
	end
	if script then
		local s = script.context
		if s then
			s = tostring(s) -- convert from script opcodes?
			if s then
				s = string.lower(s)
				if string.find(s, 'onactivate', 1, true) then
					skip = true
					if objType == CONT_T then
						if obj.organic then
							skip = false
						end
					end
				end
			end
		end
	end
	if skip then
		if logLevel >= 3 then
			mwse.log("%s: isLootable('%s') false, scripted with OnActivate", modPrefix, obj.id)
		end
		return false -- scripted with OnActivate, not lootable
	end
	if objType == LIGH_T then -- not scripted but...
		if obj.canCarry then
			if obj.isOffByDefault then
				if obj.radius < 17 then
					return false -- light may be used as icon
				end
			end
		end
	end
	return true
end

local function checkCrime(activatorRef, targetRef, targetValue)
	if tes3.hasOwnershipAccess({target = targetRef}) then
		return -- skip if player has ownership
	end
	if tes3.hasOwnershipAccess({reference = activatorRef, target = targetRef}) then
		return -- skip if actor has ownership
	end
	local mob = activatorRef.mobile
	---assert(mob)
	local hidden = mob.chameleon---.current
	if mob.actorType >= tes3_actorType_npc then -- 0 = creature, 1 = NPC, 2 = player
		hidden = hidden + mob.sneak.current
	end
	local roll = math.random(1, 100)
	if hidden >= roll then
		return -- skip if not detected
	end

	local totalValue
	if targetValue then
		totalValue = targetValue
	else
		local value = targetRef.baseObject.value
		if not value then
			value = 1
		end
		local count = targetRef.stackSize
		if not count then
			count = 1
		end
		totalValue = value * count
	end
	local owner = tes3.getOwner({reference = targetRef})
	timer.frame.delayOneFrame(
		function()
			tes3.triggerCrime({type = tes3.crimeType.theft, victim = owner, value = totalValue})
		end
	)
end

local MWCAloaded = tes3.getFileExists("MWSE\\mods\\MWCA\\main.lua")
local GHerbLoaded = tes3.getFileExists("MWSE\\mods\\graphicHerbalism\\main.lua")

-- borrowed from Graphic Herbalism
-- Update and serialize the reference's HerbalismSwitch.
-- valid indexes are: 0 = default, 1 = picked, 2 = spoiled
local function updateHerbalismSwitch(mobRef, index)
	if logLevel >= 3 then
		mwse.log("%s: updateHerbalismSwitch(mobRef=%s, index=%s)", modPrefix, mobRef.id, index)
	end
	-- valid indices are: 0=default, 1=picked, 2=spoiled
	local sceneNode = mobRef.sceneNode
	if not sceneNode then
		return false
	end
	local switchNode = sceneNode:getObjectByName("HerbalismSwitch")
	if not switchNode then
		return false
	end
	-- bounds check in case mesh does not implement a spoiled state
	index = math.min(index, #switchNode.children - 1)
	switchNode.switchIndex = index
	-- only serialize if non-zero state (e.g. if picked or spoiled)

	---mobRef.data.GH = (index > 0) and index or nil
	-- now I will rewrite this in a clear way without and/or shortcuts. /abot
	if index then
		if index <= 0 then
			index = nil
		end
	end
	if logLevel >= 3 then
		mwse.log("%s: updateHerbalismSwitch() mobRef.data.GH = %s)", modPrefix, index)
	end
	mobRef.data.GH = index
	return true
end

local skipPlayerAltActivate = false -- set/reset to make player unable to Alt+activate for a short time

local function setSkipPlayerAltActivate()
	if skipPlayerAltActivate then
		return
	end
	skipPlayerAltActivate = true
	timer.start({ duration = 2.5, type = timer.real, -- important to give enough duration else it may crash
		callback = function ()
			skipPlayerAltActivate = false
		end}
	)
end

local function doActivate(activatorRef, targetRef)
	if logLevel >= 3 then
		mwse.log("%s: doActivate(activatorRef=%s, targetRef=%s)", modPrefix, activatorRef.id, targetRef.id)
	end
	if targetRef then
		activatorRef:activate(targetRef)
	end
end

--[[
local function reevaluateEquipment(mob)
	if not mob then
		return
	end
	if tes3.mobilePlayer == mob then
		return
	end
	local actorType = mob.actorType -- 0 = creature, 1 = NPC, 2 = player
	local ob = mob.object
	if (actorType == tes3_actorType_npc)
	or (
		(actorType == tes3_actorType_creature) -- creature
		and ob.usesEquipment -- biped
	) then
		timer.delayOneFrame(
			function ()
				if ob then
					---if logLevel >= 3 then
						---mwse.log("%s: before %s:reevaluateEquipment()", modPrefix, ob.id)
					---end
					ob:reevaluateEquipment() -- is this thing crashing? nope somewhere else
					---if logLevel >= 3 then
						---mwse.log("%s: after %s:reevaluateEquipment()", modPrefix, ob.id)
					---end
				end
			end
		)
	end
end
]]

local niceLootMsg = {
[["Hey, some %s!"]],
[["I found some %s there!"]],
[["Let's see... great, some %s."]],
[["Wow, I found some %s."]],
[["Hmm... more %s."]],
[["There! some %s."]],
[["Some %s. How typical."]],
[["Some %s. How quaint."]],
[["Oh, joy. Some more %s."]],
[["Great, some %s!"]],
[["Right, I was just looking for some %s."]],
[["Hey, look what I've found, some %s!"]],
[["%s. I think we could sell some!"]],
[["Some %s. Could I keep this for myself?"]],
[["%s. I like that."]],
[["Some %s. The more, the better."]],
[["Do you like %s?"]],
[["And what do we have here? Some %s!"]],
[["Oh. It's been a long time since I've seen any %s."]],
[["%s. I want more!"]],
}

local function strip(s)
	return s:gsub('!$', '')
end

local function triggerActivate(activatorRef, targetRef)
	if logLevel >= 3 then
		mwse.log("%s: triggerActivate(activatorRef=%s, targetRef=%s)", modPrefix, activatorRef.id, targetRef.id)
	end
	event.trigger('activate', {activator = activatorRef, target = targetRef}, {filter = targetRef})
end


local function companionLootContainer(companionRef, targetRef)
	if logLevel >= 3 then
		mwse.log("%s: companionLootContainer(companionRef=%s, targetRef=%s)", modPrefix, companionRef.id, targetRef.id)
	end
	local companionMob = companionRef.mobile
	---assert(companionMob)
	local targetObj = targetRef.object
	local targetName = targetObj.name
	local inventory = targetObj.inventory

	if targetObj.organic
	or (not targetObj.isInstance) then
		local cloned = targetRef:clone() -- returns a boolean, autoupdates the reference
		if cloned then -- resolve container contents
			targetObj = targetRef.object --- important again to refresh it!!!
			targetName = targetObj.name
			inventory = targetObj.inventory
		else
			if logLevel > 0 then
				mwse.log("%s: companionLootContainer(companionRef = %s, targetRef = %s) targetRef:clone() failed", modPrefix, companionRef.id, targetRef.id)
			end
		end
	end
	if inventory then
		inventory:resolveLeveledItems()
	end

	local activatorName = companionRef.object.name
	if tes3.getLocked({reference = targetRef}) then
		tes3.playSound({sound = 'LockedChest', reference = targetRef})
		tes3.messageBox("%s: \"This %s is locked.\"", activatorName, targetName)
		return
	end

	if not inventory then
		return
	end

	-- transfer inventory to companion
	local vwMax = 0
	local niceLoot
	local items2transfer = {}
	local lootedCount = 0
	local inventoryCount = 0
	local encumb = companionMob.encumbrance
	local capacity = encumb.base - encumb.current
	local count, newCapacity, stackObj, value, weight, vw
	---local ab01goldWeight = tes3.getGlobal('ab01goldWeight')
	local variables, script

	local items = inventory.items
	local stack

	local function processStack(i)
		stack = items[i]
		if not stack then
			return
		end
		stackObj = stack.object
		if logLevel >= 2 then
			mwse.log("%s: companionLootContainer item = %s", modPrefix, stackObj.id)
		end
		inventoryCount = inventoryCount + 1
		script = nil
		variables = stack.variables
		if variables then
			script = variables.script
		end
		if not isLootable(stackObj, script) then
			return
		end
		if logLevel >= 3 then
			mwse.log("%s: companionLootContainer item = %s lootable", modPrefix, stackObj.id)
		end
		value = stackObj.value
		if not value then -- no value happens /abot
			return
		end
		weight = stackObj.weight
		--[[
		if string.lower(stackObj.id) == 'gold_001' then
			weight = 0.0001
			if ab01goldWeight then
				if ab01goldWeight > 0 then
					weight = ab01goldWeight
				end
			end
		end
		]]
		count = stack.count
		if not count then
			return
		end
		weight = fixWeight(weight)
		if logLevel >= 2 then
			mwse.log("%s: companionLootContainer item = %s, value = %s, weight = %s, count = %s", modPrefix, stackObj.id, value, weight, count)
		end
		vw = value/weight
		if (config.alwaysLootOrganic
		and targetObj.organic)
		or (vw >= config.minValueWeightRatio) then
			count = math.abs(count)
			weight = weight * count
			newCapacity = capacity - weight
			if (newCapacity >= 1 )
			or (config.allowLooting > 1) then
				if vw > vwMax then
					vwMax = vw
					niceLoot = stackObj.name
				end
				table.insert(items2transfer, stack)
				lootedCount = lootedCount + 1
				capacity = newCapacity
			end -- if (capacity
		end -- if (config
	end

	--- for _, stack in pairs(inventory) do -- needs pairs!
	for i = 1, #items do
		processStack(i)
	end -- for

	local companionActorType = companionMob.actorType
	local totalValue = 0
	local num

	local function skipActivateWhileTransfering()
		return false
	end

	if lootedCount > 0 then
		local settings = {priority = 100002}
		event.register('activate', skipActivateWhileTransfering, settings)
		for i = 1, #items2transfer do
			stack = items2transfer[i]
			stackObj = stack.object
			num = math.abs(stack.count)
			totalValue = (stackObj.value * num) + totalValue
			if logLevel >= 2 then
				mwse.log('%s: companionLootContainer tes3.transferItem({from = "%s", to = "%s", item = "%s", itemData = %s, count = %s, playSound = false, updateGUI = false, reevaluateEquipment = false)',
					modPrefix, targetRef.id, companionRef.id, stackObj.id, stack.itemData, num)
			end
			tes3.transferItem({from = targetRef, to = companionRef, item = stackObj, itemData = stack.itemData,
				count = num, playSound = false, updateGUI = false, reevaluateEquipment = false})
		end

		if companionActorType == tes3_actorType_npc then -- NPC
			if niceLoot then
				---tes3.messageBox(table.choice(niceLootMsg), strip(niceLoot))
				tes3.messageBox(niceLootMsg[math.random(#niceLootMsg)], strip(niceLoot))
			end
			local i = math.random(100)
			local tnam = strip(targetName)
			if i > 75 then
				tes3.messageBox("%s:\n\"Let's see if we can find some decent loot with that %s.\"", activatorName, tnam)
			elseif i > 50 then
				tes3.messageBox("%s:\n\"%s, let's see what can be found with that %s.\"", activatorName, player.object.name, tnam)
			elseif i > 25 then
				tes3.messageBox("%s:\n\"All right, I'll check that %s.\"", activatorName, tnam)
			else
				tes3.messageBox("%s:\n\"I'll take care of this %s.\"", activatorName, tnam)
			end
		end

		tes3.updateInventoryGUI({reference = targetRef})
		tes3.updateMagicGUI({reference = targetRef})
		tes3.updateInventoryGUI({reference = companionRef})
		tes3.updateMagicGUI({reference = companionRef})

		tes3.playSound({sound = 'Item Misc Up', reference = companionRef})
		---reevaluateEquipment(companionMob)

		event.unregister('activate', skipActivateWhileTransfering, settings)

	elseif companionActorType == tes3_actorType_npc then
		local i = math.random(100)
		local playerName = player.object.name
		if capacity >= 1 then
			local tnam = strip(targetName)
			if i > 75 then
				tes3.messageBox("%s:\n\"Hmmm... nothing good with that %s.\"", activatorName, tnam)
			elseif i > 50 then
				tes3.messageBox("%s:\n\"%s, I think there is nothing more worth taking from that %s.\"", activatorName, playerName, tnam)
			elseif i > 25 then
				tes3.messageBox("%s:\n\"No good loot in the %s.\"", activatorName, tnam)
			else
				tes3.messageBox("%s:\n\"Hmmm... no luck this time.\"", activatorName)
			end
		else
			if i > 75 then
				tes3.messageBox("%s:\n\"I can't carry more than this!\"", activatorName)
			elseif i > 50 then
				tes3.messageBox("%s:\n\"%s, I am not your beast of burden!\"", activatorName, playerName)
			elseif i > 25 then
				tes3.messageBox("%s:\n\"Sorry %s but... no, I am already carrying a lot of things.\"", activatorName, playerName)
			else
				tes3.messageBox("%s:\n\"No, that's too heavy for me.\"", activatorName)
			end
		end
	end

	if targetObj.objectType == CONT_T then
		if targetObj.organic then
			if GHerbLoaded then -- Graphic Herbalism loaded
				local gHerb = false
				if not targetObj.script then
					local id = string.lower(targetObj.id)
					if not string.find(id, 'chest', 1, true) then
						-- valid indexes are: 0 = default, 1 = picked, 2 = spoiled
						if lootedCount >= inventoryCount then
							gHerb = updateHerbalismSwitch(targetRef, 2) -- spoiled
						elseif lootedCount > 0 then
							gHerb = updateHerbalismSwitch(targetRef, 1) -- picked
						end
					end
				end -- if not targetObj.script
				if gHerb then
					if lootedCount >= inventoryCount then
						targetRef.isEmpty = true
						targetObj.modified = false
					end
				end
			end -- if GHerbLoaded
		elseif MWCAloaded then -- Morrowind Containers Animated loaded
			---mwse.log(">MWCAloaded")
			-- try and trigger animated container opening
			---triggerActivate(companionRef, targetRef)
			if logLevel >= 3 then
				mwse.log('%s: companionLootContainer() MWCAloaded triggerActivate(%s, %s)', modPrefix, player, targetRef)
			end
			setSkipPlayerAltActivate()
			triggerActivate(player, targetRef)
			--- doActivate(player, targetRef) -- nope crashing
		end
	end

	---targetObj:onInventoryClose(targetRef)
	targetRef:onCloseInventory()
	checkCrime(companionRef, targetRef, totalValue)

	if logLevel >= 3 then
		mwse.log('%s: companionLootContainer() after checkCrime(companionRef = %s, targetRef = %s, totalValue = %s)', modPrefix, companionRef.id, targetRef.id, totalValue)
	end

end


local function getThiefTool(actorRef, objectType)
	local inventory = actorRef.object.inventory
	---assert(inventory)
	if inventory then
		local obj, iData, condition
		---for _, stack in pairs(inventory) do
		local stack
		local items = inventory.items
		for i = 1, #items do
			stack = items[i]
			---assert(stack)
			obj = stack.object
			---assert(obj)
			---if obj then
			if obj.objectType == objectType then
				if obj.name then
					if not string.multifind(string.lower(obj.name), {'compass','sextant'}, 1, true) then
						iData = stack.itemData
						if iData then
							condition = iData.condition
							if condition then
								if condition > 0 then
									condition = condition - 1
									stack.itemData.condition = condition -- decrease item condition as it would be be used
									return stack
								else
									---mwscript.removeItem({reference = actorRef, item = obj, count = 1}) -- removes item with 0 uses left
									tes3.removeItem({reference = actorRef, item = obj, count = 1}) -- removes item with 0 uses left
									return getThiefTool(actorRef, objectType) -- look for another one
								end
							end
						else -- it is an unused one
							return stack
						end
					end
				end
			end
			---end
		end
	end
	local s
	if objectType == LKPK_T then
		s = 'lockpick'
	else
		s = 'probe'
	end
	tes3.messageBox("%s:\n\"I don't have a %s.\"", actorRef.object.name, s)
	return nil
end

local function getLockpick(actorRef)
	return getThiefTool(actorRef, LKPK_T)
end

local function getProbe(actorRef)
	return getThiefTool(actorRef, PROB_T)
end

local function sneakForSec(mob, seconds)
	if not (mob.actorType == tes3_actorType_npc) then
		return
	end
	if not mob.isSneaking then
		mob.forceSneak = true
		timer.start({duration = seconds, callback = function ()
			if mob then
				mob.forceSneak = false
			end
		end})
	end
end

local tes3_effect_open = tes3.effect.open

local function getOpenSpell(actorRef)
	local spells = actorRef.object.spells
	if not spells then
		return nil, nil
	end
	local t = {}
	local effectIndex, effect, magnitude, chance, mXc
	local found = false

	local funcPrefix = string.format("%s getOpenSpell()", modPrefix)

	for _, spl in pairs(spells) do
		---mwse.log("spl = %s", spl.id)
		if spl.isActiveCast or spl.alwaysSucceeds then
			effectIndex = spl:getFirstIndexOfEffect(tes3_effect_open)
			if effectIndex then
				if effectIndex >= 0 then -- returns -1 if not found
					---mwse.log("effectIndex = %s", effectIndex)
					effectIndex = effectIndex + 1
					effect = spl.effects[effectIndex]
					magnitude = math.floor((effect.min + effect.max) * 0.5)
					if spl.alwaysSucceeds then
						chance = 100
					elseif effect.cost > 0 then
						chance = spl:calculateCastChance({checkMagicka = config.checkMagicka, caster = actorRef})
					else
						chance = 100
					end
					mXc = magnitude * chance
					if logLevel >= 3 then
						mwse.log("%s: magnitude = %s, chance = %s, magnitude * chance = %s", funcPrefix, magnitude, chance, mXc)
					end
					if mXc >= 60 then
						table.insert(t, {spell = spl, magnitudeXchance = mXc})
						found = true
					end
				end
			end
		end
	end
	if found then
		 -- sort by descending cost * chance
		table.sort(t, function(a,b) return a.magnitudeXchance > b.magnitudeXchance end)
		local t1 = t[1]
		local spell = t1.spell
		if logLevel >= 2 then
			mwse.log('%s: "%s" using spell "%s" ("%s")', funcPrefix, actorRef.id, spell.id, spell.name)
		end
		return t1.spell, t1.magnitudeXchance
	end
	return nil, nil
end

local function tryUnlock(npcRef, targetRef)
	local funcPrefix = string.format("%s tryUnlock()", modPrefix)
	if logLevel >= 2 then
		mwse.log("%s: npcRef=%s, targetRef=%s)", funcPrefix, npcRef.id, targetRef.id)
	end
	local lockNode = targetRef.lockNode
	if not lockNode then
		return true
	end
	local npcMob = npcRef.mobile
	if not npcMob then
		return false
	end
	if not (npcMob.actorType == tes3_actorType_npc) then
		return false
	end
	sneakForSec(npcMob, 3)
	local npcName = npcRef.object.name
	local targetName = targetRef.object.name
	local tnam = strip(targetName)
	local key = lockNode.key
	if key then
		---if mwscript.getItemCount({reference = npcRef, item = key}) > 0 then
		if npcRef.object.inventory:contains(key.id) then
			if lockNode.trap then
				lockNode.trap = nil
			end
			if lockNode.locked then
				tes3.unlock({reference = targetRef})
				tes3.playSound({sound = 'chest open', reference = targetRef})
				tes3.messageBox("%s:\n\"I opened the %s with the %s.\"", npcName, tnam, strip(key.name))
			end
			return true
		end
	end

	local agility = npcMob.agility.current
	local luck = npcMob.luck.current
	local security = npcMob.security.current
	local stack, quality
	if config.allowProbes then
		if lockNode.trap then
			stack = getProbe(npcRef)
			if stack then
				quality = stack.object.quality
				if not quality then
					quality = 0.25
				end
				local fTrapCostMult = tes3gmst_fTrapCostMult.value
				if not fTrapCostMult then
					fTrapCostMult = 0
				end
				local trapSpellPoints = lockNode.trap.magickaCost
				if not trapSpellPoints then
					trapSpellPoints = 0
				end
				local x = (0.2 * agility) + (0.1 * luck) + security
				x = x * quality
				x = x + (fTrapCostMult * trapSpellPoints) -- note that if not 0, fTrapCostMult should be negative (usually -1)
				if x > 0 then
					local roll = math.random(1, 100)
					if roll <= x then
						lockNode.trap = nil
						tes3.playSound({sound = 'Disarm Trap', reference = targetRef})
						tes3.messageBox("%s:\n\"I managed to disarm the trapped %s with a probe!\"", npcName, tnam)
					else
						tes3.playSound({sound = 'Disarm Trap Fail', reference = targetRef})
						tes3.messageBox("%s:\n\"I failed to disarm the trapped %s.\"", npcName, tnam)

						if not lockNode.locked then
							npcRef:activate(targetRef) -- trigger the trap!?
						end
					end
				else
					tes3.messageBox("%s:\n\"I can't disarm the trapped %s.\"", npcName, tnam)
				end
			end
		end
	end

	if config.allowLockpicks then
		if lockNode.locked then
		-- lockNode.level (number) The level of the lock.
			stack = getLockpick(npcRef)
			if stack then
				quality = stack.object.quality
				if not quality then
					quality = 0.25
				end
				local fPickLockMult = tes3gmst_fPickLockMult.value
				if not fPickLockMult then
					---assert(fPickLockMult)
					fPickLockMult = -1
				end
				local lockStrength = lockNode.level
				---assert(lockStrength)
				if lockStrength == 0 then
					lockStrength = 1000000 --  locked 0 things should be impossible to unlock
				end
				local x = (0.2 * agility) + (0.1 * luck) + security
				x = x * quality
				x = x + (fPickLockMult * lockStrength)
				if x > 0 then
					local roll = math.random(1, 100)
					if roll <= x then
						tes3.unlock({reference = targetRef})
						tes3.playSound({sound = 'Open Lock', reference = targetRef})
						tes3.messageBox("%s:\n\"I managed to unlock that %s.\"", npcName, targetName)
					else
						tes3.playSound({sound = 'LockedChest', reference = targetRef})
						tes3.messageBox("%s:\n\"I failed to unlock that %s.\"", npcName, targetName)
					end
				else
					tes3.messageBox("%s:\n\"I can't unlock that %s.\"", npcName, targetName)
				end
			end
		end
	end

	if config.allowMagic then
		if lockNode.locked then
			local spl, magnitudeXchance = getOpenSpell(npcRef)
			if spl and magnitudeXchance then
				tes3.cast({reference = npcRef, target = targetRef, spell = spl, instant = false, alwaysSucceeds = false})
			end
		end-- if lockNode.locked
	end -- if config.allowMagic

	if lockNode.locked
	or lockNode.trap then
		return false
	end
	return true
end


local function tryCompanionThievery(companionRef, targetRef)
	if logLevel >= 2 then
		mwse.log("%s: tryCompanionThievery(companionRef=%s, targetRef=%s)", modPrefix, companionRef.id, targetRef.id)
	end
	local unlocked = tryUnlock(companionRef, targetRef)
	if unlocked then
		local objType = targetRef.object.objectType
		if objType == CONT_T then
			if config.allowLooting > 0 then
				setSkipPlayerAltActivate()
				companionLootContainer(companionRef, targetRef)
			end
		elseif objType == DOOR_T then
			if not targetRef.destination then
				doActivate(lastCompanionRef, targetRef)
			end
		end
	end
end

local function canWalkTo(actorRef, targetRef)

	if not tes3.testLineOfSight({ reference1 = actorRef, reference2 = targetRef }) then
		return false
	end

	local rayStartPos = actorRef.position:copy()
	rayStartPos.z = rayStartPos.z + 32
	local targetPos = targetRef.position:copy()
	local bounds = targetRef.object.boundingBox
	if bounds then
		targetPos.z = (targetRef.scale * (bounds.max.z - bounds.min.z) * 0.5) + targetPos.z
	end
	local rayDir = targetPos - rayStartPos
---@diagnostic disable-next-line: assign-type-mismatch
	local rayHit = tes3.rayTest{ position = rayStartPos, direction = rayDir:normalized(),
		maxDistance = config.maxDistance, ignore = {actorRef, player} }
	if rayHit then
		if targetRef == rayHit.reference then
			return true -- actorRef should be able to walk to targetRef
		end
	end
	return false
end

local function takeMessageBox(activatorRef, targetRef)
	local targetName = targetRef.object.name
	---assert(targetName)
	if targetName == '' then
		return
	end
	local activatorName = activatorRef.object.name
	local activatorMob = activatorRef.mobile
	local activatorActorType = activatorMob.actorType
	local targetType = targetRef.object.objectType
	local s1 = ''
	if targetType == CONT_T then
		s1 = 'care of '
	end
	local s2
	if activatorActorType == tes3_actorType_npc then
		s1 = 'care of '
		s2 = "%s:\n\"I'll take %sthe %s.\""
	elseif activatorActorType == tes3_actorType_creature then
		s1 = 'care of '
		s2 = "%s\ntakes %sthe %s."
	end
	if s2 then
		local s3 = strip(targetName)
		if logLevel >= 2 then
			mwse.log(s2, activatorName, s1, s3)
		end
		tes3.messageBox(s2, activatorName, s1, s3)
	end
end

local function deleteReference(mobRef)
	if mobRef.itemData then
		mobRef.itemData = nil
	end
	---mwscript.disable({reference = mobRef, modify = true})
	mobRef:disable()
	mobRef.position.z = mobRef.position.z + 16384 -- move after disable to try and update lights (and maybe get less problems with collisions when deleting?)
	---mwscript.enable({reference = mobRef, modify = true}) -- enable it after moving to hopefully refresh collision
	mobRef:enable()
	---mwscript.disable({reference = mobRef, modify = true}) -- finally disable
	mobRef:disable()
	local secDelay
	if mobRef.object.sourceMod then
		secDelay = 0.5 -- not a spawned thing, safe to setdelete immediately after movement
	else
		secDelay = 7.5 -- big delay, should be safe even for animated/playing sound spawned items
	end
	local refHandle = tes3.makeSafeObjectHandle(mobRef)
	timer.start({duration = secDelay,
		callback = function ()
			if not refHandle then
				return
			end
			if not refHandle:valid() then
				return
			end
			local r = refHandle:getObject()
			if not r then
				return
			end
			if r.disabled then
				---mwscript.setDelete({reference = r, delete = true})
				r:delete()
			end
		end
	})
end

local function takeItem(destActorRef, targetRef)
	local obj = targetRef.object
	local data = targetRef.itemData
	local num = 1
	if data then
		if data.count then
			num = math.abs(data.count)
		end
	end
	takeMessageBox(destActorRef, targetRef)

	checkCrime(destActorRef, targetRef)
	tes3.playSound({reference = destActorRef, sound = 'Item Book Up'})

	---tes3.addItem({reference = destActorRef, item = obj, itemData = data, count = num}) -- still crashing
---@diagnostic disable-next-line: deprecated
	mwscript.addItem({reference = destActorRef, item = obj.id, count = num})
	deleteReference(targetRef)
end

local function multifind2(s1, s2, pattern)
	return string.multifind(s1, pattern, 1, true)
	or string.multifind(s2, pattern, 1, true)
end

local function mayBeRevolvingDoor(doorRef, doorObj)
	local doorDest = doorRef.destination
	if doorDest then
		return false
	end
	if doorObj.script then
		return false
	end
	if tes3.getLocked({reference = doorRef}) then
		return false
	end
	if doorObj.persistent then
		return false
	end
	local doorCell = doorRef.cell
	if not doorCell then
		return false
	end
	if doorCell.isInterior then
		return false
	end
	local lockNode = doorRef.lockNode
	if lockNode then
		if lockNode.level then
			if lockNode.level == 1 then -- door marked as openable
				return false
			end
		end
	end
	local doorId = string.lower(doorObj.id)
	local name = doorObj.name
	if multifind2(doorId, name, {'gate','slave','star'}) then
		return false -- special door
	end
	return true -- may be a revolving door
end

local function companionActivate(targetRef)
	local obj = targetRef.object
	local lootType = obj.objectType
	if logLevel >= 2 then
		mwse.log("%s: companionActivate(targetRef = %s, lootType = %s)",
			modPrefix, targetRef.id, mwse.longToString(lootType))
	end
	if lootType == DOOR_T then
		if mayBeRevolvingDoor(targetRef, obj) then
			return
		end
	end

	local targetMob = targetRef.mobile
	local weight
	if not targetMob then
		if lootType then
			if not ( (lootType == CONT_T)
				or (lootType == DOOR_T) ) then
				weight = getRefWeight(targetRef)
			end
		end
	end

	local companions = {}
	local encumb, capacity, mobileRef, companion, dist, security
	local maxDist = config.maxDistance

	local friendlyActors = mobilePlayer.friendlyActors
	local mob
	for i = 1, #friendlyActors do
		mob = friendlyActors[i]
		if not (mob == mobilePlayer) then
			mobileRef = mob.reference
			companion = getCompanion(mobileRef)
			if companion then
				if companion == 1 then
					if logLevel >= 3 then
						mwse.log("%s: getSpreads(%s) companion = %s", modPrefix, mobileRef.id, companion)
					end
					dist = mob.position:distance(targetRef.position)
					if dist <= maxDist then
						if logLevel >= 2 then
							mwse.log("%s: %s distance from %s = %s", modPrefix, mobileRef.id, targetRef.id, dist)
						end
						encumb = mob.encumbrance
						---assert(encumb)
						capacity = encumb.base - encumb.current
						if logLevel >= 2 then
							mwse.log("%s: %s capacity = %s", modPrefix, mobileRef.id, capacity)
						end
						security = 0
						if mob.actorType == tes3_actorType_npc then
							security = mob.security.current
						end
						table.insert(companions, {mobRef = mobileRef, cap = capacity, sec = security})
					end
				end
			end
		end
	end

	table.sort(companions, function(a,b) return a.cap > b.cap end) -- sort by decreasing companion capacity first
	if (lootType == CONT_T)
	or (lootType == DOOR_T) then
		table.sort(companions, function(a,b) return a.sec > b.sec end) -- sort by decreasing companion security too
	end

	local overburdenAllowed = config.allowLooting > 1 -- 0 = No, 1 = Yes, No Overburdening, 2 = Yes, Overburdening
	local maxCapacity = 0

	lastCompanionRef = nil -- reset it
	for _, comp in pairs(companions) do
		if comp then
			if overburdenAllowed
			or (comp.cap > 0) then
				maxCapacity = comp.cap
				lastCompanionRef = comp.mobRef
				break
			end
		end
	end

	if not lastCompanionRef then
		return
	end

	local companionName = lastCompanionRef.object.name
	local playerName = player.object.name
	local itemName = targetRef.object.name
	local i = math.random(100)
	local companionIsNPC = lastCompanionRef.mobile.actorType == 1
	if weight then
		if maxCapacity <= weight then
			local inam = strip(itemName)
			if config.allowLooting == 1 then -- 1 = Yes, No Overburdening
				if i > 75 then
					if companionIsNPC then
						tes3.messageBox("%s:\n\"I can't carry more than this!\"", companionName)
					else
						tes3.messageBox("%s cannot carry any more.\"", companionName)
					end
				elseif i > 50 then
					if companionIsNPC then
						tes3.messageBox("%s:\n\"%s, I am not your beast of burden!\"", companionName, playerName)
					else
						tes3.messageBox("%s would become overburdened.", companionName)
					end
				elseif i > 25 then
					if companionIsNPC then
						tes3.messageBox("%s:\n\"Sorry %s but... no, I can barely move already.\"", companionName, playerName)
					else
						tes3.messageBox("%s cannot carry the %s.\"", companionName, inam)
					end
				else
					if companionIsNPC then
						tes3.messageBox("%s:\n\"%s? Sorry, too heavy for me.\"", companionName, inam)
					else
						tes3.messageBox("%s loot is too heavy for %s.\"", inam, companionName)
					end
				end
				return -- skip
			elseif overburdenAllowed then
				if companionIsNPC then
					if i > 75 then
						tes3.messageBox("%s:\n\"I am sworn to carry your burdens.\"", companionName)
					elseif i > 50 then
						tes3.messageBox("%s:\n\"So you DO think I am your beast of burden.\"", companionName)
					elseif i > 25 then
						tes3.messageBox("%s:\n\"%s, I cannot move freely any more while carrying this %s.\"", companionName, playerName, inam)
					else
						tes3.messageBox("%s:\n\"You can't be serious! I am already overburdened.\"", companionName)
					end
				elseif i > 75 then
					tes3.messageBox("%s:\n\"%s is overburdened by the %s.\"", companionName, inam)
				end
			end
		end
	end
	if logLevel >= 3 then
		mwse.log("%s: maxCapacity = %s, lastCompanionRef = %s", modPrefix, maxCapacity, lastCompanionRef.id)
	end
	lastTargetRef = targetRef
	---assert(companionMob)

	if targetMob then
		if config.allowLooting > 0 then
			companionLootContainer(lastCompanionRef, targetRef)
		end
		return
	end

	if weight then
		if config.allowLooting > 0 then
			if lootType == BOOK_T then -- special case for books
				takeItem(lastCompanionRef, targetRef) -- add one copy to inventory and delete the in-world original
			elseif canWalkTo(lastCompanionRef, targetRef) then -- should be able to walk to the target
				local companionMob = lastCompanionRef.mobile
				sneakForSec(companionMob, 3)
				if targetRef.itemData then
					takeItem(lastCompanionRef, targetRef) -- add one copy to inventory and delete the in-world original
				else
					---takeItem(lastCompanionRef, targetRef)
					---tes3.setAIActivate({ reference = lastCompanionRef, target = targetRef }) -- has problems with object.data?
					doActivate(lastCompanionRef, targetRef)
				end
			else -- force activation from distance
				if targetRef.itemData then
					takeItem(lastCompanionRef, targetRef) -- add one copy to inventory and delete the in-world original
				else
					---takeItem(lastCompanionRef, targetRef)
					doActivate(lastCompanionRef, targetRef)
				end
			end
		end
		return
	end

	if ( (lootType == CONT_T)
	or (lootType == DOOR_T) ) then
		tryCompanionThievery(lastCompanionRef, targetRef)
	end
end


local function checkCompanionActivate(targetRef)
	if logLevel >= 2 then
		mwse.log('%s: checkCompanionActivate(targetRef = %s)', modPrefix, targetRef)
	end
	if not targetRef then
		return
	end
	local lootType = targetRef.object.objectType
	if logLevel >= 2 then
		local lt
		if lootType then
			lt = mwse.longToString(lootType)
		end
		mwse.log('%s: checkCompanionActivate(lootType = %s)', modPrefix, lt)
	end
	local mob = targetRef.mobile
	if not lootType then
		return
	end
	if mob or lootType then
		companionActivate(targetRef)
	end
end


local persContId = "com_chest_02_j'zhirr" ---'ab01smcoTempCont'
local persContObj -- set in modConfigReady()
local persContRef -- set in loaded()

local tes3_objectType_light = tes3.objectType.light

local lightLoopSoundFixBusy = false

local function lightLoopSoundFix(mobileCrea)
	if not persContRef then
		if logLevel > 0  then
			mwse.log('%s: lightLoopSoundFix() "%s" persistent container not found', modPrefix, persContId)
		end
	end
	local mobRef = mobileCrea.reference
	if logLevel >= 2 then
		mwse.log('%s: lightLoopSoundFix("%s")', modPrefix, mobRef.id)
	end
	if lightLoopSoundFixBusy then
		return
	end
	local found = false
	local itm, cnt, movedCount
	lightLoopSoundFixBusy = true
	-- remove lights from creature inventory to stop looping sound bug

	local items = mobRef.object.inventory.items
	local stack
	local toMove = {}
	local j = 0
	for i = 1, #items do
		stack = items[i]
		if stack then
			itm = stack.object
			if itm.objectType == tes3_objectType_light then
				found = true
				cnt = math.abs(stack.count)
				j = j + 1
				toMove[j] = {it = itm, co = cnt}
			end
		end
	end
	if not found then
		lightLoopSoundFixBusy = false
		return
	end
	local moved
	for i = 1, j do
		moved = toMove[i]
		itm = moved.it
		cnt = moved.co
		movedCount = tes3.transferItem({from = mobRef, to = persContRef, item = itm, itemData = stack.itemData,
			count = cnt, limitCapacity = false, --important!!!
			playSound = false, updateGUI = false, reevaluateEquipment = false})
		if logLevel >= 3 then
			mwse.log('%s: tes3.transferItem({from = "%s", to = "%s", item = "%s", count = %s}) = %s',
				modPrefix, mobRef.id, persContRef.id, itm.id, cnt, movedCount)
		end
	end

	local function transferItemsBack()
		-- move lights back to creature inventory
		items = persContRef.object.inventory.items
		for i = 1, #items do
			stack = items[i]
			if stack then
				itm = stack.object
				cnt = math.abs(stack.count)
				movedCount = tes3.transferItem({from = persContRef, to = mobRef, item = itm, itemData = stack.itemData,
					count = cnt, playSound = false, updateGUI = false, reevaluateEquipment = false})
				if logLevel >= 3 then
					mwse.log('%s: tes3.transferItem({from = "%s", to = "%s", item = "%s", count = %s}) = %s',
						modPrefix, persContRef.id, mobRef.id, itm.id, cnt, movedCount)
				end
			end
		end
		lightLoopSoundFixBusy = false
	end

	timer.start({duration = 0.3, type = timer.real,	callback = transferItemsBack})
end


local volumeVoice = 0 -- reset in loaded()

local function combatFix(mob)
	local v = audioController.volumeVoice
	if v > 0 then
		if logLevel >= 3 then
			mwse.log('%s: combatFix("%s") volumeVoice = audioController.volumeVoice = %s stored',
				modPrefix, mob.reference.id, v)
		end
		volumeVoice = v
	end
	if logLevel >= 3 then
		mwse.log('%s: combatFix("%s") , audioController.volumeVoice = 0, mob:startCombat(mob)',
			modPrefix, mob.reference.id)
	end
	audioController.volumeVoice = 0 -- silence combat voices
	-- note: delay should be enough to silence also other companions attack sounds

	timer.start({duration = 1.2, type = timer.real, callback =
		function ()
			if volumeVoice > 0 then
				if logLevel >= 3 then
					mwse.log('%s: combatFix("%s") mob:stopCombat(true), audioController.volumeVoice reset to %s',
						modPrefix, mob.reference.id, volumeVoice)
				end
				audioController.volumeVoice = volumeVoice
			end
		end
	})

	---mob:startCombat(tes3.mobilePlayer) -- nope causes the other companions to defend player
	mob:startCombat(mob)

	timer.start({duration = 0.1, type = timer.real, callback =
		function ()
			mob:stopCombat(true)
			if not mob.isFlying then
				mob.reference:disable()
				timer.frame.delayOneFrame(
					function ()
						mob.reference:enable()
					end
				)
			end
		end
	})
end

local function back2slash(s)
	return string.gsub(s, [[\]], [[/]])
end

local animBlacklist = {'scamp'}

local function isAnimBlacklisted(mobRef)
	local mesh = mobRef.object.mesh
	if not mesh then
		return false
	end
	if mesh == '' then
		return false
	end
	if string.multifind(string.lower(back2slash(mesh)), animBlacklist, 1, true) then
		return true
	end
	return false
end

local function resetAnimation(mob)
	local mobRef = mob.reference
	if isAnimBlacklisted(mobRef) then
		return
	end
	if validFollower(mob, true) == 0 then -- always reset followers
		local animationController = mob.animationController
		if animationController then -- could be nil
			if animationController.animationData.hasOverrideAnimations then
				return -- skip e.g. a drummer
			end
		end
	end
	-- reset animation if a follwer or not having some overridden animation
	tes3.playAnimation({reference = mobRef, group = 0})
end

local tes3_aiBehaviorState_walk = tes3.aiBehaviorState.walk

local function fixActionData(mob)
	local actionData = mob.actionData
	if not actionData then
		return
	end
	local aiBehaviorState = actionData.aiBehaviorState
	if not (aiBehaviorState == tes3_aiBehaviorState_walk) then
		return
	end
	local walkDestination = actionData.walkDestination
	if not walkDestination then
		return
	end
	local position = mob.position
	if walkDestination:distance(position) > 34576 then
		actionData.walkDestination = position:copy()
	end
end

local function fixMobileAI(mob)
	if logLevel >= 3 then
		mwse.log('%s: fixMobileAI("%s")', modPrefix, mob.reference.id)
	end

	if mob.actorType == tes3_actorType_creature then
		lightLoopSoundFix(mob)
	end

-- some NullCascade's wizardry
-- https://discord.com/channels/210394599246659585/381219559094616064/826742823218053130
-- does it still work?
	mwse.memory.writeByte({
		address = mwse.memory.convertFrom.tes3mobileObject(mob) + 0xC0,
		byte = 0x00,
	})

	fixActionData(mob)

	resetAnimation(mob)

	timer.start({duration = 1.5, callback =
		function ()
			combatFix(mob) -- note to self: the delay is important!
		end
	})
end

local function addBurden(mob)
	if not mob:isAffectedByObject(burdenSpell) then
		if logLevel >= 3 then
			mwse.log('%s: addBurden("%s")', mob.reference.id)
		end
		tes3.addSpell({reference = mob, spell = burdenSpell})
	end
end

local function checkRemoveBurden(mob)
	if logLevel >= 5 then
		mwse.log('%s: checkRemoveBurden("%s")', modPrefix, mob.reference.id)
	end
	if mob:isAffectedByObject(burdenSpell) then
		if logLevel >= 3 then
			mwse.log('%s: checkRemoveBurden tes3.removeSpell({reference = "%s", spell = burdenSpell})', modPrefix, mob.reference.id)
		end
		tes3.removeSpell({reference = mob, spell = burdenSpell})
	end
end

local skipFatigued = {
'lack_qac_aaiona', 'lack_qac_aandren', 'lack_qac_amelierelm','lack_qac_assassin'
}

local function activate(e)
	local targetRef = e.target
	if not targetRef then
		return
	end

	local activatorRef = e.activator
	if not activatorRef then
		return -- it happens
	end

	if logLevel >= 4 then
		mwse.log("%s: activate() activatorRef = %s, targetRef = %s", modPrefix, activatorRef.id, targetRef.id)
	end

	local targetBaseObj = targetRef.baseObject

	if activatorRef == player then
		local targetMob = targetRef.mobile
		local targetMobIsDead = false
		if targetMob
		and targetMob.actorType then
			checkRemoveBurden(targetMob)
			targetMobIsDead = isDead(targetMob)
			if not targetMobIsDead then
				local AIfixOnActivate = config.AIfixOnActivate
				local skipSneak = mobilePlayer.isSneaking
					and config.skipActivatingFollowerWhileSneaking
				local companion = getCompanion(targetRef)
				if (companion == 1)
				or isValidScenicFollower(targetMob) then
					if AIfixOnActivate == 2 then
						fixMobileAI(targetMob)
					elseif AIfixOnActivate == 1 then
						if companion == 1 then
							fixMobileAI(targetMob)
						end
					end
					if config.transparencyFixOnActivate then
						resetTransparency(targetMob)
					end
					if targetMob.alarm > 0 then
						if config.fixAlarm then
							targetMob.alarm = 0
						end
					end
					if targetMob.actorType == tes3_actorType_npc then -- 0 = creature, 1 = NPC, 2 = player
						if targetMob.waterBreathing < 1 then
							if config.fixWaterBreathing then
								targetMob.waterBreathing = 1
							end
						end
						if targetMob.acrobatics.current < 200 then
							if config.fixAcrobatics then
								targetMob.acrobatics.current = 200
							end
						end
						if targetMob.athletics.current < 240 then
							if config.fixAthletics then
								targetMob.athletics.current = 240
							end
						end
					end
					if mobilePlayer.isSneaking then
						if targetMob.actorType == tes3_actorType_creature then
							if tes3.isAffectedBy({reference = mobilePlayer, effect = tes3_effect_slowFall}) then
								if isMount(targetRef) then
									return -- IMPORTANT!!! don't skip normal activate when riding a creature!!!
								end
							end
						end
						if targetMob.fatigue.current <= 0 then
							if not skipFatigued[string.lower(targetBaseObj.id)] then
								-- stand up from collapsed state
								targetMob.fatigue.current = targetMob.fatigue.base * 0.2
							end
						end
						if skipSneak then
							return false
						end
					end -- if mobilePlayer.isSneaking
				elseif AIfixOnActivate == 3 then
					fixMobileAI(targetMob)
					if skipSneak then
						return false
					end
					return
				end -- if companion or follower
			end -- if not targetMobIsDead
		end -- if targetMob

		-- not (alive actor target) below
		if not isAltDown() then
			return
		end
		-- alt pressed below

		if skipPlayerAltActivate then
			-- nope it may still crash player can activate only normally to allow container animation, no more Alt process
			-- e.claim = true
			--- return false
			return
		end

		if targetMob
		and targetMob.actorType then
			if config.allowLooting > 0 then
				if targetMobIsDead then
					if isLootable(targetBaseObj) then
						timer.start({ duration = 0.1,
							callback = function ()
								checkCompanionActivate(targetRef)
							end
						})
						-- skip standard activation this frame!
						---e.claim = true
						return false
					end
				elseif config.AIfixOnActivate > 0 then
					fixMobileAI(targetMob)
				end
			end
			return
		end

		-- not a mob target below

		--[[ too restrictive
		local hasOnActivate = not targetRef:testActionFlag(tes3.actionFlag.useEnabled)
		if hasOnActivate then
			if logLevel >= 2 then
				mwse.log("%s: activatorRef = %s, targetRef = %s hasOnActivate, skip", modPrefix, activatorRef.id, targetRef.id)
			end
			return
		end
		]]

		if tes3ui.menuMode() then
			return
		end

		if getValidObjLootType(targetBaseObj) then
			if isLootable(targetBaseObj) then
				timer.start({ duration = 0.1, type = timer.real,
					callback = function ()
						checkCompanionActivate(targetRef)
					end
				})
			end
			-- skip standard activationthis frame!
			---e.claim = true
			return false
		end -- if getValidObjLootType(targetBaseObj)
		return

	end -- if activatorRef == player

	-- not (activatorRef == player) below

	if not (activatorRef == lastCompanionRef) then
		return
	end

	if not (targetRef == lastTargetRef) then
		return
	end

	local objType = targetBaseObj.objectType
	if objType == DOOR_T then
		return
	end

	if config.allowLooting == 0 then
		return
	end

	takeMessageBox(activatorRef, targetRef)
	checkCrime(activatorRef, targetRef)
end


local function combatStopped(e)
	if not mobilePlayer then
		return
	end
	if not (e.actor == mobilePlayer) then
		return
	end
	local friendlyActors = mobilePlayer.friendlyActors
	if not friendlyActors then
		return
	end
	local mob
	for i = 1, #friendlyActors do
		mob = friendlyActors[i]
		if not (mob == mobilePlayer) then
			checkRemoveBurden(mob)
		end
	end
end

local function isMountedAbotGuar(mob)
	local mobRef = mob.reference
	if not mobRef then
		return false
	end
	local lcId = string.lower(mobRef.object.id)
	if not (lcId == 'ab01guguarpackmount') then
		return false
	end
	local context = mobRef.context
	if context then
		local ab01compMount = context.ab01compMount
		if ab01compMount then
			if ab01compMount == 3 then
				return true
			end
		end
	end
	return false
end

local dummies = {'dumm','mann','target','invis'}

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
	if string.multifind(string.lower(mesh), dummies, 1, true) then
		return true
	end
	return false
end

local function combatStart(e)
	local attackerMob = e.actor
	if not attackerMob then
		return
	end
	if ignoreMannequinAttacks then
		if isDummy(attackerMob) then
			return false
		end
	end
	local targetMob = e.target
	if not targetMob then
		return
	end
	if ignoreMannequinAttacks then
		if isDummy(targetMob) then
			return false
		end
	end
end

local function combatStarted(e)
	local attackerMob = e.actor
	if not attackerMob then
		return
	end
	local targetMob = e.target
	if not targetMob then
		return
	end

	if attackerMob == targetMob then
		return
	end

	if (autoAttack == 0)
	and (not autoBurden) then
		return
	end

	if not mobilePlayer then
		return
	end
	local friendlyActors = mobilePlayer.friendlyActors
	if not friendlyActors then
		return
	end

	local skip = true
	local mob
	for i = 1, #friendlyActors do -- player included
		mob = friendlyActors[i]
		if mob
		and mob == targetMob then
			skip = false
			break
		end
	end
	if skip then
		return
	end

	local anyFollower = autoAttack >= 2
	local attackerIsNotFollower = validFollower(attackerMob, anyFollower) == 0
	local valid
	for i = 1, #friendlyActors do
		mob = friendlyActors[i]
		if mob then
			if not (mob == mobilePlayer) then
				valid = validFollower(mob, anyFollower)
				if valid == 2 then -- companion
					if attackerIsNotFollower then
						if not (mob == attackerMob) then
							if not (mob == targetMob) then
								if not mob.isAttackingOrCasting then
									if not inCombat(mob) then
										if not isMountedAbotGuar(mob) then
											---mwscript.startCombat({reference = mob, target = attackerMob})
											mob:startCombat(attackerMob)
										end
									end
								end
							end
						end
					end
				elseif valid == 1 then
					if autoBurden then
						addBurden(mob)
					end
				end
			end
		end
	end
end

local function checkCombatRegistering()
	-- should almost replace diligent defenders
	-- but to work if diligent defenders is present priority needs to be higher
	local settings = {priority = 100}
	if event.isRegistered('combatStart', combatStart, settings) then
		if not ignoreMannequinAttacks then
			event.unregister('combatStart', combatStart, settings)
		end
	elseif ignoreMannequinAttacks then
		event.register('combatStart', combatStart, settings)
	end

	local combatStartedOn = (autoAttack > 0) or autoBurden
	if event.isRegistered('combatStarted', combatStarted, settings) then
		if not combatStartedOn then
			event.unregister('combatStarted', combatStart, settings)
		end
	elseif combatStartedOn then
		event.register('combatStarted', combatStarted, settings)
	end
end

--[[
local function table2str(t)
	local s = '{'
	local s2
	local valueType
	for k, v in pairs(t) do
		valueType = type(v)
		if valueType == "string" then
			s2 = string.format('%s = "%s", ', k, v)
		elseif valueType == "table" then
			s2 = string.format('%s = %s, ', k, table2str(v))
		else
			s2 = string.format('%s = %s, ', k, v)
		end
		s = s .. s2
	end
	s2 = string.sub(s, 1, -3) -- strip last comma
	s = s2 .. '}'
	return s
end
]]

local pi = math.pi
local halfSqrt2 = math.sqrt(2) * 0.5

local function startTimedTravelProcess()
	local dur = math.round(1.55 - (0.1 * math.random()), 3)
	if logLevel >= 2 then
		mwse.log("%s: startTimedTravelProcess() timer.start({duration = %s, callback = timedTravelProcess, iterations = -1})", modPrefix, dur)
	end
	timer.start({duration = dur, callback = timedTravelProcess, iterations = -1})
end

local function startWarpFollowers() -- called in loaded()
	local dur = math.round(1.25 - (0.05 * math.random()), 3)
	if logLevel >= 2 then
		mwse.log("%s: startWarpFollowers() timer.start({duration = %s, callback = warpFollowers, iterations = -1})", modPrefix, dur)
	end
	timer.start({duration = dur, callback = warpFollowers, iterations = -1})
end

local function loaded()
	local funcPrefix = string.format('%s %s', modPrefix, 'loaded()')
	player = tes3.player
	---assert(player)
	mobilePlayer = tes3.mobilePlayer
	---assert(mobilePlayer)

	tes3gmst_fPickLockMult = tes3.findGMST(tes3.gmst.fPickLockMult)
	tes3gmst_fTrapCostMult = tes3.findGMST(tes3.gmst.fTrapCostMult)
	lastCompanionRef = nil
	lastTargetRef = nil
	skipPlayerAltActivate = false
	lightLoopSoundFixBusy = false

	persContRef = tes3.getReference(persContId)
	if not persContRef then
		persContRef = tes3.createReference({
			object = persContObj,
			position = tes3vector3.new(-100, 0, 0),
			orientation = tes3vector3.new(0, 0, 0),
			cell = 'Seyda Neen, Census and Excise Office',
			persistent = true,
			modified = true, -- we want to store it if possible
		})
		if persContRef then
			local obj = persContRef.object
			if not obj.isInstance then
				local cloned = persContRef:clone() -- returns a boolean, autoupdates the reference
				if cloned then -- resolve container contents
					persContRef = tes3.getReference(persContId) -- unsure if needed but just in case
				end
			end
		end
		if not persContRef then
			mwse.log('%s: warning unable to create "%s" persistent container reference', funcPrefix, persContId)
		end

	end
	if not persContRef then
		mwse.log('%s: warning unable to find or create "%s" persistent container reference', funcPrefix, persContId)
	end

	stopMoveTravellers()
	travelType = 0

	cleanTravellers()
	travellers = player.data.ab01travellers or {}
	packTravellers()

	cleanWarpers()
	warpers = player.data.ab01warpers or {}
	packWarpers()

	cleanLastPlayerPositions()
	local ab01lastPlayerPositions = player.data.ab01lastPlayerPositions
	if ab01lastPlayerPositions then
		local v
		for i = 1, #ab01lastPlayerPositions do
			v = ab01lastPlayerPositions[i]
			lastPlayerPositions[i] = {cellId = v.cellId, pos = getVec3FromTable3(v.pos)}
		end
	end

	local ab01travelType = player.data.ab01travelType
	if ab01travelType then
		travelType = ab01travelType
		if travelType > 0 then
			if numTravellers > 0 then
				if logLevel >= 2 then
					mwse.log("%s: travelType = %s, numTravellers = %s", funcPrefix, travelType, numTravellers)
				end
				startMoveTravellers()
			end
		end
	end

	timer.start({duration = 2, type = timer.real, callback =
		function ()
			if volumeVoice > 0 then
				if logLevel >= 3 then
					mwse.log('%s: audioController.volumeVoice reset to %s', funcPrefix, volumeVoice)
				end
				audioController.volumeVoice = volumeVoice
				volumeVoice = 0
			end
		end
	})

	startWarpFollowers()

	initScenicTravelAvailable()

	if scenicTravelAvailable then
		startTimedTravelProcess()
	elseif travelType > 0 then
		if numTravellers > 0 then
			if logLevel >= 2 then
				mwse.log("%s: travelStop()", funcPrefix)
			end
			travelStop()
		end
	end

end


local function save()
	packTravellers()
	packWarpers()
	packLastPlayerPositions()
	player.data.ab01travelType = travelType
	player.data.ab01travellers = travellers
	player.data.ab01warpers = warpers

	local t = {}
	local t3, cId
	local doLog = logLevel >= 4
	for i, v in pairs(lastPlayerPositions) do
		if v then
			if v.pos then
				t3 = getTable3FromVec3(v.pos)
				cId = v.cellId
				if doLog then
					mwse.log('%s: save() ab01lastPlayerPositions[%s] = { cellId = "%s", pos = {%s, %s, %s} }',
						modPrefix, i, cId, t3[1], t3[2], t3[3])
				end
				t[i] = {cellId = cId, pos = t3}
			end
		end
	end
	player.data.ab01lastPlayerPositions = t

end

local function cellChanged(e)
	local previousCell = e.previousCell
	if not previousCell then
		return
	end
	local cell = e.cell
	if cell.isInterior
	or previousCell.isInterior then
		cleanLastPlayerPositions()
	end

	if not autoMoveCC then
		return
	end
	if not previousCell.isInterior then
		if not cell.isInterior then
			return -- exterior -> exterior, skip
		end
	end
	local mob, mobRef, size, dist, pos ---, ok
	local moving = {}
	local playerSize = mobilePlayer.boundSize.y * player.scale
	local friendlyActors = tes3.mobilePlayer.friendlyActors
	local count = #friendlyActors
	local destPos = player.position
	for i = 1, count do
		mob = friendlyActors[i]
		if not (mob == mobilePlayer) then
			mobRef = mob.reference
			pos = mobRef.position
			size = mob.boundSize.y * mobRef.scale
			dist = pos:distance(destPos)
			---mwse.log('dist "%s" = %s', mob.reference, dist)
			if dist < (playerSize + size) * halfSqrt2 then
				--[[ok = true -- not needed it seems
				if cell.isInterior
					if not previousCell.isInterior then
						if isStayOutside(mob) then
							ok = false
						end
					end
				end
				if ok then
					table.insert(moving, mob)
				end]]
				table.insert(moving, mob)
			end
		end
	end
	count = #moving
	if count == 0 then
		return
	end
	local aStep = pi / count
	local right = false
	local k
	local a = player.facing
	for i = 1, count do
		mob = moving[i]
		mobRef = mob.reference
		size = mob.boundSize.y * mobRef.scale
		dist = (playerSize + size) * 0.5 --halfSqrt2
		pos = mobRef.position
		pos.x = pos.x - (dist * math.sin(a))
		pos.y = pos.y - (dist * math.cos(a))
		mobRef.facing = player.facing
		---mwse.log('"%s" moved to %s %s a = %s',
			---mobRef.id, pos.x, pos.y, math.deg(a))
		k = i * aStep
		if right then
			a = a - k
		else
			a = a + k
		end
		right = not right
	end
end


local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	---sYes = tes3.findGMST(tes3.gmst.sYes).value
	---sNo = tes3.findGMST(tes3.gmst.sNo).value

	inputController = tes3.worldController.inputController
	audioController = tes3.worldController.audioController
	---worldObjectRoot = tes3.game.worldObjectRoot
	---worldPickRoot = tes3.game.worldPickRoot
	---assert(worldPickRoot)
	---worldLandscapeRoot = tes3.game.worldLandscapeRoot

	--[[if tes3.hasCodePatchFeature(tes3.codePatchFeature.slowfallOverhaul) then
		slowFallAmount = 20
		if logLevel > 0 then
			mwse.log('%s: Code Patch slowfallOverhaul option detected', modPrefix)
		end
	end]]

	--[[local f = mwscript.setDelete
	assert(f) -- ensure it is still available]]

	local function createSpell(spellId, spellName, spellEffects)
		return tes3.createObject({objectType = tes3.objectType.spell,
			id = spellId,
			name = spellName,
			castType = tes3.spellType.curse, -- curses are less sticky
			alwaysSucceeds = true,
			sourceLess = true,
			effects = spellEffects,
			modified = true, -- we want to store it if possible
		})
	end

	levitateSpell = createSpell('ab01smcoLevitate', 'Warping', {{id = tes3_effect_levitate, min = 400, max = 400}})
	waterWalkSpell = createSpell('ab01smcoWaterwalking', 'Water Walking', {{id = tes3_effect_waterWalking, min = 1, max = 1}})
	burdenSpell = createSpell('ab01smcoBurdened', 'Still', {{id = tes3_effect_burden, min = 2000000000, max = 2000000000}})

	ab01ssDestGlob = tes3.findGlobal('ab01ssDest')
	ab01boDestGlob = tes3.findGlobal('ab01boDest')
	ab01goDestGlob = tes3.findGlobal('ab01goDest')
	ab01goAngleGlob = tes3.findGlobal('ab01goAngle')
	NPCVoiceDistanceGlob = tes3.findGlobal('NPCVoiceDistance')

	persContObj = tes3.createObject({
	  objectType = tes3.objectType.container,
	  id = persContId,
	  name = '',
	  ---mesh = 'o\\contain_com_sack_02.nif',
	  mesh = 'EditorMarker.NIF',
	  capacity = 999999999999999999,
	  persistent = true,
	  modified = true, -- we want to store it if possible
	})
	---assert(persContObj)

	initScenicTravelAvailable()

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		logLevel = config.logLevel
		autoWarp = config.autoWarp
		autoAttack = config.autoAttack
		autoBurden = config.autoBurden
		warpFightingCompanions = config.warpFightingCompanions
		warpWaterWalk = config.warpWaterWalk
		warpLevitate = config.warpLevitate
		autoMoveCC = config.autoMoveCC

		if autoWarp >= 2 then
			if NPCVoiceDistanceGlob then -- NPCVoiceDistance = 750 by default
-- increase NPCVoiceDistanceGlob accordingly to avoid annoying "Hey! Wait for me"
				local v = roundInt(config.warpDistance * 1.5)
				if NPCVoiceDistanceGlob.value < v then
					NPCVoiceDistanceGlob.value = v
				end
			end
		end

		if not (ignoreMannequinAttacks == config.ignoreMannequinAttacks) then
			ignoreMannequinAttacks = config.ignoreMannequinAttacks
		end

		checkCombatRegistering()
		mwse.saveConfig(configName, config, {indent = true})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage({
		label="Info",
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	})

	---local sidebar = preferences.sidebar
	---sidebar:createInfo{text = ""}

	---local controls = preferences:createCategory{label = modName.."\n"}
	local controls = preferences:createCategory({})

	local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end

	local yesOrNo = {[false] = 'No', [true] = 'Yes'}

	local function getYesNoDescription(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	local optionList = {'No', 'Yes, No Overburdening', 'Yes, Overburdening'}
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
		label = 'Companions Looting:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s.
When enabled, Alt + activate to make your companions try and loot the target item/container/corpse
(with/without potential overburdening).]], 'allowLooting'),
		variable = createConfigVariable('allowLooting')
	})

	controls:createSlider({
		label = 'Minimum item Value/Weight ratio',
		description = getDescription([[Default: %s.
Minimum Value/Weight ratio for an item to be taken by a companion when looting a container.]], 'minValueWeightRatio'),
		variable = createConfigVariable('minValueWeightRatio')
		,min = 1, max = 100, step = 1, jump = 5
	})

	controls:createYesNoButton({
		label = 'Always loot from organic containers',
		description = getYesNoDescription([[Default: %s.
When enabled, companion NPCs will always loot from organic containers
(e.g. plants) regardless of the Minimum item Value/Weight ratio setting.]], 'alwaysLootOrganic'),
		variable = createConfigVariable('alwaysLootOrganic')
	})

	controls:createSlider({
		label = 'Max Loot Distance',
		description = getDescription([[Default: %s game units.
Maximum distance for an item to be activated by a companion.]], 'maxDistance'),
		variable = createConfigVariable('maxDistance')
		,min = 200, max = 1000, step = 1, jump = 5
	})

	optionList = {'No', 'Yes, Only current companions', 'Yes, Any follower', 'Yes, Any actor'}
	controls:createDropdown({
		label = 'Fix NPC/Creature AI on activate:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s.
Try and reset actors AI when activating them. Especially useful when they go crazy after teleporting around too much.
It should also try and fix the obnoxious attack sound looping bug often happening when follower creatures carry some light.]],
'AIfixOnActivate'),
		variable = createConfigVariable('AIfixOnActivate')
	})

	optionList = {'No', 'Yes, Only current companions', 'Yes, Any follower'}
	controls:createDropdown({
		label = 'Auto attack enemies:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s.
An alternative to diligent defenders.
If enabled, it should override it having higher priority and delaying the event to next frame.]],
'autoAttack'),
		variable = createConfigVariable('autoAttack')
	})

	controls:createDropdown({
		label = 'Warp to player:',
		options = getOptions(),
		description = string.format([[Default: %s. %s.
Warp valid companions/followers (mostly) at player shoulders if distance from player is more than Max Warp Distance (%s).
Note: warping control from this MWSE-Lua mod does not override warping control from the companion vanilla script if present, they coexist, so results may vary.]],
			defaultConfig.autoWarp, optionList[defaultConfig.autoWarp + 1], config.warpDistance),
		variable = createConfigVariable('autoWarp')
	})

	controls:createSlider({
		label = 'Max Warp Distance',
		description = getDescription([[Default: %s game units.
Maximum distance before triggering warp to player]], 'warpDistance'),
		variable = createConfigVariable('warpDistance')
		,min = 512, max = 7200, step = 1, jump = 5
	})

	controls:createYesNoButton({
		label = 'Warp fighting companions',
		description = getYesNoDescription([[Default: %s.
When warping is enabled, this option will make them warp to player even during fights.
You can enable this if you want to avoid companions chasing enemies too far, or if they are in a big danger.]], 'warpFightingCompanions'),
		variable = createConfigVariable('warpFightingCompanions')
	})

	controls:createDropdown({
		label = 'Automatic Levitate when warping:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s.
Selected actors levitate like player when warping.]], 'warpLevitate'),
		variable = createConfigVariable('warpLevitate'),
	})

	controls:createDropdown({
		label = 'Automatic Water Walk when warping:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s.
Selected actors water walk like player when warping.]], 'warpWaterWalk'),
		variable = createConfigVariable('warpWaterWalk'),
	})

	controls:createYesNoButton({
		label = 'Automove followers on cell change',
		description = getYesNoDescription([[Default: %s.
Automove any followers around the player e.g. after using loading doors.]], 'autoMoveCC'),
		variable = createConfigVariable('autoMoveCC')
	})

	optionList = {'Minimum', 'Low', 'Medium', 'High', 'Higher', 'Max'}
	controls:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','logLevel'),
		variable = createConfigVariable('logLevel'),
	})

	controls:createYesNoButton({
		label = 'Ignore mannequin attacks',
		description = getYesNoDescription([[Default: %s.
Ignore attacks from creatures/npcs emulating mannequins/targets/practice dummies.
This way player followers should not attack them any more.]], 'ignoreMannequinAttacks'),
		variable = createConfigVariable('ignoreMannequinAttacks')
	})

	controls:createYesNoButton({
		label = 'Auto burden followers on combat',
		description = getYesNoDescription([[Default: %s.
Autoburden non-companion followers on combat start, so they are not running after enemies.
N.B.:
- it does not work when you set "Auto attack enemies" option to "2. Yes, Any follower".
- it can make escort mission too easy.]], 'autoBurden'),
		variable = createConfigVariable('autoBurden')
	})

	controls:createYesNoButton({
		label = 'Allow Companions to use Probes',
		description = getYesNoDescription([[Default: %s.
When enabled, companion NPCs are allowed to use their stats,
skill and probes to try and disarm traps on the target you Alt + activate.
Probes with no uses left should be automatically dropped.]], 'allowProbes'),
		variable = createConfigVariable('allowProbes')
	})

	controls:createYesNoButton({
		label = 'Allow Companions to use Lockpicks',
		description = getYesNoDescription([[Default: %s.
When enabled, companion NPCs are allowed to use their stats, skill and lockpicks
to try and open the target you Alt + activate.
lockpicks with no uses left should be automatically dropped.]], 'allowLockpicks'),
		variable = createConfigVariable('allowLockpicks')
	})

	controls:createYesNoButton({
		label = 'Allow Companions to use Open spells',
		description = getYesNoDescription([[Default: %s.
When enabled, companion NPCs are allowed to use their stats, skill and spells
to try and open the target you Alt + activate.]], 'allowMagic'),
		variable = createConfigVariable('allowMagic')
	})

	controls:createYesNoButton({
		label = 'Followers 0 Alarm',
		description = getYesNoDescription([[Default: %s.
When enabled, followers are given 0 alarm on activate if not already having it.
Useful to avoid annoying "Thief!" messages.]], 'fixAlarm'),
		variable = createConfigVariable('fixAlarm')
	})
	controls:createYesNoButton({
		label = 'Follower NPCs Water Breathing',
		description = getYesNoDescription([[Default: %s.
When enabled, follower NPCs are given water breathing on activate if not already having it.
Useful to avoid them getting drowned.]], 'fixWaterBreathing'),
		variable = createConfigVariable('fixWaterBreathing')
	})
	controls:createYesNoButton({
		label = 'Follower NPCs High Acrobatics',
		description = getYesNoDescription([[Default: %s.
When enabled, follower NPCs are given high acrobatics on activate if not already having it.
Useful to avoid them getting damaged on jumping or teleporting.]], 'fixAcrobatics'),
		variable = createConfigVariable('fixAcrobatics')
	})
	controls:createYesNoButton({
		label = 'Follower NPCs High Athletics',
		description = getYesNoDescription([[Default: %s.
When enabled, follower NPCs are given high athletics on activate if not already having it.
Useful to better adapt follower animation speed to player speed.]], 'fixAthletics'),
		variable = createConfigVariable('fixAthletics')
	})

	controls:createYesNoButton({
		label = 'Skip follower activation while sneaking/unconscious',
		description = getYesNoDescription([[Default: %s.
When enabled, you will not be able to activate a follower while you are sneaking or while the follower is unconscious,
avoiding the risk to trigger a pickpocket attempt crime reaction.]], 'skipActivatingFollowerWhileSneaking'),
		variable = createConfigVariable('skipActivatingFollowerWhileSneaking')
	})

	controls:createYesNoButton({
		label = 'Fix follower transparency on activate',
		description = getYesNoDescription([[Default: %s.
When enabled, try and fix follower transparency on activate.
You can try it if a follower keeps staying transparent without apparent reason.]], 'transparencyFixOnActivate'),
		variable = createConfigVariable('transparencyFixOnActivate')
	})

	controls:createButton({
		---label = 'Emergency stop travelling',
		buttonText = "Emergency stop travelling",
		description = "Force travelling stop in case something goes wrong and followers get stuck in travelling position.",
		inGameOnly = true, -- important as player variable may not be initialized yet
		callback = travelStop
	})

	mwse.mcm.register(template)
	---logConfig(config, {indent = false})

	event.register('save', save)
	event.register('loaded', loaded)
	event.register('cellChanged', cellChanged)
	event.register('combatStopped', combatStopped)

	checkCombatRegistering()

-- high priority to try avoiding problems if another mod does not properly check for activator being the player
-- Book Pickup mod has priority 10
	event.register('activate', activate, {priority = 100000})

	timer.register('ab01SmartCompTravelEnd', travelEnd) -- persistent timer


end
event.register('modConfigReady', modConfigReady)

--[[ some security info
x = 0.2 * pcAgility + 0.1 * pcLuck + securitySkill
x *= pickQuality * fatigueTerm
x += fPickLockMult * lockStrength

if x <= 0: fail and report impossible
roll 100, if roll <= x then open lock else report failure


On probing a trap
x = 0.2 * pcAgility + 0.1 * pcLuck + securitySkill
x += fTrapCostMult * trapSpellPoints
x *= probeQuality * fatigueTerm

if x <= 0: fail and report impossible
roll 100, if roll <= x then untrap else report failure
]]
