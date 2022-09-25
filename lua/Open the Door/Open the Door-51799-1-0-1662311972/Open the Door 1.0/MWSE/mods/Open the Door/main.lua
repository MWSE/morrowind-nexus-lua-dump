-- Ensure we have the features we need.
if (mwse.buildDate == nil or mwse.buildDate < 20220225) then
	mwse.log("[Open the Door] Build date of %s does not meet minimum build date of 20220225. Please update your MWSE installation.", mwse.buildDate)
	return
end

local config = require("Open the Door.config").config
local i18n = require("Open the Door.common").i18n
dofile("Open the Door.mcm")

local messages = {
	trapped = i18n("trapped"),
	locked = i18n("locked"),
}
local activatorDoors = {
	["active_de_bar_door"] = true,
	["active_com_bar_door"] = true,
	["act_black_load03"] = true,
}
local block = {}

---@param door tes3reference
---@return boolean
local function isBlocked(door)
	local success, _ = pcall(function()
		return block[door][door.cell.id][door.startingPosition.x][door.startingPosition.y][door.startingPosition.z]
	end)
	return success
end

--- Adds a door to a table with doors that can't be opened automatically
---@param door tes3reference
---@param remove boolean? If you set this to true, the door will be removed from the block list
local function setBlocked(door, remove)
	-- Don't block if cooldowns aren't enabled
	if not config.useCooldowns then return end

	local cellId = door.cell.id
	local x = door.startingPosition.x
	local y = door.startingPosition.y
	local z = door.startingPosition.z

	if remove and isBlocked(door) then
		block[door][cellId][x][y][z]:cancel()
		block[door][cellId][x][y][z] = nil
		return
	end

	-- This ugly hack is needed since door reference don't have clone count number appended
	-- to their ID, so the table keys aren't unique. Solution: store door's cell and position.
	-- It might appear ugly at first, but much more elegan than implementing hashing function.

	block[door] = block[door] or {}
	block[door][cellId] = block[door][cellId] or {}
	block[door][cellId][x] = block[door][cellId][x] or {}
	block[door][cellId][x][y] = block[door][cellId][x][y] or {}
	block[door][cellId][x][y][z] = timer.start({
		type = timer.simulate,
		duration = config.cooldown,
		callback = function()
			block[door] = nil
		end
	})
end

---@param e referenceDeactivatedEventData
local function clearInvalidatedDoor(e)
	if isBlocked(e.reference) then
		setBlocked(e.reference, true)
	end
end

event.register(tes3.event.referenceDeactivated, clearInvalidatedDoor)

--- This function returns `true` if the `reference` is a teleport door, interior door, or a door such as a bar door.
---@param reference tes3reference
---@return boolean
local function isDoor(reference)
	return (
		reference.object.objectType == tes3.objectType.door or
		activatorDoors[reference.baseObject.id:lower()] or
		false
	)
end

--- Returns true if given `reference` is a door that leads to another cell
---@param reference tes3reference
---@return boolean
local function isTeleportDoor(reference)
	return (
		reference.object.objectType == tes3.objectType.door and
		reference.destination and true or false
	)
end

--- Returns true if given `reference` is a door that doesn't lead to another cell
---@param reference tes3reference
---@return boolean
local function isInteriorDoor(reference)
	return (
		reference.object.objectType == tes3.objectType.door and
		(not reference.destination)
	)
end

---@param reference tes3reference
---@return boolean
local function isActivatorDoor(reference)
	return activatorDoors[reference.object.id:lower()] or false
end

--- This function makes the player activate given reference if it is inside `config.minDistance` range.
---@param door tes3reference
local function maybeActivate(door)
	local distance = door.position:distance(tes3.mobilePlayer.position)

	if distance <= config.minDistance then
		setBlocked(door)
		tes3.player:activate(door)
	end
end

---@param e activationTargetChangedEventData
local function onTargetChanged(e)
	local ref = e.current
	if not ref then return end
	if isBlocked(ref) then return end

	local lockNode = ref.lockNode
	if lockNode then
		if lockNode.trap and config.skipTrapped then
			if config.showMessages then
				tes3.messageBox(table.choice(messages.trapped))
			end
			return
		end
		if lockNode.locked and config.skipLocked then
			if config.showMessages then
				tes3.messageBox(table.choice(messages.locked))
			end
			return
		end
	end

	if isTeleportDoor(ref) then
		if config.loadDoors then
			maybeActivate(ref)
		end
	elseif isInteriorDoor(ref) then
		if config.interiorDoors then
			maybeActivate(ref)
		end
	elseif isActivatorDoor(ref) then
		if config.barDoors then
			maybeActivate(ref)
		end
	end
end

event.register(tes3.event.activationTargetChanged, onTargetChanged)

local function clearBlocked()
	if config.clearOnCellChange then
		for _, blocked in pairs(block) do
			blocked.timer:cancel()
		end
		block = {}
	end
end

event.register(tes3.event.cellChanged, clearBlocked)
