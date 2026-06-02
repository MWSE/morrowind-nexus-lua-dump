-- ============================================================
-- Mod Info
-- ============================================================

local modName = "Interactive Lockpick"

local config = require("InteractiveLockpick.config")
require("InteractiveLockpick.mcm")


-- ============================================================
-- UI IDs
-- ============================================================

local ids = {
	menu = tes3ui.registerID("InteractiveLockpick:Menu"),
	pick = tes3ui.registerID("InteractiveLockpick:Pick"),
}


-- ============================================================
-- Active Lockpick State
-- ============================================================

local activeLockpickTarget = nil
local activeLockpickData = nil

local function clearActiveLockpick(reason)
	activeLockpickTarget = nil
	activeLockpickData = nil

	if reason and config.debugLog then
		mwse.log("[%s] Cleared active lockpick state. Reason: %s", modName, reason)
	end
end


-- ============================================================
-- Logging / Messages
-- ============================================================

local function debugLog(message)
	if config.debugLog then
		mwse.log("[%s] %s", modName, message)
	end
end

local function showMessageDebug(message)
	if config.debugMessages then
		tes3.messageBox("[%s] %s", modName, message)
	end

	debugLog(message)
end

local function getReferenceDebugName(reference)
	if not reference then
		return "nil"
	end

	if reference.object and reference.object.id then
		return reference.object.id
	end

	return tostring(reference)
end


-- ============================================================
-- Sound
-- ============================================================

local function playSound(soundId)
	debugLog("Playing sound: " .. tostring(soundId))

	tes3.playSound({
		sound = soundId,
		reference = tes3.player,
	})
end

local function playLockedSoundForTarget(reference)
	if not reference or not reference.object then
		playSound("lockedchest")
		return
	end

	local objectType = reference.object.objectType

	if objectType == tes3.objectType.door then
		playSound("lockeddoor")
	elseif objectType == tes3.objectType.container then
		playSound("lockedchest")
	else
		playSound("lockedchest")
	end
end

-- ============================================================
-- Lock State Helpers
-- ============================================================

local function getReferenceLockLevel(reference)
	if not reference then
		return 0
	end

	local lockLevel = tes3.getLockLevel({
		reference = reference,
	})

	if lockLevel then
		return lockLevel
	end

	if reference.lockNode and reference.lockNode.lockLevel then
		return reference.lockNode.lockLevel
	end

	return 0
end

local function getReferenceLocked(reference)
	if not reference then
		return false
	end

	local ok, locked = pcall(function()
		return tes3.getLocked({
			reference = reference,
		})
	end)

	if ok then
		return locked == true
	end

	debugLog("tes3.getLocked failed for " .. getReferenceDebugName(reference))
	return false
end

local function logReferenceLockState(prefix, reference)
	if not config.debugLog then
		return
	end

	local hasLockNode = reference and reference.lockNode ~= nil
	local lockNodeLevel = 0

	if reference and reference.lockNode and reference.lockNode.lockLevel then
		lockNodeLevel = reference.lockNode.lockLevel
	end

	local getLockLevelValue = 0

	local okLevel, levelResult = pcall(function()
		return tes3.getLockLevel({
			reference = reference,
		})
	end)

	if okLevel and levelResult then
		getLockLevelValue = levelResult
	end

	local getLockedValue = "error"

	local okLocked, lockedResult = pcall(function()
		return tes3.getLocked({
			reference = reference,
		})
	end)

	if okLocked then
		getLockedValue = tostring(lockedResult)
	end

	debugLog(string.format(
		"%s | target=%s | getLocked=%s | getLockLevel=%s | hasLockNode=%s | lockNodeLevel=%s",
		prefix,
		getReferenceDebugName(reference),
		tostring(getLockedValue),
		tostring(getLockLevelValue),
		tostring(hasLockNode),
		tostring(lockNodeLevel)
	))
end


-- ============================================================
-- Lockpick Helpers
-- ============================================================

