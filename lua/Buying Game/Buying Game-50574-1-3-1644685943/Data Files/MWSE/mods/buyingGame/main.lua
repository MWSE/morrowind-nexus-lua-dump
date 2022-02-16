local common = require("buyingGame.common")
local strings = require("buyingGame.strings")
local restock = require("buyingGame.restock")
local specialization = require("buyingGame.specialization")

event.register("modConfigReady", function()
    require("buyingGame.mcm")
	common.config  = require("buyingGame.config")
end)

local function onBarterBegin(e)
	local mobileActor = tes3ui.getServiceActor()
	local ai = mobileActor.object.aiConfig
	local aiPrev = {}
	
	if tes3.mobilePlayer.mercantile.current >= common.config.canTradeWithEveryone then
		aiPrev.bartersMiscItems = ai.bartersMiscItems
		aiPrev.bartersWeapons = ai.bartersWeapons
		aiPrev.bartersArmor = ai.bartersArmor
		aiPrev.bartersAlchemy = ai.bartersAlchemy
		aiPrev.bartersApparatus = ai.bartersApparatus
		aiPrev.bartersBooks = ai.bartersBooks
		aiPrev.bartersClothing = ai.bartersClothing
		aiPrev.bartersEnchantedItems = ai.bartersEnchantedItems
		aiPrev.bartersIngredients = ai.bartersIngredients
		aiPrev.bartersLights = ai.bartersLights
		aiPrev.bartersLockpicks = ai.bartersLockpicks
		aiPrev.bartersProbes = ai.bartersProbes
		aiPrev.bartersRepairTools = ai.bartersRepairTools
		ai.bartersMiscItems = true
		ai.bartersWeapons = true
		ai.bartersArmor = true
		ai.bartersAlchemy = true
		ai.bartersApparatus = true
		ai.bartersBooks = true
		ai.bartersClothing = true
		ai.bartersEnchantedItems = true
		ai.bartersIngredients = true
		ai.bartersLights = true
		ai.bartersLockpicks = true
		ai.bartersProbes = true
		ai.bartersRepairTools = true
	end
	if tes3.mobilePlayer.mercantile.current >= common.config.canBarterEquipped then
		local equipment = {}
		timer.delayOneFrame(
			function()
				ai.bartersMiscItems = aiPrev.bartersMiscItems
				ai.bartersWeapons = aiPrev.bartersWeapons
				ai.bartersArmor = aiPrev.bartersArmor
				ai.bartersAlchemy = aiPrev.bartersAlchemy
				ai.bartersApparatus = aiPrev.bartersApparatus
				ai.bartersBooks = aiPrev.bartersBooks
				ai.bartersClothing = aiPrev.bartersClothing
				ai.bartersEnchantedItems = aiPrev.bartersEnchantedItems
				ai.bartersIngredients = aiPrev.bartersIngredients
				ai.bartersLights = aiPrev.bartersLights
				ai.bartersLockpicks = aiPrev.bartersLockpicks
				ai.bartersProbes = aiPrev.bartersProbes
				ai.bartersRepairTools = aiPrev.bartersRepairTools
				-- reevaluating items if not a default merchant
				if not mobileActor.reference.data.buyingGame then
					mobileActor.object:reevaluateEquipment()
				-- default merchants get their equipped items restored onMobileActivated event
				else
					tes3.player.data.buyingGame = tes3.player.data.buyingGame or {}
					tes3.player.data.buyingGame.reequip = tes3.player.data.buyingGame.reequip or {}
					for i, item in ipairs(equipment) do
						local equipped = mobileActor:equip{item=item}
						if not equipped then
							if not tes3.getObject(item).enchantment then -- do not restore enchanted items
								tes3.player.data.buyingGame.reequip[mobileActor.object.id] = tes3.player.data.buyingGame.reequip[mobileActor.object.id] or {}
								table.insert(tes3.player.data.buyingGame.reequip[mobileActor.object.id], item)
							end
							--[[timer.register("buyingGame:restoreTraderEquippedItems", function() mwse.log(mobileActor.object.id) mobileActor:equip{item = item, addItem = true} mwse.log("timer done") end)
							timer.start{
								duration = 1,
								type=timer.game,
								iterations = 1,
								persist = true,
								callback = "buyingGame:restoreTraderEquippedItems"
							}]]
						end
					end
				end
			end
		)
		for _, stack in pairs(mobileActor.object.equipment) do
			table.insert(equipment, stack.object.id)
			mobileActor:unequip{item = stack.object}
		end
	end
end

-- Restoring equipped items for default merchants so that they don't stand naked forever

