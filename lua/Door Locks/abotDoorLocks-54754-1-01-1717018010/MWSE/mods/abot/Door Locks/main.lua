--[[
Dynamic loading doors locking according to time of day cycle, location, faction
]]

local defaultConfig = {
modEnabled = true,
minOpenHour = 7,
maxOpenHour = 19,
maxKnockHour = 21,
minPubCloseHour = 2,
maxPubCloseHour = 7,

-- skip scripted doors 0 = 'Off', 1 = 'Containers',
-- 2 = 'Containers and LCV doors', 3 = 'All doors/containers'
skipScript = 2,

skipPersistent = true,
skipChargen = true,
skipGuard = true,
knockOn = true,
knockNotifyPerc = 70,
maxHeardKnockDist = 1536,
maxHeardKnockZDist = 180,
minKnockDisposition = 33,
maxKnockFight = 75,
keyRing = true,
lockEmptyHouses = true,
logLevel = 0,

stdLockLevel = 38,
hardLockLevel = 58,
}

local author = 'abot'
local modName = 'Door Locks'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')

local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

local modDisabled, minOpenHour, maxOpenHour, maxKnockHour, minPubCloseHour, maxPubCloseHour
local skipScript, skipPersistent, skipChargen, skipGuard, knockOn, knockNotifyPerc
local maxHeardKnockZDist, maxHeardKnockDist, minKnockDisposition, maxKnockFight
local keyRing, lockEmptyHouses
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4
local stdLockLevel, hardLockLevel

local function updateFromConfig()
	modDisabled = not config.modEnabled
	minOpenHour = config.minOpenHour
	maxOpenHour = config.maxOpenHour
	maxKnockHour = config.maxKnockHour
	if maxKnockHour < maxOpenHour then
		maxKnockHour = maxOpenHour
		config.maxKnockHour = maxKnockHour
	end
	minPubCloseHour = config.minPubCloseHour
	maxPubCloseHour = config.maxPubCloseHour
	skipScript = config.skipScript
	skipPersistent = config.skipPersistent
	skipChargen = config.skipChargen
	skipGuard = config.skipGuard
	knockOn = config.knockOn
	knockNotifyPerc = config.knockNotifyPerc
	maxHeardKnockDist = config.maxHeardKnockDist
	maxHeardKnockZDist = config.maxHeardKnockZDist
	minKnockDisposition = config.minKnockDisposition
	maxKnockFight = config.maxKnockFight
	keyRing = config.keyRing
	lockEmptyHouses = config.lockEmptyHouses
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4

	stdLockLevel = config.stdLockLevel
	hardLockLevel = config.hardLockLevel
end
updateFromConfig()

local tes3_objectType_door = tes3.objectType.door
local tes3_objectType_container = tes3.objectType.container
local tes3_objectType_npc = tes3.objectType.npc

local function find2(s1, s2, pattern)
	return string.find(s1, pattern, 1, true)
	or string.find(s2, pattern, 1, true)
end

local function multifind2(s1, s2, pattern)
	return string.multifind(s1, pattern, 1, true)
	or string.multifind(s2, pattern, 1, true)
end

local function back2slash(s)
	return string.gsub(s, [[\]], [[/]])
end

local dummies = {'dumm','mann','target','invis'}

local function isDummy(mobRef)
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
		if logLevel3 then
			mwse.log('%s: isDummy("%s")', modPrefix, mobRef.id)
		end
		return true
	end
	return false
end

local function getRefVariable(ref, variableId)
	local script = ref.object.script
	if not script then
		return
	end
	local context = ref.context
	if not context then
		return
	end
	local value = context[variableId]
	if value then
		if logLevel2 then
			mwse.log('%s: getRefVariable("%s", "%s") context["%s"] = %s)',
				modPrefix, ref.id, variableId, variableId, value)
		end
		return value
	end
end

local function isRenting(actorRef)
	local rent = getRefVariable(actorRef, 'rent')
	if rent
	and (rent == 1) then
		return true
	end
	return false
end


local doorBlackList = {
'cave','dwem','dwrv','dwar','tomb','dae','crypt','sewer','gate','grate',
'ashl','trap','mark','pelt','propylon','strong','ship','cabin','slave'
}
local doorWhiteList = {'door','hut','colony','barrack','entrance','shack'}

