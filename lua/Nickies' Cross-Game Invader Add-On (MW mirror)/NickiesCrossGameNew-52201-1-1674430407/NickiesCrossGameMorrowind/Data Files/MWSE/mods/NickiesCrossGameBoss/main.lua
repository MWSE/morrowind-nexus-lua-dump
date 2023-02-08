tes3.claimSpellEffectId("NickiesReflectDamage", 1000)

BossDisarmed = 0
BossOffhandHurt = 0

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
        -- The ID we claimed before is now available in tes3.effect namespace
        id = tes3.effect.NickiesReflectDamage,

        -- This information if just copied from the Construction Set --
        name = "Reflect Damage",
        description = ("This spell effect reflects incoming damage to the attacker, " ..
        "with the magnitude representing the percent reflected."),
        baseCost = 2.5,
        school = tes3.magicSchool.mysticism,
        size = 1.25,
        sizeCap = 50,
        speed = 1,
        lighting = { x = 0.99, y = 0.26, z = 0.53 },
        usesNegativeLighting = false,

        icon = "s\\Tx_S_reflect.tga",
        particleTexture = "vfx_crystalline.tga",
        castSound = "Mysticism cast",
        castVFX = "VFX_MysticismCast",
        boltSound = "Mysticism bolt",
        boltVFX = "VFX_MysticismBolt",
        hitSound = "Mysticism hit",
        hitVFX = "VFX_MysticismHit",
        areaSound = "Mysticism area",
        areaVFX = "VFX_MysticismArea",
        -- --

        appliesOnce = true,
        hasNoDuration = false,
        hasNoMagnitude = false,
        illegalDaedra = false,
        unreflectable = false,
        casterLinked = false,
        nonRecastable = true,
        targetsAttributes = false,
        targetsSkills = false
    })
end)

local function fillMagicEffects(magicItem, table1, baseString, lastEffect1, numEffects1)
	counter3 = 0
	while counter3 < numEffects1 do
		effectNumber = baseString .. "Effect" .. tostring(counter3)
		effectID = table.get(table1, effectNumber .. "effect", -1)
		if effectID == -1 then
			if lastEffect1 > 0 then
				goto continue2
			else 
				tes3.messageBox("The imported spell has no valid effects!")
				return
			end
		end
		if effectID == 50 or effectID == 52 or effectID == 54 or effectID == 56 or effectID == 33 or effectID == 70 or effectID == 95 then
			--tes3.messageBox("Check3")
			effect = magicItem.effects[counter3 + 1]
			--tes3.messageBox("Check4")
			effect.id = effectID
			if effectID == 83 or effectID == 21 or effectID == 89 then 
				effect.skill = table.get(table1, effectNumber .. "attribute", 0)
			else
				effect.attribute = table.get(table1, effectNumber .. "attribute", 0)
			end
			effect.attribute = table.get(table1, effectNumber .. "attribute", 0)
			effect.rangeType = table.get(table1, effectNumber .. "range", 0)
			effect.max = table.get(table1, effectNumber .. "magnitude", 0)
			effect.min = table.get(table1, effectNumber .. "magnitude", 0)
			effect.duration = table.get(table1, effectNumber .. "duration", 0)
			effect.radius = table.get(table1, effectNumber .. "area", 0)
			--table1["ResetJSON", 0)
			counter3 = counter3 + 1

			effect = magicItem.effects[extraEffect]
			extraEffect = extraEffect - 1
			numEffects1 = numEffects1
			--tes3.messageBox("Check4")
			effect.id = effectID - 1
			if effectID == 83 or effectID == 21 or effectID == 89 then 
				effect.skill = table.get(table1, effectNumber .. "attribute", 0)
			else
				effect.attribute = table.get(table1, effectNumber .. "attribute", 0)
			end
			effect.rangeType = table.get(table1, effectNumber .. "range", 0)
			effect.max = table.get(table1, effectNumber .. "magnitude", 0)
			effect.min = table.get(table1, effectNumber .. "magnitude", 0)
			effect.duration = table.get(table1, effectNumber .. "duration", 0)
			effect.radius = table.get(table1, effectNumber .. "area", 0)
			--table1["ResetJSON", 0)
			goto continue9
		end
		if effectID == 83 or effectID == 21 or effectID == 89 then
			effect = magicItem.effects[counter3 + 1]
				--tes3.messageBox("Check4")
			effect.id = effectID
			effect.skill = table.get(table1, effectNumber .. "attribute", 0)
			if effect.skill == 5 or effect.skill == 2 or effect.skill == 6 then 
				--tes3.messageBox("Check3")
				
				if effectID == 83 or effectID == 21 or effectID == 89 then 
					effect.skill = table.get(table1, effectNumber .. "attribute", 0)
				else
					effect.attribute = table.get(table1, effectNumber .. "attribute", 0)
				end
				effect.attribute = table.get(table1, effectNumber .. "attribute", 0)
				effect.rangeType = table.get(table1, effectNumber .. "range", 0)
				effect.max = table.get(table1, effectNumber .. "magnitude", 0)
				effect.min = table.get(table1, effectNumber .. "magnitude", 0)
				effect.duration = table.get(table1, effectNumber .. "duration", 0)
				effect.radius = table.get(table1, effectNumber .. "area", 0)
				--table1["ResetJSON", 0)
				counter3 = counter3 + 1

				newEffect = magicItem.effects[extraEffect]
				newEffect.id = effectID
				extraEffect = extraEffect - 1
				numEffects1 = numEffects1
				--tes3.messageBox("Check4")
				if effect.skill == 5 then
					newEffect.skill = 22
				elseif effect.skill == 6 then 
					newEffect.skill = 4
				elseif effect.skill == 2 then 
					newEffect.skill = 3
				end
				
				newEffect.rangeType = table.get(table1, effectNumber .. "range", 0)
				newEffect.max = table.get(table1, effectNumber .. "magnitude", 0)
				newEffect.min = table.get(table1, effectNumber .. "magnitude", 0)
				newEffect.duration = table.get(table1, effectNumber .. "duration", 0)
				newEffect.radius = table.get(table1, effectNumber .. "area", 0)
				--table1["ResetJSON", 0)
				goto continue9
			end
		end
		--tes3.messageBox("Check3")
		effect = magicItem.effects[counter3 + 1]
		--tes3.messageBox("Check4")
		effect.id = effectID
		if effectID == 83 or effectID == 21 or effectID == 89 then 
			effect.skill = table.get(table1, effectNumber .. "attribute", 0)
		else
			effect.attribute = table.get(table1, effectNumber .. "attribute", 0)
		end
		effect.rangeType = table.get(table1, effectNumber .. "range", 0)
		effect.max = table.get(table1, effectNumber .. "magnitude", 0)
		effect.min = table.get(table1, effectNumber .. "magnitude", 0)
		effect.duration = table.get(table1, effectNumber .. "duration", 0)
		effect.radius = table.get(table1, effectNumber .. "area", 0)
		--table1["ResetJSON", 0)
		::continue2::
		counter3 = counter3 + 1
		::continue9::
	end
end

local function toTableMagicEffects(magicItem, baseString, table1)
	counter2 = 0
	counter12 = 0
	thisSpellEffects = magicItem.effects
	for _, effect in pairs(thisSpellEffects) do
		effectNumber = baseString .. "Effect" .. tostring(counter2)
		effectID = effect.id
		if effectID == -1 then
			counter2 = counter2 + 1
			goto continue5
		end
		table1[effectNumber .. "effect"] = effect.id
		if effectID == 83 or effectID == 21 or effectID == 89 then 
			table1[effectNumber .. "attribute"] = effect.skill
		else
			table1[effectNumber .. "attribute"] = effect.attribute
		end
		table1[effectNumber .. "range"] = effect.rangeType
		table1[effectNumber .. "magnitude"] = effect.max
		table1[effectNumber .. "duration"] = effect.duration
		table1[effectNumber .. "area"] = effect.radius
		--table1["ResetJSON", 0)
		counter2 = counter2 + 1
		counter12 = counter12 + 1
		::continue5::
	end
	table1[baseString .. "LastEffectNumber"] = counter12 - 1
end

