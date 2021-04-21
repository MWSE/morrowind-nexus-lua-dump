local ButtonTime
local NameTime
local Weapon
local WeaponData
local AmmoWeapon
local AmmoTime
local AmmoTarget
local eRef

local poisonFile
local colorFile
local config
local featureFile
local menuFile
local damageFile
local restoreFile
local resistFile
local labelFile

local H = {}

function H.AmmoTargetZero()
	AmmoTarget = 0
end

local function Button(e)
	if (ButtonTime == nil) or (ButtonTime == 0) then
		return
	end

	--Magic Effect 14 is Open ([Fire Damage] = 14 in Github, but they start at 0, not 1).
	--buttons: 0 = Potions, 1 = Poisions
	if (ButtonTime == 1) and (e.button == 0) then
		local MGEF = tes3.dataHandler.nonDynamicData.magicEffects
		if (MGEF[14].isHarmful == false) then
			ButtonTime = 0
			return
		end
		for i=1, #MGEF do
			MGEF[i].isHarmful = not MGEF[i].isHarmful
		end
		ButtonTime = 0
	end

	if (ButtonTime == 1) and (e.button == 1) then
		local MGEF = tes3.dataHandler.nonDynamicData.magicEffects
		if (MGEF[14].isHarmful == true) then
			ButtonTime = 0
			return
		end
		for i=1, #MGEF do
			MGEF[i].isHarmful = not MGEF[i].isHarmful
		end
		ButtonTime = 0
	end

	--buttons: 0 = yes, 1 = no
	if (ButtonTime == 2) and (e.button == 0) then
		NameTime = 1
		if (tes3.player.data.OEA8 == nil) then
			tes3.player.data.OEA8 = {}
		end
		tes3.player.data.OEA8[4] = 20
		menuFile.CreateMenu()
		tes3.messageBox("Write in the name of the potion you want to use. This is not case-sensitive.")
	end
	ButtonTime = 0
	return
end

local function AlchemyEnter(e)
	if (config.Messages == true) then
		tes3.messageBox{
			message = "What are you brewing?",
			buttons = { "Potions", "Poisons" },
			callback = Button
		}
		ButtonTime = 1
	else
		local MGEF = tes3.dataHandler.nonDynamicData.magicEffects
		if (MGEF[14].isHarmful == false) then
			ButtonTime = 0
			return
		end
		for i=1, #MGEF do
			MGEF[i].isHarmful = not MGEF[i].isHarmful
		end
		ButtonTime = 0
	end
end

local function OnEquip(e)
	local Length

	if (tes3.player.data.OEA8 == nil) then
		tes3.player.data.OEA8 = {}
	end

	if (e.reference ~= tes3.player) and (e.reference ~= tes3.mobilePlayer) then
		return
	end

	if (tes3.getGlobal("CharGenState") ~= -1) then
		return
	end

	if (e.item.objectType ~= tes3.objectType.weapon) and (e.item.objectType ~= tes3.objectType.ammunition) then
		return
	end

	if (tes3.getEquippedItem({ actor = tes3.mobilePlayer, objectType = tes3.objectType.weapon, type = 9 }) ~= nil) then
		if (e.item.objectType == tes3.objectType.weapon) then
			Weapon = nil
			WeaponData = nil
			colorFile.ReplaceColor(Weapon, AmmoWeapon)
			return
		end
	end
	if (tes3.getEquippedItem({ actor = tes3.mobilePlayer, objectType = tes3.objectType.weapon, type = 10 }) ~= nil) then
		if (e.item.objectType == tes3.objectType.weapon) then
			Weapon = nil
			WeaponData = nil
			colorFile.ReplaceColor(Weapon, AmmoWeapon)
			return
		end
	end

	if (string.sub(e.item.name, 1, 6) == "Bound ") then
		return
	end

	if (e.item.objectType == tes3.objectType.weapon) then
		AmmoTime = 0
		Weapon = e.item
		WeaponData = e.itemData
		Length = string.len(Weapon.name)
		colorFile.ReplaceColor(Weapon, AmmoWeapon)
		if (string.sub(Weapon.name, Length - 10, Length) == " (Poisoned)") then
			return
		end
	elseif (e.item.objectType == tes3.objectType.ammunition) then
		AmmoTime = 1
		AmmoWeapon = e.item
		Length = string.len(AmmoWeapon.name)
		colorFile.ReplaceColor(Weapon, AmmoWeapon)
		if (string.sub(AmmoWeapon.name, Length - 10, Length) == " (Poisoned)") then
			return
		end
	end

	if (config.Menu == false) and (tes3.menuMode() == false) then
		return
	end

	if (config.Combat == false) and (tes3.mobilePlayer.inCombat == true) then
		if (tes3.menuMode() == true) then
			tes3.messageBox("You cannot poison a weapon during combat.")
		end
		return
	end

	if (config.Messages == true) then
		tes3.messageBox{
			message = "Do you want to poison this weapon?",
			buttons = { "Yes", "No" },
			callback = Button
		}
		ButtonTime = 2
	end
