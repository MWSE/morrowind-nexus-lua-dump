---@diagnostic disable: undefined-field, deprecated
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
AIfixOnActivate = 2, -- 0 = No, 1 = Companions, 2 = All followers
transparencyFixOnActivate = false, -- try and fix follower transparency on activate
scenicTravelling = 2, -- 0 = No, 1 = Companions, 2 = All followers
autoWarp = 2, -- 0 = No, 1 = Companions, 2 = All followers
warpDistance = 680,
warpFightingCompanions = false,
warpWaterWalking = true, -- allow automatic waterWalking when warping
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium 3 = High
}
-- end configurable parameters

local author = 'abot'
local modName = 'Smart Companions'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

-- note the or defaultConfig is mostly to avoid Cisual Studio Code false problems detection
local config = mwse.loadConfig(configName, defaultConfig)
---assert(config)

-- to be reset in loaded()
local inputController
local player
local mobilePlayer
local lastCompanionRef
local lastTargetRef
local tes3gmst_fPickLockMult, tes3gmst_fTrapCostMult -- set in loaded()

local LALT = tes3.scanCode.lAlt
local RALT = tes3.scanCode.rAlt

local function isAltDown()
	return inputController:isKeyDown(LALT)
		or inputController:isKeyDown(RALT)
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
			if health.current <= 0 then
				return true
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
local function followOrEscortAI(mob)
	local ai = tes3.getCurrentAIPackageId(mob)
	if (ai == tes3_aiPackage_follow)
	or (ai == tes3_aiPackage_escort) then
		return ai
	end
	return nil
end

local function isValidFollower(mobile, anyFollower, travelling)
	if not isValidMobile(mobile) then
		return false
	end
	local ref = mobile.reference

	local context = ref.context
	local companion = 0
	if context then
		if context.companion then
			companion = context.companion
		end
	end
	local isCompanion = (companion == 1)

	if not warpFightingCompanions then
		if isCompanion then
			if not travelling then
				if mobile.inCombat then
					return false
				end
			end
		end
	end

	local ai = followOrEscortAI(mobile)

	if ai then
		if isCompanion then
			if travelling then
				return true
			else
				if warpFightingCompanions then
					return true
				else
					if mobile.actionData then
						if mobile.actionData.target then
							return false
						end
					end
					return true
				end
			end
		else
			if anyFollower then
				if ref.object.isGuard then
					return false
				else
					return true
				end
			else
				return false
			end
		end
	end

	-- special case for wandering companions
	if isCompanion then
		if ai then
			if ai == tes3_aiPackage_wander then
				if context then
					local oneTimeMove = context.oneTimeMove
					if oneTimeMove then
-- assuming a companion scripted to do move-away using temporary aiwander
						return true
					end
				end
			end
		end
	end

	return false
end

local function isValidScenicFollower(mobile)
	local anyFollower = config.scenicTravelling >= 2
	if isValidFollower(mobile, anyFollower, true) then
		local ref = mobile.reference
		local boundSize_y = mobile.boundSize.y * ref.scale
		if boundSize_y > 64 then -- skip big mesh actors
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

 -- reset in loaded()
local travellers = {}
local numTravellers = 0
local travelType = 0 -- 0 = none, 1 = boat, 2 = strider, 3 = gondola
local warpers = {}

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
	[1] = {spell = 'ab01boSailAbility', spread = 28, maxInLine = 5}, -- boat
	[2] = {spell = 'ab01ssMountAbility', spread = 29, maxInLine = 5}, -- strider
	[3] = {spell = 'water walking (unique)', spread = 24, maxInLine = 1}, -- gondola
	---[4] = 'ab01mountNPCAbility', -- guar mounting
}