local function toTableItems(chestRef, outputTable)
	isArmor = 0
	isWeapon = 0
	isClothing = 0
	isPotion = 0
	TypeVariable = 0

	numPauldron = 0
	numPauldronL = 0
	numPauldronR = 0
	numBelt = 0
	numGauntlet = 0
	numGauntletL = 0
	numGauntletR = 0
	numCuirass = 0
	numGreaves = 0

	armorSlot = -1
	clothingSlot = -1
	weaponType = -1

	chestObj = chestRef.object
	chestInv = chestObj.inventory
	chestItems = chestInv.items

	counter21 = 0

	for _, itemStack in pairs(chestItems) do
		item = itemStack.object
		if itemStack.variables ~= nil then
			itemData = itemStack.variables
		end
		itemID = item.id
		itemType = item.objectType
		if itemID == -1 then
			goto continue4
		end
		if itemType ~= tes3.objectType.armor and itemType ~= tes3.objectType.clothing and itemType ~= tes3.objectType.weapon and itemType ~= tes3.objectType.alchemy then
			goto continue4
		end
		if itemType == tes3.objectType.armor then
			isArmor = 1
			TypeVariable = 0
			armorSlot = item.slot
			if armorSlot == 2 then
				numPauldron = numPauldron + 1
				numPauldronL = numPauldronL + 1
			elseif armorSlot == 3 then
				numPauldron = numPauldron + 1
				numPauldronR = numPauldronR + 1
			elseif armorSlot == 6 or armorSlot == 9 then
				numGauntlet = numGauntlet + 1
				numGauntletL = numGauntletL + 1
			elseif armorSlot == 7 or armorSlot == 10 then
				numGauntlet = numGauntlet + 1
				numGauntletR = numGauntletR + 1
			elseif armorSlot == 1 then 
				numCuirass = numCuirass + 1
			end
		end
		if itemType == tes3.objectType.clothing then
			isClothing = 1
			TypeVariable = 1
			clothingSlot = item.slot
			if clothingSlot == 3 then
				numBelt = numBelt + 1
			end
			if clothingSlot == 0 or clothingSlot == 7 then
				numGreaves = numGreaves + 1
			end
		end 
		
		counter21 = counter21 + 1
		::continue4::
	end
	counter21 = 0
	if numPauldronL ~= numPauldronR or numPauldron > numCuirass * 2 or (numBelt ~= numGreaves and numBelt > 0) or numGauntletL ~= numGauntletR or numPauldron > 2 or numBelt > 1 or numGauntlet > 2 then
		tes3.messageBox("You have an invalid item configuration!")
		invalid = 1
		return
	end

	if numPauldronL > 0 then 
		outputTable["HasPauldrons"] = 1
	end
	if numGauntletL > 0 then 
		outputTable["HasGauntlets"] = 1
	end
	if numBelt > 0 then 
		outputTable["HasBelt"] = 1
	end
	outputTable["HasPauldrons"] = 0
	outputTable["HasGauntlets"] = 0
	outputTable["HasBelt"] = 0
	counter21 = 0
	for _, itemStack in pairs(chestItems) do
		
		item = itemStack.object
		--tes3.messageBox(item.name)
		if itemStack.variables ~= nil then
			itemData = itemStack.variables
		end
		itemID = item.id
		itemType = item.objectType
		isEnchanted = 0
		if itemID == -1 then
			goto continue3
		end
		if itemType == tes3.objectType.book then 
			if item.type ~= 1 or item.enchantment == nil then 
				goto continue3 
			end
		end
		if itemType ~= tes3.objectType.book and itemType ~= tes3.objectType.armor and itemType ~= tes3.objectType.clothing and itemType ~= tes3.objectType.weapon and itemType ~= tes3.objectType.alchemy then
			goto continue3
		end

		itemNumber = "Item" .. tostring(counter21)

		outputTable[itemNumber .. "id"] = item.id
		outputTable[itemNumber .. "icon"] = item.icon
		outputTable[itemNumber .. "name"] = item.name
		outputTable[itemNumber .. "count"] = itemStack.count
		outputTable[itemNumber .. "value"] = item.value
		outputTable[itemNumber .. "weight"] = item.weight

		if itemType == tes3.objectType.armor then
			isArmor = 1
			TypeVariable = 0
			armorSlot = item.slot

			outputTable[itemNumber .. "typeVar"] = TypeVariable
			outputTable[itemNumber .. "armorSlot"] = armorSlot
			outputTable[itemNumber .. "armorRating"] = item.armorRating
			outputTable[itemNumber .. "armorScalar"] = item.armorScalar
			outputTable[itemNumber .. "armorClass"] = item.weightClass
			outputTable[itemNumber .. "health"] = item.maxCondition
			outputTable[itemNumber .. "condition"] = itemData.condition
			if item.enchantment ~= nil then
				isEnchanted = 1
			end
		end
		if itemType == tes3.objectType.clothing then
			isClothing = 1
			TypeVariable = 1
			clothingSlot = item.slot
			outputTable[itemNumber .. "typeVar"] = TypeVariable
			outputTable[itemNumber .. "clothingSlot"] = clothingSlot
			if item.enchantment ~= nil then
				isEnchanted = 1
			end
		end 
		if itemType == tes3.objectType.weapon then 
			isWeapon = 1
			TypeVariable = 2
			weaponType = item.type 
			damage = math.max(item.slashMax, item.chopMax, item.thrustMax)
			if itemType == 11 then
				goto continue3
			end
			outputTable[itemNumber .. "typeVar"] = TypeVariable
			outputTable[itemNumber .. "weapDamage"] = damage
			outputTable[itemNumber .. "weapType"] = weaponType
			outputTable[itemNumber .. "weapSkill"] = item.skillId
			if item.isAmmo == false then
				outputTable[itemNumber .. "health"] = item.maxCondition
				if itemData == nil then 
					outputTable[itemNumber .. "condition"] = item.maxCondition
				else 
					outputTable[itemNumber .. "condition"] = itemData.condition
				end
			end
			outputTable[itemNumber .. "weapReach"] = item.reach
			outputTable[itemNumber .. "weapSpeed"] = item.speed
			outputTable[itemNumber .. "weapNonNormal"] = item.ignoresNormalWeaponResistance

			if item.enchantment ~= nil then
				isEnchanted = 1
			end
		end 
		if itemType == tes3.objectType.alchemy then
			isPotion = 1
			TypeVariable = 3
			isEnchanted = 0
			outputTable[itemNumber .. "typeVar"] = TypeVariable
			outputTable[itemNumber .. "EnchType"] = -1
			toTableMagicEffects(item, itemNumber, outputTable)
		end
		if itemType == tes3.objectType.book and item.enchantment ~= nil then 
			TypeVariable = 4
			isEnchanted = 1
			outputTable[itemNumber .. "typeVar"] = TypeVariable
		end
		counter22 = 0
		if isEnchanted == 1 and itemType ~= tes3.objectType.alchemy then
			thisEnch = item.enchantment
			thisSpellEffects = thisEnch.effects
			--if thisEnch.castType == 0 then 
			--	outputTable[itemNumber .. "EnchType"] = -1
			--	outputTable[itemNumber .. "LastEffectNumber"] = -1
			--	goto continue3
			--end
			outputTable[itemNumber .. "EnchType"] = thisEnch.castType
			if TypeVariable == 4 then 
				outputTable[itemNumber .. "EnchType"] = 5
			end
			outputTable[itemNumber .. "EnchCost"] = thisEnch.chargeCost
			if itemData ~= nil then 
				outputTable[itemNumber .. "EnchChargeCurr"] = itemData.charge
			else 
				outputTable[itemNumber .. "EnchChargeCurr"] = 1
			end
			outputTable[itemNumber .. "EnchChargeMax"] = thisEnch.maxCharge
			totalUses = 0
			if thisEnch.chargeCost ~= 0 then 
				totalUses = thisEnch.maxCharge / thisEnch.chargeCost	
			end
			outputTable[itemNumber .. "EnchUses"] = totalUses

			toTableMagicEffects(thisEnch, itemNumber, outputTable)
		elseif isEnchanted == 0 and itemType ~= tes3.objectType.alchemy then
			
			outputTable[itemNumber .. "EnchType"] = -1
			outputTable[itemNumber .. "LastEffectNumber"] = -1
		end
		
		counter21 = counter21 + 1
		::continue3::
	end
	outputTable["LastItemNumber"] = counter21 - 1

	
	tes3.messageBox("Tonal signatures transmitted!")
end

local function fillContainerWithItems(chestRef, outputTable)
	isArmor = 0
	isWeapon = 0
	isClothing = 0
	isPotion = 0
	isBook = 0
	TypeVariable = 0

	numPauldron = 0
	numPauldronL = 0
	numPauldronR = 0
	numBelt = 0
	numGauntlet = 0
	numGauntletL = 0
	numGauntletR = 0
	numCuirass = 0
	numGreaves = 0

	armorSlot = -1
	clothingSlot = -1
	weaponType = -1

	chestObj = chestRef.object
	chestInv = chestObj.inventory
	chestItems = chestInv.items

	for _, itemStack in pairs(chestItems) do
		item = itemStack.object
		thisCount = itemStack.count
		tes3.removeItem({reference=chestRef, item = item, count = thisCount})
	end
	lastItem = outputTable["LastItemNumber"]

	counter9 = 0
	while counter9 <= lastItem do
		itemNumber = "Item" .. tostring(counter9)
		itemTypeVar = outputTable[itemNumber .. "typeVar"]

		itemID = outputTable[itemNumber .. "id"]
		--tes3.messageBox(itemID)
		--originalRef = tes3.getReference("expensive_amulet_02")
		originalItem = tes3.getObject(itemID)
		--tes3.addItem({reference=tes3.mobilePlayer, item=originalItem})

		if itemTypeVar == 4 then 
			item1 = tes3.createObject({ objectType = tes3.objectType.book })
			--item1.boundingBox = originalItem.boundingBox
			item1.enchantCapacity = originalItem.enchantCapacity
			item1.icon = originalItem.icon 
			item1.mesh = originalItem.mesh

		else
			item1 = originalItem:createCopy()
		end
		--tes3.setSourceless(item1)

		itemName = outputTable[itemNumber .. "name"]
		nameLength = string.len(itemName)
		if nameLength > 30 then 
			itemName = string.sub(itemName, 0, 30)
		end
		itemWeight = outputTable[itemNumber .. "weight"]
		itemValue = outputTable[itemNumber .. "value"]

		item1.name = itemName
		item1.weight = itemWeight
		item1.value = itemValue
		
		

		itemType = item1.objectType
		isEnchanted = 0
		if objectID == -1 then
			goto continue13
		end
		if itemType == tes3.objectType.book then 
			if item.type ~= 1 and item.enchantment ~= nil then 
				return 
			end
		end
		if itemType ~= tes3.objectType.armor and itemType ~= tes3.objectType.clothing and itemType ~= tes3.objectType.weapon and itemType ~= tes3.objectType.alchemy and itemType ~= tes3.objectType.book then
			goto continue13
		end

		if itemType == tes3.objectType.armor then
			isArmor = 1
			TypeVariable = 0
			tes3.addItem({reference=chestRef, item=item1})
			itemData = tes3.addItemData({to=chestRef, item=item1})

			armorSlot = outputTable[itemNumber .. "armorSlot"]

			item1.armorRating = outputTable[itemNumber .. "armorRating"]

			item1.maxCondition = outputTable[itemNumber .. "health"]
			if itemData ~= nil then 
				itemData.condition = outputTable[itemNumber .. "condition"]
			end
			if itemData ~= nil then 
				itemData.charge = outputTable[itemNumber .. "EnchChargeCurr"]
			end

			if outputTable[itemNumber .. "EnchType"] > 0 then
				isEnchanted = 1
			else 
				isEnchanted = 0
			end
			--Hoods
			clothingSlot = table.get(outputTable, itemNumber .. "clothingSlot", nil)
			if clothingSlot ~= nil and item1.armorRating == 0 then 
				item1.armorRating = 20
				item1.maxCondition = 500000
				if itemData ~= nil then 
					itemData.condition = item1.maxCondition
				end
			end
			--Gauntlets
			if armorSlot == 4 then 
				itemID = itemID:gsub("right", "left")
				originalItem = tes3.getObject(itemID)
				itemL = originalItem:createCopy()
				--tes3.setSourceless(itemL)

				itemLName = itemName:gsub("(R)", "L")

	    		itemL.name = itemLName
	    		itemL.weight = itemWeight
	    		itemL.value = itemValue
				
				tes3.addItem({reference=chestRef, item=itemL})
				itemLData = tes3.addItemData({to=chestRef, item=itemL})

				itemL.armorRating = outputTable[itemNumber .. "armorRating"] / 2
				item1.armorRating = outputTable[itemNumber .. "armorRating"] / 2

				itemL.maxCondition = outputTable[itemNumber .. "health"]
				if itemLData ~= nil then 
					itemLData.condition = outputTable[itemNumber .. "condition"]
					itemLData.charge = outputTable[itemNumber .. "EnchChargeCurr"]
				end
			end
		end
		if itemType == tes3.objectType.clothing then
			isClothing = 1
			TypeVariable = 1
			thisCount = outputTable[itemNumber .. "count"]
			tes3.addItem({reference=chestRef, item=item1, count=thisCount})
			itemData = tes3.addItemData({to=chestRef, item=item1})
			armorSlot = outputTable[itemNumber .. "clothingSlot"]
			
			if outputTable[itemNumber .. "EnchType"] > 0 then
				isEnchanted = 1
			else 
				isEnchanted = 0
			end
			--Gloves
			if armorSlot == 4 then 
				itemID = itemID:gsub("right", "left")
				originalItem = tes3.getObject(itemID)
				itemL = originalItem:createCopy()
				--tes3.setSourceless(itemL)

				itemLName = itemName:gsub("(R)", "L")

	    		itemL.name = itemLName
	    		itemL.weight = itemWeight
	    		itemL.value = itemValue
				
				tes3.addItem({reference=chestRef, item=itemL})
				itemLData = tes3.addItemData({to=chestRef, item=itemL})

			end
		end 
		if itemType == tes3.objectType.weapon then 
			isWeapon = 1
			TypeVariable = 2
			thisCount = outputTable[itemNumber .. "count"]
			tes3.addItem({reference=chestRef, item=item1, count=thisCount})
			weaponType = item1.type 
			damage = outputTable[itemNumber .. "weapDamage"]
			item1.slashMax = damage
			item1.slashMin = damage 
			item1.chopMax = damage 
			item1.chopMin = damage 
			item1.thrustMax = damage 
			item1.thrustMin = damage 
			itemData = tes3.addItemData({to=chestRef, item=item1})
			
			if item1.isAmmo == false then
				item1.maxCondition = outputTable[itemNumber .. "health"]
				if itemData ~= nil then 
					itemData.condition = outputTable[itemNumber .. "condition"]
				end
			end
			item1.reach = outputTable[itemNumber .. "weapReach"]
			item1.speed = outputTable[itemNumber .. "weapSpeed"]
			item1.ignoresNormalWeaponResistance = outputTable[itemNumber .. "weapNonNormal"]

			if outputTable[itemNumber .. "EnchType"] > 0 then
				isEnchanted = 1
			else 
				isEnchanted = 0
			end
		end 
		if itemType == tes3.objectType.alchemy then
			isPotion = 1
			TypeVariable = 3
			lastEffect = table.get(outputTable, itemNumber .. "LastEffectNumber", 0)
			--tes3.messageBox("Check2")
			maxEffects = 8
			extraEffect = 8
			if lastEffect > 7 then
				lastEffect = 7
			end
			numEffects = lastEffect + 1

			fillMagicEffects(item1,outputTable,itemNumber, lastEffect, numEffects)
			thisCount = outputTable[itemNumber .. "count"]
			tes3.addItem({reference=chestRef, item=item1, count=thisCount})
			itemData = tes3.addItemData({to=chestRef, item=item1})
		end
		if itemType == tes3.objectType.book then 
			isEnchanted = 1
			TypeVariable = 4
			thisCount = outputTable[itemNumber .. "count"]
			tes3.addItem({reference=chestRef, item=item1, count=thisCount})
		end
		counter2 = 0
		if isEnchanted == 1 then
			thisChargeCost = outputTable[itemNumber .. "EnchCost"]
			if thisChargeCost == nil or thisChargeCost <= 0 then 
				thisChargeCost = 1 
			end
			if TypeVariable == 4 or outputTable[itemNumber .. 'EnchType'] == 5 then 
				outputTable[itemNumber .. 'EnchType'] = 0
			end
			if outputTable[itemNumber .. "EnchChargeMax"] == 0 then 
				outputTable[itemNumber .. "EnchChargeMax"] = 1 
			end
			thisEnch = tes3.createObject({objectType=tes3.objectType.enchantment, castType = outputTable[itemNumber .. 'EnchType'], chargeCost = thisChargeCost, maxCharge = outputTable[itemNumber .. "EnchChargeMax"]})
			thisSpellEffects = thisEnch.effects
			if TypeVariable == 4 then 
				outputTable[itemNumber .. 'EnchType'] = 0
			end
			thisEnch.castType = outputTable[itemNumber .. 'EnchType']
			if itemData ~= nil then 
				itemData.charge = outputTable[itemNumber .. "EnchChargeCurr"]
			end
			
			thisEnch.chargeCost = thisChargeCost
			thisEnch.maxCharge = outputTable[itemNumber .. "EnchChargeMax"]
			extraEffect = 7
			lastEffect = outputTable[itemNumber .. "LastEffectNumber"]
			numEffects = lastEffect + 1
			if lastEffect > 7 then 
				lastEffect = 7
			end
			fillMagicEffects(thisEnch,outputTable,itemNumber, lastEffect, numEffects)
			item1.enchantment = thisEnch
			if armorSlot == 4 then 
				itemL.enchantment = thisEnch 
			end
		elseif isEnchanted == 0 then

		end
		--if itemData ~= nil then 
		--	itemData.count = outputTable[itemNumber .. "count"]
		--end
		::continue13::
		counter9 = counter9 + 1
	end
	tes3.messageBox("Tonal signatures received!")
