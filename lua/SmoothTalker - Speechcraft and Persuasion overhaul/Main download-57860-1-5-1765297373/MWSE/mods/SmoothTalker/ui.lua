local i18n = mwse.loadTranslations("SmoothTalker")
local persuasion = require("SmoothTalker.persuasion")
local unlocks = require("SmoothTalker.unlocks")
local vanillaDialog = require("SmoothTalker.vanillaDialog")
local npcCustomData = require("SmoothTalker.npcCustomData")
local npcParams = require("SmoothTalker.npcParams")

local ui = {}

-- Action ID to action type lookup (for tooltips)
local ACTION_ID_TO_TYPE = {
	[1] = "admire",
	[2] = "intimidate",
	[3] = "taunt",
	[4] = "placate",
	[5] = "bond"
}

-- Check if persuasion menu is currently open
function ui.isPersuasionMenuOpen()
	return tes3ui.findMenu("MenuPersuasionImproved") ~= nil
end

-- Rebuild the persuasion menu at the same position (useful when unlocking new features)
function ui.rebuildPersuasionMenu()
	local menu = tes3ui.findMenu("MenuPersuasionImproved")
	if not menu then return end

	local npcRef = vanillaDialog.getNpcRefFromDialog()
	if not npcRef then return end

	local posX = menu.positionX
	local posY = menu.positionY

	menu:destroy()
	tes3ui.leaveMenuMode(tes3ui.registerID("MenuPersuasionImproved"))
	ui.buildPersuasionMenu(npcRef)
	local newMenu = tes3ui.findMenu("MenuPersuasionImproved")
	if newMenu then
		newMenu.positionX = posX
		newMenu.positionY = posY
		newMenu:updateLayout()
	end
end

-- Handle action callback (admire, intimidate, taunt, placate, bribe)
function ui.handleAction(actionType, npcRef, bribeAmount, keepGold, illegalStatus)
	-- Perform the persuasion action using the persuasion module
	local result = persuasion.performAction(actionType, npcRef, bribeAmount)

	-- Trigger vanilla dialogue response (runs scripts, returns text if quest-related)
	local actionNames = {
		["admire"] = "Admire",
		["intimidate"] = "Intimidate",
		["taunt"] = "Taunt",
		["placate"] = "Placate",
		["bribe"] = "Bribe"
	}

	-- Determine if action is a crime based on illegal status
	local isCrime = false
	if illegalStatus == persuasion.ILLEGAL_STATUS.YES then
		isCrime = true
	elseif illegalStatus == persuasion.ILLEGAL_STATUS.YES_IF_FAILED and not result.success then
		isCrime = true
	end

	-- Handle crime
	if isCrime then
		local persuasionMenu = tes3ui.findMenu("MenuPersuasionImproved")
		if persuasionMenu then
			persuasionMenu:destroy()
		end
		local dialogMenu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
		if dialogMenu then
			dialogMenu:destroy()
		end

		-- Trigger crime after dialogue closes
		timer.delayOneFrame(function()
			tes3.triggerCrime{
				value = 250 + bribeAmount,
				type = tes3.crimeType.theft,
				criminal = tes3.mobilePlayer,
				forceDetection = true
			}
		end)
		return false
	end

	local vanillaResponseText = nil
	if actionNames[actionType] then
		vanillaResponseText = vanillaDialog.triggerVanillaPersuasionResponse(npcRef, actionNames[actionType], result.success)
	end

	-- Use vanilla response text if quest-related, otherwise use module response
	local responseText = vanillaResponseText or result.response
	tes3.messageBox(responseText)

	-- Update gold label if bribe action
	if actionType == "bribe" and result.success and not keepGold then
		tes3.removeItem{reference = tes3.player, item = "gold_001", count = bribeAmount, playSound = false}
		tes3.addItem{reference = npcRef, item = "gold_001", count = bribeAmount, playSound = false}
		tes3.playSound{sound = "Item Gold Up"}

		local newPlayerGold = tes3.getPlayerGold()
		local persuasionMenu = tes3ui.findMenu("MenuPersuasionImproved")
		if persuasionMenu then
			local goldLabel = persuasionMenu:findChild(tes3ui.registerID("MenuPersuasion_HeaderGold"))
			if goldLabel then
				goldLabel.text = string.format("Gold: %d", newPlayerGold)
			end
		end
	end

	-- Update UI
	ui.refreshStatusBars(npcRef)
	vanillaDialog.updateVanillaBars(npcRef)

	if vanillaDialog.hasActiveDialogueChoice() then
		vanillaDialog.closePersuasionMenu()
	end

	return result.success