end

local function OnUnequip(e)
	if (tes3.player.data.OEA8 == nil) then
		tes3.player.data.OEA8 = {}
	end

	if (e.reference ~= tes3.player) and (e.reference ~= tes3.mobilePlayer) then
		return
	end

	if (tes3.getGlobal("CharGenState") ~= -1) then
		return
	end

	if (e.item.objectType ~= tes3.objectType.weapon) and (e.item.objectType ~= tes3.objectType.ammunition) then
		return
	end

	if (string.sub(e.item.name, 1, 6) == "Bound ") then
		return
	end

	if (e.item.objectType == tes3.objectType.weapon) then
		Weapon = nil
		WeaponData = nil
	elseif (e.item.objectType == tes3.objectType.ammunition) then
		AmmoWeapon = nil
		AmmoTime = 0
	end
end

local function MenuExit(e)
	local MGEF = tes3.dataHandler.nonDynamicData.magicEffects
	if (MGEF[14].isHarmful == true) then
		for i=1, #MGEF do
			MGEF[i].isHarmful = not MGEF[i].isHarmful
		end
	end

	if (NameTime == nil) or (NameTime == 0) then
		return
	end

	if (tes3.player.data.OEA8 == nil) then
		tes3.player.data.OEA8 = {}
	end
	tes3.player.data.OEA8[4] = -1

	local potionName = tes3.player.data.OEA8[69]
	NameTime = 0

	if (AmmoTime ~= nil) and (AmmoTime == 1) then
		poisonFile.AmmoPoisonApply(potionName, AmmoWeapon)
		AmmoTime = 0
		return
	end
	poisonFile.PoisonApply(potionName, Weapon, WeaponData)
end

local function ProjHit(e)
	local tempAmmoWeapon
	local tempWeapon
	local tempWeaponData

	if (e.firingReference ~= tes3.player) and (e.firingReference ~= tes3.mobilePlayer) then
		return
	end

	if (tes3.player.data.OEA8[e.mobile.reference.object.id] == nil) then
		return
	end
	if (tes3.player.data.OEA8[e.mobile.reference.object.id].FireCounter == nil) then
		tes3.player.data.OEA8[e.mobile.reference.object.id].FireCounter = 0
	end
	tes3.player.data.OEA8[e.mobile.reference.object.id].FireCounter = tes3.player.data.OEA8[e.mobile.reference.object.id].FireCounter + 1

	if (AmmoTarget ~= nil) and (AmmoTarget == 2) then
		AmmoTarget = 0
		return
	end

	tempAmmoWeapon = AmmoWeapon
	tempWeapon = Weapon
	tempWeaponData = WeaponData

	if (e.mobile.reference.object.objectType == tes3.objectType.ammunition) then
		if (AmmoWeapon == nil) or (AmmoWeapon.id ~= e.mobile.reference.object.id) then
			tempAmmoWeapon = e.mobile.reference.object
			tempWeapon = nil
			tempWeaponData = nil
		end
	elseif (e.mobile.reference.object.objectType == tes3.objectType.weapon) then
		if (Weapon == nil) or (Weapon.id ~= e.mobile.reference.object.id) then
			tempAmmoWeapon = nil
			tempWeapon = e.mobile.reference.object
			tempWeaponData = nil
		end
	end

	AmmoTarget = 1
	damageFile.AmmoDamage(tempWeapon, tempWeaponData, tempAmmoWeapon, AmmoTarget)