end

local function spawnNPCFromJSON(outputTable, cell, coordinates)
	raceFemale = {}
	raceMale = {}

	outputTableStats = outputTable["Player"]
	outputTableItems = outputTable["Items"]
	outputTableSpells = outputTable["Spells"]


	raceFemale["Argonian"] = "=NickiesArgonianF"
	raceFemale["Breton"] = "=NickiesBretonF"
	raceFemale["Imperial"] = "NickiesImperialF"
	raceFemale["Dark Elf"] = "NickiesDarkElfF"
	raceFemale["High Elf"] = "=NickiesHighElfF"
	raceFemale["Wood Elf"] = "=NickiesWoodElfF"
	raceFemale["Nord"] = "=NickiesNordF"
	raceFemale["Orc"] = "=NickiesOrcF"
	raceFemale["Khajiit"] = "=NickiesKhajiitF"
	raceFemale["Redguard"] = "=NickiesRedguardF"

	raceMale["Argonian"] = "=NickiesArgonianM"
	raceMale["Breton"] = "=NickiesBretonM"
	raceMale["Imperial"] = "NickiesImperialM"
	raceMale["Dark Elf"] = "NickiesDarkElfM"
	raceMale["High Elf"] = "=NickiesHighElfM"
	raceMale["Wood Elf"] = "=NickiesWoodElfM"
	raceMale["Nord"] = "=NickiesNordM"
	raceMale["Orc"] = "=NickiesOrcM"
	raceMale["Khajiit"] = "=NickiesKhajiitM"
	raceMale["Redguard"] = "=NickiesRedguardM"

	if outputTableStats["Sex"] == 1 then
		npcID = raceFemale[outputTableStats["Race"]]
	elseif outputTableStats["Sex"] == 0 then 
		npcID = raceMale[outputTableStats["Race"]]
	end

	spawnedNPC = tes3.getObject(npcID)

	spawnedNPC.name = outputTableStats["Name"]
	spawnedNPC.level = outputTableStats["Level"]

	newSkills = {outputTableStats["Block"],
		outputTableStats["Armorer"],
		outputTableStats["Mediumarmor"],
		outputTableStats["Heavyarmor"],
		outputTableStats["Bluntweapon"],
		outputTableStats["Longblade"],
		outputTableStats["Axe"],
		outputTableStats["Spear"],
		outputTableStats["Athletics"],
		outputTableStats["Enchant"],
		outputTableStats["Destruction"],
		outputTableStats["Alteration"],
		outputTableStats["Illusion"],
		outputTableStats["Conjuration"],
		outputTableStats["Mysticism"],
		outputTableStats["Restoration"],
		outputTableStats["Alchemy"],
		outputTableStats["Unarmored"],
		outputTableStats["Security"],
		outputTableStats["Sneak"],
		outputTableStats["Acrobatics"],
		outputTableStats["Lightarmor"],
		outputTableStats["Shortblade"],
		outputTableStats["Marksman"],
		outputTableStats["Mercantile"],
		outputTableStats["Speechcraft"],
		outputTableStats["Handtohand"]}
	newAttributes = {outputTableStats["Strength"], outputTableStats["Intelligence"], outputTableStats["Willpower"], outputTableStats["Agility"], outputTableStats["Speed"], outputTableStats["Endurance"], outputTableStats["Personality"], outputTableStats["Luck"]}

	--skillKeys = table.keys(spawnedNPC.skills)
	--debug.log(skillKeys[0])
	--debug.log(skillKeys[1])
	spawnedNPC.skills[1] = newSkills[1]
	spawnedNPC.skills[2] = newSkills[2]
	spawnedNPC.skills[3] = newSkills[3]
	spawnedNPC.skills[4] = newSkills[4]
	spawnedNPC.skills[5] = newSkills[5]
	spawnedNPC.skills[6] = newSkills[6]
	spawnedNPC.skills[7] = newSkills[7]
	spawnedNPC.skills[8] = newSkills[8]
	spawnedNPC.skills[9] = newSkills[9]
	spawnedNPC.skills[10] = newSkills[10]
	spawnedNPC.skills[11] = newSkills[11]
	spawnedNPC.skills[12] = newSkills[12]
	spawnedNPC.skills[13] = newSkills[13]
	spawnedNPC.skills[14] = newSkills[14]
	spawnedNPC.skills[15] = newSkills[15]
	spawnedNPC.skills[16] = newSkills[16]
	spawnedNPC.skills[17] = newSkills[17]
	spawnedNPC.skills[18] = newSkills[18]
	spawnedNPC.skills[19] = newSkills[19]
	spawnedNPC.skills[20] = newSkills[20]
	spawnedNPC.skills[21] = newSkills[21]
	spawnedNPC.skills[22] = newSkills[22]
	spawnedNPC.skills[23] = newSkills[23]
	spawnedNPC.skills[24] = newSkills[24]
	spawnedNPC.skills[25] = newSkills[25]
	spawnedNPC.skills[26] = newSkills[26]
	spawnedNPC.skills[27] = newSkills[0]

	spawnedNPC.attributes[8] = newAttributes[0]
	spawnedNPC.attributes[1] = newAttributes[1]
	spawnedNPC.attributes[2] = newAttributes[2]
	spawnedNPC.attributes[3] = newAttributes[3]
	spawnedNPC.attributes[4] = newAttributes[4]
	spawnedNPC.attributes[5] = newAttributes[5]
	spawnedNPC.attributes[6] = newAttributes[6]
	spawnedNPC.attributes[7] = newAttributes[7]

	spawnedNPC.health = outputTableStats["Health"]
	spawnedNPC.magicka = outputTableStats["Magicka"]
	spawnedNPC.fatigue = outputTableStats["Fatigue"]

	npcRef = tes3.createReference({object=spawnedNPC, position=coordinates, orientation=0, cell=cell})

	fillContainerWithItems(npcRef, outputTableItems)

	counter = 0
	while counter < outputTableSpells["TotalSpells"] do
		local spell1 = tes3.createObject({ objectType = tes3.objectType.spell })
    	--tes3.setSourceless(spell1)

    	baseString = "Spell" .. tostring(counter)

    	--tes3.messageBox("Check1")
    	nameVar = table.get(outputTableSpells, baseString .. "Name", "NOTFOUND")
    	if string.len(nameVar) > 31 then 
    		nameVar = string.sub(nameVar,0,30)
    	end
    	lastEffect = table.get(outputTableSpells, baseString .. "LastEffectNumber", 0)
    	spell1.name = nameVar
    	spell1.magickaCost = table.get(outputTableSpells, baseString .. "Cost", 5)
    	spell1.castType = table.get(outputTableSpells, baseString .. "Type", 0)
		--tes3.messageBox("Check2")
		maxEffects = 8
		extraEffect = 8
		if lastEffect > 7 then
			lastEffect = 7
		end
		numEffects = lastEffect + 1

		fillMagicEffects(spell1,outputTableSpells,baseString, lastEffect, numEffects)

		if spell1.effects[1].id == -1 then
			--tes3.messageBox("The imported spell has no valid effects!")
			return
		end
		tes3.addSpell({ reference = npcRef, spell = spell1 })

		counter = counter + 1

	end

	tes3.setAIFollow({ reference = npcRef, target = tes3.mobilePlayer})
