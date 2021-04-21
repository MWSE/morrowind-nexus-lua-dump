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
--]]

-- BEGIN configurable parameters

local defaultConfig = {
doorCloseSound = true, -- set it to false to disable loading doors door close sounds
doorLockTune = true, -- set it to false to disable loading doors lock synchronization
doorCloseSoundVolumePercent = 70, -- door close sound volume, 30 <= doorCloseSoundVolume <= 100
doorShiftLock = true, -- Shift + Activate = lock if you have the key
linkedDoorsMaxDistance = 450, -- linked doors max distance, tricky
}

-- END configurable parameters
local author = 'abot'
local modName = 'Loading Doors'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

-- 2nd parameter advantage: anything not defined in the loaded file inherits the value from defaultConfig
local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local mcm = require(author .. '.' .. modName .. '.mcm')
mcm.config = table.copy(config)

local function modConfigReady()
	mwse.registerModConfig(mcmName, mcm)
	mwse.log(modPrefix .. " modConfigReady")
	logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)

function mcm.onClose()
	config = table.copy(mcm.config)
	mwse.saveConfig(configName, config, {indent = false})
end

-- functions to e.g. avoid heavy/crashy loops on CellChange
-- when player is moving too fast e.g. superjumping

local scenicTravelAvailable  -- set in initialized()

local function initScenicTravelAvailable()
	if tes3.getGlobal('ab01boDest') then
		scenicTravelAvailable = true
	elseif tes3.getGlobal('ab01ssDest') then
		scenicTravelAvailable = true
	elseif tes3.getGlobal('ab01goDest') then
		scenicTravelAvailable = true
	elseif tes3.getGlobal('ab01compMounted') then
		scenicTravelAvailable = true
	else
		scenicTravelAvailable = false
	end
end

local function isGlobalPositive(globalVarId)
	local v = tes3.getGlobal(globalVarId)
	if v then
		--- if v > 0 then -- can't compare with 0 as GetGlobal is returning a not-zero float even for integer types
		if v >= 0.0001 then
			return true
		end
	end
	return false
end

local function isPlayerScenicTraveling()
	if not scenicTravelAvailable then
		return false
	end
	if isGlobalPositive('ab01boDest') then
		return true -- if scenic boat traveling
	end
	if isGlobalPositive('ab01ssDest') then
		return true -- if scenic strider traveling
	end
	if isGlobalPositive('ab01goDest') then
		return true -- if scenic gondola traveling
	end
	if isGlobalPositive('ab01compMounted') then
		return true -- if guar riding
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

local dlog = false ---true
local dmsg = false
--[[
can be set changing ab01debug global variable from in-game console
set ab01debug to 256 --> dmsg = true, dlog = true
set ab01debug to 128 --> dmsg = false, dlog = true
--]]

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

local DOORTYPE = tes3.objectType.door

local player -- set in loaded()

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

local function playDoorCloseSound() -- delayed on cellChanged

	local ref = activatedDoorRef
	activatedDoorRef = nil

	if not ref then
		if dlog then
			local fmt = "playDoorCloseSound activatedDoorRef=%s"
			mwse.log(fmt, ref)
		end
		return
	end

	local obj = ref.object
	if not obj then
		if dlog then
			local fmt = "playDoorCloseSound activatedDoorRef.object=%s"
			mwse.log(fmt, obj)
		end
		return
	end

	local closeSound = getCloseSound(obj)
	if not closeSound then
		if dlog then
			local fmt = "playDoorCloseSound no available open/close sound for door %s"
			mwse.log(fmt, obj.id)
		end
		return
	end

	--[[
	if not player then
		if dlog then
			local fmt = "playDoorCloseSound player=%s"
			mwse.log(fmt, player)
		end
		return
	end
	--]]

	local vol = config.doorCloseSoundVolumePercent / 100
	tes3.playSound({ sound = closeSound, reference = player, volume = vol })

	append2dbc('playDoorCloseSound')

	if dmsg then
		local fmt = "%s tes3.playSound{ sound = \"%s\", volume = \"%s\" }"
		tes3.messageBox({ message = string.format(fmt, dbc, closeSound.id, vol) })
	end
	dbc	= ''

end

local function cellChanged()
	if activatedDoorRef then
		timer.start{ duration = 1.0, iterations = 1, callback = playDoorCloseSound }
	end
end

-- for delayed scheduled doorTune
local ddtDoorRef
local ddtDoorTimer

