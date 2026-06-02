--[[
	Spell Memory

	Press the configured input (Default: Shift+R) while hovering over spells in the Magic menu to memorize or forget them.
	Hold the configured input to open a quick menu of memorized spells.
]]

local config = require("SpellMemory.config")
require("SpellMemory.mcm")

local logPrefix = "[Spell Memory]"
local playerDataKey = "SpellMemory"

local UI_ID_Menu = tes3ui.registerID("SpellMemory:Menu")
local UI_ID_Title = tes3ui.registerID("SpellMemory:Title")
local UI_ID_List = tes3ui.registerID("SpellMemory:SpellList")
local UI_ID_SelectedLabel = tes3ui.registerID("SpellMemory:SelectedLabel")
local UI_ID_MemoryCountLabel = tes3ui.registerID("SpellMemory:MemoryCountLabel")

local isMenuOpen = false
local openCount = 0
local closeCount = 0

local selectedSpell = nil
local selectedSpellName = nil
local selectedRow = nil
local selectedLabel = nil
local selectedSpellDisplayLabel = nil
local selectedSpellDetailsLabel = nil
local memoryCountLabel = nil

local spellbookHoveredSpell = nil
local spellbookHoveredElement = nil
local registeredSpellbookElements = setmetatable({}, { __mode = "k" })

local spellbookSelectedSpellId = nil
local normalColor = nil
local headerColor = nil
local disabledColor = nil
local activeColor = nil
local finalChanceColor = nil

local refreshSpellbookSpellRows = nil
local getSpellbookCastChanceText

local function debugLog(message, ...)
	if not config.current.debugLog then
		return
	end

	mwse.log(logPrefix .. " " .. message, ...)
end

local function showMessage(message, ...)
	if not config.current.showMessages then
		return
	end

	tes3.messageBox(message, ...)
end

local function refreshPaletteColors()
	normalColor = tes3ui.getPalette(tes3.palette.normalColor)
	headerColor = tes3ui.getPalette(tes3.palette.headerColor)
	disabledColor = tes3ui.getPalette(tes3.palette.disabledColor)
	activeColor = tes3ui.getPalette(tes3.palette.activeColor)
	finalChanceColor = { 0.45, 0.65, 1.0 }
end

local function cleanCombo(combo)
	if type(combo) ~= "table" then
		return {
			mouseButton = 2,
			isShiftDown = false,
			isAltDown = false,
			isControlDown = false,
		}
	end

	if combo.keyCode == false then
		combo.keyCode = nil
	end

	if combo.mouseButton == false then
		combo.mouseButton = nil
	end

	if combo.mouseWheel == false then
		combo.mouseWheel = nil
	end

	if combo.isShiftDown == nil then
		combo.isShiftDown = false
	end

	if combo.isAltDown == nil then
		combo.isAltDown = false
	end

	if combo.isControlDown == nil then
		combo.isControlDown = false
	end

	if combo.keyCode == nil and combo.mouseButton == nil then
		combo.mouseButton = 2
	end

	return combo
end

local function getOpenCombo()
	return cleanCombo(config.current.openCombo)
end

local function getComboDebugText()
	local combo = getOpenCombo()

	if type(combo.mouseButton) == "number" then
		return string.format(
			"mouseButton=%s shift=%s alt=%s ctrl=%s",
			tostring(combo.mouseButton),
			tostring(combo.isShiftDown == true),
			tostring(combo.isAltDown == true),
			tostring(combo.isControlDown == true)
		)
	end

	if type(combo.keyCode) == "number" then
		return string.format(
			"keyCode=%s shift=%s alt=%s ctrl=%s",
			tostring(combo.keyCode),
			tostring(combo.isShiftDown == true),
			tostring(combo.isAltDown == true),
			tostring(combo.isControlDown == true)
		)
	end

	return "unbound"
end

local function canOpenMenuNow()
	if not config.current.enabled then
		return false, "disabled"
	end

	if not tes3.player or not tes3.mobilePlayer then
		return false, "player unavailable"
	end

	if tes3ui.menuMode() then
		return false, "menu mode"
	end

	return true, "ok"
end

local function canChangeMemorizedSpells()
	if not config.current.requireTownOrCity then
		return true, "ok"
	end

	if not tes3.player or not tes3.player.cell then
		return false, "player cell unavailable"
	end

	if not tes3.player.cell.restingIsIllegal then
		return false, "not in town or city"
	end

	return true, "ok"
end

local function getSpellName(spell)
	if not spell then
		return "Unknown Spell"
	end

	if spell.name and spell.name ~= "" then
		return spell.name
	end

	return spell.id or "Unknown Spell"
end

local function getSpellId(spell)
	if not spell then
		return "unknown"
	end

	return spell.id or "unknown"
end

local function isShownSpell(spell)
	if not spell then
		return false
	end

	if spell.castType == tes3.spellType.ability then
		return false
	end

	if spell.castType == tes3.spellType.disease then
		return false
	end

	if spell.castType == tes3.spellType.blightDisease then
		return false
	end

	if spell.castType == tes3.spellType.curse then
		return false
	end

	return true
end

local function getSpellMemoryCost(spell)
	local cost = tonumber(spell and spell.magickaCost) or 0

	if cost < 20 then
		return 1
	elseif cost < 50 then
		return 2
	elseif cost < 100 then
		return 3
	elseif cost < 180 then
		return 4
	end

	return 5
end