local radStep = 0

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
	local tp = travelParams[travelType]
	local dist = tp.spread
	local maxInLine = tp.maxInLine
	---local a1 = player.orientation.z -- -math.pi <= a1 <= math.pi
	local a1, a2
	if travelType == 3 then -- gondola
		a1 = ab01goAngleGlob.value
		a1 = math.rad(a1)
		a2 = a1 + math.pi
	else
		a1 = mobilePlayer.facing
		a2 = a1
	end

	local dd = dist
	local cosa, sina = getCosSin(a1)
	local playerPos = mobilePlayer.position
	local x = playerPos.x
	local y = playerPos.y
	local z = playerPos.z
	local k = 1
	local mob, pos
	for _, t in pairs(travellers) do
		mob = t.mob
		if mob then
			pos = mob.position
			if pos then
				pos.z = z
				-- move behind the player to not interfere with player scenic view
				pos.x = x - (dist * sina[k])
				pos.y = y - (dist * cosa[k])
				mob.reference.orientation.z = a2 -- look front
				---mwse.log("k = %d, dist = %d, x = %s, y = %s", k, dist, pos.x, pos.y)
				if k < maxInLine then
					k = k + 1
				else
					k = 1
					dist = dist + dd -- if more than maxInLine one more step behind and reset angle
					---mwse.log("k = %d, dist = %d, dd = %s", k, dist, dd)
				end
			end
		end
	end
end

local warpLevSpell -- created in modConfigReady()
local function createWarpLevSpell()
	local spell = tes3.createObject({objectType = tes3.objectType.spell,
		id = 'ab01smcoLevitate',
		name = 'Warping',
		castType = tes3.spellType.ability,
		alwaysSucceeds = true,
		sourceLess = true,
		effects = {{id = tes3.effect.levitate, min = 400, max = 400}}
	})
	return spell
end

local tes3_effect_slowFall = tes3.effect.slowFall

local slowFallAmount = 1 -- updated in modConfigReady()

local lastPlayerPositions = {} -- reset in loaded()

local function packLastPlayerPositions()
	local t = {}
	for _, v in ipairs(lastPlayerPositions) do
		if v then
			table.insert(t, v)
		end
	end
	lastPlayerPositions = t
end

