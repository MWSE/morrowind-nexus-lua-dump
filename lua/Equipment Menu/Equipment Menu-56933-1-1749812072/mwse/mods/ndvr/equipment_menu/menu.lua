local config = require("ndvr.equipment_menu.config.config")
local utils = require("ndvr.equipment_menu.utils")
local createSlotMap = require("ndvr.equipment_menu.map")

local this = {}

function this.createTableRow(scrollPane)
	local row = scrollPane:createBlock({})
	row.flowDirection = "left_to_right"
	row.autoHeight = true
	row.widthProportional = 1.0
	row.childAlignY = 0.5
	row.paddingAllSides = 2

	return row
end

function this.addTableHeader(scrollPane, configTable)
	local row = this.createTableRow(scrollPane)

	local showIconColumn,
		showSlotNameColumn,
		showConditionColumn,
		showEnchantmentChargeColumn,
		showItemNameColumn = table.unpack(configTable)

	if showIconColumn then
		this.addItemIconHeader(row)
	end

	if showSlotNameColumn then
		this.addSlotNameHeader(row)
	end

	if showConditionColumn then
		this.addItemConditionHeader(row)
	end

	if showEnchantmentChargeColumn then
		this.addItemEnchantmentChargeHeader(row)
	end

	if showItemNameColumn then
		this.addItemNameHeader(row)
	end

	return row
end

-- cells

function this.addItemIconCell(row, item)
	local iconCell = row:createThinBorder({})
	iconCell.width = 40
	iconCell.height = 40

	if item and item.object and item.object.icon then
		if item.object.enchantment then
			local magicIcon = iconCell:createImage({
				path = "Textures\\menu_icon_magic.tga",
			})
			magicIcon.absolutePosAlignY = 0.1
		end

		local icon = iconCell:createImage({
			path = "icons\\" .. item.object.icon,
		})
		icon.absolutePosAlignX = 0.5
		icon.absolutePosAlignY = 0.5
	end
end

function this.addSlotNameCell(row, slot)
	local slotCell = row:createThinBorder({})
	slotCell.height = 40
	slotCell.width = 150
	slotCell.flowDirection = "left_to_right"
	slotCell.paddingLeft = 8
	slotCell.childAlignY = 0.5

	slotCell:createLabel({ text = slot.name })
end

function this.addItemConditionCell(row, item, colorsTable, showPercent, enableColors)
	local conditionCell = row:createThinBorder({})
	conditionCell.height = 40
	conditionCell.width = 100
	conditionCell.flowDirection = "left_to_right"
	conditionCell.paddingLeft = 8
	conditionCell.childAlignY = 0.5

	if item and item.object then
		if item.object.objectType == tes3.objectType.ammunition 
		or item.object.objectType == tes3.objectType.clothing 
		or item.object.isProjectile then
			conditionCell:createLabel{ 
				text = "-"
			}
			return
		end

		if item.object.maxCondition then
			local currentCondition = item.itemData and item.itemData.condition or 0
			local maxCondition = item.object.maxCondition

			local conditionPercent = currentCondition / maxCondition * 100

			local text = ""

			if showPercent then
				text = string.format("%d%%", utils.round(conditionPercent))
			else
				text = string.format("%d / %d", currentCondition, maxCondition)
			end

			local label = conditionCell:createLabel{ 
				text = text
			}

			if enableColors then
				local color = utils.getColor(conditionPercent, colorsTable)

				label.color = color
			end
		end
	end
end

function this.addItemEnchantmentChargeCell(row, item, colorsTable, showPercent, enableColors)
	local enchantmentChargeCell = row:createThinBorder({})
	enchantmentChargeCell.height = 40
	enchantmentChargeCell.width = 100
	enchantmentChargeCell.flowDirection = "left_to_right"
	enchantmentChargeCell.paddingLeft = 8
	enchantmentChargeCell.childAlignY = 0.5

	if item and item.object then
		if item.object.isProjectile
		or (item.object.enchantment and item.object.enchantment.castType == tes3.enchantmentType.constant)
		or not item.object.enchantment then
			enchantmentChargeCell:createLabel({ 
				text = "-"
			})
			return
		end
		
		if item.object.enchantment then
			local currentCharge = item.itemData and item.itemData.charge or 0
			local maxCharge = item.object.enchantment.maxCharge

			local chargePercent = currentCharge / maxCharge * 100

			local text = ""

			if showPercent then
				text = string.format("%d%%", utils.round(chargePercent))
			else
				text = string.format("%d / %d", currentCharge, maxCharge)
			end

			local label = enchantmentChargeCell:createLabel{
				text = text
			}
			
			if enableColors then
				local color = utils.getColor(chargePercent, colorsTable)

				label.color = color
			end
		end
	end
end

function this.addItemNameCell(row, item)
	local itemCell = row:createThinBorder({})
	itemCell.height = 40
	itemCell.flowDirection = "left_to_right"
	itemCell.widthProportional = 1.0
	itemCell.childAlignY = 0.5
	itemCell.paddingLeft = 8

	local nameText = "<empty>"
	if item and item.object and item.object.name then
		nameText = item.object.name
	end

	itemCell:createLabel({ text = nameText, wrapText = true })
