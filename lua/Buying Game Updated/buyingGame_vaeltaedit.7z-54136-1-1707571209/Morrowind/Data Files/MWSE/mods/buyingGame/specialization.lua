local common = require("buyingGame.common")

local specialization = {}

local classObjectType = {
	Clothier = {
		[tes3.objectType.clothing] = 0.2,
	},
	Bookseller = {
		[tes3.objectType.book]= 0.2,
	},
	["Savant Service"] = {
		[tes3.objectType.book]= 0.2,
	},
	["Alchemist Service"] = {
		[tes3.objectType.apparatus] = 0.1,
		[tes3.objectType.alchemy] = 0.1,
		[tes3.objectType.ingredient] = 0.1,
	},
	["Apothecary Service"] = {
		[tes3.objectType.apparatus] = 0.1,
		[tes3.objectType.alchemy] = 0.1,
		[tes3.objectType.ingredient] = 0.1,
	},
	["Healer Service"] = {
		[tes3.objectType.alchemy] = 0.15,
		[tes3.objectType.ingredient] = 0.15,
	},
	["Priest Service"] = {
		[tes3.objectType.book] = 0.1,
		[tes3.objectType.alchemy] = 0.1,
		[tes3.objectType.ingredient] = 0.1,
	},
	 Smith = {
		[tes3.objectType.armor] = 0.1,
		[tes3.objectType.weapon] = 0.1,
		[tes3.objectType.repairItem] = 0.1,
	},
	["Thief Service"] = {
		[tes3.objectType.lockpick]= 0.15,
		[tes3.objectType.probe]= 0.15,
	},
}

specialization.getModifier = function(mobile, item)
	local class = mobile.reference.object.class.id
	local cell = tes3.getPlayerCell()
	local modifier = 0
	
	if string.startswith(cell.id, "Tel Mora") then
		if tes3.player.female then
			if tes3.mobilePlayer.mercantile.current >= common.config.knowsSpecialization then
				modifier = modifier + 0.2
			end
		else
			modifier = modifier - 0.2
		end
	end
	
	if tes3.mobilePlayer.mercantile.current < common.config.knowsSpecialization then
		return modifier
	end
	
	--[[
	Will be done later
	if cell.id == "Vivec, St. Delyn Potter's Hall" and common.config.pottery[item.id] then
		modifier = modifier + 0.2
	elseif cell.id == "Vivec, St. Delyn Glassworker's Hall" and common.config.glass[item.id] then
		modifier = modifier + 0.2
	end
	]]
	
	if common.config.smuggler[mobile.reference.object.baseObject.id] then
		if item.id == "ingred_moon_sugar_01" or item.id == "potion_skooma_01" then
			modifier = modifier + 0.2
		end		
	elseif class == "Enchanter Service" then
		if item.enchantment then
			modifier = modifier + 0.15
		elseif common.config.soulgem[item.id] then
			modifier = modifier + 0.15
		end
	elseif class == "Publican" then
		if common.config.food[item.id] then
			modifier = modifier + 0.2
		end
	elseif classObjectType[class] then
		modifier = modifier + ( classObjectType[class][item.objectType] or 0)
	end
	return modifier
end

return specialization