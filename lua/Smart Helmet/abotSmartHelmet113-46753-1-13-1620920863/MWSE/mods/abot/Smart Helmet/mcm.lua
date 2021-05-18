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
		label = "Automatically swap player helmet on cell change depending on hostiles distance?",
		config = this.config,
		key = "autoSwapHostiles",
	})
	createSliderConfig({
		parent = mainPane,
		label = "Min actor AI Fight setting to be judged hostile:",
		config = this.config,
		key = "minActorAiFightTrigger",
		min = 78, max = 100, step = 1, jump = 5,
		info = ' (effective only when "Automatically swap player helmet" option is Yes)',
	})
	createSliderConfig({
		parent = mainPane,
		label = "Max distance of hostile actor from player to trigger helmet equipping:",
		config = this.config,
		key = "maxHostileDistanceTrigger",
		min = 1000, max = 7000, step = 1, jump = 100,
		info = ' (effective only when "Automatically swap player helmet" option is Yes)',
	})
	createBooleanConfig({
		parent = mainPane,
		label = "Allow automatic helmet swapping according to weather?",
		config = this.config,
		key = "autoSwapWeather",
	})
	createBooleanConfig({
		parent = mainPane,
		label = "Allow automatic swapping of enchanted helmets?",
		config = this.config,
		key = "autoSwapEnchanted",
	})
	createBooleanConfig({
		parent = mainPane,
		label = "Automatically equip any enchanted vision helmet in the dark?",
		config = this.config,
		key = "autoSwapLight",
		info = " (effective only when previous option is Yes)",
	})
	createSliderConfig({
		parent = mainPane,
		label = "Light threshold to consider an interior dark:",
		config = this.config,
		key = "lightThreshold",
		min = 1, max = 30, step = 1, jump = 5,
		info = " (effective only when previous option is Yes)",
	})
	createSliderConfig({
		parent = mainPane,
		label = "Logging level (0 = None, 1 = some, 2 = verbose):",
		config = this.config,
		key = "logLevel",
		min = 0, max = 2, step = 1, jump = 1,
		info = " useful for debugging",
	})
end

return this