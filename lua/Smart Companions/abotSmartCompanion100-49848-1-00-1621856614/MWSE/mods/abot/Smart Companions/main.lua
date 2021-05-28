--[[
]]

-- begin configurable parameters
local defaultConfig = {
allowLooting = 1, -- 0 = No, 1 = Yes, No Overburdening, 2 = Yes, Overburdening
minValueWeightRatio = 10,
maxDistance  = 384,
allowProbes = true,
allowLockpicks = true,
AIfixOnActivate = 1, -- 0 = No, 1 = Companions, 2 = All actors
fixAcrobatics = true, -- companion NPCs are given high acrobatics
fixWaterBreathing = true, -- companion NPCs are given water breathing
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

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

-- to be reset in loaded()
local inputController
local mobilePlayer
local lastCompanionRef
local lastTargetRef
local tes3gmst_fPickLockMult, tes3gmst_fTrapCostMult -- set in loaded()

local function loaded()
	inputController = tes3.worldController.inputController
	mobilePlayer = tes3.mobilePlayer
	tes3gmst_fPickLockMult = tes3.findGMST(tes3.gmst.fPickLockMult)
	tes3gmst_fTrapCostMult = tes3.findGMST(tes3.gmst.fTrapCostMult)
	lastCompanionRef = nil
	lastTargetRef = nil
	--[[
	if culledId then
		local ref = tes3.getReference(culledId)
		culledId = nil
		if ref then
			ref.sceneNode.appCulled = false
		end
	end
	]]
end
event.register('loaded', loaded)

local LALT = tes3.scanCode.lAlt
local RALT = tes3.scanCode.rAlt

local function isAltDown()
	return inputController:isKeyDown(LALT)
		or inputController:isKeyDown(RALT)
end

local T3OT = tes3.objectType
local ALCH_T = T3OT.alchemy
local AMMO_T = T3OT.ammunition
local APPA_T = T3OT.apparatus
local ARMO_T = T3OT.armor
local BOOK_T = T3OT.book
local CLOT_T = T3OT.clothing
local CONT_T = T3OT.container
local DOOR_T = T3OT.door
local INGR_T = T3OT.ingredient
local LIGH_T = T3OT.light
local LKPK_T = T3OT.lockpick
local MISC_T = T3OT.miscItem
local PROB_T = T3OT.probe
local REPA_T = T3OT.repairItem
local WEAP_T = T3OT.weapon

--[[
local ACTI_T = T3OT.activator
local STAT_T = T3OT.static
local NPC_T = T3OT.npcMobile
local CREA_T = T3OT.mobileCreature
local ACTR_T = T3OT.mobileActor
]]

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
	if validLootTypes[ot]
	or (
		(ot == LIGH_T)
		and not ( -- skip e.g. CDC inventory helpers light icons
			obj.isOffByDefault
			and obj.canCarry
			and (obj.radius < 17)
		)
	) then
		return ot
	end
	return nil
end

local function getBaseOrObject(ref)
	local obj = ref.object
	if obj.baseObject then
		return obj.baseObject
	end
	return obj
end

--[[
local function getRefLootType(ref)
	local obj = getBaseOrObject(ref)
	return getValidObjLootType(obj)
end
]]

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

local function isValidCompanion(mobile)
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
	local context = ref.context
	if context then
		local companion = context.companion
		if companion then
			if config.logLevel >= 3 then
				mwse.log("%s: %s, companion = %s", modPrefix, ref.id, companion)
			end
			if companion == 1 then
				return true
			end
		end
	end
	return false
end

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
    return tes3.getCurrentAIPackageId(mobile) == tes3.aiPackage.follow
end

local function getWeight(targetRef)
	local targetBaseObj = getBaseOrObject(targetRef)
	local weight = targetBaseObj.weight
	if weight then
		if weight < 0 then
			weight = 0
		end
	else
		weight = 0
	end
	local count = targetRef.stackSize
	if not count then
		count = 1
	end
	weight = weight * count
	return weight
end

local function isLootable(obj)
	if obj.script then
		if config.logLevel >= 3 then
			mwse.log("%s: isLootable(obj = %s), scripted)", modPrefix, obj.id)
		end
		return false
	end
	if obj.objectType == LIGH_T then
		if obj.canCarry then
			if obj.isOffByDefault then
				return false -- light used as icon
			end
		else
			return false
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
		local targetBaseObj = getBaseOrObject(targetRef)
		local value = targetBaseObj.value
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

local function companionLootContainer(companionRef, targetRef)
	if config.logLevel >= 3 then
		mwse.log("%s: companionLootContainer(companionRef=%s, targetRef=%s)", modPrefix, companionRef.id, targetRef.id)
	end
	local companionMobile = companionRef.mobile
	---assert(companionMobile)
	local targetObj = targetRef.object
	local targetName = targetObj.name
	if targetObj.organic
	or (not targetObj.isInstance) then
		targetRef:clone() -- resolve container contents
		targetObj = targetRef.object --- important to refresh it!!!
	end

	local activatorName = companionRef.object.name
	if tes3.getLocked({reference = targetRef}) then
		tes3.playSound({sound = 'LockedChest', reference = targetRef})
		tes3.messageBox("%s: \"This %s is locked.\"", activatorName, targetName)
		return
	end

	local inventory = targetObj.inventory
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
			if value then -- it happens /abot
				local weight = stackObj.weight
				if weight then
					if weight <= 0 then
						weight = 0.01
					end
				else
					weight = 0.01
				end
				if config.logLevel >= 2 then
					mwse.log("%s: companionLootContainer item = %s, value = %s, weight = %s", modPrefix, stackObj.id, value, weight)
				end
				local vw = value/weight
				if vw >= config.minValueWeightRatio then
					capacity = capacity - weight
					if (capacity > 0)
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
	local i
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
				tes3.messageBox("%s:\n\"%s, let's see what can be found with that %s.\"", activatorName, tes3.player.object.name, targetName)
			elseif i > 25 then
				tes3.messageBox("%s:\n\"All right, I'll check that %s.\"", activatorName, targetName)
			else
				tes3.messageBox("%s:\n\"I'll take care of this %s.\"", activatorName, targetName)
			end
		end
		tes3.playSound({sound = 'Item Misc Up', reference = companionRef})
	elseif actorType == 1 then -- NPC
		i = math.random(100)
		if i > 75 then
			tes3.messageBox("%s:\n\"Hmmm... nothing good with that %s.\"", activatorName, targetName)
		elseif i > 50 then
			tes3.messageBox("%s:\n\"%s, there is nothing worth taking with that %s.\"", activatorName, tes3.player.object.name, targetName)
		elseif i > 25 then
			tes3.messageBox("%s:\n\"No good loot in the %s.\"", activatorName, targetName)
		else
			tes3.messageBox("%s:\n\"Hmmm... no luck this time.\"", activatorName)
		end
	end
	targetObj:onInventoryClose(targetRef)
	if lootedCount >= inventoryCount then
		targetRef.isEmpty = true
	end
	checkCrime(companionRef, targetRef, totalValue)
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

local function tryUnlock(npcRef, targetRef)
	if config.logLevel >= 2 then
		mwse.log("%s: tryUnlock(npcRef=%s, targetRef=%s)", modPrefix, npcRef.id, targetRef.id)
	end
	local lockNode = targetRef.lockNode
	if not lockNode then
		return true
	end
	local npcName = npcRef.object.name
	local targetName = targetRef.object.name
	local key = lockNode.key
	if key then
		if mwscript.getItemCount({reference = npcRef, item = key}) > 0 then
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

	if lockNode.locked then
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
		if targetRef.object.objectType == CONT_T then
			companionLootContainer(companionRef, targetRef)
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
		maxDistance = config.maxDistance, ignore = {actorRef, tes3.player} }
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
		if config.logLevel >= 2 then
			mwse.log("%s takes %s.", activatorName, targetName)
		end
		if actorType == 1 then -- NPC
			tes3.messageBox("%s:\n\"I'll take the %s.\"", activatorName, targetName)
		elseif actorType == 0 then -- creature
			tes3.messageBox("%s\ntakes the %s.", activatorName, targetName)
		end
	end
