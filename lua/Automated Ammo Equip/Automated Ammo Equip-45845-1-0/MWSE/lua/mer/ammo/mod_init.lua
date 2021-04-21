--[[
	Automated Ammo Equip by Merlord

	This mod contains a short Lua script that will equip the correct type of ammo whenever you equip a bow or crossbow, 
	unless you have the right ammo already equipped. 
	It selects the first ammo that it finds, preferring regular ammo over enchanted.

	Requires the  latest dev build of MWSE﻿, and version 10 of MGE

	Installation
	Place this script in Data Files\MWSE\lua\mer\ammo\. To uninstall, just delete the directory 'Data Files\MWSE\lua\mer\ammo\' 
]]--

--Mappings from GetWeaponType
local bow = tes3.weaponType.marksmanBow
local crossbow = tes3.weaponType.marksmanCrossbow
local arrow = tes3.weaponType.arrow
local bolt = tes3.weaponType.bolt
--to prevent endless loop
local ignoreNextEquip

local function onEquip(event)
	if ignoreNextEquip == true then 
		ignoreNextEquip = false
		return
	end
	local mobilePlayer = tes3.getMobilePlayer()
	local playerRef = mobilePlayer.reference
	if event.reference ~= playerRef then return end
	local readiedAmmoType = mobilePlayer.readiedAmmo and mobilePlayer.readiedAmmo.object.type or ""
	local inventory = playerRef.object.inventory
	local weapon = event.item
	if weapon.type == bow and readiedAmmoType ~= arrow then 
		for stack in tes3.iterate(inventory.iterator) do
			local item = stack.object
			if item.type == arrow then
				ignoreNextEquip = true
				mwscript.equip{reference=playerRef, item=item.id }
			end
		end
	elseif weapon.type == crossbow and readiedAmmoType ~= bolt then
		for stack in tes3.iterate(inventory.iterator) do
			local item = stack.object
			if item.type == bolt then
				ignoreNextEquip = true
				mwscript.equip{reference=playerRef, item=item.id }
			end
		end
	end
end
event.register("equipped", onEquip)