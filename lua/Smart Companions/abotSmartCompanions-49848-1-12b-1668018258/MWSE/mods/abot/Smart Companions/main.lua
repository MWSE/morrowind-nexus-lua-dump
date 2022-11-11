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
maxDistance  = 384,
allowProbes = true,
allowLockpicks = true,
allowMagic = true,
fixAcrobatics = true, -- follower NPCs are given high acrobatics
fixWaterBreathing = true, -- follower NPCs are given water breathing
skipActivatingFollowerWhileSneaking = true, -- self explaining
AIfixOnActivate = 2, -- 0 = No, 1 = Companions, 2 = All followers, 3 = All actors
transparencyFixOnActivate = false, -- try and fix follower transparency on activate
scenicTravelling = 2, -- 0 = No, 1 = Companions, 2 = All followers
autoWarp = 2, -- 0 = No, 1 = Companions, 2 = All followers
warpDistance = 680,
warpFightingCompanions = false,
warpWaterWalking = true, -- allow automatic waterWalking when warping
autoAttack = 1, -- 0. No - 1. Yes, Only current companions - 2. Yes, Any follower
autoBurden = false, -- burden non-companion followers on combat start
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

-- note the or defaultConfig is mostly to avoid Cisual Studio Code false problems detection
local config = mwse.loadConfig(configName, defaultConfig)
---assert(config)

-- to be reset in loaded()
local inputController
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
--[[
local ACTI_T = T3OT.activator
local ACTR_T = T3OT.mobileActor
]]
local ALCH_T = T3OT.alchemy
local AMMO_T = T3OT.ammunition
local APPA_T = T3OT.apparatus
local ARMO_T = T3OT.armor
local BOOK_T = T3OT.book
local CLOT_T = T3OT.clothing
local CONT_T = T3OT.container
local CREA_T = T3OT.creature
local DOOR_T = T3OT.door
local INGR_T = T3OT.ingredient
local LIGH_T = T3OT.light
local LKPK_T = T3OT.lockpick
local MISC_T = T3OT.miscItem
local NPC_T = T3OT.npc
local PROB_T = T3OT.probe
local REPA_T = T3OT.repairItem
--[[
local STAT_T = T3OT.static
]]
local WEAP_T = T3OT.weapon


local validLootTypes = {
[ALCH_T] = true,
[AMMO_T] = true,
[APPA_T] = true,
[ARMO_T] = true,
[BOOK_T] = true,
[CLOT_T] = true,
[CONT_T] = true,
[DOOR_T] = true,
[INGR_T] = true,
[LIGH_T] = true,
[LKPK_T] = true,
[MISC_T] = true,
[PROB_T] = true,
[REPA_T] = true,
[WEAP_T] = true,
}
local readableObjectTypes = table.invert(T3OT)

-- refreshed in modConfigReady()
local logLevel = config.logLevel
local autoWarp = config.autoWarp
local autoAttack = config.autoAttack
local autoBurden = config.autoBurden
local warpFightingCompanions = config.warpFightingCompanions
local warpWaterWalking = config.warpWaterWalking

local function getValidObjLootType(obj)
	local ot = obj.objectType
	if logLevel >= 3 then
		mwse.log("%s: %s obj.objectType = %s", modPrefix, obj.id, readableObjectTypes[ot])
	end
	if validLootTypes[ot] then
		return ot
	end
	return nil
end

local tes3_animationState_dead = tes3.animationState.dead
local tes3_animationState_dying = tes3.animationState.dying

local function isMobileDead(mobile)
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
		return mobile.isDead
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


local function isValidMobile(mobile)
	local ref = mobile.reference
	if ref.disabled then
		return false
	end
	if ref.deleted then
		return false
	end
	if not mobile.hasFreeAction then
		return false
	end
	if isMobileDead(mobile) then
		return false
	end
	if mobile == mobilePlayer then
		return false
	end

	if mobile.actorType == tes3_actorType_creature then -- 0 = creature
		local lcId = ref.object.id:lower()
		if not (lcId == 'ab01guguarpackmount') then -- this is a good one
			if lcId:startswith('ab01') then
-- ab01 prefix, probably some abot's creature having AIEscort package, skip
				return false
			end
			local creature = mobile.object -- tes3creature or tes3creatureInstance
			if creature then
				local script = creature.script
				if script then
					local lcId2 = script.id:lower()
					if lcId2:startswith('ab01') then -- ab01 prefix, probably some abot's creature having AIEscort package, skip
						if logLevel >= 3 then
							mwse.log("%s: %s having ab01 prefix, probably some abot's creature with AIEscort package, skip", modPrefix, ref.id)
						end
						return false
					end
				end
			end
		end
	end

	return true

end

--[[
local function followOrEscortAI(mob)
	local aiData = mob.aiData
	if aiData then
		local aiPackage = aiData:getActivePackage()
		if aiPackage then
			local aiPackageType = aiPackage.type
			if (aiPackageType == tes3_aiPackage_follow)
			or (aiPackageType == tes3_aiPackage_escort) then
				local target = aiPackage.targetActor
				if target then
					if target == player.object then
						return aiPackageType
					end
				end
			end
		end
	end
	return nil
end
]]

-- mobile.inCombat alone is not reliable /abot
local function inCombat(mobile)
	if mobile.inCombat then
		return true
	end
	if mobile.combatSession then
		return true
	end
	if mobile.actionData then
		if mobile.actionData.target then
			return true
		end
	end
	--[[if mobile.isAttackingOrCasting then
		return true
	end]]
	return false
end

-- 0 = invalid, 1 = follower, 2 = companion
local function validFollower(mobile, anyFollower, travelling)
	if not isValidMobile(mobile) then
		return 0
	end
	local ref = mobile.reference

	local companion = 0
	local oneTimeMove = 0

	local context = ref.context
	if context then
		if context.companion then
			companion = context.companion
		end
		if context.oneTimeMove then
			oneTimeMove = context.oneTimeMove
		end
	end

	local isCompanion = (companion == 1)

	if not travelling then
		if not warpFightingCompanions then
			if isCompanion then
				if inCombat(mobile) then
					return 0
				end
			end
		end
	end

	local ai = tes3.getCurrentAIPackageId(mobile)
	if (ai == tes3_aiPackage_follow)
	or (ai == tes3_aiPackage_escort) then
		if isCompanion then
			return 2
		end
		if anyFollower then
			if not ref.object.isGuard then
				return 1
			end
		end
		return 0
	elseif ai == tes3_aiPackage_wander then
		-- special case for wandering companions
		if isCompanion then
			if not (oneTimeMove == 0) then
-- assuming a companion scripted to do move-away using temporary aiwander
				return 2
			end
		end
	end

	return 0
end

local function isValidScenicFollower(mobile)
	local anyFollower = config.scenicTravelling >= 2
	if validFollower(mobile, anyFollower, true) > 0 then
		local ref = mobile.reference
		local boundSize_y = mobile.boundSize.y * ref.scale
		if boundSize_y > 80 then -- skip big mesh actors
			if logLevel >= 2 then
				mwse.log("%s: %s, boundSize.y %s, skipped", modPrefix, ref.id, boundSize_y)
			end
			return false
		end
		if logLevel >= 3 then
			mwse.log("%s: %s", modPrefix, ref.id)
		end
		return true
	end
	return false
end

