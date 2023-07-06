--[[

Mod: Convenient Thief Tools
Author: Pharis

--]]

local aux_util = require('openmw_aux.util')
local core = require("openmw.core")
local self = require("openmw.self")
local storage = require("openmw.storage")
local types = require("openmw.types")
local ui = require("openmw.ui")

-- Mod info
local modInfo = require("Scripts.Pharis.ConvenientThiefTools.modinfo")
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- Settings
local generalSettings = storage.globalSection("SettingsPlayer" .. modName)
local userInterfaceSettings = storage.playerSection("SettingsPlayer" .. modName .. "UI")
local controlsSettings = storage.playerSection("SettingsPlayer" .. modName .. "Controls")
local gameplaySettings = storage.globalSection("SettingsPlayer" .. modName .. "Gameplay")

local playerData = {}

local function message(msg)
	if (not userInterfaceSettings:get("showMessages")) then return end
	ui.showMessage(msg)
end

local function reverseList(list)
	local newList = {}
	for i = #list, 1, -1 do
		table.insert(newList, list[i])
	end
	return newList
end

local function equip(slot, object)
    local equipment = types.Actor.equipment(self)
    equipment[slot] = object
    types.Actor.setEquipment(self, equipment)
end

local function indexOf(obj, list)
    for i, o in ipairs(list) do
        if obj == o then
            return i
        end
    end
    return nil
end

-- TODO: Factor in remaining uses in sorting
local function getTools(type)
	local list = types.Actor.inventory(self):getAll(type)
	list, _ = aux_util.mapFilterSort(
		list,
		function (tool)
			return type.record(tool).quality
		end
	)
	if (gameplaySettings:get("qualitySortDirection") == "descending") then return reverseList(list) end
	return list
end

local function getNextTool(list, current)
    local index = current and indexOf(current, list)
	if (index) then
		for i = index, #list do
			if (list[i] ~= current) then
				return true, list[i]
			end
		end
		return list[1] ~= current, list[1]
	end
end

local function onKeyPress(key)
	if (not generalSettings:get("modEnable"))
		or (core.isWorldPaused()) then return end

	local type
	if (key.code == controlsSettings:get("lockpickHotkey")) then
		type = types.Lockpick
	elseif (key.code == controlsSettings:get("probeHotkey")) then
		type = types.Probe
	else
		return
	end

	local carriedRight = types.Actor.equipment(self)[types.Actor.EQUIPMENT_SLOT.CarriedRight]
	if (carriedRight) and (type == carriedRight.type) then -- Tool already equipped
		if (key.withAlt) then -- Cycle to next tool
			local changed, newSelection = getNextTool(getTools(type), carriedRight)
			if (changed) then
				equip(types.Actor.EQUIPMENT_SLOT.CarriedRight, newSelection)
			end
		else -- Unequip and switch back to weapon
			equip(types.Actor.EQUIPMENT_SLOT.CarriedRight, playerData.storedWeapon)
			playerData.storedWeapon = nil
		end
	else -- No tool equipped
		-- Don't save tools or actual saved weapon will get overwritten if you switch between them
		local tools = getTools(type)
		if (#tools > 0) then
			if (not carriedRight) or (types.Weapon.objectIsInstance(carriedRight)) then playerData.storedWeapon = carriedRight end
			equip(types.Actor.EQUIPMENT_SLOT.CarriedRight, tools[1])
			if (gameplaySettings:get("autoWeaponStance")) then types.Actor.setStance(self, types.Actor.STANCE.Weapon) end
		else
			local typeStr = type == types.Probe and "probes" or "lockpicks"
			message(string.format("I'm not carrying any %s.", typeStr))
		end
	end
end

local function activationHandler(data)
	if (not generalSettings:get("modEnable")) then return end

	local type = types.Lockpick
	if (data.probe) then
		type = types.Probe
	end

	local tools = getTools(type)
	if (#tools > 0) then
		local carriedRight = types.Actor.equipment(self)[types.Actor.EQUIPMENT_SLOT.CarriedRight]
		if (not carriedRight) or (types.Weapon.objectIsInstance(carriedRight)) then playerData.storedWeapon = carriedRight end
		equip(types.Actor.EQUIPMENT_SLOT.CarriedRight, tools[1])
		if (gameplaySettings:get("autoWeaponStance")) then types.Actor.setStance(self, types.Actor.STANCE.Weapon) end
	else
		local typeStr = type == types.Probe and "probes" or "lockpicks"
		message(string.format("I'm not carrying any %s.", typeStr))
	end
end

return {
	engineHandlers = {
		onKeyPress = onKeyPress,
	},
	eventHandlers = {
		PharisConvenientThiefToolsActivateLockable = activationHandler
	}
}