end

-- UI layout constants
local rowHeight = 55
local buttonHeight = 40
local statusBarHeight = 60
local rowPadding = 3
local blockPadding = 5

-- Helper function to get difficulty label for success chance
local function getDifficultyLabel(successChance)
	if successChance >= 75 then
		return i18n("diff.easy"), "normal_pressed_color"
	elseif successChance >= 50 then
		return i18n("diff.medium"), "normal_color"
	elseif successChance >= 25 then
		return i18n("diff.hard"), "answer_color"
	else
		return i18n("diff.vhard"), "focus_color"
	end
end

-- Refresh status bars in the persuasion menu
function ui.refreshStatusBars(npcRef)
	local menu = tes3ui.findMenu("MenuPersuasionImproved")
	if not menu then return end

	local statusBars = persuasion.uiConfig.params
	local actions = persuasion.uiConfig.actions

	for _, status in ipairs(statusBars) do
		if unlocks.isUnlocked(status.unlockFeature) then
			local current = status.getValue(npcRef) or 0
			local barId = tes3ui.registerID("MenuPersuasion_"..status.id.."Bar")
			local bar = menu:findChild(barId)
			if bar then
				bar.widget.current = current
				bar.widget.max = status.max
			end
		end
	end

	-- Also refresh chance labels for all actions
	for _, actionConfig in ipairs(actions) do
		if unlocks.isUnlocked(actionConfig.unlockFeature) then
			local chance = persuasion.getSuccessChance(actionConfig.action, npcRef)
			local labelId = tes3ui.registerID("MenuPersuasion_"..actionConfig.id.."Chance")
			local label = menu:findChild(labelId)
			if label then
				if unlocks.isUnlocked(unlocks.FEATURE.SUCCESS_CHANCE_EXACT) then
					label.text = i18n("ui.chance", { math.floor(chance) })
				elseif unlocks.isUnlocked(unlocks.FEATURE.SUCCESS_CHANCE_APPROXIMATE) then
					local difficulty, paletteName = getDifficultyLabel(chance)
					label.text = i18n("ui.difficulty", { difficulty })
					label.color = tes3ui.getPalette(paletteName)
				else
					label.text = ""
				end
			end
		end
	end

	menu:updateLayout()
end

-- Helper function to create a block
local function addBlock(parent, id, width, height, vertical, framed)
    local block
    if (framed) then
        block = parent:createThinBorder{id = id  }
    else
        block = parent:createBlock{ id = id }
    end

	-- Auto-size unless explicit dimensions given
    if width then
        block.width = width
		block.autoWidth = false
    else
        block.autoWidth = true
    end

    if height then
        block.height = height
		block.autoHeight = false
    else
        block.autoHeight = true
    end

    if vertical then
        block.flowDirection = "top_to_bottom"
        block.childAlignX = 0.5
    else
        block.flowDirection = "left_to_right"
        block.childAlignY = 0.5
    end
    return block
end

-- Helper function to create a label
local function addLabel(parent, id, text, centered, height)
    local label = parent:findChild(id)
    if (label) then
        label:destroy()
    end
    label = parent:createLabel{ id=id, text = text }
	label.widthProportional = 1.0
	-- Only set explicit height if provided, otherwise auto-size
	if height then
		label.height = height
	end
    label.wrapText = true
    if (centered) then
        label.justifyText = "center"
    else
        label.justifyText = "left"
    end
    return label
end

