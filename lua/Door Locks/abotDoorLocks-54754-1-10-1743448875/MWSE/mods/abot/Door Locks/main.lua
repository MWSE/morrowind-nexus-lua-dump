--[[
Dynamic loading doors locking according to time of day cycle, location, faction
]]

local defaultConfig = {
modEnabled = true,
minOpenHour = 7,
maxOpenHour = 19,

minKnockHour = 17,

maxKnockHour = 22,
minPubCloseHour = 2,
maxPubCloseHour = 7,
lockUnlockIntervalHour = 1,
-- skip scripted doors 0 = 'Off', 1 = 'Containers',
-- 2 = 'Containers and LD/LCV doors', 3 = 'All doors/containers'
skipScript = 2,

skipPersistent = true,
skipChargen = true,
skipGuard = true,
checkScriptContext = true,
knockOn = true,
serviceKnock = true,
knockNotifyPerc = 70,
maxHeardKnockDist = 3048,
maxHeardKnockZDist = 172,
minKnockDisposition = 33,
maxKnockFight = 75,
moveOpeningActor = true,
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
assert(config) -- mainly to avoid visual studio code complains

local modDisabled, minOpenHour, maxOpenHour, minKnockHour, maxKnockHour
local minPubCloseHour, maxPubCloseHour, lockUnlockIntervalHour
local skipScript, skipPersistent, skipChargen, checkScriptContext
local skipGuard, knockOn, serviceKnock, knockNotifyPerc
local maxHeardKnockZDist, maxHeardKnockDist, minKnockDisposition, maxKnockFight
local keyRing, lockEmptyHouses
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4, logLevel5
local stdLockLevel, hardLockLevel

local function updateFromConfig()
	modDisabled = not config.modEnabled
	minOpenHour = config.minOpenHour
	maxOpenHour = config.maxOpenHour
	minKnockHour = config.minKnockHour
	maxKnockHour = config.maxKnockHour
	if maxKnockHour < maxOpenHour then
		maxKnockHour = maxOpenHour
		config.maxKnockHour = maxKnockHour
	end
	minPubCloseHour = config.minPubCloseHour
	maxPubCloseHour = config.maxPubCloseHour
	lockUnlockIntervalHour = config.lockUnlockIntervalHour
	skipScript = config.skipScript
	skipPersistent = config.skipPersistent
	skipChargen = config.skipChargen
	skipGuard = config.skipGuard
	checkScriptContext = config.checkScriptContext
	knockOn = config.knockOn
	serviceKnock = config.serviceKnock
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
	logLevel5 = logLevel >= 5

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

local function multifind2(s1, s2, t)
	return string.multifind(s1, t, 1, true)
	or string.multifind(s2, t, 1, true)
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

local function hasRefVariable(ref, variableId)
	local script = ref.object.script
	if not script then
		return false
	end
	local funcPrefix
	if logLevel1 then
		funcPrefix = string.format('%s: hasRefVariable("%s", "%s")', modPrefix, ref.id, variableId)
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
	---local context = ref['context'] -- nor reliable here

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


local highSecurityList = {'bank','vault'}

local guardedList = {'district','jail','prison'}

---local districtList = {'district','market'}

local destCellWhiteList = {
'barrack','colony','door','entrance',
'greathall','hut','mine','shack'
}

local destCellBlackList = {
'ashl','back','cabin','cave','crypt','dae',
'district','dwar','dwem','dwrv','gate','grate',---'mark',
'pelt','propylon','sewer','ship','sixth','slave',
'strong','trap','tomb','warehouse'
}

local doorBlackList = {'back'}

local classServices = {
'service','trader','seller','clothier','merchant',
'pawnbroker','guild guide','smith','master-at-arms'}

local serviceCells = {
' service',' shop','market',' trade',' seller',
' cloth',' merchant','pawn','guild',' smith','weapon','armo',
' fletch','temple','food','emporium'}

local houseCells = {' house',' home',' hut',' shack'}

local pubLikeCells = {'light house','lighthouse','tower','castle'}

---local homeLikeCells = {'apartment','flat','home','house'}

local districtLikeCells = {
'council hall','district','plaza','square','works','market'}

--[[
local factionNamePatterns = {
'guild','temple','imperial','cult','office','tong','brotherhood','company','clan',
'society','excise','fort','garrison','legion','skaal','navy','blades','reachmen','lords'
}
]]
local npcTypes = {
'Not found','NPC','Service','Faction member','Publican','Bed renting'}

local function handleToRef(handle)
	if not handle then
		return
	end
	if not handle.valid then
		return
	end
	if not handle:valid() then
		return
	end
	local ref = handle:getObject()
	return ref
end

local function getTimerRef(e)
	local timer = e.timer
	local data = timer.data
	local handle = data.handle
	local ref = handleToRef(handle)
	return ref
end

-- set in loaded()
local player

local skips = 0

---local skipKnock = false

local function ab01drlkPT1(e)
	---skipKnock = false
	local ref = getTimerRef(e)
	if not ref then
		return
	end
	---skips = 1
	player:activate(ref)
end

-- set in initialized()
local ab01KnockKnockSND, worldController

local function round(x)
	return math.floor(x + 0.5)
end

local function getInGameHoursFromGameStart()
	local daysPassed = worldController.daysPassed.value
	local gameHour = worldController.hour.value
	return round( (daysPassed * 24) + gameHour )
end

local function updateDoorData(doorRef, locked)
	local data = doorRef.data
	if not data then
		doorRef.data = {}
		data = doorRef.data
	end
	data.ab01drlkhp = getInGameHoursFromGameStart()
	if data.ab01locked then
		data.ab01locked = locked
	end
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

local function forceInstance(ref)
	if not ref.object.isInstance then
		ref:clone()
		ref.modified = true
	end
end

local function isSleeping(actorRef)
	local mob = actorRef.mobile
	if mob
	and mob.fatigue
	and mob.fatigue.current <= 0 then
		return true
	end
	return false
end

local function getCellId(cell)
	if cell.isInterior then
		return cell.id
	end
	return cell.editorName
end

local function getLcCellId(cell)
	return string.lower(getCellId(cell))
end

local someoneInside = false

-- 1 'Not found', 2 'NPC', 3 'Trader', 4 'Faction member', 5 'Publican', 6 'Bed renting'
local function checkActorRef(actorRef, destPosition, destCell)
	local rec = {npcType = 1, dist = 100000,
		zdist = 100000, ref = actorRef}
	if actorRef.disabled
	or actorRef.deleted
	or actorRef.isDead
	or isDummy(actorRef)
	or isSleeping(actorRef) then
		return rec
	end
	local actorRefId = actorRef.id
	local actorObj = actorRef.object
	local dist = round( actorRef.position:distance(destPosition) )
	local zdist = round( math.abs(actorRef.position.z - destPosition.z) )
	rec.dist = dist
	rec.zdist = zdist

	local class = actorObj.class
	local faction = actorObj.faction
	local funcPrefix = modPrefix..' checkActorRef()'
	local destCellId = getCellId(destCell)
	if logLevel5 then
		local s = string.format('%s: cell "%s" "%s" "%s" dist = %s zdist = %s',
			funcPrefix, destCellId, actorRefId, actorObj.name, dist, zdist)
		if class then
			s = s..' class = "'..class.id..'"'
		end
		if faction then
			s = s..' faction = "'..faction.id..'"'
		end
		print(s)
	end

	if class then
		if string.multifind(string.lower(class.id),
				{'publican', 'trader service'},	1, true) then
			if checkScriptContext
			and hasRefVariable(actorRef, 'rent') then
--[[
note: ref.context may not be fully initialized here, so reading/setting the local script
variable value is not reliable.
using ref.object.script.context is reliable
but you can only check if the variable exists (if it exists hasRefVariable(actorRef, 'rent')
wiil return 0 which is evaluated true, else it will return nil)
]]
				rec.npcType = 6 -- Bed renting
				return rec
			elseif class.bartersAlchemy
			and (not class.bartersClothing) then
				rec.npcType = 5 -- Publican
				if logLevel3 then
					mwse.log('%s.5-6: cell "%s" "%s" "%s" class "%s" detected npcType = %s',
						funcPrefix, destCellId, actorRefId, actorObj.name, class.id, rec.npcType)
				end
				return rec
			end
		end
	end

	if faction
	and faction.playerJoined then
		local ok = true
		local guard = isGuard(actorObj)
		if skipGuard
		and guard then
			ok = false
		end
		if logLevel4 then
			mwse.log('%s: cell "%s" "%s" "%s" dist = %s zdist = %s isGuard = %s same "%s" "%s" player faction detected',
				funcPrefix, destCellId, actorRefId, actorObj.name, dist, zdist, guard, faction.id, faction.name)
		end
		if ok then
			rec.npcType = 4 -- Faction
			return rec
		end
	end

	if class then
		if serviceKnock
		and string.multifind(string.lower(class.id),
				classServices, 1, true) then
			rec.npcType = 3 -- Service
			if logLevel3 then
				mwse.log('%s.3: cell "%s" "%s" "%s" class "%s" detected npcType = %s',
					funcPrefix, destCellId, actorRefId, actorObj.name, class.id, rec.npcType)
			end
			return rec
		end
	end

	someoneInside = true

	local aiConfig = actorObj.aiConfig
	if not aiConfig then
		rec.npcType = 1
		return rec
	end

	local fight = aiConfig.fight
	if not fight then
		rec.npcType = 1
		return rec
	end

	if fight > maxKnockFight then
		if logLevel4 then
			mwse.log('%s: cell "%s" "%s" "%s" dist = %s, zdist = %s hostile NPC detected',
				funcPrefix, destCellId, actorRefId, actorObj.name, dist, zdist)
		end
		rec.npcType = 1
		return rec
	end

	---forceInstance(actorRef) -- try and make LOS work
	-- nope does not work in unloaded cell, even rayTest does not seem to work
	---local los = tes3.testLineOfSight({position1 = actorRef.position,
		---position2 = destPosition, height1 = 120})

	---if logLevel3 then
		---mwse.log('%s: cell "%s" "%s" "%s" dist = %s zdist = %s LOS = %s',
			---funcPrefix, destCellId, actorRefId, actorObj.name, dist, zdist, los)
	---end

	---local actorIsNearDestMarker = los
		---and (dist <= maxHeardKnockDist)
		---and (zdist <= maxHeardKnockZDist)
	local actorIsNearDestMarker = (dist <= maxHeardKnockDist)
		and (zdist <= maxHeardKnockZDist)

	if not actorIsNearDestMarker then
		rec.npcType = 1
		return rec
	end

	local disposition = actorObj.disposition

	if not disposition then
		disposition = actorObj.baseDisposition
	end
	if not disposition then
		rec.npcType = 1
		return rec
	end

	if disposition >= minKnockDisposition then
		if logLevel4 then
			mwse.log('%s: cell "%s" "%s" "%s" dist = %s zdist = %s neutral NPC detected',
				funcPrefix, destCellId, actorRefId, actorObj.name, dist, zdist)
		end
		rec.npcType = 2
		return rec
	end

	if logLevel4 then
		mwse.log('%s: cell "%s" "%s" "%s" dist = %s zdist = %s low disposition NPC detected',
			funcPrefix, destCellId, actorRefId, actorObj.name, dist, zdist)
	end
	rec.npcType = 1
	return rec
end


local function byType(a, b)
	return b.npcType < a.npcType
end

local function byDist(a, b)
	return a.dist < b.dist
end

local function byZdist(a, b)
	return a.zdist < b.zdist
end

local function getBestKnownNPCrec(destCell, destPosition)
	-- note .mobile of references inside the destination cell is most likely not yet initialized/available
	local t = {}
	local i = 0
	local rec = {npcType = 1, dist = 100000, zdist = 100000}
	someoneInside = false
	for actorRef in destCell:iterateReferences(tes3_objectType_npc) do
		local arec = checkActorRef(actorRef, destPosition, destCell)
		---mwse.log('>>> arec.npcType = %s %s', arec.npcType, npcTypes[arec.npcType])
		if arec.npcType > 1 then
			i = i + 1
			t[i] = arec
		end
	end
	if i <= 0 then
		return rec
	end
	table.sort(t, byDist)
	table.sort(t, byZdist)
	table.sort(t, byType)
	rec = t[1]
	if logLevel2 then
		local npcType = rec.npcType
		if rec.ref then
			mwse.log('%s getBestKnownNPCrec("%s"): actor = "%s" "%s" npcType = %s %s',
				modPrefix, destCell.displayName, rec.ref.id, rec.ref.object.name,
				npcType, npcTypes[npcType])
		else
			mwse.log('%s getBestKnownNPCrec("%s"): npcType = %s %s',
				modPrefix, destCell.displayName, npcType, npcTypes[npcType])
		end
	end
	return rec
end

-- dummy function to override door script
local function nop()
	---return
end

-- set in initialized()
local inputController

local keyRings = {
['g7_inventory_KEYS'] = 'g7_container_KEYS',
['invhlp_keyring'] = 'invhlp_keyring_rc',
}

local function hasKeyFromKeyRing(pcInventory, keyId, keyRingId, keyRingContainerId)
	if pcInventory:contains(keyRingId) then
		local keyRingContainerRef = tes3.getReference(keyRingContainerId)
		if keyRingContainerRef then
			forceInstance(keyRingContainerRef)
			local keyChainInventory = keyRingContainerRef.object.inventory
			if keyChainInventory
			and keyChainInventory:contains(keyId) then
				return true
			end
		end
	end
	return false
end

local function isHouse(lcCellId)
	if string.multifind(lcCellId, houseCells, 1, true) then
		if logLevel2 then
			mwse.log('%s isHouse("%s") = true', modPrefix, lcCellId)
		end
		return true
	end
	return false
end

local function isService(lcCellId)
	if string.multifind(lcCellId, serviceCells, 1, true) then
		if logLevel2 then
			mwse.log('%s isService("%s") = true', modPrefix, lcCellId)
		end
		return true
	end
	return false
end

local function isDistrict(lcCellId)
	if string.multifind(lcCellId, districtLikeCells, 1, true) then
		if logLevel2 then
			mwse.log('%s isDistrict("%s") = true', modPrefix, lcCellId)
		end
		return true
	end
	return false
end

local function playSound(snd)
	if not tes3.getSoundPlaying({sound = snd,
			reference = player}) then
		tes3.playSound({sound = snd, reference = player})
	end
end

local function getCellPrefix(cell)
	local s, i
	if cell.isInterior then
		s = cell.id
		i = string.find(s, '[,:]')
	else
		s = cell.editorName
		i = string.find(s, ' (', 1, true)
	end
	if i
	and (i > 1) then
		return string.sub(s, 1, i - 1)
	end
	return s
end

local function getHasDestSameLocationPrefix(cell, destCell)
	local lcCellPrefix = string.lower(getCellPrefix(cell))
	local lcDestCellPrefix = string.lower(getCellPrefix(destCell))
	return (lcDestCellPrefix == lcCellPrefix)
end

local tes3_objectType_activator = tes3.objectType.activator

local function isIllegalResting(cell)
	if cell.restingIsIllegal then
		return true
	end
	local ownedBedsCount = 0
	local freeBedsCount = 0
	for ref in cell:iterateReferences(tes3_objectType_activator) do
		if not ref.disabled then
			local script = ref.object.script
			if script
			and string.find(string.lower(script.id),
					'bed', 1, true) then
				if tes3.hasOwnershipAccess({reference = player, target = ref}) then
					freeBedsCount = freeBedsCount + 1
				else
					ownedBedsCount = ownedBedsCount + 1
				end
			end
		end
	end
	if ownedBedsCount > freeBedsCount then
		return true
	end
	return false
end

local function mobileActivated(e)
	if e.mobile.damage then
		return -- skip projectiles
	end
	local ref = e.reference
	local data = ref.data
	if not data then
		return
	end
	if not (
		data.ab01drlkStart
		or data.ab01dlPos -- legacy
	) then
		return
	end
	if logLevel2 then
		mwse.log('%s mobileActivated(): "%s" "%s" position reset using RA',
			modPrefix, ref.cell.id, ref.id)
	end
	tes3.runLegacyScript({command = 'RA',
		source = tes3.compilerSource.console})
	data.ab01drlkStart = nil
	data.ab01dlPos = nil
	event.unregister('mobileActivated', mobileActivated)
end

local function mobileDeactivated(e)
	if e.mobile.damage then
		return -- skip projectiles
	end
	local ref = e.reference
	local data = ref.data
	if not data then
		return
	end
	local ab01drlkStart
	local ab01dlPos = data.ab01dlPos
	if ab01dlPos then -- legacy value
		ab01drlkStart = {ab01dlPos.x, ab01dlPos.y, ab01dlPos.z}
	else
		ab01drlkStart = data.ab01drlkStart
	end
	if not ab01drlkStart then
		return
	end
	local from = ref.position
	local to = tes3vector3.new(ab01drlkStart[1], ab01drlkStart[2], ab01drlkStart[3])
	local dist = to:distance(from)
	if dist < 64 then -- same position stored, fix with RA instead
		event.register('mobileActivated', mobileActivated)
		event.unregister('mobileDeactivated', mobileDeactivated)
		return
	end

	-- different position below
	if logLevel2 then
		mwse.log('%s mobileDeactivated: "%s" "%s".position reset from %s to %s',
			modPrefix, ref.cell.id, ref.id, from, to)
	end
	from.x, from.y, from.z = to.x, to.y, to.z
	if not ab01dlPos then
		ref.facing = math.rad(ab01drlkStart[4])
	end
	data.ab01dlPos = nil
	data.ab01drlkStart = nil
	event.unregister('mobileDeactivated', mobileDeactivated)
end

local pi = math.pi
local double_pi = pi + pi

local function face(ref, target)
	local angleTo = ref:getAngleTo(target)
	local angle = ref.facing + angleTo
	angle = angle % double_pi
	-- -double_pi <= angle <= double_pi
	if angle < -pi then
		angle = angle + double_pi
	elseif angle > pi then
		angle = angle - double_pi
	end
	-- -pi <= angle <= pi
	if logLevel3 then
		mwse.log('%s: face() refAngle = %s, angleTo = %s, newAngle = %s',
			modPrefix, math.deg(ref.facing), math.deg(angleTo), math.deg(angle))
		---os.setClipboardText(string.format('currentRef.facing = %s', angle))
	end
	ref.facing = angle
end

local function ab01drlkPT2(e)
	local timer = e.timer
	local data = timer.data
	local handle1 = data.handle1
	local ref1 = handleToRef(handle1)
	if not ref1 then
		return
	end
	local handle2 = data.handle2
	local ref2 = handleToRef(handle2)
	if not ref2 then
		return
	end
	face(ref1, ref2)
end

local function activate(e)
	if modDisabled then
		return
	end
	if not (e.activator == player) then
		return
	end

	local targetRef = e.target

	local obj = targetRef.object
	local objType = obj.objectType

	if not (
		(objType == tes3_objectType_door)
		or (objType == tes3_objectType_container)
	) then
		return
	end

	local targetRefId = targetRef.id

	local funcPrefix = string.format('%s: activate("%s" in "%s")',
		modPrefix, targetRefId, targetRef.cell.editorName)

	if skips > 0 then
		if logLevel2 then
			mwse.log('%s: skips = %s, return', funcPrefix, skips)
		end
		skips = skips - 1
		return
	end

	local data = targetRef.data

	if inputController:isAltDown()
	and inputController:isShiftDown() then
		if tes3.mobilePlayer.isSneaking
		and data then
			if data.ab01drlkbl then
				data.ab01drlkbl = nil
			else
				data.ab01drlkbl = 1
			end
			local action = 'removed from'
			if data.ab01drlkbl then
				action = 'added to'
			end
			tes3.messageBox('%s: "%s" %s blacklist', modPrefix, targetRefId, action)
			return
		end
		if logLevel2 then
			mwse.log("%s: Alt+Shift pressed, skip", funcPrefix)
		end
		return -- skip if Alt or Shift pressed
	end

	if data
	and data.ab01drlkbl then
		if logLevel2 then
			mwse.log('%s: "%s" blacklisted by player, skip', funcPrefix, targetRefId)
		end
		return -- skip if blacklisted by player
	end

	local function delayedActivate(withKnockSound)
		local delay = 0.25
		skips = 1
		if withKnockSound then
			delay = 1.0
			skips = 2
		end
		local refHandle1 = tes3.makeSafeObjectHandle(targetRef)
		timer.start({duration = delay,
			type = timer.real, callback = 'ab01drlkPT1',
			data = {handle = refHandle1}
		})
	end

	local lockNode, level, key
	local hasKey = false

	local hoursPassedSinceGameStart = getInGameHoursFromGameStart()

	local function checkObjType()
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
								tes3ui.showNotifyMenu([[You use the "%s" from your KeyRing...]], key.name)
								updateDoorData(targetRef, false)
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
					if logLevel2 then
						mwse.log('%s: skipping scripted container', funcPrefix)
					end
					return 1
				end
			elseif (objType == tes3_objectType_door) then
				local scriptId = script.id
				local lcScriptId = string.lower(scriptId)
				if skipScript == 3 then
					if logLevel2 then
						mwse.log('%s: skipping scripted door', funcPrefix)
					end
					return 1
				elseif string.startswith(lcScriptId, 'dl_')
						or string.startswith(lcScriptId, '_doorlock')
						or string.find(lcScriptId, '^ld_%w-lock') then
					if skipScript == 2 then
						if logLevel2 then
							mwse.log('%s: skipping scripted LD door', funcPrefix)
						end
						return 1
					elseif skipScript > 0 then
						mwse.overrideScript(scriptId, nop)
						if logLevel2 then
							mwse.log('%s: overriding scripted LD/LCV door behavior', funcPrefix)
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

	if lockNode
	and level then
		if level == 0 then
			if lockNode.locked then
				if logLevel1 then
					mwse.log('%s: skipping 0-locked door/container', funcPrefix)
				end
				return
			end
		elseif level == 1 then
			if logLevel1 then
				mwse.log('%s: skipping door/container marked as openable (locked 1, then locked/unlocked by e.g. Revolving Doors Blocker mod)', funcPrefix)
			end
			return
		elseif data then
			if targetRef.modified
			and (not data.ab01drlkhp) then
				if logLevel1 then
					mwse.log('%s: skipping (once) door/container locked/unlocked by Player or script before Player activating it', funcPrefix)
				end
				-- skip activation but update stored timestamp
				updateDoorData(targetRef, false)
				return
			end
		end
		if logLevel3 then
			mwse.log('%s: "%s" "%s" locked = %s, lock level = %s',
				funcPrefix, targetRefId, obj.name, lockNode.locked, lockNode.level)
		end
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
			mwse.log('%s: skipping "%s" door loading to exterior "%s"',
				funcPrefix, targetRefId, destCellEditorName)
		end
		return
	end
	-- real interior destination below

	local lcDestCellId = getLcCellId(destCell)
	local doorCell = targetRef.cell
	local lcDoorCellId = getLcCellId(doorCell)

	if lcDestCellId == lcDoorCellId then
		if logLevel1 then
			mwse.log('%s: skipping door leading to the same "%s" cell',
				funcPrefix, destCellEditorName)
		end
		return
	end

	local sourceMod = targetRef.sourceMod
	if sourceMod
	and string.multifind(string.lower(sourceMod),{'ab01houses'}, 1, true) then
		if logLevel1 then
			mwse.log('%s: skipping door "%s" "%s" to "%s" from blacklisted mod "%s"',
				funcPrefix, obj.id, obj.name, destCellEditorName, sourceMod)
		end
		return
	end

	if string.multifind(lcDestCellId, destCellBlackList, 1, true) then
		if logLevel1 then
			mwse.log('%s: skipping blacklisted destination cell "%s"',
				funcPrefix, destCellEditorName)
		end
		return
	end

	local lcDoorId = string.lower(obj.id)
	local lcDoorName = string.lower(obj.name)

	if skipChargen then
		if find2(lcDoorId, lcDoorName, 'chargen') then
			if logLevel1 then
				mwse.log('%s: skipping "%s" chargen door to "%s"', funcPrefix, targetRef.id, destCellEditorName)
			end
			return
		end
	end

	if multifind2(lcDoorId, lcDoorName, doorBlackList) then
		if logLevel1 then
			mwse.log('%s: skipping blacklisted door "%s" "%s"', funcPrefix, obj.id, obj.name)
		end
		return
	end

	local hasDestSameLocationPrefix = getHasDestSameLocationPrefix(doorCell, destCell)

	local destCellIsHouse = isHouse(lcDestCellId)
	local destCellIsService = isService(lcDestCellId)
	local destCellWhitelisted = false
	if string.multifind(lcDestCellId, destCellWhiteList) then
		destCellWhitelisted = true
	end

	-- e.g. "Mundrethi Plantation, Merengor's House: Underground"
	if (not hasDestSameLocationPrefix)
	and (not destCellIsHouse)
	and (not destCellIsService)
	and (not destCellWhitelisted) then
		if logLevel1 then
			mwse.log('%s: skipping non-whitelisted destination cell "%s"',
				funcPrefix, destCellEditorName)
		end
		return
	end

	if logLevel3 then
		mwse.log('%s: door to "%s", hasDestSameLocationPrefix = %s',
			funcPrefix, destCellEditorName, hasDestSameLocationPrefix)
	end

	if hasDestSameLocationPrefix then
		local skip = false
		if doorCell.isOrBehavesAsExterior then
			if logLevel3 then
				mwse.log('%s: "%s" -> "%s" hasDestSameLocationPrefix, doorCellisOrBehavesAsExterior, skip = false',
					funcPrefix, lcDoorCellId, lcDestCellId)
			end
		else
			---if string.multifind(lcDoorCellId, homeLikeCells, 1, true)) or
			if not isDistrict(lcDoorCellId) then
				if logLevel3 then
					mwse.log('%s: hasDestSameLocationPrefix, doorCell "%s" not isOrBehavesAsExterior, not isDistrict, skip = true',
						funcPrefix, lcDoorCellId)
				end
				skip = true
			end
		end
		if skip then
			if logLevel2 then
				mwse.log('%s: door from "%s" to "%s", skip',
					funcPrefix, doorCell.id, destCellEditorName)
			end
			return
		end
	end

	local guardedDest = false
	if string.multifind(lcDestCellId, guardedList, 1, true) then
		guardedDest = true
	end
	local highSecurityDest = false
	if string.multifind(lcDestCellId, highSecurityList, 1, true) then
		guardedDest = true
		highSecurityDest = true
	end

	local newLockLevel = stdLockLevel
	if highSecurityDest then
		newLockLevel = hardLockLevel
		if logLevel3 then
			mwse.log('%s: door to "%s" in high security list, newLockLevel = %s',
				funcPrefix, getCellId(destCell), newLockLevel)
		end
	end

	local hour = worldController.hour.value
	local isOpenTime = (hour >= minOpenHour)
		and (hour <= maxOpenHour)
	local nextCloseHour = minOpenHour
	if isOpenTime then
		nextCloseHour = maxOpenHour
	end

	local someoneCanOpen = false

