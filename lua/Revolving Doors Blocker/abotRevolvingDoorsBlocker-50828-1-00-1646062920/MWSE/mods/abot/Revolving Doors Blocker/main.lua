--[[
quick and dirty blocker for doors going nowhere /abot
alt + activate to mark a special door as openable
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
logLevel = 1,
}

local author = 'abot'
local modName = 'Revolving Doors Blocker'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
--[[
local mcmName = author .. "'s " .. modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end
]]

local config = mwse.loadConfig(configName, defaultConfig)

local skipDoors = {}
for _, value in pairs(config.blocked) do
	local k = value:lower()
	---mwse.log("skipDoors[%s] = true", k)
	skipDoors[k] = true
end

local DOORTYPE = tes3.objectType.door

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

local inputController -- set in initialized
local LALT = tes3.scanCode.lAlt
local RALT = tes3.scanCode.rAlt

local function isAltDown()
	return inputController:isKeyDown(LALT)
		or inputController:isKeyDown(RALT)
end

local function multifind2(s1, s2, pattern)
	return string.multifind(s1, pattern, 1, true)
	or string.multifind(s2, pattern, 1, true)
end

local lastActivatedId

local function activate(e)
	if not (e.activator == tes3.player) then
		return
	end
	local doorRef = e.target
	local obj = doorRef.object
	if not (obj.objectType == DOORTYPE) then
		return
	end
	local logLevel = config.logLevel
	if obj.script then
		if logLevel > 0 then
			mwse.log("%s: skipping scripted door '%s'", modPrefix, doorRef.id)
		end
		return -- skip scripted door
	end
	local locked = tes3.getLocked({reference = doorRef})
	if locked then
		if logLevel > 0 then
			mwse.log("%s: skipping locked door '%s'", modPrefix, doorRef.id)
		end
		return -- skip locked door
	end
	if obj.persistent then
		if logLevel > 0 then
			mwse.log("%s: skipping persistent door '%s'", modPrefix, doorRef.id)
		end
		return -- skip persistent door
	end
	local doorCell = doorRef.cell
	--[[
	if not doorCell then
		assert(doorCell)
		return
	end
	]]
	--[[mwse.log("%s: door '%s' cell = %s, isInterior = %s, behavesAsExterior = %s", modPrefix, doorRef.id, doorCell, doorCell.isInterior, doorCell.behavesAsExterior)]]

	if doorCell.isInterior then
	---if not doorCell.behavesAsExterior then
		if logLevel > 1 then
			mwse.log("%s: skipping interior door '%s'", modPrefix, doorRef.id)
		end
		return -- skip interior door
	---end
	end
	local doorId = obj.id:lower()
	---mwse.log("%s: doorId '%s'", modPrefix, doorId)

	if skipDoors[doorId] then
		if logLevel > 0 then
			mwse.log("%s: skipping blacklisted door '%s'", modPrefix, doorRef.id)
		end
		return -- skip doors from exclusion list
	end

	-- we know it is not locked here, but...
	local lockNode = doorRef.lockNode
	if lockNode then
		if lockNode.level then
			if lockNode.level == 1 then
				if logLevel > 0 then
					mwse.log("%s: skipping marked as openable door '%s'", modPrefix, doorRef.id)
				end
				return -- we previously locked 1/unlocked it to create a lock node and mark it as openable
			end
		end
	end

	local doorDest = doorRef.destination
	if doorDest then
		return
	end
	local name = obj.name

	if isAltDown() then -- mark door as openable locking 1 and unlocking it
		tes3.lock({reference = doorRef, level = 1})
		tes3.unlock({reference = doorRef})
		if logLevel > 0 then
			mwse.log("%s: door '%s' marked as openable", modPrefix, doorRef.id)
		end
		timer.delayOneFrame(function () e.activator:activate(doorRef) end)
		return false
	end

	if multifind2(doorId, name, {'gate','slave','star'}) then
		if logLevel > 0 then
			mwse.log("%s: skipping special (gate|slave|star) door '%s'", modPrefix, doorRef.id)
		end
		return	-- skip special door
	end

	if name then
		if not (doorRef.id == lastActivatedId) then
			lastActivatedId = doorRef.id
			local s
			if string.multifind(name:lower(), {'boat', 'ladder', 'stair'}, 1, true) then
				s = genericMessages[math.random(#genericMessages)]
			else
				s = doorMessages[math.random(#doorMessages)]
			end
			s = string.format(s, name)
			if logLevel > 0 then
				mwse.log("%s: no destination door '%s', skipping rotation\nmessage: %s", modPrefix, doorRef.id, s)
			end
			tes3.messageBox(s)
		end
	end
	tes3.playSound({ sound = "LockedDoor", reference = doorRef })
	-- skip ugly door rotation
	e.block = true
	e.claim = true
	return false
end

local function initialized()
	inputController = tes3.worldController.inputController
	event.register('activate', activate, {priority = -1110}) -- Not Clairvoyant Nerevarine has priority -1111
end
event.register('initialized', initialized)