local function getLevelMemoryCap(level)
	level = math.max(1, tonumber(level) or 1)

	local levelOneCap = tonumber(config.current.levelOneMemoryCap) or 10
	local levelHundredCap = tonumber(config.current.maxMemory) or 50
	local curvePower = tonumber(config.current.levelCurvePower) or 0.65

	if levelOneCap < 1 then
		levelOneCap = 1
	end

	if levelOneCap > 255 then
		levelOneCap = 255
	end

	if levelHundredCap < 1 then
		levelHundredCap = 1
	end

	if levelHundredCap > 255 then
		levelHundredCap = 255
	end

	if levelHundredCap < levelOneCap then
		levelHundredCap = levelOneCap
	end

	if curvePower < 0.25 then
		curvePower = 0.25
	end

	if curvePower > 1.25 then
		curvePower = 1.25
	end

	local progress = (level - 1) / 99

	if progress < 0 then
		progress = 0
	end

	if progress > 1 then
		progress = 1
	end

	local curvedProgress = progress ^ curvePower
	local cap = levelOneCap + ((levelHundredCap - levelOneCap) * curvedProgress)

	return math.floor(cap + 0.5)
end

local function getMemoryCapacity()
	local intelligence = 0
	local willpower = 0
	local level = 1

	if tes3.mobilePlayer then
		if tes3.mobilePlayer.intelligence then
			intelligence = tonumber(tes3.mobilePlayer.intelligence.current) or 0
		end

		if tes3.mobilePlayer.willpower then
			willpower = tonumber(tes3.mobilePlayer.willpower.current) or 0
		end
	end

	if tes3.player and tes3.player.object and tes3.player.object.level then
		level = tonumber(tes3.player.object.level) or 1
	elseif tes3.mobilePlayer and tes3.mobilePlayer.level then
		level = tonumber(tes3.mobilePlayer.level) or 1
	end

	local levelCap = getLevelMemoryCap(level)
	local weightedAttribute = (intelligence * 0.75) + (willpower * 0.25)
	local minimumAttributeFactor = tonumber(config.current.minimumAttributeFactor) or 0.60

	if minimumAttributeFactor < 0.25 then
		minimumAttributeFactor = 0.25
	end

	if minimumAttributeFactor > 1.0 then
		minimumAttributeFactor = 1.0
	end

	local attributeFactor = minimumAttributeFactor + ((weightedAttribute / 100) * (1.0 - minimumAttributeFactor))

	if attributeFactor > 1.0 then
		attributeFactor = 1.0
	end

	if attributeFactor < minimumAttributeFactor then
		attributeFactor = minimumAttributeFactor
	end

	local capacity = math.floor(levelCap * attributeFactor + 0.5)

	if capacity < 1 then
		capacity = 1
	end

	return capacity
end

local function ensurePlayerData()
	if not tes3.player then
		return nil
	end

	tes3.player.data[playerDataKey] = tes3.player.data[playerDataKey] or {}

	local data = tes3.player.data[playerDataKey]
	data.memorizedSpells = data.memorizedSpells or {}

	return data
end

local function getMemorizedTable()
	local data = ensurePlayerData()

	if not data then
		return {}
	end

	return data.memorizedSpells
end

local function isSpellMemorized(spell)
	local spellId = getSpellId(spell)

	if spellId == "unknown" then
		return false
	end

	return getMemorizedTable()[spellId] == true
end

local function getMemorizedCount()
	local memorized = getMemorizedTable()
	local count = 0

	for _, value in pairs(memorized) do
		if value == true then
			count = count + 1
		end
	end

	return count
end

local function getMemoryUsed()
	local used = 0

	if not tes3.player or not tes3.player.object or not tes3.player.object.spells then
		return used
	end

	for _, spell in pairs(tes3.player.object.spells) do
		if isShownSpell(spell) and isSpellMemorized(spell) then
			used = used + getSpellMemoryCost(spell)
		end
	end

	return used
end

local function updateMemoryCountLabel()
	if not memoryCountLabel then
		return
	end

	memoryCountLabel.text = string.format(
		"Memorized: %d / %d",
		getMemoryUsed(),
		getMemoryCapacity()
	)

	memoryCountLabel.color = headerColor
	memoryCountLabel:updateLayout()
end

local function toggleMemorizedSpell(spell)
	if not spell then
		return
	end

	local canChange, reason = canChangeMemorizedSpells()

	if not canChange then
		showMessage("You need to be in a town or city to memorize or forget spells.")

		debugLog(
			"Memorize/forget blocked. reason=%s spell='%s' cell='%s'",
			tostring(reason),
			getSpellName(spell),
			tostring(tes3.player and tes3.player.cell and tes3.player.cell.name)
		)

		return
	end

	local spellId = getSpellId(spell)
	local spellName = getSpellName(spell)
	local spellCost = getSpellMemoryCost(spell)

	if spellId == "unknown" then
		debugLog("Cannot memorize spell with unknown id. name='%s'", spellName)
		return
	end

	local memorized = getMemorizedTable()

	if memorized[spellId] == true then
		memorized[spellId] = nil

		showMessage("Forgotten\n\n%s\nMemory: %d / %d", spellName, getMemoryUsed(), getMemoryCapacity())

		debugLog(
			"Forgotten spell. name='%s' id='%s' spellCost=%d memoryUsed=%d/%d memorizedCount=%d",
			spellName,
			spellId,
			spellCost,
			getMemoryUsed(),
			getMemoryCapacity(),
			getMemorizedCount()
		)
	else
		local used = getMemoryUsed()
		local capacity = getMemoryCapacity()

		if used + spellCost > capacity then
			showMessage("Not enough memory.\n%s costs %d.\nAvailable: %d / %d", spellName, spellCost, used, capacity)

			debugLog(
				"Memorize blocked by memory cost. name='%s' id='%s' spellCost=%d memoryUsed=%d capacity=%d",
				spellName,
				spellId,
				spellCost,
				used,
				capacity
			)

			if refreshSpellbookSpellRows then
				refreshSpellbookSpellRows()
			end

			return
		end

		memorized[spellId] = true

		showMessage("Memorized\n\n%s\nAvailable: %d / %d", spellName, getMemoryUsed(), getMemoryCapacity())

		debugLog(
			"Memorized spell. name='%s' id='%s' spellCost=%d memoryUsed=%d/%d memorizedCount=%d",
			spellName,
			spellId,
			spellCost,
			getMemoryUsed(),
			getMemoryCapacity(),
			getMemorizedCount()
		)
	end

	updateMemoryCountLabel()

	if refreshSpellbookSpellRows then

		refreshSpellbookSpellRows()
	end