local function getCompanionVars(mobile) -- out companion, spread, nospread
	local companion = nil
	local spread = nil
	local nospread = nil
	local ref = mobile.reference
	if ref.disabled then
		return companion, spread, nospread
	end
	if ref.deleted then
		return companion, spread, nospread
	end
	if not mobile.hasFreeAction then
		return companion, spread, nospread
	end
	if isMobileDead(mobile) then
		return companion, spread, nospread
	end
	local context = ref.context
	if context then
		companion = context.companion
		spread = context.spread
		nospread = context.nospread
		if companion then
			if logLevel >= 3 then
				mwse.log("%s: %s, companion = %s, spread = %s, nospread = %s", modPrefix, ref.id, companion, spread, nospread)
			end
		end
	end
	return companion, spread, nospread
end

local travelType = 0 -- 0 = none, 1 = boat, 2 = strider, 3 = gondola

local function table2vec(t)
	return tes3vector3.new(t[1], t[2], t[3])
end

local function vec2table(v)
	return {math.floor(v.x + 0.5), math.floor(v.y + 0.5), math.floor(v.z + 0.5)}
end

 -- reset in loaded()
local travellers = {} -- e.g. travellers[id] = {mob = mobile, inv = mobile.invisibility, acro = mobile.acrobatics.current, ns = tns} -- store mobile, invisibility, acrobatics,
local numTravellers = 0
local doPackTravellers = false

local function packTravellers()
	doPackTravellers = true
	local t = {}
	numTravellers = 0
	local ref
	for id, v in pairs(travellers) do
		if v
		and v.mob then
			ref = tes3.getReference(id)
			if ref then
				t[id] = v
				numTravellers = numTravellers + 1
			end
		end
	end
	travellers = t
	doPackTravellers = false
end

local function cleanTravellers()
	numTravellers = 0
	--[[for k in pairs(travellers) do
		travellers[k] = nil
	end]]
	travellers = {}
end


local warpers = {} -- e.g. warpers[mobId] = speed
local doPackWarpers = false

local function packWarpers()
	doPackWarpers = true
	local t = {}
	local ref
	for id, speed in pairs(warpers) do
		if speed then
			ref = tes3.getReference(id)
			if ref then
				t[id] = speed
			end
		end
	end
	warpers = t
	doPackWarpers = false
end

local function cleanWarpers()
	--[[for k in pairs(warpers) do
		warpers[k] = nil
	end]]
	warpers = {}
end

local lastPlayerPositions = {} -- e.g. lastPlayerPositions[i] = {cellId = v.cellId, pos = table2vec(v.pos)}
local maxSavedPlayerPositions = 30

local doPackLastPlayerPositions = false
local function packLastPlayerPositions()
	doPackLastPlayerPositions = true
	local t = {}
	local size = table.size(lastPlayerPositions)
	local v
	local j = 1
	for i = 1, size do
		v = lastPlayerPositions[i]
		if v
		and v.pos then
			t[j] = v
			j = j + 1
		end
	end
	lastPlayerPositions = t
	doPackLastPlayerPositions = false
end

local function cleanLastPlayerPositions()
	--[[for k in pairs(lastPlayerPositions) do
		lastPlayerPositions[k] = nil
	end]]
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
	[3] = {spell = 'water walking (unique)', spread = 24, maxInLine = 1}, -- gondola
	---[4] = 'ab01mountNPCAbility', -- guar mounting
}

local radStep = 0 -- updated in startMoveTravellers()

local function getCosSin(a)
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
	---local a1 = player.orientation.z -- -math.pi <= a1 <= math.pi
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
	local cosa, sina = getCosSin(a1)
	local playerPos = player.position
	local dx = playerPos.x
	local dy = playerPos.y
	local playerPosZ = playerPos.z
	local mob, pos, ref
	local invalid
	local k = 1
	for id, t in pairs(travellers) do
		invalid = true
		mob = t.mob
		if mob then
			ref = mob.reference
			if ref then
				if tes3.getReference(ref.id) then -- safety as any fake summon npc could disappear
					pos = mob.position
					if pos then
						invalid = false
						pos.z = playerPosZ

						-- move behind the player to not interfere with player scenic view
						pos.x = dx - (dist * sina[k])
						pos.y = dy - (dist * cosa[k])
						ref.orientation.z = a2 -- look front
						---mwse.log("k = %d, dist = %d, x = %s, y = %s", k, dist, pos.x, pos.y)
						if k < maxInLine then
							k = k + 1
						else
							k = 1
							dist = dist + dd -- if more than maxInLine one more step behind and reset angle
							---mwse.log("k = %d, dist = %d, dd = %s", k, dist, dd)
						end
					end -- if pos
				end -- if tes3.getReference
			end -- if ref
		end -- if mob
		if invalid then
			if numTravellers > 0 then
				numTravellers = numTravellers - 1
			end
			---travellers[id] = nil
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

local warpLevSpell, waterWalkSpell, burdenedSpell -- created in modConfigReady()

---local slowFallAmount = 1 -- updated in modConfigReady()

local function isMount(ref)
	if string.multifind(ref.id:lower(), {'guar', 'horse', 'mount'}, 1, true) then
		return true
	end
	return false
end

local rad2degMul = 180 / math.pi

local function atPlayerShoulders(x, y)
	local dx = x - player.position.x
	local dy = y - player.position.y
	if dy >= 0 then
		if dy < 0.001 then
			dy = 0.001
		end
	elseif dy > -0.001 then
		dy = -0.001
	end
	local ratio = dx / dy

	local pa = player.facing
	pa = pa * rad2degMul
	pa = pa % 360
	if pa > 180 then
		pa = pa - 360
	elseif pa < -180 then
		pa = pa + 360
	end
	-- now -180 <= pa <= 180

	if dx > 0 then
		if dy > 0 then
			if ratio > 1 then
				if pa < -45 then
					return true
				end
			else
				if pa < -90 then
					return true
				elseif pa > 135 then
					return true
				end
			end
			return false
		end
		-- dy <= 0
		if ratio < -1 then
			if pa < 0 then
				if pa > -135 then
					return true
				end
			end
		elseif pa < 45 then
			if pa > -90 then
				return true
			end
		end
		return false
	end

	-- dx <= 0
	if dy > 0 then
		if ratio < -1 then
			if pa > 45 then
				return true
			end
			return false
		end
		-- ratio >= -1
		if pa > 90 then
			return true
		elseif pa < -135 then
			return true
		end
		return false
	end

	-- dx <= 0, dy <= 0
	if ratio > 1 then
		if pa > 0 then
			if pa < 135 then
				return true
			end
		end
		return false
	end

	-- ratio <= 1
	if pa > -35 then
		if pa < 90 then
			return true
		end
	end
	return false
end

