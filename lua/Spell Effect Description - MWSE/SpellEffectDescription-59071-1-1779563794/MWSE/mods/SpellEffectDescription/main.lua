local configModule = require("SpellEffectDescription.config")
local config = configModule.current

require("SpellEffectDescription.mcm")

local descriptionModule = require("SpellEffectDescription.descriptions")
local effectDescriptionsById = descriptionModule or {}

local logPrefix = "[Spell Effect Description]"
local injectedBlockName = "SpellEffectDescription_InjectedBlock"

local hookedElements = setmetatable({}, { __mode = "k" })

local lastHoverEvent = nil
local lastHoverEffects = nil
local lastHoverIsHelpMenu = false

-- Forward declaration for Lua function order.
local getTooltipParentFromEvent

local schoolNames = {
	[0] = "Alteration",
	[1] = "Conjuration",
	[2] = "Destruction",
	[3] = "Illusion",
	[4] = "Mysticism",
	[5] = "Restoration",
}

local attributeNames = {
	"Strength",
	"Intelligence",
	"Willpower",
	"Agility",
	"Speed",
	"Endurance",
	"Personality",
	"Luck",
}

local skillNames = {
	"Block",
	"Armorer",
	"Medium Armor",
	"Heavy Armor",
	"Blunt Weapon",
	"Long Blade",
	"Axe",
	"Spear",
	"Athletics",
	"Enchant",
	"Destruction",
	"Alteration",
	"Illusion",
	"Conjuration",
	"Mysticism",
	"Restoration",
	"Alchemy",
	"Unarmored",
	"Security",
	"Sneak",
	"Acrobatics",
	"Light Armor",
	"Short Blade",
	"Marksman",
	"Mercantile",
	"Speechcraft",
	"Hand-to-hand",
}

local function clearLastHover()
	lastHoverEvent = nil
	lastHoverEffects = nil
	lastHoverIsHelpMenu = false
end

local function debugLog(message)
	if config.debug then
		mwse.log("%s %s", logPrefix, message)
	end
end

local function safeSet(element, property, value)
	if not element then
		return
	end

	pcall(function()
		element[property] = value
	end)
end

local function trimText(value)
	if value == nil then
		return ""
	end

	local ok, text = pcall(tostring, value)
	if not ok or text == nil then
		return ""
	end

	text = text:gsub("\r", "")
	text = text:gsub("\n", " ")
	text = text:gsub("%s+", " ")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")

	return text
end

local function getHoldKeyCode()
	if type(config.holdKey) == "table" then
		return config.holdKey.keyCode
	end

	return config.holdKey
end

local function isHoldKeyDown()
	local keyCode = getHoldKeyCode()

	if not keyCode then
		return false
	end

	local down = false

	pcall(function()
		down = tes3.isKeyDown({ keyCode = keyCode })
	end)

	if down then
		return true
	end

	pcall(function()
		down = tes3.isKeyDown(keyCode)
	end)

	if down then
		return true
	end

	pcall(function()
		if tes3.worldController
				and tes3.worldController.inputController
				and tes3.worldController.inputController.isKeyDown then
			down = tes3.worldController.inputController:isKeyDown(keyCode)
		end
	end)

	return down == true
end

local function shouldShowDescriptionsNow(forceShow)
	if not config.enabled then
		return false
	end

	if forceShow then
		return true
	end

	if config.holdToActivate and not isHoldKeyDown() then
		return false
	end

	return true
end

local function normalizeVendorSpellName(rowText)
	local name = trimText(rowText)

	-- "Vivec's Kiss (15pts) - 145gp" -> "Vivec's Kiss"
	name = name:gsub("%s*%([^%)]*%)%s*%-%s*%d+gp%s*$", "")
	name = name:gsub("%s*%-%s*%d+gp%s*$", "")
	name = name:gsub("^%s+", ""):gsub("%s+$", "")

	return name
end

local function walkElementTree(element, callback)
	if not element then
		return
	end

	callback(element)

	local okChildren, children = pcall(function()
		return element.children
	end)

	if okChildren and children then
		for _, child in ipairs(children) do
			walkElementTree(child, callback)
		end
	end
end