end

local function findKnownPlayerSpellById(spellId)
	if not spellId then
		return nil
	end

	if not tes3.player or not tes3.player.object or not tes3.player.object.spells then
		return nil
	end

	for _, spell in pairs(tes3.player.object.spells) do
		if spell and spell.id == spellId then
			return spell
		end
	end

	return nil
end

local function getSpellbookDisplayText(spell)
	return getSpellName(spell)
end

local function refreshSpellbookMemoryHeader(menu)
	if not menu then
		return 0
	end

	local changedCount = 0

	local memoryUsed = getMemoryUsed()
	local memoryCapacity = getMemoryCapacity()
	local memoryAvailable = math.max(0, memoryCapacity - memoryUsed)

	local memoryText = string.format(
		"Spells\n[Available Memory: %d/%d]",
		memoryAvailable,
		memoryCapacity
	)

	local function scan(element, depth)
		if not element or depth > 24 then
			return
		end

		local text = nil

		pcall(function()
			if element.text and element.text ~= "" then
				text = tostring(element.text)
			end
		end)

		if text then
			local newText = nil

			if text == "Spells" or text:find("^Spells\n%[Available Memory:%s+%d+/%d+%]$") then
				newText = memoryText
			elseif text == "Cost/Chance" then
				newText = "Memory Cost     Magicka/Chance"
			end

			if newText and element.text ~= newText then
				element.text = newText
				changedCount = changedCount + 1
			end
		end

		if element.children then
			for _, child in pairs(element.children) do
				scan(child, depth + 1)
			end
		end
	end

	scan(menu, 0)

	return changedCount
end

local function getElementIndexInParent(element)
	if not element or not element.parent or not element.parent.children then
		return nil
	end

	for index, child in pairs(element.parent.children) do
		if child == element then
			return index
		end
	end

	return nil
end

local function collectTextElements(element, result, depth)
	if not element or depth > 8 then
		return
	end

	local text = nil

	pcall(function()
		if element.text and element.text ~= "" then
			text = tostring(element.text)
		end
	end)

	if text then
		table.insert(result, element)
	end

	if element.children then
		for _, child in pairs(element.children) do
			collectTextElements(child, result, depth + 1)
		end
	end
end

local function updateSpellbookRightSideValue(spell, spellNameElement)
	local spellIndex = getElementIndexInParent(spellNameElement)

	if not spellIndex then
		return 0
	end

	local spellColumn = spellNameElement.parent

	if not spellColumn or not spellColumn.parent or not spellColumn.parent.children then
		return 0
	end

	local rowContainer = spellColumn.parent
	local spellColumnIndex = getElementIndexInParent(spellColumn)

	if not spellColumnIndex then
		return 0
	end

	local costColumn = rowContainer.children[spellColumnIndex + 1]
	local chanceColumn = rowContainer.children[spellColumnIndex + 2]

	if not costColumn or not chanceColumn then
		return 0
	end

	local changedCount = 0

	local costElements = {}
	collectTextElements(costColumn, costElements, 0)

	local chanceElements = {}
	collectTextElements(chanceColumn, chanceElements, 0)

	local costElement = costElements[spellIndex]
	local chanceElement = chanceElements[spellIndex]

	local intendedCostText = string.format("%d                      ", getSpellMemoryCost(spell)) -- Memory Cost     Magicka/Chance
	local intendedChanceText = string.format(
		"%s/%s",
		tostring(spell.magickaCost or "?"),
		getSpellbookCastChanceText(spell)
	)

	if costElement then
		if costElement.text ~= intendedCostText then
			costElement.text = intendedCostText
			changedCount = changedCount + 1
		end
	end

	if chanceElement then
		if chanceElement.text ~= intendedChanceText then
			chanceElement.text = intendedChanceText
			changedCount = changedCount + 1
		end
	end

	return changedCount
end

local memorizedColor = { 0.3, 1.0, 0.3 }
local activeMemorizedColor = { 0.50, 2.0, 2.0 }

-- Lookup Table
local function buildShownSpellsByName()
	local spellsByName = {}

	if not tes3.player or not tes3.player.object or not tes3.player.object.spells then
		return spellsByName
	end

	for _, spell in pairs(tes3.player.object.spells) do
		if isShownSpell(spell) then
			spellsByName[getSpellName(spell)] = spell
		end
	end

	return spellsByName
end

-- Refresh Spellbook rows

