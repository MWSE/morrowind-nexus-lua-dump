--[[
    Descriptive Descriptions
--]]

local config = json.loadfile("config/rem_description_config")
if (not config) then
	config = {
		lightColor = true,

	}
end

local this = {}

local soulGemTable = {
    ["misc_soulgem_petty"] = true,
    ["misc_soulgem_lesser"] = true,
    ["misc_soulgem_common"] = true,
    ["misc_soulgem_greater"] = true,
    ["misc_soulgem_grand"] = true,
    ["misc_soulgem_azura"] = true,
}




local function extraTooltip(e)
    local speed, reach, duration, enchValue, maxDuration
    local isSoulGem = soulGemTable[e.object.id:lower()]


    if e.object.objectType == tes3.objectType.weapon then
        speed = e.object.speed
        reach = e.object.reach
        enchValue = e.object.enchantCapacity / 10

    elseif e.object.objectType == tes3.objectType.armor or e.object.objectType == tes3.objectType.clothing then
        enchValue = e.object.enchantCapacity / 10

    elseif e.object.objectType == tes3.objectType.light then

		maxDuration = e.object.time

        if e.itemData or e.reference then
            duration = e.object:getTimeLeft(e.itemData or e.reference)
        else
            duration = e.object.time
        end
    end


    if e.object.objectType == tes3.objectType.weapon then
        local textSpeed = string.format("Speed: %.2f", speed)
        local textReach = string.format("Reach: %.2f", reach)

        local blockSpeed = e.tooltip:createBlock()
        blockSpeed.minWidth = 1
        blockSpeed.maxWidth = 210
        blockSpeed.autoWidth = true
        blockSpeed.autoHeight = true
        local labelSpeed = blockSpeed:createLabel{text = textSpeed}
        labelSpeed.wrapText = true

        local blockReach = e.tooltip:createBlock()
        blockReach.minWidth = 1
        blockReach.maxWidth = 210
        blockReach.autoWidth = true
        blockReach.autoHeight = true
        local labelReach = blockReach:createLabel{text = textReach}
        labelReach.wrapText = true

		if e.object.enchantment == nil then

        local textEnch = string.format("Capacity: %u", enchValue)

        local blockEnch = e.tooltip:createBlock()
        blockEnch.minWidth = 1
        blockEnch.maxWidth = 210
        blockEnch.autoWidth = true
        blockEnch.autoHeight = true
        local labelEnch = blockEnch:createLabel{text = textEnch}
        labelEnch.wrapText = true
		end

        elseif e.object.objectType == tes3.objectType.armor or e.object.objectType == tes3.objectType.clothing then

		if e.object.enchantment == nil then

        local textEnch = string.format("Capacity: %u", enchValue)

        local blockEnch = e.tooltip:createBlock()
        blockEnch.minWidth = 1
        blockEnch.maxWidth = 210
        blockEnch.autoWidth = true
        blockEnch.autoHeight = true
        local labelEnch = blockEnch:createLabel{text = textEnch}
        labelEnch.wrapText = true
		end
    elseif e.object.objectType == tes3.objectType.light then


		local textDuration = string.format("Duration:    ")
		local blockDurationBar = e.tooltip:createBlock()
		blockDurationBar.autoWidth = true
        blockDurationBar.autoHeight = true
		blockDurationBar.paddingAllSides = 10
		local labelDuration = blockDurationBar:createLabel{text = textDuration}
        local labelDurationBar = blockDurationBar:createFillBar {current = duration, max = maxDuration}
		if config.lightColor then
		labelDurationBar.widget.fillColor = tes3ui.getPalette("normal_color")
		end

    elseif isSoulGem == true then
        local soulValue = tes3.getGMST("fSoulGemMult").value * e.object.value
        local textSoulSize = string.format("Soul Capacity: %u", soulValue)

        local blockSoulSize = e.tooltip:createBlock()
        blockSoulSize.minWidth = 1
        blockSoulSize.maxWidth = 210
        blockSoulSize.autoWidth = true
        blockSoulSize.autoHeight = true
        local labelSoulSize = blockSoulSize:createLabel{text = textSoulSize}
        labelSoulSize.wrapText = true
    end
end



local function initialized(e)
    event.register("uiObjectTooltip", extraTooltip)
    print("Initialized DescriptiveDescriptions v0.00")
end

event.register("initialized", initialized)

--[[MOD CONFIG MENU]]--

local modConfig = {}
function modConfig.onCreate(container)

	local descriptionLabel = {}--global scope so we can update the description in click events

	local function getYesNoText (b)
		return b and tes3.getGMST(tes3.gmst.sYes).value or tes3.getGMST(tes3.gmst.sNo).value
	end

	local function toggleLightColor(e)
		config.lightColor = not config.lightColor
		local button = e.source
		button.text = getYesNoText(config.lightColor)
		descriptionLabel.text = config.lightColor and
			"Unique color for light duration bars."
			or
			"Generic color for light duration bars."
	end


	do
		local optionBlock = container:createThinBorder({})
		optionBlock.layoutWidthFraction = 1.0
		optionBlock.flowDirection = "top_to_bottom"
		optionBlock.autoHeight = true
		optionBlock.paddingAllSides = 10


		local function makeButton(parentBlock, labelText, buttonText, callBack)
			local buttonBlock
			buttonBlock = parentBlock:createBlock({})
			buttonBlock.flowDirection = "left_to_right"
			buttonBlock.layoutWidthFraction = 1.0
			buttonBlock.autoHeight = true

			local label = buttonBlock:createLabel({ text = labelText })
			label.layoutOriginFractionX = 0.0

			local button = buttonBlock:createButton({ text = buttonText })
			button.layoutOriginFractionX = 1.0
			button.paddingTop = 3
			button:register("mouseClick", callBack)
		end
		local buttonText = getYesNoText(config.lightColor)
		makeButton(optionBlock, "Unique colors for light duration bars?", buttonText, toggleLightColor)


		--Description pane
		local descriptionBlock = container:createThinBorder({})
		descriptionBlock.layoutWidthFraction = 1.0
		descriptionBlock.paddingAllSides = 10
		descriptionBlock.layoutHeightFraction = 1.0
		descriptionBlock.flowDirection = "top_to_bottom"

		--Do description first so it can be updated by buttons
		descriptionLabel = descriptionBlock:createLabel({ text =
			"Descriptive Descriptions is a mod that adds several new tooltips . " ..
			"It adds hidden stats like speed, reach, enchantment value, soul capacity for soul gems and duration for light source. "
		})
		descriptionLabel.layoutWidthFraction = 1.0
		descriptionLabel.wrapText = true

	end
end

function modConfig.onClose(container)
	json.savefile("config/rem_descriptions_config", config, { indent = true })
end

-- When the mod config menu is ready to start accepting registrations, register this mod.
local function registerModConfig()
	mwse.registerModConfig("Descriptive Descriptions", modConfig)
	end
event.register("modConfigReady", registerModConfig)
