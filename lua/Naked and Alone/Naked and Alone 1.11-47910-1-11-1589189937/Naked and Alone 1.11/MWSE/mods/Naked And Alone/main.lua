local config = mwse.loadConfig("NakedAndAlone")
if not config then
	config = {
		dropEquippedItems = true,
		dropChance = 100,
	}
end

local messagesItemsOnly = {
	common = "You feel the weight of your inventory lifted as the intervention leaves it in place.",
	unlikely = "Curses! The intervention worked, but the contents of your inventory were left behind!",
}

local messagesEquipment = {
	common = "You feel the weight of your clothing and equipment lifted as you leave without them.",
	unlikely = "Curses! The intervention worked, but your clothing and equipment have been left behind!",
}

local boundItemIDs = {}
local magickaExpanded = include("OperatorJack.MagickaExpanded.magickaExpanded")

local function onInitialized()
	for i = tes3.gmst.sMagicBoundDaggerID, tes3.gmst.sMagicBoundRightGauntletID, 1 do
		table.insert(boundItemIDs, tes3.findGMST(i).value)
	end
end
event.register("initialized", onInitialized)

local function isSpellSourceDroppable(sourceInstance, item)
	-- if not an enchantment, then we should drop everything
	if sourceInstance.sourceType ~= tes3.magicSourceType.enchantment then
		return true
	end
	-- otherwise, make sure we used the current object to teleport!
	if tes3.mobilePlayer.currentEnchantedItem.object == item then
		return false
	end
	return true
end

local function isNotBoundItem(item)
	for _, id in pairs(boundItemIDs) do
		if id:lower() == item.id:lower() then
			return false
		end
	end

	if magickaExpanded ~= nil then
		for _, id in pairs(magickaExpanded.functions.getBoundItemIdList()) do
			if id:lower() == item.id:lower() then
				return false
			end
		end
	end
	return true
end

local function dropPlayerItems(sourceInstance)
	local items = {}
	for _, stack in pairs(tes3.player.object.inventory) do
		table.insert(items, {object = stack.object, amount = stack.count})
	end
	
	local equippedItems = {}
	local equippedItemsTest = {}
	for _, stack in pairs(tes3.player.object.equipment) do
		--if stack.
		table.insert(equippedItems, stack.object)
		equippedItemsTest[stack.object] = true
	end
	
	for _, v in pairs(items) do
		if config.dropEquippedItems or not equippedItemsTest[v.object] then
			-- don't drop whatever we're actually using to teleport!
			if isSpellSourceDroppable(sourceInstance, v.object) and isNotBoundItem(v.object) then
				tes3.player.object.inventory:dropItem(tes3.mobilePlayer, v.object, v.object.itemData, v.amount,
														tes3.mobilePlayer.position, tes3vector3.new(0,0, math.random()))
				--I know the rotation is in radians, but 1 radian looks more natural than 360 degrees of randomisation.
			end
		end
	end
	tes3ui.forcePlayerInventoryUpdate()

	if config.dropEquippedItems then
		for _, object in pairs(equippedItems) do
			if isSpellSourceDroppable(sourceInstance, object) and isNotBoundItem(object) then
				tes3.mobilePlayer:unequip{item = object}
			end
		end
		tes3ui.forcePlayerInventoryUpdate()
	end
end

local function sendDropMessage(initialItems)
	if initialItems == #tes3.player.object.inventory then
		return
	end
	local messages = config.dropEquippedItems and messagesEquipment or messagesItemsOnly
	if config.dropChance > 60 then
		tes3.messageBox(messages.common)
	else
		tes3.messageBox(messages.unlikely)
	end
end

local function onMagicCasted(e)
	if e.caster == tes3.player then
		for _, effect in ipairs(e.source.effects) do
			if effect.id == tes3.effect.divineIntervention or effect.id == tes3.effect.almsiviIntervention then
				if math.random() < config.dropChance * 0.01 then
					local initialItems = #tes3.player.object.inventory
					dropPlayerItems(e.sourceInstance)
					sendDropMessage(initialItems)
				end
			end
		end
	end
