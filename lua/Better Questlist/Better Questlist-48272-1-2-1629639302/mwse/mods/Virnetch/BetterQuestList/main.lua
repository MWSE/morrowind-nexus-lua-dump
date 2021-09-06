local config = mwse.loadConfig("better_questlist")
local default = {
	showHidden = false,
	highlightR = 0,
	highlightG = 90,
	highlightB = 0,
	resetOnFinished = true
}
if config then
	for k, v in pairs(default) do
		if config[k] == nil then
			config[k] = v
		end
	end
else
	config = default
end

local function toggleHide(name)
	local quests = tes3.player.data.betterQuestList.quests
	if quests[name] then
		quests[name] = quests[name] + 1
		if quests[name] > 2 then
			quests[name] = nil
		end
	else
		quests[name] = 1
	end
end

local function update(list)
	local questList = list.children
	if not questList then return end
	if #questList == 0 then return end

	local quests = tes3.player.data.betterQuestList.quests
	local changedFinished = tes3.player.data.betterQuestList.changedFinished

	local finishedPalette = tes3ui.getPalette("journal_finished_quest_color")
	finishedPalette[1] = math.round(finishedPalette[1], 3)
	finishedPalette[2] = math.round(finishedPalette[2], 3)
	finishedPalette[3] = math.round(finishedPalette[3], 3)
	for _, quest in pairs(questList) do
		local name = quest.text
		if (not config.resetOnFinished) or changedFinished[name] or (
			math.round(quest.color[1], 3) ~= finishedPalette[1]
			and math.round(quest.color[2], 3) ~= finishedPalette[2]
			and math.round(quest.color[3], 3) ~= finishedPalette[3]
		) then
			if name then
				name = string.gsub(name, "%d", "", 3)	   --Remove the first 3 digits so it doesn't reset when changing load order and using abot's Smart Journal with load order based sorting
				if quests[name] == 2 then
					quest.alpha = 0.5
					local inputController = tes3.worldController.inputController
					if inputController:isKeyDown(tes3.scanCode.lShift) == false and config.showHidden == false then
						quest.visible = false
					else
						quest.visible = true
					end
				else
					quest.alpha = 1.0
					if quests[name] == 1 then
						quest.color = {
							config.highlightR/255,
							config.highlightG/255,
							config.highlightB/255
						}
					end
				end
				quest:register(
					"mouseClick",
					function(e)
						local inputController = tes3.worldController.inputController
						if inputController:isKeyDown(tes3.scanCode.lShift) == true then
							toggleHide(name)
						else
							quest:forwardEvent(e)
						end
					end
				)
				quest:register(
					"mouseLeave",
					function(e)
						quest:forwardEvent(e)
						update(list)
						local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
						menu:updateLayout()
					end
				)
			end
		else
			quests[name] = nil
			changedFinished[name] = true
		end
	end
end

local function journalUpdate()
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
	if menu then
		local questsButton = menu:findChild(tes3ui.registerID("MenuJournal_button_bookmark_quests"))
		if questsButton then
			questsButton:register("mouseClick", function(e)
				questsButton:forwardEvent(e)

				local topicScroll = menu:findChild(tes3ui.registerID("MenuJournal_topicscroll"))
				if topicScroll then
					local questList = topicScroll:findChild(tes3ui.registerID("PartScrollPane_pane"))
					if questList then
						update(questList)
						menu:updateLayout()
					end
				end
			end)
		end
		local topicScroll = menu:findChild(tes3ui.registerID("MenuJournal_topicscroll"))
		if topicScroll then
			local questList = topicScroll:findChild(tes3ui.registerID("PartScrollPane_pane"))
			if questList then
				update(questList)
			end
		end
	end
end
event.register("keyDown", journalUpdate, { filter = tes3.scanCode.lShift })
event.register("keyUp", journalUpdate, { filter = tes3.scanCode.lShift })

local function onJournalEnter()
	event.register("uiEvent", journalUpdate)
	event.register("menuExit", function()
		event.unregister("uiEvent", journalUpdate)
	end)
end
event.register("uiActivated", onJournalEnter, {filter = "MenuJournal"})

local function loaded()
	tes3.player.data.betterQuestList = tes3.player.data.betterQuestList or {}
	local data = tes3.player.data.betterQuestList

	data.quests = data.quests or {}
	data.changedFinished = data.changedFinished or {}
	mwse.log("[Better Questlist] Loaded")
end
event.register("loaded", loaded)

---------------------------------------------------------------------
-----------MCM-------------------------------------------------------
---------------------------------------------------------------------

local function registerModConfig()
	local template = mwse.mcm.createTemplate("Better Questlist")
	template:saveOnClose("better_questlist", config)
	local page = template:createPage{
		label = "Settings"
	}

	local settings = page:createCategory("Settings")
	settings:createOnOffButton{
		label = "Always show hidden quests",
		variable = mwse.mcm.createTableVariable{
			id = "showHidden",
			table = config
		}
	}
	settings:createOnOffButton{
		label = "Reset quest color/visibility when quest is finished",
		variable = mwse.mcm.createTableVariable{
			id = "resetOnFinished",
			table = config
		}
	}

	settings:createButton{
		label = "Reset all quests to original colors/visibility",
		buttonText = "Reset",
		callback = (function()
			tes3.player.data.betterQuestList.quests = {}
		end),
		inGameOnly = true
	}
	
	local highlight = page:createCategory("Quest Highlight Color")
	highlight:createSlider{
		label = "Red",
		max = 255,
		min = 0,
		variable = mwse.mcm:createTableVariable{
			id = "highlightR",
			table = config
		}
	}
	highlight:createSlider{
		label = "Green",
		max = 255,
		min = 0,
		variable = mwse.mcm:createTableVariable{
			id = "highlightG",
			table = config
		}
	}
	highlight:createSlider{
		label = "Blue",
		max = 255,
		min = 0,
		variable = mwse.mcm:createTableVariable{
			id = "highlightB",
			table = config
		}
	}
	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)