local function isMount(ref)
	if string.multifind(ref.id:lower(), {'guar', 'horse', 'mount'}, 1, true) then
		return true
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
	local maxSavedPositions = 10
	local stepDist = 128
	local dist = 64
	local dd = 58
	local anyFollower = autoWarp >= 2
	local pcAngleZ = mobilePlayer.facing
	local cosa, sina = getCosSin(pcAngleZ)
	local playerPos = player.position
	local px = playerPos.x
	local py = playerPos.y
	local playerPosZ = playerPos.z
	local pz = playerPosZ
	local pcCell = player.cell
	local warpDist = config.warpDistance
	local playerLevitate = mobilePlayer.levitate
	local k = 1
	local mobRef, mobId, pos, d, mobCell, notInPlayerCell, newPosFound, ori
	local context, stayOutside, boundSize_y, speed, speed2, doPack, ok

	local funcPrefix = string.format('%s %s', modPrefix, 'warpFollowers()')
	local playerSlowfall = tes3.isAffectedBy({reference = mobilePlayer, effect = tes3_effect_slowFall})

	for mob in tes3.iterate(mobilePlayer.friendlyActors) do
		if isValidFollower(mob, anyFollower, false) then
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

				if mob:isAffectedByObject(warpLevSpell) then
					if playerLevitate <= 0 then
						pz = playerPosZ
						if mob.actorType == tes3_actorType_creature then -- npcs should have high acrobatics already
							local dz = math.abs(pz - pos.z)
							if dz > 128 then
								if not tes3.isAffectedBy({reference = mobRef, effect = tes3_effect_slowFall}) then
									tes3.applyMagicSource({ -- apply a slowfall
										reference = mob,
										name = "Landing",
										effects = { {id = tes3_effect_slowFall, duration = 20, min = slowFallAmount, max = slowFallAmount} },
										bypassResistances = true,
									})
								end
							end
						end
						---tes3.removeSpell({reference = mobRef, spell = warpLevSpell})
						mwscript.removeSpell({reference = mobRef, spell = warpLevSpell})
					end
				elseif playerLevitate > 0 then
					if not mob:isAffectedByObject(warpLevSpell) then
						pz = playerPosZ + 16
						tes3.addSpell({reference = mobRef, spell = warpLevSpell})
					end
				end -- mob:isAffectedByObject(warpLevSpell)

				--- check for waterwalking
				if warpWaterWalking then
					if mob.waterWalking == 1 then
						if mobilePlayer.waterWalking <= 0 then
							mob.waterWalking = 0
						end
					elseif mobilePlayer.waterWalking == 1 then
	-- comparison with standard 1 is important as important as it may be used as flag with different walues e.g. in guar mod
						mob.waterWalking = 1
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

					newPosFound = nil
					doPack = false

					for i = #lastPlayerPositions, 1, -1 do
						local v = lastPlayerPositions[i]
						if v then
							if v.cellId == pcCell.id then
								d = v.pos:distance(playerPos)
								if d >= stepDist then
									if d <= warpDist then
										pos.x = v.pos.x
										pos.y = v.pos.y
										pos.z = v.pos.z
										newPosFound = i
										if logLevel >= 2 then
											mwse.log('%s: newPosFound = %s', funcPrefix, i)
										end
										lastPlayerPositions[i] = nil
										doPack = true
										break
									end -- if d <= warpDist
								end -- if d >= stepDist
							else
								lastPlayerPositions[i] = nil
								doPack = true
							end -- if v.cellId
						end -- if v
					end -- for i

					if doPack then
						packLastPlayerPositions()
					end

					if newPosFound then
						if notInPlayerCell then
							if pcCell.isInterior then
								if mobCell.isOrBehavesAsExterior then
									context = mobRef.context
									if context then
										stayOutside = context.stayOutside
										if stayOutside then
											if stayOutside == 1 then
												newPosFound = nil
											end -- if stayOutside == 1
										end -- if stayOutside
									end -- if context
								end -- if mobCell.isOrBehavesAsExterior
								if newPosFound then
									if logLevel >= 2 then
										mwse.log('%s: tes3.positionCell({ref = "%s", pos = %s, ori.z = %s, cell = "%s"})', funcPrefix, mobRef, pos, ori.z, pcCell.name)
									end
									tes3.positionCell({reference = mob, position = pos, orientation = ori, cell = pcCell})
								end
							else
								if logLevel >= 2 then
									mwse.log('%s: tes3.positionCell({ref = "%s", pos = %s, ori.z = %s, cell = "%s"})', funcPrefix, mobRef, pos, ori.z, pcCell.editorname)
								end
								tes3.positionCell({reference = mob, position = pos, orientation = ori, cell = pcCell})
							end -- if pcCell.isInterior
						else
							if logLevel >= 2 then
								mwse.log('%s: ref = "%s", pos = %s, ori.z = %s', funcPrefix, mobRef, pos, ori.z)
							end
						end -- if notInPlayerCell
					else -- if newPosFound
						pos.z = pz
						pos.x = px - (dist * sina[k])
						pos.y = py - (dist * cosa[k])
						if not mobilePlayer:getViewToPoint(pos)	then -- try avoiding stuck-in-wall positions
							newPosFound = 0
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
				end
			end -- if ok
		end -- isValidFollower(mob)
	end -- for mob

	local i = #lastPlayerPositions + 1
	if i >= maxSavedPositions then
		i = maxSavedPositions
		lastPlayerPositions[1] = nil
		packLastPlayerPositions()
	end

	if i == 1 then
		lastPlayerPositions[i] = {cellId = pcCell.id, pos = playerPos}
	else
		local prevPP = lastPlayerPositions[i - 1]
		if prevPP then
			local lastPos = prevPP.pos
			if lastPos then
				d = playerPos:distance(lastPos)
				if d >= stepDist then
					if d <= warpDist then
						if logLevel >= 2 then
							mwse.log('%s: lastPlayerPositions[%s] = {cellId = "%s", pos = %s}', funcPrefix, i, pcCell.id, playerPos)
						end
						lastPlayerPositions[i] = {cellId = pcCell.id, pos = playerPos} -- store good previous player position
					end
				end
			end
		end
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
			mob:updateOpacity()
		end
	})
