local commands = require("Command Menu.commands")
local config = require("Command Menu.config")
local uiid = require("Command Menu.ui.uiid")
local util = require("Command Menu.util")

local i18n = mwse.loadTranslations("Command Menu")
local log = mwse.Logger.new()
local menuID = tes3ui.registerID(uiid.menu)
local ui = {}

--- @param tab tes3uiElement
function ui.hideTab(tab)
	tab.visible = false
	tab.autoHeight = false
	tab.autoWidth = false
	tab.height = 0
	tab.width = 0
end

--- @param tab tes3uiElement
function ui.showTab(tab)
	tab.visible = true
	tab.autoHeight = true
	tab.autoWidth = true
end

--- @param container tes3uiElement The UI element in which the new button will be created.
--- @param buttonText string The text on the new button.
--- @param tabs table<string, tes3uiElement> A map of tab containers.
--- @param currentTabKey string A key in `tabs` of a tab that will be made visible when the created button is clicked.
--- @param newTitle string The new title text.
--- @return tes3uiElement button
function ui.createTabButton(container, buttonText, tabs, currentTabKey, newTitle)
	local button = container:createButton({
		id = tes3ui.registerID("CommandMenu_button_" .. buttonText),
		text = buttonText,
	})
	local titleLabel = container:getTopLevelMenu():findChild(uiid.heading)
	button:registerAfter(tes3.uiEvent.mouseClick, function(e)
		-- Hide all the tabs and show the selected tab.
		for _, tab in pairs(tabs) do
			ui.hideTab(tab)
		end
		ui.showTab(tabs[currentTabKey])
		titleLabel.text = newTitle
		container:getTopLevelMenu():updateLayout()
	end)
	return button
end

---@param parent tes3uiElement
---@param id string|integer|nil
local function createAutoSizedBlock(parent, id)
	local block = parent:createBlock({ id = id })
	block.autoHeight = true
	block.autoWidth = true
	block.widthProportional = 1.0
	return block
end

--- @param parent tes3uiElement
--- @param id string|integer|nil
function ui.createLeftRightBlock(parent, id)
	local block = createAutoSizedBlock(parent, id)
	block.flowDirection = tes3.flowDirection.leftToRight
	return block
end

--- @param parent tes3uiElement
--- @param id string|integer|nil
function ui.createTopBottomBlock(parent, id)
	local block = createAutoSizedBlock(parent, id)
	block.flowDirection = tes3.flowDirection.topToBottom
	return block
end

--- @param parent tes3uiElement
--- @param id string|integer|nil
function ui.createTabContainer(parent, id)
	local tabContainer = ui.createTopBottomBlock(parent, id)
	tabContainer.borderLeft = 4
	tabContainer.borderRight = 4
	tabContainer.heightProportional = 1.0
	tabContainer.visible = false

	return tabContainer
end

--- @param parent tes3uiElement
--- @param labelText string
function ui.createCategory(parent, labelText)
	local outerContainer = ui.createTopBottomBlock(parent)
	outerContainer.paddingAllSides = 4
	local label = outerContainer:createLabel({ id = tes3ui.registerID("CategoryLabel"), text = labelText })
	label.color = tes3ui.getPalette(tes3.palette.headerColor)

	local container = ui.createTopBottomBlock(outerContainer, tes3ui.registerID("ContentsContainer"))
	container.borderLeft = 8
	container.borderTop = 8
	return container, label
end

--- @param previewBlock tes3uiElement
--- @param currentSoulGem tes3misc
--- @param currentCreature tes3creature
function ui.recreateSoulGemPreview(previewBlock, currentSoulGem, currentCreature)
	previewBlock:destroyChildren()

	local grow = previewBlock:createBlock()
	grow.autoHeight = true
	grow.autoWidth = true
	grow.widthProportional = 0.5

	-- Create icon
	local icon = previewBlock:createImage({
		path = "icons\\" .. currentSoulGem.icon
	})
	icon.imageScaleX = 2
	icon.imageScaleY = 2
	icon.borderLeft = 8
	icon.borderRight = 16

	-- Create labels
	local labelsBlock = previewBlock:createBlock()
	labelsBlock.autoHeight = true
	labelsBlock.autoWidth = true
	labelsBlock.flowDirection = tes3.flowDirection.topToBottom

	local nameLabel = labelsBlock:createLabel({
		text = currentSoulGem.name
	})

	local soulLabel = labelsBlock:createLabel({
		text = string.format("%s (%d/%d)",
			currentCreature.name,
			currentCreature.soul,
			currentSoulGem.soulGemCapacity
		)
	})
	soulLabel.color = tes3ui.getPalette(tes3.palette.headerColor)

	local addButton = labelsBlock:createButton({ text = i18n("Add") })
	addButton.borderTop = 12
	addButton:registerAfter(tes3.uiEvent.mouseClick, function(e)
		tes3.addItem({
			item = currentSoulGem,
			soul = currentCreature,
			count = 1,
			reference = tes3.player,
		})
		tes3.messageBox(i18n("Added") .. " %s (%s).", currentSoulGem.name, currentCreature.name)
	end)

	previewBlock:getTopLevelMenu():updateLayout()
end

