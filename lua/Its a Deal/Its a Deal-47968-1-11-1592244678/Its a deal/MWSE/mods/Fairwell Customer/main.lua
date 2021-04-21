local filteringGlobal = "pg_merchantvoice"
local voiceoverCategory = tes3.voiceover.flee	-- note that alarm appears to be a thing only in the CS, and not in game.
local delayRange = {0.45, 0.55}	-- in seconds

local config = mwse.loadConfig("Itsadeal")
if not config then
	config = {
		playChance = 1
	}
end

local function onInitialized()
	if not tes3.isModActive("Its a deal.ESP") then
		tes3.messageBox("Please activate Its a deal.ESP !")
	end
end
event.register("initialized", onInitialized)

local function onBarterOffer(e)
	if math.random() < config.playChance then
		if e.success then
			tes3.findGlobal(filteringGlobal).value = 1
			timer.start({ duration = math.random(delayRange[1], delayRange[2]), callback = function()
				tes3.playVoiceover({actor = e.mobile, voiceover = voiceoverCategory})
				tes3.findGlobal(filteringGlobal).value = 0
			end})
		end
	end
end
event.register("barterOffer", onBarterOffer)

--ModConfig
local modConfig = {}

function modConfig.onCreate(container)
	local pane = container:createThinBorder{}
	pane.widthProportional = 1.0
	pane.heightProportional = 1.0
	pane.paddingAllSides = 12
    pane.flowDirection = "top_to_bottom"

    local header = pane:createLabel{ text = "It's a deal\nversion 1.0" }
	header.color = tes3ui.getPalette("header_color")
	header.borderBottom = 25

	local txtBlock = pane:createBlock()
	txtBlock.widthProportional = 1.0
	txtBlock.autoHeight = true
	txtBlock.borderBottom = 25

    local txt = txtBlock:createLabel{}
	txt.widthProportional = 1.0
	txt.wrapText = true
    txt.text = "Adds original and new voice lines after a successful trade. \n\nCreated by Von Djangos and Petethegoat."

	local chanceBlock = pane:createBlock()
	chanceBlock.flowDirection = "left_to_right"
    chanceBlock.layoutWidthFraction = 1.0
	chanceBlock.height = 32
	chanceBlock.borderTop = 4

	local chanceLabel = chanceBlock:createLabel({ text = string.format("Voiceline Play Chance: %.f%%", config.playChance * 100) })

	local chanceSlider = chanceBlock:createSlider({ current = config.playChance * 100, max = 100, step = 1})
	chanceSlider.width = 256
	chanceSlider.layoutOriginFractionX = 1.0
	chanceSlider.borderRight = 6
	chanceSlider:register("PartScrollBar_changed", function(e)
		config.playChance = (chanceSlider:getPropertyInt("PartScrollBar_current")) * 0.01
		chanceLabel.text = string.format("Voiceline Play Chance: %.f%%", config.playChance * 100)
	end)

	local warningBlock = pane:createBlock()
	warningBlock.flowDirection = "left_to_right"
	warningBlock.widthProportional = 1.0
	warningBlock.autoHeight = true

	local warningText = warningBlock:createLabel()
	warningText.color = tes3ui.getPalette("negative_color")
	warningText.text = tes3.isModActive("Its a deal.ESP") and "" or "Please activate 'Its a deal.ESP'!"

    pane:updateLayout()
end

function modConfig.onClose()
	mwse.saveConfig("Itsadeal", config)
end

local function registerModConfig()
	mwse.registerModConfig("It's a deal", modConfig)
end
event.register("modConfigReady", registerModConfig)