local highSecurityList = {'bank','vault'}

local destCellBlackList = {
'cave','dwem','dwrv','dwar','tomb','dae','crypt','sewer','stronghold',
'ashl','prison','jail','propylon','ship','cabin','slave','sixth',
}

--[[
local factionNamePatterns = {
'guild','temple','imperial','cult','office','tong','brotherhood','company','clan',
'society','excise','fort','garrison','legion','skaal','navy','blades','reachmen','lords'
}
]]
local npcTypes = {'Not found','NPC','Faction member','Publican','Bed renting'}

local function round(x)
	return math.floor(x + 0.5)
end

local function getTimerRef(e)
	local timer = e.timer
	local data = timer.data
	local handle = data.handle
	if not handle then
		return
	end
	if not handle:valid() then
		return
	end
	local ref = handle:getObject()
	return ref
end


-- set in loaded()
local player

local skips = 0

local skipKnock = false

local function ab01drlkPT1(e)
	skipKnock = false
	local ref = getTimerRef(e)
	if not ref then
		return
	end
	---skips = 1
	player:activate(ref)
end

local function isHouse(cell)
	if string.multifind(string.lower(cell.id),
			{' house',' home',' hut',' shack'}, 1, true) then
		if logLevel2 then
			mwse.log('%s isHouse("%s") = true', modPrefix, cell.editorName)
		end
		return true
	end
	return false
end

-- set in modConfigReady()
local ab01KnockKnockSND, worldController

local function getInGameHoursPassedFromGameStart()
	local daysPassed = worldController.daysPassed.value
	local gameHour = worldController.hour.value
	return math.floor((daysPassed * 24) + gameHour + 0.5)
end

local function isGuard(object)
	if object.isInstance then
		return object.isGuard
    end
	if find2(string.lower(object.id), string.lower(object.name), 'guard') then
		return true
	end
	return false
end

-- out: 1 = Not found, 2 = NPC, 3 = Faction member, 4 = Publican, 5 = Bed renting
local function checkActorRef(actorRef, destPosition, destCellId)
	if actorRef.disabled
	or actorRef.deleted
	or actorRef.isDead
	or isDummy(actorRef) then
		return 1
	end
	local actorRefId = actorRef.id
	local actorObj = actorRef.object
	local dist = round( actorRef.position:distance(destPosition) )
	local los = tes3.testLineOfSight({position1 = destPosition,
		position2 = actorRef.position, height1 = 120, height2 = 60})
	local zdist = round( math.abs(actorRef.position.z - destPosition.z) )
	local class = actorObj.class
	local faction = actorObj.faction
	local funcPrefix = modPrefix..' checkActorRef()'
	if logLevel3 then
		mwse.log('%s: cell "%s" "%s" "%s" los = %s dist = %s zdist = %s class = "%s" faction = "%s"',
			funcPrefix, destCellId, actorRefId, actorObj.name, los, dist, zdist, class, faction)
	end
	if class
	and ( string.multifind(string.lower(class.id),
			{'publican','trader service'}, 1, true) ) then
		if logLevel1 then
			mwse.log('%s: cell "%s" "%s" "%s" class "%s" detected',
				funcPrefix, destCellId, actorRefId, actorObj.name, class.id)
		end
		if isRenting(actorRef) then
			return 5
		end
		return 4
	end

	local aiConfig = actorObj.aiConfig
	if not aiConfig then
		return 1
	end

	local fight = aiConfig.fight
	if not fight then
		return 1
	end

	if fight > maxKnockFight then
		if logLevel4 then
			mwse.log('%s: cell "%s" "%s" "%s" dist = %s, zdist = %s hostile NPC detected',
				funcPrefix, destCellId, actorRefId, actorObj.name, dist, zdist)
		end
		return 1
	end

	if faction
	and faction.playerJoined then
		local ok = true
		local guard = isGuard(actorObj)
		if skipGuard then
			ok = not guard
		end
		if logLevel2 then
			mwse.log('%s: cell "%s" "%s" "%s" dist = %s zdist = %s isGuard = %s same "%s" "%s" player faction detected',
				funcPrefix, destCellId, actorRefId, actorObj.name, dist, zdist, guard, faction.id, faction.name)
		end
		if ok then
			return 3
		end
	end
	
	local actorIsNearDestMarker = los
		and (dist <= maxHeardKnockDist)
		and (zdist <= maxHeardKnockZDist)

	if not actorIsNearDestMarker then
		return 1
	end

	local disposition = actorObj.disposition
	if not disposition then
		disposition = actorObj.baseDisposition
	end
	if not disposition then
		return 1
	end

	if disposition >= minKnockDisposition then
		if logLevel2 then
			mwse.log('%s: cell "%s" "%s" "%s" dist = %s zdist = %s neutral NPC detected',
				funcPrefix, destCellId, actorRefId, actorObj.name, dist, zdist)
		end
		return 2
	end

	if logLevel3 then
		mwse.log('%s: cell "%s" "%s" "%s" dist = %s zdist = %s low disposition NPC detected',
			funcPrefix, destCellId, actorRefId, actorObj.name, dist, zdist)
	end
	return 1
