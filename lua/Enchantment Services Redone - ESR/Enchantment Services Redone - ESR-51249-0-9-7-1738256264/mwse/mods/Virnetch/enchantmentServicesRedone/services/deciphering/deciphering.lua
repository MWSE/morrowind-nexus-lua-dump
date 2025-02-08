local deciphering = {}

local common = require("Virnetch.enchantmentServicesRedone.common")

local InventorySelectMenu = require("Virnetch.enchantmentServicesRedone.ui.InventorySelectMenu")


--- Returns the scroll object that this spell was deciphered from
--- @param spell tes3spell
--- @return tes3book|nil scroll The scroll, if it still exists...
function deciphering.getDecipheredSpellSourceScroll(spell)
	local spellIdNum = common.getIdNumOfDecipheredSpell(spell.id)
	if not spellIdNum then return end

	local scrollId = table.find(common.savedData.decipheredScrolls, spellIdNum)
	if not scrollId then return end

	return tes3.getObject(scrollId)
end

--- Returns a previously created deciphered spell if there exists one.
--- @param scroll tes3book
--- @return tes3spell|nil
function deciphering.getDecipheredSpell(scroll)
	local spellIdNum = common.savedData.decipheredScrolls[scroll.id:lower()]
	if spellIdNum then
		return common.getDecipheredSpellByIdNum(spellIdNum)
	end
end

function deciphering.scrollNameToSpellName(scrollName)
	local spellName

	local patterns = string.split(common.i18n("service.deciphering.scrollPatterns"), "\n")
	for _, pattern in ipairs(patterns) do
		-- Make the pattern case-insensitive
		pattern = pattern:gsub("%a", function(letter)
			return string.format("[%s%s]", letter:lower(), letter:upper())
		end)

		local matches
		spellName, matches = scrollName:gsub(pattern.." ", "")
		if matches == 0 then
			-- Match could still be at the end of string
			spellName, matches = scrollName:gsub(" "..pattern, "")
		end

		if spellName ~= scrollName then
			common.log:trace("Converted scroll name to spell name: %s -> %s", scrollName, spellName)

			-- If the name is whitespace only, change it to nil
			spellName = spellName:gsub("^%s*$", "")
			if spellName == "" then
				spellName = nil
			end

			return spellName
		end
	end
end

--- @param scroll tes3book
--- @param spellName string Name of the spell
--- @return tes3spell
function deciphering.createDecipheredSpell(scroll, spellName)
	local spell = deciphering.getDecipheredSpell(scroll)
	if spell then
		common.log:debug("Spell already deciphered, returning %s", spell.id)
		spell.name = spellName
		return spell
	end

	local scrollId = scroll.id:lower()
	local spellId, spellIdNum = common.getRandomId("vir_esr_dSpl")

	spell = tes3.createObject({
		objectType = tes3.objectType.spell,
		id = spellId,
		name = spellName,
		effects = scroll.enchantment.effects
	})
	spell.magickaCost = common.calculateMagickaCost(scroll.enchantment)

	common.savedData.decipheredScrolls[scrollId] = spellIdNum

	return spell
end

--- Returns true if it is possible to decipher the scroll
--- @param scroll tes3book
--- @return boolean
function deciphering.isScrollDecipherable(scroll)
	if (
		scroll.objectType ~= tes3.objectType.book
		or not scroll.enchantment
		or not common.canUseSpellmaking(scroll.enchantment)
		-- By default ignore scrolls that don't include "scroll" in their name
		-- This is to prevent items that probably shouldn't be deciphered (ie. quest related special items)
		or (
			not deciphering.scrollNameToSpellName(scroll.name)
			and (
				common.config.deciphering.allowNonStandardNames == "never"
				or ( common.config.deciphering.allowNonStandardNames == "onlyCustom" and scroll.sourceMod )
			)
		)
	) then
		return false
	end
	return true
end