local function findChildrenByName(root, wantedName, results)
	results = results or {}

	if not root then
		return results
	end

	local okName, name = pcall(function()
		return root.name
	end)

	if okName and name == wantedName then
		table.insert(results, root)
	end

	local okChildren, children = pcall(function()
		return root.children
	end)

	if okChildren and children then
		for _, child in ipairs(children) do
			findChildrenByName(child, wantedName, results)
		end
	end

	return results
end

local function findChildrenById(root, wantedId, results)
	results = results or {}

	if not root then
		return results
	end

	local okId, id = pcall(function()
		return root.id
	end)

	if okId and id == wantedId then
		table.insert(results, root)
	end

	local okChildren, children = pcall(function()
		return root.children
	end)

	if okChildren and children then
		for _, child in ipairs(children) do
			findChildrenById(child, wantedId, results)
		end
	end

	return results
end

local function getText(element)
	local text = nil

	pcall(function()
		text = element.text
	end)

	return trimText(text)
end

local function getTooltipWidthForEffects(effects)
	local width = 420

	if not effects then
		return width
	end

	if #effects >= 3 then
		return 640
	end

	for _, info in ipairs(effects) do
		if info.description and #info.description > 140 then
			return 640
		end
	end

	return width
end

local function createLabel(parent, text, width)
	local label = parent:createLabel({
		text = text or ""
	})

	safeSet(label, "wrapText", true)
	safeSet(label, "autoHeight", true)
	safeSet(label, "autoWidth", false)
	safeSet(label, "width", width or 420)

	return label
end

local function setHeaderStyle(label)
	pcall(function()
		label.color = tes3ui.getPalette("header_color")
	end)
end

local function setDisabledStyle(label)
	pcall(function()
		label.color = tes3ui.getPalette("disabled_color")
	end)
end

local function destroyInjectedBlock(parent)
	if not parent then
		return
	end

	local blocks = findChildrenById(parent, injectedBlockName)

	for _, block in ipairs(blocks) do
		pcall(function()
			block:destroy()
		end)
	end
end

local function createInjectedBlock(parent, width)
	destroyInjectedBlock(parent)

	local block = parent:createBlock({
		id = injectedBlockName,
	})

	safeSet(block, "flowDirection", "top_to_bottom")
	safeSet(block, "autoHeight", true)
	safeSet(block, "autoWidth", false)
	safeSet(block, "width", width or 420)
	safeSet(block, "paddingTop", 6)

	return block
end

local function createDivider(parent, width)
	local divider = parent:createLabel({
		text = "------------------------------"
	})

	safeSet(divider, "width", width or 420)

	return divider
end

local function getMagicEffect(effectId)
	local magicEffect = nil

	pcall(function()
		if tes3.getMagicEffect then
			magicEffect = tes3.getMagicEffect(effectId)
		end
	end)

	return magicEffect
end

local function getDescriptionEntry(effectId)
	local entry = effectDescriptionsById[effectId]

	if type(entry) == "table" then
		return entry
	end

	if type(entry) == "string" then
		return {
			description = entry,
		}
	end

	return nil
end

local function getEffectInfoFromId(effectId, summary)
	if effectId == nil or effectId < 0 then
		return nil
	end

	local magicEffect = getMagicEffect(effectId)
	local descriptionEntry = getDescriptionEntry(effectId)

	local name = "Unknown Effect"
	local schoolId = nil
	local schoolText = nil
	local description = nil

	if magicEffect then
		pcall(function()
			name = magicEffect.name
		end)

		pcall(function()
			schoolId = magicEffect.school
		end)
	end

	if descriptionEntry then
		if descriptionEntry.name and descriptionEntry.name ~= "" then
			name = descriptionEntry.name
		end

		if descriptionEntry.school and descriptionEntry.school ~= "" then
			schoolText = descriptionEntry.school
		end

		if descriptionEntry.description and descriptionEntry.description ~= "" then
			description = descriptionEntry.description
		end
	end

	if not schoolText and schoolId ~= nil then
		schoolText = schoolNames[schoolId]
	end

	return {
		id = effectId,
		name = trimText(name),
		school = schoolText,
		summary = trimText(summary),
		description = description,
	}
end

