--[[

Mod: Auto Attack
Author: Pharis

--]]

local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ui = require('openmw.ui')

-- Mod info
local modInfo = require('Scripts.Pharis.AutoAttack.modInfo')
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- Settings
local playerSettings = storage.playerSection('SettingsPlayer' .. modName)
local userInterfaceSettings = storage.playerSection('SettingsPlayer' .. modName .. 'UI')
local controlsSettings = storage.playerSection('SettingsPlayer' .. modName .. 'Controls')
local gameplaySettings = storage.playerSection('SettingsPlayer' .. modName .. 'Gameplay')

-- Other Variables
local Actor = types.Actor
local Player = types.Player
local Weapon = types.Weapon
local carriedRight = Actor.EQUIPMENT_SLOT.CarriedRight

local autoAttackControl = false
local sheatheOnDisable = false
local spellOnDisable = false
local autoAttackState = 0
local timePassed = 0
local autoAttackInterval = 1.0

local weaponWhitelist = require('Scripts.Pharis.AutoAttack.weaponWhitelist')

local weaponTypesMarksman = {
	[Weapon.TYPE.MarksmanBow] = true,
	[Weapon.TYPE.MarksmanCrossbow] = true,
	[Weapon.TYPE.MarksmanThrown] = true,
}

local function debugMessage(msg, _)
	if (not playerSettings:get('showDebug')) then return end

	print("[" .. modName .. "]", string.format(msg, _))
end

local function message(msg, _)
	if (not userInterfaceSettings:get('showMessages')) then return end

	ui.showMessage(string.format(msg, _))
end

local function isMarksmanWeapon(weapon)
	if (not weapon) then return false end -- Accounts for fists

	local weaponType = Weapon.record(weapon).type

	return weaponTypesMarksman[weaponType]
end

local function toggleAutoAttack()
	if (not playerSettings:get('modEnable')) then return end

	if (core.isWorldPaused()) then return end

	if (autoAttackControl) then
		autoAttackControl = false

		I.Controls.overrideCombatControls(false)

		self.controls.use = 0
		timePassed = 0

		if (sheatheOnDisable) or (gameplaySettings:get('sheatheOnDisable')) then -- This is slow but it has to be currently until the API has animation stuff
			async:newUnsavableSimulationTimer(1.5,
				function ()
					if (Actor.stance(self) ~= Actor.STANCE.Weapon) then return end

					if (spellOnDisable) then
						Actor.setStance(self, Actor.STANCE.Spell)

						spellOnDisable = false
					else
						Actor.setStance(self, Actor.STANCE.Nothing)
					end
				end
			)

			sheatheOnDisable = false
		end

		message("Auto attack disabled.")
	else
		local equipment = Actor.equipment(self)
		local equippedWeapon = equipment[carriedRight]
		local currentStance = Actor.stance(self)

		if (gameplaySettings:get('useWhitelist')) then
			if (not equippedWeapon) or (not weaponWhitelist[equippedWeapon.recordId]) then
				debugMessage("Weapon whitelist mode is active but equipped weapon is not on weapon whitelist. Aborting auto attack attempt.")

				return
			end
		end

		if (gameplaySettings:get('marksmanOnlyMode')) and (not isMarksmanWeapon(equippedWeapon)) then
			debugMessage("Marksman only mode is active but equipped weapon is not marksman weapon. Aborting auto attack attempt.")

			return
		end

		if (gameplaySettings:get('drawOnEnable')) then
			if (currentStance == Actor.STANCE.Nothing) then
				Actor.setStance(self, Actor.STANCE.Weapon)

				async:newUnsavableSimulationTimer(0.5, -- This is for when auto attack is triggered in the middle of transition from spell to nothing stance
					function ()
						if (autoAttackControl) then return end -- If already enabled before timer is up no need for the rest of this

						Actor.setStance(self, Actor.STANCE.Weapon)

						I.Controls.overrideCombatControls(true) -- Prevents weirdness with stopOnRelease and toggle weapon input action

						autoAttackControl = true

						message("Auto attack enabled.")
					end
				)
			end
		end


		if (currentStance == Actor.STANCE.Weapon) then

			I.Controls.overrideCombatControls(true) -- Prevents weirdness with stopOnRelease and toggle weapon input action

			autoAttackControl = true

			message("Auto attack enabled.")
		end
	end