function deciphering.calculateDecipheringChance(merchant, item)
	local spell = common.getDummySpell(item.enchantment.effects)
	return spell:calculateCastChance({
		caster = merchant,
		checkMagicka = false
	})
--	return math.max(0, castChance)
end

--- Calculate service cost and cost modified for current merchant
--- @param item tes3book
--- @return number basePurchaseCost The base cost for deciphering
--- @return number totalPrice Total cost modified by current merchant
function deciphering.calculateDecipheringCost(item)
	local spell = common.getDummySpell(item.enchantment.effects)
	local totalPrice = tes3.calculatePrice({
		basePrice = spell.basePurchaseCost,
		merchant = tes3ui.getServiceActor()
	})
	totalPrice = math.floor(totalPrice * (common.config.deciphering.costMult / 100))

	return spell.basePurchaseCost, totalPrice
end

--- Determines if a merchant can decipher an item
--- @param merchant tes3mobileNPC
--- @param item tes3book
--- @return boolean
function deciphering.canDecipherItem(merchant, item)
	if not common.config.deciphering.enableChance then return true end

	-- Get the chance for NPC
	local chance = deciphering.calculateDecipheringChance(merchant, item)

	-- Get the required chance
	local chanceRequired = common.config.deciphering.chanceRequired

	-- Modify required chance by disposition
	local disposition = merchant.object.disposition
	if disposition then
		local dispFactor = common.config.dispositionFactor
		chanceRequired = chanceRequired + math.remap(math.clamp(disposition, 0, 100), 0, 100, dispFactor, -dispFactor)
	end

	common.log:debug("  chance: %.2f, required: %.2f for deciphering %s", chance, chanceRequired, item.id)

	return ( math.max(0, chance) >= chanceRequired )
end

