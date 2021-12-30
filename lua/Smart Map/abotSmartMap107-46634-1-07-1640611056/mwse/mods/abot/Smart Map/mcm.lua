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
		label = "Switch to local map when entering interior cells?",
		config = this.config,
		key = "onEnteringInteriors",
	})
	createBooleanConfig({
		parent = mainPane,
		label = "Allow map switching when crossing exterior cells?",
		config = this.config,
		key = "onCrossingExteriors",
	})
	createSliderConfig({
		parent = mainPane,
		label = "Minimum number of linked doors found in exterior cell to automatically switch to local map:",
		config = this.config,
		key = "minExteriorCellLinkedDoorsForLocalMap",
		min = 1, max = 50, step = 1, jump = 5,
		info = '(effective only when previous "Allow map switching when crossing exterior cells" option is set to Yes)',
	})
	createBooleanConfig({
		parent = mainPane,
		label = "Switch to local map in hostile areas?",
		config = this.config,
		key = "localMapWithHostiles",
	})

	createSliderConfig({
		parent = mainPane,
		label = "Min actor AI Fight setting to be judged hostile:",
		config = this.config,
		key = "minActorAiFightTrigger",
		min = 78, max = 100, step = 1, jump = 5,
		info = ' (effective only when "Switch to local map in hostile areas" option is Yes)',
	})
	createSliderConfig({
		parent = mainPane,
		label = "Max distance of hostile actor from player to detect hostility:",
		config = this.config,
		key = "maxHostileDistanceTrigger",
		min = 1000, max = 7000, step = 1, jump = 100,
		info = ' (effective only when "Switch to local map in hostile areas" option is Yes)',
	})

	createBooleanConfig({
		parent = mainPane,
		label = "Replace TR Preview temporary cell name on map header?",
		config = this.config,
		key = "fixTRpreview",
	})

end

return this
