local config = mwse.loadConfig("Illiterate")
if not config then
	config = {
		intThreshold = 25,
		useBaseAttribute = true,
		everythingIsDaedric = false,
		disableSkillIncrease = true,
	}
end

local function literacyCheck(forceCheck)
	forceCheck = forceCheck or false
	if not forceCheck and config.everythingIsDaedric then
		return false
	end

	if config.useBaseAttribute then
		if tes3.mobilePlayer.intelligence.base <= config.intThreshold then
			return false
		end
	else
		if tes3.mobilePlayer.intelligence.current <= config.intThreshold then
			return false
		end
	end

	return true
end

local ignoreBookTextEvent = false

local function onGetBookText(e)
    if ignoreBookTextEvent then
        return
    end

    if not literacyCheck() then
        -- Get the original text, but bypass this event.
        ignoreBookTextEvent = true
        local originalText = e.book.text
        ignoreBookTextEvent = false

		-- Replace magic cards fonts with daedric ones.
		if not originalText:find("=\"Magic Cards\"") then
			e.text = "<FACE=\"Daedric\">" .. originalText .. "</font>"
		else
			e.text = originalText:gsub("=\"Magic Cards\"", "=\"Daedric\"")
		end
    end
end
event.register("bookGetText", onGetBookText)

local function onActivateBook(e)
	if config.disableSkillIncrease then
		if e.activator == tes3.player then
			if e.target.object.objectType == tes3.objectType.book then
				if not literacyCheck(true) then
					local bookSkill = e.target.object.skill
					e.target.object.skill = -1
					timer.delayOneFrame(function()
						e.target.object.skill = bookSkill
					end)
				end
			end
		end
	end
end
event.register("activate", onActivateBook)

-- Mod Config Menu
local modConfig = {}

function modConfig.onCreate(container)
	local mainBlock = container:createThinBorder({})
	mainBlock.layoutWidthFraction = 1.0
	mainBlock.layoutHeightFraction = 1.0
	mainBlock.paddingAllSides = 6
	mainBlock.flowDirection = "top_to_bottom"


    local header = mainBlock:createLabel{ text = "Illiterate\nversion 1.2" }
	header.color = tes3ui.getPalette("header_color")
    header.borderBottom = 25

	local txtBlock = mainBlock:createBlock()
	txtBlock.widthProportional = 1.0
	txtBlock.autoHeight = true
	txtBlock.borderBottom = 25
    txtBlock:createLabel{ text = "Created by NullCascade & Petethegoat." }


	do
		local scaleBlock = mainBlock:createBlock()
		scaleBlock.flowDirection = "left_to_right"
		scaleBlock.layoutWidthFraction = 1.0
		scaleBlock.height = 32

		local scaleLabel = scaleBlock:createLabel({ text = string.format("Intelligence Threshold: %d", config.intThreshold) })

		local scaleSlider = scaleBlock:createSlider({ current = (config.intThreshold), max = 100, step = 1})
		scaleSlider.width = 256
		scaleSlider.layoutOriginFractionX = 1.0
		scaleSlider.borderRight = 6
		scaleSlider:register("PartScrollBar_changed", function(e)
			config.intThreshold = (scaleSlider:getPropertyInt("PartScrollBar_current"))
			scaleLabel.text = string.format("Intelligence Threshold: %d", config.intThreshold)
		end)
	end

	do
		local horizontalBlock = mainBlock:createBlock({})
		horizontalBlock.flowDirection = "left_to_right"
		horizontalBlock.layoutWidthFraction = 1.0
		horizontalBlock.autoHeight = true

		local label = horizontalBlock:createLabel({ text = "Use Base or Current Intelligence?" })
		label.layoutOriginFractionX = 0.0

		local button = horizontalBlock:createButton({ text = (config.useBaseAttribute and "Base" or "Current") })
		button.layoutOriginFractionX = 1.0
		button.paddingTop = 3
		button:register("mouseClick", function()
			config.useBaseAttribute = not config.useBaseAttribute
			button.text = (config.useBaseAttribute and "Base" or "Current")
		end)
	end

	do
		local horizontalBlock = mainBlock:createBlock({})
		horizontalBlock.flowDirection = "left_to_right"
		horizontalBlock.layoutWidthFraction = 1.0
		horizontalBlock.autoHeight = true

		local label = horizontalBlock:createLabel({ text = "Disable Skill Increase?" })
		label.layoutOriginFractionX = 0.0

		local button = horizontalBlock:createButton({ text = (config.disableSkillIncrease and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value) })
		button.layoutOriginFractionX = 1.0
		button.paddingTop = 3
		button:register("mouseClick", function()
			config.disableSkillIncrease = not config.disableSkillIncrease
			button.text = config.disableSkillIncrease and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value
		end)
	end

	do
		local horizontalBlock = mainBlock:createBlock({})
		horizontalBlock.flowDirection = "left_to_right"
		horizontalBlock.layoutWidthFraction = 1.0
		horizontalBlock.autoHeight = true

		local label = horizontalBlock:createLabel({ text = "Just make everything always daedric?" })
		label.layoutOriginFractionX = 0.0

		local button = horizontalBlock:createButton({ text = (config.everythingIsDaedric and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value) })
		button.layoutOriginFractionX = 1.0
		button.paddingTop = 3
		button:register("mouseClick", function()
			config.everythingIsDaedric = not config.everythingIsDaedric
			button.text = config.everythingIsDaedric and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value
		end)
	end
end

function modConfig.onClose(container)
	mwse.log(json.encode(config, { indent = true }))
	mwse.saveConfig("Illiterate", config)
end

local function registerModConfig()
	mwse.registerModConfig("Illiterate", modConfig)
end
event.register("modConfigReady", registerModConfig)