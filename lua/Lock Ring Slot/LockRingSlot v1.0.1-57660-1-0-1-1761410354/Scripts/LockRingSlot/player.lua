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

---@alias GameObject userdata
local debug = false
local MODE = I.UI.MODE

local playerSettings = storage.playerSection("SettingsPlayer" .. modInfo.name)
local userInterfaceSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "UI")
local prefSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "Prefs")

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
	d.print("Re-equipping rings...")
	local equip = types.Actor.getEquipment(self)
	if newRing then
		equip[oppositeSlot_in] = newRing
	end
	equip[lockedSlot_in] = lockedRing
    types.Actor.setEquipment(self, equip)

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
	elseif not errMsg then
		message("No " .. (lockedSlot and ringSlotNames[lockedSlot] or "Rings") .. " Equipped")
		errMsg = true
	end
end

local timer = 0
local lastSnapshot = {}

local function Update(dt)

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
    if timer >= 1 then
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
		if lring ~= lastSnapshot.LeftRing or rring ~= lastSnapshot.RightRing then
			-- something changed
			d.print("Ring change detected!")
			--Cast 1: Locked ring still equipped - check if it's in correct slot or not
			if Actor.hasEquipped(self, lockedRingData.obj) then
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
				if ringInInventory(lockedRingData.rec) then
					d.print("Found ring... re-equipping...")
					--find the ring that is newly equipped.. 
					if lring ~= lastSnapshot.LeftRing and lring ~= lastSnapshot.RightRing then
						--left ring is new!
						d.print("Left ring is....:" .. tostring(lring))
						reEquip(lring, getOppSlot(slotSelection), lockedRingData.obj, slotSelection)
					elseif rring ~= lastSnapshot.LeftRing and rring ~= lastSnapshot.RightRing then
						--right ring is new!
						d.print("Right ring is....:" .. tostring(rring))
						reEquip(rring, getOppSlot(slotSelection), lockedRingData.obj, slotSelection)
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

return {
	engineHandlers = {
		onUpdate = Update
	}
}
