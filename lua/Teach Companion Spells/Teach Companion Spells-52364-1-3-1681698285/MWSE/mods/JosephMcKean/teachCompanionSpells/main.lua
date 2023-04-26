local configPath = "Teach Companion Spells"
local defaultConfig = { hideSpellsButton = true, debugMode = false }
local config = mwse.loadConfig(configPath, defaultConfig)
local data = require("JosephMcKean.teachCompanionSpells.data")
local log = require("logging.logger").new({ name = configPath, logLevel = config.debugMode and "DEBUG" or "INFO" })

--- Checks if the npc is a potential follower
--- @param ref tes3reference
--- @return boolean
local function checkIfPotentialCompanion(ref)
	local isPotentialCompanion = (ref.context and ref.context["companion"]) and true or false
	if isPotentialCompanion then
		log:debug("%s is a potential companion", ref.id)
	end
	return isPotentialCompanion
end

--- Checks if the npc is a potential follower
--- @param ref tes3reference
--- @return boolean
local function checkIfCurrentCompanion(ref)
	local isCurrentCompanion = ref.context and ref.context["companion"] and ref.context["companion"] == 1
	local aiPlanner = ref.mobile.aiPlanner
	if aiPlanner then
		local aiPackage = aiPlanner:getActivePackage()
		isCurrentCompanion = isCurrentCompanion or (aiPackage.type == tes3.aiPackage.follow and aiPackage.targetActor.reference == tes3.player)
		if isCurrentCompanion then
			log:debug("%s is currently a companion", ref.id)
		end
	end
	return isCurrentCompanion
end

-- To keep the service buttons visible after the menu updates
local function setServiceButtonVisibilitiesToTrue()
	local menu = tes3ui.findMenu(data.GUI_ID.MenuDialog)
	if not menu then
		return
	end

	local serviceButton = menu:findChild(data.GUI_ID.MenuDialog_Teach_Spells)
	if serviceButton and not serviceButton.visible then
		if checkIfCurrentCompanion(tes3ui.getServiceActor().reference) then
			serviceButton.visible = true
			log:debug("Teach Spells button set to visible")
		end
	end
end

local function buttonDisabled(playerSpells, actorSpells)
	return table.empty(playerSpells) and table.empty(actorSpells)
end

local function getSpells(targetRef)
	local spells = tes3.getSpells({ target = targetRef, spellType = tes3.spellType.spell, getRaceSpells = false, getBirthsignSpells = false })
	table.sort(spells, function(a, b)
		return a.name < b.name
	end)
	return spells
end

