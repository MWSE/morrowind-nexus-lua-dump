local recharge = {}

local common = require("Virnetch.enchantmentServicesRedone.common")

local InventorySelectMenu = require("Virnetch.enchantmentServicesRedone.ui.InventorySelectMenu")


--- Calculates the cost for recharging an item.
--- @param item tes3alchemy|tes3apparatus|tes3armor|tes3book|tes3clothing|tes3ingredient|tes3light|tes3lockpick|tes3misc|tes3probe|tes3repairTool|tes3weapon
--- @param itemData tes3itemData
--- @return number baseRechargeCost The base cost for recharging the item
--- @return number totalPrice Total cost modified by current merchant
function recharge.calculateRechargeCost(item, itemData)
	--[[
		Source: https://gitlab.com/OpenMW/openmw/-/wikis/development/research#merchant-repair

		p = max(1, basePrice)
		r = max(1, int(maxDurability / p))

		x = int((maxDurability - durability) / r)
		x = int(fRepairMult * x)
		cost = barterOffer(npc, x, buying)
	]]

	-- Calculate base cost
	local itemValue = math.max(1, item.value)
	local charge = itemData.charge * 10
	local maxCharge = item.enchantment.maxCharge * 10
	local baseRechargeCost = (( maxCharge - charge ) / math.max(1, ( maxCharge / itemValue )))

	-- Modify for current merchant
	local totalPrice = tes3.calculatePrice({
		basePrice = baseRechargeCost,
		merchant = tes3ui.getServiceActor()
	})

	-- Modify the final price with config
	totalPrice = math.floor(totalPrice * (common.config.recharge.costMult/100))

	return baseRechargeCost, totalPrice
end

--- Determines if a merchant can recharge an item
--- @param merchant tes3mobileNPC
--- @param item tes3alchemy|tes3apparatus|tes3armor|tes3book|tes3clothing|tes3ingredient|tes3light|tes3lockpick|tes3misc|tes3probe|tes3repairTool|tes3weapon
--- @return boolean
function recharge.canRechargeItem(merchant, item)
	if not common.config.recharge.enableChance then return true end

	-- Get the chance for NPC
	local baseChance = common.calculateBaseEnchantChanceForActor(merchant)
	local chance = baseChance - math.min(30, (2 * item.enchantment.chargeCost^(1/3)))

	common.log:debug(" Chance to recharge %s: %.2f - %.2f = %.2f",
		item.id, baseChance, (baseChance - chance), chance
	)

	-- Get the required chance
	local chanceRequired = common.config.recharge.chanceRequired

	-- Modify required chance by disposition
	local disposition = merchant.object.disposition
	if disposition then
		local dispFactor = common.config.dispositionFactor
		chanceRequired = chanceRequired + math.remap(math.clamp(disposition, 0, 100), 0, 100, dispFactor, -dispFactor)
	end

	common.log:debug("  chance: %.2f, required: %.2f for recharging %s", chance, chanceRequired, item.id)

	return ( chance >= chanceRequired )
end

local function rechargeItemSelected(e)
	if not e.source then return end
	local item = e.source:getPropertyObject("MenuInventorySelect_object")
	local itemData = e.source:getPropertyObject("MenuInventorySelect_extra", "tes3itemData")
	if item and itemData then
		local merchant = tes3ui.getServiceActor()

		-- Check NPC skills
		if not recharge.canRechargeItem(merchant, item) then
			tes3.messageBox(common.i18n("service.recharge.cantRecharge"))
			return
		end

		-- Check if player can afford
		local _, rechargeCost = recharge.calculateRechargeCost(item, itemData)
		if tes3.getPlayerGold() < rechargeCost then
			tes3.messageBox(tes3.findGMST(tes3.gmst.sBarterDialog1).value)
			return
		end

		-- Take the money
		tes3.transferItem({
			from = tes3.player,
			to = merchant,
			item = "Gold_001",
			count = rechargeCost
		})

		-- Restore the charge
		itemData.charge = item.enchantment.maxCharge
		tes3.playSound({ sound = "enchant success" })

		tes3ui.updateInventorySelectTiles()
		tes3.updateMagicGUI({ reference = tes3.player })
	end
end

local function rechargeItemSelectMenuUpdated()
	local menu = tes3ui.findMenu(common.GUI_ID.MenuInventorySelect)
	if not menu then return	end

	-- Update player gold label
	local goldLabel = menu:findChild(common.GUI_ID.MenuInventorySelect_gold_label)
	goldLabel.text = string.format("%s: %i", tes3.findGMST(tes3.gmst.sGold).value, tes3.getPlayerGold())

	local disabledColor = common.palette.disabledColor

	InventorySelectMenu.addToInventorySelectMenuTiles({
		--- @param section esrInventorySelectMenu.addToTilesParams.section
		addBelow = function(section)
			-- Show current charge
			local chargeBar = section.element:createFillBar({
				current = section.itemData.charge,
				max = section.item.enchantment.maxCharge
			})
			chargeBar.consumeMouseEvents = false
			chargeBar.children[1].consumeMouseEvents = false
			chargeBar.children[2].consumeMouseEvents = false

			section.element.borderTop = 2
		end,

		--- @param section esrInventorySelectMenu.addToTilesParams.section
		addRight = function(section)
			-- Show cost for recharging
			local costLabel = section.element:createLabel()
			local _, cost = recharge.calculateRechargeCost(section.item, section.itemData)
			costLabel.text = string.format("%i%s", cost, tes3.findGMST(tes3.gmst.sgp).value)
			costLabel.consumeMouseEvents = false

			-- Change item name and cost color to grey if player can't afford
			if (
				cost > tes3.getPlayerGold()
				-- Or if npc lacks the skills
				or not recharge.canRechargeItem(tes3ui.getServiceActor(), section.item)
			) then
				costLabel.color = disabledColor
				section.element.parent:findChild(common.GUI_ID.MenuInventorySelect_nameLabel).color = disabledColor
			end

			-- Register the callback when selecting item
			section.element.parent:register(tes3.uiEvent.mouseClick, rechargeItemSelected)
		end
	})
end

--- Edits the InventorySelectMenu to show player's gold and additional elements on the item tiles
--- @param e uiActivatedEventData
local function rechargeItemSelectMenuEntered(e)
	event.unregister(tes3.event.uiActivated, rechargeItemSelectMenuEntered, { filter = "MenuInventorySelect" })

	InventorySelectMenu.addPlayerGold(e.element)
	InventorySelectMenu.changeCancelToDone(e.element)

	-- Item tiles need to be edited after every update
	e.element:register(tes3.uiEvent.preUpdate, rechargeItemSelectMenuUpdated)
end

local function rechargeFilter(e)
	if (
		e.item.enchantment
		and e.itemData and e.itemData.charge
		and e.itemData.charge < e.item.enchantment.maxCharge
	) then
		return true
	end
	return false
end

--- Opens the recharge service menu
function recharge.showRechargeMenu()
	-- The recharge service menu is an edited InventorySelectMenu.

	event.register(tes3.event.uiActivated, rechargeItemSelectMenuEntered, { filter = "MenuInventorySelect" })

	tes3ui.showInventorySelectMenu({
		title = common.i18n("service.recharge.selectMenu.title"),
		noResultsText = common.i18n("service.recharge.selectMenu.noResultsText"),
		noResultsCallback = function()
			event.unregister(tes3.event.uiActivated, rechargeItemSelectMenuEntered, { filter = "MenuInventorySelect" })
		end,
		filter = rechargeFilter,
		callback = function() end	-- Required, won't actually be called
	})
end

return recharge