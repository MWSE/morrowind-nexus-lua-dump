--[[
Loading Doors by abot

Automatically tunes linked doors locked/unlocked state on activate, lock/unlock by spell, unlock by lockpick
tuned doors are not only coherent, they should work great with mods like pursuit enhanced allowing NPCs to
chase you through doors and give a purpose to the lock spell.

Basically it's the same idea as Locked Doors Fix by qqqbbb (https://www.nexusmods.com/morrowind/mods/42293),
but working with any modded door from a single MWSE-LUA script.

Thanks to NullCascade for adding the missing locking functions to MWSE-Lua :-)

requires latest development MWSE-Lua
https://nullcascade.com/mwse/mwse-dev.zip

also added door close sounds (original idea/vanilla Morrowind mod by Sara)
]]

local defaultConfig = {
doorCloseSound = true, -- set it to false to disable loading doors door close sounds
doorLockTune = true, -- set it to false to disable loading doors lock synchronization
doorCloseSoundVolumePercent = 70, -- door close sound volume, 30 <= doorCloseSoundVolume <= 100
doorShiftLock = true, -- Shift + Activate = lock if you have the key
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium, 3 = High
}

local author = 'abot'
local modName = 'Loading Doors'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local linkedDoorsMaxDistance = 350 -- linked door - marker max distance, super tricky
local linkedDoorsMaxZdistance = 192 -- linked doors - marker max Z distance, super tricky
-- clear legacy Values
config.linkedDoorsMaxDistance = nil
config.linkedDoorsMaxZdistance = nil

local logLevel, logLevel1, logLevel2, logLevel3, logLevel4

local function updateConfig()
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
end
updateConfig()

local worldController, inputController, nonDynamicData, DuelActive, Arena_Fight

-- set in loaded()
local player