-- Helper function to create a bar
local function addBar(parent, id, current, max)
    local bar = parent:findChild(id)
    if (bar) then
        bar:destroy()
    end
	bar = parent:createFillBar{id = id, current = current, max = max}
	bar.height = 30
	bar.widget.fillColor = tes3ui.getPalette("weapon_fill_color")
	bar.widget.showText = true
    return bar
end

-- Create tooltip for persuasion actions
local function createTooltip(e)
    local actionId = e.source:getPropertyInt("SmoothTalker:tooltipActionId")
    if not actionId or actionId == 0 then return end

    local actionType = ACTION_ID_TO_TYPE[actionId]
    if not actionType then return end

    local tooltipKey
    if actionType == "admire" then
        tooltipKey = "tooltip.admire"
    elseif actionType == "intimidate" then
        tooltipKey = "tooltip.intimidate"
    elseif actionType == "taunt" then
        tooltipKey = "tooltip.taunt"
    elseif actionType == "placate" then
        tooltipKey = "tooltip.placate"
    elseif actionType == "bond" then
        tooltipKey = "tooltip.bond"
    else
        return
    end

    local tooltipText = i18n(tooltipKey)

    local tooltip = tes3ui.createTooltipMenu()
    local tooltipBlock = tooltip:createBlock()
    tooltipBlock.autoWidth = true
    tooltipBlock.autoHeight = true
    tooltipBlock.paddingAllSides = 6

    local label = tooltipBlock:createLabel{text = tooltipText}
    label.wrapText = true
    label.maxWidth = 300

    tooltip:updateLayout()
end

-- Create tooltip for status bars showing permanent value
local function createStatusTooltip(e)
    local npcRef = e.source:getPropertyObject("SmoothTalker:npcRef")
    local statTypeId = e.source:getPropertyInt("SmoothTalker:statType")

    if not npcRef or not statTypeId then return end
    if not npcRef.supportsLuaData then return end

    local temporary = 0
    local current = 0

    if statTypeId == npcParams.STAT_TYPE.DISPOSITION then
        temporary = npcCustomData.getTemporaryDisposition(npcRef)
        current = npcRef.object.disposition
    elseif statTypeId == npcParams.STAT_TYPE.ALARM then
        temporary = npcCustomData.getTemporaryAlarm(npcRef)
        current = npcRef.mobile.alarm
    else
        return
    end

    -- Only show tooltip if there's a temporary component
    if temporary == 0 then return end

    -- Calculate permanent value
    local permanent = current - temporary

    local tooltip = tes3ui.createTooltipMenu()
    local tooltipBlock = tooltip:createBlock()
    tooltipBlock.autoWidth = true
    tooltipBlock.autoHeight = true
    tooltipBlock.paddingAllSides = 6

    local label = tooltipBlock:createLabel{text = i18n("ui.permanent", {permanent})}
    label.wrapText = true
    label.maxWidth = 300

    tooltip:updateLayout()
end

-- Build actions column
local function buildActionsColumn(parent, npcRef)
	local actions = persuasion.uiConfig.actions

	for i, action in ipairs(actions) do
		local isUnlocked = unlocks.isUnlocked(action.unlockFeature)

		if isUnlocked then
			local actionButton = parent:createButton{
				id = tes3ui.registerID("MenuPersuasion_"..action.label.."Button"),
				text = action.label
			}
			actionButton.width = 150
			actionButton.height = buttonHeight
			actionButton.paddingTop = 3
			actionButton.paddingBottom = 3

			actionButton:setPropertyInt("SmoothTalker:tooltipActionId", action.id)

			actionButton:register(tes3.uiEvent.help, createTooltip)

			actionButton:register("mouseClick", function()
				ui.handleAction(action.action, npcRef)
			end)

			local chance = persuasion.getSuccessChance(action.action, npcRef)
			local chanceLabel
			if unlocks.isUnlocked(unlocks.FEATURE.SUCCESS_CHANCE_EXACT) then
				chanceLabel = addLabel(parent, "MenuPersuasion_"..action.id.."Chance", i18n("ui.chance", { math.floor(chance) }), true, 20)
			elseif unlocks.isUnlocked(unlocks.FEATURE.SUCCESS_CHANCE_APPROXIMATE) then
				local difficulty, paletteName = getDifficultyLabel(chance)
				chanceLabel = addLabel(parent, "MenuPersuasion_"..action.id.."Chance", i18n("ui.difficulty", { difficulty }), true, 20)
				chanceLabel.color = tes3ui.getPalette(paletteName)
			else
				addLabel(parent, "MenuPersuasion_"..action.id.."Chance", "", true, 20)
			end

			if i < #actions then
				local spacer = parent:createBlock{}
				spacer.height = 10
			end
		end
	end