-- 1 'Not found', 2 'NPC', 3 'Trader', 4 'Faction member', 5 'Publican', 6 'Bed renting'
	local destMarker = doorDest.marker
	local npcType = 1
	---local isInstance = false
	local lastOpenerRef

	if destMarker then
		if logLevel3 then
			local s1 = 'door'
			local sourceMod = targetRef.sourceMod
			if sourceMod
			and (string.len(sourceMod) > 0) then
				s1 = '("'..sourceMod..'") door'
			end
			local s2 = '"'..destCellEditorName..'"'
			sourceMod = destMarker.sourceMod
			if sourceMod
			and (string.len(sourceMod) > 0) then
				s2 = s2..' ("'..sourceMod..'") '
			end
			mwse.log('%s: %s to %s', funcPrefix, s1, s2)
		end

		local destPosition = destMarker.position:copy()
		if destPosition then
			-- actors have origins low at feet level
			-- destMarkers have origins centered
			destPosition.z = destPosition.z - 80
			local rec = getBestKnownNPCrec(destCell, destPosition)
			npcType = rec.npcType
			local actorRef = rec.ref
			if actorRef then
				---isInstance = actorRef.object.isInstance
				---if isInstance then
					lastOpenerRef = actorRef
				---end
			end
		end
	end

-- 1 'Not found', 2 'NPC', 3 'Trader/Service', 4 'Faction member', 5 'Publican', 6 'Bed renting'
	if npcType >= 5 then -- bed renting or publican like
		isOpenTime = (hour >= maxPubCloseHour)
			or (hour <= minPubCloseHour)
		someoneInside = true
		---if isInstance
		---or (npcType == 6) then
			someoneCanOpen = true
		---end
		if not isOpenTime then
			nextCloseHour = minPubCloseHour
		end
	elseif npcType == 4 then -- same faction npc
		someoneInside = true
		if (hour >= minKnockHour)
		and (hour <= maxKnockHour) then
			someoneCanOpen = true
		end
		if not isOpenTime then
			nextCloseHour = minPubCloseHour
		end
	elseif npcType == 3 then -- trader
		someoneInside = true
		newLockLevel = hardLockLevel
		if (hour >= minKnockHour)
		and (hour <= maxKnockHour) then
			someoneCanOpen = true
		end
		if not isOpenTime then
			nextCloseHour = minPubCloseHour
		end
	elseif npcType == 2 then -- house like
		someoneInside = true
		if destCellIsHouse
		and (hour >= minKnockHour)
		and (hour <= maxKnockHour) then
			someoneCanOpen = true
		end
	else
		if string.multifind(lcDestCellId, pubLikeCells, 1, true)
		and not string.multifind(lcDestCellId, {'hut','keeper'}, 1, true) then
			isOpenTime = (hour >= maxPubCloseHour)
				or (hour <= minPubCloseHour)
			if logLevel3 then
				mwse.log('%s: door to "%s" close time set between %s and %s',
					funcPrefix, destCell.id, minPubCloseHour, maxPubCloseHour)
			end
		elseif destCellIsHouse
		and lockEmptyHouses
		and (not someoneInside) then
			isOpenTime = false
			if logLevel3 then
				mwse.log('%s: to "%s" closed empty house', funcPrefix, destCell.id)
			end
		end
	end
	if logLevel2 then
		mwse.log([[%s: dest = "%s", hour = %.02f,
isOpenTime = %s, someoneInside = %s, someoneCanOpen = %s, npcType = %s %s]],
			funcPrefix, getCellId(destCell), hour, isOpenTime,
			someoneInside, someoneCanOpen, npcType, npcTypes[npcType])
	end
	---end -- if hasDestSameLocationPrefix

	local ab01drlkhp
	if targetRef.data then
		ab01drlkhp = targetRef.data.ab01drlkhp
	end

	local recentlyLockedOrUnlocked = false
	if ab01drlkhp then
		local hoursPassedSinceLockChange = hoursPassedSinceGameStart - ab01drlkhp
		if ab01drlkhp > hoursPassedSinceGameStart then -- safety fix
			local ab01drlkhpFixed = hoursPassedSinceGameStart - 1
			if logLevel1 then
				mwse.log('%s: door "%s".data.ab01drlkhp fixed from %s to %s',
					funcPrefix, targetRef.id, ab01drlkhp, ab01drlkhpFixed)
			end
			ab01drlkhp = ab01drlkhpFixed
			targetRef.data.ab01drlkhp = ab01drlkhp
		end

		if hoursPassedSinceLockChange < lockUnlockIntervalHour then
			if logLevel1 then
				mwse.log('%s: hoursPassedSinceGameStart = %s, ab01drlkhp = %s',
					funcPrefix, hoursPassedSinceGameStart, ab01drlkhp)
				mwse.log('%s: door dest = "%s", hoursPassedSinceLockChange = %s < %s, skip',
					funcPrefix, getCellId(destCell), hoursPassedSinceLockChange, lockUnlockIntervalHour)
			end
			recentlyLockedOrUnlocked = true
		end
	end

	local function knockNotify(s)
		tes3ui.showNotifyMenu(s)
		if logLevel2 then
			mwse.log('%s: knockNotify(%s)', modPrefix, s)
		end
	end

	local function unlockAndActivateDoor()
		if logLevel1 then
			mwse.log('%s: unlockAndActivateDoor("%s") dest = "%s"',
				modPrefix, targetRefId, getCellId(destCell))
		end
		if lockNode then
			lockNode.level = newLockLevel
			if lockNode.locked then
				tes3.unlock({reference = targetRef})
			end
		end
		updateDoorData(targetRef, false)
		delayedActivate()
	end

	local destIsTent = false
	if string.multifind(string.lower(getCellId(destCell)),
			{'yurt','tent'}, 1, true) then
		destIsTent = true
	end

	local function knockUnlockAndActivateDoor()
		---skipKnock = true
		local withKnockSound = false
		if ab01KnockKnockSND
		and (player.cell == doorCell)
		and (not destIsTent) then
			withKnockSound = true
			playSound(ab01KnockKnockSND)
		end

		if npcType >= 2 then