local function getEquippedLockpick()
	local stack = tes3.getEquippedItem({
		actor = tes3.player,
		objectType = tes3.objectType.lockpick,
	})

	if not stack then
		debugLog("No equipped lockpick found.")
		return nil
	end

	debugLog(string.format(
		"Equipped lockpick found: id=%s quality=%.2f maxCondition=%s hasItemData=%s",
		stack.object and stack.object.id or "nil",
		stack.object and stack.object.quality or 0,
		stack.object and tostring(stack.object.maxCondition) or "nil",
		tostring(stack.itemData ~= nil)
	))

	return stack.object, stack.itemData
end

local function damageEquippedLockpick(lockpick, itemData)
	if not lockpick then
		debugLog("damageEquippedLockpick skipped: no lockpick.")
		return false, "Lockpick"
	end

	local itemName = lockpick.name or lockpick.id or "Lockpick"

	if not itemData then
		debugLog("No itemData on equipped lockpick. Creating itemData.")

		itemData = tes3.addItemData({
			to = tes3.player,
			item = lockpick,
		})
	end

	if not itemData then
		debugLog("damageEquippedLockpick failed: could not create/get itemData.")
		return false, itemName
	end

	local maxCondition = lockpick.maxCondition or 25
	local currentCondition = itemData.condition or maxCondition
	local newCondition = math.max(currentCondition - 1, 0)

	itemData.condition = newCondition

	debugLog(string.format(
		"Damaged lockpick: id=%s condition %s -> %s",
		tostring(lockpick.id),
		tostring(currentCondition),
		tostring(newCondition)
	))

	if newCondition <= 0 then
		tes3.removeItem({
			reference = tes3.player,
			item = lockpick,
			itemData = itemData,
			count = 1,
			playSound = true,
			updateGUI = true,
		})

		return true, itemName
	end

	tes3ui.forcePlayerInventoryUpdate()

	return false, itemName
end

local function getPinCountForDifficulty(difficultyText)
	if difficultyText == "Too Complex" then
		return 10
	elseif difficultyText == "Very Difficult" then
		return 8
	elseif difficultyText == "Difficult" then
		return 6
	elseif difficultyText == "Tricky" then
		return 5
	elseif difficultyText == "Moderate" then
		return 4
	elseif difficultyText == "Easy" then
		return 3
	elseif difficultyText == "Simple" then
		return 2
	end

	return 1 -- Basic / Unknown fallback
end

local function calculatePuzzleSettings(lockLevel, lockpick)
	local mobile = tes3.mobilePlayer

	local security = mobile.security.current
	local agility = mobile.agility.current
	local luck = mobile.luck.current

	local currentFatigue = mobile.fatigue.current
	local maxFatigue = math.max(mobile.fatigue.base, 1)

	local statsModifier = security + (agility / 5) + (luck / 10)
	local equipmentModifier = lockpick and lockpick.quality or 1.0
	local fatigueModifier = 0.75 + (0.5 * (currentFatigue / maxFatigue))

	local successChance = (statsModifier * equipmentModifier * fatigueModifier) - lockLevel
	local impossible = successChance <= 0

	local normalizedDifficulty

	if impossible then
		normalizedDifficulty = 1.0
	else
		normalizedDifficulty = 1.0 - math.clamp(successChance / 100, 0, 1)
	end

	local difficultyText

	if impossible then
		difficultyText = "Too Complex"
	elseif successChance < 10 then
		difficultyText = "Very Difficult"
	elseif successChance < 25 then
		difficultyText = "Difficult"
	elseif successChance < 40 then
		difficultyText = "Tricky"
	elseif successChance < 55 then
		difficultyText = "Moderate"
	elseif successChance < 70 then
		difficultyText = "Easy"
	elseif successChance < 85 then
		difficultyText = "Simple"
	else
		difficultyText = "Basic"
	end

	local pinCount = getPinCountForDifficulty(difficultyText)

	if not impossible then
		local maxSliders = math.clamp(config.maximumSliders or 8, 3, 10)
		pinCount = math.min(pinCount, maxSliders)
	end

	local maxValue = math.clamp(math.floor(10 + (normalizedDifficulty * 90)), 10, 100)
	local tolerance = math.clamp(math.floor(8 - (normalizedDifficulty * 7)), 1, 4)

	debugLog(string.format(
		"Calculated puzzle settings | lock=%d security=%d agility=%d luck=%d stats=%.2f pickQuality=%.2f fatigue=%.2f chance=%.2f impossible=%s pins=%d max=%d tolerance=%d",
		lockLevel,
		security,
		agility,
		luck,
		statsModifier,
		equipmentModifier,
		fatigueModifier,
		successChance,
		tostring(impossible),
		pinCount,
		maxValue,
		tolerance
	))

	return {
		lockLevel = lockLevel,
		security = security,
		agility = agility,
		luck = luck,
		statsModifier = statsModifier,
		equipmentModifier = equipmentModifier,
		fatigueModifier = fatigueModifier,
		successChance = successChance,
		impossible = impossible,
		difficultyText = difficultyText,
		lockpick = lockpick,
		pinCount = pinCount,
		maxValue = maxValue,
		tolerance = tolerance,
	}
