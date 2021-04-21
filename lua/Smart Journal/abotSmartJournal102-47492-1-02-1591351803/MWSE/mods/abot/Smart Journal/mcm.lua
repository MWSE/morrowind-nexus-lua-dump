local this = {}

local lib = require('abot.lib')

this.config = {}

function this.onCreate(container)
	local mainPane = lib.createMainPane(container)
	lib.createBooleanConfig({
		parent = mainPane,
		label = "Clear topics with no entries yet from the journal?",
		config = this.config,
		key = "clearTopicsWithNoEntries",
	})
	lib.createBooleanConfig({
		parent = mainPane,
		label = "Collapse journal paragraphs having the same date header?",
		config = this.config,
		key = "collapseDates",
	})
	lib.createBooleanConfig({
		parent = mainPane,
		label = "Skip links contained inside journal words?",
		config = this.config,
		key = "skipLinksInsideWords",
	})
	lib.createSliderConfig({
		parent = mainPane,
		label = "Add a prefix in order to group quest names?",
		config = this.config,
		key = "questPrefix",
		min = 0, max = 3, step = 1, jump = 1,
		info = '(0 = No, 1 = source mod loading index, 2 = source mod condensed name, 3 = quest id)',
	})
	lib.createBooleanConfig({
		parent = mainPane,
		label = "Sort quests list by quest name? (better to enable it when adding a prefix)",
		config = this.config,
		key = "questSort",
	})
	lib.createBooleanConfig({
		parent = mainPane,
		label = "Add quest id to quest hint?",
		config = this.config,
		key = "questHintQuestId",
	})
	lib.createBooleanConfig({
		parent = mainPane,
		label = "Add source mod name to quest hint?",
		config = this.config,
		key = "questHintSourceMod",
	})
	lib.createBooleanConfig({
		parent = mainPane,
		label = "Add source mod Author and Info to quest hint while Alt key is pressed?",
		config = this.config,
		key = "questHintAltSourceInfo",
	})
	lib.createBooleanConfig({
		parent = mainPane,
		label = "Open first URL found in mod Info while Ctrl+Alt keys are pressed?",
		config = this.config,
		key = "questHintCtrlAltURL",
	})
end

return this
