--[[

Mod: Light Hotkey - OpenMW Lua
Author: Pharis

--]]

local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local ui = require('openmw.ui')
local interfaces = require('openmw.interfaces')
local storage = require('openmw.storage')
local input = require('openmw.input')
local settings = require('Scripts.Pharis.LightHotkey.settings')

local Actor = types.Actor
local Armor = types.Armor
local Light = types.Light

local actorInventory = Actor.inventory(self)
local carriedLeft = Actor.EQUIPMENT_SLOT.CarriedLeft

local lastShield
local preferredLight

local function logger(msg)
	-- If debug messages disabled do nothing
	if not settings.playerSettings:get('showDebugConf') then return end
	print('[', settings.modName, '] ', tostring(msg))
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
	if key.code ~= settings.playerSettings:get('modHotkeyConf') then return end
	-- If mod is disabled do nothing
	if not settings.playerSettings:get('modEnableConf') then return end
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
			logger("Shield saved: " .. lastShield)
		end

		-- Equip light
		if preferredLight and actorInventory:countOf(preferredLight) >= 1 then
			equip(carriedLeft, preferredLight)
			logger("Preferred light equipped")
		else
			equip(carriedLeft, firstLight)
			logger("No preferred light found, equipping first light")
		end

		return
	end

	ui.showMessage("I'm not carrying any lights.")
end

return {
	engineHandlers = {
		onInit = function ()
			print("[", settings.modName, "] Initialized v" .. settings.modVersion)
		end,
		onKeyPress = swap,
		onLoad = function(data)
			-- data can potentially be nil, throws error
			if not data then return end
			lastShield = data.lastShield
			preferredLight = data.preferredLight
			if lastShield then logger("Loaded saved shield: " .. lastShield) end
			if preferredLight then logger("Loaded preferred light: " .. preferredLight) end
		end,
		onSave = function()
			return {
				lastShield = lastShield,
				preferredLight = preferredLight
			}
		end,
	}
}