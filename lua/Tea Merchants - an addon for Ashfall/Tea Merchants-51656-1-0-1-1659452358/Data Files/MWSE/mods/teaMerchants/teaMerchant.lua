local this = {}
local common = require("mer.ashfall.common.common")
local config = require("teaMerchants.mcm").config
local logger = require("logging.logger")
local log = logger.new { name = "teaMerchants.teaMerchants", logLevel = config.logLevel }
local merchantMenu = require("mer.ashfall.merchants.merchantMenu")
local teaConfig = common.staticConfigs.teaConfig
local interop = require("mer.ashfall.interop")

interop.registerWaterContainers({
	jsmk_Misc_Com_Bottle = { capacity = 90, weight = 3, value = 4, holdsStew = false },
	includeOverrides = false,
})

this.guids = { MenuDialog_TeaService = tes3ui.registerID("MenuDialog_service_TeaService") }

local function isTeaMerchants(reference)
	local obj = reference.baseObject or reference.object
	local objId = obj.id:lower()
	local classId = obj.class and reference.object.class.id:lower()
	log:debug("%s is a %s.", objId, classId)
	return (classId == "tea merchant") or config.teaMerchants[objId]
	-- return config.teaMerchants[objId]
end

local teaBaseCost = 25
local dispMulti = 1.3
local personalityMulti = 1.1

local function getTeaCost(merchantObj)
	local disposition = math.min(merchantObj.disposition, 100)
	local personality = math.min(tes3.mobilePlayer.personality.current, 100)
	local dispEffect = math.remap(disposition, 0, 100, dispMulti, 1.0)
	local personalityEffect = math.remap(personality, 0, 100, personalityMulti, 1.0)
	local discountApplied = tes3.getJournalIndex { id = "teaMerchants_golden_sedge" } >= 100 or
	                        tes3.getJournalIndex { id = "teaMerchants_scathecraw" } >= 100
	if discountApplied then
		return 10
	end
	return math.floor(teaBaseCost * dispEffect * personalityEffect)
end

local function getTeaMenuText(merchantObj)
	local cost = getTeaCost(merchantObj)
	return string.format("Hot Tea (%d gold)", cost)