-- 1 'Not found', 2 'NPC', 3 'Trader', 4 'Faction member', 5 'Publican', 6 'Bed renting'
			local doNotify = knockNotifyPerc >= math.random(100)
			if lastOpenerRef then
				-- move opener to door
				if logLevel1 then
					mwse.log('%s: knockUnlockAndActivateDoor("%s") dest = "%s", opened by "%s"',
						modPrefix, targetRefId, getCellId(destCell), lastOpenerRef)
				end
				if config.moveOpeningActor then
					local data = lastOpenerRef.data or {}
					local lop = lastOpenerRef.position
					data.ab01drlkStart = {round(lop.x), round(lop.y), round(lop.z),
						round( math.deg(lastOpenerRef.facing) )}
					event.register('mobileDeactivated', mobileDeactivated)

-- multiply vector by scalar see https://mwse.github.io/MWSE/types/tes3vector3/#multiplication
					local pos = (destMarker.forwardDirection * 72) + destMarker.position
					if logLevel2 then
						mwse.log('%s knockUnlockAndActivateDoor(): "%s".position set to "%s" %s',
							modPrefix, lastOpenerRef.id, lastOpenerRef.cell.id, pos)
					end
					local from = lastOpenerRef.position
					from.x, from.y, from.z = pos.x, pos.y, pos.z
					local refHandle1 = tes3.makeSafeObjectHandle(lastOpenerRef)
					local refHandle2 = tes3.makeSafeObjectHandle(destMarker)
					timer.start({duration = 0.25,
						type = timer.real, callback = 'ab01drlkPT2',
						data = {handle1 = refHandle1, handle2 = refHandle2}
					})
				end
				if doNotify
				and lastOpenerRef.object.isInstance then
					local o = lastOpenerRef.object
					local actorName = o.name
					local faction = o.faction
					local pcName = player.object.name
					local playerName = pcName
					if faction
					and faction.playerJoined then
						local playerRank = faction.playerRank
						if playerRank
						and (playerRank >= 0) then
						    playerName = faction:getRankName(playerRank) .. ' ' .. pcName
						end
					else
						local playerClass = player.object.class
						if playerClass
						and (math.random(1, 100) > 66) then
						    playerName = playerClass.name .. ' ' .. pcName
						end
					end
					if math.random(100) >= 75  then
						knockNotify( string.format([["It's me, %s!"]], playerName) )
					else -- 5 'Publican', 6 'Bed renting'
						knockNotify( string.format([[%s: "Ah, it's you. Welcome, %s."]],
							actorName, playerName) )
					end
				end
			elseif doNotify then
				local firstTimeSay = {
[["Anybody in there?"]], [["Hello, someone's inside?"]],
[["Somebody please, open the door!"]],[["Could someone make me enter?"]],
[["Please, I really need to enter!"]],[["Let me in!"]]
}
				knockNotify(firstTimeSay[math.random(#firstTimeSay)])
			end -- lastOpenerRef
		end -- if npcType >= 2

		if withKnockSound then
			timer.start({duration = 0.45, type = timer.real, callback = function ()
				playSound('Open Lock')
			end})
		end
		unlockAndActivateDoor()
	end

	local function lockAndActivateDoor()
		if someoneInside then
			if not someoneCanOpen then
				if math.random(100) >= 75 then
					knockNotify([["It's probably too late."]])
				end
			end
		else
			if logLevel1 then
				mwse.log('%s: empty/unfriendly house dest = "%s"',
					funcPrefix, destCell.id)
			end
			if math.random(100) >= 75 then
				knockNotify([["It seems nobody's home, or willing to open."]])
			end
		end
		tes3.lock({reference = targetRef, level = newLockLevel})
		updateDoorData(targetRef, true)
		delayedActivate()
	end

	if lockNode then
		if recentlyLockedOrUnlocked then
			if logLevel1 then
				mwse.log('%s: "%s" door to "%s" recently locked/unlocked, skip',
					funcPrefix, doorCell.id, destCell.id)
			end
			return -- lockNode processed
		end
		if lockNode.locked then
			if isOpenTime then
				if someoneInside
				or destCellWhitelisted
				or guardedDest then
					unlockAndActivateDoor()
					return false
				end
			else
				if someoneCanOpen
				or guardedDest then
				    if knockOn then
					    knockUnlockAndActivateDoor()
					    return false
					end
				end
			end
		else -- (lockNode.locked == false) and (recentlyLockedOrUnlocked == false)
			if hasDestSameLocationPrefix
			and (not isOpenTime)
			and (not destIsTent) then
				if someoneCanOpen then
					if knockOn then
						knockUnlockAndActivateDoor()
						return false
					end
				else
					if logLevel1 then
						mwse.log('%s: door "%s" (dest = "%s") locked',
							funcPrefix, targetRefId, getCellId(destCell))
					end
					lockAndActivateDoor()
					return false
				end
			end
		end
		return -- lockNode processed
	end

	if not recentlyLockedOrUnlocked
	and hasDestSameLocationPrefix
	and (not isOpenTime)
	and (not destIsTent) then
		if logLevel2 then
			mwse.log([[%s: door "%s" cell = "%s", dest = "%s", isOpenTime = %s,	someoneCanOpen = %s]],
				funcPrefix, targetRefId, getCellId(doorCell),
					getCellId(destCell), isOpenTime, someoneCanOpen)
		end
		if someoneCanOpen then
			if knockOn then
				knockUnlockAndActivateDoor()
			else
				unlockAndActivateDoor()
			end
		else
			if not isIllegalResting(destCell) then
				if logLevel1 then
					mwse.log('%s: door linked to "%s" legal-to-sleep interior cell destination, skip',
						funcPrefix, getCellId(destCell) )
				end
				return
			end
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
	timer.register('ab01drlkPT2', ab01drlkPT2)
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

local template = mwse.mcm.createTemplate({name = mcmName})

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

	local controls = preferences:createCategory({})

	local function getYesNoDescription(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	controls:createYesNoButton({
		label = 'Enabled',
		description = getYesNoDescription([[Default: %s.
Enable the mod effects.
Note: you can also skip processing current door/container under the cursor by pressing Alt+Shift while activating it.
Also if you do it while sneaking you can add/remove the door/container reference to/from the mod blacklist to make the mod ignore it.
]], 'modEnabled'),
		variable = createConfigVariable('modEnabled')
	})

	local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end

	controls:createInfo({text = string.format('House doors opening between %s and %s',
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
		,min = minKnockHour, max = 23
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

	controls:createSlider({
		label = 'Min lock/unlock interval (%s hours)',
		description = getDescription([[Default: %s.
Minimum hours interval between scheduled doors lock/unlock.]], 'lockUnlockIntervalHour'),
		variable = createConfigVariable('lockUnlockIntervalHour')
		,min = 1, max = 24
	})

	local optionList = {'Off','Containers',
		'Containers and LD/LCV Nighttime locked doors','All doors/containers'}

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
changes related to "LD/LCV Nighttime locks vanilla scripts" option are effective only on next Morrowind.exe restart.
]], 'skipScript')
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

local onlyEffective = '\nOnly effective when "Knock on doors" is enabled.'

	controls:createYesNoButton({
		label = 'Knock on doors',
		description = getYesNoDescription([[Default: %s.
Enable knocking on doors (e.g. doors to player Guilds).]], 'knockOn'),
		variable = createConfigVariable('knockOn')
	})

	controls:createYesNoButton({
		label = 'Allow knock for service/vendors',
		description = getYesNoDescription([[Default: %s.
Enable service/vendor actors to open doors (e.g. doors to pawnbrokers, but also to temple if player is not the same faction but there is some vendor/service inside).]], 'serviceKnock'),
		variable = createConfigVariable('serviceKnock')
	})

	controls:createSlider({
		label = 'Max door knock hearing distance',
		description = getDescription([[Default: %s.
Maximum distance of a friendly NPC from door destination marker to be able to hear player knocking on the door.]]..onlyEffective, 'maxHeardKnockDist'),
		variable = createConfigVariable('maxHeardKnockDist')
		,min = 256, max = 8192, jump = 16
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
Percent probability of player/npc saying something when player knocks on door.]]..onlyEffective, 'knockNotifyPerc'),
		variable = createConfigVariable('knockNotifyPerc')
		,min = 0, max = 100, jump = 5
	})

	controls:createYesNoButton({
		label = 'Move the actor opening the door',
		description = getYesNoDescription([[Default: %s.
Move the actor opening the door. Make it more immersive in places like 2 story houses/castles where nearby actors are not visible.]], 'moveOpeningActor'),
		variable = createConfigVariable('moveOpeningActor')
	})

	controls:createYesNoButton({
		label = 'Check script context',
		description = getYesNoDescription([[Default: %s.
Useful to check for bed renting services.
Try disabling it only in case of crashes while activating a door.]], 'checkScriptContext'),
		variable = createConfigVariable('checkScriptContext')
	})

	optionList = {'Off', 'Low', 'Medium', 'High', 'Higher', 'Max'}
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
end, {doOnce = true})