end

local function autoAttack(dt)
	if (not playerSettings:get('modEnable')) then return end

	if (core.isWorldPaused()) then return end

	if (not autoAttackControl) then return end

	timePassed = timePassed + dt

	if (input.isKeyPressed(controlsSettings:get('decreaseAttackIntervalHotkey'))) then
		autoAttackInterval = autoAttackInterval - (0.5 * dt)
		debugMessage("Set 'autoAttackInterval' to: %s", autoAttackInterval)
	elseif (input.isKeyPressed(controlsSettings:get('increaseAttackIntervalHotkey'))) then
		autoAttackInterval = autoAttackInterval + (0.5 * dt)
		debugMessage("Set 'autoAttackInterval' to: %s", autoAttackInterval)
	end

	autoAttackInterval = math.max(autoAttackInterval, 0.0)

	-- Disable auto attack if the player is no longer holding a weapon, avoids putting away weapon and forgetting it's on
	-- or auto attack remaining enabled after a weapon breaks
	if (Actor.stance(self) ~= Actor.STANCE.Weapon) then
		toggleAutoAttack()

		return
	end

	if (controlsSettings:get('stopOnRelease')) then
		if (not input.isKeyPressed(controlsSettings:get('autoAttackHotkey'))) and (not input.isActionPressed(input.ACTION.Use)) then
			toggleAutoAttack()

			return
		end
	end

	-- Thanks to uramer and Petr Mikheev for fixing this part for me :)
	if (timePassed < autoAttackInterval) then
		self.controls.use = 1 -- continue charging attack (otherwise playercontrols.lua sets it to 0)

		return
	else
		self.controls.use = 0 -- finish attack

		timePassed = 0
	end
end

-- Functionally identical to how it was previously I just think it looks a little neater I guess
local inputActionHandler = {
	autoAttackHotkey = function ()
		if (controlsSettings:get('attackBindingMode')) then return end

		toggleAutoAttack()
	end,
	attackBinding = function ()
		if (not controlsSettings:get('attackBindingMode')) then return end

		toggleAutoAttack()
	end,
	toggleWeapon = function ()
		if (not autoAttackControl) then return end

		if (controlsSettings:get('stopOnRelease')) then return end

		sheatheOnDisable = true

		toggleAutoAttack()
	end,
	toggleSpell = function ()
		if (not autoAttackControl) then return end

		if (controlsSettings:get('stopOnRelease')) then return end

		sheatheOnDisable = true

		spellOnDisable = true

		toggleAutoAttack()
	end
}

local function onKeyPress(key)
	if (not playerSettings:get('modEnable')) then return end

	if (core.isWorldPaused()) then return end

	if (key.code == controlsSettings:get('autoAttackHotkey')) then
		inputActionHandler.autoAttackHotkey()
	end
end

local function onInputAction(id)
	if (not playerSettings:get('modEnable')) then return end

	if (core.isWorldPaused()) then return end

	if (id == input.ACTION.Use) then
		inputActionHandler.attackBinding()
	elseif (id == input.ACTION.ToggleWeapon) then
		inputActionHandler.toggleWeapon()
	elseif (id == input.ACTION.ToggleSpell) then
		inputActionHandler.toggleSpell()
	end
end

local function onSave()
	return {
		autoAttackInterval = autoAttackInterval
	}
end

local function onLoad(data)
	if (not data) then return end

	autoAttackInterval = data.autoAttackInterval
end

return {
	engineHandlers = {
		onFrame = autoAttack,
		onKeyPress = onKeyPress,
		onInputAction = onInputAction,
		onSave = onSave,
		onLoad = onLoad,
	}
}
