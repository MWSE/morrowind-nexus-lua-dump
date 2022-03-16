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

-- BEGIN configurable parameters
local defaultConfig = {
doorCloseSound = true, -- set it to false to disable loading doors door close sounds
doorLockTune = true, -- set it to false to disable loading doors lock synchronization
doorCloseSoundVolumePercent = 70, -- door close sound volume, 30 <= doorCloseSoundVolume <= 100
doorShiftLock = true, -- Shift + Activate = lock if you have the key
linkedDoorsMaxDistance = 450, -- linked doors max distance, tricky (e.g. see Ald-ruhn, Manor District->Ald-ruhn, Redoran Council Entrance multiple in_ar_door_01)
---fixNorthMarkers = false, -- place/fix missing/misoriented North Markers in door linked interiors, not for now
debugLog = false,
debugMsg = false,
}
-- END configurable parameters

local author = 'abot'
local modName = 'Loading Doors'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)


-- functions to e.g. avoid heavy/crashy loops on CellChange
-- when player is moving too fast e.g. superjumping

local inputController, DuelActive, scenicTravelAvailable, ab01boDest, ab01ssDest, ab01goDest, ab01compMounted, Arena_Fight
local function initVariables() -- called in modConfigReady
	inputController = tes3.worldController.inputController
	assert(inputController)
	DuelActive = tes3.findGlobal('DuelActive')
	assert(DuelActive) -- standard quests global variable
	ab01boDest = tes3.findGlobal('ab01boDest')
	ab01ssDest = tes3.findGlobal('ab01ssDest')
	ab01goDest = tes3.findGlobal('ab01goDest')
	ab01compMounted = tes3.findGlobal('ab01compMounted')
	if ab01boDest then
		scenicTravelAvailable = true
	elseif ab01ssDest then
		scenicTravelAvailable = true
	elseif ab01goDest then
		scenicTravelAvailable = true
	elseif ab01compMounted then
		scenicTravelAvailable = true
	else
		scenicTravelAvailable = false
	end
	Arena_Fight = tes3.findGlobal('Arena_Fight') -- look for arena mod
end

--[[local function isGlobalPositive(globalVarId)
	local v = tes3.getGlobal(globalVarId)
	if v then
		if v > 0 then
			if math.floor(v) > 0 then
				return true
			end
		end
	end
	return false
end]]

local function isPlayerScenicTraveling()
	if not scenicTravelAvailable then
		return false
	end
	if ab01boDest then
		if math.floor(ab01boDest.value + 0.5) > 0 then
			return true -- if scenic boat traveling
		end
	end
	if ab01ssDest then
		if math.floor(ab01ssDest.value + 0.5) > 0 then
			return true -- if scenic strider traveling
		end
	end
	if ab01goDest then
		if math.floor(ab01goDest.value + 0.5) > 0 then
			return true -- if scenic gondola traveling
		end
	end
	if ab01compMounted then
		if math.floor(ab01compMounted.value + 0.5) > 0 then
			return true -- if guar riding
		end
	end
end

local function isPlayerMovingFast()
	local mobilePlayer = tes3.mobilePlayer
	if mobilePlayer then
		local velocity = mobilePlayer.velocity
		if velocity then
			if #velocity >= 300 then
				return true
			end
		end
	end
	return false
end

local dbc = '' -- debug message breadcrumb

local function append2dbc(append)
	if dbc then
		if not append then
			assert(append)
			append = ''
		end
		if dbc == '' then
			dbc = append
		else
			dbc = string.format("%s/%s", dbc, append)
		end
	end
end

local function prefixed(s)
	return string.format("%s/%s", modPrefix, s)
end

---local maxDoorDistance = 450 -- max allowed door - doormarker distance - very tricky to tune for both lock and sound effect

local DOOR_T = tes3.objectType.door
local CONT_T = tes3.objectType.container

