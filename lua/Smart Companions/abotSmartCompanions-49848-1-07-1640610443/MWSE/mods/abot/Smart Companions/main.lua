---@diagnostic disable: deprecated, undefined-field
--[[
Smart Companions
by abot

see modConfigReady() / MCM panel definition for features
]]

-- begin configurable parameters
local defaultConfig = {
allowLooting = 1, -- 0 = No, 1 = Yes, No Overburdening, 2 = Yes, Overburdening
minValueWeightRatio = 10,
alwaysLootOrganic = true, -- always loot from organic containers (e.g. plants) regardless of value/weight ratio
maxDistance  = 384,
allowProbes = true,
allowLockpicks = true,
fixAcrobatics = true, -- follower NPCs are given high acrobatics
fixWaterBreathing = true, -- follower NPCs are given water breathing
skipActivatingFollowerWhileSneaking = true, -- self explaining
AIfixOnActivate = 2, -- 0 = No, 1 = Companions, 2 = All followers
transparencyFixOnActivate = false, -- try and fix follower transparency on activate
scenicTravelling = 2, -- 0 = No, 1 = Companions, 2 = All followers
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
local config = mwse.loadConfig(configName, defaultConfig) or defaultConfig
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

local function getValidObjLootType(obj)
	local ot = obj.objectType
	if config.logLevel >= 3 then
		mwse.log("%s: %s obj.objectType = %s", modPrefix, obj.id, ot)
	end
	if validLootTypes[ot] then
		return ot
	end
	return nil
end

local AS_DEAD = tes3.animationState.dead
local AS_DYING = tes3.animationState.dying

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
	return false
end

local tes3_aiPackage_follow = tes3.aiPackage.follow
local tes3_aiPackage_wander = tes3.aiPackage.wander

local function isValidFollower(mobile)
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
	if mobile == tes3.mobilePlayer then
		return false
	end

	local boundSize_y = mobile.boundSize.y
	if boundSize_y > 64 then -- skip big mesh actors
		if config.logLevel >= 2 then
			mwse.log("%s: %s, boundSize.y %s, skipped", modPrefix, ref.id, boundSize_y)
		end
		return false
	end
	if config.logLevel >= 3 then
		mwse.log("%s: %s", modPrefix, ref.id)
	end

	if mobile.actorType == 0 then -- 0 = creature
		if string.startswith(ref.id:lower(), 'ab01') then -- ab01 prefix, probably some abot's creature having AIEscort package, skip
			return false
		end
		local creature = mobile.object -- tes3creature or tes3creatureInstance
		if creature then
			local script = creature.script
			if script then
				if string.startswith(script.id:lower(), 'ab01') then -- ab01 prefix, probably some abot's creature having AIEscort package, skip
					if config.logLevel >= 3 then
						mwse.log("%s: %s having ab01 prefix, probably some abot's creature with AIEscort package, skip", modPrefix, ref.id)
					end
					return false
				end
			end
		end
	end

	local context = ref.context
	local companion = 0
	if context then
		companion = context.companion
	end

	local ai = tes3.getCurrentAIPackageId(mobile)
	if ai == tes3_aiPackage_follow then
		if config.scenicTravelling >= 2 then
			return true -- >=2 = set to travel with any follower
		elseif companion == 1 then
			return true
		end
	end

	if not (ai == tes3_aiPackage_wander) then
		return false
	end
	if not (companion == 1) then
		return false
	end
	-- special case for wandering companions below

	local oneTimeMove = context.oneTimeMove
	if oneTimeMove then
		return true -- assuming a companion scripted to do move-away using temporary aiwander
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
			if config.logLevel >= 3 then
				mwse.log("%s: %s, companion = %s, spread = %s, nospread = %s", modPrefix, ref.id, companion, spread, nospread)
			end
		end
	end
	return companion, spread, nospread
end

--[[
local function isGlobalPositive(globalVarId)
	local v = tes3.getGlobal(globalVarId)
	if v then
		if v > 0 then
			if math.floor(v) > 0 then
				return true
			end
		end
	end
	return false
end
]]

local function getIntGlobal(globalIntVarId)
	local v = tes3.getGlobal(globalIntVarId) -- getGlobal returns value
	if v then
		v = math.floor(v + 0.5)
	end
	return v
end


 -- reset in loaded()
local travellers = {}
local numTravellers = 0
local travelType = 0 -- 0 = none, 1 = boat, 2 = strider, 3 = gondola

local scenicTravelAvailable
local ab01ssDest, ab01boDest, ab01goDest

local function initScenicTravelAvailable() -- called in initialized()
	ab01boDest = getIntGlobal('ab01boDest')
	ab01ssDest = getIntGlobal('ab01ssDest')
	ab01goDest = getIntGlobal('ab01goDest')
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

--[[
function math.remap(value, lowIn, highIn, lowOut, highOut)
	return lowOut + (value - lowIn) * (highOut - lowOut) / (highIn - lowIn)
end
]]

local function moveTravellers()
	if tes3.menuMode() then
		return
	end
	local tp = travelParams[travelType]
	local dist = tp.spread
	local maxInLine = tp.maxInLine
	---if maxInLine > numTravellers then
		---maxInLine = numTravellers
	---end

	---local playerPos = player.position
	local playerPos = mobilePlayer.position
	---local a1 = player.orientation.z -- -math.pi <= a1 <= math.pi
	local a1, a2
	if travelType == 3 then -- gondola
		a1 = tes3.getGlobal('ab01goAngle')
		a1 = math.rad(a1)
		a2 = a1 + math.pi
	else
		a1 = mobilePlayer.facing
		a2 = a1
	end
	local dd = dist
	local radStep2 = radStep * 2
	local cosa = {
		[1] = math.cos(a1),
		[2] = math.cos(a1 - radStep),
		[3] = math.cos(a1 + radStep),
		[4] = math.cos(a1 - radStep2),
		[5] = math.cos(a1 + radStep2),
	}
	local sina = {
		[1] = math.sin(a1),
		[2] = math.sin(a1 - radStep),
		[3] = math.sin(a1 + radStep),
		[4] = math.sin(a1 - radStep2),
		[5] = math.sin(a1 + radStep2),
	}
	local x = playerPos.x
	local y = playerPos.y
	local z = playerPos.z
	local k = 1
	local mob, pos
	for _, t in pairs(travellers) do
		mob = t.mob
		pos = mob.position
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

local travelStopped = false -- set in travelStop(), used in timedTravelProcess to skip

local function startMoveTravellers()
	radStep = math.rad(170 / numTravellers)
	if config.logLevel >= 2 then
		mwse.log("%s: numTravellers = %s, startMoveTravellers() event.register('simulate', moveTravellers)", modPrefix, numTravellers)
	end
	event.register('simulate', moveTravellers)
end

local function stopMoveTravellers()
	if config.logLevel >= 2 then
		mwse.log("%s: stopMoveTravellers() event.unregister('simulate', moveTravellers)", modPrefix)
	end
	event.unregister('simulate', moveTravellers)
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
	mobile:updateOpacity() --- in theory this should be enough? not really it seems /abot
end

local function travelEnd()
	stopMoveTravellers()
	local ability = travelParams[travelType].spell
	local mob, ref
	for id, t in pairs(travellers) do
		mob = t.mob
		ref = mob.reference
		if config.logLevel >= 2 then
			mwse.log("%s: mwscript.removeSpell({reference = %s, spell = %s}), invisibility = %s, acrobatics = %s, nospread = %s", modPrefix, id, ability, t.inv, t.acro, t.ns)
		end
		mwscript.removeSpell({reference = mob, spell = ability}) -- remove travelling spell
		mob.invisibility = t.inv -- reset invisibility
		resetTransparency(mob)
		mob.acrobatics.current = t.acro -- reset acrobatics
		mob.movementCollision = true
		if t.ns > 0 then
			local context = ref.context
			if context then
				if context.nospread then
					if config.logLevel >= 3 then
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
		if config.logLevel >= 2 then
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

	local boDest = getIntGlobal('ab01boDest')
	local ssDest = getIntGlobal('ab01ssDest')
	local goDest = getIntGlobal('ab01goDest')

	local stop = false
	if travelType == 1 then -- boat
		if boDest then
			if boDest <= 0 then
				if ab01boDest > 0 then
					stop = true
				end
			end
		end
	elseif travelType == 2 then -- strider
		if ssDest then
			if ssDest <= 0 then
				if ab01ssDest > 0 then
					stop = true
				end
			end
		end
	elseif travelType == 3 then -- gondola
		if goDest then
			if goDest <= 0 then
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
		if boDest == ab01boDest then
			if ssDest == ab01ssDest then
				if goDest == ab01goDest then
					return -- none changed, return
				else
					ab01goDest = goDest
					travelType = 3 -- gondola
					tes3.setGlobal('ab01goAngle', 10000) -- reset it
				end
			else
				ab01ssDest = ssDest
				travelType = 2 -- strider
			end
		else
			ab01boDest = boDest
			travelType = 1 -- boat
		end
	else
		return
	end

	local dist, id
	local maxDist = 8192
	local playerPos = player.position
	numTravellers = 0
	---local doMove
	local tns
	for mobile in tes3.iterate(mobilePlayer.friendlyActors) do
		---if not (mobile == mobilePlayer) then
			if mobile.actorType == 1 then -- NPC
				if isValidFollower(mobile) then
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
							if config.logLevel >= 2 then
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
		---end
	end
	if numTravellers > 0 then
		local ability = travelParams[travelType].spell
		local mob
		for id2, t in pairs(travellers) do
			mob = t.mob
			if config.logLevel >= 2 then
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
	local dur = 1.55 - (0.1 * math.random())
	if config.logLevel >= 2 then
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
			s = tostring(s) -- convert from script opcodes
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
		if config.logLevel >= 3 then
			mwse.log("%s: isLootable('%s') false, scripted with OnActivate", modPrefix, obj.id)
		end
		return false -- scripted with OnActivate, not lootable
	end
	if objType == LIGH_T then
		-- not a scripted light
		if obj.isOffByDefault
		and obj.canCarry
		and (obj.radius < 17) then
			return false -- but light may be used as icon
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
	if mobile.actorType >= 1 then -- 0 = creature, 1 = NPC, 2 = player
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
	timer.delayOneFrame(
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
	if config.logLevel >= 3 then
		mwse.log("%s: updateHerbalismSwitch(ref=%s, index=%s)", modPrefix, ref.id, index)
	end
	-- valid indices are: 0=default, 1=picked, 2=spoiled
	local sceneNode = ref.sceneNode
	if not sceneNode then
		return
	end
	local switchNode = sceneNode:getObjectByName("HerbalismSwitch")
	if not switchNode then
		return
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
	if config.logLevel >= 3 then
		mwse.log("%s: updateHerbalismSwitch() ref.data.GH = %s)", modPrefix, index)
	end
	ref.data.GH = index
end

local skipPlayerAltActivate = false -- set/reset to make player unable to Alt+activate for a short time

local function doActivate(activatorRef, targetRef)
	activatorRef:activate(targetRef)
	skipPlayerAltActivate = true
end

local function triggerActivate(activatorRef, targetRef)
	event.trigger('activate', {activator = activatorRef, target = targetRef}, {filter = targetRef})
end

local function companionLootContainer(companionRef, targetRef)
	if config.logLevel >= 3 then
		mwse.log("%s: companionLootContainer(companionRef=%s, targetRef=%s)", modPrefix, companionRef.id, targetRef.id)
	end
	local companionMobile = companionRef.mobile
	---assert(companionMobile)
	local targetObj = targetRef.object
	local targetName = targetObj.name
	local inventory = targetObj.inventory

	if targetObj.organic
	or (not targetObj.isInstance) then
		targetRef:clone() -- resolve container contents
		targetObj = targetRef.object --- important to refresh it!!!
		inventory = targetObj.inventory
		if inventory then
			inventory:resolveLeveledItems()
		end
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
	local stackObj
	---local ab01goldWeight = tes3.getGlobal('ab01goldWeight')
	for _, stack in pairs(inventory) do
		stackObj = stack.object
		if config.logLevel >= 2 then
			mwse.log("%s: companionLootContainer item = %s", modPrefix, stackObj.id)
		end
		inventoryCount = inventoryCount + 1
		if isLootable(stackObj) then
			if config.logLevel >= 3 then
				mwse.log("%s: companionLootContainer item = %s lootable", modPrefix, stackObj.id)
			end
			local value = stackObj.value
			if value then -- no value happens /abot
				local weight = stackObj.weight
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
				if config.logLevel >= 2 then
					mwse.log("%s: companionLootContainer item = %s, value = %s, weight = %s", modPrefix, stackObj.id, value, weight)
				end
				local vw = value/weight
				if (config.alwaysLootOrganic
					and targetObj.organic)
				or (vw >= config.minValueWeightRatio) then
					local count = stackObj.count
					if not count then
						count = 1
					end
					weight = weight * count
					capacity = capacity - weight
					if (capacity >= 1 )
					or (config.allowLooting > 1) then
						if vw > vwMax then
							vwMax = vw
							niceLoot = stackObj.name
						end
						table.insert(items, stack)
						lootedCount = lootedCount + 1
					end
				end
			end
		end
	end

	local actorType = companionMobile.actorType
	local totalValue = 0
	local num

	if lootedCount > 0 then
		for _, stack in ipairs(items) do
			stackObj = stack.object
			num = stack.count
			totalValue = (stackObj.value * num) + totalValue
			tes3.transferItem({from = targetRef, to = companionRef,	item = stackObj, itemData = stackObj.itemData,
				count = num, playSound = false, updateGUI  = false})
		end

		if actorType == 1 then -- NPC
			local i
			if niceLoot then
				i = math.random(100)
				if i > 75 then
					tes3.messageBox("\"Hey, some %s!\"", niceLoot)
				elseif i > 50 then
					tes3.messageBox("\"I found some %s in there!\"", niceLoot)
				elseif i > 25 then
					tes3.messageBox("\"Let's see... great, some %s.\"", niceLoot)
				end
			end
			i = math.random(100)
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
		tes3.playSound({sound = 'Item Misc Up', reference = companionRef})
	elseif actorType == 1 then -- NPC
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

	if targetObj.organic then
		if GHerbLoaded then -- Graphic Herbalism loaded
			if not targetObj.script then
				-- valid indexes are: 0 = default, 1 = picked, 2 = spoiled
				if lootedCount >= inventoryCount then
					updateHerbalismSwitch(targetRef, 2) -- spoiled
				elseif lootedCount > 0 then
					updateHerbalismSwitch(targetRef, 1) -- picked
				end
			end -- if not targetObj.script
		end -- if GHerbLoaded
	elseif MWCAloaded then -- Morrowind Containers Animated loaded
		---mwse.log(">MWCAloaded")
		-- try and trigger animated container opening
		---triggerActivate(companionRef, targetRef)
		---mwse.log(">>triggerActivate(%s, %s)", player, targetRef)
		triggerActivate(player, targetRef)
	end

	if lootedCount >= inventoryCount then
		targetRef.isEmpty = true
		if targetObj.organic then
			targetObj.modified = false
		end
	end
	targetObj:onInventoryClose(targetRef)
	checkCrime(companionRef, targetRef, totalValue)
	skipPlayerAltActivate = true
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

local function checkSneakToTarget(mobile, seconds)
	if not mobile.isSneaking then
		mobile.forceSneak = true
		timer.start({duration = seconds, callback = function ()
			if mobile then
				mobile.forceSneak = false
			end
		end})
	end
end

local function tryUnlock(npcRef, targetRef)
	if config.logLevel >= 2 then
		mwse.log("%s: tryUnlock(npcRef=%s, targetRef=%s)", modPrefix, npcRef.id, targetRef.id)
	end
	local lockNode = targetRef.lockNode
	if not lockNode then
		return true
	end
	local mobile = npcRef.mobile
	if mobile then
		checkSneakToTarget(mobile, 3)
	end
	local npcName = npcRef.object.name
	local targetName = targetRef.object.name
	local key = lockNode.key
	if key then
		---if mwscript.getItemCount({reference = npcRef, item = key}) > 0 then
		if npcRef.object.inventory:contains(key) then
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

	local npcMobile = npcRef.mobile
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

	if lockNode.locked
	or lockNode.trap then
		return false
	end
	return true
end


local function tryCompanionThievery(companionRef, targetRef)
	if config.logLevel >= 2 then
		mwse.log("%s: tryCompanionThievery(companionRef=%s, targetRef=%s)", modPrefix, companionRef.id, targetRef.id)
	end
	local unlocked = tryUnlock(companionRef, targetRef)
	if unlocked then
		local objType = targetRef.object.objectType
		if objType == CONT_T then
			if config.allowLooting > 0 then
				companionLootContainer(companionRef, targetRef)
			end
		elseif objType == DOOR_T then
			doActivate(lastCompanionRef, targetRef)
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
		local actorType = activatorMobile.actorType
		assert(actorType)
		local targetType = targetRef.object.objectType
		local s1 = ''
		if (targetType == NPC_T)
		or (targetType == CREA_T)
		or (targetType == CONT_T) then
			s1 = 'care of '
		end
		local s2
		if actorType == 1 then -- NPC
			s2 = "%s:\n\"I'll take %sthe %s.\""
		elseif actorType == 0 then -- creature
			s2 = "%s\ntakes %sthe %s."
		end
		if s2 then
			if config.logLevel >= 2 then
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
	timer.start({duration = secDelay, callback = function ()
		mwscript.setDelete({reference = ref, delete = true})
	end})
end

local function takeItem(destActorRef, targetRef)
	local obj = targetRef.object
	local data = targetRef.itemData
	local num = 1
	if data then
		if data.count then
			num = data.count
		end
	end
	takeMessageBox(destActorRef, targetRef)

	checkCrime(destActorRef, targetRef)
	tes3.playSound({reference = destActorRef, sound = 'Item Book Up'})

	---tes3.addItem({reference = destActorRef, item = obj, itemData = data, count = num}) -- still crashing
	mwscript.addItem({ reference = destActorRef, item = obj.id, count = num })
	deleteReference(targetRef)
end

local function companionActivate(targetRef)
	local lootType = targetRef.object.objectType
	if config.logLevel >= 2 then
		mwse.log("%s: companionActivate(targetRef = %s, lootType = %s)", modPrefix, targetRef.id, lootType)
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
				if config.logLevel >= 3 then
					mwse.log("%s: getCompanionVars(%s) companion = %s", modPrefix, mobileRef.id, companion)
				end
				dist = mobile.position:distance(targetRef.position)
				if dist <= maxDist then
					if config.logLevel >= 2 then
						mwse.log("%s: %s distance from %s = %s", modPrefix, mobileRef.id, targetRef.id, dist)
					end
					encumb = mobile.encumbrance
					---assert(encumb)
					capacity = encumb.base - encumb.current
					if config.logLevel >= 2 then
						mwse.log("%s: %s capacity = %s", modPrefix, mobileRef.id, capacity)
					end
					security = 0
					if mobile.actorType == 1 then -- NPC
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
	local isNPC = lastCompanionRef.mobile.actorType == 1
	if weight then
		if maxCapacity <= weight then
			if config.allowLooting == 1 then -- 1 = Yes, No Overburdening
				if i > 75 then
					if isNPC then
						tes3.messageBox("%s:\n\"I can't carry more than this!\"", companionName)
					else
						tes3.messageBox("%s cannot carry any more.\"", companionName)
					end
				elseif i > 50 then
					if isNPC then
						tes3.messageBox("%s:\n\"%s, I am not your beast of burden!\"", companionName, playerName)
					else
						tes3.messageBox("%s would become overburdened.\"", companionName)
					end
				elseif i > 25 then
					if isNPC then
						tes3.messageBox("%s:\n\"Sorry %s but... no, I can barely move already.\"", companionName, playerName)
					else
						tes3.messageBox("%s cannot carry the %s.\"", companionName, itemName)
					end
				else
					if isNPC then
						tes3.messageBox("%s:\n\"%s? Sorry, too heavy for me.\"", companionName, itemName)
					else
						tes3.messageBox("%s loot is too heavy for %s.\"", itemName, companionName)
					end
				end
				return -- skip
			elseif overburdenAllowed then
				if isNPC then
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
	if config.logLevel >= 3 then
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
				checkSneakToTarget(companionMobile, 3)
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
	local lootType = targetRef.object.objectType
	if config.logLevel >= 2 then
		mwse.log("%s: checkCompanionActivate(targetRef = %s, lootType = %s)", modPrefix, targetRef.id, lootType)
	end
	if not targetRef then
		return
	end
	if not lootType then
		return
	end
	local mobile = targetRef.mobile
	if mobile or lootType then
		companionActivate(targetRef)
	end
end

local function fixMobileAI(mobile)
	if config.logLevel >= 3 then
		mwse.log("%s: fixMobileAI(%s).", modPrefix, mobile.reference.id)
	end
-- some NullCascade's wizardry
-- https://discord.com/channels/210394599246659585/381219559094616064/826742823218053130
	mwse.memory.writeByte({
		address = mwse.memory.convertFrom.tes3mobileObject(mobile) + 0xC0,
		byte = 0x00,
	})
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
end

local function activate(e)
	if not processActivate then
		return
	end
	local targetRef = e.target
	local activatorRef = e.activator

	if activatorRef == player then
		local targetMobile = targetRef.mobile
		local deadMobile = false
		if targetMobile then
			deadMobile = isMobileDead(targetMobile)
			if config.logLevel >= 2 then
				mwse.log("%s: activatorRef = %s, targetMobile = %s", modPrefix, activatorRef.id, targetRef.id)
			end
			if not deadMobile then
				local AIfixOnActivate = config.AIfixOnActivate
				local companion, _, _ = getCompanionVars(targetMobile)
				local isFollower = isValidFollower(targetMobile)
				if (companion == 1)
				or isFollower then
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
					if targetMobile.actorType == 1 then -- 0 = creature, 1 = NPC, 2 = player
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
						if targetMobile.fatigue.current <= 0 then
							targetMobile.fatigue.current = targetMobile.fatigue.base * 0.2
							e.claim = true
							return false
						end
						if mobilePlayer.isSneaking then
							e.claim = true
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
			-- player can activate only normally to allow container animation, no more Alt process
			return
		end

		if targetMobile then
			if config.allowLooting > 0 then
				if deadMobile then
					timer.start({ duration = 0.05,
						callback = function ()
							skipPlayerAltActivate = true
							checkCompanionActivate(targetRef)
							timer.start({ duration = 1, type = timer.real,
								callback = function ()
									skipPlayerAltActivate = false
								end}
							)
						end
					})
					-- skip standard activation this frame!
					e.claim = true
					return false
				else
					fixMobileAI(targetMobile)
				end
			end
			return
		end

		--[[ too restrictive
		local hasOnActivate = not targetRef:testActionFlag(tes3.actionFlag.useEnabled)
		if hasOnActivate then
			if config.logLevel >= 2 then
				mwse.log("%s: activatorRef = %s, targetRef = %s hasOnActivate, skip", modPrefix, activatorRef.id, targetRef.id)
			end
			return
		end
		]]

		local targetBaseObj = targetRef.baseObject
		---local lootType = targetBaseObj.objectType
		if getValidObjLootType(targetBaseObj) then
			if isLootable(targetBaseObj) then
				timer.start({ duration = 0.05, type = timer.real,
					callback = function ()
						skipPlayerAltActivate = true
						checkCompanionActivate(targetRef)
						timer.start({ duration = 1,
							callback = function ()
								skipPlayerAltActivate = false
							end}
						)
					end
				})
			end
			-- skip standard activationthis frame!
			e.claim = true
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
					if config.logLevel >= 2 then
						mwse.log("%s: loaded travellers[%s] = {inv = %s, acro = %s, nospread = %s}", modPrefix, id, t.inv, t.acro, t.ns)
					end
					travellers[id] = {mob = mobile, inv = t.inv, acro = t.acro, ns = t.ns}
					numTravellers =	numTravellers + 1
				end
			end
		end
	end

	local ab01travelType = tes3.player.data.ab01travelType
	if ab01travelType then
		travelType = ab01travelType
		if travelType > 0 then
			if numTravellers > 0 then
				if config.logLevel >= 2 then
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
		if config.logLevel >= 2 then
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
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	---sYes = tes3.findGMST(tes3.gmst.sYes).value
	---sNo = tes3.findGMST(tes3.gmst.sNo).value

	initScenicTravelAvailable()

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
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
		description = [[Default: Yes.When enabled, you will not be able to activate a follower while you are sneaking or while the follower is unconscious,
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

	if scenicTravelAvailable then
		controls:createDropdown{
			label = "Detect and apply Scenic Travelling:",
			options = {
				{ label = "0. No", value = 0 },
				{ label = "1. Yes, Only current companions", value = 1 },
				{ label = "2. Yes, Any follower", value = 2 },
			},
			description = [[Default: 2. Yes, Any follower.
Detect abot's modded Scenic Travelling and apply it to followers not already implementing scenic travelling in their local script (the majority of them).
Basically you should be able to scenic travel with any follower now.
Note: followers too big for scenic travelling like guars or wolves should not be included.]],
		variable = createConfigVariable("scenicTravelling")
		}
	else
		config.scenicTravelling = 0
	end

	mwse.mcm.register(template)
	logConfig(config, {indent = false})
	checkProcessActivate()
end
event.register('modConfigReady', modConfigReady) -- WTF this even happens before initialized

local function initialized()

	inputController = tes3.worldController.inputController
	local f = mwscript.setDelete
	assert(f) -- ensure it is still available

	initScenicTravelAvailable()
	event.register('save', save)
	event.register('loaded', loaded)

-- high priority to try avoiding problems if another mod does not properly check for activator being the player
-- Book Pickup mod has priority 10
	event.register('activate', activate, {priority = 9999})
	mwse.log("%s: initialized", modPrefix)
end
event.register('initialized', initialized)

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