end

local function ProjObject(e)
	local tempAmmoWeapon
	local tempWeapon
	local tempWeaponData

	if (e.firingReference ~= tes3.player) and (e.firingReference ~= tes3.mobilePlayer) then
		return
	end

	if (tes3.player.data.OEA8[e.mobile.reference.object.id] == nil) then
		return
	end
	if (tes3.player.data.OEA8[e.mobile.reference.object.id].FireCounter == nil) then
		tes3.player.data.OEA8[e.mobile.reference.object.id].FireCounter = 0
	end
	tes3.player.data.OEA8[e.mobile.reference.object.id].FireCounter = tes3.player.data.OEA8[e.mobile.reference.object.id].FireCounter + 1

	tempAmmoWeapon = AmmoWeapon
	tempWeapon = Weapon
	tempWeaponData = WeaponData

	if (e.mobile.reference.object.objectType == tes3.objectType.ammunition) then
		if (AmmoWeapon == nil) or (AmmoWeapon.id ~= e.mobile.reference.object.id) then
			tempAmmoWeapon = e.mobile.reference.object
			tempWeapon = nil
			tempWeaponData = nil
		end
	elseif (e.mobile.reference.object.objectType == tes3.objectType.weapon) then
		if (Weapon == nil) or (Weapon.id ~= e.mobile.reference.object.id) then
			tempAmmoWeapon = nil
			tempWeapon = e.mobile.reference.object
			tempWeaponData = nil
		end
	end

	AmmoTarget = 1
	damageFile.AmmoDamage(tempWeapon, tempWeaponData, tempAmmoWeapon, AmmoTarget)
end

local function ProjTerrain(e)
	local tempAmmoWeapon
	local tempWeapon
	local tempWeaponData

	if (e.firingReference ~= tes3.player) and (e.firingReference ~= tes3.mobilePlayer) then
		return
	end

	if (tes3.player.data.OEA8[e.mobile.reference.object.id] == nil) then
		return
	end
	if (tes3.player.data.OEA8[e.mobile.reference.object.id].FireCounter == nil) then
		tes3.player.data.OEA8[e.mobile.reference.object.id].FireCounter = 0
	end
	tes3.player.data.OEA8[e.mobile.reference.object.id].FireCounter = tes3.player.data.OEA8[e.mobile.reference.object.id].FireCounter + 1

	tempAmmoWeapon = AmmoWeapon
	tempWeapon = Weapon
	tempWeaponData = WeaponData

	if (e.mobile.reference.object.objectType == tes3.objectType.ammunition) then
		if (AmmoWeapon == nil) or (AmmoWeapon.id ~= e.mobile.reference.object.id) then
			tempAmmoWeapon = e.mobile.reference.object
			tempWeapon = nil
			tempWeaponData = nil
		end
	elseif (e.mobile.reference.object.objectType == tes3.objectType.weapon) then
		if (Weapon == nil) or (Weapon.id ~= e.mobile.reference.object.id) then
			tempAmmoWeapon = nil
			tempWeapon = e.mobile.reference.object
			tempWeaponData = nil
		end
	end

	AmmoTarget = 1
	damageFile.AmmoDamage(tempWeapon, tempWeaponData, tempAmmoWeapon, AmmoTarget)
end