local function initVariables() -- called in initialized/(
	worldController = tes3.worldController
	assert(worldController)
	inputController = worldController.inputController
	assert(inputController)
	nonDynamicData = tes3.dataHandler.nonDynamicData
	assert(nonDynamicData)
	DuelActive = tes3.findGlobal('DuelActive')
	assert(DuelActive) -- standard quests global variable
	Arena_Fight = tes3.findGlobal('Arena_Fight') -- look for arena mod
end

-- updated in cellChanged()
local cachedExtCells = {}

local function scanCells(cell, cellsArray, logTime)
	local etime = os.clock()
	local cells = {}
	local cellGridX = cell.gridX
	local cellGridY = cell.gridY
	local size = #cellsArray
	assert(size >= 9)
	local j = 0
	local logElapsedTime = logTime
		and logLevel3
	for _, c in ipairs(cellsArray) do
		for x = -1, 1 do
			if c.gridX == cellGridX + x then
				for y = -1, 1 do
					if c.gridY == cellGridY + y then
						j = j + 1
						cells[j] = c
						if j >= 9 then
							if logElapsedTime then
								mwse.log('%s: scanCells("%s", %s) 1 elapsed time: %.3f s',
									modPrefix, cell.editorName, size, os.clock() - etime)
							end
							return cells
						end
					end
				end
			end
		end
	end
	if logElapsedTime then
		mwse.log('%s: scanCells("%s", %s) 2 elapsed time: %.3f s',
			modPrefix, cell.editorName, size, os.clock() - etime)
	end
	return cells
end

local function getCellsCulled(ref, maxDistanceFromRef)
-- active cells matrix example:
-- ^369
-- |258
-- |147
-- +----->
-- example
-- [1] = -3, -10 [2] = -3, -9 [3] = -3, -8
-- [4] = -2, -10 [5] = -2, -9 [6] = -2, -8
-- [7] = -1, -10 [8] = -1, -9 [9] = -1, -8
-- try marking cells that can be skipped

	local cells = {}

	local cell = ref.cell
	if cell.isInterior then
		cells[1] = cell
		return cells
	end

	if not maxDistanceFromRef then
		maxDistanceFromRef = 11585 -- math.floor(math.sqrt(8192*8192*2) + 0.5)
	elseif maxDistanceFromRef > 34756 then -- math.floor(math.sqrt((3*8192)*(3*8192)*2) + 0.5)
		maxDistanceFromRef = 34756
	end
	---assert(ref)
	local skip = {}
	local x = ref.position.x
	local y = ref.position.y
	local cellGridX = cell.gridX
	local cellGridY = cell.gridY

	local x0 = cellGridX * 8192
	local y0 = cellGridY * 8192
	local x1 = x0 + 8191
	local y1 = y0 + 8191

	local ac

	if cell == player.cell then
		ac = tes3.getActiveCells()
	elseif (#cachedExtCells >= 9) then
		ac = scanCells(cell, cachedExtCells)
	else
		if logLevel1 then
			mwse.log('%s: getCellsCulled("%s", %s) ac = scanCells(cell, nonDynamicData.cells, true)',
				modPrefix, ref, maxDistanceFromRef)
		end
		ac = scanCells(cell, nonDynamicData.cells, true)
	end
	
	assert(#ac >= 9)

	-- skip cells depending on distance of target marker from cell borders
	local dx = x1 - x
	if dx > maxDistanceFromRef then
		skip[7] = true
		skip[8] = true
		skip[9] = true
	end

	dx = x - x0
	if dx > maxDistanceFromRef then
		skip[1] = true
		skip[2] = true
		skip[3] = true
	end

	local dy = y1 - y
	if dy > maxDistanceFromRef then
		skip[3] = true
		skip[6] = true
		skip[9] = true
	end
	dy = y - y0
	if dy > maxDistanceFromRef then
		skip[1] = true
		skip[4] = true
		skip[7] = true
	end

	local j = 0
	for i = 1, #ac do
		if not skip[i] then
			j = j + 1
			cells[j] = ac[i]
			---mwse.log("culledCell = %s", ac[i].editorName)
		end
	end

	if (j == 0)
	or logLevel2 then
		local msg = "%s: getCellsCulled(ref = %s, maxDistanceFromRef = %s)"
		if j == 0 then
			msg = msg .. " no cells found!"
		end
		mwse.log(msg, modPrefix, ref, maxDistanceFromRef)
		if j > 0 then
			for i, c in ipairs(cells) do
				mwse.log("culledCell[%s] = %s", i, c.editorName)
			end
		end
	end

	return cells
end

local zdistMax = 0
local distMax = 0

local tes3_objectType_door = tes3.objectType.door

local function getCellDestDoorRef(doorRef, destMarker, destCell, maxDist)

	local destMarkerPos = destMarker.position

	local maxZdist = linkedDoorsMaxZdistance

	---mwse.log("maxZdist = %s", maxZdist)
	local doorRefPos = doorRef.position
	local funcPrefix = string.format("%s: %s", modPrefix, 'getCellDestDoorRef')
	if logLevel3 then
		mwse.log("%s destCell = %s", funcPrefix, destCell)
	end
	local doorRefCell = doorRef.cell
	for _, destDoorRef in pairs(destCell.activators) do
		if destDoorRef
		and (not destDoorRef.disabled)
		and (not destDoorRef.deleted)
		and (destDoorRef.baseObject.objectType == tes3_objectType_door) then
			---mwse.log("destDoorRef = %s", destDoorRef)
			local destDoorDest = destDoorRef.destination
			if destDoorDest then
				if logLevel4 then
					mwse.log("%s doorRef.cell = %s, destDoorDest.cell = %s",
						funcPrefix, doorRef.cell, destDoorDest.cell)
				end
				if destDoorDest.cell == doorRefCell then
					local destDoorRefPos = destDoorRef.position
					local destDoorDestMarkerPos = destDoorDest.marker.position
					local zdist = math.abs(destDoorRefPos.z - destMarkerPos.z)
					if logLevel2 then
						mwse.log("%s zdist = %s, maxZdist = %s", funcPrefix, zdist, maxZdist)
					end
					if zdist <= maxZdist then
						local zdist2 = math.abs(doorRefPos.z - destDoorDestMarkerPos.z)
						if logLevel2 then
							mwse.log("%s zdist2 = %s, maxZdist = %s", funcPrefix, zdist2, maxZdist)
						end
						if zdist2 <= maxZdist then
							local dist = destDoorRefPos:distance(destMarkerPos)
							if dist <= maxDist then
								local dist2 = doorRefPos:distance(destDoorDestMarkerPos)
								if dist2 <= maxDist then
									local zd = math.max(zdist, zdist2)
									if zd > zdistMax then
										zdistMax = zd
										if logLevel2 then
											mwse.log("%s zdistMax = %s", funcPrefix, zdistMax)
										end
									end
									local d = math.max(dist, dist2)
									if d > distMax then
										distMax = d
										if logLevel2 then
											mwse.log("%s distMax = %s", funcPrefix, distMax)
										end
									end
									if logLevel2 then
										mwse.log("%s doorRef = %s, doorcell = %s, destDoorRef = %s, destCell = %s, distMax = %s, zdistMax = %s)",
											funcPrefix, doorRef, doorRef.cell, destDoorRef, destCell, distMax, zdistMax)
									end
									return destDoorRef
								end -- if dist2 <= maxDist
							end -- if dist <= maxDist
						end -- if zdist2 <= maxZdist
					end -- if zdist <= maxZdist
				end -- if destDoorDest.cell
			end -- if destDoorDest
		end -- if destDoorRef
	end -- for destDoorRef
	return nil
end


local function round(x)
	return math.floor(x + 0.5)
end

local function getLinkedDoorRef(doorRef)
	local doorDest = doorRef.destination
	if not doorDest then
		return nil
	end

	local funcPrefix = string.format("%s: %s", modPrefix, 'getLinkedDoorRef')
	if round(DuelActive.value) > 0 then
		if logLevel1 then
			mwse.log("%s DuelActive global variable = %s, skip)", funcPrefix, DuelActive.value)
		end
		return nil
	end
	if Arena_Fight then
		if round(Arena_Fight.value) > 0 then
			if logLevel1 then
				mwse.log("%s Arena_Fight global variable = %s, skip)", funcPrefix, Arena_Fight.value)
			end
			return nil
		end
	end

	local destCell = doorDest.cell
	local destMarker = doorDest.marker
	if logLevel4 then
		mwse.log('%s doorDest = %s, destCell = %s, destMarker = %s',
			funcPrefix, doorDest, destCell, destMarker)
	end
	local maxDist = linkedDoorsMaxDistance

	if destCell.isInterior then
		local ldRef = getCellDestDoorRef(doorRef, destMarker, destCell, maxDist)
		return ldRef
	end

	local culledCells = getCellsCulled(destMarker, maxDist)
	for i = 1, #culledCells do
		local culledDestCell = culledCells[i]
		local ldRef = getCellDestDoorRef(doorRef, destMarker, culledDestCell, maxDist)
		if ldRef then
			return ldRef
		end
	end
end

local function getInGameHoursFromGameStart()
	local daysPassed = worldController.daysPassed.value
	local gameHour = worldController.hour.value
	return round( (daysPassed * 24) + gameHour )
end

local function updateLocked(ref)
	local data = ref.data
	if not data then
		return
	end
	local ab01locked = data.ab01locked
	if ab01locked == nil then
		return -- true/false are valid, nil means not set
	end
	-- we are now sure it is a processed lockable door

	local ab01lockLevel = data.ab01lockLevel

	local locked = tes3.getLocked({reference = ref})
	local lockLevel = tes3.getLockLevel({reference = ref})

	local lockedChanged = false
	if not (ab01locked == locked) then
		lockedChanged = true
		if ab01locked then
			tes3.lock({reference = ref})
		else
			tes3.unlock({reference = ref})
		end
		---if data.ab01drlkhp then
		data.ab01drlkhp = getInGameHoursFromGameStart()
		---end
		if not data.ab01mt then
			data.ab01mt = 1 -- mark it as already processed for More Traps mod
		end
	end

	local lockLevelChanged = false
	if ab01lockLevel
	and (ab01lockLevel > 0)
	and ( not (ab01lockLevel == lockLevel) ) then
		lockLevelChanged = true
		tes3.setLockLevel({reference = ref, level = ab01lockLevel})
	end
	if logLevel1 then
		local funcPrefix = string.format('%s: %s', modPrefix, 'updateLocked')
		local msg = string.format('%s ref = "%s"."%s"', funcPrefix, ref.cell.editorName, ref)
		if lockedChanged then
			msg = string.format('%s\n"%s".locked set to %s', msg, ref, ab01locked)
		end
		if lockLevelChanged then
			msg = string.format('%s\n, "%s".lockLevel set to %s', msg, ref, ab01lockLevel)
		end
		mwse.log(msg)
	end
	data.ab01locked = nil
	data.ab01lockLevel = nil
end

---local function referenceActivated(e)
	---updateLocked(e.reference)
---end

local function doorTune(doorRef, destDoorRef)
	local locked = tes3.getLocked({reference = doorRef})
	local destLocked = tes3.getLocked({reference = destDoorRef})
	local doorPos = doorRef.position
	local destDoorPos = destDoorRef.position

	if destLocked
	and destDoorRef.baseObject.persistent then
		if logLevel1 then
			local msg = string.format("%s: doorTune() destDoorRef = %s (%s %s %s) is persistent and locked, could be a rented inn door, skip",
				modPrefix, destDoorRef, destDoorPos.x, destDoorPos.y, destDoorPos.z)
			mwse.log(msg)
		end
		return -- it could be linked to a rented inn door, skip
	end

	-- try to avoid problems with e.g scheduling mods locking tavern doors by night
	local doLock = false
	local doorCell = doorRef.cell
	local destDoorCell = destDoorRef.cell

	if doorCell.isInterior then
		if doorCell.behavesAsExterior then
			doLock = true
		else
			if destDoorCell.isInterior then
				if not destDoorCell.behavesAsExterior then
					doLock = true
				end
			else
				doLock = true
			end
		end

	else
		doLock = true
	end

	if not doLock then
		if logLevel1 then
			local msg = string.format("%s: doorTune() destDoorRef = %s (%s %s %s) could be related to scheduling mods e.g. locking tavern doors by night, skip",
				modPrefix, destDoorRef, destDoorPos.x, destDoorPos.y, destDoorPos.z)
			mwse.log(msg)
		end
		return
	end

	local lockLevel = tes3.getLockLevel({reference = doorRef})
	if lockLevel
	and (lockLevel < 0)
	and	locked then
		lockLevel = 5
	end

	local destLockLevel = tes3.getLockLevel({reference = destDoorRef})
	if destLockLevel
	and (destLockLevel < 0)
	and destLocked then
		destLockLevel = 5
	end

	if logLevel1 then
		local msg = string.format("%s: doorTune() doorRef = %s (%.4f %.4f %.4f), destDoorRef = %s (%.4f %.4f %.4f)", modPrefix, doorRef,
			doorPos.x, doorPos.y, doorPos.z, destDoorRef, destDoorPos.x, destDoorPos.y, destDoorPos.z)
		if logLevel2 then
			msg = string.format('%s\nBEFORE:\ndoorRef "%s".locked = %s, doorRef "%s".lockLevel = %s\ndestDoorRef "%s".locked = %s, destDoorRef "%s".lockLevel = %s',
				msg, doorRef, locked, doorRef, lockLevel, destDoorRef, destLocked, destDoorRef, destLockLevel)
		end
		mwse.log(msg)
	end

	local lockNode = doorRef.lockNode
	if lockNode then
		local key = lockNode.key
		if key then
			local keyId = key.id
			local destLockNode = destDoorRef.lockNode
			if destLockNode then
				local destKey = destLockNode.key
				if (not destKey)
				and player.object.inventory:contains(keyId) then
-- cannot add a key to destination door, so unlock it as we have the key for the other side door anyway				
					locked = false
				end
			end
		end
	end

	local data = destDoorRef.data
	if not data then
		destDoorRef.data = {}
		data = destDoorRef.data
	end
	data.ab01locked = locked
	data.ab01lockLevel = lockLevel

	updateLocked(destDoorRef)

end

local function handleToRef(handle)
	---assert(handle)
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

--[[
local function getTimerRefs(e)
	local data = e.timer.data
	local handles = data.handles
	local refs = {}
	for i = 1, #handles do
		local ref = handleToRef(handles[i])
		if ref then
			refs[i] = ref
		end
	end
	if #refs == #handles then
		return refs
	end
end
]]

local function ab01lddrPT1(e)
	local doorRef = getTimerRef(e)
	if not doorRef then
		return
	end
	local destDoorRef = getLinkedDoorRef(doorRef)
	if not destDoorRef then
		return
	end
	if logLevel1 then
		mwse.log('%s: ab01lddrPT1() doorTune(doorRef = "%s"."%s", destDoorRef = "%s"."%s")',
			modPrefix, doorRef.cell.editorName, doorRef, destDoorRef.cell.editorName, destDoorRef)
	end
	doorTune(doorRef, destDoorRef)
end

local function delayedDoorTune(doorRef, delay)
	local doorRefHandle = tes3.makeSafeObjectHandle(doorRef)
	timer.start({duration = delay, callback = 'ab01lddrPT1', --[[type = timer.real,]]
		data = {handle = doorRefHandle}
	})
end


local closeSoundId
local function getCloseSoundId(obj)
	local cs = obj.closeSound
	if cs then
		return cs.id
	end
	local openSound = obj.openSound
	if openSound then
		local s = openSound.id
		if s then
			s = string.gsub(s, '[Oo][Pp][En][Nn]', 'Close') -- replace 'Open' with 'Close', case insensitive
			cs = tes3.getSound(s)
			if cs then
				return s
			end
		end
	end
end

local function ab01ldndoorPT1()
	if closeSoundId then
		local vol = config.doorCloseSoundVolumePercent / 100
		tes3.playSound({sound = closeSoundId, volume = vol})
		closeSoundId = nil
	end
end


local function cellChanged()
	local ac = tes3.getActiveCells()
	local count = #ac
	if count >= 9 then
		for i = 1, count do
			cachedExtCells[i] = ac[i]
		end
		if logLevel3 then
			mwse.log('%s: cellChanged() cachedExtCells updated', modPrefix)
		end	
	end
	if closeSoundId then
		timer.start({duration = 1, callback = 'ab01ldndoorPT1'})
	end
end


local tes3_objectType_container = tes3.objectType.container

-- priority must be > animated containers
local function activateShiftLockCheck(e)
	if not config.doorShiftLock then
		return
	end
	if not (e.activator == player) then
		return
	end

	if logLevel3 then
		mwse.log("%s: activateShiftLockCheck()", modPrefix)
	end

	local ref = e.target
	local obj = ref.baseObject
	local objType = obj.objectType

	if not (
		(objType == tes3_objectType_door)
	 or (objType == tes3_objectType_container)
	) then
		---mwse.log("objType = %s", objType)
		return
	end
	if not inputController:isShiftDown() then
		---mwse.log("no SHIFT pressed")
		return
	end
	local locked = tes3.getLocked({reference = ref})
	if locked then -- important! it happens a lot!
		return
	end
	local lockNode = ref.lockNode
	---mwse.log("%s: inputController:isKeyDown(LEFT_SHIFT), lockNode = %s", modPrefix, lockNode)
	if not lockNode then
		---mwse.log("no lockNode")
		return
	end
	local key = lockNode.key
	if not key then
		---mwse.log("no lockNode.key")
		return
	end
	local keyId = key.id
	---mwse.log("%s: keyId = %s", modPrefix, keyId)
	if not e.activator.object.inventory:contains(keyId) then
		---mwse.log("e.activator.object.inventory:contains('%s') is false", keyId)
		return
	end
	---mwse.log("%s: hasKey(%s), locking", modPrefix, keyId)
	if tes3.lock({reference = ref}) then
		tes3.playSound({sound = 'Open Lock'})
		tes3ui.showNotifyMenu("%s used to lock %s", key.name, obj.name)
	end
	return false -- important!
end

local lockedDoorSoundId = 'LockedDoor'
local lockedDoorSound -- set in modConfigReady()= tes3.getSound(lockedDoorSoundId)

local soundObjectPlayRegistered = false
local function soundObjectPlay(e)
	-- skip if the door is emitting a locked sound (not locked but scripted e.g. bank door
	if e.sound == lockedDoorSound then
		if logLevel1 then
			mwse.log("%s: soundObjectPlay() e.sound == lockedDoorSound", modPrefix)
		end
		closeSoundId = nil --  if door is playing locked sound, set linked door close sound to nil
	--[[elseif e.sound.id == lockedDoorSoundId then
		if logLevel1 then
			mwse.log("%s: soundObjectPlay() e.sound.id == lockedDoorSoundId", modPrefix)
		end
		closeSoundId = nil]]
	elseif logLevel4 then
		mwse.log("%s: soundObjectPlay() e.sound.id = %s", modPrefix, e.sound.id)
	end
	---if event.isRegistered('soundObjectPlay', soundObjectPlay) then
	soundObjectPlayRegistered = false
	event.unregister('soundObjectPlay', soundObjectPlay)
	---end
end

-- lower priority
local function activate(e)
	if not (e.activator == player) then
		return
	end
	if not config.doorLockTune then
		if not config.doorCloseSound then
			return
		end
	end
	if logLevel4 then
		mwse.log("%s: activate()", modPrefix)
	end
	local doorRef = e.target
	local obj = doorRef.baseObject
	local objType = obj.objectType

	if not (objType == tes3_objectType_door) then
		return
	end
	local doorDest = doorRef.destination
	if not doorDest then
		return
	end
	local locked = tes3.getLocked({reference = doorRef})
	if locked then
		return
	end

	if config.doorCloseSound then
		closeSoundId = getCloseSoundId(doorRef.baseObject)
		--- if not event.isRegistered('soundObjectPlay', soundObjectPlay, {sound = lockedDoorSound}) then -- nope filtering does not work
		if not soundObjectPlayRegistered then
			soundObjectPlayRegistered = true
			event.register('soundObjectPlay', soundObjectPlay)
		end
	else
		closeSoundId = nil
	end
	delayedDoorTune(doorRef, 0.5)
end

local function lockPick(e)
	local doorRef = e.reference
	if not (doorRef.baseObject.objectType == tes3_objectType_door) then
		return
	end
	local doorDest = doorRef.destination
	if not doorDest then
		return
	end
	if not e.picker == tes3.mobilePlayer then
		return
	end
	if logLevel2 then
		mwse.log('\n%s: lockPick() door "%s"', modPrefix, doorRef.id)
	end
	delayedDoorTune(doorRef, 0.5)
end


local tes3_effect_lock = tes3.effect.lock
local tes3_effect_open = tes3.effect.open

local spellTicked
local function spellTick(e)
	local effectId = e.effectId
	if not (
		(effectId == tes3_effect_open)
	 or (effectId == tes3_effect_lock)
	) then
		return
	end
	if not (e.caster == player) then
		return
	end
	local doorRef = e.target
	if not doorRef then
		return
	end
	if not (doorRef.baseObject.objectType == tes3_objectType_door) then
		return
	end
	local doorDest = doorRef.destination
	if not doorDest then
		return
	end

	if spellTicked then
		return -- before spamming log!
	end
	if logLevel2 then
		mwse.log("\n%s: spellTick(), spell = %s, effectId = %s, target = %s", modPrefix, e.source, effectId, doorRef)
	end
	spellTicked = true
	delayedDoorTune(doorRef, 0.5)
end


local function casted(e)
	--- mwse.log(json.encode(e))
	--[[local doorRef = e.target -- bah! e.target is always nil even with onTouck lock/unlock spells]]
	if not (e.caster == player) then
		return
	end
	local effects = e.source.effects
	local eff
	for i = 1, #effects do
		eff = effects[i]
		if (eff.id == tes3_effect_open)
		or (eff.id == tes3_effect_lock) then
			if logLevel2 then
				mwse.log("\n%s: casted(), magic = %s", modPrefix, e.source)
			end
			spellTicked = false
			return -- important to exit the loop ASAP, or could use break
		end
	end
end


local function logConfig(cfg, options)
	mwse.log(json.encode(cfg, options))
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function save()
	local data = player.data
	if data then
		data.ab01ldCloSndId = closeSoundId
	end
end

local loadedOnce = false

local function loaded()
	player = tes3.player
	closeSoundId = nil
	local data = player.data
	if data then
		closeSoundId = data.ab01ldCloSndId
	end
	if loadedOnce then
		return
	end
	loadedOnce = true
	event.register('save', save)
	event.register('magicCasted', casted) -- spells, alchemy and enchanted items
	event.register('spellTick', spellTick)
	event.register('lockPick', lockPick)
	event.register('activate', activateShiftLockCheck, {priority = 1300}) -- priority must be > animated containers
	event.register('activate', activate, {priority = -1113})
	event.register('cellChanged', cellChanged)
end

local function modConfigReady()

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		updateConfig()
		mwse.saveConfig(configName, config, {indent = false})
	end

	local preferences = template:createSideBarPage{
		label="Info",
		postCreate = function(self)
			local width1 = 1.4
			local width2 = 2 - width1 -- total width must be 2
			local sideBlock = self.elements.sideToSideBlock
			sideBlock.children[1].widthProportional = width1
			sideBlock.children[2].widthProportional = width2
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo{text = ""}

	local controls = preferences:createCategory{label = mcmName}

	---controls:createInfo({text = 'Note: some settings need to restart Morrowind.exe to be effective.'})

	controls:createYesNoButton{
		label = "Loading doors lock synchronization",
		description = "If exterior door is locked/unlocked, so is linked interior door and vice versa. Default: Yes.",
		variable = createConfigVariable("doorLockTune")
	}

	controls:createYesNoButton{
		label = "Loading doors close sound enabled",
		description = "Play a slighty delayed close door sound after opening a loading door. Default: Yes.",
		variable = createConfigVariable("doorCloseSound")
	}

	controls:createSlider{
		label = "Close door sound volume %s%%",
		description = '(effective only when previous "Loading doors close sound" option is set to Yes',
		variable = createConfigVariable("doorCloseSoundVolumePercent")
		,min = 20, max = 100, step = 1, jump = 10
	}

	controls:createYesNoButton{
		label = "Shift + Activate = Lock",
		description = "Lock a door with Shift + Activate (if you have the key). Default: Yes.",
		variable = createConfigVariable("doorShiftLock")
	}

	local optionList = {'Off', 'Low', 'Medium', 'High', 'Max'}
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
		label = 'Log level:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s', 'logLevel'),
		variable = createConfigVariable('logLevel'),
	})

	lockedDoorSound = tes3.getSound(lockedDoorSoundId)
	assert(lockedDoorSound)

	timer.register('ab01lddrPT1', ab01lddrPT1)
	timer.register('ab01ldndoorPT1', ab01ldndoorPT1)

	mwse.mcm.register(template)
	logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)

event.register('initialized', function ()
	initVariables()
	---event.register('referenceActivated', referenceActivated)	
	event.register('loaded', loaded)
end, {doOnce = true})