local function getCloseSound(obj)
	local closeSound = obj.closeSound
	if not closeSound then
		local openSound = obj.openSound
		if openSound then
			local s = openSound.id
			if s then
				s = string.gsub(s, '[Oo][Pp][En][Nn]', 'Close') -- replace 'Open' with 'Close', case insensitive
				closeSound = tes3.getObject(s)
			end
		end
	end
	return closeSound
end

local activatedDoorRef

local player -- set in loaded()

local function playDoorCloseSound() -- delayed on cellChanged

	local ref = activatedDoorRef
	activatedDoorRef = nil

	if not ref then
		if config.debugLog then
			local fmt = "playDoorCloseSound activatedDoorRef=%s"
			mwse.log(fmt, ref)
		end
		return
	end

	local obj = ref.object
	if not obj then
		if config.debugLog then
			local fmt = "playDoorCloseSound activatedDoorRef.object=%s"
			mwse.log(fmt, obj)
		end
		return
	end

	local closeSound = getCloseSound(obj)
	if not closeSound then
		if config.debugLog then
			local fmt = "playDoorCloseSound no available open/close sound for door %s"
			mwse.log(fmt, obj.id)
		end
		return
	end

	--[[
	if not player then
		if config.debugLog then
			local fmt = "playDoorCloseSound player=%s"
			mwse.log(fmt, player)
		end
		return
	end
	--]]

	local vol = config.doorCloseSoundVolumePercent / 100
	tes3.playSound({ sound = closeSound, volume = vol })

	append2dbc('playDoorCloseSound')

	if config.debugMsg then
		local fmt = "%s tes3.playSound{ sound = \"%s\", volume = \"%s\" }"
		tes3.messageBox({ message = string.format(fmt, dbc, closeSound.id, vol) })
	end
	dbc	= ''

end

local function cellChanged()
	if activatedDoorRef then
		timer.start({type = timer.real, duration = 1.0, callback = playDoorCloseSound})
	end
end

-- for delayed scheduled doorTune
local ddtDoorRef
local ddtDoorTimer

--[[
local STAT_T = tes3.objectType.static

local function getNorthMarkerRef(interiorCell)
	for ref in interiorCell:iterateReferences(STAT_T) do
		if ref.object.id:lower() == 'northmarker' then
			return ref
		end
	end
	return nil
end

local PI = math.pi
local DOUBLE_PI = PI * 2
local HALF_PI = PI / 2
local DGR = PI/180

local function wrapRadians(x)
	return x % DOUBLE_PI
end
]]

local function getActiveCellsCulled(ref, maxDistanceFromRef)
--[[
active cells matrix example:
^369
|258
|147
---->
[1] = -3, -10 [2] = -3, -9 [3] = -3, -8
[4] = -2, -10 [5] = -2, -9 [6] = -2, -8
[7] = -1, -10 [8] = -1, -9 [9] = -1, -8
try marking cells that can be skipped
]]
	if not maxDistanceFromRef then
		maxDistanceFromRef = 11585 -- math.floor(math.sqrt(8192*8192*2) + 0.5)
	elseif maxDistanceFromRef > 34756 then -- math.floor(math.sqrt((3*8192)*(3*8192)*2) + 0.5)
		maxDistanceFromRef = 34756
	end
	if not ref then
		ref = player
	end
	local skip = {}
	local x = ref.position.x
	local y = ref.position.y
	local x0 = ref.cell.gridX * 8192
	local y0 = ref.cell.gridY * 8192
	local x1 = x0 + 8191
	local y1 = y0 + 8191

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

	local cells = {}
	local j = 0
	local debugLog = config.debugLog
	for i, cell in ipairs(tes3.getActiveCells()) do
		---mwse.log("tes3.getActiveCells() i = %s, cell = %s", i, cell.editorName)
		if not skip[i] then -- skip loaded cells depending on distance of target marker from cell borders
			j = j + 1
			cells[j] = cell -- important if using ipairs as f* ipairs does not work without 1..n complete key sequence
			if debugLog then
				mwse.log('getActiveCellsCulled(ref = "%s", maxDistanceFromRef = %s): cell "%s" added', ref.id, maxDistanceFromRef, cell.editorName)
			end
		elseif debugLog then
			mwse.log('getActiveCellsCulled(ref = "%s", maxDistanceFromRef = %s): cell "%s" skipped', ref.id, maxDistanceFromRef, cell.editorName)
		end
	end
	return cells