end

-- headers

function this.addItemIconHeader(row)
	local iconCell = row:createThinBorder({})
	iconCell.width = 40
	iconCell.height = 40
	iconCell.flowDirection = "left_to_right"
	iconCell.paddingLeft = 2
	iconCell.childAlignY = 0.5

	iconCell:createLabel({ text = "Icon" })
end

function this.addSlotNameHeader(row)
	local slotCell = row:createThinBorder({})
	slotCell.height = 40
	slotCell.width = 150
	slotCell.flowDirection = "left_to_right"
	slotCell.paddingLeft = 8
	slotCell.childAlignY = 0.5

	slotCell:createLabel({ text = "Slot" })
end

function this.addItemConditionHeader(row)
	local conditionCell = row:createThinBorder({})
	conditionCell.height = 40
	conditionCell.width = 100
	conditionCell.flowDirection = "left_to_right"
	conditionCell.paddingLeft = 8
	conditionCell.childAlignY = 0.5

	conditionCell:createLabel({ text = "Condition" })
end

function this.addItemEnchantmentChargeHeader(row)
	local enchantmentChargeCell = row:createThinBorder({})
	enchantmentChargeCell.height = 40
	enchantmentChargeCell.width = 100
	enchantmentChargeCell.flowDirection = "left_to_right"
	enchantmentChargeCell.paddingLeft = 8
	enchantmentChargeCell.childAlignY = 0.5

	enchantmentChargeCell:createLabel({ text = "Charge" })
end

function this.addItemNameHeader(row)
	local itemCell = row:createThinBorder({})
	itemCell.height = 40
	itemCell.flowDirection = "left_to_right"
	itemCell.widthProportional = 1.0
	itemCell.childAlignY = 0.5
	itemCell.paddingLeft = 8
	
	itemCell:createLabel({ text = "Item name" })
end

-- tables

function this.addWeaponTable(equipWindowScroll, weaponSlots)
	local itemsWereShown = false

	if config.showWeaponHeader then
		local configTable = {
			config.showWeaponIconColumn,
			config.showWeaponSlotNameColumn,
			config.showWeaponConditionColumn,
			config.showWeaponEnchantmentChargeColumn,
			config.showWeaponItemNameColumn,
		}
		this.addTableHeader(equipWindowScroll, configTable)
	end

	for _, slot in ipairs(weaponSlots) do
		local item = slot.item

		local showSlot = true
		-- if "show empty slots only" mod and current slot has item equipped - skip it
		if config.showEmptySlotsOnly and item then
			showSlot = false
		end

		if showSlot then
			itemsWereShown = true

			local row = this.createTableRow(equipWindowScroll)

			if config.showWeaponIconColumn then
				this.addItemIconCell(row, item)
			end

			if config.showWeaponSlotNameColumn then
				this.addSlotNameCell(row, slot)
			end

			if config.showWeaponConditionColumn then
				local colorsTable = {
					config.weaponConditionColorExcellent,
					config.weaponConditionColorGood,
					config.weaponConditionColorPoor,
					config.weaponConditionColorBad
				}
				this.addItemConditionCell(row, item, colorsTable, config.showWeaponConditionPercent, config.enableColorsWeaponCondition)
			end

			if config.showWeaponEnchantmentChargeColumn then
				local colorsTable = {
					config.weaponEnchantmentChargeColorExcellent,
					config.weaponEnchantmentChargeColorGood,
					config.weaponEnchantmentChargeColorPoor,
					config.weaponEnchantmentChargeColorBad
				}
				this.addItemEnchantmentChargeCell(row, item, colorsTable, config.showWeaponEnchantmentChargePercent, config.enableColorsWeaponEnchantmentCharge)
			end

			if config.showWeaponItemNameColumn then
				this.addItemNameCell(row, item)
			end
		end
	end

	if not itemsWereShown and config.showEmptySlotsOnly then
		this.addAllSlotsAreFilledRow(equipWindowScroll, "weapon")
	end

	this.addTableSeparator(equipWindowScroll)
end