end
local function teaSelectMenu()
	local menuDialog = merchantMenu.getDialogMenu()
	local merchant = menuDialog:getPropertyObject("PartHyperText_actor")
	local menuMessage = "Select a type of tea"
	local buttons = {}
	local surpriseMe = table.choice(teaConfig.validTeas)
	table.insert(buttons, {
		text = string.format("Surprise Me"),
		callback = function()
			--[[local cost = getTeaCost(merchant.object)
			local newBottle = true
			for _, itemStack in pairs(tes3.player.object.inventory) do
				local item = itemStack.object
				if item.id == "jsmk_Misc_Com_Bottle" then
					if item.data and item.data.waterAmount and item.data.waterAmount == 0 then
						newBottle = false
						item.data.waterAmount = 90
						item.data.waterType = surpriseMe
						item.data.teaProgress = 100
						item.data.waterHeat = 100
					end
				end
			end
			if newBottle then
				tes3.addItem({ reference = tes3.player, item = "jsmk_Misc_Com_Bottle", count = 1 })
				-- tes3.addItem({ reference = tes3.player, item = "Misc_Com_Bottle_08", count = 1 })
				local itemData
				itemData = tes3.addItemData { to = tes3.player, item = "jsmk_Misc_Com_Bottle" }
				itemData.data.waterAmount = 90
				itemData.data.waterType = surpriseMe
				itemData.data.teaProgress = 100
				itemData.data.waterHeat = 100
			else
				cost = cost - 1
				tes3.messageBox("A one-drake discount has been applied. Thank you for reusing the Tea Merchants' bottle.")
			end
			tes3.removeItem({ reference = tes3.player, item = "Gold_001", count = cost })
			tes3.addItem({ reference = merchant.reference, item = "Gold_001", count = cost })
			log:debug("teaSelectMenu: Triggering DrinkTea")
			event.trigger("Ashfall:Drink", { waterType = surpriseMe, amount = 100 })
			event.trigger("Ashfall:DrinkTea", { teaType = surpriseMe, amountDrank = 100, heat = 100 })
			tes3.messageBox("A bottle of tea has been added to your inventory.")]]
			local cost = getTeaCost(merchant.object)
			tes3.removeItem({ reference = tes3.player, item = "Gold_001", count = cost })
			tes3.addItem({ reference = merchant.reference, item = "Gold_001", count = cost })
			event.trigger("Ashfall:Drink", { waterType = surpriseMe, amount = 100 })
			event.trigger("Ashfall:DrinkTea", { teaType = surpriseMe, amountDrank = 100, heat = 100 })
			tes3.addItem({ reference = tes3.player, item = "jsmk_Misc_Com_Bottle", count = 1 })
			local itemData
			itemData = tes3.addItemData { to = tes3.player, item = "jsmk_Misc_Com_Bottle" }
			itemData.data.waterAmount = 90
			itemData.data.waterType = surpriseMe
			itemData.data.teaProgress = 100
			itemData.data.waterHeat = 100
			tes3.messageBox("A bottle of tea has been added to your inventory.")
		end,
		tooltip = {
			header = string.format("Surprise Me"),
			text = "Feeling adventurous? The Tea Merchant will make a random drink. It might just become your new favourite!",
		},
	})
	for teaType, teaData in pairs(teaConfig.teaTypes) do
		local teaTypeAvailable = tes3.getItemCount({ item = teaType, reference = merchant.reference }) ~= 0
		--[[for ref in merchant.reference.cell:iterateReferences(tes3.objectType.ingredient) do
			if ref.id == teaType then
				local ingredOwner = tes3.getOwner(ref)
				if ingredOwner and ingredOwner == merchant.object.id then
					teaTypeAvailable = true
				end
			end
		end
		for ref in merchant.reference.cell:iterateReferences(tes3.objectType.container) do
			local owner = tes3.getOwner(ref)
			if owner and owner == merchant.object.id then
				if tes3.getItemCount({ item = teaType, reference = ref }) then
					teaTypeAvailable = true
				end
			end
		end]]
		if teaTypeAvailable then
			table.insert(buttons, {
				text = string.format("%s", teaData.teaName),
				callback = function()
					--[[local cost = getTeaCost(merchant.object)
					local newBottle = true
					for _, itemStack in pairs(tes3.player.object.inventory) do
						local item = itemStack.object
						if item.id == "jsmk_Misc_Com_Bottle" then
							if item.data and item.data.waterAmount and item.data.waterAmount == 0 then
								newBottle = false
								item.data.waterAmount = 90
								item.data.waterType = surpriseMe
								item.data.teaProgress = 100
								item.data.waterHeat = 100
							end
						end
					end
					if newBottle then
						tes3.addItem({ reference = tes3.player, item = "jsmk_Misc_Com_Bottle", count = 1 })
						-- tes3.addItem({ reference = tes3.player, item = "Misc_Com_Bottle_08", count = 1 })
						local itemData
						itemData = tes3.addItemData { to = tes3.player, item = "jsmk_Misc_Com_Bottle" }
						itemData.data.waterAmount = 90
						itemData.data.waterType = surpriseMe
						itemData.data.teaProgress = 100
						itemData.data.waterHeat = 100
					else
						cost = cost - 1
						tes3.messageBox("A one-drake discount has been applied. Thank you for reusing the Tea Merchants' bottle.")
					end
					tes3.removeItem({ reference = tes3.player, item = "Gold_001", count = cost })
					tes3.addItem({ reference = merchant.reference, item = "Gold_001", count = cost })
					tes3.removeItem({ reference = merchant.reference, item = teaType, count = 1 })
					log:debug("teaSelectMenu: Triggering DrinkTea")
					event.trigger("Ashfall:Drink", { waterType = teaType, amount = 100 })
					event.trigger("Ashfall:DrinkTea", { teaType = teaType, amountDrank = 100, heat = 100 })
					tes3.messageBox("A bottle of %s has been added to your inventory.", teaData.teaName)]]
					local cost = getTeaCost(merchant.object)
					tes3.removeItem({ reference = tes3.player, item = "Gold_001", count = cost })
					tes3.addItem({ reference = merchant.reference, item = "Gold_001", count = cost })
					tes3.removeItem({ reference = merchant.reference, item = teaType, count = 1 })
					event.trigger("Ashfall:Drink", { waterType = teaType, amount = 100 })
					event.trigger("Ashfall:DrinkTea", { teaType = teaType, amountDrank = 100, heat = 100 })
					tes3.addItem({ reference = tes3.player, item = "jsmk_Misc_Com_Bottle", count = 1 })
					-- tes3.addItem({ reference = tes3.player, item = "Misc_Com_Bottle_08", count = 1 })
					local itemData
					itemData = tes3.addItemData { to = tes3.player, item = "jsmk_Misc_Com_Bottle" }
					-- itemData = tes3.addItemData { to = tes3.player, item = "Misc_Com_Bottle_08" }
					itemData.data.waterAmount = 90
					itemData.data.waterType = teaType
					itemData.data.teaProgress = 100
					itemData.data.waterHeat = 100
					tes3.messageBox("A bottle of %s has been added to your inventory.", teaData.teaName)
				end,
				tooltip = { header = string.format("%s", teaData.teaName), text = teaData.teaDescription },
			})
		end
	end
	tes3ui.showMessageMenu { message = menuMessage, buttons = buttons, cancels = true }