---@param container tes3uiElement
function ui.recreatePlayerPane(container)
	container:getContentElement():destroyChildren()

	local primaryAttributesCategory = ui.createCategory(container, i18n("Primary Attributes"))
	for key, id in pairs(tes3.attribute) do
		-- This function gets names from GMSTs which are capitalized.
		local name = tes3.getAttributeName(id)
		local input = mwse.mcm.createTextField(primaryAttributesCategory, {
			label = name,
			variable = mwse.mcm.createCustom({
				converter = tonumber,
				getter = function(self)
					return tes3.mobilePlayer[key].current
				end,
				setter = function(self, newValue)
					if not newValue then return end
					local msg = string.format(i18n("Set x to y"), name, newValue)
					tes3.messageBox({ message = msg, duration = 3 })
					tes3.setStatistic({ reference = tes3.player, attribute = id, value = newValue })
				end
			})
		})
		-- We don't want default messagebox.
		--- @diagnostic disable-next-line: duplicate-set-field
		input.callback = function() end
	end


	local derivedAttributesCategory = ui.createCategory(container, i18n("Derived Attributes"))
	local derivedKeys = { "health", "magicka", "fatigue", "encumbrance" }
	for _, key in ipairs(derivedKeys) do
		local name = util.capitalize(i18n(key))
		local input = mwse.mcm.createTextField(derivedAttributesCategory, {
			label = name,
			variable = mwse.mcm.createCustom({
				converter = tonumber,
				getter = function(self)
					return math.round(tes3.mobilePlayer[key].current, 2)
				end,
				setter = function(self, newValue)
					if not newValue then return end
					local msg = string.format(i18n("Set x to y"), name, newValue)
					tes3.messageBox({ message = msg, duration = 3 })
					tes3.setStatistic({ reference = tes3.player, name = key, value = newValue })
				end
			})
		})
		-- We don't want default messagebox.
		--- @diagnostic disable-next-line: duplicate-set-field
		input.callback = function() end
	end

	local skillsContainer = ui.createCategory(container, i18n("Skills"))
	for key, id in pairs(tes3.skill) do
		-- This function gets names from GMSTs which are capitalized.
		local name = tes3.getSkillName(id)
		local input = mwse.mcm.createTextField(skillsContainer, {
			label = name,
			inGameOnly = true,
			variable = mwse.mcm.createCustom({
				converter = tonumber,
				getter = function(self)
					return tes3.mobilePlayer[key].current
				end,
				setter = function(self, newValue)
					if not newValue then return end
					local msg = string.format(i18n("Set x to y"), name, newValue)
					tes3.messageBox({ message = msg, duration = 3 })
					tes3.setStatistic({ reference = tes3.player, skill = id, value = newValue })
				end
			})
		})
		-- We don't want default messagebox.
		--- @diagnostic disable-next-line: duplicate-set-field
		input.callback = function() end
	end
end

--- @param parent tes3uiElement
--- @return tes3uiElement input
function ui.createSeachBox(parent)
	local searchBox = parent:createThinBorder({ id = tes3ui.registerID("CommandMenu_search_border") })
	searchBox.autoHeight = true
	searchBox.autoWidth = true
	searchBox.widthProportional = 1.0
	searchBox.paddingAllSides = 8
	searchBox.borderBottom = 8
	searchBox.borderTop = 8

	local input = searchBox:createTextInput({
		id = tes3ui.registerID("CommandMenu_search_input"),
		autoFocus = true,
		placeholderText = i18n("Search..."),
	})
	input.autoWidth = true
	input.widthProportional = 1.0
	return input
end

-- TODO: consider limiting the number of search results to, for example 1000 items.

--- This filter makes all the child items visible when there is no text in the search box.
--- @param paneItem tes3uiElement
--- @param searchTerm string
--- @param cleared boolean
local function standardFilterVisible(paneItem, searchTerm, cleared)
	if cleared or util.ciContains(paneItem.text, searchTerm) then
		paneItem.visible = true
		return
	end

	paneItem.visible = false
end

--- This filter makes all the child items hidden when there is no text in the search box.
--- @param paneItem tes3uiElement
--- @param searchTerm string
--- @param cleared boolean
local function standardFilterHidden(paneItem, searchTerm, cleared)
	if not cleared and util.ciContains(paneItem.text, searchTerm) then
		paneItem.visible = true
		return
	end

	paneItem.visible = false
end

-- TODO: fix searching on player tab. When typing some search term and then clearing the search text,
-- all the settings are hidden
--- @param parent tes3uiElement
--- Function called on each pane item. It should hide and show pane children that match given searchTerm
--- (which is lowercase). Cleared is true when the search box text was cleared.
--- @param filter fun(paneItem: tes3uiElement, searchTerm: string, cleared: boolean)
--- @param id string|integer|nil The id of the pane element.
function ui.createSearchPane(parent, filter, id)
	local input = ui.createSeachBox(parent)
	local pane = parent:createVerticalScrollPane({ id = id })
	pane.autoHeight = true
	pane.heightProportional = 1.0

	--- @param e tes3uiEventData
	local function filterItems(e)
		local container = pane:getContentElement()
		local searchTerm = input.text:lower()
		local cleared = input.text == input:getLuaData("placeholderText")
		for _, paneItem in ipairs(container.children) do
			filter(paneItem, searchTerm, cleared)
		end
		pane:getTopLevelMenu():updateLayout()
		local widget = pane.widget --[[@as tes3uiScrollPane]]
		widget:contentsChanged()
	end
	input:registerAfter(tes3.uiEvent.textCleared, filterItems)
	input:registerAfter(tes3.uiEvent.textUpdated, filterItems)

	return pane
end

---@param npc tes3npc
local function openTeleportMenuNPC(npc)
	local name = util.getNiceName(npc)
	tes3ui.showMessageMenu({
		header = i18n("Do you wish to teleport to the NPC's location or teleport the NPC in front of yourself?"),
		buttons = {
			{
				text = string.format(i18n("Teleport %s here"), name),
				callback = function()
					commands.teleportNPC(npc)
				end,
			}, {
				text = string.format(i18n("Teleport to %s's location"), name),
				callback = function()
					ui.closeMenu()
					commands.teleport(npc)
				end
			}
		}
	})
