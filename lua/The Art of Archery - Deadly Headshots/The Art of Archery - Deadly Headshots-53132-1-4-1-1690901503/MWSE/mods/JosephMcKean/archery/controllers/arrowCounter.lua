local config = require("JosephMcKean.archery.config")

---@class ArcheryTweaks.uiids
local uiids = { menuMulti = tes3ui.registerID("MenuMulti"), weaponBorder = tes3ui.registerID("MenuMulti_weapon_border") }

---@return boolean
---@return number
local function getMarksmanEquipment()
	if tes3.mobilePlayer.readiedAmmo then
		if tes3.mobilePlayer.readiedAmmo.object.type == tes3.weaponType.marksmanThrown then
			return true, tes3.mobilePlayer.readiedAmmoCount
		elseif tes3.mobilePlayer.readiedAmmo.object.type == tes3.weaponType.arrow then
			if tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon, type = tes3.weaponType.marksmanBow }) then
				return true, tes3.mobilePlayer.readiedAmmoCount
			elseif tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon, type = tes3.weaponType.marksmanCrossbow }) then
				return true, 0
			end
		elseif tes3.mobilePlayer.readiedAmmo.object.type == tes3.weaponType.bolt then
			if tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon, type = tes3.weaponType.marksmanCrossbow }) then
				return true, tes3.mobilePlayer.readiedAmmoCount
			elseif tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon, type = tes3.weaponType.marksmanBow }) then
				return true, 0
			end
		end
	elseif tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon, type = tes3.weaponType.marksmanBow }) then
		return true, 0
	elseif tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon, type = tes3.weaponType.marksmanCrossbow }) then
		return true, 0
	end
	return false, 0
end

local function createAmmoCountLabel()
	local menuMulti = tes3ui.findMenu(uiids.menuMulti)
	if not menuMulti then return end
	local ammoCountLabel = menuMulti:findChild(uiids.weaponBorder):createLabel({ id = "MenuMulti_ammo_count_label" })
	ammoCountLabel.absolutePosAlignX = 0.9
	ammoCountLabel.absolutePosAlignY = 0.95
	ammoCountLabel.color = { 0.875, 0.788, 0.624, 1.000 }
	timer.start({
		iterations = -1,
		duration = 0.5,
		callback = function()
			local hasMarksmanWeaponEquipped, ammoCount = getMarksmanEquipment()
			ammoCountLabel.visible = config.enableArrowCounter and hasMarksmanWeaponEquipped
			ammoCountLabel.text = tostring(ammoCount)
		end,
	})
end

return createAmmoCountLabel