local function getEffectInfo(effect)
	if not effect then
		return nil
	end

	local effectId = nil

	pcall(function()
		effectId = effect.id
	end)

	if effectId == nil then
		pcall(function()
			effectId = effect.effectId
		end)
	end

	if effectId == nil then
		pcall(function()
			effectId = effect.effect
		end)
	end

	if effectId == nil then
		pcall(function()
			effectId = effect.magicEffect
		end)
	end

	if effectId == nil then
		pcall(function()
			effectId = effect.magicEffectId
		end)
	end

	if effectId == nil or effectId < 0 then
		return nil
	end

	return getEffectInfoFromId(effectId, effect)
end

local function findEffectInfoByName(effectName)
	effectName = trimText(effectName)

	if effectName == "" then
		return nil
	end

	local lowered = effectName:lower()

	for effectId, _ in pairs(effectDescriptionsById) do
		local descriptionEntry = getDescriptionEntry(effectId)
		local entryName = nil

		if descriptionEntry then
			entryName = descriptionEntry.name
		end

		if entryName and entryName:lower() == lowered then
			return getEffectInfoFromId(effectId, "")
		end
	end

	return nil
end

local function visibleIngredientEffectToGenericName(effectName)
	effectName = trimText(effectName)

	if effectName == "" or effectName == "?" then
		return nil
	end

	for _, attributeName in ipairs(attributeNames) do
		if effectName == "Drain " .. attributeName then
			return "Drain Attribute"
		end

		if effectName == "Damage " .. attributeName then
			return "Damage Attribute"
		end

		if effectName == "Restore " .. attributeName then
			return "Restore Attribute"
		end

		if effectName == "Fortify " .. attributeName then
			return "Fortify Attribute"
		end

		if effectName == "Absorb " .. attributeName then
			return "Absorb Attribute"
		end
	end

	for _, skillName in ipairs(skillNames) do
		if effectName == "Drain " .. skillName then
			return "Drain Skill"
		end

		if effectName == "Damage " .. skillName then
			return "Damage Skill"
		end

		if effectName == "Restore " .. skillName then
			return "Restore Skill"
		end

		if effectName == "Fortify " .. skillName then
			return "Fortify Skill"
		end

		if effectName == "Absorb " .. skillName then
			return "Absorb Skill"
		end
	end

	return effectName
end

local function findEffectInfoByVisibleIngredientName(effectName)
	local genericName = visibleIngredientEffectToGenericName(effectName)

	if not genericName then
		return nil
	end

	local info = findEffectInfoByName(genericName)
	if not info then
		return nil
	end

	info.name = trimText(effectName)
	info.summary = ""

	return info
end

local function addUniqueEffectInfo(results, seen, info)
	if not info or info.id == nil then
		return
	end

	local key = tostring(info.id) .. "|" .. trimText(info.name) .. "|" .. trimText(info.summary)

	if seen[key] then
		return
	end

	seen[key] = true
	table.insert(results, info)
end

local function collectEffectsFromEffectCollection(effects)
	local results = {}
	local seen = {}

	if not effects then
		return results
	end

	local function addFromValue(value)
		if value == nil then
			return
		end

		if type(value) == "number" then
			addUniqueEffectInfo(results, seen, getEffectInfoFromId(value, ""))
			return
		end

		local info = getEffectInfo(value)
		if info then
			addUniqueEffectInfo(results, seen, info)
			return
		end

		local possibleFields = {
			"id",
			"effectId",
			"effect",
			"magicEffect",
			"magicEffectId",
		}

		for _, field in ipairs(possibleFields) do
			local fieldValue = nil

			pcall(function()
				fieldValue = value[field]
			end)

			if type(fieldValue) == "number" then
				addUniqueEffectInfo(results, seen, getEffectInfoFromId(fieldValue, ""))
				return
			end

			local fieldInfo = getEffectInfo(fieldValue)
			if fieldInfo then
				addUniqueEffectInfo(results, seen, fieldInfo)
				return
			end
		end
	end

	local function tryIndex(index)
		local value = nil

		local ok = pcall(function()
			value = effects[index]
		end)

		if ok then
			addFromValue(value)
		end
	end

	for index = 1, 8 do
		tryIndex(index)
	end

	for index = 0, 8 do
		tryIndex(index)
	end

	pcall(function()
		for _, value in ipairs(effects) do
			addFromValue(value)
		end
	end)

	pcall(function()
		for _, value in pairs(effects) do
			addFromValue(value)
		end
	end)

	return results