end

--- @param container tes3uiElement
--- @param quest tes3quest
local function recreateQuestInfosList(container, quest)
	container:destroyChildren()
	local dialogue = quest.dialogue[1]
	local topContainer = ui.createTopBottomBlock(container)
	topContainer.paddingAllSides = 8
	local label = topContainer:createLabel({
		text = string.format("%s: %s (%q)", i18n("Selected quest"), quest.id, dialogue.id)
	})
	label.color = tes3ui.getPalette(tes3.palette.bigNormalColor)

	--- @param dialogue tes3dialogue
	local function getCurrentIndexText(dialogue)
		return string.format("%s: %s",
			i18n("Current journal index"),
			tes3.getJournalIndex({ id = dialogue })
		)
	end

	local currentIndex = topContainer:createLabel({
		text = getCurrentIndexText(dialogue)
	})

	local infosPane = ui.createSearchPane(container, function(paneItem, searchTerm, cleared)
		if cleared then
			paneItem.visible = true
			return
		end
		local categoryLabel = paneItem.children[1]
		if not categoryLabel then
			return
		end
		if util.ciContains(categoryLabel.text, searchTerm) then
			paneItem.visible = true
			return
		end
		local journalIndex = paneItem.children[2].children[1]
		if util.ciContains(journalIndex.text, searchTerm) then
			paneItem.visible = true
			return
		end
		paneItem.visible = false
	end)

	local len = #dialogue.info
	for i, info in ipairs(dialogue.info) do
		-- Text has '@' and '#' characters arount topic links. Remove them
		local infoText = string.gsub(string.gsub(info.text, "@", ""), "#", "")
		local container, text = ui.createCategory(infosPane, infoText)
		container.consumeMouseEvents = false
		text.color = tes3ui.getPalette(tes3.palette.normalColor)
		text.consumeMouseEvents = false
		text.wrapText = true

		local journalIndex = container:createLabel({
			text = string.format("%s: %d, %s: %s, %s: %s, %s: %s.",
				i18n("Journal index"), info.journalIndex,
				i18n("Quest name"), info.isQuestName,
				i18n("Finished"), info.isQuestFinished,
				i18n("Restart"), info.isQuestRestart
			)
		})
		journalIndex.consumeMouseEvents = false
		journalIndex.color = tes3ui.getPalette(tes3.palette.miscColor)

		local lastEntry = i == len
		if not lastEntry then
			infosPane:createDivider()
		end
		local container = container.parent
		container:registerAfter(tes3.uiEvent.mouseOver, function(e)
			text.color = tes3ui.getPalette(tes3.palette.activeOverColor)
			text:getTopLevelMenu():updateLayout()
		end)
		container:registerAfter(tes3.uiEvent.mouseLeave, function(e)
			text.color = tes3ui.getPalette(tes3.palette.normalColor)
			text:getTopLevelMenu():updateLayout()
		end)
		container:register(tes3.uiEvent.mouseDown, function(e)
			text.color = tes3ui.getPalette(tes3.palette.activePressedColor)
			text:getTopLevelMenu():updateLayout()
		end)
		container:register(tes3.uiEvent.mouseRelease, function(e)
			text.color = tes3ui.getPalette(tes3.palette.activeOverColor)
			text:getTopLevelMenu():updateLayout()
		end)
		container:registerAfter(tes3.uiEvent.mouseClick, function(e)
			if info.journalIndex == 0 then return end
			dialogue:addToJournal({
				index = info.journalIndex
			})

			tes3.setJournalIndex({
				id = dialogue,
				index = info.journalIndex,
				showMessage = true,
			})
			currentIndex.text = getCurrentIndexText(dialogue)
		end)
	end
	ui.updateLayoutTextWrapping(infosPane:getTopLevelMenu())
end

--- @class CommandMenu.ui.createHeadingMenu.params
--- @field id string|integer|nil
--- @field minWidth integer?
--- @field minHeight integer?
--- @field heading string
--- @field absolutePosAlignX number?
--- @field absolutePosAlignY number?

--- @param params CommandMenu.ui.createHeadingMenu.params
function ui.createHeadingMenu(params)
	local menu = tes3ui.createMenu({ id = params.id, fixedFrame = true })

	menu.absolutePosAlignX = params.absolutePosAlignX or 0.1
	menu.absolutePosAlignY = params.absolutePosAlignY or 0.2
	menu.childAlignX = 0.5
	menu.childAlignY = 0.5
	menu.autoWidth = true
	menu.autoHeight = true
	menu.minWidth = params.minWidth or 500
	menu.minHeight = params.minHeight
	menu.alpha = tes3.worldController.menuAlpha

	-- Heading
	local headingBlock = ui.createTopBottomBlock(menu)
	headingBlock.childAlignX = 0.5
	headingBlock.paddingAllSides = 8

	local title = headingBlock:createLabel({
		id = tes3ui.registerID(uiid.heading),
		text = params.heading
	})
	headingBlock:createDivider()

	-- Main body
	local bodyBlock = ui.createTopBottomBlock(menu)
	bodyBlock.heightProportional = 1.0
	bodyBlock.paddingLeft = 8
	bodyBlock.paddingRight = 8

	menu:getTopLevelMenu():updateLayout()

	return {
		title = title,
		menu = menu,
		body = bodyBlock
	}
end

