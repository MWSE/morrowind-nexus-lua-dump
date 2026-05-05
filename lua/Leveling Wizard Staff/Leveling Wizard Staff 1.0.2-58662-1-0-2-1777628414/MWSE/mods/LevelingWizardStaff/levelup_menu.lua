local log = mwse.Logger.new()

LevelUpMenu = {
	-- ###
	ids = {},
}

function LevelUpMenu:Initialize()
	self.ids.menu = tes3ui.registerID("lws:LevelUpMenu")
	self.ids.okButton = tes3ui.registerID("lws:LevelUpMenu_OkButton")
end

---@return tes3uiElement
function LevelUpMenu:CreateWindow()
	log:trace("Opening Level-Up menu")

	local menu = tes3ui.findMenu(self.ids.menu)
	-- Return if window is already open
	if (menu ~= nil) then
		log:trace("Re-used existing menu")
		return menu
	end

	local sideSpace = 10
	local betweenSpace = 10

	menu = tes3ui.createMenu({ id = self.ids.menu, fixedFrame = true })
	menu.alpha = 1.0 -- To avoid low contrast, text input windows should not use menu transparency settings
	menu.width = 450
	menu.autoHeight = true
	menu.childAlignY = 0.5
	menu.flowDirection = tes3.flowDirection.topToBottom

	local function closeLevelUpMenu()
		tes3ui.leaveMenuMode()
		menu:destroy()
		log:trace("Closed Level-Up menu")
	end

	local headerLayout = menu:createBlock({ id = "lws_levelup_header_layout" })
	headerLayout.width = menu.width
	headerLayout.autoHeight = true
	headerLayout.borderBottom = betweenSpace
	headerLayout.flowDirection = tes3.flowDirection.topToBottom
	headerLayout.childAlignX = 0.5

	local headerLabel = headerLayout:createLabel({ id = "lws_levelup_header_label", text = "Your Wizard Staff has grown in strength!\nSelect below what effect to upgrade or add:" })
	headerLabel.widthProportional = 1
	headerLabel.autoHeight = true
	headerLabel.wrapText = true
	headerLabel.justifyText = tes3.justifyText.center

	local topLayout = menu:createBlock({ id = "lws_levelup_top_layout" })
	topLayout.width = menu.width
	topLayout.height = 200
	topLayout.borderBottom = betweenSpace
	topLayout.childAlignX = 0.5
	topLayout.flowDirection = tes3.flowDirection.leftToRight

	local topBorder = topLayout:createThinBorder()
	topBorder.widthProportional = 1
	topBorder.height = topLayout.height
	topBorder.borderLeft = sideSpace
	topBorder.borderRight = sideSpace
	topBorder.childAlignX = 0.5
	topBorder.flowDirection = tes3.flowDirection.topToBottom

	local topLabel = topBorder:createLabel({ text = "Existing Effects" })
	local topScrollPane = topBorder:createVerticalScrollPane()
	topScrollPane.height = topBorder.height - topLabel.height

	local bottomLayout = menu:createBlock({ id = "lws_levelup_bottom_layout" })
	bottomLayout.width = menu.width
	bottomLayout.height = 200
	bottomLayout.borderBottom = betweenSpace
	bottomLayout.childAlignX = 0.5
	bottomLayout.flowDirection = tes3.flowDirection.leftToRight

	local bottomBorder = bottomLayout:createThinBorder()
	bottomBorder.widthProportional = 1
	bottomBorder.height = bottomLayout.height
	bottomBorder.borderLeft = sideSpace
	bottomBorder.borderRight = sideSpace
	bottomBorder.childAlignX = 0.5
	bottomBorder.flowDirection = tes3.flowDirection.topToBottom

	local bottomLabel = bottomBorder:createLabel({ text = "New Effects" })
	local bottomScrollPane = bottomBorder:createVerticalScrollPane()
	bottomScrollPane.height = bottomBorder.height - bottomLabel.height

	local modData = lws.GetModData()
	local nextLevel = modData.staffLevel + 1
	local freeEnchantmentSlots = math.max(0, 8 - modData.staffFilledEnchantmentSlots)

	--- @type integer
	local optionsCount = 0
	---@type lwsEffectDefinition
	local selectedEffectDefinition = nil
	---@type table<lws.effectType, lwsUpgradeOptionUi>
	local upgradeoptionsTyType = {}

	---@type tes3uiElement
	local confirmButton = nil

	---@param active boolean
	local function setConfirmButtonActive(active)
		if confirmButton == nil then
			return
		end

		if confirmButton.disabled == not active then
			return
		end

		log:trace("Setting confirmButton active: %s", active)

		local alpha
		if active then
			alpha = 1
		else
			alpha = 0.5
		end

		confirmButton.alpha = alpha
		for _, childElement in ipairs(confirmButton.children) do
			childElement.alpha = alpha
		end
		confirmButton.disabled = not active

		menu:updateLayout()
	end

	---@param parent tes3uiElement
	---@param effectDefinition lwsEffectDefinition
	---@param currentMagnitude integer|nil
	---@param nextMagnitude integer
	---@param buttonlabel string
	---@return lwsUpgradeOptionUi
	local function createUpgradeOptionUi(parent, effectDefinition, currentMagnitude, nextMagnitude, buttonlabel)
		local layout = parent:createBlock({ id = "lws_upgrade_layout_outer" })
		layout.widthProportional = 1
		layout.autoHeight = true
		layout.flowDirection = tes3.flowDirection.leftToRight
		layout.childAlignY = 0.5

		local leftLayout = layout:createBlock({ id = "lws_upgrade_layout_left" })
		leftLayout.widthProportional = 1
		leftLayout.autoHeight = true
		leftLayout.flowDirection = tes3.flowDirection.leftToRight

		local middleLayout = layout:createBlock({ id = "lws_upgrade_layout_middle" })
		middleLayout.width = 100
		middleLayout.autoHeight = true
		middleLayout.flowDirection = tes3.flowDirection.leftToRight

		local rightLayout = layout:createBlock({ id = "lws_upgrade_layout_right" })
		rightLayout.width = 95
		rightLayout.autoHeight = true
		rightLayout.flowDirection = tes3.flowDirection.leftToRight

		leftLayout:createLabel({ text = effectDefinition.displayName })

		---@param magnitude integer|nil
		---@param effectType lws.effectType
		local function getMagnitudeString(magnitude, effectType)
			if magnitude == nil then
				return " - "
			end

			if effectType == lws.effectType.fortifyMaxMagicka then
				return (magnitude / 10) .. "x"
			end

			return "" .. magnitude
		end

		middleLayout:createLabel({ text = getMagnitudeString(currentMagnitude, effectDefinition.type) })
		local upgradedLabel = middleLayout:createLabel({ text = " >> " .. getMagnitudeString(nextMagnitude, effectDefinition.type) })
		upgradedLabel.color = { 0, 1, 0 }
		upgradedLabel.visible = false

		local selectButton = rightLayout:createButton({ text = buttonlabel })
		selectButton.widthProportional = 1
		selectButton:register(tes3.uiEvent.mouseClick, function()
			if selectedEffectDefinition == effectDefinition then
				return
			end

			if selectedEffectDefinition ~= nil then
				---@type lwsUpgradeOptionUi|nil
				local previousUpgradeOption = upgradeoptionsTyType[selectedEffectDefinition.type]
				if previousUpgradeOption ~= nil then
					previousUpgradeOption.setSelected(false)
				end
			end

			selectedEffectDefinition = effectDefinition

			---@type lwsUpgradeOptionUi|nil
			local newUpgradeOption = upgradeoptionsTyType[selectedEffectDefinition.type]
			if newUpgradeOption then
				newUpgradeOption.setSelected(true)
			end

			setConfirmButtonActive(selectedEffectDefinition ~= nil)
			menu:updateLayout()
		end)

		---@type lwsUpgradeOptionUi
		local upgradeOption = {
			setSelected = function(selected)
				upgradedLabel.visible = selected
			end,
		}
		return upgradeOption
	end

	for _, effectDefinition in ipairs(lws.effectDefinitions) do
		if effectDefinition.availableAtLevel <= nextLevel then
			local currentEffectLevel = modData.staffEffectLevels[effectDefinition.type] or 0
			local nextEffectLevel = currentEffectLevel + 1
			local currentMagnitude = effectDefinition.magnitudes[currentEffectLevel]
			local nextMagnitude = effectDefinition.magnitudes[nextEffectLevel]

			if currentEffectLevel > 0 then
				if nextMagnitude ~= nil then
					local upgradeOption = createUpgradeOptionUi(topScrollPane, effectDefinition, currentMagnitude, nextMagnitude, "Upgrade")
					upgradeoptionsTyType[effectDefinition.type] = upgradeOption
					optionsCount = optionsCount + 1
				end
			else
				local enchantmentCount = #effectDefinition.effectInfos
				if enchantmentCount <= freeEnchantmentSlots and nextMagnitude ~= nil then
					local upgradeOption = createUpgradeOptionUi(bottomScrollPane, effectDefinition, currentMagnitude, nextMagnitude, "Add")
					upgradeoptionsTyType[effectDefinition.type] = upgradeOption
					optionsCount = optionsCount + 1
				end
			end
		end
	end

	local buttonLayout = menu:createBlock({ id = "lws_levelup_footer_layout" })
	buttonLayout.width = menu.width
	buttonLayout.autoHeight = true
	buttonLayout.childAlignX = 0.5
	buttonLayout.flowDirection = tes3.flowDirection.topToBottom

	if optionsCount > 0 then
		confirmButton = buttonLayout:createButton({ text = "Confirm" })
		setConfirmButtonActive(selectedEffectDefinition ~= nil)
		confirmButton:register(tes3.uiEvent.mouseClick, function()
			if selectedEffectDefinition ~= nil then
				lws.LevelUp(selectedEffectDefinition)
				closeLevelUpMenu()
			end
		end)
	else
		-- this should never happen, since we check for max level reached directly after the level-up and prevent further level ups
		buttonLayout:createLabel({ text = "Your Wizard Staff has reached its maximum potential." })
		buttonLayout:createLabel({ text = "No further strengthening is possible." })
		local abortButton = buttonLayout:createButton({ text = "Abort" })
		abortButton:register(tes3.uiEvent.mouseClick, function()
			closeLevelUpMenu()
		end)
	end

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(self.ids.menu)

	return menu
end