end

local function travelEnd()
	stopMoveTravellers()
	local ability = travelParams[travelType].spell
	local mob, ref
	for id, t in pairs(travellers) do
		mob = t.mob
		ref = mob.reference
		if logLevel >= 2 then
			mwse.log("%s: mwscript.removeSpell({reference = %s, spell = %s}), invisibility = %s, acrobatics = %s, nospread = %s", modPrefix, id, ability, t.inv, t.acro, t.ns)
		end
		mwscript.removeSpell({reference = mob, spell = ability}) -- remove travelling spell
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
	resetTransparency(mobilePlayer)
	travellers = {}
	numTravellers = 0
	travelType = 0
	initScenicTravelAvailable()
	travelStopped = false
end

local function travelStop()
	local ppos = player.position
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
	timer.start({duration = 1, callback = travelEnd})
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
		return
	end

	local dist, id
	local maxDist = 8192
	local playerPos = player.position
	numTravellers = 0
	---local doMove
	local tns
	for mobile in tes3.iterate(mobilePlayer.friendlyActors) do
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
						if not travellers[id] then
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
			mwscript.addSpell({reference = mob, spell = ability})
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
	assert(mobile)
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

	if lootedCount > 0 then
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
				local niceLootMsg = {
					[["Hey, some %s!"]],
					[["I found some %s in there!"]],
					[["Let's see... great, some %s."]],
					[["Wow, I found some %s."]],
					[["Hmm... more %s."]],
					[["There! some %s."]],
					[["Some %s. How typical."]],
				}
				tes3.messageBox(table.choice(niceLootMsg), niceLoot)
			end
			local i = math.random(100)
			if i > 75 then
				tes3.messageBox("%s:\n\"Let's see if we can find some decent loot with that %s.\"", activatorName, targetName)
			elseif i > 50 then
				tes3.messageBox("%s:\n\"%s, let's see what can be found with that %s.\"", activatorName, player.object.name, targetName)
			elseif i > 25 then
				tes3.messageBox("%s:\n\"All right, I'll check that %s.\"", activatorName, targetName)
			else
				tes3.messageBox("%s:\n\"I'll take care of this %s.\"", activatorName, targetName)
			end
		end

		tes3.updateInventoryGUI({reference = targetRef})
		tes3.updateMagicGUI({reference = targetRef})
		tes3.updateInventoryGUI({reference = companionRef})
		tes3.updateMagicGUI({reference = companionRef})

		tes3.playSound({sound = 'Item Misc Up', reference = companionRef})
		---reevaluateEquipment(companionMobile)
	elseif companionActorType == tes3_actorType_npc then
		local i = math.random(100)
		local playerName = player.object.name
		if capacity >= 1 then
			if i > 75 then
				tes3.messageBox("%s:\n\"Hmmm... nothing good with that %s.\"", activatorName, targetName)
			elseif i > 50 then
				tes3.messageBox("%s:\n\"%s, I think there is nothing more worth taking from that %s.\"", activatorName, playerName, targetName)
			elseif i > 25 then
				tes3.messageBox("%s:\n\"No good loot in the %s.\"", activatorName, targetName)
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
			mwse.log(">>triggerActivate(%s, %s)", player, targetRef)
			setSkipPlayerAltActivate()
			triggerActivate(player, targetRef) -- nope crashing
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
	assert(inventory)
	if inventory then
		local obj, iData, condition
		for stack in tes3.iterate(inventory.iterator) do
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
										mwscript.removeItem({ reference = actorRef, item = obj, count = 1}) -- removes item with 0 uses left
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

	for spl in tes3.iterate(spells.iterator) do
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
		table.sort(t, function(a,b) return a.magnitudeXchance > b.magnitudeXchance end) -- sort by descending cost * chance
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
				tes3.messageBox("%s:\n\"I opened the %s with the %s.\"", npcName, targetName, key.name)
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
				if x > 0 then
					local roll = math.random(1, 100)
					if roll <= x then
						lockNode.trap = nil
						tes3.playSound({sound = 'Disarm Trap', reference = targetRef})
						tes3.messageBox("%s:\n\"I managed to disarm the trapped %s with a probe.\"", npcName, targetName)
					else
						tes3.playSound({sound = 'Disarm Trap Fail', reference = targetRef})
						tes3.messageBox("%s:\n\"I failed to disarm the trapped %s.\"", npcName, targetName)

						if not lockNode.locked then
							npcRef:activate(targetRef) -- trigger the trap!?
						end
					end
				else
					tes3.messageBox("%s:\n\"I can't disarm the trapped %s.\"", npcName, targetName)
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
					assert(fPickLockMult)
					fPickLockMult = -1
				end
				local lockStrength = lockNode.level
				assert(lockStrength)
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
						tes3.messageBox("%s:\n\"I managed to unlock the %s.\"", npcName, targetName)
					else
						tes3.playSound({sound = 'LockedChest', reference = targetRef})
						tes3.messageBox("%s:\n\"I failed to unlock the %s.\"", npcName, targetName)
					end
				else
					tes3.messageBox("%s:\n\"I can't unlock the %s.\"", npcName, targetName)
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
	assert(targetName)
	local activatorName = activatorRef.object.name
	assert(activatorName)
	if string.len(targetName) > 0 then
		local activatorMobile = activatorRef.mobile
		assert(activatorMobile)
		local activatorMobileActorType = activatorMobile.actorType
		assert(activatorMobileActorType)
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
			tes3.messageBox(s2, activatorName, s1, targetName)
		end
	end