local checkArenaFight -- flag to check for "welcome to the arena" variable, set in initialized()

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
	if not (doorObj.objectType == DOORTYPE) then
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
	local destCell = doorDest.cell
	if not destCell then
		if dlog then
			local fmt = "doorTune destCell = %s"
			mwse.log(fmt, destCell)
		end
		return
	end
	local destMarker = doorDest.marker -- note: markers are type STAT
	if not destMarker then
		if dlog then
			local fmt = "doorTune destMarker = %s"
			mwse.log(fmt, destMarker)
		end
		return
	end

	local destMarkerPos = destMarker.position
	if not destMarkerPos then
		if dlog then
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
	if isGlobalPositive('DuelActive') then
		return
	end
	if checkArenaFight then
		if isGlobalPositive('Arena_Fight') then
			return
		end
	end


	local maxDist1 = config.linkedDoorsMaxDistance
	local maxDist2 = config.linkedDoorsMaxDistance
	local ldRef
	local dist1
	local dist2
	local linkedDoorDest
	for linkedDoorRef in tes3.iterate(destCell.activators) do
		if not linkedDoorRef.disabled then
			if not linkedDoorRef.deleted then
				local linkedDoorObj = linkedDoorRef.object
				if linkedDoorObj then
					if linkedDoorObj.objectType == DOORTYPE then
						dist2 = linkedDoorRef.position:distance(destMarkerPos)
						if dist2 < maxDist2 then
							linkedDoorDest = linkedDoorRef.destination
							if linkedDoorDest then
								if linkedDoorDest.cell then
									if linkedDoorDest.cell.id then
										if linkedDoorDest.cell.id == doorCell.id then
											if linkedDoorDest.marker then
												if linkedDoorDest.marker.position then
													dist1 = doorRef.position:distance(linkedDoorDest.marker.position)
													if dist1 < maxDist1 then
														ldRef = linkedDoorRef
														break
													end
												end -- if linkedDoorDest.marker.position
											end -- if linkedDoorDest.marker
										end -- if linkedDoorDest.cell.id == doorCell.id
									end -- if linkedDoorDest.cell.id
								end -- if linkedDoorDest.cell
							end -- if linkedDoorDest
						end -- if dist2 < maxDist2
					end -- if linkedDoorObj.objectType == DOORTYPE
				end -- if linkedDoorObj
			end -- not linkedDoorRef.deleted
		end -- not linkedDoorRef.disabled
	end -- for linkedDoorRef

	if ldRef then
		local locked = tes3.getLocked({reference = doorRef})
		local lockLevel = tes3.getLockLevel({reference = doorRef})
		local linkedLocked = tes3.getLocked({reference = ldRef})
		local linkedLockLevel = tes3.getLockLevel({reference = ldRef})
		append2dbc('doorTune')
		if dlog then
			local fmt = "%s door \"%s\" \"%s\" lock=%s locked=%s linking door \"%s\" \"%s\" lnkLock=%s lnkLocked=%s marker distance=%s, %s"
			mwse.log(fmt, prefixed(dbc), doorCell.id, doorRef.id, lockLevel, locked, destCell.id, ldRef.id, linkedLockLevel, linkedLocked, dist1, dist2)
			if dmsg then
				tes3.messageBox({ message = string.format(fmt, dbc, doorCell.id, doorRef.id, lockLevel, locked, destCell.id, ldRef.id, linkedLockLevel, linkedLocked, dist1, dist2) })
			end
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

		if dlog then
			local fmt = "%s setting \"%s\" door \"%s\" X:%.0f Y:%.02f Z:%.02f lnkLock to %s, lnkLocked to %s"
			mwse.log(fmt, prefixed(dbc), doorRef.destination.cell.id, ldRef.id, ldRef.position.x, ldRef.position.y, ldRef.position.z, lockLevel, locked)
			if dmsg then
				tes3.messageBox({ message = string.format(fmt, dbc, doorRef.destination.cell.id, ldRef.id, ldRef.position.x, ldRef.position.y, ldRef.position.z, lockLevel, locked) })
			end
		end
	else
		if dlog then
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
	if not ddtDoorTimer then
		ddtDoorRef = doorRef
		ddtDoorTimer = timer.start{ duration = 0.9, iterations = 1, callback = delayedDoorTune }
	end
end

local LEFT_SHIFT = tes3.scanCode.lShift
local inputController -- set in loaded()

local function activate(e)
	if not (e.activator == player) then
		return
	end
	local doorRef = e.target
	local obj = doorRef.object
	if not (obj.objectType == DOORTYPE) then
		return
	end
	if not config.doorLockTune then
		if not config.doorCloseSound then
			if not config.doorShiftLock then
				return
			end
		end
	end

	local doorDest = doorRef.destination
	if not doorDest then
		return
	end

	append2dbc('activate')

	checkDelayedDoorTune(doorRef)

	local locked = tes3.getLocked({reference = doorRef})
	if not locked then -- important! it happens a lot!
		if config.doorShiftLock then
			---mwse.log("%s: config.doorShiftLock = %s", modPrefix, config.doorShiftLock)
			if inputController:isKeyDown(LEFT_SHIFT) then
				local lockNode = doorRef.lockNode
				---mwse.log("%s: inputController:isKeyDown(LEFT_SHIFT), loclNode = %s", modPrefix, lockNode)
				if lockNode then
					local key = lockNode.key
					if key then
						local keyId = key.id
						---mwse.log("%s: keyId = %s", modPrefix, keyId)
						if mwscript.getItemCount({reference = player, item = keyId}) > 0 then
							---mwse.log("%s: hasKey(%s), locking", modPrefix, keyId)
							tes3.lock({reference = doorRef})
							tes3.playSound({sound = 'Open Lock'})
							---locked = true
							tes3.messageBox("%s used to lock %s", key.name, obj.name)
							return false -- important to skip opening!!!
						end
					end
				end
			end
		end
		if not locked then
			if config.doorCloseSound then
				activatedDoorRef = doorRef
			end
		end
	end
	dbc = '' -- reset debug breadcrumb