end


-- ============================================================
-- Pin Utility
-- ============================================================

local function getDefaultPinValue()
	return 0
end

local function getPinCurrent(pinData)
	return pinData.current or getDefaultPinValue()
end

local function getPinMaxValue(pinData)
	return pinData.maxValue or 100
end

local function getDistanceColor(distance, tolerance)
	if distance <= tolerance then
		return { 0.25, 1.0, 0.25 } -- green
	elseif distance <= tolerance * 2 then
		return { 1.0, 0.85, 0.25 } -- yellow
	else
		return { 1.0, 0.25, 0.25 } -- red
	end
end

local function getPinColor(pinData)
	local current = getPinCurrent(pinData)
	local distance = math.abs(current - pinData.target)

	return getDistanceColor(distance, pinData.tolerance)
end

local function isPinGreen(pinData)
	local current = getPinCurrent(pinData)
	local distance = math.abs(current - pinData.target)

	return distance <= pinData.tolerance
end

local function getPinMarker(pinData)
	if isPinGreen(pinData) then
		return "O"
	end

	return "X"
end

local function getPinBarText(pinData)
	local current = getPinCurrent(pinData)
	local marker = getPinMarker(pinData)
	local maxValue = getPinMaxValue(pinData)

	local percent = 0

	if maxValue > 0 then
		percent = current / maxValue
	end

	percent = math.clamp(percent, 0, 1)

	local markerSlot = math.floor(percent * 10) + 1
	markerSlot = math.clamp(markerSlot, 1, 11)

	local text = ""

	for slot = 11, 1, -1 do
		if slot == markerSlot then
			text = text .. marker
		else
			text = text .. "|"
		end

		if slot > 1 then
			text = text .. "\n"
		end
	end

	return text
end

local function getPinTitleText(pinData)
--	return string.format("Pin %d: %d", pinData.index, getPinCurrent(pinData))
	return string.format("Pin %d", pinData.index)
end


-- ============================================================
-- Lockpick Menu State Update
-- ============================================================

local function updatePinVisual(pinData)
	local color = getPinColor(pinData)

	pinData.titleLabel.text = getPinTitleText(pinData)
	pinData.titleLabel.color = color
	pinData.titleLabel:updateLayout()

	pinData.fillLabel.text = getPinBarText(pinData)
	pinData.fillLabel.color = color
	pinData.fillLabel:updateLayout()
end

local function updateStatus(pinDataList, statusLabel)
	local allGreen = true

	for _, pinData in ipairs(pinDataList) do
		updatePinVisual(pinData)

		if not isPinGreen(pinData) then
			allGreen = false
		end
	end

	if allGreen then
		statusLabel.text = "All pins aligned."
		statusLabel.color = { 0.25, 1.0, 0.25 }
	else
		statusLabel.text = "Adjust the pins until all values are green."
		statusLabel.color = tes3ui.getPalette("normal_color")
	end

	statusLabel:updateLayout()
end


-- ============================================================
-- Lockpick Menu Controls
-- ============================================================

local function destroyExistingLockpickMenuOnly()
	local existingMenu = tes3ui.findMenu(ids.menu)

	if existingMenu then
		debugLog("Destroying existing lockpick menu without clearing active lockpick state.")
		existingMenu:destroy()
		tes3ui.leaveMenuMode()
	end