--- @param scroll tes3book
--- @param spellName string? Optional, if `nil`, a name will either be generated from the scroll name or an input menu will be shown according to the `deciphering.customName` config option.
local function decipherScroll(scroll, spellName)

	if not spellName then
		spellName = deciphering.scrollNameToSpellName(scroll.name)
		if (
			not spellName
			or common.config.deciphering.customName == "always"
			or common.config.deciphering.customName == "alwaysForCustom" and not scroll.sourceMod
		) then
			local nameMenu = tes3ui.createMenu({ id = common.GUI_ID.Deciphering_nameMenu, fixedFrame = true })
			nameMenu.flowDirection = tes3.flowDirection.topToBottom
			nameMenu.autoWidth = true
			nameMenu.minWidth = 390

			local nameHeaderBlock = nameMenu:createBlock({ id = common.GUI_ID.Deciphering_nameHeaderBlock })
			nameHeaderBlock.autoHeight = true
			nameHeaderBlock.autoWidth = true
			nameHeaderBlock.parent.childAlignX = 0.5
			nameHeaderBlock.childAlignY = 0.5

			local itemHolderBlock = nameHeaderBlock:createBlock()
			itemHolderBlock.width = 44
			itemHolderBlock.height = 44
			itemHolderBlock.borderAllSides = 8
			itemHolderBlock.childAlignY = 0.5
			itemHolderBlock:register(tes3.uiEvent.help, function()
				tes3ui.createTooltipMenu({ item = scroll })
			end)

			-- Add enchantment icon
			local magicIcon = itemHolderBlock:createImage({ path = "Textures\\menu_icon_magic.tga" })
			magicIcon.widthProportional = 1
			magicIcon.heightProportional = 1

			-- Add shadow icon
			local shadowIcon = itemHolderBlock:createImage({ path = "icons\\" .. scroll.icon })
			shadowIcon.color = {0.0, 0.0, 0.0}
			shadowIcon.absolutePosAlignX = 0.6
			shadowIcon.absolutePosAlignY = 0.55

			-- Add item icon
			local icon = itemHolderBlock:createImage({ path = "icons\\" .. scroll.icon })
			icon.absolutePosAlignX = 0.5
			icon.absolutePosAlignY = 0.5

			local nameHeaderLabel = nameHeaderBlock:createLabel({ text = common.i18n("service.deciphering.customNameHeader", { scrollName = scroll.name }) })

			local nameInputBlock = nameMenu:createBlock({ id = common.GUI_ID.Deciphering_nameInputBlock })
			nameInputBlock.autoHeight = true
			nameInputBlock.widthProportional = 1.0
			nameInputBlock.childAlignY = 0.5
			nameInputBlock.borderAllSides = 6
			nameInputBlock.borderLeft = 5

			local nameLabel = nameInputBlock:createLabel({ text = common.i18n("service.deciphering.customNameLabel") })
			nameLabel.borderAllSides = 6
			nameLabel.color = common.palette.headerColor
			nameLabel:register(tes3.uiEvent.help, function()
				common.tooltip(common.i18n("service.deciphering.customNameTooltip"), true)
			end)

			local nameInputBorder = nameInputBlock:createThinBorder()
			nameInputBorder.widthProportional = 1.0
			nameInputBorder.height = 30
			nameInputBorder.childAlignY = 0.5
			nameInputBorder.paddingAllSides = 4

			local nameInput = nameInputBorder:createTextInput({ id = common.GUI_ID.Deciphering_nameInput, text = (spellName or scroll.name) })
			nameInput.widget.lengthLimit = 31
			nameInput.widget.eraseOnFirstKey = false
			nameInput.borderLeft = 5
			nameInput.borderRight = 5
			nameInputBorder:register(tes3.uiEvent.mouseClick, function()
				tes3ui.acquireTextInput(nameInput)
			end)

			local bottomBlock = nameMenu:createBlock({ id = common.GUI_ID.Deciphering_nameBottomBlock })
			bottomBlock.autoHeight = true
			bottomBlock.widthProportional = 1.0
			bottomBlock.childAlignX = 1.0

			local nameOkButton = bottomBlock:createButton({ text = tes3.findGMST(tes3.gmst.sOK).value })
			nameOkButton:register(tes3.uiEvent.mouseClick, function()
				if not (nameInput and nameInput.text and string.len(nameInput.text) > 0) then
					tes3.messageBox(common.i18n("service.deciphering.customNameNeeded"))
				else
					decipherScroll(scroll, nameInput.text)
					nameMenu:destroy()
				end
			end)

			tes3ui.acquireTextInput(nameInput)
			nameMenu:updateLayout()

			return
		end
	end

	local spell = deciphering.createDecipheredSpell(scroll, spellName)
	tes3.addSpell({
		reference = tes3.player,
		spell = spell
	})
	if common.config.deciphering.npcLearns then
		tes3.addSpell({
			reference = tes3ui.getServiceActor(),
			spell = spell
		})
	end
	tes3.messageBox(common.i18n("service.deciphering.spellLearned", { spellName = spell.name }))
	tes3.playSound({ sound = "enchant success" })
--	local firstMagicEffect = common.getFirstMagicEffectOnEnchantment(item.enchantment)
--	tes3.playSound({ sound = firstMagicEffect.castSoundEffect })
--	timer.start({
--		type = timer.real,
--		duration = 1,
--		callback = function()
--			tes3.playSound({ sound = firstMagicEffect.hitSoundEffect })
--		end
--	})

	tes3ui.updateInventorySelectTiles()
end

local function decipheringItemSelected(e)
	if not e.source then return end
	local item = e.source:getPropertyObject("MenuInventorySelect_object")
	if item then
		local merchant = tes3ui.getServiceActor()

		-- Check NPC skills
		if not deciphering.canDecipherItem(merchant, item) then
			tes3.messageBox(common.i18n("service.deciphering.cantDecipher"))
			return
		end

		-- Check if player can afford
		local _, decipheringCost = deciphering.calculateDecipheringCost(item)
		if tes3.getPlayerGold() < decipheringCost then
			tes3.messageBox(tes3.findGMST(tes3.gmst.sBarterDialog1).value)
			return
		end

		-- Take the money
		common.payMerchant(merchant, decipheringCost)

		-- Create the actual spell and add it
		decipherScroll(item)
	end