end

local lastOpenerRef
-- out: 1 = Not found, 2 = NPC, 3 = Faction member, 4 = Publican, 5 = Bed renting
local function getFirstKnownNPCtype(cell, destPosition)
	-- note .mobile od references inside the destination cell is most likely not yet initialized/available
	local result = 1
	local destCellId = cell.id
	for actorRef in cell:iterateReferences(tes3_objectType_npc) do
		result = checkActorRef(actorRef, destPosition, destCellId)
		if result > 1 then
			lastOpenerRef = actorRef
			return result
		end
	end
end

-- dummy function to oberride door script
local function nop()
	return
end

-- set in initialized()
local inputController

local keyRings = {
['g7_inventory_KEYS'] = 'g7_container_KEYS',
['invhlp_keyring'] = 'invhlp_keyring_rc',
}

local function forceInstance(ref)
	if not ref.object.isInstance then
        ref:clone()
        ref.modified = true 
    end 
end

local function hasKeyFromKeyRing(pcInventory, keyId, keyRingId, keyRingContainerId)
	if pcInventory:contains(keyRingId) then
		local keyRingContainerRef = tes3.getReference(keyRingContainerId)
		if keyRingContainerRef then
			forceInstance(keyRingContainerRef)
			local keyChainInventory =keyRingContainerRef.object.inventory
			if keyChainInventory
			and keyChainInventory:contains(keyId) then
				return true
			end
		end
	end
	return false
end