end

-- Build status column
local function buildStatusColumn(parent, npcRef)
	local statusBars = persuasion.uiConfig.params

	for _, status in ipairs(statusBars) do
		if unlocks.isUnlocked(status.unlockFeature) then
			local current = status.getValue(npcRef) or 0
			local statusBlock = addBlock(parent, "MenuPersuasion_"..status.id, parent.width, statusBarHeight, true)
			addLabel(statusBlock, "MenuPersuasion_"..status.id.."Title", status.label, true)
			local bar = addBar(statusBlock, "MenuPersuasion_"..status.id.."Bar", current, status.max)

			-- Add tooltip for disposition and alarm to show permanent value
			if status.id == "disposition" then
				bar:setPropertyObject("SmoothTalker:npcRef", npcRef)
				bar:setPropertyInt("SmoothTalker:statType", npcParams.STAT_TYPE.DISPOSITION)
				bar:register(tes3.uiEvent.help, createStatusTooltip)
			elseif status.id == "alarm" then
				bar:setPropertyObject("SmoothTalker:npcRef", npcRef)
				bar:setPropertyInt("SmoothTalker:statType", npcParams.STAT_TYPE.ALARM)
				bar:register(tes3.uiEvent.help, createStatusTooltip)
			end
		end
	end
end

local function filterGifts(e)
	return persuasion.calculateItemPersuasionModifier(e.item, e.itemData) > 0
end

local function giveGift(npcRef, item, itemData)
	local illegalStatus = persuasion.isGiftIllegal(item, npcRef)
	if npcRef.object.class and npcRef.object.class.id == "Guard" and illegalStatus == persuasion.ILLEGAL_STATUS.NO then
		illegalStatus = persuasion.ILLEGAL_STATUS.YES_IF_FAILED
	end
	local success = ui.handleAction("bribe", npcRef, persuasion.calculateItemPersuasionModifier(item, itemData), true, illegalStatus)
	if success then
		tes3.transferItem({
			from = tes3.player,
			to = npcRef,
			item = item,
			itemData = itemData,
			playSound = true,
			count = 1,
			updateGUI = true
		})
	end
end

