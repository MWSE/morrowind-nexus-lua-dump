local world = require("openmw.world")
local types = require("openmw.types")
local core = require('openmw.core')

local glassWeaponGS = {
	"glass claymore",
	"glass dagger",
	"glass firesword",
	"glass frostsword",
	"glass halberd",
	"glass jinkblade",
	"glass longsword",
	"glass poisonsword",
	"glass stormsword",
}

local glassShieldGS = {
	"glass_shield",
	"glass_towershield",
}

local ebonyWeaponGS = {
	"ebony broadsword",
	"ebony longsword",
	"ebony mace",
	"ebony shortsword",
	"ebony spear",
}

local ebonyShieldGS = {
	"ebony_shield",
	"ebony_towershield",
}

local daedricWeaponGS = {
	"daedric dagger",
	"daedric katana",
	"daedric longsword",
	"daedric shortsword",
	"daedric mace",
}

local daedricShieldGS = {
	"daedric_shield",
	"daedric_towershield",
}

local function printList(list)
	for _, item in pairs(list) do print(item) end
end

local function onInit()

	if core.contentFiles.has("Tribunal.esm") then
		ebonyWeaponGS[#ebonyWeaponGS+1] = "ebony scimitar"
	end

	if core.contentFiles.has("Tamriel_Data.esm") then
		daedricWeaponGS[#daedricWeaponGS+1] = "t_dae_regular_scimitar_01"
		daedricWeaponGS[#daedricWeaponGS+1] = "t_dae_regular_longsword_01"

		ebonyWeaponGS[#ebonyWeaponGS+1] = "t_de_ebony_katana_01"

		glassWeaponGS[#glassWeaponGS+1] = "t_de_glass_flamesword_01"
		glassWeaponGS[#glassWeaponGS+1] = "t_de_glass_shardsword_01"
		glassWeaponGS[#glassWeaponGS+1] = "t_de_glass_sparksword_01"
		glassWeaponGS[#glassWeaponGS+1] = "t_de_glass_vipersword_01"
		glassWeaponGS[#glassWeaponGS+1] = "t_de_glass_mace_01"
		glassWeaponGS[#glassWeaponGS+1] = "t_de_glass_flamemace_01"
		glassWeaponGS[#glassWeaponGS+1] = "t_de_glass_shardmace_01"
		glassWeaponGS[#glassWeaponGS+1] = "t_de_glass_sparkmace_01"
		glassWeaponGS[#glassWeaponGS+1] = "t_de_glass_vipermace_01"
		glassWeaponGS[#glassWeaponGS+1] = "t_de_glass_katana_01"
	end
end

local function deleteAllObj(obj)
    obj.enabled = false
    obj:remove(obj.count)
end

local function removeAllItems(itemList)
	for _, item in pairs(itemList) do deleteAllObj(item) end
end

local function addNewItem(actor, itemId, count)
	local item = world.createObject(itemId, count)
	item:moveInto(actor.type.inventory(actor))
	return item
end

local function updateEquipmentGS(actor)

	local newWeaponId
	local newShieldId

	local rand = math.random(3)

	if rand == 1 then
		newWeaponId = daedricWeaponGS[math.random(#daedricWeaponGS)]
		newShieldId = daedricShieldGS[math.random(#daedricShieldGS)]
	elseif rand == 2 then
		newWeaponId = ebonyWeaponGS[math.random(#ebonyWeaponGS)]
		newShieldId = ebonyShieldGS[math.random(#ebonyShieldGS)]
	else
		newWeaponId = glassWeaponGS[math.random(#glassWeaponGS)]
		newShieldId = glassShieldGS[math.random(#glassShieldGS)]
	end

	actorInventory = types.Actor.inventory(actor)

	removeAllItems(actorInventory:getAll(types.Weapon))
	removeAllItems(actorInventory:getAll(types.Armor))

	local newWeapon = addNewItem(actor, newWeaponId, 1)
	local newShield = addNewItem(actor, newShieldId, 1)

	actor:sendEvent('equipWeaponAndShieldGS', { weapon=newWeapon, shield=newShield })
end

return {
	eventHandlers = {
		updateEquipmentGS = updateEquipmentGS
	},
	engineHandlers = {
		onInit = onInit, onLoad = onInit 
	}
}