function this.addArmorTable(equipWindowScroll, armorSlots)
	local itemsWereShown = false

	if config.showArmorHeader then
		local configTable = {
			config.showArmorIconColumn,
			config.showArmorSlotNameColumn,
			config.showArmorConditionColumn,
			config.showArmorEnchantmentChargeColumn,
			config.showArmorItemNameColumn,
		}

		this.addTableHeader(equipWindowScroll, configTable)
	end

	for _, slot in ipairs(armorSlots) do
		-- if shoes/boots slots NOT allowed for Beast races
		if not config.showShoesBootsSlotsForBeastRaces then
			if tes3.player.object.race.isBeast and slot.id == tes3.armorSlot.boots then
				goto continue
			end
		end

		-- if item slot is in MCM's exclude list - skip
		if config.excludedArmorSlots[slot.name] then
			goto continue
		end

		local map = createSlotMap(config)
		local item = utils.getEffectiveEquippedItem(map.armorOverrideSlotMap, slot.id, tes3.objectType.armor)

		local showSlot = true
		-- if "show empty slots only" mod and current slot has item equipped - skip it
		if config.showEmptySlotsOnly and item then
			showSlot = false
		end

		if showSlot then
			itemsWereShown = true

			local row = this.createTableRow(equipWindowScroll)

			if config.showArmorIconColumn then
				this.addItemIconCell(row, item)
			end

			if config.showArmorSlotNameColumn then
				this.addSlotNameCell(row, slot)
			end

			if config.showArmorConditionColumn then
				local colorsTable = {
					config.armorConditionColorExcellent,
					config.armorConditionColorGood,
					config.armorConditionColorPoor,
					config.armorConditionColorBad
				}
				this.addItemConditionCell(row, item, colorsTable, config.showArmorConditionPercent, config.enableColorsArmorCondition)
			end

			if config.showArmorEnchantmentChargeColumn then
				local colorsTable = {
					config.armorEnchantmentChargeColorExcellent,
					config.armorEnchantmentChargeColorGood,
					config.armorEnchantmentChargeColorPoor,
					config.armorEnchantmentChargeColorBad
				}
				this.addItemEnchantmentChargeCell(row, item, colorsTable, config.showArmorEnchantmentChargePercent, config.enableColorsArmorEnchantmentCharge)
			end

			if config.showArmorItemNameColumn then
				this.addItemNameCell(row, item)
			end
		end

		::continue::
	end

	if not itemsWereShown and config.showEmptySlotsOnly then
		this.addAllSlotsAreFilledRow(equipWindowScroll, "armor")
	end

	this.addTableSeparator(equipWindowScroll)
end

function this.addClothingTable(equipWindowScroll, clothingSlots)
	local itemsWereShown = false

	if config.showClothingHeader then
		local configTable = {
			config.showClothingIconColumn,
			config.showClothingSlotNameColumn,
			config.showClothingConditionColumn,
			config.showClothingEnchantmentChargeColumn,
			config.showClothingItemNameColumn,
		}

		this.addTableHeader(equipWindowScroll, configTable)
	end

	for _, slot in ipairs(clothingSlots) do
		-- if shoes/boots slots NOT allowed for Beast races
		if not config.showShoesBootsSlotsForBeastRaces then
			if tes3.player.object.race.isBeast and slot.id == tes3.clothingSlot.shoes then
				goto continue
			end
		end

		-- if item slot is in MCM's exclude list - skip
		if config.excludedClothingSlots[slot.name] or (slot.id == tes3.clothingSlot.ring and config.excludedClothingSlots["Ring"]) then
			goto continue
		end

		local item
		if slot.id == tes3.clothingSlot.ring then
			item = slot.item
		else
			local map = createSlotMap(config)
			item = utils.getEffectiveEquippedItem(map.clothingOverrideSlotMap, slot.id, tes3.objectType.clothing)
		end

		local showSlot = true
		-- if "show empty slots only" mod and current slot has item equipped - skip it
		if config.showEmptySlotsOnly and item then
			showSlot = false
		end

		if showSlot then
			itemsWereShown = true

			local row = this.createTableRow(equipWindowScroll)

			if config.showClothingIconColumn then
				this.addItemIconCell(row, item)
			end

			if config.showClothingSlotNameColumn then
				this.addSlotNameCell(row, slot)
			end

			if config.showClothingConditionColumn then
				local colorsTable = {
					config.clothingConditionColorExcellent,
					config.clothingConditionColorGood,
					config.clothingConditionColorPoor,
					config.clothingConditionColorBad
				}
				this.addItemConditionCell(row, item, colorsTable, config.showClothingConditionPercent, config.enableColorsClothingCondition)
			end

			if config.showClothingEnchantmentChargeColumn then
				local colorsTable = {
					config.clothingEnchantmentChargeColorExcellent,
					config.clothingEnchantmentChargeColorGood,
					config.clothingEnchantmentChargeColorPoor,
					config.clothingEnchantmentChargeColorBad
				}
				this.addItemEnchantmentChargeCell(row, item, colorsTable, config.showClothingEnchantmentChargePercent, config.enableColorsClothingEnchantmentCharge)
			end

			if config.showClothingItemNameColumn then
				this.addItemNameCell(row, item)
			end
		end

		::continue::
	end

	if not itemsWereShown and config.showEmptySlotsOnly then
		this.addAllSlotsAreFilledRow(equipWindowScroll, "clothing")
	end

	this.addTableSeparator(equipWindowScroll)
end

function this.addAllSlotsAreFilledRow(scrollPane, itemType)
	local row = this.createTableRow(scrollPane)

	local itemCell = row:createThinBorder({})
	itemCell.height = 40
	itemCell.flowDirection = "left_to_right"
	itemCell.widthProportional = 1.0
	itemCell.childAlignY = 0.5
	itemCell.paddingLeft = 8

	itemCell:createLabel{ text = "--- All " .. itemType .. " slots are filled ---"}.color = { 0.4, 0.4, 0.4 }
end

function this.addTableSeparator(scrollPane)
	scrollPane:createBlock({}).height = 20
end

return this