-- Build bribe column
local function buildBribeColumn(parent, menu, npcRef)
	local bribe = persuasion.uiConfig.bribe

	local bribeButton = parent:createButton{
			id = tes3ui.registerID("MenuPersuasion_BribeExecute"),
			text = "Bribe"
		}
		bribeButton.autoWidth = true
		bribeButton.height = buttonHeight

		addLabel(parent, "MenuPersuasion_BribeDifficulty", i18n("ui.chance", { 50 }), true, 20)

		local frameBlock = parent:createThinBorder{id = tes3ui.registerID("MenuPersuasion_BribeFrame")}
		frameBlock.widthProportional = 1.0
		frameBlock.autoHeight = true
		frameBlock.paddingAllSides = 8
		frameBlock.flowDirection = "top_to_bottom"
		frameBlock.borderTop = 8

		local presetPadding = 5
		local numPresets = #bribe.presets

		local presetBlock = addBlock(frameBlock, "MenuPersuasion_BribePresets", nil, 40, false, false)

		for i, amount in ipairs(bribe.presets) do
			local presetBtn = presetBlock:createButton{
				id = tes3ui.registerID("MenuPersuasion_BribePreset"..amount),
				text = tostring(amount)
			}
			presetBtn.autoWidth = true
			presetBtn.height = 30

			if i < numPresets then
				presetBtn.paddingRight = presetPadding
			end
			presetBtn:register("mouseClick", function()
				-- Will set the amount input when we create it below
			end)
		end

		local buttonWidth = 26
		local labelWidth = 35

		local amountBlock = frameBlock:createBlock{id = tes3ui.registerID("MenuPersuasion_BribeAmountBlock")}
		amountBlock.flowDirection = "left_to_right"
		amountBlock.autoHeight = true
		amountBlock.autoWidth = true
		amountBlock.widthProportional = 1.0
		amountBlock.heightProportional = 1.0
		amountBlock.childAlignX = 0.5

		local minusButton = amountBlock:createButton{
			id = tes3ui.registerID("MenuPersuasion_BribeMinus"),
			text = "-"
		}
		minusButton.width = buttonWidth
		minusButton.autoWidth = false
		minusButton.height = 30
		minusButton.autoHeight = false

		-- Amount display in a wrapper block (label sizing is unpredictable, block handles it)
		local labelContainer = amountBlock:createBlock{id = tes3ui.registerID("MenuPersuasion_BribeAmountContainer")}
		labelContainer.width = labelWidth
		labelContainer.autoWidth = false
		labelContainer.height = 30
		labelContainer.autoHeight = false
		labelContainer.borderAllSides = 2
		labelContainer.childAlignX = 0.5
		labelContainer.childAlignY = 0.5

		local amountLabel = labelContainer:createLabel{
			id = tes3ui.registerID("MenuPersuasion_BribeAmount"),
			text = "10"
		}
		amountLabel.autoWidth = true
		amountLabel.autoHeight = true
		amountLabel.wrapText = true
		amountLabel.justifyText = "center"

		local plusButton = amountBlock:createButton{
			id = tes3ui.registerID("MenuPersuasion_BribePlus"),
			text = "+"
		}
		plusButton.width = buttonWidth
		plusButton.autoWidth = false
		plusButton.height = 30
		plusButton.autoHeight = false

		menu:updateLayout()

		local function updateBribeChance()
			local amount = tonumber(amountLabel.text) or 0
			local chance = persuasion.getSuccessChance("bribe", npcRef, amount)
			local chanceLabel = menu:findChild(tes3ui.registerID("MenuPersuasion_BribeDifficulty"))
			if chanceLabel then
				if unlocks.isUnlocked(unlocks.FEATURE.SUCCESS_CHANCE_EXACT) then
					chanceLabel.text = i18n("ui.chance", { math.floor(chance) })
				elseif unlocks.isUnlocked(unlocks.FEATURE.SUCCESS_CHANCE_APPROXIMATE) then
					local difficulty, paletteName = getDifficultyLabel(chance)
					chanceLabel.text = i18n("ui.difficulty", { difficulty })
					chanceLabel.color = tes3ui.getPalette(paletteName)
				else
					chanceLabel.text = ""
				end
			end
			menu:updateLayout()
		end

		local function decreaseAmount()
			local current = tonumber(amountLabel.text) or 0
			local newAmount = math.max(0, current - 10)
			amountLabel.text = tostring(newAmount)
			updateBribeChance()
		end

		local function increaseAmount()
			local current = tonumber(amountLabel.text) or 0
			local newAmount = current + 10
			amountLabel.text = tostring(newAmount)
			updateBribeChance()
		end

		minusButton:register("mouseClick", decreaseAmount)
		plusButton:register("mouseClick", increaseAmount)

		-- Now wire up the preset buttons to set the amount
		for _, child in ipairs(presetBlock.children) do
			if child.widget then -- It's a button
				local btnText = child.text
				local amount = tonumber(btnText)
				if amount then
					child:register("mouseClick", function()
						amountLabel.text = tostring(amount)
						updateBribeChance()
					end)
				end
			end
		end

		-- Initialize with starting chance
		updateBribeChance()

		bribeButton:register("mouseClick", function()
			local amount = tonumber(amountLabel.text) or 0
			if amount <= 0 then
				tes3.messageBox("Invalid bribe amount")
				return
			end

			local playerGold = tes3.getPlayerGold()
			if amount > playerGold then
				tes3.messageBox("You don't have enough gold")
				return
			end

			-- Bribing a guard is a crime if it fails
			local illegalStatus = persuasion.ILLEGAL_STATUS.NO
			if npcRef.object.class and npcRef.object.class.id == "Guard" then
				illegalStatus = persuasion.ILLEGAL_STATUS.YES_IF_FAILED
			end

			-- Use the common action callback
			ui.handleAction("bribe", npcRef, amount, false, illegalStatus)
		end)

		-- Add gift giving button
		local spacer = parent:createBlock{}
		spacer.height = 20

		local giftButton = parent:createButton{
			id = tes3ui.registerID("MenuPersuasion_GiveGift"),
			text = "Give a Gift"
		}
		giftButton.autoWidth = true
		giftButton.height = buttonHeight

		giftButton:register("mouseClick", function()
			tes3ui.showInventorySelectMenu({
				title = "Give a Gift",
				noResultsText = "No possible gifts found.",
				filter = filterGifts,
				callback = function(e)
					giveGift(npcRef, e.item, e.itemData)
				end
			})
		end)
		