end

local function collectEffectsFromSpell(spell)
	if not spell then
		return {}
	end

	local effects = nil

	pcall(function()
		effects = spell.effects
	end)

	return collectEffectsFromEffectCollection(effects)
end

local function collectEffectsFromEnchantment(enchantment)
	if not enchantment then
		return {}
	end

	local effects = nil

	pcall(function()
		effects = enchantment.effects
	end)

	return collectEffectsFromEffectCollection(effects)
end

local function collectEffectsFromObject(object)
	local results = {}
	local seen = {}

	if not object then
		return results
	end

	local function addMany(list)
		for _, info in ipairs(list or {}) do
			addUniqueEffectInfo(results, seen, info)
		end
	end

	local directEffects = nil
	pcall(function()
		directEffects = object.effects
	end)

	if directEffects then
		addMany(collectEffectsFromEffectCollection(directEffects))
	end

	local enchantment = nil
	pcall(function()
		enchantment = object.enchantment
	end)

	if enchantment then
		addMany(collectEffectsFromEnchantment(enchantment))
	end

	return results
end

local function isIngredientObject(object)
	if not object then
		return false
	end

	local objectId = ""

	pcall(function()
		objectId = object.id
	end)

	objectId = trimText(objectId):lower()

	if objectId:find("^ingred_") or objectId:find("^food_") then
		return true
	end

	local objectType = nil

	pcall(function()
		objectType = object.objectType
	end)

	if objectType == 1380404809 then
		return true
	end

	return false
end

getTooltipParentFromEvent = function(e)
	if not e then
		return nil, nil
	end

	local tooltip = nil

	pcall(function()
		tooltip = e.tooltip
	end)

	if not tooltip then
		pcall(function()
			tooltip = e.element
		end)
	end

	if not tooltip then
		pcall(function()
			if tes3ui.findHelpLayerMenu then
				tooltip = tes3ui.findHelpLayerMenu("HelpMenu")
			end
		end)
	end

	if not tooltip then
		return nil, nil
	end

	local mains = findChildrenByName(tooltip, "PartHelpMenu_main")
	local parent = mains[1] or tooltip

	return tooltip, parent
end

local function collectVisibleIngredientEffectsFromTooltip(e)
	local results = {}
	local seen = {}

	local tooltip, parent = getTooltipParentFromEvent(e)
	if not tooltip or not parent then
		return results
	end

	walkElementTree(parent, function(element)
		local name = nil

		pcall(function()
			name = element.name
		end)

		-- Only read vanilla ingredient effect rows.
		if name ~= "HelpMenu_effectIcon" then
			return
		end

		local text = getText(element)

		if text ~= "" and text ~= "?" then
			local info = findEffectInfoByVisibleIngredientName(text)

			if info and info.id ~= nil and not seen[info.name] then
				seen[info.name] = true
				table.insert(results, info)
			end
		end
	end)

	return results
end

local function appendEffectsToTooltipParent(parent, effects, options)
	options = options or {}

	if not parent or not effects or #effects == 0 then
		return false
	end

	local width = getTooltipWidthForEffects(effects)
	local block = createInjectedBlock(parent, width)
	local hasAnythingToShow = false
	local visibleIndex = 0

	for _, info in ipairs(effects) do
		local hasDescription = info.description and info.description ~= ""

		if options.showAllEffects or hasDescription then
			visibleIndex = visibleIndex + 1
			hasAnythingToShow = true

			if visibleIndex > 1 then
				createDivider(block, width)
			end

			local title = createLabel(block, info.name, width)
			setHeaderStyle(title)

			if config.showSchool and info.school then
				createLabel(block, "School: " .. info.school, width)
			end

			if config.showEffectSummary and info.summary and info.summary ~= "" then
				createLabel(block, info.summary, width)
			end

			if config.showDescriptions then
				if hasDescription then
					createLabel(block, info.description, width)
				elseif options.showMissing then
					local missing = createLabel(block, "No description defined yet for effect id " .. tostring(info.id) .. ".", width)
					setDisabledStyle(missing)
				end
			end
		end
	end

	if not hasAnythingToShow then
		pcall(function()
			block:destroy()
		end)
		return false
	end

	return true
