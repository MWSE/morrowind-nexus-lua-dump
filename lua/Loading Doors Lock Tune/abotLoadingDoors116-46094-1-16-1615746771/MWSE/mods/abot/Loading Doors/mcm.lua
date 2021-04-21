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
		label = "Loading doors lock synchronization?",
		config = this.config,
		key = "doorLockTune",
		info = "(e.g. if exterior door is locked/unlocked, so is linked interior door and vice versa)",
	})
	createSliderConfig({
		parent = mainPane,
		label = "Linked doors max distance:",
		config = this.config,
		key = "linkedDoorsMaxDistance",
		min = 400, max = 800, step = 1, jump = 5,
		info = '(default: 450)',
	})
	createBooleanConfig({
		parent = mainPane,
		label = "Loading doors close sound enabled?",
		config = this.config,
		key = "doorCloseSound",
		info = " (play close door sound after opening a loading door)",
	})
	createSliderConfig({
		parent = mainPane,
		label = "Close door sound volume (%):",
		config = this.config,
		key = "doorCloseSoundVolumePercent",
		min = 20, max = 100, step = 1, jump = 10, -- NOTE: only integer parameters!
		info = '(effective only when previous "Loading doors close sound" option is set to Yes)',
	})
	createBooleanConfig({
		parent = mainPane,
		label = "Lock the door with Shift + Activate (if you have the key)?",
		config = this.config,
		key = "doorShiftLock",
	})

end

return this
