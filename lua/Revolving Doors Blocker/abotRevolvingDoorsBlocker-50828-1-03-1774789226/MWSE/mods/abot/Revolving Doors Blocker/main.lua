--[[
Quick and dirty blocker for doors going nowhere.
Optionally gives advice about pesky non-scripted locked 0 doors.
Shift + activate to mark a special door as openable.
]]

local defaultConfig = {
blocked = {
-- insert doors you want to skip here (lowercase ids)
'bar_railsdoor',
'door_cavern_doors00',
'ex_t_door_stone_large',
'sm_shak_d',
'wthdoor',
},
lockedZeroAdvice = true, -- gives advice about pesky non-scripted locked 0 doors
logLevel = 0,
}

local author = 'abot'
local modName = 'Revolving Doors Blocker'
local modPrefix = author .. '/' .. modName
local configName = author .. modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local skipDoors = {}
for i = 1, #config.blocked do
	local k = config.blocked[i]:lower()
	---mwse.log("skipDoors[%s] = true", k)
	skipDoors[k] = true
end

local tes3_objectType_door = tes3.objectType.door

local doorMessages = {
[1] = "This %s is blocked.",
[2] = "The %s won't budge.",
[3] = "No way to use this.",
[4] = "This %s is going nowhere.",
[5] = "The %s is barred from the inside.",
[6] = "The %s is jammed shut.",
}

local genericMessages = {
[1] = "No way to use this.",
[2] = "It does not seem to work.",
[3] = "It appears to be broken.",
[4] = "Broken.",
[5] = "It does not seem safe to use.",
[6] = "The %s cannot be used.",
}

local locked0Messages = {
[1] = "This %s needs a special key or other means to open it.",
[2] = "It can't be opened without the proper key or special item.",
[3] = "Try as you might, you can't force this %s open. It may need a special key or item.",
[4] = "No way to open this %s without a special key or item.",
[5] = "The lock on the %s defies all your attempts. It needs a special key or item to be opened.",
[6] = "You need a special key or item to open this %s.",
}

local inputController -- set in initialized()
---local LSHIFT = tes3.scanCode.lShift
---local RSHIFT = tes3.scanCode.rShift

---@param s1 string
---@param s2 string
---@param patterns string[]
local function multifind2(s1, s2, patterns)
	return s1:multifind(patterns, 1, true)
	or s2:multifind(patterns, 1, true)
end

local sourceModBlacklist = {'ab01houses','tr_mainland.'}

local lastActivatedId

local function activate(e)
	if not (e.activator == tes3.player) then
		return
	end
	local doorRef = e.target
	local obj = doorRef.object
	if not (obj.objectType == tes3_objectType_door) then
		return
	end

	local logLevel = config.logLevel

	-- skip blacklisted mods
	local sourceMod = doorRef.sourceMod
	if sourceMod
	and sourceMod:lower():multifind(sourceModBlacklist, 1, true) then
		return
	end
	
	local doorCell = doorRef.cell
	local doorRefId = doorRef.id

	if doorCell.isInterior
	and ( not doorCell.id:startswith('Mournhold') ) then
		if logLevel > 1 then
			mwse.log("%s: skipping interior door '%s'", modPrefix, doorRefId)
		end
		return -- skip interior door
	end

	local doorName = obj.name
	if obj.script then
		if logLevel > 0 then
			mwse.log("%s: skipping scripted door '%s'", modPrefix, doorRefId)
		end
		return -- skip scripted door
	end
	local lockNode = doorRef.lockNode
	if lockNode
	and lockNode.locked then
		local key = lockNode.key
		if key
		and e.activator.object.inventory:contains(key.id) then
			if logLevel > 0 then
				mwse.log("%s: skipping locked door '%s' as player has the key ", modPrefix, doorRefId)
			end
			return
		end
		local level = lockNode.level
		if level then
			if level == 0 then
				if logLevel > 0 then
					mwse.log("%s: skipping 0-locked door '%s'", modPrefix, doorRefId)
				end
				if config.lockedZeroAdvice then
					local i = math.random(#locked0Messages)
					local s = (locked0Messages[i]):format(doorName)
 -- advice about pesky 0 locked door with no script and no explanation					
					tes3ui.showNotifyMenu(s)
				end
				return
			end
			if logLevel > 0 then
				mwse.log("%s: skipping locked door '%s'", modPrefix, doorRefId)
			end
			return -- skip locked door
		end
	end

	if obj.persistent then
		if logLevel > 0 then
			mwse.log("%s: skipping persistent door '%s'", modPrefix, doorRefId)
		end
		return -- skip persistent door
	end
	
	local lcDoorId = obj.id:lower()
	---mwse.log("%s: lcDoorId '%s'", modPrefix, lcDoorId)

	if skipDoors[lcDoorId] then
		if logLevel > 0 then
			mwse.log("%s: skipping blacklisted door '%s'", modPrefix, doorRefId)
		end
		return -- skip doors from exclusion list
	end

	-- we know it is not locked here, but...
	if lockNode
	and lockNode.level
	and (lockNode.level == 1) then
		if logLevel > 0 then
			mwse.log("%s: skipping marked as openable door '%s'", modPrefix, doorRefId)
		end
		-- we previously locked/unlocked it
		-- to create a lock node and mark it as openable
		return
	end

	local doorDest = doorRef.destination
	if doorDest then
		return
	end

	if inputController:isShiftDown() then
-- mark door as openable locking 1 and unlocking it

		-- skip current frame activation
		e.block = true
		e.claim = true
		
		tes3.lock({reference = doorRef, level = 1})
		tes3.unlock({reference = doorRef})
		if logLevel > 0 then
			mwse.log("%s: door '%s' marked as openable", modPrefix, doorRefId)
		end
		timer.frame.delayOneFrame(function () e.activator:activate(doorRef) end)
		return
	end

	if doorName then
		local lcDoorName = doorName:lower()
		if multifind2(lcDoorId, lcDoorName, {'gate','slave','bars','star'}) then
			if logLevel > 0 then
				mwse.log("%s: skipping special (gate|slave|bars|star) door '%s'", modPrefix, doorRefId)
			end
			return	-- skip special door
		end
		if not (doorRefId == lastActivatedId) then
			lastActivatedId = doorRefId
			local s
			if lcDoorName:multifind({'boat','ladder','stair'}, 1, true) then
				s = genericMessages[math.random(#genericMessages)]
			else
				s = doorMessages[math.random(#doorMessages)]
			end
			s = s:format(doorName)
			if logLevel > 0 then
				mwse.log("%s: no destination door '%s', skipping rotation\nmessage: %s", modPrefix, doorRefId, s)
			end
			tes3ui.showNotifyMenu(s)
		end
	end
	tes3.playSound({sound = "LockedDoor", reference = doorRef})
	-- skip ugly door rotation
	e.block = true
	e.claim = true
	return
end

event.register('initialized',
	function ()
		inputController = tes3.worldController.inputController
		-- Not Clairvoyant Nerevarine has priority -1111
		event.register('activate', activate, {priority = -1110})
	end, {doOnce = true}
)