end

local function uploadPlayerData()
	--outputTable = json.loadfile("PlayerData")
		--if (table.get(outputTable, "GameOrigin") == 0) then
		--	tes3.messageBox("The receiver's tonal resonance has already been transmitted. Receive novel tones before attempting to transmit new ones.")
		--	return
		--end

		thePlayer = tes3.mobilePlayer.object 
		SpellBook = tes3.getSpells({ target = tes3.mobilePlayer, spellType = -1, getActorSpells = true, getRaceSpells = false, getBirthsignSpells = false})

		outputTableSpells = {}

		counter = 0
		for index, spell in pairs(SpellBook) do		
			thisSpell = spell
			thisSpellType = thisSpell.castType
			thisSpellEffects = thisSpell.effects

			baseString = "Spell" .. tostring(index - 1)

			outputTableSpells[baseString .. "Name"] = thisSpell.name
			outputTableSpells[baseString .. "Type"] = thisSpellType
			outputTableSpells[baseString .. "Cost"] = thisSpell.magickaCost

			toTableMagicEffects(thisSpell, baseString, outputTableSpells)
			counter = counter + 1
		end
		outputTableSpells["TotalSpells"] = counter
		
		--tes3.messageBox("Spell registered!")
		--json.savefile("SpellData", outputTable)

		outputTableItems = {}
		table.clear(outputTableItems)

		chestRef = tes3.mobilePlayer.reference

		toTableItems(chestRef, outputTableItems)

		--json.savefile("ItemData", outputTable)

		outputTableStats = {}

		outputTableStats["Name"] = thePlayer.name 
		outputTableStats["Level"] = thePlayer.level
		

		if thePlayer.female == true then
			outputTableStats["Sex"] = 1
		else 
			outputTableStats["Sex"] = 0
		end

		outputTableStats["Race"] = thePlayer.race.name 

		thePlayer = tes3.mobilePlayer

		outputTableStats["Health"] = thePlayer.health.base
		outputTableStats["Magicka"] = thePlayer.magicka.base
		outputTableStats["Fatigue"] = thePlayer.fatigue.base

		outputTableStats["Strength"] = thePlayer.strength.base
		outputTableStats["Endurance"] = thePlayer.endurance.base
		outputTableStats["Willpower"] = thePlayer.willpower.base
		outputTableStats["Intelligence"] = thePlayer.intelligence.base
		outputTableStats["Speed"] = thePlayer.speed.base
		outputTableStats["Agility"] = thePlayer.agility.base
		outputTableStats["Personality"] = thePlayer.personality.base
		outputTableStats["Luck"] = thePlayer.luck.base

		outputTableStats["Acrobatics"] = thePlayer.acrobatics.base
		outputTableStats["Heavyarmor"] = thePlayer.heavyArmor.base
		outputTableStats["Illusion"] = thePlayer.illusion.base
		outputTableStats["Mercantile"] = thePlayer.mercantile.base
		outputTableStats["Alchemy"] = thePlayer.alchemy.base
		outputTableStats["Bluntweapon"] = thePlayer.bluntWeapon.base
		outputTableStats["Conjuration"] = thePlayer.conjuration.base
		outputTableStats["Shortblade"] = thePlayer.shortBlade.base
		outputTableStats["Security"] = thePlayer.security.base
		outputTableStats["Handtohand"] = thePlayer.handToHand.base
		outputTableStats["Alteration"] = thePlayer.alteration.base
		outputTableStats["Spear"] = thePlayer.spear.base
		outputTableStats["Mediumarmor"] = thePlayer.mediumArmor.base
		outputTableStats["Marksman"] = thePlayer.marksman.base
		outputTableStats["Enchant"] = thePlayer.enchant.base
		outputTableStats["Speechcraft"] = thePlayer.speechcraft.base
		outputTableStats["Athletics"] = thePlayer.athletics.base
		outputTableStats["Armorer"] = thePlayer.armorer.base
		outputTableStats["Mysticism"] = thePlayer.mysticism.base
		outputTableStats["Lightarmor"] = thePlayer.lightArmor.base
		outputTableStats["Destruction"] = thePlayer.destruction.base
		outputTableStats["Restoration"] = thePlayer.restoration.base
		outputTableStats["Unarmored"] = thePlayer.unarmored.base
		outputTableStats["Block"] = thePlayer.block.base
		outputTableStats["Axe"] = thePlayer.axe.base
		outputTableStats["Sneak"] = thePlayer.sneak.base
		outputTableStats["Longblade"] = thePlayer.longBlade.base

		outputTable = {}
		outputTable["Items"] = outputTableItems
		outputTable["Spells"] = outputTableSpells
		outputTable["Player"] = outputTableStats

		json.savefile("PlayerDataMW", outputTable)

		local executor = os.createProcess({command=[[python C:\NickiesData\fromMorrowindPlayer.py]]})

		tes3.messageBox("Player data registered!")
end

local function importPlayerData()
	outputTable = json.loadfile("PlayerDataOB")

	outputTableStats = outputTable["Player"]
	outputTableItems = outputTable["Items"]
	outputTableSpells = outputTable["Spells"]

	spawnedNPC = tes3.mobilePlayer.reference.baseObject

	npcRef = tes3.mobilePlayer.reference

	spawnedNPC.name = outputTableStats["Name"]
	command1 = "player->SetLevel " .. tostring(outputTableStats["Level"])
	tes3.runLegacyScript({command=command1})

	newSkills = {outputTableStats["Block"],
		outputTableStats["Armorer"],
		outputTableStats["Mediumarmor"],
		outputTableStats["Heavyarmor"],
		outputTableStats["Bluntweapon"],
		outputTableStats["Longblade"],
		outputTableStats["Axe"],
		outputTableStats["Spear"],
		outputTableStats["Athletics"],
		outputTableStats["Enchant"],
		outputTableStats["Destruction"],
		outputTableStats["Alteration"],
		outputTableStats["Illusion"],
		outputTableStats["Conjuration"],
		outputTableStats["Mysticism"],
		outputTableStats["Restoration"],
		outputTableStats["Alchemy"],
		outputTableStats["Unarmored"],
		outputTableStats["Security"],
		outputTableStats["Sneak"],
		outputTableStats["Acrobatics"],
		outputTableStats["Lightarmor"],
		outputTableStats["Shortblade"],
		outputTableStats["Marksman"],
		outputTableStats["Mercantile"],
		outputTableStats["Speechcraft"],
		outputTableStats["Handtohand"]}
	newAttributes = {outputTableStats["Strength"], outputTableStats["Intelligence"], outputTableStats["Willpower"], outputTableStats["Agility"], outputTableStats["Speed"], outputTableStats["Endurance"], outputTableStats["Personality"], outputTableStats["Luck"]}

	--skillKeys = table.keys(spawnedNPC.skills)
	--debug.log(skillKeys[0])
	--debug.log(skillKeys[1])
	tes3.setStatistic({reference = npcRef, name = "block", value = outputTableStats["Block"] })
	tes3.setStatistic({reference = npcRef, name = "armorer", value = outputTableStats["Armorer"] })
	tes3.setStatistic({reference = npcRef, name = "mediumArmor", value = outputTableStats["Mediumarmor"] })
	tes3.setStatistic({reference = npcRef, name = "heavyArmor", value = outputTableStats["Heavyarmor"] })
	tes3.setStatistic({reference = npcRef, name = "bluntWeapon", value = outputTableStats["Bluntweapon"] })
	tes3.setStatistic({reference = npcRef, name = "longBlade", value = outputTableStats["Longblade"] })
	tes3.setStatistic({reference = npcRef, name = "axe", value = outputTableStats["Axe"] })
	tes3.setStatistic({reference = npcRef, name = "spear", value = outputTableStats["Spear"] })
	tes3.setStatistic({reference = npcRef, name = "athletics", value = outputTableStats["Athletics"] })
	tes3.setStatistic({reference = npcRef, name = "enchant", value = outputTableStats["Enchant"] })
	tes3.setStatistic({reference = npcRef, name = "destruction", value = outputTableStats["Destruction"] })
	tes3.setStatistic({reference = npcRef, name = "alteration", value = outputTableStats["Alteration"] })
	tes3.setStatistic({reference = npcRef, name = "illusion", value = outputTableStats["Illusion"] })
	tes3.setStatistic({reference = npcRef, name = "conjuration", value = outputTableStats["Conjuration"] })
	tes3.setStatistic({reference = npcRef, name = "mysticism", value = outputTableStats["Mysticism"] })
	tes3.setStatistic({reference = npcRef, name = "restoration", value = outputTableStats["Restoration"] })
	tes3.setStatistic({reference = npcRef, name = "alchemy", value = outputTableStats["Alchemy"] })
	tes3.setStatistic({reference = npcRef, name = "unarmored", value = outputTableStats["Unarmored"] })
	tes3.setStatistic({reference = npcRef, name = "security", value = outputTableStats["Security"] })
	tes3.setStatistic({reference = npcRef, name = "sneak", value = outputTableStats["Sneak"] })
	tes3.setStatistic({reference = npcRef, name = "acrobatics", value = outputTableStats["Acrobatics"] })
	tes3.setStatistic({reference = npcRef, name = "lightArmor", value = outputTableStats["Lightarmor"] })
	tes3.setStatistic({reference = npcRef, name = "shortBlade", value = outputTableStats["Shortblade"] })
	tes3.setStatistic({reference = npcRef, name = "marksman", value = outputTableStats["Marksman"] })
	tes3.setStatistic({reference = npcRef, name = "mercantile", value = outputTableStats["Mercantile"] })
	tes3.setStatistic({reference = npcRef, name = "speechcraft", value = outputTableStats["Speechcraft"] })
	tes3.setStatistic({reference = npcRef, name = "handToHand", value = outputTableStats["Handtohand"] })

	tes3.setStatistic({reference = npcRef, name = "strength", value = outputTableStats["Strength"] })
	tes3.setStatistic({reference = npcRef, name = "endurance", value = outputTableStats["Endurance"] })
	tes3.setStatistic({reference = npcRef, name = "intelligence", value = outputTableStats["Intelligence"] })
	tes3.setStatistic({reference = npcRef, name = "willpower", value = outputTableStats["Willpower"] })
	tes3.setStatistic({reference = npcRef, name = "speed", value = outputTableStats["Speed"] })
	tes3.setStatistic({reference = npcRef, name = "agility", value = outputTableStats["Agility"] })
	tes3.setStatistic({reference = npcRef, name = "personality", value = outputTableStats["Personality"] })
	tes3.setStatistic({reference = npcRef, name = "luck", value = outputTableStats["Luck"] })
	

	tes3.setStatistic({reference = npcRef, name = "health", value = outputTableStats["Health"] })
	tes3.setStatistic({reference = npcRef, name = "magicka", value = outputTableStats["Magicka"] })
	tes3.setStatistic({reference = npcRef, name = "fatigue", value = outputTableStats["Fatigue"] })

	 

	chestItems = spawnedNPC.inventory.items

	for _, itemStack in pairs(chestItems) do
		item = itemStack.object
		thisCount = itemStack.count
		tes3.removeItem({reference=npcRef, item = item, count = thisCount})
	end

	fillContainerWithItems(npcRef, outputTableItems)

	counter = 0
	while counter < outputTableSpells["TotalSpells"] do
		local spell1 = tes3.createObject({ objectType = tes3.objectType.spell })
    	--tes3.setSourceless(spell1)

    	baseString = "Spell" .. tostring(counter)

    	--tes3.messageBox("Check1")
    	nameVar = table.get(outputTableSpells, baseString .. "Name", "NOTFOUND")
    	if string.len(nameVar) > 31 then 
    		nameVar = string.sub(nameVar,0,30)
    	end
    	lastEffect = table.get(outputTableSpells, baseString .. "LastEffectNumber", 0)
    	spell1.name = nameVar
    	spell1.magickaCost = table.get(outputTableSpells, baseString .. "Cost", 5)
    	spell1.castType = table.get(outputTableSpells, baseString .. "Type", 0)
		--tes3.messageBox("Check2")
		maxEffects = 8
		extraEffect = 8
		if lastEffect > 7 then
			lastEffect = 7
		end
		numEffects = lastEffect + 1

		fillMagicEffects(spell1,outputTableSpells,baseString, lastEffect, numEffects)

		if spell1.effects[1].id == -1 then
			--tes3.messageBox("The imported spell has no valid effects!")
			return
		end
		tes3.addSpell({ reference = npcRef, spell = spell1 })

		counter = counter + 1

	end