local function activate(e)
	if modDisabled then
		return
	end
	if not (e.activator == player) then
		return
	end

	local targetRef = e.target
	local targetRefId = targetRef.id
	local funcPrefix = string.format('%s: activate("%s" in "%s")',
		modPrefix, targetRefId, targetRef.cell.editorName)

	if inputController:isControlDown()
	and inputController:isAltDown() then
		if logLevel2 then
			mwse.log('%s: Ctrl+Alt pressed, return', funcPrefix, skips)
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

	local obj = targetRef.object
	local objType = obj.objectType

	local function delayedActivate(withKnockSound)
		local delay = 0.25
		skips = 1
		if withKnockSound then
			delay = 1.0
			skips = 2
		end
		local refHandle1 = tes3.makeSafeObjectHandle(targetRef)
		timer.start({duration = delay, type = timer.real, callback = 'ab01drlkPT1',
			data = {handle = refHandle1} })
	end

	local lockNode, level, key
	local hasKey = false

	local function checkObjType()
		if not (
			(objType == tes3_objectType_door)
			or (objType == tes3_objectType_container)
		) then
			return 1
		end
		lockNode = targetRef.lockNode
		if lockNode then
			level = lockNode.level
			key = lockNode.key
			if lockNode.locked
			and key then
				local keyId = key.id
				local inventory = e.activator.object.inventory
				if inventory then
					if inventory:contains(keyId) then
						hasKey = true
					elseif config.keyRing then
						for keyRingId, keyRingContainerId in pairs(keyRings) do
							if hasKeyFromKeyRing(inventory, keyId, keyRingId, keyRingContainerId) then
								tes3.unlock({reference = targetRef})
								if logLevel1 then
									mwse.log('%s: opening using "%s" key from KeyRing',	funcPrefix, keyId)
								end
								tes3ui.showNotifyMenu([[You use "%s" from your KeyRing...]], key.name)
								delayedActivate()
								return 2
							end
						end
					end
				end
				if hasKey then
					if logLevel1 then
						mwse.log('%s: skipping lock processing player has the key', funcPrefix)
					end
					return 1
				end

			end -- if lockNode.locked
		end -- if lockNode

		if obj.persistent
		and skipPersistent then
			if logLevel1 then
				mwse.log('%s: skipping persistent', funcPrefix)
			end
			return 1
		end

		local script = obj.script
		if script then
			if (objType == tes3_objectType_container) then
				if skipScript > 0 then
					if logLevel1 then
						mwse.log('%s: skipping scripted container', funcPrefix)
					end
					return 1
				end
			elseif (objType == tes3_objectType_door) then
				local scriptId = script.id
				if skipScript == 3 then
					if logLevel1 then
						mwse.log('%s: skipping scripted door', funcPrefix)
					end
					return 1
				elseif string.find(string.lower(scriptId),'^ld_%w-lock') then
					if skipScript == 2 then
						if logLevel1 then
							mwse.log('%s: skipping scripted LD LCV door', funcPrefix)
						end
						return 1
					elseif skipScript > 0 then
						mwse.overrideScript(scriptId, nop)
						if logLevel1 then
							mwse.log('%s: overriding scripted LD LCV door behavior', funcPrefix)
						end
					end
				end
			end
		end
		
		return 0

	end -- function checkObjType()

	local result = checkObjType()
	if result == 2 then
		return false -- block event and open using key from KeyRing
	elseif result == 1 then
		return -- skip
	end

	if not (objType == tes3_objectType_door) then
		return
	end
	-- only doors below

	local doorDest = targetRef.destination
	if not doorDest then
		if logLevel1 then
			mwse.log('%s: skipping non-loading door', funcPrefix)
		end
		return
	end

	local destCell = doorDest.cell
	local destCellEditorName = destCell.editorName

	if destCell.isOrBehavesAsExterior then
		if logLevel1 then
			mwse.log('%s: %s skipping loading-to-exterior "%s" door',
				funcPrefix, targetRefId, destCellEditorName)
		end
		return
	end

	-- real interior destination below
	if not destCell.restingIsIllegal then
		if logLevel1 then
			mwse.log('%s: door linked to "%s" legal-to-sleep interior cell destination, skip',
				funcPrefix, destCell.id)
		end
		return
	end

	local lcDestCellId = string.lower(destCell.id)
	local doorCell = targetRef.cell
	local lcDoorCellId = string.lower(doorCell.id)

	if lcDestCellId == lcDoorCellId then
		if logLevel1 then
			mwse.log('%s: skipping door leading to the same "%s" cell',
				funcPrefix, destCellEditorName)
		end
		return
	end

	if lockNode then
		if level then
			if level == 0 then
				if lockNode.locked then
					if logLevel1 then
						mwse.log('%s: skipping 0-locked door', funcPrefix)
					end
					return
				end
			elseif level == 1 then
				if logLevel1 then
					mwse.log('%s: skipping door marked as openable (locked/unlocked 1 by e.g. Revolving Doors Block mod)', funcPrefix)
				end
				return
			elseif targetRef.data
			and (not (targetRef.data.ab01locked == nil)) then
				if logLevel1 then
					mwse.log('%s: skipping door locked/unlocked by Loading Doors Lock Tune mod)', funcPrefix)
				end
				return
			end
		end
		if logLevel3 then
			mwse.log('%s: door to "%s", locked = %s, lock level = %s',
				funcPrefix, destCellEditorName, lockNode.locked, lockNode.level)
		end
	end

	local sourceMod = targetRef.sourceMod
	if sourceMod
	and string.multifind(string.lower(sourceMod),{'ab01houses'}, 1, true) then
		if logLevel1 then
			mwse.log('%s: skipping door to "%s" from blacklisted mod "%s"',
				funcPrefix, destCellEditorName, sourceMod)
		end
		return
	end

	local lcDoorId = string.lower(obj.id)
	local lcDoorName = string.lower(obj.name)

	if string.multifind(lcDestCellId, destCellBlackList, 1, true) then
		if logLevel1 then
			mwse.log('%s: skipping blacklisted destination cell "%s"',
				funcPrefix, destCellEditorName)
		end
		return
	end

	if skipChargen then
		if find2(lcDoorId, lcDoorName, 'chargen') then
			if logLevel1 then
				mwse.log('%s: skipping chargen door to "%s"', funcPrefix, destCellEditorName)
			end
			return
		end
	end
	
	if multifind2(lcDoorId, lcDoorName,	doorBlackList) then
		if logLevel1 then
			mwse.log('%s: skipping blacklisted door to "%s"', funcPrefix, destCellEditorName)
		end
		return
	end

	local hasDestSameLocationPrefix = false
	local cellPrefix = string.match(lcDoorCellId, "^([^,]+),")
	local destCellPrefix = string.match(lcDestCellId, "^([^,]+),")
	if doorCell.isOrBehavesAsExterior then
		hasDestSameLocationPrefix = string.startswith(lcDestCellId, lcDoorCellId..',')
	else -- if not destCell.isOrBehavesAsExterior then -- already checked
		hasDestSameLocationPrefix = destCellPrefix
			and	(destCellPrefix == cellPrefix)
	end

	if logLevel3 then
		mwse.log('%s: door to "%s", hasDestSameLocationPrefix = %s',
			funcPrefix, destCellEditorName, hasDestSameLocationPrefix)
	end

	local destCellIsHouse = isHouse(destCell)

	-- e.g. "Mundrethi Plantation, Merengor's House: Underground"
	if (not hasDestSameLocationPrefix)
	and (not destCellIsHouse)
	and (not multifind2(lcDoorId, lcDoorName, doorWhiteList)) then
		if logLevel1 then
			mwse.log('%s: skipping non-whitelisted door', funcPrefix)
		end
		return
	end

	local newLockLevel = stdLockLevel
	if string.multifind(lcDestCellId, highSecurityList, 1, true) then
		newLockLevel = hardLockLevel
		if logLevel3 then
			mwse.log('%s: door to "%s" in high security list, newLockLevel = %s',
				funcPrefix, destCellEditorName, newLockLevel)
		end
	end

	if hasDestSameLocationPrefix
	and (not doorCell.isOrBehavesAsExterior)
	and (not destCell.isOrBehavesAsExterior) then
		if logLevel3 then
			mwse.log('%s: door to "%s" is interior-to-interior, skip',
				funcPrefix, destCellEditorName)
		end
		return
	end

	local hour = worldController.hour.value

	local isOpenTime = (hour >= minOpenHour)
		and (hour <= maxOpenHour)
	local nextCloseHour = minOpenHour
	if isOpenTime then
		nextCloseHour = maxOpenHour
	end

	local someoneInside = false
	local someoneCanOpen = false
	---if hasDestSameLocationPrefix then

	-- 1 = Not found, 2 = NPC, 3 = Faction member, 4 = Publican, 5 = Bed renting
	local destMarker = doorDest.marker
	local npcType = getFirstKnownNPCtype(destCell, destMarker.position)
	if npcType == 5 then -- bed renting tavern like
		isOpenTime = (hour >= maxPubCloseHour)
			or (hour <= minPubCloseHour)
		someoneInside = true
		someoneCanOpen = true
		if not isOpenTime then
			nextCloseHour = minPubCloseHour
		end
	elseif npcType == 4 then -- tavern like
		isOpenTime = (hour >= maxPubCloseHour)
			or (hour <= minPubCloseHour)
		someoneInside = true
		if not isOpenTime then
			nextCloseHour = minPubCloseHour
		end
	elseif npcType == 3 then -- same guild npc
		someoneInside = true
		--[[local isGuild = false
		if string.multifind(lcDestCellId, factionNamePatterns, 1, true) then
			isGuild = true
		end
		if isGuild then]]
			---isOpenTime = (hour >= maxPubCloseHour)
				---or (hour <= minPubCloseHour)
			newLockLevel = hardLockLevel
			someoneCanOpen = true
		---end
		if not isOpenTime then
			nextCloseHour = minPubCloseHour
		end
	elseif npcType == 2 then -- house like
		someoneInside = true
		if destCellIsHouse then
			if hour <= maxOpenHour then
				someoneCanOpen = true
			end
		end
	elseif lockEmptyHouses then
		if logLevel3 then
			mwse.log('%s: to "%s" empty/unfriendly house isOpenTime set to false', funcPrefix, destCellEditorName)
		end
		isOpenTime = false -- lock empty/unfriendly houses by default
	end
	if logLevel2 then
		mwse.log([[%s: dest = "%s", hour = %.02f, isOpenTime = %s,
someoneInside = %s, someoneCanOpen = %s, npcType = %s %s]],
			funcPrefix, destCellEditorName, hour, isOpenTime,
			someoneInside, someoneCanOpen, npcType, npcTypes[npcType])
	end
	---end -- if hasDestSameLocationPrefix

	local hoursPassedFromGameStart = getInGameHoursPassedFromGameStart()

	local ab01drlkhp
	if targetRef.data then
		ab01drlkhp = targetRef.data.ab01drlkhp
	end

	local hasAlreadyBeenLockedToday = false
	if ab01drlkhp then
		local hoursPassedSinceLastLocked = hoursPassedFromGameStart - ab01drlkhp
		if hoursPassedSinceLastLocked < 24 then
			if logLevel1 then
				mwse.log('%s: hoursPassedFromGameStart = %s, ab01drlkhp = %s',
					funcPrefix, hoursPassedFromGameStart, ab01drlkhp)
				mwse.log('%s: door dest = "%s", hoursPassedSinceLastLocked = %s < 24, skip',
					funcPrefix, destCellEditorName, hoursPassedSinceLastLocked)
			end
			hasAlreadyBeenLockedToday = true
		end
	end

	local function unlockAndActivateDoor()
		if logLevel1 then
			mwse.log('%s: unlockAndActivateDoor("%s") dest = "%s"',
				modPrefix, targetRefId, destCellEditorName)
		end
		if lockNode then
			lockNode.level = newLockLevel
			if lockNode.locked then
				tes3.unlock({reference = targetRef})
			end
		end
		if not targetRef.data then
			targetRef.data = {}
		end
		targetRef.data.ab01drlkhp = hoursPassedFromGameStart
		delayedActivate()
	end

	local function knockUnlockAndActivateDoor()
		skipKnock = true
		local withKnockSound = false
		if ab01KnockKnockSND then
			withKnockSound = true
			tes3.playSound({sound = ab01KnockKnockSND})
		end
		if npcType > 2 then
			local i = math.random(100)
			if knockNotifyPerc >= i then
				local pcName = tes3.player.object.name
				local i = 100
				if lastOpenerRef then
					i = math.random(100)
				end
				if i > 50 then
					tes3ui.showNotifyMenu([["It's me, %s!"]], pcName)
				else
					local obj = lastOpenerRef.object
					local name = obj.name
					local faction = obj.faction
					if faction then
						local class = obj.class
						if class then
							name = class.name
						end
						pcName = faction:getRankName(faction.playerRank)
					end
					tes3ui.showNotifyMenu([[%s: "Ah, it's you. Welcome, %s."]], name, pcName)
					lastOpenerRef = nil
				end
			end
		end
		if withKnockSound then
			timer.start({duration = 0.45, type = timer.real, callback = function ()
				tes3.playSound({sound = 'Open Lock'})
			end})
		end
		unlockAndActivateDoor()
	end

	local function lockAndActivateDoor()
		if logLevel1 then
			mwse.log('%s: empty/unfriendly houses dest = "%s"',
				funcPrefix, destCellEditorName)
		end
		tes3.lock({reference = targetRef, level = newLockLevel})
		if not targetRef.data then
			targetRef.data = {}
		end
		targetRef.data.ab01drlkhp = hoursPassedFromGameStart
		delayedActivate()
	end

	if lockNode then
		if lockNode.locked
		or hasAlreadyBeenLockedToday then
			if isOpenTime then
				if someoneInside then
					unlockAndActivateDoor()
					return false
				end
			elseif someoneCanOpen then
				if knockOn then
					knockUnlockAndActivateDoor()
					return false
				end
			end
		else -- (lockNode.locked == false) and (hasAlreadyBeenLockedToday == false)
			if hasDestSameLocationPrefix
			and (not isOpenTime) then
				if someoneCanOpen then
					if knockOn then
						knockUnlockAndActivateDoor()
						return false
					end
				else
					if logLevel1 then
						mwse.log('%s: door "%s" (dest = "%s") locked',
							funcPrefix, targetRefId, destCell.id)
					end
					lockAndActivateDoor()
					return false
				end
			end
		end

		return -- lockNode processed
	end

	if not hasAlreadyBeenLockedToday
	and hasDestSameLocationPrefix
	and (not isOpenTime) then
		if logLevel2 then
			mwse.log([[%s: door "%s" cell = "%s", dest = "%s", isOpenTime = %s,	someoneCanOpen = %s]],
				funcPrefix, targetRefId, doorCell.editorName, destCellEditorName, isOpenTime, someoneCanOpen)
		end
		if someoneCanOpen then
			if knockOn then
				knockUnlockAndActivateDoor()
			else
				unlockAndActivateDoor()
			end
		else
			lockAndActivateDoor()
		end
		return false
	end