end

local function appendEffectsToEventTooltip(e, effects, forceShow)
	if not shouldShowDescriptionsNow(forceShow) then
		return
	end

	if not config.showDescriptions then
		return
	end

	if not effects or #effects == 0 then
		return
	end

	local tooltip, parent = getTooltipParentFromEvent(e)
	if not tooltip or not parent then
		debugLog("No tooltip parent found for normal tooltip event.")
		return
	end

	local added = appendEffectsToTooltipParent(parent, effects, {
		showAllEffects = true,
		showMissing = true,
	})

	if added then
		pcall(function()
			tooltip:updateLayout()
		end)

		timer.delayOneFrame(function()
			pcall(function()
				tooltip:updateLayout()
			end)
		end)
	end
end

local function getHelpMenuParent()
	local helpMenu = nil

	pcall(function()
		if tes3ui.findHelpLayerMenu then
			helpMenu = tes3ui.findHelpLayerMenu("HelpMenu")
		end
	end)

	if not helpMenu then
		return nil, nil
	end

	local mains = findChildrenByName(helpMenu, "PartHelpMenu_main")
	local parent = mains[1] or helpMenu

	return helpMenu, parent
end

local function appendEffectsToCurrentHelpMenu(effects, forceShow)
	if not shouldShowDescriptionsNow(forceShow) then
		return
	end

	if not config.showDescriptions then
		return
	end

	if not effects or #effects == 0 then
		return
	end

	local helpMenu, parent = getHelpMenuParent()

	if not helpMenu or not parent then
		debugLog("HelpMenu not found for tooltip injection.")
		return
	end

	local added = appendEffectsToTooltipParent(parent, effects, {
		showAllEffects = true,
		showMissing = true,
	})

	if added then
		pcall(function()
			helpMenu:updateLayout()
		end)

		timer.delayOneFrame(function()
			pcall(function()
				helpMenu:updateLayout()
			end)
		end)
	end
end

local function getServiceActorObject()
	local serviceActor = nil

	pcall(function()
		if tes3ui.getServiceActor then
			serviceActor = tes3ui.getServiceActor()
		end
	end)

	if not serviceActor then
		return nil
	end

	local ref = nil
	pcall(function()
		ref = serviceActor.reference or serviceActor
	end)

	local object = nil
	pcall(function()
		object = ref and ref.object or serviceActor.object or serviceActor
	end)

	return object
end

local function findServiceSpellByName(spellName)
	spellName = trimText(spellName)

	if spellName == "" then
		return nil
	end

	local actorObject = getServiceActorObject()
	if not actorObject then
		debugLog("No service actor object.")
		return nil
	end

	local spells = nil
	pcall(function()
		spells = actorObject.spells
	end)

	if not spells then
		debugLog("Service actor has no spells collection.")
		return nil
	end

	local lowered = spellName:lower()

	for _, spell in pairs(spells) do
		local name = nil

		pcall(function()
			name = spell.name
		end)

		if name and name:lower() == lowered then
			return spell
		end
	end

	return nil
end

local function getPlayerSpellCollections()
	local collections = {}

	pcall(function()
		if tes3.player and tes3.player.object and tes3.player.object.spells then
			table.insert(collections, tes3.player.object.spells)
		end
	end)

	pcall(function()
		if tes3.mobilePlayer and tes3.mobilePlayer.spells then
			table.insert(collections, tes3.mobilePlayer.spells)
		end
	end)

	pcall(function()
		if tes3.mobilePlayer and tes3.mobilePlayer.spellList then
			table.insert(collections, tes3.mobilePlayer.spellList)
		end
	end)

	return collections
end

local function findPlayerSpellByName(spellName)
	spellName = trimText(spellName)

	if spellName == "" then
		return nil
	end

	local lowered = spellName:lower()
	local collections = getPlayerSpellCollections()

	for _, spells in ipairs(collections) do
		local found = nil

		pcall(function()
			for _, spell in pairs(spells) do
				local name = nil

				pcall(function()
					name = spell.name
				end)

				if name and name:lower() == lowered then
					found = spell
					break
				end
			end
		end)

		if found then
			return found
		end
	end

	return nil