end

onButtonPressed1 = function(e)
	if e.button == 0 then
        uploadPlayerData()
    elseif e.button == 1 then 
    	outputTable = json.loadfile("PlayerDataOB")
		spawnNPCFromJSON(outputTable, tes3.getPlayerCell(), tes3.getPlayerEyePosition())
    elseif e.button == 2 then 
    	outputTable = json.loadfile("PlayerDataMW")
    	outputTableStats = outputTable["Player"]
    	savedName = outputTableStats["Name"]
    	playerName = tes3.mobilePlayer.object.name
    	if savedName ~= playerName then 
			spawnNPCFromJSON(outputTable, tes3.getPlayerCell(), tes3.getPlayerEyePosition())
		else 
			tes3.messageBox("The saved Hero's tonal signature is identical to your own!")
		end
    elseif e.button == 3 then
    	local executor = os.createProcess({command=[[python C:\NickiesData\toMorrowindPlayer.py]]})
        tes3.messageBox({
	        message = "Are you sure? This cannot be undone and you should complete the full process once beginning",
	        buttons = { "Yes", "No"},
	        showInDialog = false,
	        callback = onButtonPressed2,
	    })
	else 
		-- do nothing
    end
end

onButtonPressed2 = function(e)
	if e.button == 0 then
         tes3.messageBox({
	        message = "You will now go through the race, class, and birthsign menus, setting your appearance, class, and birthsign to your liking -- then the imported stats, items, and spells will be applied. ",
	        buttons = { "Begin"},
	        showInDialog = false,
	        callback = onButtonPressed3,
	    })
    elseif e.button == 1 then 
    	-- Do Nothing
	else 
		-- do nothing
    end
end

charGenMenuTracker = -1

simulateCallback = function(e)
	if charGenMenuTracker == 0 then 
		tes3.runLegacyScript({command="enableNameMenu"})
		charGenMenuTracker = 1
	elseif charGenMenuTracker == 1 then 
		tes3.runLegacyScript({command="enableRaceMenu"})
		charGenMenuTracker = 2
	elseif charGenMenuTracker == 2 then 
		tes3.runLegacyScript({command="enableClassMenu"})
		charGenMenuTracker = 3
	elseif charGenMenuTracker == 3 then 
		tes3.runLegacyScript({command="enableBirthMenu"})
		charGenMenuTracker = 4
	elseif charGenMenuTracker == 4 then 
		local executor = os.createProcess({command=[[python C:\NickiesData\toMorrowindPlayer.py]]})
		importPlayerData()
		charGenMenuTracker = 5
	elseif charGenMenuTracker == 5 then 
		event.unregister(tes3.event.simulate, simulateCallback)
	end
end


onButtonPressed3 = function(e)
	if e.button == 0 then
		charGenMenuTracker = 0
		event.register(tes3.event.simulate, simulateCallback)
	end
end

local function onDialogueEnvironmentCreated(e)
    -- Cache the environment variables outside the function for easier access.
    -- Dialogue scripters shouldn't have to constantly pass these to the functions anyway.
    local env = e.environment
    local reference = env.reference
    local dialogue = env.dialogue
    local info = env.info


    function env.recordBossDisarmed()
		outputTable = json.loadfile("BossData")
		if outputTable["Boss"] == nil then 
			outputTable["Boss"] = {}
		end
		outputTable2 = outputTable["Boss"]
		outputTable2["BossDisarmed"] = 1 
		json.savefile("BossData", outputTable)

		BossDisarmed = 1
	end
end
event.register(tes3.event.dialogueEnvironmentCreated, onDialogueEnvironmentCreated)

local function consoleReferenceChangedCallback(e)
	if e.reference == nil then 
		return 
	end
	if e.reference == tes3.getReference("=NickiesCGInvader") then
		tes3.setStatistic({
			    reference = tes3.mobilePlayer,
			    name = "health",
			    current = 0
			})
		tes3.newGame()
	end
end

event.register(tes3.event.consoleReferenceChanged, consoleReferenceChangedCallback)

local function nickiesOrgnumCofferCallback(e)
    local timer = e.timer
    local data = timer.data
    local currentTimestamp = tes3.getSimulationTimestamp()

    -- We are sure that the timer.data ~= nil since we
    -- created that table in timer.start function.
    -- So, lets disable the warnings for a bit.
    ---@diagnostic disable:need-check-nil
    originalItem = tes3.getObject("Gold001")
	tes3.addItem({reference=tes3.mobilePlayer, item=originalItem, count=100})
    ---@diagnostic enable:need-check-nil

    -- Save this to the data table on the timer
    data.lastIterationTimestamp = currentTimestamp
end



function recordBossDisarmed()
	outputTable = json.loadfile("BossData")
	if outputTable["Boss"] == nil then 
		outputTable["Boss"] = {}
	end
	outputTable2 = outputTable["Boss"]
	outputTable2["BossDisarmed"] = 1 
	json.savefile("BossData", outputTable)

	BossDisarmed = 1
end

function disarmBoss()
	tes3.dropItem({reference=tes3.getReference("=NickiesCGInvader"),item="=InvaderAxe"})
	recordBossDisarmed()

end

function recordBossOffHandHurt()
	outputTable = json.loadfile("BossData")
	if outputTable["Boss"] == nil then 
		outputTable["Boss"] = {}
	end
	outputTable2 = outputTable["Boss"]
	outputTable2["BossOffhandHurt"] = 1 
	json.savefile("BossData", outputTable)

	BossOffhandHurt = 1
end

function hurtBossOffHand()
	tes3.dropItem({reference=tes3.getReference("=NickiesCGInvader"),item="dwemer_shield_Invader"})
	recordBossOffHandHurt()

end

local function playMusicOnEnter(e)
	thisCell = e.cell 
	if thisCell.displayName == "Tonal Lair" then
		tes3.streamMusic({ path = "NickiesCrossGame\\Perchance.mp3", situation=0})
	elseif thisCell.displayName == "Addamasartus" then 
		outputTable = json.loadfile("BossData")
		outputTable = outputTable["Boss"]
		if outputTable["BossBeatenOB"] == 1 then 
			tes3.setGlobal("NickiesCrossSaveCheck", 2)
			object1 = tes3.getReference("==NickiesFroOblivionItemButton")
			object1:enable()
			object1 = tes3.getReference("==NickiesToOblivionItemButton")
			object1:enable()
			object1 = tes3.getReference("==NickiesToObItemChest")
			object1:enable()
			object1 = tes3.getReference("==NickiesFroOblivionSpellButton")
			object1:enable()
			object1 = tes3.getReference("==NickiesToOblivionPlayerButton")
			object1:enable()
			object1 = tes3.getReference("NickiesLairEntranceDoor")
			object1:disable()
			object1 = tes3.getReference("NickiesLairEntranceStatic")
			object1:disable()
			object1 = tes3.getReference("=NickiesBlockerRock")
			object1:disable()
			object1 = tes3.getReference("=NickiesGuidebook")
			object1:enable()
			return
		elseif outputTable["BossBeatenMW"] == 1 then 
			tes3.setGlobal("NickiesCrossSaveCheck", 1)
		end
		object1 = tes3.getReference("==NickiesFroOblivionItemButton")
		object1:disable()
		object1 = tes3.getReference("==NickiesToOblivionItemButton")
		object1:disable()
		object1 = tes3.getReference("==NickiesToObItemChest")
		object1:disable()
		object1 = tes3.getReference("==NickiesFroOblivionSpellButton")
		object1:disable()
		object1 = tes3.getReference("==NickiesToOblivionPlayerButton")
		object1:disable()
		object1 = tes3.getReference("NickiesLairEntranceDoor")
		object1:enable()
		object1 = tes3.getReference("NickiesLairEntranceStatic")
		object1:enable()
		object1 = tes3.getReference("=NickiesBlockerRock")
		object1:enable()
		object1 = tes3.getReference("=NickiesGuidebook")
		object1:disable()
	end
end


local function showMessageOnHealthLow(e)
	local health = e.mobile.health.current
	local id = e.reference.id
	if e.mobile.readiedWeapon == nil then
		weap = "none" 
	else
		weap = e.mobile.readiedWeapon.object.id
	end
	if health < 2000 then
		if id == "==NickiesBlack00000000" then
			table1 = e.reference.data
			--table1 = table.clear()
			table1["health"] = health
			table1["weap"] = weap
			tes3.messageBox("!")
			e.reference:disable()
			--json.savefile("BossData", table1)
		end
	end
end

