local this = {}

local function createBooleanConfigPackage(params)
	local horizontalBlock = params.parent:createBlock({})
	horizontalBlock.flowDirection = "left_to_right"
	horizontalBlock.layoutWidthFraction = 1.0
	horizontalBlock.height = 24

	local label = horizontalBlock:createLabel({ text = params.label })
	label.layoutOriginFractionX = 0.0
	label.layoutOriginFractionY = 0.5

	local button = horizontalBlock:createButton({ text = (this.config[params.key] and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value) })
	button.layoutOriginFractionX = 1.0
	button.layoutOriginFractionY = 0.5
	button.paddingTop = 3
	button:register("mouseClick", function(e)
		this.config[params.key] = not this.config[params.key]
		button.text = this.config[params.key] and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value

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

		createBooleanConfigPackage({
		parent = mainPane,
		label = "Trade restrictions enabled",
		config = this.config,
		key = "tradeEnabled",
		tooltip = "If disabled, all merchants will buy the items they buy in vanilla game.",
	})

		createBooleanConfigPackage({
		parent = mainPane,
		label = "Illegal items restricstions enabled",
		config = this.config,
		key = "contrabandEnabled",
		tooltip = "If disabled, all merchants will buy illegal items: skooma, moonsugar, dwemer artifacts, ebony and glass. Disable ESP-file to restore vanilla trade restrictions for illegal items.",
	})
end

function this.onClose(container)
	mwse.saveConfig("Lore-friendly Trade Restrictions", this.config)
end

return this
