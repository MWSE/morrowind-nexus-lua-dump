--[[

Mod: Light Hotkey
Author: Pharis

--]]

local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ui = require('openmw.ui')

-- Mod info
local modInfo = require('Scripts.Pharis.LightHotkey.modInfo')
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- Settings
local playerSettings = storage.playerSection('SettingsPlayer' .. modName)
local userInterfaceSettings = storage.playerSection('SettingsPlayer' .. modName .. 'UI')
local controlsSettings = storage.playerSection('SettingsPlayer' .. modName .. 'Controls')
local gameplaySettings = storage.playerSection('SettingsPlayer' .. modName .. 'Gameplay')

-- Other Variables
local Actor = types.Actor
local Armor = types.Armor
local Light = types.Light
local Weapon = types.Weapon

local playerInventory = Actor.inventory(self)
local carriedLeft = Actor.EQUIPMENT_SLOT.CarriedLeft
local carriedRight = Actor.EQUIPMENT_SLOT.CarriedRight

local playerData = {}

-- Had to find these by trial and error, actually in order now but idk which of the last two is which
local weaponTypesTwoHanded = {
	false, -- ShortBladeOneHand
	false, -- LongBladeOneHand
	true, -- LongBladeTwoHand
	false, -- BluntOneHand
	true, -- BluntTwoClose
	true, -- BluntTwoWide
	true, -- SpearTwoWide
	false, -- AxeOneHand
	true, -- AxeTwoHand
	true, -- MarksmanBow
	true, -- MarksmanCrossbow
	false, -- MarksmanThrown
	false, --
	false, --
}

local function debugMessage(msg, _)
	if (not playerSettings:get('showDebug')) then return end

	print("[" .. modName .. "]", string.format(msg, _))
end

local function message(msg, _)
	if (not userInterfaceSettings:get('showMessages')) then return end

	ui.showMessage(string.format(msg, _))
end

local function isTwoHanded(weapon)
	if (not weapon) then return false end -- Accounts for fists

	local weaponType = Weapon.record(weapon).type

	return weaponTypesTwoHanded[weaponType + 1] -- Weapon types start at zero, Lua tables start at 1
end

local function getFirstLight()
	for _, object in ipairs(playerInventory:getAll(Light)) do
		return object
	end
end

local function equip(slot, object)
    local equipment = Actor.equipment(self)

    equipment[slot] = object
    Actor.setEquipment(self, equipment)
end

local function lightSwap(key)
	if (not playerSettings:get('modEnable')) then return end

	if (core.isWorldPaused()) then return end

	if (key.code ~= controlsSettings:get('lightHotkey')) then return end

	local equipment = Actor.equipment(self)
	local lastShield = playerData.lastShield
	local preferredLight = playerData.preferredLight

	-- If any light equipped
	local equippedLight = equipment[carriedLeft]
	if (equippedLight) and (Light.objectIsInstance(equippedLight)) then
		-- Set/clear preferred light if alt is held when hotkey is pressed
		if (key.withAlt) then
			if (preferredLight == equippedLight.recordId) then
				playerData.preferredLight = nil
				message("Cleared preferred light.")

				return
			end

			playerData.preferredLight = equippedLight.recordId
			message("Set preferred light.")

			return
		end

		-- Unequip light
		equip(carriedLeft, nil)

		-- Equip stored shield if any
		if (lastShield) and (playerInventory:countOf(lastShield) >= 1) then
			equip(carriedLeft, lastShield)
		end

		return
	end

	-- If no light Equipped
	local firstLight = getFirstLight()
	if (firstLight) then
		firstLight = firstLight.recordId
		playerData.lastShield = nil

		-- Store currently equipped shield if any
		local equippedShield = equipment[carriedLeft]
		if (equippedShield) and (Armor.objectIsInstance(equippedShield)) then
			playerData.lastShield = equippedShield.recordId
			debugMessage("Shield saved: %s", lastShield)
		end

		-- Equip light
		if (preferredLight) and (playerInventory:countOf(preferredLight) >= 1) then
			equip(carriedLeft, preferredLight)
			debugMessage("Preferred light equipped")
		else
			equip(carriedLeft, firstLight)
			debugMessage("No preferred light found, equipping first light")
		end

		if (gameplaySettings:get('lowerTwoHandedWeapon')) then
			local equippedWeapon = equipment[carriedRight]

			if (isTwoHanded(equippedWeapon)) then
				Actor.setStance(self, Actor.STANCE.Nothing)
			end
		end

		return
	end

	message("I'm not carrying any lights.")
end

local function onSave()
	return playerData
end

local function onLoad(data)
	if (not data) then return end

	playerData = data
end

return {
	engineHandlers = {
		onKeyPress = lightSwap,
		onSave = onSave,
		onLoad = onLoad,
	}
}