--- @param e uiActivatedEventData
local function onMenuDialogActivated(e)
	local actor = tes3ui.getServiceActor()
	local actorRef = actor.reference ---@type tes3reference
	log:debug("Talking to %s", actorRef.id)
	local topicsScrollPane = e.element:findChild(data.GUI_ID.MenuDialog_TopicList)
	local divider = topicsScrollPane:findChild(data.GUI_ID.MenuDialog_Divider)
	local topicsList = divider.parent

	-- Need to update the visibility once after the menu is updated for the
	-- first time, after that, we update the visibility on each "uiEvent" event.
	local updatedOnce = false
	local function updateOnce()
		if updatedOnce then
			return
		end
		updatedOnce = true
		setServiceButtonVisibilitiesToTrue()
	end
	e.element:registerAfter("update", updateOnce)

	-- Add the service buttons
	if checkIfPotentialCompanion(actorRef) or checkIfCurrentCompanion(actorRef) then
		-- Create the new button
		local button = topicsList:createTextSelect({ id = data.GUI_ID.MenuDialog_Teach_Spells, text = data.GUI_text.MenuDialog_Teach_Spells })
		log:debug("Teach Spells button created")
		-- Potential companion but not yet a companion
		if (actorRef.context and actorRef.context["companion"] and actorRef.context["companion"] ~= 1) then
			button.visible = false
		end

		-- By default move it above the divider, into the services section
		topicsList:reorderChildren(divider, button, 1)

		--- Called when the player clicks on the service button. Opens the teach spells service menu
		local function showTeachSpellsMenu()
			log:debug("Creating Teach Spells menu...")
			local menu = tes3ui.createMenu({ id = data.GUI_ID.MenuTeachSpells, dragFrame = true })
			menu.width = 700
			menu.height = 490
			menu.minWidth = 700
			menu.minHeight = 490
			menu.maxHeight = 490
			menu.flowDirection = "top_to_bottom"
			menu:findChild("PartDragMenu_title").text = "Teach Spells"
			local blockMain = menu:createBlock({ id = data.GUI_ID.MenuTeachSpells_block_main })
			blockMain.autoWidth = true
			blockMain.autoHeight = true
			blockMain.widthProportional = 1.0
			blockMain.flowDirection = "left_to_right"
			local blockMy = blockMain:createBlock({ id = data.GUI_ID.MenuTeachSpells_block_my })
			blockMy.autoWidth = true
			blockMy.autoHeight = true
			blockMy.widthProportional = 1.0
			blockMy.flowDirection = "top_to_bottom"
			local blockYour = blockMain:createBlock({ id = data.GUI_ID.MenuTeachSpells_block_your })
			blockYour.autoWidth = true
			blockYour.autoHeight = true
			blockYour.widthProportional = 1.0
			blockYour.flowDirection = "top_to_bottom"
			local labelMy = blockMy:createLabel({ id = data.GUI_ID.MenuTeachSpells_label_my, text = data.GUI_text.MenuTeachSpells_label_my })
			local labelYour = blockYour:createLabel({ id = data.GUI_ID.MenuTeachSpells_label_your, text = actorRef.object.name .. "'s spells" })
			labelMy.widthProportional = 1.0
			labelMy.borderAllSides = 10
			labelMy.wrapText = true
			labelMy.justifyText = "center"
			labelYour.widthProportional = 1.0
			labelYour.borderAllSides = 10
			labelYour.wrapText = true
			labelYour.justifyText = "center"
			local listMy = blockMy:createVerticalScrollPane({ id = data.GUI_ID.MenuTeachSpells_List_my })
			listMy.minWidth = 240
			listMy.minHeight = 360
			listMy.maxHeight = 360
			listMy.autoWidth = true
			listMy.borderAllSides = 5
			listMy.paddingLeft = 2
			listMy.flowDirection = "left_to_right"
			local listYour = blockYour:createVerticalScrollPane({ id = data.GUI_ID.MenuTeachSpells_List_your })
			listYour.minWidth = 240
			listYour.minHeight = 360
			listYour.maxHeight = 360
			listYour.autoWidth = true
			listYour.borderAllSides = 5
			listYour.paddingLeft = 2
			listYour.flowDirection = "left_to_right"

			---@param ref tes3reference
			---@param spell tes3spell
			local function createSpellBlock(ref, spell)
				local spellList = ((ref == tes3.player) and listMy) or listYour
				local targetRef = ((ref == tes3.player) and actorRef) or tes3.player
				local targetSpells = getSpells(targetRef)
				local spellBlock = spellList:createBlock({ id = data.GUI_ID.MenuTeachSpells_spell })
				spellBlock.parent.flowDirection = "top_to_bottom"
				spellBlock.autoWidth = true
				spellBlock.autoHeight = true
				spellBlock.borderLeft = 4
				local icon = spellBlock:createImage({ id = tes3ui.registerID("MenuTeachSpells_icon"), path = "icons\\" .. spell.effects[1].object.icon })
				icon.borderTop = 2
				local targetLearned = table.find(targetSpells, spell) and true or false
				local castChance = math.min(math.floor(spell:calculateCastChance({ caster = ref })), 100)
				local spellText = spellBlock:createTextSelect({
					id = tes3ui.registerID("MenuTeachSpells_spell"),
					text = spell.name .. " - " .. castChance .. "%",
					state = (targetLearned and tes3.uiState.disabled) or tes3.uiState.normal,
				})
				spellText.borderLeft = 4
				spellText.wrapText = true
				spellText.widthProportional = 1.0
				spellText.consumeMouseEvents = true
				spellText:register("help", function()
					local tooltip = tes3ui.createTooltipMenu()
					local helpText = tooltip:createLabel({ id = data.GUI_ID.MenuTeachSpells_helptext, text = spell.name })
					helpText.color = tes3ui.getPalette(tes3.palette.whiteColor)
					local helpBlock = tooltip:createBlock({ id = data.GUI_ID.MenuTeachSpells_help_block })
					helpBlock.autoHeight = true
					helpBlock.autoWidth = true
					helpBlock.flowDirection = "top_to_bottom"
					local school = tes3.skillName[spell.effects[1].object.skill]
					local schoolLabel = helpBlock:createLabel({ text = "School: " .. school })
					for i, effect in ipairs(spell.effects) do
						if effect and effect.object then
							local effectBlock = helpBlock:createBlock({ id = tes3ui.registerID("MenuTeachSpells_help_effect" .. tostring(i)) })
							effectBlock.autoHeight = true
							effectBlock.autoWidth = true
							local effectIcon = effectBlock:createImage({ id = tes3ui.registerID("MenuTeachSpells_help_icon"), path = "icons\\" .. spell.effects[i].object.icon })
							effectIcon.borderRight = 8
							local descLabel = effectBlock:createLabel({ text = tostring(effect) })
						end
					end
				end)
				spellText:register("mouseClick", function()
					-- Holding shift deletes spell
					local isShiftDown = tes3.worldController.inputController:isShiftDown()
					if isShiftDown then
						tes3.messageBox("%s's spell %s has been deleted", ref.object.name, spell.name)
						tes3.removeSpell({ reference = ref, spell = spell })
						spellText.parent:destroy()
					else
						if not targetLearned then
							tes3.messageBox("%s has learnt spell %s", targetRef.object.name, spell.name)
							tes3.addSpell({ reference = targetRef, spell = spell })
							targetLearned = true
							spellText.widget.state = tes3.uiState.disabled
							createSpellBlock(targetRef, spell)
						end
					end
					menu:updateLayout()
				end)
			end
			for _, ref in ipairs({ tes3.player, actorRef }) do
				local spells = getSpells(ref)
				if spells then
					for _, spell in ipairs(spells) do
						createSpellBlock(ref, spell)
					end
				end
			end
			local buttonOk = menu:createButton({ id = data.GUI_ID.MenuTeachSpells_ok, text = data.GUI_text.MenuTeachSpells_ok })
			buttonOk.borderBottom = 12
			buttonOk.absolutePosAlignX = 0.5
			buttonOk:register("mouseClick", function()
				tes3ui.leaveMenuMode()
				tes3ui.findMenu(data.GUI_ID.MenuTeachSpells):destroy()
			end)
			tes3ui.enterMenuMode(data.GUI_ID.MenuTeachSpells)
		end

		local function updateButton()
			local playerSpells = getSpells(tes3.player)
			local actorSpells = getSpells(actorRef)
			if buttonDisabled(playerSpells, actorSpells) then
				button.disabled = true
				button.widget.state = 2
			else
				button.disabled = false
			end
		end
		button:register("help", function()
			updateButton()
			if buttonDisabled(getSpells(tes3.player), getSpells(actorRef)) then
				local tooltip = tes3ui.createTooltipMenu()
				local tooltipText = tooltip:createLabel({ text = "Both of you don't know any spell" })
				tooltipText.wrapText = true
			end
		end)
		button:register("mouseClick", function()
			updateButton()
			showTeachSpellsMenu()
		end)

		-- Hide Spells button
		if config.hideSpellsButton then
			log:debug("Finding Spells button...")
			local spellsButton = e.element:findChild("MenuDialog_service_spells")
			timer.delayOneFrame(function()
				if not spellsButton.visible then
					log:debug("Spells button not visible")
					return
				end
				if button.disabled then
					log:debug("Teach Spells button is disabled")
					return
				end
				log:debug("Hiding Spells button...")
				spellsButton.visible = false
			end, timer.real)
		end
	end
end

local function onInit()
	event.register("infoGetText", setServiceButtonVisibilitiesToTrue)
	event.register("uiEvent", setServiceButtonVisibilitiesToTrue)
	event.register("uiActivated", onMenuDialogActivated, { filter = "MenuDialog", priority = -200 })
end
event.register("initialized", onInit)

local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = configPath })
	template:register()
	template.onClose = function()
		mwse.saveConfig(configPath, config)
	end
	local preferences = template:createSideBarPage{ label = "Mod Preferences", noScroll = true }
	preferences:createYesNoButton({
		label = "Hide Spells button",
		description = "Hide Spells button for companions who sell spells. (Default: Yes)",
		variable = mwse.mcm.createTableVariable { id = "hideSpellsButton", table = config },
	})
	preferences:createYesNoButton({
		label = "Debug mode",
		description = "For troubleshooting. (Default: No)",
		variable = mwse.mcm.createTableVariable { id = "debugMode", table = config },
		callback = function(self)
			log:setLogLevel(self.variable.value and "DEBUG" or "INFO")
		end,
	})
end
event.register("modConfigReady", registerModConfig)