local function warpFollowers()
	if movingTravellers then
		return
	end
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
	local dist = 64
	local dd = 58
	local anyFollower = autoWarp >= 2
	local pcAngleZ = mobilePlayer.facing
	local cosa, sina = getCosSin(pcAngleZ)
	local playerPos = player.position
	local dx = playerPos.x
	local dy = playerPos.y
	local playerPosZ = playerPos.z
	local pcCell = player.cell
	local warpDist = config.warpDistance
	local playerLevitate = mobilePlayer.levitate
	local mobRef, mobId, pos, d, mobCell, notInPlayerCell, newPosFound, ori
	local context, stayOutside, boundSize_y, speed, speed2, ok

	local funcPrefix = string.format('%s %s', modPrefix, 'warpFollowers()')
	-- nope local playerSlowfall = tes3.isAffectedBy({reference = mobilePlayer, effect = tes3_effect_slowFall})
	local playerSlowfall = tes3.isAffectedBy({reference = mobilePlayer, effect = tes3_effect_slowFall})

	local function sameCellOrExterior(cell_1_id, cell_2)
		return (cell_1_id == cell_2.id)
		or ( (cell_1_id == '') and (not cell_2.isInterior) ) -- stored cell_1_id == '' means cell1 is exterior
	end

	local k = 1
	for _, mob in pairs(mobilePlayer.friendlyActors) do
		if validFollower(mob, anyFollower, false) > 0 then
			mobRef = mob.reference

			ok = true
			if playerSlowfall then
				if mob.actorType == tes3_actorType_creature then
					if isMount(mobRef) then
						ok = false
					end
				end
			end

			if ok then
				mobId = mobRef.id:lower()
				pos = mobRef.position

				if playerLevitate > 0 then
					if not tes3.isAffectedBy({reference = mobRef, effect = tes3_effect_levitate, object = warpLevSpell}) then
					---not	mob:isAffectedByObject(warpLevSpell) then
						---mwscript.addSpell({reference = mobRef, spell = warpLevSpell})
						tes3.addSpell({reference = mobRef, spell = warpLevSpell})
					end
					if not (mob.levitate > 0) then
						mob.levitate = playerLevitate -- this is needed too
					end
				else
					local wasLevitating = false
					if tes3.isAffectedBy({reference = mobRef, effect = tes3_effect_levitate, object = warpLevSpell}) then
					---if mob:isAffectedByObject(warpLevSpell) then
						wasLevitating = true
						---mwscript.removeSpell({reference = mobRef, spell = warpLevSpell})
						tes3.removeSpell({reference = mobRef, spell = warpLevSpell})
					elseif mob.levitate > 0 then
						wasLevitating = true
					end
					if wasLevitating then
						tes3.removeEffects({reference = mobRef, effect = tes3_effect_levitate})
						mob.levitate = 0 -- this is needed too
					end
				end

				--- check for waterwalking
				if warpWaterWalking then
					if mob:isAffectedByObject(waterWalkSpell) then
						if mobilePlayer.waterWalking <= 0 then
							---mwscript.removeSpell({reference = mobRef, spell = waterWalkSpell})
							tes3.removeSpell({reference = mobRef, spell = waterWalkSpell})
						end
					elseif mobilePlayer.waterWalking == 1 then
	-- comparison with standard 1 is important as it may be used as flag with different walues e.g. in guar mod
						tes3.addSpell({reference = mobRef, spell = waterWalkSpell})
						---mwscript.addSpell({reference = mobRef, spell = waterWalkSpell})
					end
				end

				if not warpers[mobId] then
					speed = mob.speed.current
					speed2 = mobilePlayer.speed.current * 1.3
					if speed2 > 210 then
						speed2 = 210
					elseif speed2 < 40 then
						speed2 = 40
					end
					if speed < speed2 then
						warpers[mobId] = speed
						tes3.setStatistic({reference = mob, name = 'speed', current = speed2})
					end
				end

				d = pos:distance(playerPos)
				if d > warpDist then
					-- check for levitation

					mobCell = mob.cell
					notInPlayerCell = not (mobCell == pcCell)
					ori = mobRef.orientation
					if notInPlayerCell then
						pos = pos:copy()
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
									if d >= minDist then
										if d <= warpDist then
											if atPlayerShoulders(v_pos.x, v_pos.y) then
											-- only if player can't see destination point
												pos.x = v_pos.x
												pos.y = v_pos.y
												pos.z = v_pos.z
												newPosFound = i
												if logLevel >= 3 then
													mwse.log('%s: newPosFound[%s] dist = %s', funcPrefix, i, d)
												end
												v.pos = nil
												doPackLastPlayerPositions = true
												break
											elseif logLevel >= 4 then
												mwse.log('%s: mobilePlayer:getViewToPointWithFacing(v_pos) = true, skip', funcPrefix)
											end
										elseif logLevel >= 4 then
											mwse.log('%s: v_pos:distance(playerPos) = %s > warpDist = %s, skip', funcPrefix, d, warpDist)
										end -- if d <= warpDist
									elseif logLevel >= 4 then
										mwse.log('%s: v_pos:distance(playerPos) = %s < minDist = %s, skip', funcPrefix, d, minDist)
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
									context = mobRef.context
									if context then
										stayOutside = context.stayOutside
										if stayOutside then
											if stayOutside == 1 then
												newPosFound = 0
											end -- if stayOutside == 1
										end -- if stayOutside
									end -- if context
								end -- if mobCell.isOrBehavesAsExterior
								if newPosFound > 0 then
									if logLevel >= 2 then
										mwse.log('%s: newPosFound = %s notInPlayerCell pcCell.isInterior tes3.positionCell({ref = "%s", pos = %s, ori.z = %s, cell = "%s"})',
											funcPrefix, newPosFound, mobRef, pos, ori.z, pcCell.name)
									end
									tes3.positionCell({reference = mob, position = pos, orientation = ori, cell = pcCell})
								end
							else
								if logLevel >= 2 then
									mwse.log('%s: newPosFound = %s notInPlayerCell tes3.positionCell({ref = "%s", pos = %s, ori.z = %s, cell = "%s"})', funcPrefix, newPosFound, mobRef, pos, ori.z, pcCell.editorname)
								end
								tes3.positionCell({reference = mob, position = pos, orientation = ori, cell = pcCell})
							end -- if pcCell.isInterior
						else
							if logLevel >= 2 then
								mwse.log('%s: newPosFound = %s InPlayerCell ref = "%s", pos = %s, ori.z = %s', funcPrefix, newPosFound, mobRef, pos, ori.z)
							end
						end -- if notInPlayerCell
					else -- newPosFound == 0 here
						pos.z = playerPosZ
						pos.x = dx - (dist * sina[k])
						pos.y = dy - (dist * cosa[k])
						if mobilePlayer:getViewToPoint(pos)	then -- only if not stuck-in-wall positions
							if atPlayerShoulders(pos.x, pos.y) then -- only if at player shoulders
								newPosFound = 1
							end
						end
					end -- if newPosFound

					if newPosFound == 0 then
						if k < 5 then
							k = k + 1
						else
							k = 1
							dist = dist + dd -- if more than maxInLine one more step behind and reset angle
							if boundSize_y > 64 then
								dist = dist + dd -- double for big mesh actors
							end
							---mwse.log("k = %d, dist = %d, dd = %s", k, dist, dd)
						end -- if k < 5
					end

				end -- if d > warpDist

			else -- not ok
				speed = warpers[mobId]
				if speed then
					tes3.setStatistic({reference = mob, name = 'speed', current = speed})
					warpers[mobId] = nil
					doPackWarpers = true
				end
			end -- if ok
		end -- validFollower(mob)
	end -- for mob

	if doPackWarpers then
		packWarpers()
	end

	local count = #lastPlayerPositions
	local i = count + 1
	if i > maxSavedPlayerPositions then
		if logLevel >= 4 then
			mwse.log('%s: %s > maxSavedPlayerPositions (%s)', funcPrefix, i, maxSavedPlayerPositions)
		end
		local v
		local c = 1
		for j = 2, count do
			v = lastPlayerPositions[j]
			if v then
				if v.pos then
					if logLevel >= 3 then
						mwse.log('%s: lastPlayerPositions[%s] = {cellId = "%s", pos = %s}', funcPrefix, c, v.cellId, v.pos)
					end
					lastPlayerPositions[c] = v
					c = c + 1
				end
			end
		end
		i = c
	end
	local good = false
	if i > 1 then
		local prevPP = lastPlayerPositions[i - 1]
		if prevPP then
			local lastPos = prevPP.pos
			if lastPos then
				d = playerPos:distance(lastPos)
				if d >= stepDist then
					if d <= warpDist then
						good = true
						if logLevel >= 3 then
							mwse.log('%s: lastPos: %s, playerPos: %s, playerPos:distance(lastPos) = %s', funcPrefix, lastPos, playerPos, d)
						end
					end
				end
			end
		end
	else
		good = true
	end
	if good then
		if logLevel >= 2 then
			mwse.log('%s: lastPlayerPositions[%s] = {cellId = "%s", pos = %s}', funcPrefix, i, pcCell.id, playerPos)
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
	radStep = math.rad(170 / numTravellers)
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