end

-- Build the persuasion menu
function ui.buildPersuasionMenu(npcRef)

	-- Retrieve configuration from domain modules
	local actions = persuasion.uiConfig.actions
	local statusBars = persuasion.uiConfig.params

	-- Calculate how many columns we'll have
	local hasActions = unlocks.hasAnyUnlocked(actions)
	local hasStatus = unlocks.hasAnyUnlocked(statusBars)
	local hasBribe = true  -- Bribe is always available

	local columnCount = 0
	if hasActions then columnCount = columnCount + 1 end
	if hasStatus then columnCount = columnCount + 1 end
	if hasBribe then columnCount = columnCount + 1 end

	-- Calculate menu width: column count * 210, with minimum of 250
	local columnWidth = 210
	local menuWidth = columnCount * columnWidth + (columnCount + 1) * blockPadding
	menuWidth = math.max(350, menuWidth)

	local position = tes3.getCursorPosition()
	local menu = tes3ui.createMenu{id=tes3ui.registerID("MenuPersuasionImproved"), fixedFrame=true}

	menu.width = menuWidth
	menu.autoHeight = true
	menu.flowDirection = "top_to_bottom"
	menu:findChild(tes3ui.registerID("PartNonDragMenu_main")).paddingAllSides = 10
	menu.positionX = position.x
	menu.positionY = position.y

    local headerBlock = addBlock(menu, "MenuPersuasion_HeaderBlock", menuWidth, nil, false, false)

    local npcName = npcRef.object.name or "Unknown"
    local npcLabel = headerBlock:createLabel{id = tes3ui.registerID("MenuPersuasion_NpcName"), text = npcName}
    npcLabel.color = tes3ui.getPalette("header_color")

    local fillerBlock = headerBlock:createBlock{id = tes3ui.registerID("MenuPersuasion_HeaderFiller")}
    fillerBlock.widthProportional = 1.0
    fillerBlock.heightProportional = 1.0
    fillerBlock.autoHeight = true

    local playerGold = tes3.getPlayerGold()
    local goldLabel = headerBlock:createLabel{id = tes3ui.registerID("MenuPersuasion_HeaderGold"), text = string.format("Gold: %d", playerGold)}
    goldLabel.color = tes3ui.getPalette("normal_color")
    goldLabel.paddingRight = 20
    goldLabel.borderRight = 10

    local speechcraft = tes3.mobilePlayer.speechcraft.current
    local speechcraftLabel = headerBlock:createLabel{id = tes3ui.registerID("MenuPersuasion_Speechcraft"), text = string.format("Speechcraft: %d", speechcraft)}
    speechcraftLabel.color = tes3ui.getPalette("header_color")

    menu:updateLayout()

	local mainBlock = menu:createBlock{id = tes3ui.registerID("MenuPersuasion_MainBlock")}
	mainBlock.flowDirection = "left_to_right"
	mainBlock.widthProportional = 1.0
	mainBlock.autoHeight = true
	mainBlock.childAlignY = 0.0

	-- Center content if only one column
	if columnCount == 1 then
		mainBlock.childAlignX = 0.5
	end

	-- Build actions column if any actions are unlocked
	if hasActions then
		local actionsBlock = addBlock(mainBlock, "MenuPersuasion_ActionsBlock", columnWidth, nil, true, false)
		actionsBlock.borderRight = blockPadding
		actionsBlock.paddingTop = 15
		buildActionsColumn(actionsBlock, npcRef)
	end

	-- Build status column if any status bars are unlocked
	if hasStatus then
		local statusBlock = addBlock(mainBlock, "MenuPersuasion_StatusBlock", columnWidth, nil, true, false)
		statusBlock.borderRight = blockPadding
		buildStatusColumn(statusBlock, npcRef)
	end

	-- Build bribe column if bribe is unlocked
	if hasBribe then
		local bribeBlock = addBlock(mainBlock, "MenuPersuasion_BribeBlock", columnWidth, nil, true, false)
		bribeBlock.paddingTop = 15
		buildBribeColumn(bribeBlock, menu, npcRef)
	end

	local bottomBlock = addBlock(menu, "MenuPersuasion_BottomBlock", menuWidth, 40, false, false)

	local bottomFiller = bottomBlock:createBlock{id = tes3ui.registerID("MenuPersuasion_BottomFiller")}
	bottomFiller.widthProportional = 1.0
	bottomFiller.heightProportional = 1.0
	bottomFiller.autoHeight = true

	local button = bottomBlock:createButton{id = tes3ui.registerID("MenuPersuasion_closeButton")}
	button.text = "Close"
	button:register("mouseClick", function()
		menu:destroy()
		tes3ui.leaveMenuMode(tes3ui.registerID("MenuPersuasionImproved"))
	end)

    local RightClickMenuExit = include("mer.RightClickMenuExit")
    if RightClickMenuExit and RightClickMenuExit.registerMenu then
        RightClickMenuExit.registerMenu{
            menuId = "MenuPersuasionImproved",
            buttonId = "MenuPersuasion_closeButton"
        }
    end

	menu:updateLayout()
