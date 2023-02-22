local data = require("JosephMcKean.teachCompanionSpells.data")

--- Checks if the npc is a potential follower
--- @param ref tes3reference
--- @return boolean
local function checkIfPotentialCompanion(ref)
	return (ref.context and ref.context["companion"]) and true or false
end
-- (currentRef.context and currentRef.context["companion"]) and true

--- Checks if the npc is a potential follower
--- @param ref tes3reference
--- @return boolean
local function checkIfCurrentCompanion(ref)
	return (ref.context and ref.context["companion"] and ref.context["companion"] == 1) or
	       tes3.getCurrentAIPackageId({ reference = ref }) == tes3.aiPackage.follow
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
		end
	end
end

--- @param e uiActivatedEventData
local function onMenuDialogActivated(e)
	local actor = tes3ui.getServiceActor()
	local actorRef = actor.reference ---@type tes3reference

	local topicsScrollPane = e.element:findChild(data.GUI_ID.MenuDialog_TopicList)
	local divider = topicsScrollPane:findChild(data.GUI_ID.MenuDialog_Divider)
	local topicsList = divider.parent

	-- Need to update the visibility once after the menu is updated for the
	-- first time, after that, we update the visibility on each "uiEvent" event.
	local updatedOnce = false
	local function updateOnce()
		-- e.element:unregisterAfter(tes3.uiEvent.update, updateOnce)
		-- Using unregisterAfter would cause the game to crash if there is still a lower priority callback registered.
		if updatedOnce then
			return
		end
		updatedOnce = true

		setServiceButtonVisibilitiesToTrue()
	end
	e.element:registerAfter(tes3.uiEvent.update, updateOnce)

	-- Add the service buttons
	if checkIfPotentialCompanion(actorRef) or checkIfCurrentCompanion(actorRef) then
		-- Create the new button
		local button = topicsList:createTextSelect({
			id = data.GUI_ID.MenuDialog_Teach_Spells,
			text = data.GUI_text.MenuDialog_Teach_Spells,
		})
		-- Potential companion but not yet a companion
		if (actorRef.context and actorRef.context["companion"] and actorRef.context["companion"] ~= 1) then
			button.visible = false
		end

		-- By default move it above the divider, into the services section
		topicsList:reorderChildren(divider, button, 1)

		--- Called when the player clicks on the service button. Opens the teach spells service menu
		local function showTeachSpellsMenu(playerSpells, actorSpells)
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
			local labelMy = blockMy:createLabel({
				id = data.GUI_ID.MenuTeachSpells_label_my,
				text = data.GUI_text.MenuTeachSpells_label_my,
			})
			local labelYour = blockYour:createLabel({
				id = data.GUI_ID.MenuTeachSpells_label_your,
				text = actorRef.object.name .. "'s spells",
			})
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

			local function createSpellBlock(ref, spell)
				local spellList = ((ref == tes3.player) and listMy) or listYour
				local targetRef = ((ref == tes3.player) and actorRef) or tes3.player
				local targetSpells = ((ref == tes3.player) and actorSpells) or playerSpells
				local spellBlock = spellList:createBlock({ id = data.GUI_ID.MenuTeachSpells_spell })
				spellBlock.parent.flowDirection = "top_to_bottom"
				spellBlock.autoWidth = true
				spellBlock.autoHeight = true
				spellBlock.borderLeft = 4
				local icon = spellBlock:createImage({
					id = tes3ui.registerID("MenuTeachSpells_icon"),
					path = "icons\\" .. spell.effects[1].object.icon,
				})
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
							local effectBlock = helpBlock:createBlock(
							                    { id = tes3ui.registerID("MenuTeachSpells_help_effect" .. tostring(i)) })
							effectBlock.autoHeight = true
							effectBlock.autoWidth = true
							local effectIcon = effectBlock:createImage({
								id = tes3ui.registerID("MenuTeachSpells_help_icon"),
								path = "icons\\" .. spell.effects[i].object.icon,
							})
							effectIcon.borderRight = 10
							local magnitude = ""
							if not effect.object.hasNoMagnitude then
								if effect.min == effect.max then
									if effect.max == 1 then
										magnitude = effect.max .. " pt "
									else
										magnitude = effect.max .. " pts "
									end
								else
									if effect.max == 1 then
										magnitude = (effect.min .. " to " .. effect.max .. " pt ")
									else
										magnitude = (effect.min .. " to " .. effect.max .. " pts ")
									end
								end
							end
							local duration = ""
							if not effect.object.hasNoDuration then
								if effect.min == 1 then
									duration = "for " .. effect.duration .. " sec "
								else
									duration = "for " .. effect.duration .. " secs "
								end
							end
							local range = effect.range and ("in " .. effect.range .. " ft ") or ""
							local rangeType = ((effect.rangeType == tes3.effectRange.self) and "on Self") or
							                  ((effect.rangeType == tes3.effectRange.touch) and "on Touch") or
							                  ((effect.rangeType == tes3.effectRange.targer) and "on Target") or ""
							local descLabel = effectBlock:createLabel({
								text = effect.object.name .. " " .. magnitude .. duration .. range .. rangeType,
							})
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
				local spells = ((ref == tes3.player) and playerSpells) or actorSpells
				for _, spell in ipairs(spells) do
					createSpellBlock(ref, spell)
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
		button:register("mouseClick", function()
			local playerSpells = tes3.getSpells({
				target = tes3.player,
				spellType = tes3.spellType.spell,
				getRaceSpells = false,
				getBirthsignSpells = false,
			})
			local actorSpells = tes3.getSpells({
				target = actorRef,
				spellType = tes3.spellType.spell,
				getRaceSpells = false,
				getBirthsignSpells = false,
			})
			if playerSpells == nil and actorSpells == nil then
				tes3.messageBox("Both of you don't know any spell")
			else
				table.sort(playerSpells, function(a, b)
					return a.name < b.name
				end)
				table.sort(actorSpells, function(a, b)
					return a.name < b.name
				end)
				showTeachSpellsMenu(playerSpells, actorSpells)
			end
		end)
		-- Add a tooltip
		button:register("help", function()
			local tooltip = tes3ui.createTooltipMenu()
			local tooltipText = tooltip:createLabel({ text = data.GUI_text.helpLabelText })
			tooltipText.wrapText = true
		end)
	end
end

local function onInit()
	event.register("infoGetText", setServiceButtonVisibilitiesToTrue)
	event.register("uiEvent", setServiceButtonVisibilitiesToTrue)
	event.register("uiActivated", onMenuDialogActivated, { filter = "MenuDialog", priority = -100 })
end
event.register("initialized", onInit)

--[[
    Convenient command:
    tes3.setAIFollow({reference = currentRef, target = tes3.player})
]]