local function resetTransparency(mobile)
	tes3.applyMagicSource({ -- apply a short chameleon/invisibility to try and fix appearance sometimes buggy after travelling with setinvisible
		reference = mobile,
		name = "Negate Invisibility",
		effects = {  {id = tes3_effect_invisibility, duration = 1}, {id = tes3_effect_chameleon, duration = 2, min = 1, max = 1}, },
		bypassResistances = true
	})
---@diagnostic disable-next-line: redundant-parameter
	local mobHandle = tes3.makeSafeObjectHandle(mobile)
	timer.start({duration = 2.75,
		callback = function ()
			if not mobHandle then
				return
			end
			if not mobHandle:valid() then
				return
			end
			local mob  = mobHandle:getObject()
			if not mob then
				return
			end
			mob.invisibility = 0
---@diagnostic disable-next-line: undefined-field
			mob:updateOpacity()
		end
	})
end

local function travelEnd()
	if logLevel >= 3 then
		mwse.log("%s: travelEnd()", modPrefix)
	end
	stopMoveTravellers()
	local ability, mob, ref
	if travelType > 0 then
		local tp = travelParams[travelType]
		ability = tp.spell
	end
	for id, t in pairs(travellers) do
		if t then
			mob = t.mob
			if mob then
				ref = mob.reference
				if ref then
					if ability then
						if logLevel >= 2 then
							mwse.log("%s: mwscript.removeSpell({reference = %s, spell = %s}), invisibility = %s, acrobatics = %s, nospread = %s", modPrefix, id, ability, t.inv, t.acro, t.ns)
						end
						tes3.removeSpell({reference = mob, spell = ability}) -- remove travelling spell
						---mwscript.removeSpell({reference = mob, spell = ability}) -- remove travelling spell
					end
					resetTransparency(mob)
					mob.invisibility = t.inv -- reset invisibility
					mob:updateOpacity()
					mob.acrobatics.current = t.acro -- reset acrobatics
					mob.movementCollision = true
					if t.ns > 0 then
						local context = ref.context
						if context then
							if context.nospread then
								if logLevel >= 3 then
									mwse.log("%s: %s nospread reset to 0", modPrefix, ref.id)
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
	for id, t in pairs(travellers) do
		if logLevel >= 2 then
			mwse.log("%s: tes3.positionCell({reference = %s, cell = %s})", modPrefix, id, cellId)
		end
		tes3.positionCell({reference = t.mob.reference, position = ppos, orientation = pori, cell = pcell}) -- ensure followers move to player cell
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
	---local doMove
	local tns, traveller
	for _, mobile in pairs(mobilePlayer.friendlyActors) do
		if mobile.actorType == tes3_actorType_npc then
			if isValidScenicFollower(mobile) then
				local _, spread, nospread = getCompanionVars(mobile)
				---doMove = true
				tns = 0
				if spread then -- companion script already providing scenic travelling
					if nospread then
						tns = 1
						mobile.reference.context.nospread = 1 -- set nospread to 1 in the local companion script so vanilla travelling code is skipped
					---else
						---doMove = false -- should not happen with up to date companions, but just in case. Keep using vanilla script for moving
					end
				end

				---if doMove then
					dist = mobile.position:distance(playerPos)
					if dist <= maxDist then
						id = mobile.reference.id
						if logLevel >= 2 then
							mwse.log("%s: %s, dist = %s added to travellers", modPrefix, id, dist)
						end
						traveller = travellers[id]
						if (not traveller)
						or (not traveller.mob) then
							tes3.setAIWander({reference = mobile, range = 0, idles = {30, 0, 0, 0, 0, 0, 0, 0}, reset = true}) -- hopefully local NPC script will stop warping in wander mode
							travellers[id] = {mob = mobile, inv = mobile.invisibility, acro = mobile.acrobatics.current, ns = tns} -- store mobile, invisibility, acrobatics, nospread of follower
							numTravellers = numTravellers + 1
						end
					end
				---end
			end
		end
	end
	if numTravellers > 0 then
		local ability = travelParams[travelType].spell
		local mob
		for id2, t in pairs(travellers) do
			mob = t.mob
			if logLevel >= 2 then
				mwse.log("%s: mwscript.addSpell({reference = %s, spell = %s}), invisibility = 1, acrobatics = 200", modPrefix, id2, ability)
			end
			---mwscript.addSpell({reference = mob, spell = ability})
			tes3.addSpell({reference = mob, spell = ability})
			mob.invisibility = 1 -- setInvisible to avoid aggro cliffracers
			mob.acrobatics.current = 200 -- high acrobatics to avoid damage if cell changed
			mob.movementCollision = false -- this works better especially with multiple guards
		end
		startMoveTravellers()
	end
end

local function startTimedTravelProcess()
	local dur = math.round(1.55 - (0.1 * math.random()), 3)
	if logLevel >= 2 then
		mwse.log("%s: loaded timer.start({duration = %s, callback = timedTravelProcess, iterations = -1})", modPrefix, dur)
	end
	timer.start({duration = dur, callback = timedTravelProcess, iterations = -1})
end

local function fixWeight(w)
	if w then
		if w < 0 then
			w = 10000000 -- try to avoid negative weights, could be fake items from mods trying to fix negative encumbrance
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

local function getRefWeight(ref)
	local weight = ref.baseObject.weight
	weight = fixWeight(weight)
	local count = ref.stackSize
	if not count then
		count = 1
	end
	weight = weight * count
	return weight
end

local function isLootable(obj)
	local skip = false
	local objType = obj.objectType
	--[[
	-- not sure how to use testActionFlag without a proper reference
	if not ref:testActionFlag(tes3_actionFlag_useEnabled) then
		return -- onactivate block present, skip disabling event on scripted activate
	end
	]]
	local script = obj.script
	if script then
		local s = script.context
		if s then
			s = tostring(s) -- convert from script opcodes?
			if s then
				s = s:lower()
			end
		end
		if string.find(s, 'onactivate', 1, true) then
			skip = true
			if objType == CONT_T then
				if obj.organic then
					skip = false
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
	local mobile = activatorRef.mobile
	---assert(mobile)
	local hidden = mobile.chameleon---.current
	if mobile.actorType >= tes3_actorType_npc then -- 0 = creature, 1 = NPC, 2 = player
		hidden = hidden + mobile.sneak.current
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
	local owner = tes3.getOwner(targetRef)
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
local function updateHerbalismSwitch(ref, index)
	if logLevel >= 3 then
		mwse.log("%s: updateHerbalismSwitch(ref=%s, index=%s)", modPrefix, ref.id, index)
	end
	-- valid indices are: 0=default, 1=picked, 2=spoiled
	local sceneNode = ref.sceneNode
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

	---ref.data.GH = (index > 0) and index or nil
	-- now I will rewrite this in a clear way without and/or shortcuts. /abot
	if index then
		if index <= 0 then
			index = nil
		end
	end
	if logLevel >= 3 then
		mwse.log("%s: updateHerbalismSwitch() ref.data.GH = %s)", modPrefix, index)
	end
	ref.data.GH = index
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