end

local initDone = false
local function initOnce()
	if initDone then
		return
	end
	initDone = true
	timer.register('ab01drlkPT1', ab01drlkPT1)
	-- higher priority than Smart Activate
	event.register('activate', activate, {priority = 100020})
end

local function loaded()
	player = tes3.player
	initOnce()
end


local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId, table = config}
end

local yesOrNo = {[false] = 'No', [true] = 'Yes'}

local function modConfigReady()

local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		updateFromConfig()
		mwse.saveConfig(configName, config, {indent = false})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label = 'Info',
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo({
		text = [[Dynamic loading doors locking according to time of day cycle, location, faction, disposition...
Meant as a more general/dynamic replacement of Living Cities of Vvardenfell Locks mod, but it works with or without it already installed.
Also can use keys contained in a recognized keyring while opening doors.]]
})

	---local controls = preferences:createCategory{label = mcmName}
	local controls = preferences:createCategory({})

	local function getYesNoDescription(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	controls:createYesNoButton({
		label = 'Enabled',
		description = getYesNoDescription([[Default: %s.
Enable the mod effects.
Note: you can also skip processing cuurent door/container by pressing Ctrl+Alt while activating it.]], 'modEnabled'),
		variable = createConfigVariable('modEnabled')
	})

	local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end

	controls:createInfo({text = string.format('House doors opened between %s and %s',
		minOpenHour, maxOpenHour)})
	controls:createSlider({
		label = 'Min house door opening hour %s',
		description = getDescription([[Default: %s.
Minimun door opening hour for house-like places.]], 'minOpenHour'),
		variable = createConfigVariable('minOpenHour')
		,min = 5, max = 9
	})
	controls:createSlider({
		label = 'Max house door opening hour %s',
		description = getDescription([[Default: %s.
Maximum door opening hour for house-like places.]], 'maxOpenHour'),
		variable = createConfigVariable('maxOpenHour')
		,min = 17, max = 21
	})

	controls:createSlider({
		label = 'Max house door knock hour %s',
		description = getDescription([[Default: %s.
Maximum door knocking hour for house-like places.]], 'maxKnockHour'),
		variable = createConfigVariable('maxKnockHour')
		,min = 17, max = 23
	})

	controls:createInfo({text = string.format('Service doors locking between %s and %s',
		minPubCloseHour, maxPubCloseHour)})
	controls:createSlider({
		label = 'Min service door locking hour %s',
		description = getDescription([[Default: %s.
Minimun door locking hour for tavern-like places (having a publican or trade service NPC).]], 'minPubCloseHour'),
		variable = createConfigVariable('minPubCloseHour')
		,min = 0, max = 4
	})
	controls:createSlider({
		label = 'Max service door locking hour %s',
		description = getDescription([[Default: %s.
Maximum door locking hour for tavern like places (e.g. having a publican or trade service NPC).]], 'maxPubCloseHour'),
		variable = createConfigVariable('maxPubCloseHour')
		,min = 5, max = 9
	})

	local optionList = {'Off','Containers',
		'Containers and Living Cities of Vvardenfell locked doors','All doors/containers'}

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

	controls:createDropdown{
		label = 'Skip Scripted:',
		options = getOptions(),
		variable = createConfigVariable('skipScript'),
		description = getDropDownDescription([[Default: %s.
Set if/when to skip processing vanilla scripted doors.
Note:
changes related to "Living Cities of Vvardenfell locks vanilla scripts" option are effective only on game restart.
]],'skipScript')
	}

	controls:createYesNoButton({
		label = 'Skip Persistent',
		description = getYesNoDescription([[Default: %s.
Skip processing persistent doors.]], 'skipPersistent'),
		variable = createConfigVariable('skipPersistent')
	})
	
	controls:createYesNoButton({
		label = 'Skip Chargen',
		description = getYesNoDescription([[Default: %s.
Skip processing Chargen doors.]], 'skipChargen'),
		variable = createConfigVariable('skipChargen')
	})	

	controls:createYesNoButton({
		label = 'Skip Guards',
		description = getYesNoDescription([[Default: %s.
Do not allow guard NPCs to open doors for player.]], 'skipGuard'),
		variable = createConfigVariable('skipGuard')
	})
	
	controls:createYesNoButton({
		label = 'Use Keyring',
		description = getYesNoDescription([[Default: %s.
Try and use keys contained in a recognized keyring while opening doors.
Currently working with MWSE Containers and Inventory Helpers keyrings.]], 'keyRing'),
		variable = createConfigVariable('keyRing')
	})

	controls:createYesNoButton({
		label = 'Lock empty houses',
		description = getYesNoDescription([[Default: %s.
When enabled empty houses/homes will be locked when nobody's home regardless of the hour.]], 'lockEmptyHouses'),
		variable = createConfigVariable('lockEmptyHouses')
	})

	controls:createYesNoButton({
		label = 'Knock on doors',
		description = getYesNoDescription([[Default: %s.
Enable knocking on doors (e.g. doors to player Guilds).]], 'knockOn'),
		variable = createConfigVariable('knockOn')
	})

local onlyEffective = '\nOnly effective when "Knock on doors" is enabled.'

	controls:createSlider({
		label = 'Max door knock hearing distance',
		description = getDescription([[Default: %s.
Maximum distance of a friendly NPC from door destination marker to be able to hear player knocking on the door.]]..onlyEffective, 'maxHeardKnockDist'),
		variable = createConfigVariable('maxHeardKnockDist')
		,min = 256, max = 3072, jump = 16
	})

	controls:createSlider({
		label = 'Max door knock vertical hearing distance',
		description = getDescription([[Default: %s.
Maximum vertical/Z axis distance of a friendly NPC from door destination marker to be able to hear player knocking on the door.]]..onlyEffective, 'maxHeardKnockZDist'),
		variable = createConfigVariable('maxHeardKnockZDist')
		,min = 92, max = 1024, jump = 16
	})

	controls:createSlider({
		label = 'Max Knock Fight',
		description = getDescription([[Default: %s.
Maximum NPC Fight setting to be still considered friendly/willing to open to a door-knocking player.]]..onlyEffective, 'maxKnockFight'),
		variable = createConfigVariable('maxKnockFight')
		,min = 75, max = 100, jump = 5
	})

	controls:createSlider({
		label = 'Min Knock Disposition',
		description = getDescription([[Default: %s.
Minimum friendly NPC base object disposition to open to a door-knocking player.
Only effective for services/home-like interiors and only when "Knock on doors" is enabled.]], 'minKnockDisposition'),
		variable = createConfigVariable('minKnockDisposition')
		,min = 30, max = 100, jump = 5
	})

	controls:createSlider({
		label = 'Knock Notify Perc',
		description = getDescription([[Default: %s.
Percent probability of player saying something when knocking on door.]]..onlyEffective, 'knockNotifyPerc'),
		variable = createConfigVariable('knockNotifyPerc')
		,min = 0, max = 100, jump = 5
	})

	optionList = {'Off', 'Low', 'Medium', 'High', 'Max'}
	controls:createDropdown{
		label = 'Logging level:',
		options = getOptions(),
		variable = createConfigVariable('logLevel'),
		description = getDropDownDescription([[Default: %s.]],'logLevel')
	}

	mwse.mcm.register(template)

end
event.register('modConfigReady', modConfigReady)

event.register('initialized', function ()
	worldController = tes3.worldController
	inputController = worldController.inputController
	ab01KnockKnockSND = tes3.getSound('ab01KnockKnockSND')
	if not ab01KnockKnockSND then
		ab01KnockKnockSND = tes3.createObject({objectType = tes3.objectType.sound,
			id = 'ab01KnockKnockSND', filename = 'abot\\knockdoor.wav', volume = 1})
	end
	event.register('loaded', loaded)
end---, {doOnce = true}
)