end

local function adjustPin(pinData, amount, pinDataList, statusLabel)
--	playSound("Open Lock Fail")

	local oldValue = pinData.current

	pinData.current = math.clamp(
		pinData.current + amount,
		0,
		getPinMaxValue(pinData)
	)

	debugLog(string.format(
		"Adjusted pin %d: %s -> %s | target=%s tolerance=%s max=%s green=%s",
		pinData.index,
		tostring(oldValue),
		tostring(pinData.current),
		tostring(pinData.target),
		tostring(pinData.tolerance),
		tostring(getPinMaxValue(pinData)),
		tostring(isPinGreen(pinData))
	))

	updateStatus(pinDataList, statusLabel)
end

local function createVerticalPinColumn(parent, index, pinDataList, statusLabel, onPinChanged)
	local maxValue = 100
	local tolerance = 5

	if activeLockpickData then
		maxValue = activeLockpickData.maxValue
		tolerance = activeLockpickData.tolerance
	end

	local target

	if activeLockpickData and activeLockpickData.impossible then
		target = maxValue + tolerance + 1

		debugLog(string.format(
			"Created impossible pin %d | target=%d max=%d tolerance=%d",
			index,
			target,
			maxValue,
			tolerance
		))
	else
		target = math.random(0, maxValue)

		debugLog(string.format(
			"Created normal pin %d | target=%d max=%d tolerance=%d",
			index,
			target,
			maxValue,
			tolerance
		))
	end

	local pinData = {
		index = index,
		current = getDefaultPinValue(),
		target = target,
		tolerance = tolerance,
		maxValue = maxValue,
	}

	local column = parent:createBlock({})
	column.flowDirection = "top_to_bottom"
	column.autoHeight = true
	column.width = 90
	column.paddingAllSides = 6

	local titleLabel = column:createLabel({
		text = string.format("Pin %d: 0", index),
	})
	titleLabel.width = 85
	titleLabel.height = 24
	titleLabel.color = { 1.0, 0.25, 0.25 }
	titleLabel.borderBottom = 6

	local plusTenButton = column:createButton({
		text = "+10",
	})
	plusTenButton.width = 60

	local plusOneButton = column:createButton({
		text = "+1",
	})
	plusOneButton.width = 60

	local fillLabel = column:createLabel({
		text = "|\n|\n|\n|\n|\n|\n|\n|\n|\n|\nX",
	})
	fillLabel.width = 60
	fillLabel.height = 170
	fillLabel.color = { 1.0, 0.25, 0.25 }
	fillLabel.borderTop = 6
	fillLabel.borderBottom = 6

	local minusOneButton = column:createButton({
		text = "-1",
	})
	minusOneButton.width = 60

	local minusTenButton = column:createButton({
		text = "-10",
	})
	minusTenButton.width = 60

	pinData.titleLabel = titleLabel
	pinData.fillLabel = fillLabel

	table.insert(pinDataList, pinData)

	plusTenButton:register("mouseClick", function()
		adjustPin(pinData, 10, pinDataList, statusLabel)
		if onPinChanged then
			onPinChanged()
		end
	end)

	plusOneButton:register("mouseClick", function()
		adjustPin(pinData, 1, pinDataList, statusLabel)
		if onPinChanged then
			onPinChanged()
		end

	end)

	minusOneButton:register("mouseClick", function()
		adjustPin(pinData, -1, pinDataList, statusLabel)
		if onPinChanged then
			onPinChanged()
		end

	end)

	minusTenButton:register("mouseClick", function()
		adjustPin(pinData, -10, pinDataList, statusLabel)
		if onPinChanged then
			onPinChanged()
		end

	end)

	return pinData
end


-- ============================================================
-- Delayed First Paint
-- ============================================================

local function scheduleInitialPaint(pinDataList, statusLabel)
	debugLog("Scheduling initial UI paint.")

	timer.start({
		duration = 0.05,
		type = timer.real,
		callback = function()
			local activeMenu = tes3ui.findMenu(ids.menu)

			if not activeMenu then
				debugLog("Initial lockpick menu paint skipped: menu no longer exists.")
				return
			end

			debugLog("Running delayed initial lockpick menu paint.")
			updateStatus(pinDataList, statusLabel)
			activeMenu:updateLayout()
		end,
	})
