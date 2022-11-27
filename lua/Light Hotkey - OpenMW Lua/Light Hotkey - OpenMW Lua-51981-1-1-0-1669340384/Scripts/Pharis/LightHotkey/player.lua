--[[

Mod: Light Hotkey - OpenMW Lua
Author: Pharis

--]]

local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local ui = require('openmw.ui')
local interface = require('openmw.interfaces')
local storage = require('openmw.storage')
local input = require('openmw.input')

local Actor = types.Actor
local Armor = types.Armor
local Light = types.Light

local actorInventory = Actor.inventory(self)
local carriedLeft = Actor.EQUIPMENT_SLOT.CarriedLeft

local lastShield
local preferredLight

local modName = "LightHotkey"
local playerSettings = storage.playerSection('SettingsPlayer' .. modName)
local modEnableConfDesc = "To mod or not to mod."
local logDebugConfDesc = "Press F10 to see logged messages in-game."
local swapLightHotkey = 'c'

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

interface.Settings.registerPage {
	key = modName,
	l10n = modName,
	name = "Light Hotkey",
	description = "By Pharis\n\nEquip light with hotkey; automatically re-equip shield when light is unequipped."
}

interface.Settings.registerGroup {
	key = 'SettingsPlayer' .. modName,
	page = modName,
	l10n = modName,
	name = "Player Settings",
	permanentStorage = false,
	settings = {
		setting('modEnableConf', 'checkbox', {}, "Enable Mod", modEnableConfDesc, true),
		setting('showDebugConf', 'checkbox', {}, "Log Debug Messages", logDebugConfDesc, false),
	}
}

-- Optional debug messages
local function debugMessage(msg)
	-- If debug messages disabled do nothing
	if not playerSettings:get('showDebugConf') then return end
	if msg == 'load' then
		if lastShield then print("Loaded saved shield: " .. lastShield) end
		if preferredLight then print("Loaded preferred light: " .. preferredLight) end
	elseif msg == 'shieldSave' then
		print("Shield saved: " .. lastShield)
	elseif msg == 'equipPreferredLight' then
		print("Preferred light equipped")
	elseif msg == 'noPreferredLight' then
		print("No preferred light found, equipping first light")
	end
end

local function getFirstLight()
	for _, object in ipairs(actorInventory:getAll(Light)) do
		return object
	end
end

local function equip(slot, object)
    local equipment = Actor.equipment(self)
    equipment[slot] = object
    Actor.setEquipment(self, equipment)
end

local function swap(key)
	-- If incorrect key pressed do nothing
	if key.symbol ~= swapLightHotkey then return end
	-- If mod is disabled do nothing
	if not playerSettings:get('modEnableConf') then return end
	-- If game is paused do nothing
	if core.isWorldPaused() then return end

	local equipment = Actor.equipment(self)

	-- If any light equipped
	local equippedLight = equipment[carriedLeft]
	if equippedLight and Light.objectIsInstance(equippedLight) then
		-- Set/clear preferred light if alt is held when hotkey is pressed
		if key.withAlt then
			if preferredLight == equippedLight.recordId then
				preferredLight = nil
				ui.showMessage("Cleared preferred light.")
				return
			end

			preferredLight = equippedLight.recordId
			ui.showMessage("Set preferred light.")
			return
		end

		-- Unequip light
		equip(carriedLeft, nil)

		-- Equip stored shield if any
		if lastShield and actorInventory:countOf(lastShield) >= 1 then
			equip(carriedLeft, lastShield)
		end

		return
	end

	-- If no light Equipped
	local firstLight = getFirstLight()
	if firstLight then
		firstLight = firstLight.recordId
		lastShield = nil

		-- Store currently equipped shield if any
		local equippedShield = equipment[carriedLeft]
		if equippedShield and Armor.objectIsInstance(equippedShield) then
			lastShield = equippedShield.recordId
			debugMessage('shieldSave')
		end

		-- Equip light
		if preferredLight and actorInventory:countOf(preferredLight) >= 1 then
			equip(carriedLeft, preferredLight)
			debugMessage('equipPreferredLight')
		else
			equip(carriedLeft, firstLight)
			debugMessage('noPreferredLight')
		end

		return
	end

	ui.showMessage("I'm not carrying any lights.")
end

return {
	engineHandlers = {
		onInit = function()
			print("Initialized Light Hotkey")
		end,
		onKeyPress = swap,
		onLoad = function(data)
			-- data can potentially be nil, throws error
			if not data then return end
			lastShield = data.lastShield
			preferredLight = data.preferredLight
			debugMessage('load')
		end,
		onSave = function()
			return {
				lastShield = lastShield,
				preferredLight = preferredLight
			}
		end,
	}
}