local config = require("ndvr.equipment_menu.config.config")

local this = {}

function this.getArmorSlots()
	local customOrder = {
		[tes3.armorSlot.helmet] = 0,
		[tes3.armorSlot.leftPauldron] = 1,
		[tes3.armorSlot.rightPauldron] = 2,
		[tes3.armorSlot.cuirass] = 3,
		[tes3.armorSlot.leftBracer] = 4,
		[tes3.armorSlot.rightBracer] = 5,
		[tes3.armorSlot.leftGauntlet] = 6,
		[tes3.armorSlot.rightGauntlet] = 7,
		[tes3.armorSlot.greaves] = 8,
		[tes3.armorSlot.boots] = 9,
	}

	-- for other slots
	local fallbackIndex = 100

	armorSlots = {}

	for key, value in pairs(tes3.armorSlot) do
		-- skip shield, we'll show it in weapon table
        if type(value) == "number" and value ~= tes3.armorSlot.shield then 
            local readable = key:gsub("([A-Z])", " %1")
            readable = readable:gsub("^%l", string.upper)

			local order = customOrder[value]
			if not order then
				order = fallbackIndex
				fallbackIndex = fallbackIndex + 1
			end

            table.insert(armorSlots, { 
				name = readable, 
				id = value, 
				type = "armor",
				order = order
			})
        end
    end

	table.sort(armorSlots, function(a, b)
		return a.order < b.order
	end)

	--table.sort(armorSlots, function(a, b) return a.id < b.id end)
	return armorSlots
end

-- Получаем все кольца, надетые на персонаже
function this.getEquippedRings()
	local actor = tes3.player
	if not actor then return end

	local rings = {}
	for _, stack in pairs(actor.object.equipment) do
		if stack.object.objectType == tes3.objectType.clothing
			and stack.object.slot == tes3.clothingSlot.ring
		then
			table.insert(rings, stack)
		end
	end
	return rings
end

-- Добавляем в таблицу слоты для колец
function this.addRingSlots(clothingSlots, customOrder)
	local actor = tes3.player
	if not actor then return end

	local rings = this.getEquippedRings()

	local ringCount = #rings
	for i = 1, ringCount do
		table.insert(clothingSlots, {
			name = "Ring " .. i,
			id = tes3.clothingSlot.ring,
			type = "clothing",
			order = customOrder[tes3.clothingSlot.ring] + i,
			item = rings[i],
		})
	end

	-- Добавим пустые слоты, если колец меньше 2
	for i = ringCount + 1, 2 do
		table.insert(clothingSlots, {
			name = "Ring " .. i,
			id = tes3.clothingSlot.ring,
			type = "clothing",
			order = customOrder[tes3.clothingSlot.ring] + i,
			item = nil
		})
	end

	return clothingSlots
end

function this.getClothingSlots(excludeRings)
	local customOrder = {
		[tes3.clothingSlot.robe] = 0,
		[tes3.clothingSlot.shirt] = 1,
		[tes3.clothingSlot.belt] = 2,
		[tes3.clothingSlot.leftGlove] = 3,
		[tes3.clothingSlot.rightGlove] = 4,
		[tes3.clothingSlot.pants] = 5,
		[tes3.clothingSlot.skirt] = 6,
		[tes3.clothingSlot.shoes] = 7,
		[tes3.clothingSlot.ring] = 8,
		[tes3.clothingSlot.amulet] = 30, -- set to 30 to give more space for rings
	}

	-- for other slots
	local fallbackIndex = 100

    if excludeRings == nil then
        excludeRings = false
    end

    clothingSlots = {}

    for key, value in pairs(tes3.clothingSlot) do
        if type(value) == "number" and (not excludeRings or value ~= tes3.clothingSlot.ring) then
            local readable = key:gsub("([A-Z])", " %1")
            readable = readable:gsub("^%l", string.upper)

			local order = customOrder[value]
			if not order then
				order = fallbackIndex
				fallbackIndex = fallbackIndex + 1
			end

            table.insert(clothingSlots, { 
				name = readable, 
				id = value, 
				type = "clothing",
				order = order 
			})
        end
    end

	if excludeRings then
		clothingSlots = this.addRingSlots(clothingSlots, customOrder)
	end

	table.sort(clothingSlots, function(a, b)
		return a.order < b.order
	end)

	--table.sort(clothingSlots, function(a, b) return a.id < b.id end)

	return clothingSlots
end

function this.getWeaponSlots()
	local weaponSlots = {}

	local mobile = tes3.mobilePlayer
	if not mobile then return weaponSlots end

	-- weird bug: readiedWeapon won't update in 'equipped' event
	-- using getEquippedItem instead
	--local weaponItem = mobile.readiedWeapon

	local weaponItem = tes3.getEquippedItem{ actor = tes3.player, objectType = tes3.objectType.weapon }
	local shieldItem = mobile.readiedShield

	local weapon = weaponItem and weaponItem.object
	local isTwoHanded = weapon and (weapon.isTwoHanded or weapon.isRanged) and not weapon.isProjectile

	-- Оружие
	local weaponSlot = {
		name = "Weapon",
		id = "weapon",
		type = "weapon",
		item = weaponItem
	}

	table.insert(weaponSlots, weaponSlot)

	-- Щит: только если оружие не двуручное
	local shieldSlot = {
		name = "Shield",
		id = "shield",
		type = "armor",
		item = nil
	}

	if isTwoHanded then
		-- twohanded tooks both slots
		shieldSlot.item = weaponItem
	elseif shieldItem then
		shieldSlot.item = shieldItem
	end

	table.insert(weaponSlots, shieldSlot)

	if config.showAmmoSlot then
		local ammoItem = tes3.getEquippedItem{ actor = tes3.player, objectType = tes3.objectType.ammunition }

		local ammoSlot = {
			name = "Ammo",
			id = "ammo",
			type = "ammo",
			item = ammoItem
		}

		table.insert(weaponSlots, ammoSlot)
	end

	return weaponSlots
end

function this.toColorArray(colorTable)
    return {
        colorTable.r or 1.0,
        colorTable.g or 1.0,
        colorTable.b or 1.0
    }
end

function this.getColor(conditionPercent, colorsTable)
	local over80color, over50color, over25color, below25color = table.unpack(colorsTable)

	if conditionPercent >= 80 then
		return this.toColorArray(over80color)
	end
	if conditionPercent >= 50 then
		return this.toColorArray(over50color)
	end
	if conditionPercent >= 25 then
		return this.toColorArray(over25color)
	end
	
	return this.toColorArray(below25color)
end

function this.getEffectiveEquippedItem(overrideSlotMap, slotId, objectType)
	local overrideSlots = overrideSlotMap[slotId]
	if overrideSlots then
		for _, slot in ipairs(overrideSlots) do
			local item = tes3.getEquippedItem{
				actor = tes3.player,
				objectType = slot.type,
				slot = slot.id
			}
			if item then
				return item
			end
		end
	end

	return tes3.getEquippedItem{
		actor = tes3.player,
		objectType = objectType,
		slot = slotId
	}
end

function this.round(x)
    return math.floor(x + 0.5)
end

return this