end


-- ============================================================
-- Lockpick Menu
-- ============================================================

local difficultyColors = {
	["Too Complex"] = { 0.55, 0.05, 0.05 }, -- dark red
	["Very Difficult"] = { 0.85, 0.10, 0.05 }, -- red
	["Difficult"] = { 0.95, 0.35, 0.05 }, -- orange-red
	["Tricky"] = { 1.00, 0.60, 0.10 }, -- orange
	["Moderate"] = { 0.95, 0.85, 0.20 }, -- yellow
	["Easy"] = { 0.55, 0.85, 0.20 }, -- yellow-green
	["Simple"] = { 0.20, 0.80, 0.20 }, -- green
	["Basic"] = { 0.45, 0.95, 0.65 }, -- pale green
	["Unknown"] = tes3ui.getPalette("normal_color"),
}

local function getDifficultyColor(difficultyText)
	return difficultyColors[difficultyText] or difficultyColors["Unknown"]
end

local function getDifficultyText(lockpickData)
	if not lockpickData then
		return "Unknown"
	end

	return lockpickData.difficultyText or "Unknown"
end

local function closeLockpickMenu(reason)
	local menu = tes3ui.findMenu(ids.menu)

	if menu then
		menu:destroy()
		tes3ui.leaveMenuMode()
	end

	clearActiveLockpick(reason or "closeLockpickMenu")
end

local function areAllPinsGreen(pinDataList)
	if not pinDataList or #pinDataList == 0 then
		return false
	end

	for _, pinData in ipairs(pinDataList) do
		if not isPinGreen(pinData) then
			return false
		end
	end

	return true
end

local function openLockpickMenu()
	debugLog("Opening lockpick menu.")
	destroyExistingLockpickMenuOnly()

	local menu = tes3ui.createMenu({
		id = ids.menu,
		fixedFrame = true,
	})

	tes3ui.enterMenuMode(ids.menu)

	local pinCount = config.maximumSliders or 5

	if activeLockpickData then
		pinCount = activeLockpickData.pinCount
	end

	pinCount = math.clamp(pinCount, 1, 10)

	local menuWidth = math.max(520, 260 + (pinCount * 100))

	menu.width = menuWidth
	menu.height = 600
	menu.minWidth = menuWidth
	menu.flowDirection = "top_to_bottom"
	menu.paddingAllSides = 12
	menu.absolutePosAlignX = 0.5
	menu.absolutePosAlignY = 0.5

	local title = menu:createLabel({
		text = "Interactive Lockpick",
	})
	title.color = tes3ui.getPalette("header_color")
	title.borderBottom = 10

	-- Lock level + difficulty text.
	local infoBlock = menu:createBlock({})
	infoBlock.flowDirection = "top_to_bottom"
	infoBlock.widthProportional = 1.0
	infoBlock.autoHeight = true
	infoBlock.borderBottom = 10

	local lockLevelText = "Lock"
	local difficultyText = "Unknown"

	if activeLockpickData then
		lockLevelText = string.format("Lock %d", activeLockpickData.lockLevel)