end

local function deleteReference(ref)
	if ref.itemData then
		ref.itemData = nil
	end
	mwscript.disable({reference = ref, modify = true})
	local pos = ref.position:copy()
	pos.z = pos.z + 2048 -- move after disable mostly to try and update lights
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
				weight = getWeight(targetRef)
			end
		end
	end

	local companions = {}
	local encumb, capacity, mobileRef, dist, security
	local maxDist = config.maxDistance

	for mobile in tes3.iterate(mobilePlayer.friendlyActors) do
		if not (mobile == mobilePlayer) then
			if isValidCompanion(mobile) then
				mobileRef = mobile.reference
				if config.logLevel >= 3 then
					mwse.log("%s: isValidCompanion(%s)", modPrefix, mobileRef.id)
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
	local playerName = tes3.player.object.name
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
		companionLootContainer(lastCompanionRef, targetRef)
		return
	end

	local companionMobile = lastCompanionRef.mobile
	if weight then
		if lootType == BOOK_T then -- special case for books
			takeItem(lastCompanionRef, targetRef) -- add one copy to inventory and delete the in-world original
		elseif canWalkTo(lastCompanionRef, targetRef) then -- should be able to walk to the target
			checkSneakToTarget(companionMobile, 3)
			if targetRef.itemData then
				takeItem(lastCompanionRef, targetRef) -- add one copy to inventory and delete the in-world original
			else
				---takeItem(lastCompanionRef, targetRef)
				---tes3.setAIActivate({ reference = lastCompanionRef, target = targetRef }) -- has problems with object.data?
				lastCompanionRef:activate(targetRef)
			end
		else -- force activation from distance
			if targetRef.itemData then
				takeItem(lastCompanionRef, targetRef) -- add one copy to inventory and delete the in-world original
			else
				---takeItem(lastCompanionRef, targetRef)
				lastCompanionRef:activate(targetRef)
			end
		end
		return
	end
	if ( (lootType == CONT_T)
	or (lootType == DOOR_T) ) then
		checkSneakToTarget(companionMobile, 3)
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
end