end

local function deleteReference(ref)
	if ref.itemData then
		ref.itemData = nil
	end
	mwscript.disable({reference = ref, modify = true})
	ref.position.z = ref.position.z + 16384 -- move after disable to try and update lights (and maybe get less problems with collisions when deleting?)
	mwscript.enable({reference = ref, modify = true}) -- enable it after moving to hopefully refresh collision
	mwscript.disable({reference = ref, modify = true}) -- finally disable
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
				mwscript.setDelete({reference = r, delete = true})
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
	return true -- may be a revoving door
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

	for mobile in tes3.iterate(mobilePlayer.friendlyActors) do
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
						tes3.messageBox("%s would become overburdened.\"", companionName)
					end
				elseif i > 25 then
					if companionIsNPC then
						tes3.messageBox("%s:\n\"Sorry %s but... no, I can barely move already.\"", companionName, playerName)
					else
						tes3.messageBox("%s cannot carry the %s.\"", companionName, itemName)
					end
				else
					if companionIsNPC then
						tes3.messageBox("%s:\n\"%s? Sorry, too heavy for me.\"", companionName, itemName)
					else
						tes3.messageBox("%s loot is too heavy for %s.\"", itemName, companionName)
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
						tes3.messageBox("%s:\n\"%s, I cannot move freely any more while carrying this %s.\"", companionName, playerName, itemName)
					else
						tes3.messageBox("%s:\n\"Great! I am overburdened already.\"")
					end
				elseif i > 75 then
					tes3.messageBox("%s:\n\"%s is overburdened by the %s.\"", companionName, itemName)
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

local function fixMobileAI(mobile)
	if logLevel >= 3 then
		mwse.log("%s: fixMobileAI(%s)", modPrefix, mobile.reference.id)
	end

