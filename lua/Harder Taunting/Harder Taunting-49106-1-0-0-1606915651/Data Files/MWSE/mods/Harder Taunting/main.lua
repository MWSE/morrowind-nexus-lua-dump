local mod = "Harder Taunting"
local version = "1.0.0"

local GUI_ID_MenuDialog = tes3ui.registerID("MenuDialog")
local GUI_ID_MenuDialog_topics_pane = tes3ui.registerID("MenuDialog_topics_pane")
local GUI_ID_MenuDialog_a_topic = tes3ui.registerID("MenuDialog_a_topic")
local GUI_ID_PartScrollPane_pane = tes3ui.registerID("PartScrollPane_pane")
local GUI_ID_MenuPersuasion = tes3ui.registerID("MenuPersuasion")
local GUI_ID_MenuPersuasion_ServiceList = tes3ui.registerID("MenuPersuasion_ServiceList")
local GUI_ID_MenuPersuasion_ServiceList_Taunt = tes3ui.registerID("MenuPersuasion_ServiceList_NewTaunt")

local oldMenuPositionX = nil
local oldMenuPositionY = nil

local function onTauntClick(e)
	local menuPersuasion = tes3ui.findMenu(GUI_ID_MenuPersuasion)
	local actor = menuPersuasion:getPropertyObject("MenuPersuasion_Actor")
	local speechcraft = tes3.getSkill(tes3.skill.speechcraft)
	local speechcraftModifier = math.max(0.2, math.min(1.0, (100 + actor.speechcraft.current - tes3.mobilePlayer.speechcraft.current) / 100))
	local success = tes3.persuade({ actor = actor, index = 2 })
	
	local dialoguePage
	local dialogueHeaderText
	if success then
		dialoguePage = 6
		dialogueHeaderText = tes3.findGMST(tes3.gmst.sTauntSuccess).value
		tes3.mobilePlayer:exerciseSkill(tes3.skill.speechcraft, speechcraft.actions[1])
	else
		if actor.fight and actor.fight >= 30 then
			actor.fight = math.max(30, actor.fight - math.round(math.random(3, 15) * speechcraftModifier))
		end
		dialoguePage = 7
		dialogueHeaderText = tes3.findGMST(tes3.gmst.sTauntFail).value
		tes3.mobilePlayer:exerciseSkill(tes3.skill.speechcraft, speechcraft.actions[2])
	end
	
	-- Show a dialogue if we can.
	local dialogue = tes3.findDialogue({ type = 3, page = dialoguePage })
	local info = dialogue:getInfo({ actor = actor })
	if (info) then
		local text = info.text
		if (text and text ~= "") then
			tes3ui.showDialogueMessage({ text = dialogueHeaderText, style = 1 })
			tes3ui.showDialogueMessage({ text = text })
			info:runScript(actor.reference)
		end
	end

	-- Update UI elements.
	tes3ui.updateDialogDisposition()
	
	-- Close the menu.
	if tes3.hasCodePatchFeature(271) then
		-- If the persuasion menu code patch feature has been activated execute the dirtiest hack ever.
		-- First close the menu normally.
		oldMenuPositionX = menuPersuasion.positionX
		oldMenuPositionY = menuPersuasion.positionY
		menuPersuasion:destroy()
		
		-- Then find the persuasion menu option and simulate a mouse click. Yes, I did that since dealing with npc fight ratings is a pain for this simple feature.
		local menuDialog = tes3ui.findMenu(GUI_ID_MenuDialog)
		local topicsPane = menuDialog:findChild(GUI_ID_MenuDialog_topics_pane):findChild(GUI_ID_PartScrollPane_pane)
		for _, element in pairs(topicsPane.children) do
			-- We only care about topics in the service list which have the same text as the persuasion option.
			if (element.id ~= GUI_ID_MenuDialog_a_topic) and (element.text == tes3.findGMST(tes3.gmst.sPersuasion).value) then
				oldMenuPositionX = menuPersuasion.positionX
				oldMenuPositionY = menuPersuasion.positionY
				element:triggerEvent("mouseClick")
			end
		end
	else
		oldMenuPositionX = nil
		oldMenuPositionY = nil
		menuPersuasion:destroy()
	end
end

-- Runs each time the persuasion menu is opened.
local function onPersuasionMenu(e)
	if oldMenuPositionX and oldMenuPositionY then
		e.element.positionX = oldMenuPositionX
		e.element.positionY = oldMenuPositionY
	end
	oldMenuPositionX = nil
	oldMenuPositionY = nil

    -- Find the list of persuasion options.
    local persuasionList = e.element:findChild(GUI_ID_MenuPersuasion_ServiceList)

    -- Taunt is the third option down.
    local tauntButton = persuasionList.children[3]

    -- The button is still there, just hidden, so there shouldn't be conflicts.
    tauntButton.visible = false
	
	-- Weird update required or the menu gets weird.
	e.element.visible = false
	e.element.visible = true
	e.element:updateLayout()
	
	-- Create our new button.
	if (not e.newlyCreated) then
		return
	end

	local tauntButton = persuasionList:createTextSelect({ id = GUI_ID_MenuPersuasion_ServiceList_Taunt, text = "Taunt" })
	tauntButton:register("mouseClick", onTauntClick)
	persuasionList:reorderChildren(3, tauntButton, 1)

	-- Weird update required or the menu gets weird.
	e.element.visible = false
	e.element.visible = true
	e.element:updateLayout()
end

local function onInitialized()
    event.register("uiActivated", onPersuasionMenu, { filter = "MenuPersuasion" })
    mwse.log("[%s %s] Initialized", mod, version)
end

event.register("initialized", onInitialized)