local function Poisoned(e)
	local tempAmmoWeapon
	local tempWeapon
	local tempWeaponData

	eRef = e.reference

	if (e.attackerReference == nil) or (e.attackerReference ~= tes3.player) then
		return
	end

	if (e.magicSourceInstance ~= nil) or (e.magicEffectInstance ~= nil) then
		return
	end

	if (e.projectile ~= nil) then
		tempAmmoWeapon = AmmoWeapon
		tempWeapon = Weapon
		tempWeaponData = WeaponData

		if (e.projectile.reference.object.objectType == tes3.objectType.ammunition) then
			if (AmmoWeapon == nil) or (AmmoWeapon.id ~= e.projectile.reference.object.id) then
				tempAmmoWeapon = e.projectile.reference.object
				tempWeapon = nil
				tempWeaponData = nil
			end
		elseif (e.projectile.reference.object.objectType == tes3.objectType.weapon) then
			if (Weapon == nil) or (Weapon.id ~= e.projectile.reference.object.id) then
				tempAmmoWeapon = nil
				tempWeapon = e.mobile.reference.object
				tempWeaponData = nil
			end
		end
		if (config.ResistLife == true) then
			AmmoTarget = 2
			resistFile.TestResist(eRef, tempAmmoWeapon, tempWeapon, tempWeaponData, AmmoTarget, Target)
			return
		end
		AmmoTarget = 2
		damageFile.AmmoDamage(tempWeapon, tempWeaponData, tempAmmoWeapon, AmmoTarget)
		return
	end

	if (tes3.mobilePlayer.readiedWeapon == nil) or (Weapon == nil) then
		return
	end

	local Length = string.len(Weapon.name)
	if (string.sub(Weapon.name, Length - 10, Length) ~= " (Poisoned)") then
		return
	end

	if (config.ResistLife == true) then
		resistFile.TestResist(eRef, AmmoWeapon, Weapon, WeaponData, AmmoTarget)
		return
	end
	damageFile.WeaponDamage(Weapon, WeaponData, AmmoWeapon)
end

local function CellChange(e)
	if (e.previous ~= nil) or (tes3.getGlobal("CharGenState") ~= -1) then
		return
	end

	local saveWeapon = tes3.getEquippedItem({ actor = tes3.mobilePlayer, objectType = tes3.objectType.weapon })
	local saveBow = tes3.getEquippedItem({ actor = tes3.mobilePlayer, objectType = tes3.objectType.weapon, type = 9 }) 
	local saveCrossbow = tes3.getEquippedItem({ actor = tes3.mobilePlayer, objectType = tes3.objectType.weapon, type = 10 }) 
	local saveAmmo = tes3.getEquippedItem({ actor = tes3.mobilePlayer, objectType = tes3.objectType.ammunition })

	if (saveWeapon ~= nil) and (saveBow == nil) and (saveCrossbow == nil) then
		Weapon = saveWeapon.object
		WeaponData = saveWeapon.itemData
	else
		Weapon = nil
		WeaponData = nil
	end 
	if (saveAmmo ~= nil) then
		AmmoWeapon = saveAmmo.object
	else
		AmmoWeapon = nil
	end
	restoreFile.Restoration(Weapon, AmmoWeapon)
end

local function OnLoad(e)
	mwse.log("[Poison Redux-ion] Initialized.")
	event.register("uiActivated", AlchemyEnter, { filter = "MenuAlchemy" }, { priority = -10000 })
	event.register("buttonPressed", Button)
	event.register("equipped", OnEquip)
	event.register("unequipped", OnUnequip)
	event.register("menuExit", MenuExit)
	event.register("damaged", Poisoned)
	event.register("projectileHitActor", ProjHit)
	event.register("projectileHitObject", ProjObject)
	event.register("projectileHitTerrain", ProjTerrain)
	event.register("cellChanged", CellChange)

	poisonFile = require("OEA.OEA8 Craft.poison")
	colorFile = require("OEA.OEA8 Craft.color")
	config = require("OEA.OEA8 Craft.config")
	featureFile = require("OEA.OEA8 Craft.features")
	menuFile = require("OEA.OEA8 Craft.menu")
	damageFile = require("OEA.OEA8 Craft.damage")
	restoreFile = require("OEA.OEA8 Craft.restore")
	resistFile = require("OEA.OEA8 Craft.resist")
	labelFile = require("OEA.OEA8 Craft.labels")
	labelFile.loadLabels()
end
event.register("initialized", OnLoad)

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
	require("OEA.OEA8 Craft.mcm")
end)

return H