end

local currTarget

local function loaded()
	player = tes3.player
	inputController = tes3.worldController.inputController
-- IMPORTANT! it seems timers are invalid and crashing on reload, not reset to a clean nil!
	activatedDoorRef = nil
-- for doorTune
	ddtDoorRef = nil
	ddtDoorTimer = nil
	currTarget = nil
	dbc = ''
end

local function objectInvalidated(e)
	if currTarget then
		if currTarget == e.object then
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
	if not (obj.objectType == DOORTYPE) then
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

	if dlog then
		append2dbc('lockPick')
		local targetId = e.reference.id
		local toolId = e.tool.id
		local fmt = "%s target = %s tool = %s"
		mwse.log(fmt, prefixed(dbc), targetId, toolId)
		if dmsg then
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
	assert(obj)
	if not (obj.objectType == DOORTYPE) then
		return
	end
	currTarget = ref -- used by attack(), mouseButtonUp()
end

local function attack(e)
	local target = e.targetReference
	if target then
		return -- skip if target is real
	end
	if not (e.reference == player) then
		return -- only player can use lock bashing
	end
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
	if not (obj.objectType == DOORTYPE) then
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
		ddtDoorTimer = timer.start{ duration = 1.6, iterations = 1, callback = delayedDoorTune }
	end
end


local function initialized()
	initScenicTravelAvailable()
	if tes3.getGlobal('Arena_Fight') then
		checkArenaFight = true -- flag to check for "welcome to the arena" variable
	else
		checkArenaFight = false
	end
	event.register('spellTick', spellTick)
	event.register('lockPick', lockPick) -- now I can use this event (not yet documented as usual, found it delving in the mwse source)

	event.register('activationTargetChanged', activationTargetChanged)
	event.register('objectInvalidated', objectInvalidated) -- useful in case some mod deletes things under cursor
	--- event.register('mouseButtonUp', mouseButtonUp, {filter = 0}) -- filter for left mouse button WARNING some mod can setdelete things under the cursor!
	event.register('attack', attack) -- does not get door reference, but I can still use it instead of mouseButtonUp

	event.register('activate', activate)
	event.register('cellChanged', cellChanged)
	event.register('loaded', loaded)
	---if tes3.getGlobal('ab01debug') then
		--event.register('menuExit', menuExit)
	---end
	---mwse.log("%s initialized", modPrefix)
end
event.register('initialized', initialized)

---event.register('weaponReadied', weaponReadied) -- does not work with lockpicks

--[[
local LOCKPICK_TYPE = tes3.objectType.lockpick
local function mouseButtonUp()
	if not currTarget then
		return
	end

	---mwse.log("currTarget.id = %s", currTarget.id)
	if not config.doorLockTune then
		if not config.doorCloseSound then
			return
		end
	end

	local obj = currTarget.object
	if not obj then
		return
	end
	if not (obj.objectType == DOORTYPE) then
		return
	end
	if not tes3.mobilePlayer then
		return
	end
	if not tes3.mobilePlayer.weaponDrawn then
		return
	end

	local equippedLockpick = tes3.getEquippedItem({ actor = player, objectType = LOCKPICK_TYPE })
	if not equippedLockpick then
		return
	end
	if dlog then
		append2dbc('mouseButtonUp')
		local fmt = "%s currTarget = %s equippedLockpick = %s"
		mwse.log(fmt, prefixed(dbc), currTarget, equippedLockpick.object.id)
		if dmsg then
			tes3.messageBox({ message = string.format(fmt, dbc, currTarget, equippedLockpick.object.id) })
		end
	end
	checkDelayedDoorTune(currTarget)
end
--]]

--[[
local function menuExit()
	local ab01debug = tes3.getGlobal('ab01debug')
	if ab01debug then
		local i = math.floor(ab01debug / 256)
		local r = ab01debug % 256
		dmsg = (i >= 1)
		i = math.floor(r / 128)
		dlog = dmsg or ( i >= 1 )
	end
end
--]]

--[[
https://www.tutorialspoint.com/lua/lua_functions.htm
Function with Variable Argument

It is possible to create functions with variable arguments in Lua using '...' as its parameter.
We can get a grasp of this by seeing an example in which the function will return the average and it can take variable arguments.
Live Demo

function average(...)
   result = 0
   local arg = {...}
   for i,v in ipairs(arg) do
	  result = result + v
   end
   return result/#arg
end

print("The average is",average(10,5,3,4,5,6))

When we run the above code, we will get the following output.

The average is	5.5
--]]

--[[
local function weaponReadied(e)
	local ref = e.reference
	assert(ref)
	local weaponStack = e.weaponStack
	assert(weaponStack)
	tes3.messageBox("weaponReadied id = %s, %s", ref.id, weaponStack.object.id)
end
--]]
