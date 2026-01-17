--[[

Mod: LockRingSlot
Author:Nitro

--]]

local self = require("openmw.self")
local storage = require("openmw.storage")
local types = require("openmw.types")
local ui = require("openmw.ui")
local I = require('openmw.interfaces')
local modInfo = require("Scripts.LockRingSlot.modInfo")
local async = require('openmw.async')

---@alias GameObject userdata
local MODE = I.UI.MODE

local playerSettings = storage.playerSection("SettingsPlayer" .. modInfo.name)
local userInterfaceSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "UI")
local prefSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "Prefs")
local debug = playerSettings:get("debugMode")

local Actor = types.Actor
local Clothing = types.Clothing
local RIGHT_RING = Actor.EQUIPMENT_SLOT.RightRing
local LEFT_RING = Actor.EQUIPMENT_SLOT.LeftRing
local lockedSlot = nil -- one of Actor.EQUIPMENT_SLOT.LeftRing / RightRing, or nil
local lockedRingData = nil -- recordId of the locked ring (so we can re-equip)
local doneFlag = false
local errMsg = false
local prevSelection = nil
local oppositeRingData = nil
local ringSlotNames = {
	[LEFT_RING] = "Left Ring",
	[RIGHT_RING] = "Right Ring",
}

-- Display a message if UI messages are enabled
---@param msg string
local function message(msg)
	if (userInterfaceSettings:get("showMessages")) then ui.showMessage(msg) end
end

local d = {}
function d.print(msg)
	if debug then
		print("[LockRingSlot DEBUG]: " .. tostring(msg))
	end
end
-- Returns the equipment slot based on settings selection
---@param selection string
---@return number
local function getSelectedSlot(selection)
	local output
	if selection == "Left" then
		output = LEFT_RING
	else
		output = RIGHT_RING
	end
	return output
end

local function getOppSlot(slot)
    if slot == LEFT_RING then
        return RIGHT_RING
    else
        return LEFT_RING
    end
end

-- lock a slot ("Left" or "Right")
local function lockRing(slot)
	if not slot then return message("No slot selected to lock.") end
    local eq = types.Actor.equipment(self)
    local object = eq and eq[slot]
	local ringName = object and Clothing.record(object).name
	if not ringName then
		--return nil if there are no rings. 
		return
	end
	return {['obj'] = object, ['rec']=object.recordId}
end

-- unlock
local function unlockRing()
    lockedSlot = nil
    lockedRingData = nil
	doneFlag = false
	oppositeRingData = nil
    --ui.showMessage("Unlocked ring slots")
end

---@param leftring GameObject
---@param rightring GameObject
local function swap(leftring, rightring)
	d.print("Swap Function called")
	local equip = types.Actor.getEquipment(self)
	equip[RIGHT_RING] = leftring
	equip[LEFT_RING] = rightring
	types.Actor.setEquipment(self, equip)
end

---@param lockedRingRecordID string
---@return boolean
local function ringInInventory(lockedRingRecordID)
	local inv = Actor.inventory(self)
	return lockedRingRecordID and inv:find(lockedRingRecordID)
end

---@param newRing GameObject
---@param lockedRing GameObject
---@param lockedSlot_in number
---@param oppositeSlot_in number
local function reEquip(newRing, oppositeSlot_in, lockedRing, lockedSlot_in)
	if not oppositeSlot_in or not lockedSlot_in then return d.print("missing new or locked slot numbers") end
	d.print("Re-equipping rings...\n" .. tostring(lockedRing and Clothing.record(lockedRing).name) .. " to slot " .. tostring(lockedSlot_in).."\n" ..
	tostring(newRing and Clothing.record(newRing).name) .. " to slot " .. tostring(oppositeSlot_in))
	local equip = types.Actor.getEquipment(self)
	if newRing then
		equip[oppositeSlot_in] = newRing
	end
	equip[lockedSlot_in] = lockedRing
    types.Actor.setEquipment(self, equip)
	message("Re-equipped locked ring:\n" .. Clothing.record(lockedRing).name)
	--refresh inventory
	if I.UI.getMode() == I.UI.MODE.Interface and I.UI.isWindowVisible('Inventory') then
		local windows={}
		for i, window in pairs(I.UI.WINDOW) do
			if window and I.UI.isWindowVisible(window)then
				table.insert(windows,window)
			end
		end
		I.UI.setMode(MODE.Interface, {windows = {}})
		I.UI.setMode(I.UI.MODE.Interface, {windows = windows})
	end
end

local function attemptLock(slotSelection)
	local result = lockRing(slotSelection)
	prevSelection = slotSelection
	if result then
		lockedRingData = result
		doneFlag = true
		errMsg = false
		message("Locking " .. ringSlotNames[slotSelection] .. ":\n" .. Clothing.record(lockedRingData.obj).name)
	elseif not errMsg then
		message("No " .. (lockedSlot and ringSlotNames[lockedSlot] or "Ring") .. " Equipped")
		errMsg = true -- flag to prevent log spamming
	end
end

local timer = 0
local lastSnapshot = {}
local charGenFlag = false