local function registerSpellOnActivate(e)
	if (e.activator ~= tes3.player) then
		return
	end
	if (e.target.id == "=NickiesEETorchLever") then 
		outputTable = json.loadfile("BossData")
		if outputTable["Misc"] == nil then 
			outputTable["Misc"] = {}
		end
		outputTable2 = outputTable["Misc"]
		outputTable2["MWButtonPressed"] = 1 
		tes3.messageBox("A signal echoes out into the future...")
		tes3.getReference("=NickiesEETorchLever"):disable()
		json.savefile("BossData", outputTable)

		os.createProcess({command=[[python C:\NickiesData\fromMorrowindMisc.py]]})

	elseif (e.target.id == "==NickiesToOblivionSpellButton") then
		thisSpell = tes3.mobilePlayer.currentSpell
		thisSpellType = thisSpell.castType
		thisSpellEffects = thisSpell.effects
		outputTable = e.activator.data
		counter1 = 0
		table.clear(outputTable)

		outputTable1 = {}
		outputTable["Spell"] = outputTable1

		outputTable1["Spell0Name"] = thisSpell.name
		outputTable1["Spell0Type"] = thisSpellType
		outputTable1["Spell0Cost"] = thisSpell.magickaCost
		outputTable1["GameOrigin"] = 0
		outputTable1["ReceivedThis"] = 0

		toTableMagicEffects(thisSpell, "Spell0", outputTable)
		
		tes3.messageBox("Spell registered!")
		json.savefile("SpellData", outputTable)
	end
	if (e.target.id == "==NickiesFroOblivionSpellButton") then
		outputTable1 = json.loadfile("SpellData")
		outputTable = outputTable1["Spell"]
		if outputTable["GameOrigin"] == 0 then
			tes3.messageBox("You already have the transferred spell!")
			return
		end
		if outputTable["ReceivedThis"] == 1 then
			tes3.messageBox("You already have the transferred spell!")
			return
		end
		counter1 = 0

		local spell1 = tes3.createObject({ objectType = tes3.objectType.spell })
    	--tes3.setSourceless(spell1)

    	--tes3.messageBox("Check1")
    	nameVar = table.get(outputTable, "Spell0Name", "NOTFOUND")
    	if string.len(nameVar) > 31 then 
    		nameVar = string.sub(nameVar,0,30)
    	end
    	lastEffect = table.get(outputTable, "Spell0LastEffectNumber", 0)
    	spell1.name = nameVar
    	spell1.magickaCost = table.get(outputTable, "Spell0Cost", 5)
    	spell1.castType = table.get(outputTable, "Spell0Type", 0)
		--tes3.messageBox("Check2")
		maxEffects = 8
		extraEffect = 8
		if lastEffect > 7 then
			lastEffect = 7
		end
		numEffects = lastEffect + 1

		fillMagicEffects(spell1,outputTable,"Spell0", lastEffect, numEffects)

		if spell1.effects[1].id == -1 then
			tes3.messageBox("The imported spell has no valid effects!")
			return
		end
		tes3.addSpell({ reference = tes3.mobilePlayer, spell = spell1 })

		outputTable["ReceivedThis"] = 1
		json.savefile("SpellData", outputTable1)

		tes3.messageBox("Spell " .. spell1.name .. " added!")
	end
	if (e.target.id == "==NickiesToOblivionItemButton") then

		outputTable = json.loadfile("ItemData")
		if (table.get(outputTable, "GameOrigin") == 0) then
			tes3.messageBox("The receiver's tonal resonance has already been transmitted. Receive novel tones before attempting to transmit new ones.")
			return
		end

		thisSpell = tes3.mobilePlayer.currentSpell
		thisSpellType = thisSpell.castType
		thisSpellEffects = thisSpell.effects
		outputTable = {}
		counter1 = 0
		table.clear(outputTable)

		outputTable1 = {}
		outputTable["Spell"] = outputTable1

		outputTable1["Spell0Name"] = thisSpell.name
		outputTable1["Spell0Type"] = thisSpellType
		outputTable1["Spell0Cost"] = thisSpell.magickaCost
		outputTable1["GameOrigin"] = 0
		outputTable1["ReceivedThis"] = 0

		toTableMagicEffects(thisSpell, "Spell0", outputTable1)
		
		--tes3.messageBox("Spell registered!")
		json.savefile("SpellData", outputTable)

		outputTable = {}

		table.clear(outputTable)
		outputTable["GameOrigin"] = 0
		outputTable["ReceivedThis"] = 0

		chestRef = tes3.getReference("==NickiesToObItemChest")

		toTableItems(chestRef, outputTable)

		chestObj = chestRef.object
		chestInv = chestObj.inventory
		chestItems = chestInv.items

		for _, itemStack in pairs(chestItems) do
			item = itemStack.object
			thisCount = itemStack.count
			tes3.removeItem({reference=chestRef, item = item, count = thisCount})
		end

		json.savefile("ItemData", outputTable)

		local executor = os.createProcess({command=[[python C:\NickiesData\fromMorrowindItem.py]]})
		invalid = 0
	end
	if (e.target.id == "==NickiesFroOblivionItemButton") then



		outputTable = json.loadfile("ItemData")
		if (table.get(outputTable, "GameOrigin") == 0) then
			tes3.messageBox("The receiver's tonal resonance already resides in this era. Transmit tones before receiving new ones.")
			return
		end
		if (table.get(outputTable, "ReceivedThis") == 1) then
			tes3.messageBox("The receiver's tonal resonance already resides in this era. Transmit tones before receiving new ones.")
			return
		end
		counter1 = 0

		chestRef = tes3.getReference("==NickiesToObItemChest")

		fillContainerWithItems(chestRef, outputTable)

		outputTable["ReceivedThis"] = 1
		json.savefile("ItemData", outputTable)

		
		
	end
	if (e.target.id == "==NickiesToObItemChest00000000") then
		chestOpened = 1
	end
	if (e.target.id == "==NickiesToOblivionPlayerButton") then
		tes3.messageBox({
	        message = "What would you like to do?",
	        buttons = { "Record this Hero's tonal signature", "Bring a future Hero into this time", "Bring an alternate Hero\nfrom this time into this [dream]", "Imprint a future Hero's\nsignatures onto this Hero", "Exit"},
	        showInDialog = false,
	        callback = onButtonPressed1,
	    })



		--local executor = os.createProcess({command=[[python C:\NickiesData\fromMorrowindItem.py]]})
		invalid = 0
	end
end

local function loadedCallback(e)
	
	outputTable = json.loadfile("BossData")
	outputTable = outputTable["Boss"]
	if outputTable["BossBeatenOB"] == 1 then 
		tes3.setGlobal("NickiesCrossSaveCheck", 2)
		object1 = tes3.getReference("==NickiesFroOblivionItemButton")
		object1:enable()
		object1 = tes3.getReference("==NickiesToOblivionItemButton")
		object1:enable()
		object1 = tes3.getReference("==NickiesToObItemChest")
		object1:enable()
		object1 = tes3.getReference("==NickiesFroOblivionSpellButton")
		object1:enable()
		object1 = tes3.getReference("==NickiesToOblivionPlayerButton")
		object1:enable()
		object1 = tes3.getReference("NickiesLairEntranceDoor")
		object1:disable()
		object1 = tes3.getReference("NickiesLairEntranceStatic")
		object1:disable()
		object1 = tes3.getReference("=NickiesBlockerRock")
		object1:disable()
		object1 = tes3.getReference("=NickiesGuidebook")
		object1:enable()
		return
	elseif outputTable["BossBeatenMW"] == 1 then 
		tes3.setGlobal("NickiesCrossSaveCheck", 1)
	end
	object1 = tes3.getReference("==NickiesFroOblivionItemButton")
	object1:disable()
	object1 = tes3.getReference("==NickiesToOblivionItemButton")
	object1:disable()
	object1 = tes3.getReference("==NickiesToObItemChest")
	object1:disable()
	object1 = tes3.getReference("==NickiesFroOblivionSpellButton")
	object1:disable()
	object1 = tes3.getReference("==NickiesToOblivionPlayerButton")
	object1:disable()
	object1 = tes3.getReference("NickiesLairEntranceDoor")
	object1:enable()
	object1 = tes3.getReference("NickiesLairEntranceStatic")
	object1:enable()
	object1 = tes3.getReference("=NickiesBlockerRock")
	object1:enable()
	object1 = tes3.getReference("=NickiesGuidebook")
	object1:disable()
end

event.register(tes3.event.loaded, loadedCallback)

onButtonPressed10 = function(e)
	player1 = tes3.mobilePlayer
	if e.button == 0 then
         stat = player1.intelligence.current + (player1.luck.current / 10)
         if stat > 100 then 
         	tes3.messageBox({
		        message = "You successfully counter the Invader's tones with your own!",
		        showInDialog = false,
		        callback = onButtonPressed10,
		    })
		    tes3.modStatistic({
			    reference = tes3.mobilePlayer,
			    name = "magicka",
			    current = -100
			})
         else
         	tes3.messageBox({
		        message = "You fail to generate the necessary counter-tones, and the Invader's attack hits you!",
		        showInDialog = false,
		        callback = onButtonPressed10,
		    })
		    tes3.modStatistic({
			    reference = tes3.mobilePlayer,
			    name = "magicka",
			    current = -100
			})
			tes3.modStatistic({
			    reference = tes3.mobilePlayer,
			    name = "health",
			    current = -250
			})
			tes3.playAnimation({reference=tes3.mobilePlayer, group="hit5",loopcount="0"})
         end
    elseif e.button == 1 then 
    	stat = player1.willpower.current + (player1.luck.current / 10)
         if stat > 100 then 
         	if BossDisarmed == 1 then 
	         	tes3.messageBox({
			        message = "You charge through the nascent tones with determination and attack!",
			        showInDialog = false,
			        callback = onButtonPressed10,
			    })
			    tes3.modStatistic({
				    reference = tes3.mobilePlayer,
				    name = "fatigue",
				    current = -100
				})
				tes3.modStatistic({
				    reference = tes3.mobilePlayer,
				    name = "health",
				    current = -50
				})
				tes3.modStatistic({
				    reference = tes3.getReference("=NickiesCGInvader"),
				    name = "health",
				    current = -200
				})
				tes3.playAnimation({reference=tes3.getReference("=NickiesCGInvader"), group="hit5",loopcount="0"})

			else
				tes3.messageBox({
			        message = "You charge through the nascent tones with determination and attack, disarming the surprised Invader!",
			        showInDialog = false,
			        callback = onButtonPressed10,
			    })
			    tes3.modStatistic({
				    reference = tes3.mobilePlayer,
				    name = "fatigue",
				    current = -100
				})
				tes3.modStatistic({
				    reference = tes3.mobilePlayer,
				    name = "health",
				    current = -50
				})
				tes3.modStatistic({
				    reference = tes3.getReference("=NickiesCGInvader"),
				    name = "health",
				    current = -200
				})
				disarmBoss()
				tes3.playAnimation({reference=tes3.getReference("=NickiesCGInvader"), group="hit5",loopcount="0"})

			end
         else
         	tes3.messageBox({
		        message = "You stumble and fail to charge through the nascent tones, and the Invader's attack hits you!",
		        showInDialog = false,
		        callback = onButtonPressed10,
		    })
		    tes3.modStatistic({
			    reference = tes3.mobilePlayer,
			    name = "fatigue",
			    current = -100
			})
			tes3.modStatistic({
			    reference = tes3.mobilePlayer,
			    name = "health",
			    current = -200
			})
			tes3.playAnimation({reference=tes3.mobilePlayer, group="hit5",loopcount="0"})
         end
	else 
		-- do nothing
    end
