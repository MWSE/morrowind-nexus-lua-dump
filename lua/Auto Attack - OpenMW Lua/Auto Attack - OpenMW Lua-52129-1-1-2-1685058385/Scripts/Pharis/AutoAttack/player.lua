--[[

Mod: Auto Attack
Author: Pharis

--]]

local async = require("openmw.async")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local self = require("openmw.self")
local storage = require("openmw.storage")
local types = require("openmw.types")
local ui = require("openmw.ui")

-- Mod info
local modInfo = require("Scripts.Pharis.AutoAttack.modInfo")
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- Settings
local playerSettings = storage.playerSection("SettingsPlayer" .. modName)
local userInterfaceSettings = storage.playerSection("SettingsPlayer" .. modName .. "UI")
local controlsSettings = storage.playerSection("SettingsPlayer" .. modName .. "Controls")
local gameplaySettings = storage.playerSection("SettingsPlayer" .. modName .. "Gameplay")

local Actor = types.Actor
local Player = types.Player
local Weapon = types.Weapon
local carriedRight = Actor.EQUIPMENT_SLOT.CarriedRight

local autoAttackControl = false
local sheatheOnDisable = false
local spellOnDisable = false
local autoAttackState = 0
local autoAttackSecondsPassed = 0
local autoAttackInterval = 1.0

local weaponWhitelist = require("Scripts.Pharis.AutoAttack.weaponWhitelist")

local weaponTypesMarksman = {
	[Weapon.TYPE.MarksmanBow] = true,
	[Weapon.TYPE.MarksmanCrossbow] = true,
	[Weapon.TYPE.MarksmanThrown] = true,
}

local function message(msg, _)
	if (not userInterfaceSettings:get("showMessages")) then return end

	ui.showMessage(string.format(msg, _))
end

local function isMarksmanWeapon(weapon)
	if (not weapon)
	or (types.Lockpick.objectIsInstance(weapon))
	or (types.Probe.objectIsInstance(weapon)) then return false end -- Accounts for fists, lockpicks, and probes

	return weaponTypesMarksman[Weapon.record(weapon).type]
end

local function toggleAutoAttack()
	if (not playerSettings:get("modEnable"))
		or (core.isWorldPaused()) then return end

	if (autoAttackControl) then
		autoAttackControl = false
		I.Controls.overrideCombatControls(false)
		self.controls.use = 0
		autoAttackSecondsPassed = 0

		if (sheatheOnDisable) or (gameplaySettings:get("sheatheOnDisable")) then -- This is slow but it has to be currently until the API has animation stuff
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
		local equippedWeapon = Actor.equipment(self)[carriedRight]
		local currentStance = Actor.stance(self)

		if (gameplaySettings:get("useWhitelist"))
			and ((not equippedWeapon) or (not weaponWhitelist[equippedWeapon.recordId])) then return end

		if (gameplaySettings:get("marksmanOnlyMode")) and (not isMarksmanWeapon(equippedWeapon)) then return end

		if (gameplaySettings:get("drawOnEnable")) then
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


		if (Actor.stance(self) == Actor.STANCE.Weapon) then
			I.Controls.overrideCombatControls(true) -- Prevents weirdness with stopOnRelease and toggle weapon input action
			autoAttackControl = true
			message("Auto attack enabled.")
		end
	end
end

local function autoAttack(dt)
	if (not playerSettings:get("modEnable"))
		or (core.isWorldPaused())
		or (not autoAttackControl) then return end

	autoAttackSecondsPassed = autoAttackSecondsPassed + dt

	if (input.isKeyPressed(controlsSettings:get("decreaseAttackIntervalHotkey"))) then
		autoAttackInterval = autoAttackInterval - (0.5 * dt)
	elseif (input.isKeyPressed(controlsSettings:get("increaseAttackIntervalHotkey"))) then
		autoAttackInterval = autoAttackInterval + (0.5 * dt)
	end

	autoAttackInterval = math.max(autoAttackInterval, 0.0)

	-- Disable auto attack if the player is no longer holding a weapon, avoids putting away weapon and forgetting it"s on
	-- or auto attack remaining enabled after a weapon breaks
	if (Actor.stance(self) ~= Actor.STANCE.Weapon) then
		toggleAutoAttack()
		return
	end

	if (controlsSettings:get("stopOnRelease")) then
		if (not input.isKeyPressed(controlsSettings:get("autoAttackHotkey"))) and (not input.isActionPressed(input.ACTION.Use)) then
			toggleAutoAttack()
			return
		end
	end

	-- Thanks to uramer and Petr Mikheev for fixing this part for me :)
	if (autoAttackSecondsPassed < autoAttackInterval) then
		self.controls.use = 1 -- continue charging attack (otherwise playercontrols.lua sets it to 0)
		return
	else
		self.controls.use = 0 -- finish attack
		autoAttackSecondsPassed = 0
	end
end

local inputActions = {
	autoAttackHotkey = function ()
		if (controlsSettings:get("attackBindingMode")) then return end

		toggleAutoAttack()
	end,
	attackBinding = function ()
		if (not controlsSettings:get("attackBindingMode")) then return end

		toggleAutoAttack()
	end,
	toggleWeapon = function ()
		if (not autoAttackControl)
			or (controlsSettings:get("stopOnRelease")) then return end

		sheatheOnDisable = true
		toggleAutoAttack()
	end,
	toggleSpell = function ()
		if (not autoAttackControl)
			or (controlsSettings:get("stopOnRelease")) then return end

		sheatheOnDisable = true
		spellOnDisable = true
		toggleAutoAttack()
	end
}

local function onKeyPress(key)
	if (not playerSettings:get("modEnable")) then return end

	if (core.isWorldPaused()) then return end

	if (key.code == controlsSettings:get("autoAttackHotkey")) then
		inputActions.autoAttackHotkey()
	end
end

local function onInputAction(id)
	if (not playerSettings:get("modEnable")) then return end

	if (core.isWorldPaused()) then return end

	if (id == input.ACTION.Use) then
		inputActions.attackBinding()
	elseif (id == input.ACTION.ToggleWeapon) then
		inputActions.toggleWeapon()
	elseif (id == input.ACTION.ToggleSpell) then
		inputActions.toggleSpell()
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