local tes3UseEnabled = tes3.actionFlag.useEnabled

local function activate(e)
	if not processActivate then
		return
	end
	local targetRef = e.target
	if not targetRef:testActionFlag(tes3UseEnabled) then
		return	-- skip if use blocked by script
	end
	local activatorRef = e.activator

	if activatorRef == tes3.player then
		local targetMobile = targetRef.mobile
		local deadMobile = false
		if targetMobile then
			deadMobile = isMobileDead(targetMobile)
			if config.logLevel >= 2 then
				mwse.log("%s: activatorRef = %s, targetMobile = %s", modPrefix, activatorRef.id, targetRef.id)
			end
			if not deadMobile then
				local AIfixOnActivate = config.AIfixOnActivate
				local isCompanion = isValidCompanion(targetMobile)
				local isFollower = isValidFollower(targetMobile)
				if isCompanion
				or isFollower then
					if AIfixOnActivate > 1 then
						fixMobileAI(targetMobile)
					elseif AIfixOnActivate > 0 then
						if isCompanion then
							fixMobileAI(targetMobile)
						end
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
				end
			end
		end
		if config.allowLooting > 0 then
			if targetRef then
				if isAltDown() then
					if targetMobile then
						if deadMobile then
							timer.start({ duration = 0.1, callback = function ()
								checkCompanionActivate(targetRef)
							end })
							-- skip standard activation!
							e.claim = true
							return false
						else
							fixMobileAI(targetMobile)
						end
						return
					end
					local targetBaseObj = getBaseOrObject(targetRef)
					local lootType = targetBaseObj.objectType
					if getValidObjLootType(targetBaseObj) then
						if isLootable(targetBaseObj) then
							timer.start({ duration = 0.1, type = timer.real, callback = function ()
								if lootType then
									checkCompanionActivate(targetRef)
								end
							end })
						end
						-- skip standard activation!
						e.claim = true
						return false
					end
				end
			end
		end
		return
	end

	if not (activatorRef == lastCompanionRef) then
		return
	end

	if not (targetRef == lastTargetRef) then
		return
	end

	if config.allowLooting == 0 then
		return
	end

	takeMessageBox(activatorRef, targetRef)
	checkCrime(activatorRef, targetRef)