end

local function hookServiceSpellRows(menu)
	local rows = findChildrenByName(menu, "MenuServiceSpells_Spell")

	debugLog("Found " .. tostring(#rows) .. " service spell rows.")

	for _, row in ipairs(rows) do
		if not hookedElements[row] then
			hookedElements[row] = true

			row:registerAfter(tes3.uiEvent.help, function()
				if not config.enabled then
					return
				end

				local rowText = getText(row)
				local spellName = normalizeVendorSpellName(rowText)

				debugLog("Vendor spell help: " .. rowText .. " -> " .. spellName)

				local spell = findServiceSpellByName(spellName)
				if not spell then
					clearLastHover()
					debugLog("Could not match vendor spell: " .. spellName)
					return
				end

				local effects = collectEffectsFromSpell(spell)

				if #effects == 0 then
					clearLastHover()
					return
				end

				lastHoverEvent = nil
				lastHoverEffects = effects
				lastHoverIsHelpMenu = true

				timer.delayOneFrame(function()
					appendEffectsToCurrentHelpMenu(effects, false)
				end)

				timer.start({
					duration = 0.05,
					type = timer.real,
					callback = function()
						appendEffectsToCurrentHelpMenu(effects, false)
					end
				})
			end)
		end
	end
end

local function handleMenuMagicRow(rowText)
	rowText = trimText(rowText)

	if rowText == "" or rowText == "None" then
		return
	end

	debugLog("MenuMagic help row: " .. rowText)

	local effects = {}

	local spell = findPlayerSpellByName(rowText)
	if spell then
		effects = collectEffectsFromSpell(spell)
	else
		local effectInfo = findEffectInfoByName(rowText)
		if effectInfo then
			table.insert(effects, effectInfo)
		end
	end

	if #effects == 0 then
		debugLog("MenuMagic row had no matched spell/effect: " .. rowText)
		return
	end

	timer.delayOneFrame(function()
		-- Force true: spellbook always shows descriptions.
		appendEffectsToCurrentHelpMenu(effects, true)
	end)

	timer.start({
		duration = 0.05,
		type = timer.real,
		callback = function()
			appendEffectsToCurrentHelpMenu(effects, true)
		end
	})
end

local function hookMenuMagicRows(menu)
	local hookedCount = 0

	walkElementTree(menu, function(element)
		if hookedElements[element] then
			return
		end

		local elementType = nil
		local text = nil

		pcall(function()
			elementType = element.type
		end)

		pcall(function()
			text = element.text
		end)

		text = trimText(text)

		if elementType == tes3.uiElementType.textSelect and text ~= "" then
			hookedElements[element] = true
			hookedCount = hookedCount + 1

			element:registerAfter(tes3.uiEvent.help, function()
				handleMenuMagicRow(getText(element))
			end)
		end
	end)

	debugLog("Hooked " .. tostring(hookedCount) .. " MenuMagic textSelect rows.")
end

local function onSpellTooltip(e)
	if not config.enabled then
		return
	end

	debugLog("uiSpellTooltip fired.")

	local spell = nil

	pcall(function()
		spell = e.spell
	end)

	if not spell then
		pcall(function()
			spell = e.source
		end)
	end

	if not spell then
		debugLog("uiSpellTooltip had no spell/source.")
		return
	end

	local effects = collectEffectsFromSpell(spell)

	debugLog("uiSpellTooltip effects count=" .. tostring(#effects))

	if #effects == 0 then
		return
	end

	lastHoverEvent = e
	lastHoverEffects = effects
	lastHoverIsHelpMenu = false

	timer.start({
		duration = 0.05,
		type = timer.real,
		callback = function()
			-- Force true: spellbook/spell tooltips always show.
			appendEffectsToEventTooltip(e, effects, true)
		end,
	})
end

local function onObjectTooltip(e)
	if not config.enabled then
		return
	end

	debugLog("uiObjectTooltip fired.")

	local object = nil

	pcall(function()
		object = e.object
	end)

	if not object then
		pcall(function()
			object = e.itemStack and e.itemStack.object
		end)
	end

	if not object then
		pcall(function()
			object = e.item and e.item.object
		end)
	end

	if not object then
		pcall(function()
			object = e.source and e.source.object
		end)
	end

	if not object then
		debugLog("uiObjectTooltip had no object/itemStack/item/source object.")
		clearLastHover()
		return
	end

	debugLog("uiObjectTooltip object=" .. trimText(object))

	-- Clear stale hold-key cache immediately. If this object has effects,
	-- it will be set again below.
	clearLastHover()

	if isIngredientObject(object) then
		timer.start({
			duration = 0.08,
			type = timer.real,
			callback = function()
				local effects = collectVisibleIngredientEffectsFromTooltip(e)
				debugLog("ingredient visible effects count=" .. tostring(#effects))

				if #effects > 0 then
					lastHoverEvent = e
					lastHoverEffects = effects
					lastHoverIsHelpMenu = false

					appendEffectsToEventTooltip(e, effects, false)
				else
					clearLastHover()
				end
			end,
		})

		return
	end

	local effects = collectEffectsFromObject(object)

	debugLog("uiObjectTooltip effects count=" .. tostring(#effects))

	if #effects == 0 then
		clearLastHover()
		return
	end

	lastHoverEvent = e
	lastHoverEffects = effects
	lastHoverIsHelpMenu = false

	timer.start({
		duration = 0.05,
		type = timer.real,
		callback = function()
			appendEffectsToEventTooltip(e, effects, false)
		end,
	})
end

local function onKeyDown(e)
	if not config.enabled then
		return
	end

	if not config.holdToActivate then
		return
	end

	local keyCode = nil

	pcall(function()
		keyCode = e.keyCode
	end)

	local wantedKeyCode = getHoldKeyCode()

	if not wantedKeyCode or keyCode ~= wantedKeyCode then
		return
	end

	if not lastHoverEffects or #lastHoverEffects == 0 then
		return
	end

	debugLog("Hold key pressed. Injecting last hovered effect description.")

	if lastHoverIsHelpMenu then
		appendEffectsToCurrentHelpMenu(lastHoverEffects, true)
	elseif lastHoverEvent then
		appendEffectsToEventTooltip(lastHoverEvent, lastHoverEffects, true)
	end
end

local function onUiActivated(e)
	if not config.enabled then
		return
	end

	if not e or not e.element then
		return
	end

	local menuName = nil

	pcall(function()
		menuName = e.element.name
	end)

	if menuName == "MenuServiceSpells" then
		hookServiceSpellRows(e.element)
		return
	end

	if menuName == "MenuMagic" then
		timer.delayOneFrame(function()
			local menu = tes3ui.findMenu("MenuMagic")
			if menu then
				hookMenuMagicRows(menu)
			end
		end)

		timer.start({
			duration = 0.20,
			type = timer.real,
			callback = function()
				local menu = tes3ui.findMenu("MenuMagic")
				if menu then
					hookMenuMagicRows(menu)
				end
			end
		})

		return
	end
end

local function onUiRefreshed(e)
	if not config.enabled then
		return
	end

	if not e or not e.element then
		return
	end

	local elementName = nil

	pcall(function()
		elementName = e.element.name
	end)

	if elementName == "MenuServiceSpells" or elementName == "MenuServiceSpells_ServiceList" then
		local menu = tes3ui.findMenu("MenuServiceSpells")
		if menu then
			hookServiceSpellRows(menu)
		end
	end

	if elementName == "MenuMagic" then
		local menu = tes3ui.findMenu("MenuMagic")
		if menu then
			hookMenuMagicRows(menu)
		end
	end
end

local function onInitialized()
	mwse.log("%s Initialized.", logPrefix)
end

event.register(tes3.event.initialized, onInitialized)

event.register(tes3.event.uiActivated, onUiActivated)
event.register(tes3.event.uiRefreshed, onUiRefreshed)

event.register(tes3.event.uiSpellTooltip, onSpellTooltip)
event.register(tes3.event.uiObjectTooltip, onObjectTooltip)
event.register(tes3.event.keyDown, onKeyDown)