end

onButtonPressed11 = function(e)
	player1 = tes3.mobilePlayer
	if e.button == 0 then
         stat = player1.speed.current + (player1.luck.current / 10)
         if stat > 100 then 
         	if BossOffhandHurt == 0 then 
	         	tes3.messageBox({
			        message = "You swiftly step back, avoiding his knife and striking his off-hand!",
			        showInDialog = false,
			        callback = onButtonPressed10,
			    })
			    tes3.modStatistic({
				    reference = tes3.mobilePlayer,
				    name = "fatigue",
				    current = -50
				})
				tes3.modStatistic({
				    reference = tes3.getReference("=NickiesCGInvader"),
				    name = "health",
				    current = -200
				})
				tes3.playAnimation({reference=tes3.getReference("=NickiesCGInvader"), group="hit5",loopcount="0"})
				hurtBossOffHand()

			else
				tes3.messageBox({
			        message = "You swiftly step back, avoiding his knife and striking him!",
			        showInDialog = false,
			        callback = onButtonPressed10,
			    })
			    tes3.modStatistic({
				    reference = tes3.mobilePlayer,
				    name = "fatigue",
				    current = -50
				})
				tes3.modStatistic({
				    reference = tes3.getReference("=NickiesCGInvader"),
				    name = "health",
				    current = -200
				})
				tes3.playAnimation({reference=tes3.getReference("=NickiesCGInvader"), group="hit5",loopcount="0"})
			end
		else
         	tes3.messageBox({
		        message = "You're not quick enough, and the Invader's knife buries into your chest!",
		        showInDialog = false,
		        callback = onButtonPressed10,
		    })
			tes3.modStatistic({
			    reference = tes3.mobilePlayer,
			    name = "health",
			    current = -250
			})
			tes3.playAnimation({reference=tes3.mobilePlayer, group="hit5",loopcount="0"})
         end
    elseif e.button == 1 then 
    	stat = player1.endurance.current + (player1.luck.current / 10)
         if stat > 100 then 
         	if BossDisarmed == 1 then 
	         	tes3.messageBox({
			        message = "You grunt as the Invader's knife hits your chest, but at the same time you land a powerful attack of your own!",
			        showInDialog = false,
			        callback = onButtonPressed10,
			    })
			    tes3.modStatistic({
				    reference = tes3.mobilePlayer,
				    name = "health",
				    current = -100
				})
				tes3.modStatistic({
				    reference = tes3.getReference("=NickiesCGInvader"),
				    name = "health",
				    current = -250
				})
				tes3.playAnimation({reference=tes3.getReference("=NickiesCGInvader"), group="hit5",loopcount="0"})
				tes3.playAnimation({reference=tes3.mobilePlayer, group="hit5",loopcount="0"})

			else
				tes3.messageBox({
			        message = "You grunt as the Invader's knife hits your chest, but at the same time you land a powerful attack knocking the Invader's weapon out of his hand!",
			        showInDialog = false,
			        callback = onButtonPressed10,
			    })
			    tes3.modStatistic({
				    reference = tes3.mobilePlayer,
				    name = "health",
				    current = -100
				})
				tes3.modStatistic({
				    reference = tes3.getReference("=NickiesCGInvader"),
				    name = "health",
				    current = -250
				})
				tes3.playAnimation({reference=tes3.getReference("=NickiesCGInvader"), group="hit5",loopcount="0"})
				tes3.playAnimation({reference=tes3.mobilePlayer, group="hit5",loopcount="0"})
				disarmBoss()

			end
         else
         	tes3.messageBox({
		        message = "You grimace as the Invader's knife buries into your chest -- it hurts too much!",
		        showInDialog = false,
		        callback = onButtonPressed10,
		    })
		    tes3.modStatistic({
			    reference = tes3.mobilePlayer,
			    name = "health",
			    current = -250
			})
			tes3.playAnimation({reference=tes3.mobilePlayer, group="hit5",loopcount="0"})
         end
	else 
		-- do nothing
    end
end

onButtonPressed12 = function(e)
	player1 = tes3.mobilePlayer
	if e.button == 0 then
         stat = player1.agility.current + (player1.luck.current / 10)
         if stat > 100 then 
         	tes3.messageBox({
		        message = "You lean back, pulling your neck away from the Invader's grip!",
		        showInDialog = false,
		        callback = onButtonPressed10,
		    })
		    tes3.modStatistic({
			    reference = tes3.mobilePlayer,
			    name = "fatigue",
			    current = -50
			})
		else
         	tes3.messageBox({
		        message = "You're not agile enough, and the Invader's hand clenches your throat. He squeezes until your vision swims black...",
		        showInDialog = false,
		        callback = onButtonPressed10,
		    })
			tes3.modStatistic({
			    reference = tes3.mobilePlayer,
			    name = "health",
			    current = -25000
			})
         end
    elseif e.button == 1 then 
    	stat = player1.strength.current + (player1.luck.current / 10)
         if stat > 100 then 
         	if BossOffhandHurt == 1 then 
	         	tes3.messageBox({
			        message = "You clench your teeth as your fingers clamp around the Invader's forearm, and squeeze. The Invader yells in pain and releases your neck, his forearm bruised and shattered!",
			        showInDialog = false,
			        callback = onButtonPressed10,
			    })
			    tes3.modStatistic({
				    reference = tes3.mobilePlayer,
				    name = "fatigue",
				    current = -100
				})
				tes3.modStatistic({
				    reference = tes3.getReference("=NickiesCGInvader"),
				    name = "health",
				    current = -250
				})
				tes3.playAnimation({reference=tes3.getReference("=NickiesCGInvader"), group="hit5",loopcount="0"})

			else
				tes3.messageBox({
			        message = "You clench your teeth as your fingers clamp around the Invader's forearms, and squeeze. The Invader yells in pain and releases your neck, his forearm bruised and shattered!",
			        showInDialog = false,
			        callback = onButtonPressed10,
			    })
			    tes3.modStatistic({
				    reference = tes3.mobilePlayer,
				    name = "fatigue",
				    current = -100
				})
				tes3.modStatistic({
				    reference = tes3.getReference("=NickiesCGInvader"),
				    name = "health",
				    current = -250
				})
				tes3.playAnimation({reference=tes3.getReference("=NickiesCGInvader"), group="hit5",loopcount="0"})
				hurtBossOffHand()

			end
         else
         	tes3.messageBox({
		        message = "You grimace as you attempt to crush the Invader's forearm -- you just can't summon the necessary strength! Slowly, your vision swims as he crushes the life out of you...",
		        showInDialog = false,
		        callback = onButtonPressed10,
		    })
		    tes3.modStatistic({
			    reference = tes3.mobilePlayer,
			    name = "health",
			    current = -25000
			})
         end
	else 
		-- do nothing
    end
end

onButtonPressed13 = function(e)
	player1 = tes3.mobilePlayer
	if e.button == 0 then
         stat = player1.agility.current + (player1.luck.current / 10)
         if stat > 100 then 
         	tes3.messageBox({
		        message = "You lean back, pulling your neck away from the Invader's grip!",
		        showInDialog = false,
		        callback = onButtonPressed10,
		    })
		    tes3.modStatistic({
			    reference = tes3.mobilePlayer,
			    name = "fatigue",
			    current = -50
			})
		else
         	tes3.messageBox({
		        message = "You're not agile enough, and the Invader's hand clenches your throat. He squeezes until your vision swims black...",
		        showInDialog = false,
		        callback = onButtonPressed10,
		    })
			tes3.modStatistic({
			    reference = tes3.mobilePlayer,
			    name = "health",
			    current = -25000
			})
         end
    elseif e.button == 1 then 
    	stat = player1.strength.current + (player1.luck.current / 10)
         if stat > 100 then 
         	if BossDisarmed == 1 then 
	         	tes3.messageBox({
			        message = "You clench your teeth as your fingers clamp around the Invader's forearm, and squeeze. The Invader yells in pain and releases your neck, his forearm bruised and shattered!",
			        showInDialog = false,
			        callback = onButtonPressed10,
			    })
			    tes3.modStatistic({
				    reference = tes3.mobilePlayer,
				    name = "fatigue",
				    current = -100
				})
				tes3.modStatistic({
				    reference = tes3.getReference("=NickiesCGInvader"),
				    name = "health",
				    current = -250
				})
				tes3.playAnimation({reference=tes3.getReference("=NickiesCGInvader"), group="hit5",loopcount="0"})

			else
				tes3.messageBox({
			        message = "You clench your teeth as your fingers clamp around the Invader's forearms, and squeeze. The Invader yells in pain and releases your neck, his forearm bruised and shattered!",
			        showInDialog = false,
			        callback = onButtonPressed10,
			    })
			    tes3.modStatistic({
				    reference = tes3.mobilePlayer,
				    name = "fatigue",
				    current = -100
				})
				tes3.modStatistic({
				    reference = tes3.getReference("=NickiesCGInvader"),
				    name = "health",
				    current = -250
				})
				tes3.playAnimation({reference=tes3.getReference("=NickiesCGInvader"), group="hit5",loopcount="0"})
				disarmBoss()

			end
         else
         	tes3.messageBox({
		        message = "You grimace as you attempt to crush the Invader's forearm -- you just can't summon the necessary strength! Slowly, your vision swims as he crushes the life out of you...",
		        showInDialog = false,
		        callback = onButtonPressed10,
		    })
		    tes3.modStatistic({
			    reference = tes3.mobilePlayer,
			    name = "health",
			    current = -25000
			})
         end
	else 
		-- do nothing
    end
end

bossPhase1 = 0
bossPhase2 = 0
bossPhase3 = 0

