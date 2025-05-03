local function getArmorClass(armor)
	local record = types.Armor.record(armor)
	local referenceWeight = 0
	local recordType = record.type
	if recordType == types.Armor.TYPE.Boots then
		referenceWeight = core.getGMST("iBootsWeight")
	elseif recordType == types.Armor.TYPE.Cuirass then
		referenceWeight = core.getGMST("iCuirassWeight")
	elseif recordType == types.Armor.TYPE.Greaves then
		referenceWeight = core.getGMST("iGreavesWeight")
	elseif recordType == types.Armor.TYPE.Helmet then
		referenceWeight = core.getGMST("iHelmWeight")
	elseif recordType == types.Armor.TYPE.LBracer then
		referenceWeight = core.getGMST("iGauntletWeight")
	elseif recordType == types.Armor.TYPE.RBracer then
		referenceWeight = core.getGMST("iGauntletWeight")
	elseif recordType == types.Armor.TYPE.LPauldron then
		referenceWeight = core.getGMST("iPauldronWeight")
	elseif recordType == types.Armor.TYPE.RPauldron then
		referenceWeight = core.getGMST("iPauldronWeight")
	elseif recordType == types.Armor.TYPE.LGauntlet then
		referenceWeight = core.getGMST("iGauntletWeight")
	elseif recordType == types.Armor.TYPE.RGauntlet then
		referenceWeight = core.getGMST("iGauntletWeight")
	elseif recordType == types.Armor.TYPE.Shield then
		referenceWeight = core.getGMST("iShieldWeight")
	end
	local epsilon = 5e-4

	if record.weight <= referenceWeight * core.getGMST("fLightMaxMod") + epsilon then
		return "light"
	elseif record.weight <= referenceWeight * core.getGMST("fMedMaxMod") + epsilon then
		return "medium"
	else
		return "heavy"
	end
end

return function(thing)
	if thing.type == types.Armor then
		return "item armor "..getArmorClass(thing).." up"
		--"item armor heavy up"
		--"item armor light up"
		--"item armor medium up"
	elseif thing.type == types.Apparatus then
		return "item apparatus up" 
	elseif thing.type == types.Book then
		return "item book up"
	elseif thing.type == types.Clothing then
		local record = types.Clothing.record(thing)
		local recordType = record.type
		if recordType == types.Clothing.TYPE.Ring then
			return "item ring up"
		elseif recordType == types.Clothing.TYPE.Amulet then --not vanilla
			return "item ring up"
		else
			return "item clothes up"
		end
	elseif  thing.recordId == "gold_001" or thing.recordId == "gold_005" or thing.recordId == "gold_010" or thing.recordId == "gold_025" or thing.recordId == "gold_100" then
		return "item gold up"
	elseif thing.type == types.Ingredient then
		return "item ingredient up"
	elseif thing.type == types.Lockpick then
		return "item lockpick up"
	elseif thing.type == types.Miscellaneous then
		return "item misc up"
	elseif thing.type == types.Potion then
		return "item potion up"
	elseif thing.type == types.Probe then
		return "item probe up"
	elseif thing.type == types.Repair then
		return "item repair up"
	elseif thing.type == types.Weapon then
		local record = types.Weapon.record(thing)
		local recordType = record.type
		if recordType == types.Weapon.TYPE.Arrow or recordType == types.Weapon.TYPE.Bolt then
			return "item ammo up"
		elseif recordType == types.Weapon.TYPE.MarksmanBow then
			return "item weapon bow up"
		elseif recordType == types.Weapon.TYPE.MarksmanCrossbow then
			return "item weapon crossbow up"
		elseif recordType == types.Weapon.TYPE.LongBladeOneHand or recordType == types.Weapon.TYPE.LongBladeTwoHand then
			return "item weapon longblade up"
		elseif recordType == types.Weapon.TYPE.ShortBladeOneHand then
			return "item weapon shortblade up"
		elseif recordType == types.Weapon.TYPE.SpearTwoWide then
			return "item weapon spear up"
		else--if recordType == types.Weapon.TYPE.BluntOneHand 
		--or recordType == types.Weapon.TYPE.BluntTwoClose 
		--or recordType == types.Weapon.TYPE.BluntTwoWide 
		--or recordType == types.Weapon.TYPE.MarksmanThrown 
		--or recordType == types.Weapon.TYPE.AxeOneHand 
		--or recordType == types.Weapon.TYPE.AxeTwoHand then
			return "item weapon blunt up"
		end
	else
		return "item bodypart up"
	end
end