--[[
-- some NullCascade's wizardry
-- https://discord.com/channels/210394599246659585/381219559094616064/826742823218053130
-- does not work anymore?
	mwse.memory.writeByte({
		address = mwse.memory.convertFrom.tes3mobileObject(mobile) + 0xC0,
		byte = 0x00,
	})
]]

	tes3.cancelAnimationLoop({reference = mobile}) -- will this work with silly creature attack loop sounds?

	local aiData = mobile.aiData
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
	end

end

local processActivate = false
local function checkProcessActivate()
	processActivate = (config.allowLooting > 0)
	or (config.AIfixOnActivate > 0)
	or config.allowProbes
	or config.allowLockpicks
	or config.fixAcrobatics
	or config.fixWaterBreathing
	or config.skipActivatingFollowerWhileSneaking
	or config.transparencyFixOnActivate
end


local function activate(e)
	if not processActivate then
		return
	end
	local targetRef = e.target

	local activatorRef = e.activator
	if not activatorRef then
		return -- it happens
	end

	if logLevel >= 3 then
		mwse.log("%s: activate() activatorRef = %s, player = %s, targetRef = %s, skipPlayerAltActivate = %s", modPrefix, activatorRef.id, player.id, targetRef.id, skipPlayerAltActivate)
	end

	if activatorRef == player then
		local targetMobile = targetRef.mobile
		local deadMobile = false
		if targetMobile then
			deadMobile = isMobileDead(targetMobile)
			if not deadMobile then
				local AIfixOnActivate = config.AIfixOnActivate
				local companion, _, _ = getCompanionVars(targetMobile)
				if (companion == 1)
				or isValidScenicFollower(targetMobile) then
					if AIfixOnActivate > 1 then
						fixMobileAI(targetMobile)
					elseif AIfixOnActivate > 0 then
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
					if config.skipActivatingFollowerWhileSneaking then
						if mobilePlayer.isSneaking then
							if targetMobile.actorType == tes3_actorType_creature then
								---if mobilePlayer:getActiveMagicEffects({effect = tes3_effect_slowfall}) then
								if tes3.isAffectedBy({reference = mobilePlayer, effect = tes3_effect_slowFall}) then
									if isMount(targetRef) then
										return -- IMPORTANT!!! don't skip activate detection when riding a creature!!!
									end
								end
							end
							return false -- skip this activate sneaking
						end
						if targetMobile.fatigue.current <= 0 then
							targetMobile.fatigue.current = targetMobile.fatigue.base * 0.2
							---e.claim = true
							return false
						end
					end
				end
			end -- if not deadMobile
		end -- if targetMobile then

		-- not (alive mobile target) below
		if not targetRef then
			return
		end
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

local function loaded()
	player = tes3.player
	assert(player)
	mobilePlayer = tes3.mobilePlayer
	assert(mobilePlayer)
	tes3gmst_fPickLockMult = tes3.findGMST(tes3.gmst.fPickLockMult)
	tes3gmst_fTrapCostMult = tes3.findGMST(tes3.gmst.fTrapCostMult)
	lastCompanionRef = nil
	lastTargetRef = nil
	skipPlayerAltActivate = false

	stopMoveTravellers()
	travelType = 0
	numTravellers = 0
	travellers = {}

	local ab01travellers = tes3.player.data.ab01travellers
	if ab01travellers then
		local ref, mobile
		-- try reconstructing correct references from id
		for id, t in pairs(ab01travellers) do
			ref = tes3.getReference(id)
			if ref then
				mobile = ref.mobile
				if mobile then
					if not t.ns then
						t.ns = 1
					end
					if logLevel >= 2 then
						mwse.log("%s: loaded travellers[%s] = {inv = %s, acro = %s, nospread = %s}", modPrefix, id, t.inv, t.acro, t.ns)
					end
					travellers[id] = {mob = mobile, inv = t.inv, acro = t.acro, ns = t.ns}
					numTravellers =	numTravellers + 1
				end
			end
		end
	end

	warpers = {}
	local ab01warpers = tes3.player.data.ab01warpers
	if ab01warpers then
		local ref, mobile
		-- try reconstructing correct references from id
		for id, speed in pairs(ab01warpers) do
			if speed then
				ref = tes3.getReference(id)
				if ref then
					mobile = ref.mobile
					if mobile then
						if logLevel >= 2 then
							mwse.log("%s: loaded warpers[%s] = %s", modPrefix, id, speed)
						end
						warpers[id] = speed
					end
				end
			end
		end
	end

	lastPlayerPositions = {}

	checkStartAutoWarpProcess()

	local ab01travelType = tes3.player.data.ab01travelType
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


