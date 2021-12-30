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

function this.onCreate(container)
	-- Create the main pane for a uniform look.
	local mainPane = container:createThinBorder({})
	mainPane.flowDirection = "top_to_bottom"
	mainPane.layoutHeightFraction = 1.0
	mainPane.layoutWidthFraction = 1.0
	mainPane.paddingAllSides = 6

	createConfigSliderPackage({
		parent = mainPane,
		label = "Maximum loan period:",
		config = this.config,
		key = "maxLoanPeriod",
		min = 14,
		max = 60,
		step = 1,
		jump = 1,
	})

	createConfigSliderPackage({
		parent = mainPane,
		label = "Interest rate (per day):",
		config = this.config,
		key = "interestRate",
		min = 0,
		max = 3,
		step = 1,
		jump = 1,
	})
end

function this.onClose(container)
	mwse.saveConfig("Loanable Funds", this.config)
end

return this