end

local function decipheringItemSelectMenuUpdated()
	local menu = tes3ui.findMenu(common.GUI_ID.MenuInventorySelect)
	if not menu then return	end

	-- Update player gold label
	local goldLabel = menu:findChild(common.GUI_ID.MenuInventorySelect_gold_label)
	goldLabel.text = string.format("%s: %i", tes3.findGMST(tes3.gmst.sGold).value, tes3.getPlayerGold())

	local disabledColor = common.palette.disabledColor

	InventorySelectMenu.addToInventorySelectMenuTiles({
		--- @param section esrInventorySelectMenu.addToTilesParams.section
		addBelow = function(section)
			-- Show spell cast chance and cost

			-- Get the cast chance for the spell
			local spell = common.getDummySpell(section.item.enchantment.effects)
			local castChance = spell:calculateCastChance({
				caster = tes3.player,
				checkMagicka = false
			})
			castChance = math.clamp(castChance, 0, 100)

			-- Add the label
			local castChanceAndCostLabel = section.element:createLabel()
			castChanceAndCostLabel.text = string.format("%s: %i %s: %i",
				tes3.findGMST(tes3.gmst.sCastCost).value, spell.magickaCost, -- Cast Cost
				tes3.findGMST(tes3.gmst.sEnchantmentMenu6).value, castChance -- Chance
			)
		end,

		--- @param section esrInventorySelectMenu.addToTilesParams.section
		addRight = function(section)
			-- Show cost for deciphering

			-- Get the cost
			local _, cost = deciphering.calculateDecipheringCost(section.item)

			-- Add the label
			local costLabel = section.element:createLabel()
			costLabel.text = string.format("%i%s", cost, tes3.findGMST(tes3.gmst.sgp).value)
			costLabel.consumeMouseEvents = false

			-- Change item name and cost color to grey if player can't afford
			if (
				cost > tes3.getPlayerGold()
				-- Or if npc lacks the skills
				or not deciphering.canDecipherItem(tes3ui.getServiceActor(), section.item)
			) then
				section.element.parent:findChild(common.GUI_ID.MenuInventorySelect_nameLabel).color = disabledColor
				section.element.parent:findChild(common.GUI_ID.MenuInventorySelect_belowBlock).children[1].color = disabledColor
				costLabel.color = disabledColor
			end

			-- Register the callback when selecting item
			section.element.parent:register(tes3.uiEvent.mouseClick, decipheringItemSelected)
		end
	})
end

--- Edits the InventorySelectMenu to show player's gold and additional elements on the item tiles
--- @param e uiActivatedEventData
local function decipheringItemSelectMenuEntered(e)
	event.unregister(tes3.event.uiActivated, decipheringItemSelectMenuEntered, { filter = "MenuInventorySelect" })

	InventorySelectMenu.addPlayerGold(e.element)
	InventorySelectMenu.changeCancelToDone(e.element)

	-- Item tiles need to be edited after every update
	e.element:register(tes3.uiEvent.preUpdate, decipheringItemSelectMenuUpdated)
end

local function decipheringFilter(e)
	if deciphering.isScrollDecipherable(e.item) then
		-- Check if player already has the spell
		local decipheredSpell = deciphering.getDecipheredSpell(e.item)
		local pcSpells = tes3.player.object.spells
		local pcHasSpell = decipheredSpell and pcSpells:contains(decipheredSpell)
		if not pcHasSpell then
			return true
		end
	end
	return false
end