end


local function doorTune(doorRef)
	if not doorRef then
		assert(doorRef)
		return
	end
	if not doorRef.position then
		assert(doorRef.position)
		return
	end
	local doorCell = doorRef.cell
	if not doorCell then
		assert(doorCell)
		return
	end
	local doorObj = doorRef.object
	if not doorObj then
		assert(doorObj)
		return
	end
	if not (doorObj.objectType == DOOR_T) then
		return
	end

	--[[
	if not doorCell.id then
		return
	end
	--]]

	local doorDest = doorRef.destination
	if not doorDest then
		return
	end

	local debugLog = config.debugLog

	local destCell = doorDest.cell
	if not destCell then
		if config.debugLog then
			local fmt = "doorTune destCell = %s"
			mwse.log(fmt, destCell)
		end
		return
	end
	local destMarker = doorDest.marker -- note: markers are type STAT
	if not destMarker then
		if debugLog then
			local fmt = "doorTune destMarker = %s"
			mwse.log(fmt, destMarker)
		end
		return
	end

	local destMarkerPos = destMarker.position
	if not destMarkerPos then
		if debugLog then
			local fmt = "doorTune destMarkerPos = %s"
			mwse.log(fmt, destMarkerPos)
		end
		return
	end

	if isPlayerMovingFast() then
		return
	end
	if isPlayerScenicTraveling() then
		return
	end
	if math.floor(DuelActive.value + 0.5) > 0 then
		return
	end
	if Arena_Fight then
		if math.floor(Arena_Fight.value + 0.5) > 0 then
			return
		end
	end

	local maxDist = config.linkedDoorsMaxDistance
	local ldRef
	local dist1, dist2
	local linkedDoorDest, marker

	local function checkDoors(linkedDoorRef)
		if linkedDoorRef.disabled then
			return
		end
		if linkedDoorRef.deleted then
			return
		end
		local linkedDoorObj = linkedDoorRef.object
		if not linkedDoorObj then
			assert(linkedDoorObj)
			return
		end
		if not (linkedDoorObj.objectType == DOOR_T) then
			return
		end
		---mwse.log("linkedDoorRef = %s", linkedDoorRef.id)
		dist2 = linkedDoorRef.position:distance(destMarkerPos)
		if dist2 > maxDist then
			return
		end
		if debugLog then
			mwse.log('doorTune "%s".position:distance(destMarkerPos) = %s <= %s found', linkedDoorRef.id, dist2, maxDist)
		end
		linkedDoorDest = linkedDoorRef.destination
		if not linkedDoorDest then
			return
		end
		if not linkedDoorDest.cell then
			return
		end
		---mwse.log("linkedDoorDest.cell.id = %s, doorCell.id = %s", linkedDoorDest.cell.id, doorCell.id)
		if not (linkedDoorDest.cell.id == doorCell.id) then
			return
		end
		marker = linkedDoorDest.marker
		if not marker then
			return
		end
		if not marker.position then
			return
		end
		dist1 = doorRef.position:distance(marker.position)
		if dist1 <= maxDist then
			if debugLog then
				mwse.log('doorTune "%s".position:distance(marker.position) = %s <= %s found', doorRef.id, dist1, maxDist)
			end
			ldRef = linkedDoorRef
		end
	end

	if destCell.isInterior then
		for linkedDoorRef in tes3.iterate(destCell.activators) do
			checkDoors(linkedDoorRef)
			if ldRef then
				break
			end
		end
	else
		local activeCells = getActiveCellsCulled(destMarker, maxDist)
		if debugLog then
			mwse.log("doorTune #activeCells = %s", #activeCells)
		end
		for _, dcell in ipairs(activeCells) do
			if debugLog then
				mwse.log('doorTune processing cell "%s"', dcell.editorName)
			end
			for linkedDoorRef in tes3.iterate(dcell.activators) do
				checkDoors(linkedDoorRef)
				if ldRef then
					break
				end
			end -- for linkedDoorRef

			if ldRef then
				break
			end

		end -- for _, cell
	end -- if destCell.isInterior

	if ldRef then

		--[[ bah. door mesh orientation is too random for this
		if config.fixNorthMarkers then
			if doorCell.isInterior then
				if not doorCell.behavesAsExterior then
					if ( (not ldRef.cell.isInterior)
					or (ldRef.cell.behavesAsExterior) ) then
						local z = wrapRadians( math.abs( wrapRadians(ldRef.orientation.z) - wrapRadians(destMarker.orientation.z) ) )
						if z > HALF_PI then
							z = destMarker.orientation.z -- probably the destMarker is more precise here as it could be a door with non-standard alignment
						else
							z = ldRef.orientation.z
						end
						z = wrapRadians( wrapRadians(DOUBLE_PI - z) + wrapRadians(doorRef.orientation.z + PI) )
						if not z then
							z = 0
						end
						local northMarkerPos, northMarkerOrient
						local northMarkerRef = getNorthMarkerRef(doorCell)
						if northMarkerRef then
							northMarkerPos = northMarkerRef.position:copy()
							northMarkerOrient = northMarkerRef.orientation:copy()
						else
							northMarkerPos = doorRef.position:copy()
							northMarkerPos.z = northMarkerPos.z + 512
							northMarkerOrient = {0, 0, z}
							northMarkerRef = tes3.createReference( {object = 'NorthMarker', position = northMarkerPos,
								orientation = northMarkerOrient, cell = doorCell} )
							local fmt = "%s %s cell \"%s\" missing NorthMarker placed"
							mwse.log(fmt, prefixed(dbc), doorCell.sourceMod, doorCell.id)
						end
						if northMarkerRef then
							local dz = math.abs(z - wrapRadians(northMarkerOrient.z))
							if dz > DGR then
								northMarkerOrient.z = z
								tes3.setEnabled({reference = northMarkerRef, enabled = true})
								northMarkerRef.modified = true
								---if config.debugLog then
									local fmt = "%s %s cell \"%s\" NorthMarker set to x = %s, y = %s, z = %s, Z angle = %s"
									mwse.log(fmt, prefixed(dbc), doorCell.sourceMod, doorCell.id, northMarkerPos.x, northMarkerPos.y, northMarkerPos.z, z)
								---end
							end
						end
					end
				end
			end
		end
		]]

		local locked = tes3.getLocked({reference = doorRef})
		local lockLevel = tes3.getLockLevel({reference = doorRef})
		local linkedLocked = tes3.getLocked({reference = ldRef})
		local linkedLockLevel = tes3.getLockLevel({reference = ldRef})
		append2dbc('doorTune')

		if debugLog then
			local fmt = "%s door \"%s\" \"%s\" lock=%s locked=%s linking door \"%s\" \"%s\" lnkLock=%s lnkLocked=%s marker distance=%s, %s"
			mwse.log(fmt, prefixed(dbc), doorCell.id, doorRef.id, lockLevel, locked, destCell.id, ldRef.id, linkedLockLevel, linkedLocked, dist1, dist2)
			if config.debugMsg then
				tes3.messageBox({ message = string.format(fmt, dbc, doorCell.id, doorRef.id, lockLevel, locked, destCell.id, ldRef.id, linkedLockLevel, linkedLocked, dist1, dist2) })
			end
		end

		local linkedPersistent = ldRef.baseObject.persistent
		if linkedPersistent
		and linkedLocked then -- it could be linked to a rented inn door, skip
			dbc = '' -- reset debug breadcrumb
			return -- exit loop & function
		end

		if locked == linkedLocked then
			if lockLevel == linkedLockLevel then
				dbc = '' -- reset debug breadcrumb
				return -- exit loop & function
			end
		end

		if lockLevel then -- SAFETY!
			if ldRef.cell then
				tes3.setLockLevel({ reference = ldRef, level = lockLevel})
			end
		end
		if locked then
			local doLock = false -- try to avoid problems with e.g scheduling mods locking tavern doors by night
			if doorCell.isInterior then
				if doorCell.behavesAsExterior then
					doLock = true
				elseif linkedDoorDest.cell.isInterior then
					if not linkedDoorDest.cell.behavesAsExterior then
						doLock = true
					end
				end
			else
				doLock = true
			end
			if doLock then
				tes3.lock({ reference = ldRef})
			end
		else
			tes3.unlock({ reference = ldRef})
		end

		if doorRef.lockNode then
			if doorRef.lockNode.key then
				if ldRef.lockNode then
					if not ldRef.lockNode.key then
						ldRef.lockNode.key = doorRef.lockNode.key
						ldRef.modified = true
					end
				end
			end
		end

		if debugLog then
			local fmt = "%s setting \"%s\" door \"%s\" X:%.0f Y:%.02f Z:%.02f lnkLock to %s, lnkLocked to %s"
			mwse.log(fmt, prefixed(dbc), doorRef.destination.cell.id, ldRef.id, ldRef.position.x, ldRef.position.y, ldRef.position.z, lockLevel, locked)
			if config.debugMsg then
				tes3.messageBox({ message = string.format(fmt, dbc, doorRef.destination.cell.id, ldRef.id, ldRef.position.x, ldRef.position.y, ldRef.position.z, lockLevel, locked) })
			end
		end
	else
		if debugLog then
			local fmt = "%s no destination door marker < %s maxdistance found"
			mwse.log(fmt, prefixed(dbc), config.linkedDoorsMaxDistance)
		end
	end
	---dbc = '' -- reset debug breadcrumb
end

local function delayedDoorTune()
	if ddtDoorTimer then
		ddtDoorTimer:cancel()
	end
	ddtDoorTimer = nil
	if not ddtDoorRef then
		assert(ddtDoorRef)
		return
	end
	doorTune(ddtDoorRef)
end

local function checkDelayedDoorTune(doorRef)
	local doorDest = doorRef.destination
	if not doorDest then
		return
	end
	if not doorDest.cell then
		return
	end
	if not ddtDoorTimer then
		ddtDoorRef = doorRef
		ddtDoorTimer = timer.start({type = timer.real, duration = 0.9, callback = delayedDoorTune})
	end
end

local LEFT_SHIFT = tes3.scanCode.lShift
local RIGHT_SHIFT = tes3.scanCode.rShift

local function activateToLock(e)
	---mwse.log("activateToLock(e)")
	if not config.doorShiftLock then
		---mwse.log("config.doorShiftLock = %s", config.doorShiftLock)
		return
	end
	if not (e.activator == player) then
		---mwse.log("e.activator = %s, player = %s", e.activator, player)
		return
	end
	local ref = e.target
	local obj = ref.object
	local objType = obj.objectType
	if not (
		(objType == DOOR_T)
	 or (objType == CONT_T)
	) then
		---mwse.log("objType = %s", objType)
		return
	end
	local shiftPressed = inputController:isKeyDown(LEFT_SHIFT)
		or inputController:isKeyDown(RIGHT_SHIFT)
	if not shiftPressed then
		---mwse.log("no SHIFT pressed")
		return
	end
	local locked = tes3.getLocked({reference = ref})
	if locked then -- important! it happens a lot!
		---mwse.log("ref %s locked", ref)
		return false -- skip everything in this case
	end
	---mwse.log("%s: config.doorShiftLock = %s", modPrefix, config.doorShiftLock)
	local lockNode = ref.lockNode
	---mwse.log("%s: inputController:isKeyDown(LEFT_SHIFT), loclNode = %s", modPrefix, lockNode)
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
		tes3.messageBox("%s used to lock %s", key.name, obj.name)
	end
	dbc = '' -- reset debug breadcrumb
	return false -- important!
end

local function activate(e)
	if not (e.activator == player) then
		return
	end
	local ref = e.target
	local obj = ref.object
	if not config.doorLockTune then
		if not config.doorCloseSound then
			return
		end
	end
	local objType = obj.objectType
	if objType == DOOR_T then
		if ref.destination then
			append2dbc('activate')
			checkDelayedDoorTune(ref)
		end
		if config.doorCloseSound then
			local locked = tes3.getLocked({reference = ref})
			if not locked then
				activatedDoorRef = ref
			end
		end
	elseif not (objType == CONT_T) then
		return
	end
	dbc = '' -- reset debug breadcrumb
end

local currTarget

local function onLoad()
	-- for doorTune
	if ddtDoorTimer then
		ddtDoorTimer:cancel() -- better to do it right before loading
	end
-- IMPORTANT! timers are invalid and crashing on reload, not reset to a clean nil!
	ddtDoorRef = nil
	ddtDoorTimer = nil
end

local function loaded()
	player = tes3.player
	activatedDoorRef = nil
	currTarget = nil
	dbc = ''
end

local function objectInvalidated(e)
	if currTarget then
		if currTarget == e.object then -- tes3baseObject, but can be a tes3reference
			--- mwse.log("%s objectInvalidated %s deleted, resetting currTarget", modPrefix, e.object.id)
			currTarget = nil -- safety if some mod is deleting things under the mouse pointer
		end
	end
end

local function checkDoorEvent(doorRef)
	if not config.doorLockTune then
		if not config.doorCloseSound then
			return
		end
	end
	local obj = doorRef.object
	assert(obj)
	---if not obj then	return end
	if not (obj.objectType == DOOR_T) then
		return
	end
	checkDelayedDoorTune(doorRef)
end

local function lockPick(e)
	--[[
	tes3.messageBox("lockPick\n reference=%s\n lockData=%s\n picker=%s\n tool=%s\n toolItemData=%s\n chance=%s\n lockPresent=%s"
	, e.reference, e.lockData, e.picker.reference.id, e.tool.id, e.toolItemData, e.chance, e.lockPresent
	)
	--]]

	--[[ it should work even with other NPCs in theory
	if not (e.picker == tes3.mobilePlayer) then
		return
	end
	--]]

	if config.debugLog then
		append2dbc('lockPick')
		local targetId = e.reference.id
		local toolId = e.tool.id
		local fmt = "%s target = %s tool = %s"
		mwse.log(fmt, prefixed(dbc), targetId, toolId)
		if config.debugMsg then
			tes3.messageBox({ message = string.format(fmt, dbc, targetId, toolId) })
		end
		dbc = '' -- reset debug breadcrumb
	end
	checkDoorEvent(e.reference)
end

local function activationTargetChanged(e)
	local ref = e.current
	if not ref then
		return
	end
	---does not work with setdelete robe it seems
	---if ref.deleted then
	---	tes3.messageBox("activationTargetChanged WARNING id = %s deleted!", ref.id)
	---	return
	---end
	local obj = ref.object
	---assert(obj)
	if not (obj.objectType == DOOR_T) then
		return
	end
	currTarget = ref -- used by attack()
end

local function attack(e)
	local target = e.targetReference
	if target then
		return -- skip if target is real
	end
	--[[
	if not (e.reference == player) then
		return -- only player can use lock bashing
	end
	--]]
	-- no real target, could be bashing mod
	if currTarget then
		checkDoorEvent(currTarget)
	end
end

local LOCKEFFECT = tes3.effect.lock
local OPENEFFECT = tes3.effect.open
local function spellTick(e)
	---assert(e)
	if not config.doorLockTune then
		if not config.doorCloseSound then
			return
		end
	end
	local target = e.target
	if not target then
		return
	end
	if ddtDoorTimer then
		return
	end
	local obj = target.object
	if not obj then
		return
	end
	if not (obj.objectType == DOOR_T) then
		return
	end
	local effectId = e.effectId
	if not effectId then
		return
	end
	if ( effectId == LOCKEFFECT )
	or ( effectId == OPENEFFECT ) then
		append2dbc('spellTick')
		ddtDoorRef = target
		ddtDoorTimer = timer.start({type = timer.real, duration = 1.6, callback = delayedDoorTune})
	end
end

local function logConfig(cfg, options)
	mwse.log(json.encode(cfg, options))
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()

	initVariables()

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		mwse.saveConfig(configName, config, {indent = false})
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

	local controls = preferences:createCategory{label = mcmName}

	---controls:createInfo({text = 'Note: some settings need to restart Morrowind.exe to be effective.'})

	controls:createYesNoButton{
		label = "Loading doors lock synchronization",
		description = "If exterior door is locked/unlocked, so is linked interior door and vice versa. Default: Yes.",
		variable = createConfigVariable("doorLockTune")
	}

	controls:createSlider{
		label = "Linked doors max distance",
		description = "Max distance from door destination marker for another door in that cell to be a linked door candidate. Default: 450).",
		variable = createConfigVariable("linkedDoorsMaxDistance")
		,min = 400, max = 800, step = 1, jump = 5
	}

	controls:createYesNoButton{
		label = "Loading doors close sound enabled",
		description = "Play a slighty delayed close door sound after opening a loading door. Default: Yes.",
		variable = createConfigVariable("doorCloseSound")
	}

	controls:createSlider{
		label = "Close door sound volume (%)",
		description = '(effective only when previous "Loading doors close sound" option is set to Yes',
		variable = createConfigVariable("doorCloseSoundVolumePercent")
		,min = 20, max = 100, step = 1, jump = 10
	}

	controls:createYesNoButton{
		label = "Shift + Activate = Lock",
		description = "Lock a door with Shift + Activate (if you have the key). Default: Yes.",
		variable = createConfigVariable("doorShiftLock")
	}

	--[[ too buggy
	controls:createYesNoButton{
		label = "Fix North Markers",
		description = "Place/fix missing/misoriented North Markers in door linked interiors.",
		variable = createConfigVariable("fixNorthMarkers")
	}
	]]

	controls:createYesNoButton{
		label = "Debug Log",
		description = "Write some debug information to MWSE.log. Default: No.",
		variable = createConfigVariable("debugLog")
	}
	controls:createYesNoButton{
		label = "Debug messages",
		description = "Show some debug information using in game messages. Default: No.",
		variable = createConfigVariable("debugMsg")
	}

	mwse.mcm.register(template)
	logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)

local function initialized()
	event.register('load', onLoad)
	event.register('loaded', loaded)
	event.register('spellTick', spellTick)
	event.register('lockPick', lockPick)

	event.register('activationTargetChanged', activationTargetChanged)
	event.register('objectInvalidated', objectInvalidated) -- useful in case some mod deletes things under cursor
	--- event.register('mouseButtonUp', mouseButtonUp, {filter = 0}) -- filter for left mouse button WARNING some mod can setdelete things under the cursor!
	event.register('attack', attack) -- does not get door reference, but I can still use it instead of mouseButtonUp

	event.register('activate', activateToLock, {priority = 1300}) -- priority must be > animated containers
	event.register('activate', activate, {priority = -1113})
	event.register('cellChanged', cellChanged)
	---if math.floor(tes3.getGlobal('ab01debug')) then
		--event.register('menuExit', menuExit)
	---end
	---mwse.log("%s initialized", modPrefix)
end
event.register('initialized', initialized)