end
-- high priority to try avoiding problems if another mod does not properly check for activator being the player
-- Book Pickup mod has priority 10
event.register('activate', activate, {priority = 9999})


local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	---sYes = tes3.findGMST(tes3.gmst.sYes).value
	---sNo = tes3.findGMST(tes3.gmst.sNo).value
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
			self.elements.sideToSideBlock.children[1].widthProportional = 1.4
			self.elements.sideToSideBlock.children[2].widthProportional = 0.6
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
		description = [[
Default: 1. Yes, No companion overburdening allowed.
When enabled, Alt + activate to make your companions try and loot the target item/container/corpse
(with/without potential overburdening).
]],
		variable = createConfigVariable("allowLooting")
	}

	controls:createSlider{
		label = "Minimum item Value/Weight ratio",
		description = string.format("Minimum Value/Weight ratio for an item to be taken by a companion when looting a container, default: %s",
			defaultConfig.minValueWeightRatio),
		variable = createConfigVariable("minValueWeightRatio")
		,min = 1, max = 100, step = 1, jump = 5
	}

	controls:createSlider{
		label = "Max Loot Distance",
		description = string.format("Maximum distance for an item to be activated by a companion, default: %s", defaultConfig.maxDistance),
		variable = createConfigVariable("maxDistance")
		,min = 200, max = 1000, step = 1, jump = 5
	}

	controls:createYesNoButton{
		label = "Allow Companions to use Probes",
		description = [[
Default: Yes. When enabled, companion NPCs are allowed to use their stats,
skill and probes to try and disarm traps on the target you Alt + activate.
Probes with no uses left should be automatically dropped.
]],
		variable = createConfigVariable("allowProbes")
	}

	controls:createYesNoButton{
		label = "Allow Companions to use Lockpicks",
		description = [[
Default: Yes. When enabled, companion NPCs are allowed to use their stats, skill and lockpicks
to try and open the target you Alt + activate.
lockpicks with no uses left should be automatically dropped.
]],
		variable = createConfigVariable("allowLockpicks")
	}

	controls:createYesNoButton{
		label = "Companion NPCs High Acrobatics",
		description = [[
Default: Yes.
When enabled, companion NPCs are given high acrobatics on activate if not already having it.
Useful to avoid them getting damaged on jumping or teleporting.
]],
		variable = createConfigVariable("fixAcrobatics")
	}
	controls:createYesNoButton{
		label = "Companion NPCs Water Breathing",
		description = [[
Default: Yes.
When enabled, companion NPCs are given water breathing on activate if not already having it.
Useful to avoid them getting drowned.
]],
		variable = createConfigVariable("fixWaterBreathing")
	}

	controls:createDropdown{
		label = "Fix NPC/Creature AI on activate:",
		options = {
			{ label = "0. No", value = 0 },
			{ label = "1. Yes, Only current companions", value = 1 },
			{ label = "2. Yes, Any actor", value = 2 },
		},
		description = [[
Default: 1. Yes, Only current companions.
try and fix actors AI when activating them. Especially useful when companions go crazy after teleporting around too much.
]],
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

	mwse.mcm.register(template)
	logConfig(config, {indent = false})
	checkProcessActivate()
end
event.register('modConfigReady', modConfigReady)


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




@Safebox Usage:

if (tes3.testLineOfSight({ reference1 = tes3.player, reference2 = "ajira" }))


or

if (tes3.testLineOfSight({ position1 = { x1, y1, z1 }, height1 = h1, position2 = { x2, y2, z3 }, height2 = h2 }))



]]