--- Opens the deciphering service menu
function deciphering.showDecipheringMenu()
	-- The deciphering service menu is an edited InventorySelectMenu.

	event.register(tes3.event.uiActivated, decipheringItemSelectMenuEntered, { filter = "MenuInventorySelect" })

	tes3ui.showInventorySelectMenu({
		title = common.i18n("service.deciphering.selectMenu.title"),
		noResultsText = common.i18n("service.deciphering.selectMenu.noResultsText"),
		noResultsCallback = function()
			event.unregister(tes3.event.uiActivated, decipheringItemSelectMenuEntered, { filter = "MenuInventorySelect" })
		end,
		filter = decipheringFilter,
		callback = function() end	-- Required, won't actually be called
	})
end

--- Add labels to a deciphered spell's tooltip
--- @param e uiSpellTooltipEventData
local function onUiSpellTooltip(e)
	if (
		not common.config.deciphering.showSourceInTooltip
		and common.config.deciphering.sourceTextToShowInTooltip == "nothing"
	) then
		return
	end

	local main = e.tooltip:findChild(common.GUI_ID.HelpMenu_main)
	if not main then return end
	local effect = e.tooltip:findChild(common.GUI_ID.effect)
	if not effect then return end

	-- Get the original scroll the spell was deciphered from
	local sourceScroll = deciphering.getDecipheredSpellSourceScroll(e.spell)
	if not sourceScroll then return end

	-- Create a block for the new labels
	local decipherBlock = main:createBlock({ id = common.GUI_ID.Tooltip_decipherBlock })
	decipherBlock.autoHeight = true
	decipherBlock.width = 445
	decipherBlock.flowDirection = tes3.flowDirection.topToBottom

	-- Move the block below the spell name in the tooltip
	main:reorderChildren(effect, decipherBlock, 1)

	-- Show "Deciphered from: ..."
	if common.config.deciphering.showSourceInTooltip then
		local decipherLabel = decipherBlock:createLabel({ id = common.GUI_ID.Tooltip_decipherLabel })
		decipherLabel.text = common.i18n("service.deciphering.spellTooltip", {scroll = sourceScroll.name})
		decipherLabel.widthProportional = 1.0
		decipherLabel.wrapText = true
		decipherLabel.justifyText = tes3.justifyText.center
	end

	-- Get what to show for the text
	local showText = common.config.deciphering.sourceTextToShowInTooltip ~= "nothing"
	local translate = (
		common.config.deciphering.sourceTextToShowInTooltip == "fullEnglish"
		or common.config.deciphering.sourceTextToShowInTooltip == "oneLineEnglish"
	)
	local oneLineOnly = (
		common.config.deciphering.sourceTextToShowInTooltip == "oneLine"
		or common.config.deciphering.sourceTextToShowInTooltip == "oneLineEnglish"
	)

	-- Show text from original scroll
	if sourceScroll.text and showText then
		local formattedText = sourceScroll.text

		-- Get rid of the tags
		formattedText = string.gsub(formattedText, "%b<>", "")

		-- Get rid of line breaks at the beginning and end
		formattedText = string.gsub(formattedText, "^%s*", "")
		formattedText = string.gsub(formattedText, "%s*$", "")

		if oneLineOnly then
			local repl = translate and "..." or ""
			formattedText = string.gsub(formattedText, "\n.*$", repl)
		end

		local decipherTextLabel = decipherBlock:createLabel({ id = common.GUI_ID.Tooltip_decipherTextLabel })
		decipherTextLabel.text = formattedText
		decipherTextLabel.color = common.palette.headerColor
		decipherTextLabel.widthProportional = 1.0
		decipherTextLabel.wrapText = true
		decipherTextLabel.justifyText = tes3.justifyText.center

		if not translate then
			decipherTextLabel.font = 2
		end
	end

	e.tooltip:updateLayout()
end
event.register(tes3.event.uiSpellTooltip, onUiSpellTooltip)

return deciphering