--		lockLevelText = string.format("Lock %d, Chance: %.0f%%", activeLockpickData.lockLevel, activeLockpickData.successChance or 0)
		difficultyText = getDifficultyText(activeLockpickData)
	end

	local lockLevelRow = infoBlock:createBlock({})
	lockLevelRow.flowDirection = "left_to_right"
	lockLevelRow.widthProportional = 1.0
	lockLevelRow.autoHeight = true

	local lockLevelLeftSpacer = lockLevelRow:createBlock({})
	lockLevelLeftSpacer.widthProportional = 1.0
	lockLevelLeftSpacer.autoHeight = true

	local lockLevelLabel = lockLevelRow:createLabel({
		text = lockLevelText,
	})
	lockLevelLabel.color = tes3ui.getPalette("header_color")

	local lockLevelRightSpacer = lockLevelRow:createBlock({})
	lockLevelRightSpacer.widthProportional = 1.0
	lockLevelRightSpacer.autoHeight = true

	local difficultyRow = infoBlock:createBlock({})
	difficultyRow.flowDirection = "left_to_right"
	difficultyRow.widthProportional = 1.0
	difficultyRow.autoHeight = true

	local difficultyLeftSpacer = difficultyRow:createBlock({})
	difficultyLeftSpacer.widthProportional = 1.0
	difficultyLeftSpacer.autoHeight = true

	local difficultyLabel = difficultyRow:createLabel({
		text = difficultyText,
	})
	difficultyLabel.color = getDifficultyColor(difficultyText)

	local difficultyRightSpacer = difficultyRow:createBlock({})
	difficultyRightSpacer.widthProportional = 1.0
	difficultyRightSpacer.autoHeight = true

	-- Status text.
	local statusRow = menu:createBlock({})
	statusRow.flowDirection = "left_to_right"
	statusRow.widthProportional = 1.0
	statusRow.autoHeight = true
	statusRow.borderBottom = 14

	local statusLeftSpacer = statusRow:createBlock({})
	statusLeftSpacer.widthProportional = 1.0
	statusLeftSpacer.autoHeight = true

	local statusLabel = statusRow:createLabel({
		text = "Adjust the pins until all values are green.",
	})
	statusLabel.color = tes3ui.getPalette("header_color")

	local statusRightSpacer = statusRow:createBlock({})
	statusRightSpacer.widthProportional = 1.0
	statusRightSpacer.autoHeight = true

	local pinDataList = {}



	debugLog("Creating lockpick pins. Count: " .. tostring(pinCount))

	-- Pins.
	local pinOuterBlock = menu:createBlock({})
	pinOuterBlock.flowDirection = "left_to_right"
	pinOuterBlock.autoHeight = true
	pinOuterBlock.widthProportional = 1.0
	pinOuterBlock.borderBottom = 18

	local pinLeftSpacer = pinOuterBlock:createBlock({})
	pinLeftSpacer.widthProportional = 1.0
	pinLeftSpacer.autoHeight = true

	local pinBlock = pinOuterBlock:createBlock({})
	pinBlock.flowDirection = "left_to_right"
	pinBlock.autoHeight = true
	pinBlock.width = pinCount * 95

	local pinRightSpacer = pinOuterBlock:createBlock({})
	pinRightSpacer.widthProportional = 1.0
	pinRightSpacer.autoHeight = true

	local pickButton = nil

	local function updatePickButtonText()
		if not pickButton then
			return
		end

		if activeLockpickData and activeLockpickData.impossible then
			pickButton.text = "Lock Too Complex"
		elseif areAllPinsGreen(pinDataList) then
			pickButton.text = "Unlock"
		else
			pickButton.text = "Reset Pins"
		end
	end

	for i = 1, pinCount do
		createVerticalPinColumn(pinBlock, i, pinDataList, statusLabel, updatePickButtonText)
	end

	-- Button row.
	local buttonOuterBlock = menu:createBlock({})
	buttonOuterBlock.flowDirection = "left_to_right"
	buttonOuterBlock.autoHeight = true
	buttonOuterBlock.widthProportional = 1.0
	buttonOuterBlock.borderTop = 8

	local hasCancelButton = not (activeLockpickData and activeLockpickData.impossible)

	if hasCancelButton then
		local cancelButton = buttonOuterBlock:createButton({
			text = "Cancel",
		})
		cancelButton.width = 120

		cancelButton:register("mouseClick", function()
			playLockedSoundForTarget(activeLockpickTarget)
			closeLockpickMenu("cancelled")
		end)
	end

	local centerSpacerLeft = buttonOuterBlock:createBlock({})
	centerSpacerLeft.widthProportional = 1.0
	centerSpacerLeft.autoHeight = true

	pickButton = buttonOuterBlock:createButton({
		id = ids.pick,
		text = "Reset Pins",
	})
	pickButton.width = 220

	local centerSpacerRight = buttonOuterBlock:createBlock({})
	centerSpacerRight.widthProportional = 1.0
	centerSpacerRight.autoHeight = true

	if hasCancelButton then
		local rightBalanceSpacer = buttonOuterBlock:createBlock({})
		rightBalanceSpacer.width = 120
		rightBalanceSpacer.autoHeight = true
	end

	updatePickButtonText()

	pickButton:register("mouseClick", function()
		local allGreen = true
		local values = {}

		for _, pinData in ipairs(pinDataList) do
			local current = getPinCurrent(pinData)

			table.insert(values, string.format(
				"%d/%d",
				current,
				pinData.target
			))

			if not isPinGreen(pinData) then
				allGreen = false
			end
		end

		debugLog("Lockpick action button pressed. allGreen=" .. tostring(allGreen) .. " values=" .. table.concat(values, ", "))

		-- Pressing the button always spends one use.
		local lockpickBroke = false
		local lockpickName = "Lockpick"

		if activeLockpickData and activeLockpickData.lockpickUseAlreadySpent then
			debugLog("Skipping custom lockpick durability use: vanilla lockPick event already spent one use.")
		elseif activeLockpickData and activeLockpickData.lockpick then
			lockpickBroke, lockpickName = damageEquippedLockpick(
				activeLockpickData.lockpick,
				activeLockpickData.lockpickItemData
			)
		else
			debugLog("Lockpick action button pressed but no active lockpick data was available for durability use.")
		end

		if lockpickBroke then
			tes3.messageBox("The %s has been used up.", lockpickName)
			closeLockpickMenu("lockpick used up")
			return
		end

		if activeLockpickData and activeLockpickData.impossible then
			playLockedSoundForTarget(activeLockpickTarget)
			showMessageDebug("Lock too complex. Pin values: " .. table.concat(values, ", "))

			closeLockpickMenu("lock too complex attempt")
			return
		end

		if allGreen then
			playSound("Open Lock")
			showMessageDebug("Success. Pin values: " .. table.concat(values, ", "))
			tes3.mobilePlayer:exerciseSkill(tes3.skill.security, 2)

			if activeLockpickTarget then
				logReferenceLockState("Before unlock", activeLockpickTarget)

				tes3.unlock({
					reference = activeLockpickTarget,
				})

				logReferenceLockState("After unlock", activeLockpickTarget)
				showMessageDebug("Unlocked target.")
			else
				debugLog("Success had no activeLockpickTarget.")
			end

			closeLockpickMenu("successful pick")
		else
			playSound("Open Lock Fail")
			showMessageDebug("Not aligned. Pin values: " .. table.concat(values, ", "))

			openLockpickMenu()
		end
	end)

	menu:updateLayout()
	scheduleInitialPaint(pinDataList, statusLabel)
	updatePickButtonText()