refreshSpellbookSpellRows = function()
--	showMessage("Refreshed")
	local menu = tes3ui.findMenu("MenuMagic")

	if not menu or menu.visible == false then
		spellbookHoveredSpell = nil
		spellbookHoveredElement = nil
		return
	end

	refreshPaletteColors()
	local spellsByName = buildShownSpellsByName()
	local changedCount = refreshSpellbookMemoryHeader(menu)
	local hoverRegisteredCount = 0

	local function scan(element, depth)
		if not element or depth > 24 then
			return
		end

		local text = nil

		pcall(function()
			if element.text and element.text ~= "" then
				text = tostring(element.text)
			end
		end)

		if text and depth >= 10 then
			local spell = spellsByName[text]

			if spell then
				local newText = getSpellbookDisplayText(spell)

				if element.text ~= newText then
					element.text = newText
					changedCount = changedCount + 1
				end

				changedCount = changedCount + updateSpellbookRightSideValue(spell, element)

				local spellId = string.lower(tostring(getSpellId(spell)))
				local isActiveSpell = spellbookSelectedSpellId and spellId == spellbookSelectedSpellId
				local isMemorized = isSpellMemorized(spell)

				local targetColor = normalColor

				if isMemorized then
					targetColor = memorizedColor
				end

				if isActiveSpell then
					targetColor = activeColor
				end

				if isActiveSpell and isMemorized then
					targetColor = activeMemorizedColor
				end

				element.color = targetColor
				changedCount = changedCount + 1

				if tes3.uiEvent and tes3.uiEvent.mouseOver and not registeredSpellbookElements[element] then
					element:register(tes3.uiEvent.mouseOver, function()
						spellbookHoveredSpell = spell
						spellbookHoveredElement = element

						debugLog(
							"Spellbook row hovered. name='%s' id='%s' memorized=%s memoryCost=%d",
							getSpellName(spell),
							getSpellId(spell),
							tostring(isSpellMemorized(spell)),
							getSpellMemoryCost(spell)
						)
					end)

					if tes3.uiEvent.mouseLeave then
						element:register(tes3.uiEvent.mouseLeave, function()
							if spellbookHoveredElement == element then
								spellbookHoveredSpell = nil
								spellbookHoveredElement = nil
							end
						end)
					end

					registeredSpellbookElements[element] = true
					hoverRegisteredCount = hoverRegisteredCount + 1
				end
			end
		end

		if element.children then
			for _, child in pairs(element.children) do
				scan(child, depth + 1)
			end
		end
	end

	scan(menu, 0)

	if changedCount > 0 or hoverRegisteredCount > 0 then
		menu:updateLayout()

		debugLog(
			"Spellbook rows refreshed. changed=%d hoverRegistered=%d",
			changedCount,
			hoverRegisteredCount
		)
	end
end

local function collectPlayerSpells()
	local result = {}

	if not tes3.player or not tes3.player.object or not tes3.player.object.spells then
		debugLog("Cannot collect spells. Player spell list unavailable.")
		return result
	end

	local totalSeen = 0
	local hiddenSeen = 0
	local memorizedSeen = 0

	for _, spell in pairs(tes3.player.object.spells) do
		totalSeen = totalSeen + 1

		if isShownSpell(spell) then
			if isSpellMemorized(spell) then
				memorizedSeen = memorizedSeen + 1
				table.insert(result, spell)
			end
		else
			hiddenSeen = hiddenSeen + 1
		end
	end

	table.sort(result, function(a, b)
		return getSpellName(a):lower() < getSpellName(b):lower()
	end)

	debugLog(
		"Collected spells. total=%d memorizedShown=%d hidden=%d memoryUsed=%d/%d",
		totalSeen,
		memorizedSeen,
		hiddenSeen,
		getMemoryUsed(),
		getMemoryCapacity()
	)

	return result
end

local function getEffectRangeText(rangeType)
	if rangeType == tes3.effectRange.self then
		return "on self"
	elseif rangeType == tes3.effectRange.touch then
		return "on touch"
	elseif rangeType == tes3.effectRange.target then
		return "on target"
	end

	return "on unknown"
end

local function isRealEffect(effect)
	if not effect then
		return false
	end

	if effect.id == nil then
		return false
	end

	if tonumber(effect.id) == -1 then
		return false
	end

	if not effect.object then
		return false
	end

	return true
end

local function getEffectName(effect)
	if effect and effect.object and effect.object.name and effect.object.name ~= "" then
		return effect.object.name
	end

	return tostring(effect and effect.id or "Unknown Effect")
end

local function getEffectMagnitudeText(effect)
	local min = tonumber(effect and effect.min) or 0
	local max = tonumber(effect and effect.max) or 0

	if min <= 0 and max <= 0 then
		return ""
	end

	if min == max then
		return string.format(" %d pts", min)
	end

	return string.format(" %d-%d pts", min, max)
end

local function getEffectDurationText(effect)
	local duration = tonumber(effect and effect.duration) or 0

	if duration <= 0 then
		return ""
	end

	return string.format(" for %d sec", duration)
end

local function getEffectRadiusText(effect)
	local radius = tonumber(effect and effect.radius) or 0

	if radius <= 0 then
		return ""
	end

	return string.format(" in %d ft", radius)
end


