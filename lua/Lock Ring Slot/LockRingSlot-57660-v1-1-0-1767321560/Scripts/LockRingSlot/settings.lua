--[[

Mod: LockRingSlot
Author: Nitro

--]]

local async = require("openmw.async")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local ui = require("openmw.ui")
local types = require("openmw.types")
local self = require("openmw.self")
local debug = require('openmw.debug')
local storage = require("openmw.storage")
local modInfo = require("Scripts.LockRingSlot.modInfo")

local toggle = true
local toggle2 = true

-- Settings Descriptions
local pageDescription = "By Nitro\nv" .. modInfo.version .. "\n\nLet's you lock an equipment ring slot" 
local modEnableDescription = "This enables the mod or disables it."
local showMessagesDescription = "Enables UI messages to be shown for any cases which require it. (Currently none)"
local RingSlotSelection = "Pick Either Left or Right ring slot to lock."

-- params to display currently equipped rings
local Actor = types.Actor
local RIGHT_RING = Actor.EQUIPMENT_SLOT.RightRing
local LEFT_RING = Actor.EQUIPMENT_SLOT.LeftRing
local Clothing = types.Clothing
local rings = Clothing.TYPE.Ring


-- Function to return a string of currently equipped rings
local function myRings()
	local rring = Actor.getEquipment(self, RIGHT_RING)
	local rringName = rring and Clothing.record(rring).name
	local lring = Actor.getEquipment(self, LEFT_RING)
	local lringName = lring and Clothing.record(lring).name
	if rring and lring then
		return "Right: " .. rringName .. "\nLeft: " .. lringName
	elseif rring then
		return "Right: " .. rringName .. "\nLeft: None "
	elseif lring then
		return "Left: " .. lringName .. "\nRight: None "
	else
		return "None Equipped"
	end
end

local function getSelectedSlot(selection)
	local output
	if selection == "Left" then
		output = LEFT_RING
	else
		output = RIGHT_RING
	end
	return output
end

local function setting(key, renderer, argument, name, description, default)
	return {
		key = key,
		renderer = renderer,
		argument = argument,
		name = name,
		description = description,
		default = default,
	}
end

I.Settings.registerPage {
	key = modInfo.name,
	l10n = modInfo.name,
	name = "LockRingSlot",
	description = pageDescription
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. modInfo.name,
	page = modInfo.name,
	order = 0,
	l10n = modInfo.name,
	name = "General",
	permanentStorage = false,
	settings = {
		setting("modEnable", "checkbox", {}, "Enable Mod", modEnableDescription, true),
		setting("debugMode", "checkbox", {}, "Enable debug", "Enable debug prints", false),
	}
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. modInfo.name .. "UI",
	page = modInfo.name,
	order = 1,
	l10n = modInfo.name,
	name = "UI",
	permanentStorage = false,
	settings = {
		setting("showMessages", "checkbox", {}, "Show Messages", showMessagesDescription, true),
	}
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. modInfo.name .. "Prefs",
	page = modInfo.name,
	order = 2,
	l10n = modInfo.name,
	name = "Preferences",
	permanentStorage = false,
	settings = {
		setting("slotSelect", "select", {l10n = modInfo.name, items = {"Left", "Right"}}, "Slot Selection", RingSlotSelection, "Left"),
		setting("ringSlots", "checkbox", {}, "Current Equipped Rings", "Toggle to show rings  ------------------->", false),
		setting("toggleLock", "checkbox", {}, "Lock/Unlock Slot", "Toggles the selected ring slot to be locked or unlocked.", false),
	}
}

print("[" .. modInfo.name .. "] Initialized v" .. modInfo.version)

local userInterfaceSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "UI")

local function message(msg)
	if (userInterfaceSettings:get("showMessages")) then ui.showMessage(msg) end
end
userInterfaceSettings:get("showMessages")

local prefSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "Prefs")

--groupOptions.settings = {setting("ringSlots", "textLine", {disabled = true}, "Current Equipped Rings", myRings(), "")}

prefSettings:subscribe(async:callback(function(section, key)
    if key then
        if key == "slotSelect" then
			if prefSettings:get("toggleLock") then
				local slot = prefSettings:get("slotSelect")
				print(slot)
				local slotID = getSelectedSlot(slot)
				self:sendEvent("E_UnlockRing")
				self:sendEvent("E_AttemptLock",slotID)
			end
        end
    end
end))

return {
	engineHandlers = {
		onInit = function(data)
			print("[" .. modInfo.name .. "] onInit called")
			toggle2 = not prefSettings:get("ringSlots")
		end,
		onLoad = function(savedData, initData)
			print("[" .. modInfo.name .. "] onLoad called")
			 -- Force the toggle2 to be opposite of setting to not trigger on load
			toggle2 = not prefSettings:get("ringSlots")
		end,
		onUpdate = function(dt)
			if toggle == prefSettings:get("toggleLock") then
				-- -- message to display based on logic of rings equipped and their names
				-- local selectSlot = prefSettings:get("slotSelect")
				-- local msg = (selectSlot == "Left" and
				-- (Actor.getEquipment(self, LEFT_RING) and Clothing.record(Actor.getEquipment(self, LEFT_RING)).name) or
				-- (Actor.getEquipment(self, RIGHT_RING) and Clothing.record(Actor.getEquipment(self, RIGHT_RING)).name) or "None")

				-- if prefSettings:get("toggleLock") then
				-- 	message("Locking Ring slot " .. selectSlot.. ":\n" .. msg)
				-- else
				-- 	message("Unlocking Ring slot " .. selectSlot .. ":\n" .. msg)
				-- end
				-- toggle = not toggle
			end
			if toggle2 == prefSettings:get("ringSlots") then
				message(myRings())
				print(myRings())
				toggle2 = not toggle2
			end
		end,
	}
}