end


-- ============================================================
-- Lockpick Activation Hook
-- ============================================================

local function onActivate(e)
	if not config.enabled then
		return
	end
	
	if config.lockpickOpenMode ~= "interact"
	and config.lockpickOpenMode ~= "either" then
		return
	end

	if e.activator ~= tes3.player then
		debugLog("Activate ignored: activator is not player.")
		return
	end

	if not e.target then
		debugLog("Activate ignored: no target.")
		return
	end

	local objectType = e.target.object.objectType

	if objectType ~= tes3.objectType.container
	and objectType ~= tes3.objectType.door then
		debugLog("Activate ignored: target is not container or door. Target=" .. getReferenceDebugName(e.target))
		return
	end

	logReferenceLockState("Activate received", e.target)

	local isLocked = getReferenceLocked(e.target)

	if not isLocked then
		debugLog("Activate allowed: target is not currently locked.")
		clearActiveLockpick("activate unlocked target")
		return
	end

	if activeLockpickTarget then
		debugLog("Activate blocked: already lockpicking target " .. getReferenceDebugName(activeLockpickTarget))
		e.block = true
		return false
	end

	local lockLevel = getReferenceLockLevel(e.target)

	if lockLevel <= 0 then
		debugLog("Activate allowed: target reported locked, but lockLevel <= 0. Letting vanilla handle it.")
		clearActiveLockpick("locked true but lockLevel <= 0")
		return
	end

	local lockpick, lockpickItemData = getEquippedLockpick()

	if not lockpick then
		debugLog("Activate blocked: target locked but no lockpick equipped.")
		e.block = true
		playLockedSoundForTarget(e.target)
		return false
	end

	activeLockpickTarget = e.target
	activeLockpickData = calculatePuzzleSettings(lockLevel, lockpick)
	activeLockpickData.lockpickItemData = lockpickItemData
	activeLockpickData.lockpickUseAlreadySpent = false
	if activeLockpickData.successChance >= 100 then
		debugLog(string.format(
			"Auto-unlock: chance %.2f%% >= 100. Target=%s",
			activeLockpickData.successChance,
			getReferenceDebugName(e.target)
		))

		e.block = true

		playSound("Open Lock")
		local lockpickBroke, lockpickName = damageEquippedLockpick(lockpick, lockpickItemData)

		if lockpickBroke then
			tes3.messageBox("The %s has been used up.", lockpickName)
			clearActiveLockpick("lockpick used up during auto-unlock")
			return false
		end
		tes3.unlock({
			reference = e.target,
		})

		tes3.mobilePlayer:exerciseSkill(tes3.skill.security, 2)

		showMessageDebug("Lock opened automatically.")

		clearActiveLockpick("auto-unlock success chance >= 100")

		return false
	end

	debugLog(string.format(
		"Opening minigame for target=%s | lock=%d security=%d agility=%d luck=%d pick=%s pickQuality=%.2f fatigue=%.2f chance=%.2f impossible=%s pins=%d max=%d tolerance=%d",
		getReferenceDebugName(e.target),
		activeLockpickData.lockLevel,
		activeLockpickData.security,
		activeLockpickData.agility,
		activeLockpickData.luck,
		lockpick.id,
		activeLockpickData.equipmentModifier,
		activeLockpickData.fatigueModifier,
		activeLockpickData.successChance,
		tostring(activeLockpickData.impossible),
		activeLockpickData.pinCount,
		activeLockpickData.maxValue,
		activeLockpickData.tolerance
	))

	e.block = true
	openLockpickMenu()

	return false