-- Spell Chance Calculations
local function getSpellCastChanceText(spell)
	if not spell or type(spell.calculateCastChance) ~= "function" then
		return "?"
	end

	local caster = tes3.mobilePlayer or tes3.player

	if not caster then
		return "?"
	end

	local success, chanceOrError = pcall(function()
		return spell:calculateCastChance({
			caster = caster,
			checkMagicka = true,
		})
	end)

	if not success then
		debugLog(
			"Cast chance calculation failed. name='%s' id='%s' error=%s",
			getSpellName(spell),
			getSpellId(spell),
			tostring(chanceOrError)
		)

		return "?"
	end

	local baseChance = tonumber(chanceOrError)

	if not baseChance then
		return "?"
	end

	local finalChance = baseChance

	if isSpellMemorized(spell) then
		if config.current.memorizedBonusEnabled then
			local bonus = tonumber(config.current.memorizedCastChanceBonus) or 0
			finalChance = baseChance * (1 + (bonus / 100))
		end
	else
		if config.current.unmemorizedPenaltyEnabled then
			local penalty = tonumber(config.current.unmemorizedCastChancePenalty) or 0
			finalChance = baseChance * (1 - (penalty / 100))
		end
	end

	if baseChance > 100 then
		baseChance = 100
	end

	if baseChance < 0 then
		baseChance = 0
	end

	if finalChance > 100 then
		finalChance = 100
	end

	if finalChance < 0 then
		finalChance = 0
	end

	baseChance = math.floor(baseChance + 0.5)
	finalChance = math.floor(finalChance + 0.5)

	local modifier = finalChance - baseChance

	if modifier > 0 then
		return string.format("%d%%+%d%%= %d%%", baseChance, modifier, finalChance)
	elseif modifier < 0 then
		return string.format("%d%%%d%%= %d%%", baseChance, modifier, finalChance)
	end

	return string.format("%d%%", baseChance)
end

getSpellbookCastChanceText = function(spell)
	local chanceText = getSpellCastChanceText(spell)

	return chanceText:match("= ?(%d+%%)$") or chanceText
end

local function getSpellEffectDescriptionText(spell)
	if not spell then
		return "Mouse over a spell to see its effects.\n"
	end

	local effectLines = {}

	if spell.effects then
		for _, effect in ipairs(spell.effects) do
			if isRealEffect(effect) then
				table.insert(effectLines, string.format(
					"%s%s%s%s %s",
					getEffectName(effect),
					getEffectMagnitudeText(effect),
					getEffectDurationText(effect),
					getEffectRadiusText(effect),
					getEffectRangeText(effect.rangeType)
				))
			end
		end
	end

	if #effectLines > 0 then
		return table.concat(effectLines, "; ")
	end

	return "No effect data found."
end

local function getSpellDetailsText(spell)
	if not spell then
		return "Mouse over a spell to see its effects.\n"
	end

	return string.format(
		"%s | Magicka %s | Chance %s | Memory %d",
		getSpellEffectDescriptionText(spell),
		tostring(spell.magickaCost or "?"),
		getSpellCastChanceText(spell),
		getSpellMemoryCost(spell)
	)
end

local function clearSelectedVisual()
	if selectedRow then
		pcall(function()
			selectedRow.borderAllSides = 0
			selectedRow.borderTop = 0
			selectedRow.borderBottom = 0
		end)
	end

	if selectedLabel then
		pcall(function()
			selectedLabel.color = normalColor
		end)
	end

	selectedRow = nil
	selectedLabel = nil
end

local function updateSelectedSpellDisplay()
	if selectedSpellDisplayLabel then
		if selectedSpell then
			selectedSpellDisplayLabel.text = string.format("%s", selectedSpellName or getSpellName(selectedSpell))
			selectedSpellDisplayLabel.color = activeColor
		else
			selectedSpellDisplayLabel.text = "Selected: none"
			selectedSpellDisplayLabel.color = disabledColor
		end

		selectedSpellDisplayLabel:updateLayout()
	end

	if selectedSpellDetailsLabel then
		selectedSpellDetailsLabel:destroyChildren()

		if selectedSpell then
			local descriptionLabel = selectedSpellDetailsLabel:createLabel({
				text = getSpellEffectDescriptionText(selectedSpell),
			})
			descriptionLabel.color = normalColor
			descriptionLabel.wrapText = false

			local statLine = selectedSpellDetailsLabel:createBlock()
			statLine.flowDirection = tes3.flowDirection.leftToRight
			statLine.autoWidth = true
			statLine.height = 24

			local chanceText = getSpellCastChanceText(selectedSpell)
			local chanceBeforeFinal, finalChance = chanceText:match("^(.-= )(%d+%%)$")

			local beforeLabel = statLine:createLabel({
				text = string.format("Cost: %s | Chance:", tostring(selectedSpell.magickaCost or "?")),
			})
			beforeLabel.color = normalColor

			local chanceSpacer = statLine:createBlock()
			chanceSpacer.width = 8
			chanceSpacer.height = 1

			if chanceBeforeFinal and finalChance then
				local chanceBeforeLabel = statLine:createLabel({
					text = chanceBeforeFinal,
				})
				chanceBeforeLabel.color = normalColor

				local finalChanceLabel = statLine:createLabel({
					text = finalChance,
				})
				finalChanceLabel.color = finalChanceColor
			else
				local chanceLabel = statLine:createLabel({
					text = chanceText,
				})
				chanceLabel.color = normalColor
			end

			local memoryLabel = statLine:createLabel({
				text = string.format(" | Memory: %d", getSpellMemoryCost(selectedSpell)),
			})
			memoryLabel.color = normalColor
		else
			local placeholder = selectedSpellDetailsLabel:createLabel({
				text = "Mouse over a spell to see its effects.\n",
			})
			placeholder.color = disabledColor
		end

		selectedSpellDetailsLabel:updateLayout()
	end
end

local function setSelectedSpell(spell, row, label, source)
	if selectedSpell == spell then
		return
	end

	clearSelectedVisual()

	selectedSpell = spell
	selectedSpellName = getSpellName(spell)
	selectedRow = row
	selectedLabel = label

	if selectedRow then
		selectedRow.borderAllSides = 1
		selectedRow.borderTop = 1
		selectedRow.borderBottom = 1
	end

	if selectedLabel then
		selectedLabel.color = activeColor
	end

	updateSelectedSpellDisplay()

	debugLog(
		"Selected spell. source=%s name='%s' id='%s' memoryCost=%d",
		tostring(source),
		getSpellName(spell),
		getSpellId(spell),
		getSpellMemoryCost(spell)
	)