local function triggerActivate(activatorRef, targetRef)
	if logLevel >= 3 then
		mwse.log("%s: triggerActivate(activatorRef=%s, targetRef=%s)", modPrefix, activatorRef.id, targetRef.id)
	end
	event.trigger('activate', {activator = activatorRef, target = targetRef}, {filter = targetRef})
end

--[[
local function reevaluateEquipment(mobile)
	if not mobile then
		return
	end
	if tes3.mobilePlayer == mobile then
		return
	end
	local actorType = mobile.actorType -- 0 = creature, 1 = NPC, 2 = player
	local ob = mobile.object
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
[["Great, some %s!"]],
[["Right, I was just looking for some %s."]],
[["Hey, look what I've found, some %s!"]],
[["%s. I think we could sell some!"]],
[["Some %s. Could I keep it for myself?"]],
[["%s. I like that."]],
[["Some %s. The more, the better."]],
[["Do you like %s?"]],
}

local function strip(s)
	return s:gsub('!$', '')
end

local function companionLootContainer(companionRef, targetRef)
	if logLevel >= 3 then
		mwse.log("%s: companionLootContainer(companionRef=%s, targetRef=%s)", modPrefix, companionRef.id, targetRef.id)
	end
	local companionMobile = companionRef.mobile
	---assert(companionMobile)
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

	--[[ --better not trust #
	local inventoryCount = #inventory
	if not inventoryCount then
		return
	end
	if inventoryCount <= 0 then
		return
	end
	]]

	-- transfer inventory to companion
	local vwMax = 0
	local niceLoot
	local items = {}
	local lootedCount = 0
	local inventoryCount = 0
	local encumb = companionMobile.encumbrance
	local capacity = encumb.base - encumb.current
	local count, newCapacity, stackObj, value, weight, vw
	---local ab01goldWeight = tes3.getGlobal('ab01goldWeight')

	for _, stack in pairs(inventory) do
		if stack then
			stackObj = stack.object
			if logLevel >= 2 then
				mwse.log("%s: companionLootContainer item = %s", modPrefix, stackObj.id)
			end
			inventoryCount = inventoryCount + 1
			if isLootable(stackObj) then
				if logLevel >= 3 then
					mwse.log("%s: companionLootContainer item = %s lootable", modPrefix, stackObj.id)
				end
				value = stackObj.value
				if value then -- no value happens /abot
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
					weight = fixWeight(weight)
					count = stack.count
					if logLevel >= 2 then
						mwse.log("%s: companionLootContainer item = %s, value = %s, weight = %s, count = %s", modPrefix, stackObj.id, value, weight, count)
					end
					vw = value/weight
					if (config.alwaysLootOrganic
						and targetObj.organic)
					or (vw >= config.minValueWeightRatio) then
						if count then
							count = math.abs(count)
							weight = weight * count
							newCapacity = capacity - weight
							if (newCapacity >= 1 )
							or (config.allowLooting > 1) then
								if vw > vwMax then
									vwMax = vw
									niceLoot = stackObj.name
								end
								table.insert(items, stack)
								lootedCount = lootedCount + 1
								capacity = newCapacity
							end -- if (capacity
						end -- if count
					end -- if (config
				end -- if value then
			end -- if isLootable(stackObj)
		end -- if stack
	end -- for

	local companionActorType = companionMobile.actorType
	local totalValue = 0
	local num

	local function skipActivateWhileTransfering()
		return false
	end

	if lootedCount > 0 then
		local filter = {priority = 100000}
		event.register('activate', skipActivateWhileTransfering, filter)
		for _, stack in ipairs(items) do
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
				tes3.messageBox(table.choice(niceLootMsg), strip(niceLoot))
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
		---reevaluateEquipment(companionMobile)

		event.unregister('activate', skipActivateWhileTransfering, filter)

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
					local id = targetObj.id:lower()
					if not id:find('chest', 1, true) then
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
		for _, stack in pairs(inventory) do
			obj = stack.object
			if obj then
				if obj.objectType == objectType then
					if obj.name then
						if not obj.name:lower():multifind({'compass','sextant'}) then
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
			end
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

local function sneakForSec(mobile, seconds)
	if not (mobile.actorType == tes3_actorType_npc) then
		return
	end
	if not mobile.isSneaking then
		mobile.forceSneak = true
		timer.start({duration = seconds, callback = function ()
			if mobile then
				mobile.forceSneak = false
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
	local npcMobile = npcRef.mobile
	if not npcMobile then
		return false
	end
	if not (npcMobile.actorType == tes3_actorType_npc) then
		return false
	end
	sneakForSec(npcMobile, 3)
	local npcName = npcRef.object.name
	local targetName = targetRef.object.name
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
				tes3.messageBox("%s:\n\"I opened the %s with the %s.\"", npcName, targetName, strip(key.name))
			end
			return true
		end
	end

	local agility = npcMobile.agility.current
	local luck = npcMobile.luck.current
	local security = npcMobile.security.current
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
				local tnam = strip(targetName)
				if x > 0 then
					local roll = math.random(1, 100)
					if roll <= x then
						lockNode.trap = nil
						tes3.playSound({sound = 'Disarm Trap', reference = targetRef})
						tes3.messageBox("%s:\n\"I managed to disarm the trapped %s with a probe.\"", npcName, tnam)
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
			if magnitudeXchance then
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
	local rayHit = tes3.rayTest{ position = rayStartPos, direction = rayDir,
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
	local activatorName = activatorRef.object.name
	---assert(activatorName)
	if string.len(targetName) > 0 then
		local activatorMobile = activatorRef.mobile
		---assert(activatorMobile)
		local activatorMobileActorType = activatorMobile.actorType
		---assert(activatorMobileActorType)
		local targetType = targetRef.object.objectType
		local s1 = ''
		if (targetType == NPC_T)
		or (targetType == CREA_T)
		or (targetType == CONT_T) then
			s1 = 'care of '
		end
		local s2
		if activatorMobileActorType == tes3_actorType_npc then
			s2 = "%s:\n\"I'll take %sthe %s.\""
		elseif activatorMobileActorType == tes3_actorType_creature then
			s2 = "%s\ntakes %sthe %s."
		end
		if s2 then
			if logLevel >= 2 then
				mwse.log(s2, activatorName, s1, targetName)
			end
			tes3.messageBox(s2, activatorName, s1, strip(targetName))
		end
	end
end

local function deleteReference(ref)
	if ref.itemData then
		ref.itemData = nil
	end
	---mwscript.disable({reference = ref, modify = true})
	ref:disable()
	ref.position.z = ref.position.z + 16384 -- move after disable to try and update lights (and maybe get less problems with collisions when deleting?)
	---mwscript.enable({reference = ref, modify = true}) -- enable it after moving to hopefully refresh collision
	ref:enable()
	---mwscript.disable({reference = ref, modify = true}) -- finally disable
	ref:disable()
	local secDelay
	if ref.object.sourceMod then
		secDelay = 0.5 -- not a spawned thing, safe to setdelete immediately after movement
	else
		secDelay = 7.5 -- big delay, should be safe even for animated/playing sound spawned items
	end
	local refHandle = tes3.makeSafeObjectHandle(ref)
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
	mwscript.addItem({ reference = destActorRef, item = obj.id, count = num })
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
	local doorId = doorObj.id:lower()
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
		mwse.log("%s: companionActivate(targetRef = %s, lootType = %s)", modPrefix, targetRef.id, readableObjectTypes[lootType])
	end
	if lootType == DOOR_T then
		if mayBeRevolvingDoor(targetRef, obj) then
			return
		end
	end

	local mobileTarget = targetRef.mobile
	local weight
	if not mobileTarget then
		if lootType then
			if not ( (lootType == CONT_T)
				or (lootType == DOOR_T) ) then
				weight = getRefWeight(targetRef)
			end
		end
	end

	local companions = {}
	local encumb, capacity, mobileRef, dist, security
	local maxDist = config.maxDistance

	for _, mobile in pairs(mobilePlayer.friendlyActors) do
		if not (mobile == mobilePlayer) then
			local companion, _, _ = getCompanionVars(mobile)
			if companion == 1 then
				mobileRef = mobile.reference
				if logLevel >= 3 then
					mwse.log("%s: getCompanionVars(%s) companion = %s", modPrefix, mobileRef.id, companion)
				end
				dist = mobile.position:distance(targetRef.position)
				if dist <= maxDist then
					if logLevel >= 2 then
						mwse.log("%s: %s distance from %s = %s", modPrefix, mobileRef.id, targetRef.id, dist)
					end
					encumb = mobile.encumbrance
					---assert(encumb)
					capacity = encumb.base - encumb.current
					if logLevel >= 2 then
						mwse.log("%s: %s capacity = %s", modPrefix, mobileRef.id, capacity)
					end
					security = 0
					if mobile.actorType == tes3_actorType_npc then
						security = mobile.security.current
					end
					table.insert(companions, {ref = mobileRef, cap = capacity, sec = security})
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
	for _, comp in ipairs(companions) do
		if overburdenAllowed
		or (comp.cap > 0) then
			maxCapacity = comp.cap
			lastCompanionRef = comp.ref
			break
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
						tes3.messageBox("%s:\n\"Great! I am overburdened already.\"")
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
	---assert(companionMobile)

	if mobileTarget then
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
				local companionMobile = lastCompanionRef.mobile
				sneakForSec(companionMobile, 3)
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
			lt = readableObjectTypes[lootType]
		end
		mwse.log('%s: checkCompanionActivate(lootType = %s)', modPrefix, lt)
	end
	local mobile = targetRef.mobile
	if not lootType then
		return
	end
	if mobile or lootType then
		companionActivate(targetRef)
	end
end

local volumeVoice = 0 -- reset in loaded()

local function combatFix(mobile)
	local v = tes3.worldController.audioController.volumeVoice
	if v > 0 then
		if logLevel >= 3 then
			mwse.log('%s: combatFix("%s") volumeVoice = tes3.worldController.audioController.volumeVoice = %s stored',
					modPrefix, mobile.reference.id, v)
		end
		volumeVoice = v
	end
	if logLevel >= 3 then
		mwse.log('%s: combatFix("%s") , tes3.worldController.audioController.volumeVoice = 0, mobile:startCombat(mobile)',
			modPrefix, mobile.reference.id)
	end
	tes3.worldController.audioController.volumeVoice = 0 -- silence combat voices
	-- note: delay should be enough to silence also other companions attack sounds
	timer.start({duration = 1.5, callback = function ()
		mobile:stopCombat(true)
		if volumeVoice > 0 then
			if logLevel >= 3 then
				mwse.log('%s: combatFix("%s") mobile:stopCombat(true), tes3.worldController.audioController.volumeVoice reset to %s',
					modPrefix, mobile.reference.id, volumeVoice)
			end
			tes3.worldController.audioController.volumeVoice = volumeVoice
		end
	end})
	mobile:startCombat(mobile)
	---mobile:startCombat(tes3.mobilePlayer) -- nope causes the other companions to defend player
end

local function fixMobileAI(mobile)
	if logLevel >= 3 then
		mwse.log("%s: fixMobileAI(%s)", modPrefix, mobile.reference.id)
	end

-- some NullCascade's wizardry
-- https://discord.com/channels/210394599246659585/381219559094616064/826742823218053130
-- does it still work?
	mwse.memory.writeByte({
		address = mwse.memory.convertFrom.tes3mobileObject(mobile) + 0xC0,
		byte = 0x00,
	})

	tes3.playAnimation{reference = mobile, group = 0}

	timer.start({duration = 1, callback = function ()
		combatFix(mobile) -- note to self: the delay is needed!
	end})

	--[[local aiData = mobile.aiData
	if aiData then
		local activePackage = aiData:getActivePackage()
		if activePackage then
			local destination = activePackage.destination
			if destination then
				local playerPos = player.position
				local d = destination:distance(playerPos)
				if d > 1048576 then
					if logLevel >= 3 then
						mwse.log("%s: fixMobileAI(%s) destination distance was %s, activePackage.destination set to player position (%s)", modPrefix, mobile.reference.id, d, playerPos)
					end
					activePackage.destination.x = playerPos.x
					activePackage.destination.y = playerPos.y
					activePackage.destination.z = playerPos.z
				end
			end
		end
	end]]

end

local function addBurden(mobile)
	if not mobile:isAffectedByObject(burdenedSpell) then
		if logLevel >= 3 then
			mwse.log('%s: addBurden("%s")', mobile.reference.id)
		end
		tes3.addSpell({reference = mobile, spell = burdenedSpell})
	end
end

local function removeBurden(mobile)
	if mobile:isAffectedByObject(burdenedSpell) then
		if logLevel >= 3 then
			mwse.log('%s: removeBurden("%s")', mobile.reference.id)
		end
		tes3.removeSpell({reference = mobile, spell = burdenedSpell})
	end
end


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

	if activatorRef == player then
		local targetMobile = targetRef.mobile
		local deadMobile = false
		if targetMobile then
			removeBurden(targetMobile)
			deadMobile = isMobileDead(targetMobile)
			if not deadMobile then
				local AIfixOnActivate = config.AIfixOnActivate
				local skipSneak = mobilePlayer.isSneaking
					and config.skipActivatingFollowerWhileSneaking
				if AIfixOnActivate == 3 then
					fixMobileAI(targetMobile)
					if skipSneak then
						return false
					end
					return
				end
				local companion, _, _ = getCompanionVars(targetMobile)
				if (companion == 1)
				or isValidScenicFollower(targetMobile) then
					if AIfixOnActivate == 2 then
						fixMobileAI(targetMobile)
					elseif AIfixOnActivate == 1 then
						if companion == 1 then
							fixMobileAI(targetMobile)
						end
					end
					if config.transparencyFixOnActivate then
						resetTransparency(targetMobile)
					end
					if targetMobile.actorType == tes3_actorType_npc then -- 0 = creature, 1 = NPC, 2 = player
						if config.fixAcrobatics then
							if targetMobile.acrobatics.current < 200 then
								targetMobile.acrobatics.current = 200
							end
						end
						if config.fixWaterBreathing then
							if targetMobile.waterBreathing < 1 then
								targetMobile.waterBreathing = 1
							end
						end
					end
					if mobilePlayer.isSneaking then
						if targetMobile.actorType == tes3_actorType_creature then
							if tes3.isAffectedBy({reference = mobilePlayer, effect = tes3_effect_slowFall}) then
								if isMount(targetRef) then
									return -- IMPORTANT!!! don't skip normal activate when riding a creature!!!
								end
							end
						end
						if targetMobile.fatigue.current <= 0 then
							targetMobile.fatigue.current = targetMobile.fatigue.base * 0.2 -- stand up from collapsed state
						end
						if skipSneak then
							return false
						end
					end -- if player sneaking
				end -- if companion or follower
			end -- if not deadMobile
		end -- if targetMobile then

		-- not (alive mobile target) below
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

		if targetMobile then
			if config.allowLooting > 0 then
				if deadMobile then
					if isLootable(targetRef.baseObject) then
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
					fixMobileAI(targetMobile)
				end
			end
			return
		end

		-- not a mobile target below

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

		local targetBaseObj = targetRef.baseObject
		---local lootType = targetBaseObj.objectType
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

	local objType = targetRef.object.objectType
	if objType == DOOR_T then
		return
	end

	if config.allowLooting == 0 then
		return
	end

	takeMessageBox(activatorRef, targetRef)
	checkCrime(activatorRef, targetRef)
end


local function checkStartAutoWarpProcess()
	if autoWarp < 1 then
		return
	end
	local dur = math.round(1.25 - (0.05 * math.random()), 3)
	if logLevel >= 2 then
		mwse.log("%s: loaded timer.start({duration = %s, callback = warpFollowers, iterations = -1})", modPrefix, dur)
	end
	timer.start({duration = dur, callback = warpFollowers, iterations = -1})
end

local function combatStopped(e)
	if not (e.actor == mobilePlayer) then
		return
	end
	for _, mob in pairs(mobilePlayer.friendlyActors) do
		if not (mob == mobilePlayer) then
			removeBurden(mob)
		end
	end
end

local function combatStarted(e)
	if (autoAttack == 0)
	and (not autoBurden) then
		return
	end
	local attackerMob = e.actor
	local targetedMob = e.target
	local friendlyActors = mobilePlayer.friendlyActors
	local skip = true
	for _, mob in pairs(friendlyActors) do
		if (mob == targetedMob)
		and (not (mob == attackerMob)) then
			skip = false
			break
		end
	end
	if skip then
		return
	end
	local anyFollower = autoAttack >= 2
	skip = true
	local valid
	for _, mob in pairs(friendlyActors) do
		valid = validFollower(mob, anyFollower, false)
		if valid == 2 then -- companion
			if not inCombat(mob) then
				---mwscript.startCombat({reference = mob.reference, target = attackerMob.reference})
				mob:startCombat(attackerMob)
				skip = false
			end
		elseif valid == 1 then
			if autoBurden then
				addBurden(mob)
			end
			skip = false
		end
	end
	if skip then
		return
	end
	--[[timer.start({type = timer.real, duration = 0.55, callback =
		function ()
			event.trigger('combatStarted', {actor = attackerMob, target = targetedMob})
		end
	})]]
	return false
end

local function checkStartCombatProcess()
	-- should almost replace diligent defenders
	-- but to work if diligent defenders is present priority needs to be higher
	local settings = {priority = 100}
	local enabled = (autoAttack > 0) or autoBurden

	if event.isRegistered('combatStarted', combatStarted, settings) then
		if not enabled then
			event.unregister('combatStarted', combatStarted, settings)
		end
	elseif enabled then
		event.register('combatStarted', combatStarted, settings)
	end

	if event.isRegistered('combatStopped', combatStopped) then
		if not enabled then
			event.unregister('combatStopped', combatStopped)
		end
	elseif enabled then
		event.register('combatStopped', combatStopped)
	end
end

local function loaded()
	player = tes3.player
	---assert(player)
	mobilePlayer = tes3.mobilePlayer
	---assert(mobilePlayer)
	tes3gmst_fPickLockMult = tes3.findGMST(tes3.gmst.fPickLockMult)
	tes3gmst_fTrapCostMult = tes3.findGMST(tes3.gmst.fTrapCostMult)
	lastCompanionRef = nil
	lastTargetRef = nil
	skipPlayerAltActivate = false

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
		for i, v in ipairs(ab01lastPlayerPositions) do
			lastPlayerPositions[i] = {cellId = v.cellId, pos = table2vec(v.pos)}
		end
	end

	checkStartAutoWarpProcess()
	checkStartCombatProcess()

	local ab01travelType = player.data.ab01travelType
	if ab01travelType then
		travelType = ab01travelType
		if travelType > 0 then
			if numTravellers > 0 then
				if logLevel >= 2 then
					mwse.log("%s: loaded travelType = %s, numTravellers = %s", modPrefix, travelType, numTravellers)
				end
				startMoveTravellers()
			end
		end
	end

	initScenicTravelAvailable()
	if scenicTravelAvailable
	and (config.scenicTravelling > 0) then
		startTimedTravelProcess()
		return
	end

	if (travelType > 0)
	and (numTravellers > 0) then
		if logLevel >= 2 then
			mwse.log("%s: loaded travelStop()", modPrefix)
		end
		travelStop()
	end

	if volumeVoice > 0 then
		if logLevel >= 3 then
			mwse.log('%s: loaded() tes3.worldController.audioController.volumeVoice reset to %s', modPrefix, volumeVoice)
		end
		tes3.worldController.audioController.volumeVoice = volumeVoice
		volumeVoice = 0
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
	for i, v in ipairs(lastPlayerPositions) do
		local t3 = vec2table(v.pos)
		local cId = v.cellId
		if logLevel >= 4 then
			mwse.log('%s: save() ab01lastPlayerPositions[%s] = { cellId = "%s", pos = {%s, %s, %s} }', modPrefix, i, cId, t3[1], t3[2], t3[3])
		end
		t[i] = {cellId = cId, pos = t3}
	end
	player.data.ab01lastPlayerPositions = t
end

local function cellChanged(e)
	if not e.previousCell then
		return -- skip at game load
	end
	if e.cell.isInterior
	or e.previousCell.isInterior then
		cleanLastPlayerPositions()
	end
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	---sYes = tes3.findGMST(tes3.gmst.sYes).value
	---sNo = tes3.findGMST(tes3.gmst.sNo).value

	inputController = tes3.worldController.inputController

	--[[if tes3.hasCodePatchFeature(tes3.codePatchFeature.slowfallOverhaul) then
		slowFallAmount = 20
		if logLevel > 0 then
			mwse.log('%s: Code Patch slowfallOverhaul option detected', modPrefix)
		end
	end]]

---@diagnostic disable-next-line: deprecated
	local f = mwscript.setDelete
	assert(f) -- ensure it is still available

	local function createSpell(spellId, spellName, spellEffects)
		return tes3.createObject({objectType = tes3.objectType.spell,
			id = spellId,
			name = spellName,
			castType = tes3.spellType.curse, -- curses are less sticky
			alwaysSucceeds = true,
			sourceLess = true,
			effects = spellEffects
		})
	end

	warpLevSpell = createSpell('ab01smcoLevitate', 'Warping', {{id = tes3_effect_levitate, min = 400, max = 400}})
	waterWalkSpell = createSpell('ab01smcoWaterwalking', 'Water Walking', {{id = tes3_effect_waterWalking, min = 1, max = 1}})
	burdenedSpell = createSpell('ab01smcoBurdened', 'Still', {{id = tes3_effect_burden, min = 2000000000, max = 2000000000}})

	ab01ssDestGlob = tes3.findGlobal('ab01ssDest')
	ab01boDestGlob = tes3.findGlobal('ab01boDest')
	ab01goDestGlob = tes3.findGlobal('ab01goDest')
	ab01goAngleGlob = tes3.findGlobal('ab01goAngle')
	NPCVoiceDistanceGlob = tes3.findGlobal('NPCVoiceDistance')

	initScenicTravelAvailable()

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		logLevel = config.logLevel
		autoWarp = config.autoWarp
		autoAttack = config.autoAttack
		autoBurden = config.autoBurden
		warpFightingCompanions = config.warpFightingCompanions
		warpWaterWalking = config.warpWaterWalking
		if autoWarp >= 2 then
			if NPCVoiceDistanceGlob then -- NPCVoiceDistance = 750 by default
-- increase NPCVoiceDistanceGlob accordingly to avoid annoying "Hwy! Wait for me"
				local v = roundInt(config.warpDistance * 1.5)
				if NPCVoiceDistanceGlob.value < v then
					NPCVoiceDistanceGlob.value = v
				end
			end
		end
		mwse.saveConfig(configName, config, {indent = false})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label="Info",
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo{text = ""}

	local controls = preferences:createCategory{label = modName.."\n"}

	controls:createDropdown{
		label = "Companions Looting:",
		options = {
			{ label = "0. No", value = 0 },
			{ label = "1. Yes, No Overburdening", value = 1 },
			{ label = "2. Yes, Overburdening", value = 2 },
		},
		description = [[Default: 1. Yes, No companion overburdening allowed.
When enabled, Alt + activate to make your companions try and loot the target item/container/corpse
(with/without potential overburdening)]],
		variable = createConfigVariable("allowLooting")
	}

	controls:createSlider{
		label = "Minimum item Value/Weight ratio",
		description = string.format("Minimum Value/Weight ratio for an item to be taken by a companion when looting a container, default: %s",
			defaultConfig.minValueWeightRatio),
		variable = createConfigVariable("minValueWeightRatio")
		,min = 1, max = 100, step = 1, jump = 5
	}

	controls:createYesNoButton{
		label = "Always loot from organic containers",
		description = [[Default: Yes. When enabled, companion NPCs will always loot from organic
containers (e.g. plants) regardless of the Minimum item Value/Weight ratio setting]],
		variable = createConfigVariable("alwaysLootOrganic")
	}

	controls:createSlider{
		label = "Max Loot Distance",
		description = string.format("Maximum distance for an item to be activated by a companion, default: %s game units", defaultConfig.maxDistance),
		variable = createConfigVariable("maxDistance")
		,min = 200, max = 1000, step = 1, jump = 5
	}

	controls:createYesNoButton{
		label = "Allow Companions to use Probes",
		description = [[Default: Yes. When enabled, companion NPCs are allowed to use their stats,
skill and probes to try and disarm traps on the target you Alt + activate.
Probes with no uses left should be automatically dropped]],
		variable = createConfigVariable("allowProbes")
	}

	controls:createYesNoButton{
		label = "Allow Companions to use Lockpicks",
		description = [[Default: Yes. When enabled, companion NPCs are allowed to use their stats, skill and lockpicks
to try and open the target you Alt + activate.
lockpicks with no uses left should be automatically dropped]],
		variable = createConfigVariable("allowLockpicks")
	}

	controls:createYesNoButton{
		label = "Allow Companions to use Open spells",
		description = [[Default: Yes. When enabled, companion NPCs are allowed to use their stats, skill and spells
to try and open the target you Alt + activate.]],
		variable = createConfigVariable("allowMagic")
	}

	controls:createYesNoButton{
		label = "Follower NPCs High Acrobatics",
		description = [[Default: Yes.
When enabled, follower NPCs are given high acrobatics on activate if not already having it.
Useful to avoid them getting damaged on jumping or teleporting]],
		variable = createConfigVariable("fixAcrobatics")
	}
	controls:createYesNoButton{
		label = "Follower NPCs Water Breathing",
		description = [[Default: Yes.
When enabled, follower NPCs are given water breathing on activate if not already having it.
Useful to avoid them getting drowned]],
		variable = createConfigVariable("fixWaterBreathing")
	}

	controls:createYesNoButton{
		label = "Skip follower activation while sneaking/unconscious",
		description = [[Default: Yes. When enabled, you will not be able to activate a follower while you are sneaking or while the follower is unconscious,
avoiding the risk to trigger a pickpocket attempt crime reaction]],
		variable = createConfigVariable("skipActivatingFollowerWhileSneaking")
	}

	controls:createYesNoButton{
		label = "Fix follower transparency on activate",
		description = [[Default: No.
When enabled, try and fix follower transparency on activate.
You can try it if a follower keeps staying transparent without apparent reason.]],
		variable = createConfigVariable("transparencyFixOnActivate")
	}

	controls:createDropdown{
		label = "Fix NPC/Creature AI on activate:",
		options = {
			{ label = "0. No", value = 0 },
			{ label = "1. Yes, Only current companions", value = 1 },
			{ label = "2. Yes, Any follower", value = 2 },
			{ label = "3. Yes, Any actor", value = 3 },
		},
		description = [[Default: 2. Yes, Any follower.
try and reset actors AI when activating them. Especially useful when they go crazy after teleporting around too much.]],
		variable = createConfigVariable("AIfixOnActivate")
	}

	controls:createDropdown{
		label = "Auto attack enemies:",
		options = {
			{ label = "0. No", value = 0 },
			{ label = "1. Yes, Only current companions", value = 1 },
			{ label = "2. Yes, Any follower", value = 2 },
		},
		description = [[An alternative to diligent defenders. If enabled, it should override it having higher priority and delaying the event to next frame.]],
		variable = createConfigVariable("autoAttack")
	}

	controls:createYesNoButton{
		label = "Auto burden followers on combat",
		description = [[Default: No.
Autoburden non-companion followers on combat start, so they are not running after enemies.
N.B.:
- it does not work when you set "Auto attack enemies" option to "2. Yes, Any follower".
- it can meake escort mission too easy.]],
		variable = createConfigVariable("autoBurden")
	}

	controls:createDropdown{
		label = "Logging level:",
		options = {
			{ label = "0. Minimum", value = 0 },
			{ label = "1. Low", value = 1 },
			{ label = "2. Medium", value = 2 },
			{ label = "3. High", value = 3 },
			{ label = "4. Max", value = 4 },
		},
		variable = createConfigVariable("logLevel"),
		description = "Default: 0. Minimum."
	}

	controls:createDropdown{
		label = "Warp to player:",
		options = {
			{ label = "0. No", value = 0 },
			{ label = "1. Yes, Only current companions", value = 1 },
			{ label = "2. Yes, Any follower", value = 2 },
		},
		description = string.format([[Default: 2. Yes, Any follower.
Warp valid companions/followers at player shoulders if distance from player is more than Max Warp Distance (%s).
Note: warping control from this MWSE-Lua mod does not override warping control from the companion vanilla script if present, they coexist, so results may vary.]],
config.warpDistance),
		variable = createConfigVariable("autoWarp")
	}

	controls:createSlider{
		label = "Max Warp Distance",
		description = string.format("Maximum distance before triggering warp to player, default: %s game units", defaultConfig.warpDistance),
		variable = createConfigVariable("warpDistance")
		,min = 512, max = 7200, step = 1, jump = 5
	}

	controls:createYesNoButton{
		label = "Warp fighting companions",
		description = [[Default: No.
When warping is enabled, this option will make them warp to player even during fights.
You can enable this if you want to avoid comnpanions chasing enemies too far, or if they are in a big danger.]],
		variable = createConfigVariable("warpFightingCompanions")
	}

	controls:createYesNoButton{
		label = "Automatic Water walk when warping",
		description = [[Default: Yes.
When warping is enabled, this option will make them waterwalk with player.]],
		variable = createConfigVariable("warpWaterWalking")
	}

	controls:createButton{
		---label = "Emergency stop travelling",
		buttonText = "Emergency stop travelling",
		description = "Force travelling stop in case something goes wrong and followers get stuck in travelling position.",
		inGameOnly = true, -- important as player variable may not be initialized yet
		callback = travelStop
	}

	mwse.mcm.register(template)
	---logConfig(config, {indent = false})

	event.register('save', save)
	event.register('loaded', loaded)
	event.register('cellChanged', cellChanged)

-- high priority to try avoiding problems if another mod does not properly check for activator being the player
-- Book Pickup mod has priority 10
	event.register('activate', activate, {priority = 100000})
	timer.register('ab01SmartCompTravelEnd', travelEnd)

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
