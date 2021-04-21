--[[
	Character Creation Name Generator
	By Aleist3r

	TODO:
		a fuckton of stuff, mainly code optimization, probably ;]
--]]

local common = {}
local doOnce = 0

common.version = 1.0

local defaultConfig = {
	version = common.version,
	components = {
		enableGenerator = true
	},
}

local config = table.copy(defaultConfig)

local function loadConfig()
	config = {}

	table.copy(defaultConfig, config)

	local configJson = mwse.loadConfig("Character Creation Name Generator")
	if (configJson ~= nil) then
		if (configJson.version == nil or common.version > configJson.version) then
			configJson.components = nil
		end

		table.copy(configJson, config)
	end

	mwse.log("[Character Creation Name Generator] Loaded configuration:")
	mwse.log(json.encode(config, { indent = true }))
end
loadConfig()

local modConfig = {}

function modConfig.onCreate(container)
	local pane = container:createThinBorder{}
	pane.widthProportional = 1.0
	pane.heightProportional = 1.0
	pane.paddingAllSides = 12
    pane.flowDirection = "top_to_bottom"

	local header = pane:createLabel({ text = "Character Creation Name Generator based on tool by Aleist3r. version 1.0" })
    header.borderAllSides = 6

	local UI_toolLink = pane:createTextSelect({ text = "Just A Simple Name Generator Nexus", state = 1 })
		UI_toolLink.widget.idle = tes3ui.getPalette("magic_color")
		UI_toolLink.widget.over = tes3ui.getPalette("health_npc_color")
		UI_toolLink.widget.pressed = tes3ui.getPalette("health_color")
		UI_toolLink.borderAllSides = 6
		UI_toolLink:triggerEvent("mouseLeave")
		UI_toolLink:register("mouseClick", function()
			tes3.messageBox({
				message = "Open web browser?",
				buttons = { tes3.getGMST(tes3.gmst.sYes).value, tes3.getGMST(tes3.gmst.sNo).value },
				callback = function(e)
					if (e.button == 0) then
						os.execute("start https://www.nexusmods.com/morrowind/mods/45610")
					end
				end
			})
		end)

	local horizontalBlock = pane:createBlock({})
	horizontalBlock.flowDirection = "left_to_right"
	horizontalBlock.widthProportional = 1.0
	horizontalBlock.height = 32
	horizontalBlock.borderAllSides = 6

	local label = horizontalBlock:createLabel({ text = "Enable name generator:" })
	label.absolutePosAlignX = 0.0
	label.absolutePosAlignY = 0.5

	local button = horizontalBlock:createButton({ text = config.components.enableGenerator and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value })
	button.absolutePosAlignX = 1.0
	button.absolutePosAlignY = 0.5
	button.paddingTop = 3
	button:register("mouseClick", function(e)
		config.components.enableGenerator = not config.components.enableGenerator
		button.text = config.components.enableGenerator and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value
	end)

	local UI_textInfo = pane:createLabel({ text = "You need to restart game to apply changes."})
	UI_textInfo.borderAllSides = 6
	UI_textInfo.color = tes3ui.getPalette("health_color")

	local credits = pane:createLabel({ text = "Credits:" })
	credits.color = tes3ui.getPalette("header_color")
	credits.borderLeft = 6
	credits.borderRight = 6
	credits.borderTop = 6

	local UI_coding = pane:createLabel({ text = "Coding: Aleist3r"})
	UI_coding.borderLeft = 6
	UI_coding.borderRight = 6

	local UI_Help = pane:createLabel({ text = "Various help: Greatness7, NullCascade, Merlord"})
	UI_Help.borderLeft = 6
	UI_Help.borderRight = 6

    pane:updateLayout()
end

function modConfig.onClose(container)
	mwse.saveConfig("Character Creation Name Generator", config)
end

modConfig.config = config

local function registerModConfig()
	mwse.registerModConfig("Character Creation Name Generator", modConfig)
end
event.register("modConfigReady", registerModConfig)

local function OnInitialized(e)
	if ( config.components.enableGenerator ) then
		if doOnce == 0 then
			dofile("Data Files/MWSE/mods/Aleist3r/Character Creation Name Generator/MenuNameGenerator.lua")
			mwse.log("[Character Creation Name Generator] initialized")
			doOnce = 1
		end
	else
		mwse.log("[Character Creation Name Generator] Skipping module")
	end
end
event.register("loaded", OnInitialized)