end

local function resetSelectionState()
	selectedSpell = nil
	selectedSpellName = nil
	selectedRow = nil
	selectedLabel = nil
	selectedSpellDisplayLabel = nil
	selectedSpellDetailsLabel = nil
	memoryCountLabel = nil
end

local function leaveMemoryMenuMode(reason)
	if not isMenuOpen then
		return
	end

	local success, errorMessage = pcall(tes3ui.leaveMenuMode)

	if success then
		debugLog("Left menu mode. reason=%s", tostring(reason))
	else
		debugLog("Failed to leave menu mode. reason=%s error=%s", tostring(reason), tostring(errorMessage))
	end
end

local function readySelectedSpell(reason)
	if not selectedSpell then
		debugLog("No selected spell to ready. reason=%s", tostring(reason))
		return false
	end

	if not isSpellMemorized(selectedSpell) then
		showMessage("Not memorized: %s", getSpellName(selectedSpell))
		return false
	end

	if not tes3.mobilePlayer then
		debugLog("Cannot ready spell. mobilePlayer unavailable.")
		return false
	end

	local success, resultOrError = pcall(function()
		return tes3.mobilePlayer:equipMagic({
			source = selectedSpell,
			updateGUI = true,
		})
	end)

	if not success then
		debugLog(
			"Ready spell failed. reason=%s name='%s' id='%s' error=%s",
			tostring(reason),
			getSpellName(selectedSpell),
			getSpellId(selectedSpell),
			tostring(resultOrError)
		)

		return false
	end

	spellbookSelectedSpellId = string.lower(tostring(getSpellId(selectedSpell)))

	if resultOrError == true then

	end

	debugLog(
		"Ready spell result. reason=%s name='%s' id='%s' result=%s",
		tostring(reason),
		getSpellName(selectedSpell),
		getSpellId(selectedSpell),
		tostring(resultOrError)
	)

	return resultOrError == true
end

local function destroyMemoryMenu(reason)
	local menu = tes3ui.findMenu(UI_ID_Menu)

	if selectedSpell then
		readySelectedSpell(reason)
	else
		debugLog("Menu closed with no selected spell. reason=%s", tostring(reason))
	end

	leaveMemoryMenuMode(reason)

	if menu then
		menu:destroy()
		closeCount = closeCount + 1
		debugLog("Closed menu. reason=%s closeCount=%d", tostring(reason), closeCount)
	end

	isMenuOpen = false
	resetSelectionState()
end

local function getSpellListLabelText(spell)
	return string.format("%s (%d)", getSpellName(spell), getSpellMemoryCost(spell))
end

local function createSelectableSpellCell(cell, spell, spellIndex, rowIndex, columnIndex)
	local row = cell:createBlock()
	row.flowDirection = tes3.flowDirection.leftToRight
	row.width = 320
	row.height = 20
	row.paddingLeft = 3
	row.paddingRight = 3
	row.childAlignY = 0.5
	row.consumeMouseEvents = true

	local label = row:createLabel({
		text = getSpellListLabelText(spell),
	})

	label.color = normalColor
	label.consumeMouseEvents = true

	local function onHover()
		setSelectedSpell(spell, row, label, "hover")
	end

	if tes3.uiEvent and tes3.uiEvent.mouseOver then
		local success, errorMessage = pcall(function()
			row:register(tes3.uiEvent.mouseOver, onHover)
			label:register(tes3.uiEvent.mouseOver, onHover)
		end)

		if not success then
			debugLog(
				"Failed to register spell hover. index=%d name='%s' error=%s",
				spellIndex,
				getSpellName(spell),
				tostring(errorMessage)
			)
		end
	end

	debugLog(
		"Created spell cell. index=%d row=%d column=%d memoryCost=%d name='%s'",
		spellIndex,
		rowIndex,
		columnIndex,
		getSpellMemoryCost(spell),
		getSpellName(spell)
	)
end