end

local function save()
	tes3.player.data.ab01travelType = travelType
	local ab01travellers = {}
	if travellers then
		for id, t in pairs(travellers) do
-- cannot store pointers in saves, they have to be reconstructed from id on reload
			ab01travellers[id] = {inv = t.inv, acro = t.acro, ns = t.ns}
		end
	end
	tes3.player.data.ab01travellers = ab01travellers

	local ab01warpers = {}
	if warpers then
		for id, speed in pairs(warpers) do
			if speed then
				ab01warpers[id] = speed
			end
		end
	end
	tes3.player.data.ab01warpers = ab01warpers

end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	---sYes = tes3.findGMST(tes3.gmst.sYes).value
	---sNo = tes3.findGMST(tes3.gmst.sNo).value

	inputController = tes3.worldController.inputController

	if tes3.hasCodePatchFeature(tes3.codePatchFeature.slowfallOverhaul) then
		slowFallAmount = 20
		if logLevel > 0 then
			mwse.log('%s: Code Patch slowfallOverhaul option detected', modPrefix)
		end
	end

	local f = mwscript.setDelete
	assert(f) -- ensure it is still available

	warpLevSpell = createWarpLevSpell()

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
		warpFightingCompanions = config.warpFightingCompanions
		warpWaterWalking = config.warpWaterWalking
		if autoWarp >= 2 then
			if NPCVoiceDistanceGlob then -- NPCVoiceDistance = 750 by default
-- increse NPCVoiceDistanceGlob accordingly to avoid annoying "Hwy! Wait for me"
				local v = roundInt(config.warpDistance * 1.5)
				if NPCVoiceDistanceGlob.value < v then
					NPCVoiceDistanceGlob.value = v
				end
			end
		end
		mwse.saveConfig(configName, config, {indent = false})
		checkProcessActivate()
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
		},
		description = [[Default: 2. 2. Yes, Any follower.
try and fix followers AI when activating them. Especially useful when followers go crazy after teleporting around too much]],
		variable = createConfigVariable("AIfixOnActivate")
	}

	controls:createDropdown{
		label = "Logging level:",
		options = {
			{ label = "0. Minimum", value = 0 },
			{ label = "1. Low", value = 1 },
			{ label = "2. Medium", value = 2 },
			{ label = "3. High", value = 3 },
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
Warp valid companions/followers at player shoulders if distance from player is more than Max Warp Distance (%s).]],
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
When  warping is enabled, this option will make them warp to player even during fights.
You can enable this if you want to avoid comnpanions chasing enemies too far, or if they are in a big danger.]],
		variable = createConfigVariable("warpFightingCompanions")
	}

	controls:createYesNoButton{
		label = "Automatic Water walk when warping",
		description = [[Default: Yes.
When warping is enabled, this option will make them waterwalk with player.]],
		variable = createConfigVariable("warpWaterWalking")
	}

	mwse.mcm.register(template)
	logConfig(config, {indent = false})
	checkProcessActivate()

	event.register('save', save)
	event.register('loaded', loaded)

-- high priority to try avoiding problems if another mod does not properly check for activator being the player
-- Book Pickup mod has priority 10
	event.register('activate', activate, {priority = 100000})

end
event.register('modConfigReady', modConfigReady) -- WTF this even happens before initialized


--[[
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