end
event.register("magicCasted", onMagicCasted)

--ModConfig
local modConfig = {}

function modConfig.checkPlugin(label)
	if tes3.isModActive("NakedAndAlone.esp") then
		label.text = config.dropEquippedItems and "" or "Activating NakedAndAlone.esp is only recommended with this setting enabled. Consider removing it from your load order."
		label.color = tes3ui.getPalette("negative_color")
	else
		label.text = config.dropEquippedItems and "Activating the companion plugin NakedAndAlone.esp is highly recommended with this setting enabled." or ""
		label.color = tes3ui.getPalette("notify_color")
	end
end

function modConfig.onCreate(container)
	local pane = container:createThinBorder{}
	pane.widthProportional = 1.0
	pane.heightProportional = 1.0
	pane.paddingAllSides = 12
    pane.flowDirection = "top_to_bottom"

    local header = pane:createLabel{ text = "Naked And Alone\nversion 1.0" }
	header.color = tes3ui.getPalette("header_color")
	header.borderBottom = 25

	local txtBlock = pane:createBlock()
	txtBlock.widthProportional = 1.0
	txtBlock.autoHeight = true
	txtBlock.borderBottom = 25

    local txt = txtBlock:createLabel{}
	txt.widthProportional = 1.0
	txt.wrapText = true
    txt.text = "Drops all items (optionally including worn and equipped items) when using Divine or Almsivi intervention. \n\nCreated by Lucevar and Petethegoat."

	local buttonBlock = pane:createBlock()
	buttonBlock.flowDirection = "left_to_right"
	buttonBlock.widthProportional = 1.0
	buttonBlock.autoHeight = true

	buttonBlock:createLabel({ text = "Drop Equipped Items?" })

	local warningBlock = pane:createBlock()
	warningBlock.flowDirection = "left_to_right"
	warningBlock.widthProportional = 1.0
	warningBlock.autoHeight = true
	local warningText

	local button = buttonBlock:createButton({ text = config.dropEquippedItems and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value })
	button.absolutePosAlignX = 1.0
	button.paddingTop = 2
	button.borderRight = 6
	button:register("mouseClick", function(e)
		config.dropEquippedItems = not config.dropEquippedItems
		button.text = config.dropEquippedItems and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value
		modConfig.checkPlugin(warningText)
	end)

	warningText = warningBlock:createLabel()
	modConfig.checkPlugin(warningText)

	local chanceBlock = pane:createBlock()
	chanceBlock.flowDirection = "left_to_right"
    chanceBlock.layoutWidthFraction = 1.0
	chanceBlock.height = 32
	chanceBlock.borderTop = 4

	local chanceWarning = pane:createBlock()
	chanceWarning.flowDirection = "left_to_right"
	chanceWarning.widthProportional = 1.0
	chanceWarning.autoHeight = true

	local chanceWarningText = chanceWarning:createLabel({ text = "Item dropping disabled." })
	chanceWarningText.color = tes3ui.getPalette("negative_color")
	chanceWarning.visible = config.dropChance == 0

	local chanceLabel = chanceBlock:createLabel({ text = string.format("Item Drop Chance: %.f%%", config.dropChance) })

	local chanceSlider = chanceBlock:createSlider({ current = config.dropChance, max = 100, step = 1})
	chanceSlider.width = 256
	chanceSlider.layoutOriginFractionX = 1.0
	chanceSlider.borderRight = 6
	chanceSlider:register("PartScrollBar_changed", function(e)
		config.dropChance = (chanceSlider:getPropertyInt("PartScrollBar_current"))
		chanceLabel.text = string.format("Item Drop Chance: %.f%%", config.dropChance)
		chanceWarning.visible = config.dropChance == 0
	end)

    pane:updateLayout()
end

function modConfig.onClose()
	mwse.saveConfig("NakedAndAlone", config)
end

local function registerModConfig()
	mwse.registerModConfig("Naked And Alone", modConfig)
end
event.register("modConfigReady", registerModConfig)