local function Update(dt)
	if not types.Player.isCharGenFinished(self) then
		if dt > 0 and not charGenFlag then d.print("Character generation not finished, skipping update") charGenFlag = true end
		return
	else
		if charGenFlag then d.print("Character generation finished, resuming updates") charGenFlag = false end
	end
	if not playerSettings:get("modEnable") then return end
	-- If lock is disabled, unlock ring slot and exit
	if not prefSettings:get("toggleLock") then
		unlockRing()
		return
	end

	local slotSelection = getSelectedSlot(prefSettings:get("slotSelect"))
	-- if first time running, just set the initial value
    if not prevSelection then
        prevSelection = slotSelection
    end

	-- if selection has changed, attempt to lock new slot
	if slotSelection ~= prevSelection or not doneFlag then
		attemptLock(slotSelection)
	end

	timer = timer + dt
    if timer >= 0.2 or dt == 0 then
		-- get current rings
		local lring = Actor.getEquipment(self, LEFT_RING)
		local rring = Actor.getEquipment(self, RIGHT_RING)

		-- first-time snapshot
		if not next(lastSnapshot) then
			lastSnapshot.LeftRing = lring
			lastSnapshot.RightRing = rring
			return
		end
		-- compare
		local leftChanged  = lring ~= lastSnapshot.LeftRing
		local rightChanged = rring ~= lastSnapshot.RightRing

		if leftChanged or rightChanged then
			-- if not lockedRingData then
			-- 	d.print("No locked ring data - skipping")
			-- 	return
			-- end

			-- something changed
			d.print("Ring change detected!")
			if leftChanged and rightChanged then d.print("simultaneous change!!!") end

			--Cast 1: Locked ring still equipped - check if it's in correct slot or not
			if lockedRingData and lockedRingData.obj and Actor.hasEquipped(self, lockedRingData.obj) then
				if lring == lockedRingData.obj and slotSelection == LEFT_RING then
					d.print("ring still left locked slot -- do nothing")
				elseif rring == lockedRingData.obj and slotSelection == RIGHT_RING then
					d.print("ring still right locked slot -- do nothing")
				else
					local temp = Actor.getSelectedEnchantedItem(self)
					swap(lring,rring) --swap ring slots, if it's still on the player and not in either correct slot.
					if temp then
						Actor.setSelectedEnchantedItem(self, temp) --Hack to re-Equip the last enchanted item spell... since swapping clears.. 
					end
					d.print("*****SWAP******")
 
				end
			else
				--Cast 2: Ring is not equipped anymore, check inventory, re-equip if found
				d.print("Locked ring not equipped, attempting to find in inventory...")
				if lockedRingData and ringInInventory(lockedRingData.rec) then
					d.print("Found ring... re-equipping...")
					--find the ring that is newly equipped.. 
					d.print("Left ring is:" .. tostring(lring))
					d.print("Right ring is:" .. tostring(rring))
					d.print("Left snapshot:" .. tostring(lastSnapshot.LeftRing))
					d.print("Right snapshot:" .. tostring(lastSnapshot.RightRing))
					if rring == nil and lastSnapshot.RightRing == nil then
						if leftChanged then
							--left ring is new!
							d.print("Left ring ~= Lsnap")
							reEquip(lring, getOppSlot(slotSelection), lockedRingData.obj, slotSelection)
						end
					elseif lring == nil and lastSnapshot.LeftRing == nil then
						if rightChanged then
							--right ring is new!
							d.print("Right ring ~= Rsnap")
							reEquip(rring, getOppSlot(slotSelection), lockedRingData.obj, slotSelection)
						end
					end
					if lring ~= lastSnapshot.LeftRing and lring ~= lastSnapshot.RightRing then
						--left ring is new!
						d.print("Left Ring new re-Equipping")
						local temp = Actor.getSelectedEnchantedItem(self)
						reEquip(lring, getOppSlot(slotSelection), lockedRingData.obj, slotSelection)
						if temp then
							Actor.setSelectedEnchantedItem(self, temp) --Hack to re-Equip the last enchanted item spell... since swapping clears..
							d.print("setting Lring Enchant Spell")
						end
					elseif rring ~= lastSnapshot.LeftRing and rring ~= lastSnapshot.RightRing then
						--right ring is new!
						d.print("Right Ring new, re-Equipping")
						local temp = Actor.getSelectedEnchantedItem(self)
						reEquip(rring, getOppSlot(slotSelection), lockedRingData.obj, slotSelection)
						if temp then
							Actor.setSelectedEnchantedItem(self, temp) --Hack to re-Equip the last enchanted item spell... since swapping clears..
							d.print("setting Rring Enchant Spell")
						end
					else
						d.print("Left or Right not new")
					end
				else
					message("Locked ring missing from inventory!")
				end
			end

		end
		-- update snapshot
		lastSnapshot.LeftRing = lring
		lastSnapshot.RightRing = rring
		timer = 0
    end

end

playerSettings:subscribe(async:callback(function(section, key)
    if key == "debugMode" then
        debug = playerSettings:get(key)
    end
end))

return {
	engineHandlers = {
		onUpdate = Update
	},
	eventHandlers = {
		E_LockRing = lockRing,
		E_UnlockRing = unlockRing,
		E_AttemptLock = attemptLock,
		E_GetSelectedSlot = getSelectedSlot,
	}
}