local function onMobileActivate(e)
	if not tes3.player.data or not tes3.player.data.buyingGame or not tes3.player.data.buyingGame.reequip or not tes3.player.data.buyingGame.reequip[e.reference.id] then
		return 
	end
	
	if e.mobile.isDead then
		tes3.player.data.buyingGame.reequip[e.reference.id] = nil
		return	
	end
	
	timestamp = e.reference.data.buyingGame and e.reference.data.buyingGame.timestamp
	local newTimestamp = tes3.getSimulationTimestamp()
	
	if newTimestamp - timestamp >= tes3.findGMST(tes3.gmst.fBarterGoldResetDelay).value * common.config.restockTime then
	
		equipment = tes3.player.data.buyingGame.reequip[e.reference.id]

		for i, item in ipairs(equipment) do
			e.mobile:equip{item = item, addItem = true}
		end
	end
	
end

local function onCalcBarterPrice(e)

	e.price = e.basePrice
	local delta	= common.deltaTrade(e.mobile)
	local coef = math.max(1.5 - specialization.getModifier(e.mobile, e.item) + delta, 1)
	
	if e.buying then
		e.price = common.applyValueModifiers(e.price, e.item, e.itemData, "buy")
		e.price = e.price * coef
	else
		e.price = common.applyValueModifiers(e.price, e.item, e.itemData, "sell")
		e.price = e.price / coef
	end
	
	e.price = e.basePrice
	
	if e.itemData then
		if e.itemData.condition and e.item.maxCondition then
			e.price = e.price * e.itemData.condition/e.item.maxCondition
		end
	end
	
	if e.buying then
		if common.isImport(e.item.id) then
			e.price = e.price * (1 + common.config.sdModifier/100)
		elseif common.isExport(e.item.id) and tes3.mobilePlayer.mercantile.current >= common.config.knowsExport then
			e.price = e.price * (1 - common.config.sdModifier/100)
		end
		e.price = e.price * coef 
	else 
		if common.isExport(e.item.id) then
			e.price = e.price * (1 - common.config.sdModifier/100)
		elseif common.isImport(e.item.id) and tes3.mobilePlayer.mercantile.current >= common.config.knowsExport then
			e.price = e.price * (1 + common.config.sdModifier/100)
		end
		e.price = e.price / coef
	end
	
end

local function onBarterOffer(e)
	
	--mwse.log("Barter Offer")

	local forbidden = common.hasForbiddenItems(e.selling)
	local merchant = tes3ui.getServiceActor()
	if forbidden and not (common.config.smuggler[merchant.object.baseObject.id] or merchant.alarm == 0) then
		timer.start{
			duration = 0.0000001,
			type = timer.real,
			callback = function()
				dialogueMenu = tes3ui.findMenu("MenuDialog")
				byeButton = dialogueMenu:findChild(tes3ui.registerID("MenuDialog_button_bye"))
				byeButton:triggerEvent("mouseClick")
				tes3.messageBox(strings.forbiddenItemRefused, forbidden.name)
				tes3.triggerCrime({
					criminal = tes3.player,
					victim = merchant,
					type = tes3.crimeType.theft,
					value = 500
				})
			end
		}
		local menu = tes3ui.findMenu(tes3ui.registerID("MenuBarter"))
		local cancelButton = menu:findChild(tes3ui.registerID("MenuBarter_Cancelbutton"))
		cancelButton:triggerEvent("mouseClick")
		return false
	end
	
	-- Prevent exploitable haggling
	if e.offer > e.value then
		local trueValue = common.getArrayValue(e.selling, "sell") - common.getArrayValue(e.buying, "buy")
		if e.offer > trueValue then
			e.success = false
		end
	end
end

local function onBarterSuccess(e)

	--mwse.log("Barter Success")
	if not e.success then return end
	local merchant = tes3ui.getServiceActor().reference
	
	-- if doesn't have buyingGame table then we are using grandmaster perk, the npc is no merchant - no need to remove items
	
	if not merchant.data.buyingGame then
		return
	end
	
	if not merchant.data.buyingGame.boughtItems then
		merchant.data.buyingGame.boughtItems = {}
	end
	
	-- removing from the table all the items player currently bought 
	
	for i, tile in ipairs(e.buying) do
		if merchant.data.buyingGame.boughtItems[tile.item.id] then
			if merchant.data.buyingGame.boughtItems[tile.item.id] - tile.count <= 0 then
				merchant.data.buyingGame.boughtItems[tile.item.id] = nil
			else
				merchant.data.buyingGame.boughtItems[tile.item.id] = merchant.data.buyingGame.boughtItems[tile.item.id] - tile.count
			end
		end				
	end
	
	-- adding to the table that player currently sold
	
	for i, tile in ipairs(e.selling) do
		if merchant.data.buyingGame.boughtItems[tile.item.id] then
			merchant.data.buyingGame.boughtItems[tile.item.id] = merchant.data.buyingGame.boughtItems[tile.item.id] + tile.count
		else
			merchant.data.buyingGame.boughtItems[tile.item.id] = tile.count
		end
	end 
	