local function createSpellGrid(parent, spells)
	local listBlock = parent:createBlock({
		id = UI_ID_List,
	})

	listBlock.flowDirection = tes3.flowDirection.topToBottom
	listBlock.width = 880
	listBlock.autoHeight = true
	listBlock.paddingTop = 8

	if #spells == 0 then
		local label = listBlock:createLabel({
			text = "No memorized spells found.",
		})

		label.color = normalColor

		local hint = listBlock:createLabel({
			text = "Open the magic menu and use your Spell Memory keybind on a spell row to memorize it.",
		})

		hint.color = disabledColor
		hint.wrapText = true
		hint.width = 860

		return
	end

	local hintLabel = listBlock:createLabel({
		text = "Hover to select. Release input to ready spell.",
	})

	hintLabel.color = disabledColor
	hintLabel.wrapText = true
	hintLabel.width = 860

	local spacer = listBlock:createBlock()
	spacer.width = 1
	spacer.height = 6

	local border = listBlock:createThinBorder({})
	border.flowDirection = tes3.flowDirection.topToBottom
	border.width = 880
	border.height = 500
	border.childAlignX = 0.0
	border.childAlignY = 0.0

	local scrollPane = border:createVerticalScrollPane({})
	scrollPane.width = 860
	scrollPane.height = 500

	local scrollContent = scrollPane:findChild(tes3ui.registerID("PartScrollPane_pane"))

	if not scrollContent then
		debugLog("Scroll pane content element not found.")
		return
	end

	scrollContent.flowDirection = tes3.flowDirection.topToBottom
	scrollContent.width = 840
	scrollContent.autoHeight = true

	local columns = 2
	local rows = math.ceil(#spells / columns)

	if rows < 1 then
		rows = 1
	end

	for rowIndex = 1, rows do
		local row = scrollContent:createBlock()
		row.flowDirection = tes3.flowDirection.leftToRight
		row.width = 860
		row.height = 20

		for columnIndex = 1, columns do
			local spellIndex = ((rowIndex - 1) * columns) + columnIndex
			local spell = spells[spellIndex]

			local cell = row:createBlock()
			cell.flowDirection = tes3.flowDirection.leftToRight
			cell.width = 430
			cell.height = 20
			cell.paddingRight = 8

			if spell then
				createSelectableSpellCell(cell, spell, spellIndex, rowIndex, columnIndex)
			end
		end
	end
end

local function enterMemoryMenuMode()
	local success, errorMessage = pcall(tes3ui.enterMenuMode, UI_ID_Menu)

	if success then
		debugLog("Entered menu mode.")
	else
		debugLog("Failed to enter menu mode. error=%s", tostring(errorMessage))
	end
end

local function createMemoryMenu()
	if isMenuOpen or tes3ui.findMenu(UI_ID_Menu) then
		return
	end

	refreshPaletteColors()
	resetSelectionState()
	ensurePlayerData()

	local spells = collectPlayerSpells()

	local menu = tes3ui.createMenu({
		id = UI_ID_Menu,
		fixedFrame = true,
		dragFrame = false,
	})

	menu.width = 1000
	menu.height = 700
	menu.absolutePosAlignX = 0.5
	menu.absolutePosAlignY = 0.5
	menu.alpha = 1.0

	local outer = menu:createBlock()
	outer.flowDirection = tes3.flowDirection.topToBottom
	outer.width = 1000
	outer.height = 700
	outer.paddingAllSides = 20
	outer.childAlignX = 0.5
	outer.childAlignY = 0.0

	local title = outer:createLabel({
		id = UI_ID_Title,
		text = "SPELL MEMORY",
	})

	title.color = headerColor

	local memoryUsed = getMemoryUsed()
	local memoryCapacity = getMemoryCapacity()
	local memoryAvailable = math.max(0, memoryCapacity - memoryUsed)

	memoryCountLabel = outer:createLabel({
		id = UI_ID_MemoryCountLabel,
		text = string.format(
			"Available Memory: %d/%d",
			memoryAvailable,
			memoryCapacity
		),
	})

	memoryCountLabel.color = headerColor

	selectedSpellDisplayLabel = outer:createLabel({
		id = UI_ID_SelectedLabel,
		text = "Selected: none",
	})

	selectedSpellDisplayLabel.color = disabledColor

	selectedSpellDetailsLabel = outer:createBlock()
	selectedSpellDetailsLabel.flowDirection = tes3.flowDirection.topToBottom
	selectedSpellDetailsLabel.width = 880
	selectedSpellDetailsLabel.height = 48
	selectedSpellDetailsLabel.childAlignX = 0.5

	local selectedSpellDetailsPlaceholder = selectedSpellDetailsLabel:createLabel({
		text = "Mouse over a spell to see its effects.\n",
	})

	selectedSpellDetailsPlaceholder.color = disabledColor

	createSpellGrid(outer, spells)

	menu:updateLayout()

	isMenuOpen = true
	openCount = openCount + 1

	enterMemoryMenuMode()

	debugLog(
		"Opened menu. openCount=%d spellCount=%d memoryUsed=%d/%d memorizedCount=%d combo=%s",
		openCount,
		#spells,
		getMemoryUsed(),
		getMemoryCapacity(),
		getMemorizedCount(),
		getComboDebugText()
	)
end


-- Keybinding shit
local function modifiersMatch(combo, e)
	if combo.isShiftDown ~= nil and combo.isShiftDown ~= (e.isShiftDown == true) then
		return false
	end

	if combo.isAltDown ~= nil and combo.isAltDown ~= (e.isAltDown == true) then
		return false
	end

	if combo.isControlDown ~= nil and combo.isControlDown ~= (e.isControlDown == true) then
		return false
	end

	return true
end

local function keyboardInputMatches(e)
	local combo = getOpenCombo()

	if type(combo.keyCode) ~= "number" then
		return false
	end

	if e.keyCode ~= combo.keyCode then
		return false
	end

	return modifiersMatch(combo, e)
end

local function mouseInputMatches(e)
	local combo = getOpenCombo()

	if type(combo.mouseButton) ~= "number" then
		return false
	end

	if e.button ~= combo.mouseButton then
		return false
	end

	return modifiersMatch(combo, e)
end



local function openMenuFromKeyboard(e)
	if not keyboardInputMatches(e) then
		return
	end

	if tes3ui.menuMode() and tes3ui.findMenu("MenuMagic") then
		local spell = spellbookHoveredSpell

		if spell and spellbookHoveredElement and findKnownPlayerSpellById(getSpellId(spell)) and isShownSpell(spell) then
			toggleMemorizedSpell(spell)
		else
			debugLog("Keyboard input in MenuMagic, but no spell row was hovered.")
		end

		return
	end

	local canOpen, reason = canOpenMenuNow()

	if not canOpen then
		debugLog("Keyboard input matched, but menu did not open. reason=%s", tostring(reason))
		return
	end

	createMemoryMenu()
end

local function openMenuFromMouse(e)
	if not mouseInputMatches(e) then
		return
	end

	if tes3ui.menuMode() and tes3ui.findMenu("MenuMagic") then
		local spell = spellbookHoveredSpell

		if spell and spellbookHoveredElement and findKnownPlayerSpellById(getSpellId(spell)) and isShownSpell(spell) then
			toggleMemorizedSpell(spell)
		else
			debugLog("Mouse input in MenuMagic, but no spell row was hovered.")
		end

		return
	end

	local canOpen, reason = canOpenMenuNow()

	if not canOpen then
		debugLog("Mouse input matched, but menu did not open. reason=%s", tostring(reason))
		return
	end

	createMemoryMenu()
end

local function closeMenuFromKeyboard(e)
	if not keyboardInputMatches(e) then
		return
	end

	destroyMemoryMenu("keyboard_released")
end

local function closeMenuFromMouse(e)
	if not mouseInputMatches(e) then
		return
	end

	if tes3ui.findMenu("MenuMagic") and not isMenuOpen then
		return
	end

	destroyMemoryMenu("mouse_released")
end

local function onMagicSelectionChanged(e)
	spellbookHoveredSpell = nil
	spellbookHoveredElement = nil

	if not e or not e.source then
		spellbookSelectedSpellId = nil
	else
		spellbookSelectedSpellId = string.lower(tostring(e.source.id))

		local knownSpell = findKnownPlayerSpellById(e.source.id)

		if knownSpell and isShownSpell(knownSpell) then
			debugLog(
				"Magic selection changed. name='%s' id='%s' memoryCost=%d memorized=%s",
				getSpellName(knownSpell),
				getSpellId(knownSpell),
				getSpellMemoryCost(knownSpell),
				tostring(isSpellMemorized(knownSpell))
			)
		end
	end

	local menu = tes3ui.findMenu("MenuMagic")
	if not menu or menu.visible == false then
		return
	end

	timer.start({
		duration = 0.01,
		type = timer.real,
		callback = function()
			refreshSpellbookSpellRows()
		end
	})
end


---- Spell Benefit/Penalty calculations
local function onSpellCast(e)
	if not config.current.enabled then
		return
	end

	if not e then
		return
	end

	if e.caster ~= tes3.mobilePlayer and e.caster ~= tes3.player then
		return
	end

	local spell = e.source

	if not spell or not isShownSpell(spell) then
		return
	end

	local oldChance = tonumber(e.castChance) or 0
	local newChance = oldChance

	if isSpellMemorized(spell) then
		if not config.current.memorizedBonusEnabled then
			return
		end

		local bonus = tonumber(config.current.memorizedCastChanceBonus) or 0

		if bonus <= 0 then
			return
		end

		if bonus > 95 then
			bonus = 95
		end

		newChance = oldChance * (1 + (bonus / 100))

		if newChance > 100 then
			newChance = 100
		end

		e.castChance = newChance

		debugLog(
			"Applied memorized spell bonus. name='%s' id='%s' oldChance=%.1f newChance=%.1f bonus=%d",
			getSpellName(spell),
			getSpellId(spell),
			oldChance,
			newChance,
			bonus
		)

		return
	end

	if not config.current.unmemorizedPenaltyEnabled then
		return
	end

	local penalty = tonumber(config.current.unmemorizedCastChancePenalty) or 0

	if penalty <= 0 then
		return
	end

	if penalty > 95 then
		penalty = 95
	end

	newChance = oldChance * (1 - (penalty / 100))

	if newChance < 0 then
		newChance = 0
	end

	e.castChance = newChance

	debugLog(
		"Applied unmemorized spell penalty. name='%s' id='%s' oldChance=%.1f newChance=%.1f penalty=%d",
		getSpellName(spell),
		getSpellId(spell),
		oldChance,
		newChance,
		penalty
	)
end

----- Callbacks

local function onMenuMagicActivated(e)
	if not e or not e.element then
		return
	end

	if e.element.name ~= "MenuMagic" then
		return
	end

	timer.start({
		duration = 0.05,
		type = timer.real,
		callback = function()
			refreshSpellbookSpellRows()
		end
	})
end

local function menuEnterCallback(e)
	local menu = tes3ui.findMenu("MenuMagic")

	if not menu or menu.visible == false then
		return
	end

	timer.start({
		duration = 0.05,
		type = timer.real,
		callback = function()
			refreshSpellbookSpellRows()
		end
	})
end

local function onLoaded()
	destroyMemoryMenu("loaded")

	spellbookHoveredSpell = nil
	spellbookHoveredElement = nil
	registeredSpellbookElements = setmetatable({}, { __mode = "k" })

	ensurePlayerData()
	refreshSpellbookSpellRows()
	debugLog(
		"Loaded. combo=%s enabled=%s memoryUsed=%d/%d memorizedCount=%d debugLog=%s",
		getComboDebugText(),
		tostring(config.current.enabled),
		getMemoryUsed(),
		getMemoryCapacity(),
		getMemorizedCount(),
		tostring(config.current.debugLog)
	)
end

local function onInitialized()
	mwse.log("%s Initialized.", logPrefix)
end

-- Registers
event.register(tes3.event.uiActivated, onMenuMagicActivated)
event.register(tes3.event.menuEnter, menuEnterCallback)
event.register(tes3.event.initialized, onInitialized)
event.register(tes3.event.loaded, onLoaded)
event.register(tes3.event.keyDown, openMenuFromKeyboard)
event.register(tes3.event.keyUp, closeMenuFromKeyboard)
event.register(tes3.event.mouseButtonDown, openMenuFromMouse)
event.register(tes3.event.mouseButtonUp, closeMenuFromMouse)
event.register(tes3.event.magicSelectionChanged, onMagicSelectionChanged)
event.register(tes3.event.spellCast, onSpellCast)