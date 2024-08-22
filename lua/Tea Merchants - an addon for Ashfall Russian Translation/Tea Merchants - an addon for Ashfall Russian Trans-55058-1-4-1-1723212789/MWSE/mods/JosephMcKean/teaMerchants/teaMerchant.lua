-- this is the main tea merchants code
local this = {}
local common = require("mer.ashfall.common.common")
local config = require("JosephMcKean.teaMerchants.config")
local logger = require("JosephMcKean.teaMerchants.logging").createLogger("teaMerchant")
local merchantMenu = require("mer.ashfall.merchants.merchantMenu")
local teaConfig = common.staticConfigs.teaConfig
local validTeas = require("JosephMcKean.teaMerchants.validTeas")

this.guids = { MenuDialog_TeaService = tes3ui.registerID("MenuDialog_service_TeaService") }

-- return true if npc has Tea Merchant class or is in the mcm Tea Merchant white list
local function isTeaMerchant(reference)
	local obj = reference.baseObject or reference.object
	local objId = obj.id:lower()
	local classId = obj.class and reference.object.class.id:lower()
	logger:debug("%s is a %s.", objId, classId)
	return (classId == "tea merchant") or config.teaMerchants[objId]
end

local teaBaseCost = 25
local dispMulti = 1.3
local personalityMulti = 1.1

-- tea cost varies between teabasecost (default 25) and teabasecost*dispMulti*personalityMulti (default 35)
local function getTeaCost(merchantObj)
	local disposition = math.min(merchantObj.disposition, 100)
	local personality = math.min(tes3.mobilePlayer.personality.current, 100)
	local dispEffect = math.remap(disposition, 0, 100, dispMulti, 1.0)
	local personalityEffect = math.remap(personality, 0, 100, personalityMulti, 1.0)
	-- do quest to get a lifetime tea merchants discount
	local discountApplied = tes3.getJournalIndex { id = "teaMerchants_golden_sedge" } >= 100 or
	                        tes3.getJournalIndex { id = "teaMerchants_scathecraw" } >= 100
	if discountApplied then
		return 10
	end
	return math.floor(teaBaseCost * dispEffect * personalityEffect)
end

-- create the text of the button Hot Tea (30 gold) on the dialog menu 
local function getTeaMenuText(merchantObj)
	local cost = getTeaCost(merchantObj)
	return string.format("Горячий чай (%d зол.)", cost)
end

local function fill(merchant, teaType, bottle)
	local cost = getTeaCost(merchant.object)
	tes3.removeItem({ reference = tes3.player, item = "Gold_001", count = cost })
	if config.barterGoldFix then
		merchant.barterGold = merchant.barterGold + cost
	end
	tes3.addItem({ reference = tes3.player, item = bottle, count = 1 })
	local itemData
	itemData = tes3.addItemData { to = tes3.player, item = bottle }
	-- fill the bottle to its full capacity
	local bottleData = require("mer.ashfall.needs.thirstController").getBottleData(bottle)
	if bottleData then
		itemData.data.waterAmount = bottleData.capacity
		itemData.data.waterType = teaType
		itemData.data.teaProgress = 100
		itemData.data.waterHeat = 100
	end
	tes3.closeDialogueMenu({ force = false })
	common.helper.fadeTimeOut(0.25, 2, function()
	end) -- 15 min has been passed 
	tes3.messageBox("В ваш инвентарь добавлена %s, заполненная %s.", tes3.getObject(bottle).name,
	                teaConfig.teaTypes[teaType].teaName)
end

-- the menu that shows up after clicking on the Hot Tea (30 gold) button 
local function teaSelectMenu()
	local merchant = merchantMenu.getDialogMenu():getPropertyObject("PartHyperText_actor")
	local buttons = {}
	table.insert(buttons, {
		text = string.format("Удиви меня"),
		callback = function()
			fill(merchant, table.choice(validTeas), "jsmk_Misc_Com_Bottle")
		end,
		tooltip = {
			header = string.format("Удиви меня"),
			text = "Хотите почувствовать дух приключений? Торговец чаем приготовит случайный напиток. Возможно, он может стать вашим новым любимым напитком!",
		},
	})
	-- loop through every valid tea types and the ones that are in tea merchant's inventory
	-- will show up as select options
	for teaType, teaData in pairs(teaConfig.teaTypes) do
		if tes3.getItemCount({ item = teaType, reference = merchant.reference }) ~= 0 then
			table.insert(buttons, {
				text = string.format("%s", teaData.teaName),
				callback = function()
					fill(merchant, teaType, "jsmk_Misc_Com_Bottle")
					tes3.removeItem({ reference = merchant.reference, item = teaType }) -- brewing one bottle of tea actually consumes one ingredient
				end,
				tooltip = { header = string.format("%s", teaData.teaName), text = teaData.teaDescription },
			})
		end
	end
	tes3ui.showMessageMenu({ message = "Выберите вид чая", buttons = buttons, cancels = true })
end

-- check if the button should be disabled 
local function getDisabled(cost)
	-- check if the player can afford
	if tes3.getPlayerGold() < cost then
		return true
	end
	return false
end

-- make the tooltip when hovering over the Hot Tea (30 gold) button
local function makeTooltip()
	local menuDialog = merchantMenu.getDialogMenu()
	if not menuDialog then
		return
	end
	local merchant = menuDialog:getPropertyObject("PartHyperText_actor")
	local cost = getTeaCost(merchant.object)
	local tooltip = tes3ui.createTooltipMenu()
	local labelText = "Приобрести бутылку чая. "
	if getDisabled(cost) then
		labelText = "У вас недостаточно золота."
	end
	local tooltipText = tooltip:createLabel{ text = labelText }
	tooltipText.wrapText = true
end

-- issue (v1.3): the tea service button doesn't update after bartering
local function updateTeaServiceButton(e)
	timer.frame.delayOneFrame(function()
		local menuDialog = merchantMenu.getDialogMenu()
		if not menuDialog then
			return
		end
		local teaServiceButton = menuDialog:findChild(this.guids.MenuDialog_TeaService)
		local merchant = menuDialog:getPropertyObject("PartHyperText_actor")
		local cost = getTeaCost(merchant.object)
		-- if the button should be disabled, disable it and grey out
		if getDisabled(cost) then
			teaServiceButton.disabled = true
			teaServiceButton.widget.state = 2
		else
			teaServiceButton.disabled = false
		end
		teaServiceButton.text = getTeaMenuText(merchant.object)
	end)
end

-- create the button of Hot Tea (30 gold) on the dialog menu 
local function createTeaButton(menuDialog)
	local parent = merchantMenu.getButtonBlock()
	if not parent then
		return
	end
	local merchant = merchantMenu.getMerchantObject()
	local button = parent:createTextSelect{ id = this.guids.MenuDialog_TeaService, text = getTeaMenuText(merchant) }
	button.widthProportional = 1.0
	button:register("mouseClick", teaSelectMenu)
	button:register("help", makeTooltip)
	menuDialog:registerAfter("update", updateTeaServiceButton)
end

-- upon entering the dialog menu, create the hot tea button 
local function onMenuDialogActivated()
	local menuDialog = merchantMenu.getDialogMenu()
	-- Get the actor that we're talking with.
	local mobileActor = menuDialog:getPropertyObject("PartHyperText_actor")
	local ref = mobileActor.reference
	if isTeaMerchant(ref) then
		logger:debug("Adding Hot Tea Service")
		-- Create our new button.
		createTeaButton(menuDialog)
	end
end
event.register("uiActivated", onMenuDialogActivated, { filter = "MenuDialog", priority = -99 }) -- not sure what priority i should set to 