end

local function onServiceRefusal(e)
	if e.dialogue.type ~= 3 then return end
	if common.dialogueId[e.info.id] then
		e.passes = false
	end
end

local function createInvestmentMenu()
	local position = tes3.getCursorPosition()
	local menu = tes3ui.createMenu{id=tes3ui.registerID("MenuInvestment"), fixedFrame=true}
	menu.width = 220
	menu.autoHeight = true
	menu.flowDirection = "top_to_bottom"
	menu:findChild(tes3ui.registerID("PartNonDragMenu_main")).paddingAllSides = 10
	menu.absolutePosAlignX = false
	menu.absolutePosAlignY = false
	menu.positionX = position.x - 100
	menu.positionY = position.y
	local name = menu:createBlock()
	name.width = 200
	name.autoHeight = true
	name.widthProportional = 1
	name.childAlignX = 0.5
	name.flowDirection = "left_to_right"
	name = name:createLabel{text="Investment"}
	name.color = tes3ui.getPalette("header_color")
	name.borderBottom = 4
	local border = menu:createThinBorder{id = tes3ui.registerID("MenuInvestment_ServiceList")}
	border.width = 192
	border.autoHeight = true
	border.paddingAllSides = 4
	border.borderAllSides = 4
	border.flowDirection = "top_to_bottom"
	common.createInvest(menu, border, 2.5)
	common.createInvest(menu, border, 5)
	common.createInvest(menu, border, 10)
	local bottom = menu:createBlock()
	bottom.autoWidth = true
	bottom.autoHeight = true
	bottom.widthProportional = 1
	bottom.childAlignX = -1
	bottom.childAlignY = 0.5
	bottom.borderLeft = 4
	bottom:createLabel{text="Gold: "..tostring(tes3.getPlayerGold())}
	local button = bottom:createButton{id = tes3ui.registerID("MenuInvestment_closeButton")}
	button.text = "Close"
	button:register("mouseClick", function() 
		menu:destroy()
		tes3ui.leaveMenuMode(tes3ui.registerID("MenuInvestment"))
	end)
end

local function onMenuDialog(e)
	local actor = tes3ui.getServiceActor().reference
	local barter = e.element:findChild(tes3ui.registerID("MenuDialog_service_barter"))
	timer.frame.delayOneFrame(function()
		if barter.visible then
			restock.check(actor)
			if tes3.mobilePlayer.mercantile.current >= common.config.canTradeWithEveryone then
				barter:registerBefore("mouseClick", onBarterBegin)
			end
			if tes3.mobilePlayer.mercantile.current < common.config.canInvest then return end 
			if actor.data.buyingGame and actor.data.buyingGame.investment then return end
			local investment = barter.parent:createTextSelect{id = tes3ui.registerID("MenuDialog_investment"), text="Investment"}
			barter.parent:reorderChildren(barter, investment, 1)
			investment.visible = true
			investment:register("mouseClick", function() createInvestmentMenu() end)
			e.element:updateLayout()
		elseif tes3.mobilePlayer.mercantile.current >= common.config.canTradeWithEveryone then
			barter.visible = true
			barter:registerBefore("mouseClick", onBarterBegin)
		end
	end)
end