end

-- Update item tooltips in gift selection menu to show bribe chances
function ui.updateTooltip(e)
	-- Only show chances if persuasion menu is open
	if not ui.isPersuasionMenuOpen() then
		return
	end

	-- Only process item tooltips
	if not e.object or e.object.isCarriable == false then
		return
	end

	-- Get NPC reference from dialog
	local npcRef = vanillaDialog.getNpcRefFromDialog()
	if not npcRef then
		return
	end

	-- Calculate bribe chance for this item
	local bribeAmount = persuasion.calculateItemPersuasionModifier(e.object, e.itemData)
	local chance = persuasion.getSuccessChance("bribe", npcRef, bribeAmount)

	-- Determine what to display based on unlocks
	local chanceText = nil
	local colorPalette = "header_color"

	if unlocks.isUnlocked(unlocks.FEATURE.SUCCESS_CHANCE_EXACT) then
		chanceText = i18n("ui.chance", { math.floor(chance) })
	elseif unlocks.isUnlocked(unlocks.FEATURE.SUCCESS_CHANCE_APPROXIMATE) then
		local difficulty, paletteName = getDifficultyLabel(chance)
		chanceText = i18n("ui.difficulty", { difficulty })
		colorPalette = paletteName
	end

	-- Add chance to tooltip if unlocked
	if chanceText then
		local divider = e.tooltip:createDivider()
		divider.paddingTop = 6
		divider.paddingBottom = 4

		local label = e.tooltip:createLabel({ text = chanceText })
		label.color = tes3ui.getPalette(colorPalette)
	end
end

return ui
