local this = {}

this.config = {}

-- MCM functions, a lot stolen from Nullcascade's examples
local function createBooleanConfig(params)
	local sYes = tes3.findGMST(tes3.gmst.sYes).value
	local sNo = tes3.findGMST(tes3.gmst.sNo).value

	local block = params.parent:createBlock({})
	--block.flowDirection = "left_to_right"
	block.layoutWidthFraction = 1.0
	block.height = 48
	block.childAlignY = 0.5 -- Y centered
	block.paddingAllSides = 4

	local label = block:createLabel({text = params.label})

	local button = block:createButton({text = (params.config[params.key] and sYes or sNo)})
	button.borderTop = 7
	button:register(
		'mouseClick',
		function(e)
			params.config[params.key] = not params.config[params.key]
			button.text = params.config[params.key] and sYes or sNo
			if (params.onUpdate) then
				params.onUpdate(e)
			end
		end
	)
	local info = block:createLabel({text = params.info or ''})

	return {block = block, label = label, button = button, info = info}
end

local function createSliderConfig(params)
	local block = params.parent:createBlock({})
	block.flowDirection = 'top_to_bottom'
	block.layoutWidthFraction = 1.0
	block.height = 80
	block.childAlignY = 0.5 -- Y centered
	block.paddingAllSides = 4

	local config = params.config
	local key = params.key
	local value = config[key] or params.default or 0

	local label = block:createLabel({text = params.label})

	local sliderLabel = block:createLabel({text = tostring(value)})

	local range = params.max - params.min

	-- NOTE: only integer parameters!
	local slider = block:createSlider({current = value - params.min, max = range, step = params.step, jump = params.jump})
	slider.width = 400
	slider:register(
		'PartScrollBar_changed',
		function(e)
			config[key] = slider:getPropertyInt('PartScrollBar_current') + params.min
			sliderLabel.text = config[key]
			if (params.onUpdate) then
				params.onUpdate(e)
			end
		end
	)
	local info = block:createLabel({text = params.info or ''})

	return {block = block, label = label, sliderLabel = sliderLabel, slider = slider, info = info}
end

--[[
local function createLabelConfig(params)
	local block = params.parent:createBlock({})
	block.flowDirection = 'top_to_bottom'
	block.paddingAllSides = 4
	block.layoutWidthFraction = 1.0
	block.height = 48
	local label = block:createLabel({text = params.label})
	return {block = block, label = label}
end
--]]

local function createMainPane(container)
	-- Create the main pane for a uniform look.
	local mainPane = container:createThinBorder({})
	mainPane.flowDirection = 'top_to_bottom'
	mainPane.layoutHeightFraction = 1.0
	mainPane.layoutWidthFraction = 1.0
	mainPane.paddingAllSides = 6
	mainPane.widthProportional = 1.0
	mainPane.heightProportional = 1.0
	return mainPane
end

function this.onCreate(container)
	local mainPane = createMainPane(container)
	createBooleanConfig({
		parent = mainPane,
		label = "Clear topics with no entries yet from the journal?",
		config = this.config,
		key = "clearTopicsWithNoEntries",
	})
	createBooleanConfig({
		parent = mainPane,
		label = "Collapse journal paragraphs having the same date header?",
		config = this.config,
		key = "collapseDates",
	})
	createBooleanConfig({
		parent = mainPane,
		label = "Skip links contained inside journal words?",
		config = this.config,
		key = "skipLinksInsideWords",
	})
	createSliderConfig({
		parent = mainPane,
		label = "Add a prefix in order to group quest names?",
		config = this.config,
		key = "questPrefix",
		min = 0, max = 3, step = 1, jump = 1,
		info = '(0 = No, 1 = source mod loading index, 2 = source mod condensed name, 3 = quest id)',
	})
	createBooleanConfig({
		parent = mainPane,
		label = "Sort quests list by quest name? (better to enable it when adding a prefix)",
		config = this.config,
		key = "questSort",
	})
	createBooleanConfig({
		parent = mainPane,
		label = "Add quest id to quest hint?",
		config = this.config,
		key = "questHintQuestId",
	})
	createBooleanConfig({
		parent = mainPane,
		label = "Add source mod name to quest hint?",
		config = this.config,
		key = "questHintSourceMod",
	})
	createBooleanConfig({
		parent = mainPane,
		label = "Add source mod Author and Info to quest hint while Alt key is pressed?",
		config = this.config,
		key = "questHintAltSourceInfo",
	})
	createBooleanConfig({
		parent = mainPane,
		label = "Open first URL found in mod Info while Ctrl+Alt keys are pressed?",
		config = this.config,
		key = "questHintCtrlAltURL",
	})
end

return this