local function onItemTooltip(e)
	--[[if tes3.mobilePlayer.mercantile.current >= common.config.knowsPrice then
		return
	end
	local value = e.tooltip:findChild(tes3ui.registerID("HelpMenu_value"))
	if value then
		value.visible = false
	end
	local value = e.tooltip:findChild(tes3ui.registerID("UIEXP_Tooltip_IconGoldBlock"))
	if value then
		value.visible = false
	end]]
	local value = e.tooltip:findChild(tes3ui.registerID("UIEXP_Tooltip_IconGoldBlock")) or e.tooltip:findChild(tes3ui.registerID("HelpMenu_value"))
	if not value then return end
	
	if tes3.mobilePlayer.mercantile.current < common.config.knowsPrice then 
		value.visible = false
		return
	end
	
	if common.config.knowsExport > tes3.mobilePlayer.mercantile.current then
        return
    end
	
	local stolen = e.tooltip:findChild(GUI_ID_TooltipStolenLabel)
    local merchant = tes3ui.getServiceActor()
	
    if merchant then
        if common.config.forbidden[e.object.id] and not (common.config.smuggler[merchant.id] or merchant.alarm == 0) then
            --e.tooltip:createDivider()
            local labelBlock = e.tooltip:createBlock{ id = GUI_ID_TooltipContraband }
            labelBlock.minWidth = 1
            labelBlock.maxWidth = 210
            labelBlock.autoWidth = true
            labelBlock.autoHeight = true
            labelBlock.paddingAllSides = 1
            local label = labelBlock:createLabel{ text = strings.contraband }
            label.wrapText = true
            label.borderAllSides = 6
            label.justifyText = "center"
            label.color = tes3ui.getPalette("negative_color")
        end
    end
	
    if common.isExport(e.object.id) then
	
		for _, child in pairs(value.children) do
			if child.text and not child.contentPath then
				child.color = tes3ui.getPalette("journal_finished_quest_color")
				child.text = e.object.value * (1 - common.config.sdModifier/100)
			end
		end
	
        --e.tooltip:createDivider()
        local labelBlock = e.tooltip:createBlock{ id = GUI_ID_TooltipExport }
        labelBlock.minWidth = 1
        labelBlock.maxWidth = 210
        labelBlock.autoWidth = true
        labelBlock.autoHeight = true
        labelBlock.paddingAllSides = 1
        local label = labelBlock:createLabel{ text = strings.export}
        label.wrapText = true
        label.borderAllSides = 6
        label.justifyText = "center"
        label.color = tes3ui.getPalette("normal_color")
    elseif common.isImport(e.object.id) then
		
		for _, child in pairs(value.children) do
			if child.text and not child.contentPath then
				child.color = tes3ui.getPalette("header_color")
				child.text = e.object.value * (1 + common.config.sdModifier/100)
			end
		end
	
        --e.tooltip:createDivider()
        local labelBlock = e.tooltip:createBlock{ id = GUI_ID_TooltipImport }
        labelBlock.minWidth = 1
        labelBlock.maxWidth = 210
        labelBlock.autoWidth = true
        labelBlock.autoHeight = true
        labelBlock.paddingAllSides = 1
        local label = labelBlock:createLabel{ text = strings.import }
        label.wrapText = true
        label.borderAllSides = 6
        label.justifyText = "center"
        label.color = tes3ui.getPalette("normal_color")    
    end
	
end

--[[

ToDo: better indicators for import and export

local function onItemTileUpdated(e)

    if common.config.knowsExport > tes3.mobilePlayer.mercantile.current then
        return
    end

	local merchant = tes3ui.getServiceActor()

	if common.config.forbidden(e.item.id) and not (common.config.smuggler[merchant.id] or merchant.alarm == 0) then
        local icon = e.element:createImage({ path = "icons/ui_exp/ownership_indicator.dds" })
        icon.consumeMouseEvents = false
        icon.width = 16
        icon.height = 16
        icon.scaleMode = true
        icon.absolutePosAlignX = 0.2
        icon.absolutePosAlignY = 0.75
	end

    if common.isExport(e.item.id) then
        local icon = e.element:createImage({ path = "icons/ui_exp/ownership_indicator.dds" })
        icon.consumeMouseEvents = false
        icon.width = 16
        icon.height = 16
        icon.scaleMode = true
        icon.absolutePosAlignX = 0.6
        icon.absolutePosAlignY = 0.75
    elseif common.isImport(e.item.id) then
        local icon = e.element:createImage({ path = "icons/ui_exp/ownership_indicator.dds" })
        icon.consumeMouseEvents = false
        icon.width = 16
        icon.height = 16
        icon.scaleMode = true
        icon.absolutePosAlignX = 0.6
        icon.absolutePosAlignY = 0.75
	end

end

]]

local function onInfoResponse(e)
	local command = string.lower(e.command)
	if not command then
		return
	end
	if (string.find(command, "\npayfine") and not string.find(command, "\npayfinethief")) or string.find(command, "gotojail") then
		common.removeForbidden(tes3.player)
	end
end


local function onInitialized(e)
	if common.config.modEnabled then
		mwse.log("[Buying Game]: enabled")
		event.register("infoResponse", onInfoResponse)
		event.register("uiActivated", onMenuDialog, {filter = "MenuDialog"})
		event.register("infoFilter", onServiceRefusal)
		event.register("calcBarterPrice", onCalcBarterPrice)
		event.register("barterOffer", onBarterOffer)
		event.register("barterOffer", onBarterSuccess, {priority = -99999})
		event.register("uiObjectTooltip", onItemTooltip)
		event.register("mobileActivated", onMobileActivate)
	else
		mwse.log("[Buying Game]: disabled")
	end
end

event.register("initialized", onInitialized)