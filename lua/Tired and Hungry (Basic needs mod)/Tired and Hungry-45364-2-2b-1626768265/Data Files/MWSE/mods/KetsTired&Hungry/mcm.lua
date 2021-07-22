local this = {}

local function createConfigSliderPackage(params)
	local horizontalBlock = params.parent:createBlock({})
	horizontalBlock.flowDirection = "left_to_right"
	horizontalBlock.layoutWidthFraction = 1.0
	horizontalBlock.height = 24

	local label = horizontalBlock:createLabel({ text = params.label })
	label.layoutOriginFractionX = 0.0
	label.layoutOriginFractionY = 0.5

	local config = params.config
	local key = params.key
	local value = config[key] or params.default or 0

	local sliderLabel = horizontalBlock:createLabel({ text = tostring(value) })
	sliderLabel.layoutOriginFractionX = 1.0
	sliderLabel.layoutOriginFractionY = 0.5
	sliderLabel.borderRight = 306

	local range = params.max - params.min

	local slider = horizontalBlock:createSlider({ current = value - params.min, max = range, step = params.step, jump = params.jump })
	slider.layoutOriginFractionX = 1.0
	slider.layoutOriginFractionY = 0.5
	slider.width = 300
	slider:register("PartScrollBar_changed", function(e)
		config[key] = slider:getPropertyInt("PartScrollBar_current") + params.min
		sliderLabel.text = config[key]
		if (params.onUpdate) then
			params.onUpdate(e)
		end
	end)

	if (params.tooltip) then
		local tooltipType = type(params.tooltip)
		if (tooltipType == "string") then
			slider:register("help", function(e)
				local tooltipMenu = tes3ui.createTooltipMenu()
				local tooltipText = tooltipMenu:createLabel({ text = params.tooltip })
				tooltipText.wrapText = true
			end)
		elseif (tooltipType == "function") then
			slider:register("help", params.tooltip)
		end
	end

	return { block = horizontalBlock, label = label, sliderLabel = sliderLabel, slider = slider }
end

local function createBooleanConfigPackage(params)
	local horizontalBlock = params.parent:createBlock({})
	horizontalBlock.flowDirection = "left_to_right"
	horizontalBlock.layoutWidthFraction = 1.0
	horizontalBlock.height = 24

	local label = horizontalBlock:createLabel({ text = params.label })
	label.layoutOriginFractionX = 0.0
	label.layoutOriginFractionY = 0.5

	local button = horizontalBlock:createButton({ text = (this.config[params.key] and tes3.getGMST(tes3.gmst.sYes).value or tes3.getGMST(tes3.gmst.sNo).value) })
	button.layoutOriginFractionX = 1.0
	button.layoutOriginFractionY = 0.5
	button.paddingTop = 3
	button:register("mouseClick", function(e)
		this.config[params.key] = not this.config[params.key]
		button.text = this.config[params.key] and tes3.getGMST(tes3.gmst.sYes).value or tes3.getGMST(tes3.gmst.sNo).value

		if (params.onUpdate) then
			params.onUpdate(e)
		end
	end)

	if (params.tooltip) then
		local tooltipType = type(params.tooltip)
		if (tooltipType == "string") then
			button:register("help", function(e)
				local tooltipMenu = tes3ui.createTooltipMenu()
				local tooltipText = tooltipMenu:createLabel({ text = params.tooltip })
				tooltipText.wrapText = true
			end)
		elseif (tooltipType == "function") then
			button:register("help", params.tooltip)
		end
	end

	return { block = horizontalBlock, label = label, button = button }
end

function this.onCreate(container)
	-- Create the main pane for a uniform look.
	local mainPane = container:createThinBorder({})
	mainPane.flowDirection = "top_to_bottom"
	mainPane.layoutHeightFraction = 1.0
	mainPane.layoutWidthFraction = 1.0
	mainPane.paddingAllSides = 6

	createConfigSliderPackage({
		parent = mainPane,
		label = "Food units per meal:",
		config = this.config,
		key = "minFood",
		min = 1,
		max = 5,
		step = 1,
		jump = 1,
		tooltip = "Average amount of food items your character has to use to remove the lowest hunger level.\n\nDefault: 3",
	})

	createConfigSliderPackage({
		parent = mainPane,
		label = "Sleep hours per rest:",
		config = this.config,
		key = "minSleep",
		min = 1,
		max = 12,
		step = 1,
		jump = 1,
		tooltip = "Average amount of hours your character has to sleep to remove the lowest tiredness level.\n\nDefault: 8",
	})

		createBooleanConfigPackage({
		parent = mainPane,
		label = "No vagrancy:",
		config = this.config,
		key = "noVagrancy",
		tooltip = "Defines if your will't get less tired while sleeping outdoors.\n\nDefault: Yes",
	})

		createBooleanConfigPackage({
		parent = mainPane,
		label = "No hunger or tiredness during travel:",
		config = this.config,
		key = "travel",
		tooltip = "Defines if your character won't get hungry or tired during travel.\n\nDefault: No",
	})
end

function this.onClose(container)
	mwse.saveConfig("Ket's Tired and Hungry", this.config)
end

return this