local function onAttackHitCallback(e)
	target = e.targetMobile
	attacker = e.mobile
	if target == nil then
		return
	end
	targetEffects = target.activeMagicEffectList
	totalResist = 0
	totalNegate = 0
	for _, eachEffect in pairs(targetEffects) do
		if eachEffect.effectId == tes3.effect.NickiesReflectDamage then
			effectInstance = eachEffect.effectInstance
			totalResist = totalResist + effectInstance.effectiveMagnitude
		end
	end
	totalNegate = totalResist
	if totalNegate > 100 then
		totalNegate = 100
	end
	--tes3.messageBox("Total Resist: " .. tostring(totalResist))
	--tes3.messageBox("Total Negate: " .. tostring(totalNegate))
	if totalResist > 0 then
		attacker:applyDamage({damage = attacker.actionData.physicalDamage * (totalResist / 100), applyArmor = false})
    	attacker.actionData.physicalDamage = attacker.actionData.physicalDamage * ((100 - totalNegate) / 100)
    end
    --tes3.messageBox("Somehow it missed!")

    mobile = e.mobile
    if mobile.readiedWeapon ~= nil then 
    	if mobile.readiedWeapon.object == tes3.getObject("=NickiesParasiteDagger") then 
	    	tes3.modStatistic({
				    reference = mobile,
				    name = "health",
				    value = 3
				})
	    	tes3.modStatistic({
				    reference = mobile,
				    name = "magicka",
				    value = 3
				})
	    	tes3.modStatistic({
				    reference = mobile,
				    name = "fatigue",
				    value = 3
				})

	    	tes3.modStatistic({
				    reference = mobile,
				    name = "strength",
				    value = 1
				})
	    	tes3.modStatistic({
				    reference = mobile,
				    name = "endurance",
				    value = 1
				})
	    	tes3.modStatistic({
				    reference = mobile,
				    name = "intelligence",
				    value = 1
				})
	    	tes3.modStatistic({
				    reference = mobile,
				    name = "willpower",
				    value = 1
				})
	    	tes3.modStatistic({
				    reference = mobile,
				    name = "agility",
				    value = 1
				})
	    	tes3.modStatistic({
				    reference = mobile,
				    name = "speed",
				    value = 1
				})
	    	tes3.modStatistic({
				    reference = mobile,
				    name = "personality",
				    value = 1
				})
	    	tes3.modStatistic({
				    reference = mobile,
				    name = "luck",
				    value = 1
				})

	    	tes3.modStatistic({
				    reference = target,
				    name = "health",
				    value = -3
				})
	    	tes3.modStatistic({
				    reference = target,
				    name = "magicka",
				    value = -3
				})
	    	tes3.modStatistic({
				    reference = target,
				    name = "fatigue",
				    value = -3
				})

	    	tes3.modStatistic({
				    reference = target,
				    name = "strength",
				    value = -1
				})
	    	tes3.modStatistic({
				    reference = target,
				    name = "endurance",
				    value = -1
				})
	    	tes3.modStatistic({
				    reference = target,
				    name = "intelligence",
				    value = -1
				})
	    	tes3.modStatistic({
				    reference = target,
				    name = "willpower",
				    value = -1
				})
	    	tes3.modStatistic({
				    reference = target,
				    name = "agility",
				    value = -1
				})
	    	tes3.modStatistic({
				    reference = target,
				    name = "speed",
				    value = -1
				})
	    	tes3.modStatistic({
				    reference = target,
				    name = "personality",
				    value = -1
				})
	    	tes3.modStatistic({
				    reference = target,
				    name = "luck",
				    value = -1
				})
	    end
    end

    
    attacker = e.reference
    if attacker.id == "=NickiesCGInvader00000000" then 
    	attacker = e.mobile
    	
    	
    	if attacker.health.current < 4200 and bossPhase1 == 0 then 
    		attacker.actionData.physicalDamage = 0
    		bossPhase1 = 1
    		tes3.messageBox({
		        message = "The air around his hand starts to vibrate and resonate with strange tones. He's about to hit you with a strange spell!",
		        buttons = { "[Intelligence] Generate equal and opposite\ntones with your own magicka", "[Willpower] Move through the tones and attack"},
		        showInDialog = false,
		        callback = onButtonPressed10,
		    })

    	end
    	if attacker.health.current < 3600 and bossPhase2 == 0 then 
    		attacker.actionData.physicalDamage = 0
    		bossPhase2 = 1
    		tes3.messageBox({
		        message = "Smiling, the Invader reaches to his belt with his off-hand and pulls out a small knife. In a flash, he aims it directly at your chest!",
		        buttons = { "[Speed] Move out of the way and\nland a strike against his off-hand", "[Endurance] Tank the knife into your chest,\nbut use the opportunity to attack him directly"},
		        showInDialog = false,
		        callback = onButtonPressed11,
		    })
    	end
    	if attacker.health.current < 3000 and bossPhase3 == 0 then 
    		attacker.actionData.physicalDamage = 0
    		bossPhase3 = 1
    		if BossDisarmed == 1 and BossOffhandHurt == 0 then
    			tes3.messageBox({
		        message = "The Invader grimaces, and moves to grab your throat with his off-hand. He's attempting to strangle you!",
		        buttons = { "[Agility] Angle your neck away from his hand\n and avoid it", "[Strength] When he grabs your neck, seize\nhis arm and crush it with your grip strength."},
		        showInDialog = false,
		        callback = onButtonPressed12,
		    })
    		elseif BossDisarmed == 0 then 
    			tes3.messageBox({
		        message = "The Invader grimaces, and moves to grab your throat with his main-hand. He's attempting to strangle you!",
		        buttons = { "[Agility] Angle your neck away from his hand\n and avoid it", "[Strength] When he grabs your neck, seize\nhis arm and crush it with your grip strength."},
		        showInDialog = false,
		        callback = onButtonPressed13,
		    })
    		end
    	end
    elseif e.targetReference.id == "=NickiesCGInvader00000000" then 
    	if target.health.current > 4200 then 
    		bossPhase1 = 0
    		bossPhase2 = 0
    		bossPhase3 = 0
    		BossOffhandHurt = 0
    		if e.targetReference.object:hasItemEquipped("=InvaderAxe") then
    			BossDisarmed = 0
    		end
    	end
    	if target.health.current < 2400 then 
    		for _, activeMagicEffect in pairs(e.mobile.activeMagicEffectList) do
	    		activeMagicEffect.instance:playVisualEffect{
	                   effectIndex = 0,
	                   position = e.mobile.position,
	                   visual = "VFX_Summon_end"
	               }
	           	break
	       	end
	       	outputTable = json.loadfile("BossData")
			if outputTable["Boss"] == nil then 
				outputTable["Boss"] = {}
			end
			outputTable2 = outputTable["Boss"]
			outputTable2["BossHealth"] = target.health.current
			outputTable2["BossBeatenMW"] = 1 
			if e.targetReference.object:hasItemEquipped("dwemer_boots") then
    			outputTable2["HasBoots"] = 1
    		else 
    			outputTable2["HasBoots"] = 0
    		end
    		if e.targetReference.object:hasItemEquipped("dwemer_greaves") then
    			outputTable2["HasGreaves"] = 1
    		else 
    			outputTable2["HasGreaves"] = 0
    		end
    		if e.targetReference.object:hasItemEquipped("dwemer_cuirass") then
    			outputTable2["HasCuirass"] = 1
    		else 
    			outputTable2["HasCuirass"] = 0
    		end
    		if e.targetReference.object:hasItemEquipped("dwemer_bracer_left") or e.targetReference.object:hasItemEquipped("dwemer_bracer_right") then
    			outputTable2["HasGauntlet"] = 1
    		else 
    			outputTable2["HasGauntlet"] = 0
    		end
    		outputTable2["BossDisarmed"] = BossDisarmed
    		outputTable2["BossOffhandHurt"] = BossOffhandHurt
			json.savefile("BossData", outputTable)

			tes3.messageBox("You're more annoying that I thought. Fine -- you've beaten me here. Until I come again, hero...")
			e.targetReference:disable()
			tes3.streamMusic({ path = "NickiesCrossGame\\Perchance.mp3", situation=0})
			tes3.updateJournal({ id = "=NickiesCrossGameQuest", index = 30, showMessage = true })
			local executor = os.createProcess({command=[[python C:\NickiesData\fromMorrowindMisc.py]]})

   		end
   	end
end


local function onBossDeath(e)
	local boss = e.reference
	if boss.id ~= "NickiesCGInvader00000000" then
		return 
	end
	boss:disable()

	outputTable = json.loadfile("BossData")
	if outputTable["Boss"] == nil then 
		outputTable["Boss"] = {}
	end
	outputTable = outputTable["Boss"]
	outputTable["BossBeatenMW"] = 1 
	json.savefile("BossData", outputTable)

	tes3.messageBox("You're more annoying that I thought. Fine -- you've beaten me here. A little rest and recovery in the future, where you can never reach me, is all I need before I return and destroy you...")
end

local function onChestClosed(e)
	if (e.reference.id == "==NickiesToObItemChest00000000") then
		chestOpened = 0

	end
end

DoOnce = 0

local function closeMenu()
    local topMenu = tes3ui.registerID("MenuContents")
    local button = tes3ui.registerID("MenuContents_closebutton")
    local topMenu = tes3ui.findMenu(topMenu)

    local closeButton = topMenu:findChild(button)
    if closeButton.visible then
        closeButton:triggerEvent("mouseClick")
    end
    return

end

local function onItemUpdated(e)
	if invalid == 1 and DoOnce == 0 and chestOpened == 1 and tes3ui.findHelpLayerMenu("CursorIcon"):getPropertyObject("MenuInventory_Thing", "tes3inventoryTile") ~= nil then
		DoOnce = 1
		tes3.messageBox("Grabbed something!!!")
		c = tes3ui.findHelpLayerMenu("CursorIcon"):getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
       	chestRef = tes3.getReference("==NickiesToObItemChest00000000")
       	
       	closeMenu()
       	--rClickKey = tes3.getInputBinding(18).code
       	--tes3.tapKey(rClickKey)

       	tes3.transferItem({from= tes3.player, to=chestRef, item=c.item})	
       	tes3.messageBox("You cannot remove items resulting in an invalid item configuration!")
       	return
	end
	if (chestOpened == 1 and e.menu.name == "MenuContents") then
		outputTable = {}

		chestRef = tes3.getReference("==NickiesToObItemChest00000000")

		table.clear(outputTable)
		outputTable["GameOrigin"] = 0
		outputTable["ReceivedThis"] = 0

		toTableItems(chestRef, outputTable)

		--tes3.messageBox("Items registered!")
		json.savefile("ItemData", outputTable)
	end
end

local function updateChest(e)
	if (e.menuMode == true and chestOpened == 1) then 
		outputTable = json.loadfile("ItemData")
		if (table.get(outputTable, "GameOrigin") ~= 0) then
			chestRef = tes3.getReference("==NickiesToObItemChest00000000")
			fillContainerWithItems(chestRef, outputTable)
			tes3ui.updateContentsMenuTiles()
		end
	end
end

event.register(tes3.event.attackHit, onAttackHitCallback)
--event.register(tes3.event.damaged, showMessageOnHealthLow)
event.register(tes3.event.activate, registerSpellOnActivate)
event.register(tes3.event.cellChanged, playMusicOnEnter)
--event.register(tes3.event.death, onBossDeath)
--event.register(tes3.event.containerClosed, onChestClosed)
--event.register(tes3.event.itemTileUpdated, onItemUpdated)
--event.register(tes3.event.enterFrame, updateChest)
