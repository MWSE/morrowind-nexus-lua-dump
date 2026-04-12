local world = require("openmw.world")
local types = require("openmw.types")
local core = require('openmw.core')

local dremoraBossWeapon = {
	"daedric battle axe",
	"daedric claymore",
	"daedric dai-katana",
	"daedric katana",
	"daedric longsword",
	"daedric mace",
	"daedric wakizashi",
	"daedric war axe",
	"daedric warhammer",
}

local hasDremoraEquipment = false

local function printList(list)
	for _, item in pairs(list) do print(item) end
end

local function onInit()

	if core.contentFiles.has("Dremora Equipment.omwaddon") then
		hasDremoraEquipment = true
	end

	if core.contentFiles.has("Tamriel_Data.esm") then
		dremoraBossWeapon[#dremoraBossWeapon+1] = "t_dae_regular_scimitar_01"
		dremoraBossWeapon[#dremoraBossWeapon+1] = "t_dae_regular_longsword_01"

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

local function updateEquipmentDremora(actor)

	if not hasDremoraEquipment then return end

	local weapons = types.Actor.inventory(actor):getAll(types.Weapon)

	if not weapons[1] then return end

	local oldWeaponRec = types.Weapon.record(weapons[1])

	local newWeaponId

	local isArcherDremora = false
	local isArcherDaedric = false

	if oldWeaponRec.id:find("daedric") then return
	else		
		if oldWeaponRec.id:find("ebony") then
			
			if oldWeaponRec.type == types.Weapon.TYPE.Arrow then
				isArcherDremora = true
			elseif oldWeaponRec.type == types.Weapon.TYPE.AxeOneHand then
				newWeaponId = "daedric war axe"
			elseif oldWeaponRec.type == types.Weapon.TYPE.AxeTwoHand then
				newWeaponId = "daedric battle axe"
			elseif oldWeaponRec.type == types.Weapon.TYPE.BluntOneHand then
				if oldWeaponRec.id:find("mace") then
					newWeaponId = "daedric mace"
				else
					newWeaponId = "daedric club"
				end
			elseif oldWeaponRec.type == types.Weapon.TYPE.BluntTwoClose then
				newWeaponId = "daedric warhammer"
			elseif oldWeaponRec.type == types.Weapon.TYPE.BluntTwoWide then
				newWeaponId = "daedric staff"
			elseif oldWeaponRec.type == types.Weapon.TYPE.LongBladeOneHand then
				newWeaponId = "daedric longsword"
			elseif oldWeaponRec.type == types.Weapon.TYPE.LongBladeTwoHand then
				newWeaponId = "daedric claymore"
			elseif oldWeaponRec.type == types.Weapon.TYPE.MarksmanBow then
				isArcherDremora = true
			elseif oldWeaponRec.type == types.Weapon.TYPE.ShortBladeOneHand then
				if oldWeaponRec.id:find("short") then
					newWeaponId = "daedric shortsword"
				elseif oldWeaponRec.id:find("wakizashi") then
					newWeaponId = "daedric wakizashi"
				elseif oldWeaponRec.id:find("tanto") then
					newWeaponId = "daedric tanto"
				else
					newWeaponId = "daedric dagger"
				end
			elseif oldWeaponRec.type == types.Weapon.TYPE.SpearTwoWide then
				newWeaponId = "daedric spear"
			else
				newWeaponId = "daedric mace"
			end


		else
			if oldWeaponRec.type == types.Weapon.TYPE.Arrow then
				isArcherDremora = true
			elseif oldWeaponRec.type == types.Weapon.TYPE.AxeOneHand then
				newWeaponId = "dremora war axe"
			elseif oldWeaponRec.type == types.Weapon.TYPE.AxeTwoHand then
				newWeaponId = "dremora battle axe"
			elseif oldWeaponRec.type == types.Weapon.TYPE.BluntOneHand then
				if oldWeaponRec.id:find("mace") then
					newWeaponId = "dremora mace"
				else
					newWeaponId = "dremora club"
				end
			elseif oldWeaponRec.type == types.Weapon.TYPE.BluntTwoClose then
				newWeaponId = "dremora warhammer"
			elseif oldWeaponRec.type == types.Weapon.TYPE.BluntTwoWide then
				newWeaponId = "dremora staff"
			elseif oldWeaponRec.type == types.Weapon.TYPE.LongBladeOneHand then
				newWeaponId = "dremora longsword"
			elseif oldWeaponRec.type == types.Weapon.TYPE.LongBladeTwoHand then
				newWeaponId = "dremora claymore"
			elseif oldWeaponRec.type == types.Weapon.TYPE.MarksmanBow then
				isArcherDremora = true
			elseif oldWeaponRec.type == types.Weapon.TYPE.ShortBladeOneHand then
				if oldWeaponRec.id:find("short") or oldWeaponRec.id:find("wakizashi") then
					newWeaponId = "dremora shortsword"
				else
					newWeaponId = "dremora dagger"
				end
			elseif oldWeaponRec.type == types.Weapon.TYPE.SpearTwoWide then
				if oldWeaponRec.id:find("long") then
					newWeaponId = "dremora longspear"
				else
					newWeaponId = "dremora spear"
				end
			else
				newWeaponId = "dremora mace"
			end
		end
	end

	removeAllItems(weapons)

	if isArcherDremora then
		addNewItem(actor, "dremora long bow", 1)
		addNewItem(actor, "dremora arrow", 40)
	elseif isArcherDaedric then
		addNewItem(actor, "daedric long bow", 1)
		addNewItem(actor, "daedric arrow", 40)
	else
		local newWeapon = addNewItem(actor, newWeaponId, 1)
		actor:sendEvent('equipWeaponDremora', newWeapon)
	end
end

local function updateEquipmentDremoraBoss(actor)

	local weapons = types.Actor.inventory(actor):getAll(types.Weapon)

	newWeaponId = dremoraBossWeapon[math.random(#dremoraBossWeapon)]

	removeAllItems(weapons)

	local newWeapon = addNewItem(actor, newWeaponId, 1)
	actor:sendEvent('equipWeaponDremora', newWeapon)
end

return {
	eventHandlers = {
		updateEquipmentDremora = updateEquipmentDremora, updateEquipmentDremoraBoss = updateEquipmentDremoraBoss
	},
	engineHandlers = {
		onInit = onInit, onLoad = onInit 
	}
}