end



-- ============================================================
-- Lockpick Use Hook
-- ============================================================

local function onLockPick(e)
	if not config.enabled then
		return
	end

	if config.lockpickOpenMode ~= "lockpickUse"
	and config.lockpickOpenMode ~= "either" then
		return
	end

	if not e.picker or e.picker ~= tes3.mobilePlayer then
		return
	end

	if not e.reference or not e.tool then
		return
	end

	if activeLockpickTarget then
		debugLog("lockPick blocked: already lockpicking target " .. getReferenceDebugName(activeLockpickTarget))
		e.block = true
		return false
	end

	local lockLevel = getReferenceLockLevel(e.reference)

	activeLockpickTarget = e.reference
	activeLockpickData = calculatePuzzleSettings(lockLevel, e.tool)
	activeLockpickData.lockpickItemData = e.toolItemData
	activeLockpickData.lockpickUseAlreadySpent = true
	debugLog(string.format(
		"[LOCKPICK EVENT] Opening minigame | reference=%s tool=%s chance=%.2f lockLevel=%d lockPresent=%s hasToolItemData=%s",
		getReferenceDebugName(e.reference),
		e.tool and e.tool.id or "nil",
		e.chance or 0,
		lockLevel,
		tostring(e.lockPresent),
		tostring(e.toolItemData ~= nil)
	))

	e.block = true

	timer.start({
		duration = 0.35,
		type = timer.real,
		callback = function()
			if not activeLockpickTarget then
				debugLog("Delayed lockpick menu open skipped: no active target.")
				return
			end

			openLockpickMenu()
		end,
	})

	return false
end

-- ============================================================
-- Load Handling
-- ============================================================

local function onLoaded()
	clearActiveLockpick("loaded event")
	debugLog("Loaded event complete.")
end

-- ============================================================
-- Initialization
-- ============================================================

local function initialized()
	event.register(tes3.event.activate, onActivate)
	event.register(tes3.event.lockPick, onLockPick)
	event.register(tes3.event.loaded, onLoaded)

	debugLog("Initialized.")
end

event.register(tes3.event.initialized, initialized)