end
local function onTeaServiceClick()
	teaSelectMenu()
end
local function isHydrated()
	local thirst = common.staticConfigs.conditionConfig.thirst:getValue()
	if thirst < 0.1 then
		return true
	end
	return false
end
local function getDisabled(cost)
	-- check player can afford
	if tes3.getPlayerGold() < cost then
		return true
	end
	if isHydrated() then
		return true
	end
	return false
end
local function makeTooltip()
	local menuDialog = merchantMenu.getDialogMenu()
	if not menuDialog then
		return
	end
	local merchant = menuDialog:getPropertyObject("PartHyperText_actor")
	local cost = getTeaCost(merchant.object)
	local tooltip = tes3ui.createTooltipMenu()
	local labelText = "Purchase a bottle of tea. "
	if getDisabled(cost) then
		if isHydrated() then
			labelText = "You are fully hydrated."
		else
			labelText = "You do not have enough gold."
		end
	end
	local tooltipText = tooltip:createLabel{ text = labelText }
	tooltipText.wrapText = true
end
local function updateTeaServiceButton(e)
	timer.frame.delayOneFrame(function()
		local menuDialog = merchantMenu.getDialogMenu()
		if not menuDialog then
			return
		end
		local teaServiceButton = menuDialog:findChild(this.guids.MenuDialog_TeaService)
		local merchant = menuDialog:getPropertyObject("PartHyperText_actor")
		local cost = getTeaCost(merchant.object)
		if getDisabled(cost) then
			teaServiceButton.disabled = true
			teaServiceButton.widget.state = 2
		else
			teaServiceButton.disabled = false
		end
		teaServiceButton.text = getTeaMenuText(merchant.object)
	end)
end
local function createTeaButton(menuDialog)
	local parent = merchantMenu.getButtonBlock()
	local merchant = merchantMenu.getMerchantObject()
	local button = parent:createTextSelect{ id = this.guids.MenuDialog_TeaService, text = getTeaMenuText(merchant) }
	button.widthProportional = 1.0
	button:register("mouseClick", onTeaServiceClick)
	button:register("help", makeTooltip)
	menuDialog:registerAfter("update", updateTeaServiceButton)
end
local function onMenuDialogActivated()
	if require("mer.ashfall.config").config.enableThirst ~= true then
		return
	end
	local menuDialog = merchantMenu.getDialogMenu()
	-- Get the actor that we're talking with.
	local mobileActor = menuDialog:getPropertyObject("PartHyperText_actor")
	local ref = mobileActor.reference
	if isTeaMerchants(ref) then
		log:debug("Adding Hot Tea Service")
		-- Create our new button.
		createTeaButton(menuDialog)
	end
end
event.register("uiActivated", onMenuDialogActivated, { filter = "MenuDialog", priority = -99 })