--- Some super duper secret agent code from Hrnchamd aimed to fix an issue with text label overlapping.
--- @param menu tes3uiElement
function ui.updateLayoutTextWrapping(menu)
	--- @param element tes3uiElement
	local function recurse(element)
		if element.contentType == tes3.contentType.text then
			-- Flag element to reflow content
			if element.wrapText then
				element.wrapText = true
				return
			end
		end
		for _, child in pairs(element.children) do
			if child then
				ui.updateLayoutTextWrapping(child)
				-- As originally suggested by Hrnchamd. Doesn't fix the issue unfortunately.
				-- recurse(child)
			end
		end
	end

	menu:updateLayout()
	recurse(menu)
	menu:updateLayout()
end


--- @param objects CommandMenu.objectsTable
function ui.createMenu(objects)
	local menuElements = ui.createHeadingMenu({
		heading = i18n("Choose items to add"),
		id = menuID,
		minWidth = 500,
		minHeight = 800,
	})

	local menu = menuElements.body

	local tabsButtonsContainer = ui.createLeftRightBlock(menu)
	menu:createDivider()

	--- @type table<string, tes3uiElement>
	local tabs = {}

	local generalContainer = ui.createTabContainer(menu, tes3ui.registerID("CommandMenu_general_container"))
	tabs.generalContainer = generalContainer
	do -- General tab
		local pane = generalContainer:createVerticalScrollPane()
		pane.autoHeight = true
		pane.heightProportional = 1.0

		local contentsBlock = ui.createTopBottomBlock(pane)

		do -- Engine settings category
			local container = ui.createCategory(contentsBlock, i18n("Engine settings"))

			mwse.mcm.createOnOffButton(container, {
				label = i18n("God mode"),
				leftSide = true,
				variable = mwse.mcm.createCustom({
					getter = function(self)
						return tes3.worldController.menuController.godModeEnabled
					end,
					setter = function(self, newValue)
						commands.setGodMode(newValue)
					end,
				}),
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Collision"),
				leftSide = true,
				variable = mwse.mcm.createCustom({
					getter = function(self)
						return not tes3.worldController.menuController.collisionDisabled
					end,
					setter = function(self, newValue)
						commands.setCollsion(newValue)
					end
				})
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Vanity mode"),
				leftSide = true,
				variable = mwse.mcm.createCustom({
					getter = function(self)
						return tes3.getVanityMode()
					end,
					setter = function(self, newValue)
						commands.setVanityMode(newValue)
					end
				})
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("AI enabled"),
				leftSide = true,
				variable = mwse.mcm.createCustom({
					getter = function(self)
						return not tes3.worldController.menuController.aiDisabled
					end,
					setter = function(self, newValue)
						commands.setAI(newValue)
					end,
				})
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Fog of war on local map"),
				leftSide = true,
				variable = mwse.mcm.createCustom({
					getter = function(self)
						return not tes3.worldController.menuController.fogOfWarDisabled
					end,
					setter = function(self, newValue)
						commands.setFogOfWar(newValue)
					end
				})
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Wireframe mode"),
				leftSide = true,
				variable = mwse.mcm.createCustom({
					getter = function(self)
						return tes3.worldController.menuController.wireframeEnabled
					end,
					setter = function(self, newValue)
						commands.setWireframe(newValue)
					end
				})
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Draw cell borders"),
				leftSide = true,
				variable = mwse.mcm.createCustom({
					getter = function(self)
						return tes3.worldController.menuController.bordersEnabled
					end,
					setter = function(self, newValue)
						tes3.worldController.menuController.bordersEnabled = newValue
					end
				})
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Draw collision boxes"),
				leftSide = true,
				variable = mwse.mcm.createCustom({
					getter = function(self)
						return tes3.worldController.menuController.collisionBoxesEnabled
					end,
					setter = function(self, newValue)
						tes3.worldController.menuController.collisionBoxesEnabled = newValue
					end
				})
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Draw path grid nodes"),
				leftSide = true,
				variable = mwse.mcm.createCustom({
					getter = function(self)
						return tes3.worldController.menuController.pathGridShown
					end,
					setter = function(self, newValue)
						tes3.worldController.menuController.pathGridShown = newValue
					end
				})
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Teleportation spells enabled"),
				leftSide = true,
				variable = mwse.mcm.createCustom({
					getter = function(self)
						return not tes3.worldController.flagTeleportingDisabled
					end,
					--- @param newValue boolean
					setter = function(self, newValue)
						tes3.worldController.flagTeleportingDisabled = not newValue
					end
				})
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Levitation spells enabled"),
				leftSide = true,
				variable = mwse.mcm.createCustom({
					getter = function(self)
						return not tes3.worldController.flagLevitationDisabled
					end,
					--- @param newValue boolean
					setter = function(self, newValue)
						tes3.worldController.flagLevitationDisabled = not newValue
					end
				})
			})
		end

		do -- Mechanics
			local container = ui.createCategory(contentsBlock, i18n("Mechanics"))

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Combat enabled"),
				leftSide = true,
				variable = mwse.mcm.createTableVariable({ table = config, id = "combatEnabled" })
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Rest interrupt enabled"),
				leftSide = true,
				variable = mwse.mcm.createTableVariable({ table = config, id = "restInterruptEnabled" })
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Essential actors can't be damaged"),
				leftSide = true,
				variable = mwse.mcm.createTableVariable({ table = config, id = "blockDamageForEssentialActors" })
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Always hit"),
				leftSide = true,
				variable = mwse.mcm.createTableVariable({ table = config, id = "alwaysHit" })
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Casting always succeeds"),
				leftSide = true,
				variable = mwse.mcm.createTableVariable({ table = config, id = "castingAlwaysSucceeds" })
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Spells don't consume magicka"),
				leftSide = true,
				variable = mwse.mcm.createTableVariable({ table = config, id = "spellsConsumeNoMagicka" })
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Enchantments don't consume charge"),
				leftSide = true,
				variable = mwse.mcm.createTableVariable({ table = config, id = "enchantmentsConsumeNoCharge" })
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Brewing potions always succeeds"),
				leftSide = true,
				variable = mwse.mcm.createTableVariable({ table = config, id = "potionBrewingAlwaysSucceeds" })
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Self-repairing equipment always succeeds"),
				leftSide = true,
				variable = mwse.mcm.createTableVariable({ table = config, id = "repairingAlwaysSucceeds" })
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Picking locks always succeeds"),
				leftSide = true,
				variable = mwse.mcm.createTableVariable({ table = config, id = "lockPickAlwaysSucceeds" })
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Player doesn't recieve Sun Damage as a Vampire"),
				leftSide = true,
				variable = mwse.mcm.createTableVariable({ table = config, id = "blockSunDamage" })
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Fatiguesless jumping"),
				leftSide = true,
				variable = mwse.mcm.createTableVariable({ table = config, id = "fatiguelessJumping" })
			})
		end

		do -- Security & Crime
			local container = ui.createCategory(contentsBlock, i18n("Security & Crime"))

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Auto unlock doors and containers"),
				leftSide = true,
				variable = mwse.mcm.createTableVariable({ table = config, id = "unlockEnabled" })
			})

			local function getBountyLabel()
				local bounty = 0
				if tes3.mobilePlayer then
					bounty = tes3.mobilePlayer.bounty
				end
				return string.format(i18n("Current player bounty") .. " = %s.", bounty)
			end

			mwse.mcm.createButton(container, {
				label = getBountyLabel(),
				buttonText = i18n("Clear bounty"),
				postCreate = function(self)
					self.label = getBountyLabel()
					self.elements.label.text = getBountyLabel()
				end,
				callback = function(self)
					commands.clearBounty()
					self:postCreate()
				end
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Stealing owned items is not a crime"),
				leftSide = true,
				variable = mwse.mcm.createTableVariable({ table = config, id = "stealingFree" })
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Picking locks isn't considered a crime"),
				leftSide = true,
				variable = mwse.mcm.createTableVariable({ table = config, id = "lockPickNotCrime" })
			})

			mwse.mcm.createButton(container, {
				label = i18n("Clear stolen flag on items in player's inventory"),
				buttonText = i18n("Clear"),
				callback = function(self)
					commands.clearStolenFlag()
					tes3.messageBox(i18n("Stolen flag cleared."))
				end
			})
		end

		do -- Time & Weather
			local container = ui.createCategory(contentsBlock, i18n("Time & Weather"))

			local weathers = {}
			for weather, id in pairs(tes3.weather) do
				table.insert(weathers, { label = i18n("weather." .. util.capitalize(weather)), value = id })
			end
			table.sort(weathers, function(a, b)
				return a.label < b.label
			end)

			mwse.mcm.createDropdown(container, {
				label = i18n("Change current weather:"),
				options = weathers,
				variable = mwse.mcm.createCustom({
					getter = function()
						return tes3.getCurrentWeather().index or 0
					end,
					setter = function(self, newVal)
						tes3.worldController.weatherController:switchImmediate(newVal)
					end
				})
			})

			mwse.mcm.createTextField(container, {
				label = i18n("Timescale"),
				-- TODO: might want to save the changes to timescale
				variable = mwse.mcm.createCustom({
					getter = function(self)
						return tes3.worldController.timescale.value
					end,
					converter = tonumber,
					setter = function(self, newValue)
						tes3.worldController.timescale.value = newValue
					end,

				})
			})

			mwse.mcm.createSlider(container, {
				label = i18n("Simulation time scale"),
				min = 0.5,
				max = 2.0,
				jump = 0.01,
				decimalPlaces = 2,
				variable = mwse.mcm.createCustom({
					getter = function(self)
						return tes3.worldController.simulationTimeScalar
					end,
					setter = function(self, newValue)
						tes3.worldController.simulationTimeScalar = newValue
					end
				})
			})
		end

		do -- Misc
			local container = ui.createCategory(contentsBlock, i18n("Misc"))

			local resetActors = container:createButton({
				text = i18n("Reset actors")
			})
			resetActors:registerAfter(tes3.uiEvent.mouseClick, function(e)
				commands.resetActors()
			end)

			local fixMe = container:createButton({
				text = i18n("Fix me")
			})
			fixMe:registerAfter(tes3.uiEvent.mouseClick, function(e)
				commands.fixMe()
			end)

			local killHostiles = container:createButton({
				text = i18n("Kill hostiles")
			})
			killHostiles:registerAfter(tes3.uiEvent.mouseClick, function(e)
				commands.killHostiles()
			end)

			local fillMap = container:createButton({
				text = i18n("Show all map markers")
			})
			fillMap:registerAfter(tes3.uiEvent.mouseClick, function(e)
				commands.fillMap()
			end)

			local fillJournal = container:createButton({
				text = i18n("Fill journal")
			})
			fillJournal:registerAfter(tes3.uiEvent.mouseClick, function(e)
				commands.fillJournal()
			end)

			local statsReview = container:createButton({
				text = i18n("Open stats review menu")
			})
			statsReview:registerAfter(tes3.uiEvent.mouseClick, function(e)
				commands.enableStatReviewMenu()
			end)

			local rechargePowers = container:createButton({
				text = i18n("Recharge player powers")
			})
			rechargePowers:registerAfter(tes3.uiEvent.mouseClick, function(e)
				commands.rechargePowers()
				tes3.messageBox(i18n("All powers recharged."))
			end)

			local removeMagic = container:createButton({
				text = i18n("Remove magic")
			})
			removeMagic:registerAfter(tes3.uiEvent.mouseClick, function(e)
				commands.removeMagic()
				tes3.messageBox(i18n("Removed all curses, diseases and spells."))
			end)

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Player can colide with other actors and projectiles?"),
				leftSide = true,
				variable = mwse.mcm.createCustom({
					getter = function(self)
						return tes3.mobilePlayer.mobToMobCollision
					end,
					setter = function(self, newValue)
						tes3.mobilePlayer.mobToMobCollision = newValue
					end,
				}),
			})

			mwse.mcm.createOnOffButton(container, {
				label = i18n("Player can colide with other objects?"),
				leftSide = true,
				variable = mwse.mcm.createCustom({
					getter = function(self)
						return tes3.mobilePlayer.movementCollision
					end,
					setter = function(self, newValue)
						tes3.mobilePlayer.movementCollision = newValue
					end,
				}),
			})
		end
	end

	local playerContainer = ui.createTabContainer(menu, tes3ui.registerID("CommandMenu_player_container"))
	tabs.playerContainer = playerContainer
	do -- Player tab
		local pane = ui.createSearchPane(playerContainer, function(category, searchTerm, cleared)
			local contentsContainer = category:findChild("ContentsContainer")
			---@cast contentsContainer tes3uiElement
			for _, statBlock in ipairs(contentsContainer.children) do
				local labelBlock = statBlock:findChild("LabelBlock")
				---@cast labelBlock tes3uiElement
				local label = labelBlock.children[1]
				local statContainer = labelBlock.parent
				if cleared then
					statContainer.visible = true
				else
					if util.ciContains(label.text, searchTerm) then
						statContainer.visible = true
					else
						statContainer.visible = false
					end
				end
			end
		end, uiid.playerPane)

		ui.recreatePlayerPane(pane)
	end

	local itemsContainer = ui.createTabContainer(menu, tes3ui.registerID("CommandMenu_items_container"))
	tabs.itemsContainer = itemsContainer
	do -- Items tab
		local count = mwse.mcm.createVariable({ value = 1 })
		local slider = mwse.mcm.createSlider(itemsContainer, {
			label = i18n("No. items to add"),
			variable = count,
			min = 1,
			max = 10,
			jump = 1,
		})

		local pane = ui.createSearchPane(itemsContainer, standardFilterHidden)

		for _, item in ipairs(objects.items) do
			local select = pane:createTextSelect({ text = util.getNiceName(item) })
			select:registerAfter(tes3.uiEvent.mouseClick, function(e)
				tes3.addItem({
					item = item,
					count = count.value,
					reference = tes3.player,
				})
				tes3.messageBox(i18n("Added") .. " %d %q.", count.value, item.name)
			end)
			select:register(tes3.uiEvent.help, function(e)
				local tooltip = tes3ui.createTooltipMenu({ item = item })
				local border = createAutoSizedBlock(tooltip)
				border.childAlignX = 0.5
				border.borderAllSides = 8
				border.paddingAllSides = 8
				local icon = border:createImage({ path = "icons\\" .. item.icon })
				icon.imageScaleX = 2
				icon.imageScaleY = 2
				tooltip:updateLayout()
			end)
			select.visible = false
		end
	end

	local spellsContainer = ui.createTabContainer(menu, tes3ui.registerID("CommandMenu_spells_container"))
	tabs.spellsContainer = spellsContainer
	do -- Spells tab
		local pane = ui.createSearchPane(spellsContainer, standardFilterHidden)

		local spellTypeNames = table.invert(tes3.spellType)
		for i, name in pairs(spellTypeNames) do
			spellTypeNames[i] = util.capitalize(name)
		end
		local pts = tes3.findGMST(tes3.gmst.spoints).value --[[@as string]]

		for _, spell in ipairs(objects.spells) do
			local select = pane:createTextSelect({
				text = string.format("%s, (%s, %d %s)",
					spell.name, i18n(spellTypeNames[spell.castType]), spell.magickaCost, pts)
			})
			select:registerAfter(tes3.uiEvent.mouseClick, function(e)
				tes3.playSound({ sound = "spellmake success" })
				tes3.addSpell({
					spell = spell,
					reference = tes3.player,
				})
				tes3.messageBox(i18n("Learned") .. " %q.", spell.name)
			end)
			select:register(tes3.uiEvent.help, function(e)
				tes3ui.createTooltipMenu({ spell = spell })
			end)
			select.visible = false
		end
	end

	local soulGemsContainer = ui.createTabContainer(menu, tes3ui.registerID("CommandMenu_soulGem_container"))
	tabs.soulGemsContainer = soulGemsContainer
	do -- Soul Gems tab
		-- Let's take common soul gem as starting gem, because the first one is Azura's star.
		local startingGem = objects.soulGems[2]
		local selectedGemVariable = mwse.mcm.createVariable({
			value = startingGem
		})

		local selectedSoulVariable = mwse.mcm.createVariable({
			value = util.getStartingCreature(objects.creatures, startingGem)
		})

		--- @type mwseMCMDropdownOption[]
		local options = {}
		for _, soulGem in ipairs(objects.soulGems) do
			table.insert(options, {
				label = soulGem.name,
				value = soulGem
			})
		end

		local topBlock = ui.createLeftRightBlock(
			soulGemsContainer, tes3ui.registerID("CommandMenu_soulGems_top_block_container"))
		topBlock.borderAllSides = 4

		local dropDown = mwse.mcm.createDropdown(topBlock, {
			label = i18n("Choose a Soul Gem:"),
			options = options,
			variable = selectedGemVariable,
		})

		local previewBlock = ui.createLeftRightBlock(topBlock,
			tes3ui.registerID("CommandMenu_soulGems_top_block_previewContainer"))

		ui.recreateSoulGemPreview(previewBlock, selectedGemVariable.value, selectedSoulVariable.value)
		-- Update currently selected soul gem preview
		dropDown.callback = function(self)
			selectedSoulVariable.value = util.getStartingCreature(objects.creatures, selectedGemVariable.value)
			ui.recreateSoulGemPreview(previewBlock, selectedGemVariable.value, selectedSoulVariable.value)
		end

		soulGemsContainer:createLabel({
			text = i18n("Choose a Soul:"),
		})

		local pane = ui.createSearchPane(soulGemsContainer, standardFilterVisible)
		local pts = tes3.findGMST(tes3.gmst.spoints).value --[[@as string]]

		for _, creature in ipairs(objects.creatures) do
			local select = pane:createTextSelect({
				text = string.format("%s, (%d %s)", util.getNiceName(creature), creature.soul, pts)
			})
			select:registerAfter(tes3.uiEvent.mouseClick, function(e)
				local maxSoul = selectedGemVariable.value.soulGemCapacity
				if creature.soul > maxSoul then
					tes3.messageBox(i18n("Too large soul"))
					return
				end
				selectedSoulVariable.value = creature
				ui.recreateSoulGemPreview(previewBlock, selectedGemVariable.value, selectedSoulVariable.value)
				select:getTopLevelMenu():updateLayout()
			end)
		end
	end

	local teleportContainer = ui.createTabContainer(menu, tes3ui.registerID("CommandMenu_teleport_container"))
	tabs.teleportContainer = teleportContainer
	do -- Teleport tab
		local current = mwse.mcm.createVariable({ value = 1 })

		local dropDown = mwse.mcm.createDropdown(teleportContainer, {
			label = i18n("Teleport to..."),
			options = {
				{ label = i18n("Cell"), value = 1 },
				{ label = i18n("NPC"), value = 2 },
			},
			variable = current,
			callback = function(self)
				local cell = teleportContainer:findChild("CommandMenu_teleport_cell_container") --[[@as tes3uiElement]]
				local NPC = teleportContainer:findChild("CommandMenu_teleport_npc_container") --[[@as tes3uiElement]]
				if current.value == 1 then
					ui.showTab(cell)
					ui.hideTab(NPC)
				else
					ui.hideTab(cell)
					ui.showTab(NPC)
				end
			end
		})

		local cellContainer = ui.createTabContainer(teleportContainer,
			tes3ui.registerID("CommandMenu_teleport_cell_container"))
		-- This is the default view in teleport tab.
		cellContainer.visible = true

		-- Teleport to Cell
		local pane = ui.createSearchPane(cellContainer, standardFilterVisible)
		for _, cell in ipairs(objects.cells) do
			local select = pane:createTextSelect({
				text = cell.editorName
			})
			select:registerAfter(tes3.uiEvent.mouseClick, function(e)
				ui.closeMenu()
				commands.teleport(cell)
			end)
		end

		-- Teleport to NPC
		local npcContainer = ui.createTabContainer(teleportContainer, tes3ui.registerID("CommandMenu_teleport_npc_container"))
		local pane = ui.createSearchPane(npcContainer, standardFilterVisible)
		local idFormat = i18n("Id") .. ": %q"
		local locationFormat = i18n("Located at") .. ": %s"
		local deadFormat = i18n("Dead") .. ": %s"
		for _, npc in ipairs(objects.npcs) do
			local select = pane:createTextSelect({
				text = util.getNiceName(npc)
			})
			select:registerAfter(tes3.uiEvent.mouseClick, function()
				openTeleportMenuNPC(npc)
			end)
			select:register(tes3.uiEvent.help, function(e)
				local tooltip = tes3ui.createTooltipMenu()
				local npcRef = tes3.getReference(npc.id)

				local titleBlock = ui.createLeftRightBlock(tooltip)
				titleBlock.childAlignX = 0.5
				titleBlock.paddingAllSides = 8
				local title = titleBlock:createLabel({ text = util.getNiceName(npc) })
				title.color = tes3ui.getPalette(tes3.palette.bigHeaderColor)

				local bodyBlock = ui.createTopBottomBlock(tooltip)
				bodyBlock.childAlignX = 0
				bodyBlock.paddingAllSides = 8
				bodyBlock:createLabel({ text = string.format(idFormat, npcRef.id) })
				bodyBlock:createLabel({ text = string.format(locationFormat, npcRef.cell.editorName) })
				bodyBlock:createLabel({ text = string.format(deadFormat,
					npcRef.isDead and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value)
				})
			end)
		end
	end

	local factionsContainer = ui.createTabContainer(menu, tes3ui.registerID("CommandMenu_factions_container"))
	tabs.factionsContainer = factionsContainer
	do -- Factions tab
		local pane = ui.createSearchPane(factionsContainer, function(category, searchTerm, cleared)
			local label = category:findChild("CategoryLabel")
			--- @cast label tes3uiElement
			if cleared then
				category.visible = true
			else
				if util.ciContains(label.text, searchTerm) then
					category.visible = true
				else
					category.visible = false
				end
			end
		end)

		for _, faction in ipairs(objects.factions) do
			local container = ui.createCategory(pane, util.getNiceName(faction))
			local label = container:createLabel({ text = util.getFactionLabel(faction) })
			local buttonsBlock = ui.createLeftRightBlock(container)
			buttonsBlock.borderAllSides = 4

			local join = buttonsBlock:createButton({
				text = faction.playerJoined and i18n("Leave") or i18n("Join"),
			})
			join:registerAfter(tes3.uiEvent.mouseClick, function(e)
				if faction.playerJoined then
					faction:leave()
					label.text = util.getFactionLabel(faction)
					join.text = i18n("Join")
					return
				end
				faction:join()
				label.text = util.getFactionLabel(faction)
				join.text = i18n("Leave")
			end)

			local demote = buttonsBlock:createButton({
				text = i18n("Demote"),
			})
			demote:registerAfter(tes3.uiEvent.mouseClick, function(e)
				faction:demote()
				label.text = util.getFactionLabel(faction)
			end)

			local promote = buttonsBlock:createButton({
				text = i18n("Promote"),
			})
			promote:registerAfter(tes3.uiEvent.mouseClick, function(e)
				faction:promote()
				label.text = util.getFactionLabel(faction)
			end)

			local expel = buttonsBlock:createButton({
				text = faction.playerExpelled and i18n("Rejoin") or i18n("Expel")
			})
			expel:registerAfter(tes3.uiEvent.mouseClick, function(e)
				if not faction.playerJoined then return end
				if faction.playerExpelled then
					faction:clearExpel()
					expel.text = i18n("Expel")
					label.text = util.getFactionLabel(faction)
					return
				end
				faction:expel()
				expel.text = i18n("Rejoin")
				label.text = util.getFactionLabel(faction)
			end)
		end
	end

	local questsContainer = ui.createTabContainer(menu, tes3ui.registerID("CommandMenu_quests_container"))
	tabs.questsContainer = questsContainer
	do -- Quests tab
		local currentQuest = tes3.worldController.quests[1]
		local label = questsContainer:createLabel({ text = i18n("Choose a quest...") })
		label.color = tes3ui.getPalette(tes3.palette.headerColor)

		local questsPane = ui.createSearchPane(questsContainer, standardFilterVisible)
		questsPane.heightProportional = 2 / 3

		local currentContainer = questsContainer:createThinBorder({ id = tes3ui.registerID("CommandMenu_quests_current_container") })
		currentContainer.autoHeight = true
		currentContainer.autoWidth = true
		currentContainer.widthProportional = 1.0
		currentContainer.heightProportional = 4 / 3
		currentContainer.flowDirection = tes3.flowDirection.topToBottom
		currentContainer.paddingAllSides = 2

		for _, quest in ipairs(tes3.worldController.quests) do
			local select = questsPane:createTextSelect({ text = quest.id })
			select:registerAfter(tes3.uiEvent.mouseClick, function(e)
				currentQuest = quest
				recreateQuestInfosList(currentContainer, currentQuest)
			end)
		end

		recreateQuestInfosList(currentContainer, currentQuest)
	end

	-- Done button
	local doneContainer = ui.createLeftRightBlock(menu, tes3ui.registerID("CommandMenu_done_container"))
	doneContainer.childAlignX = 1.0

	local done = doneContainer:createButton({
		id = tes3ui.registerID(uiid.doneButton),
		text = tes3.findGMST(tes3.gmst.sClose).value --[[@as string]]
	})
	done:registerAfter(tes3.uiEvent.mouseClick, ui.closeMenu)

	-- Create Tab buttons
	local firstButton = ui.createTabButton(tabsButtonsContainer, i18n("General"), tabs, "generalContainer", i18n("General"))
	ui.createTabButton(tabsButtonsContainer, i18n("Player"), tabs, "playerContainer", i18n("Player stats"))
	ui.createTabButton(tabsButtonsContainer, i18n("Items"), tabs, "itemsContainer", i18n("Choose items to add"))
	ui.createTabButton(tabsButtonsContainer, i18n("Spells"), tabs, "spellsContainer", i18n("Choose spells to learn"))
	ui.createTabButton(tabsButtonsContainer, i18n("Soul Gems"), tabs, "soulGemsContainer", i18n("Choose a soul gem to add"))
	ui.createTabButton(tabsButtonsContainer, i18n("Teleport"), tabs, "teleportContainer", i18n("Teleport"))
	ui.createTabButton(tabsButtonsContainer, i18n("Factions"), tabs, "factionsContainer", i18n("Manage faction membership"))
	ui.createTabButton(tabsButtonsContainer, i18n("Quests"), tabs, "questsContainer", i18n("Quests"))

	-- Show the first tab.
	firstButton:triggerEvent(tes3.uiEvent.mouseClick)
	menu:getTopLevelMenu():updateLayout()
	menuElements.menu.visible = false
	return { menu = menuElements.menu }
end

function ui.isMenuOpen()
	if not tes3.menuMode() then
		return false
	end
	local menu = tes3ui.findMenu(menuID)
	if not menu then
		return false
	end
	return menu.visible
end

function ui.openMenu()
	if tes3.onMainMenu() then
		tes3.messageBox(i18n("Load a game to open Command Menu."))
		return
	end
	if ui.isMenuOpen() then return end
	local menu = tes3ui.findMenu(menuID)
	if not menu then
		log:warn("Command Menu not found.")
		tes3.messageBox("Command Menu not found.")
		return
	end

	-- Update the player page with current attribute/skill values.
	local playerPane = menu:findChild(uiid.playerPane)
	---	@cast playerPane tes3uiElement
	ui.recreatePlayerPane(playerPane)
	menu.visible = true
	tes3ui.enterMenuMode(menuID)
end

function ui.closeMenu()
	local menu = tes3ui.findMenu(menuID)
	if not menu then return end
	mwse.saveConfig(config.fileName, config)
	menu.visible = false
	tes3ui.leaveMenuMode()
end

return ui
