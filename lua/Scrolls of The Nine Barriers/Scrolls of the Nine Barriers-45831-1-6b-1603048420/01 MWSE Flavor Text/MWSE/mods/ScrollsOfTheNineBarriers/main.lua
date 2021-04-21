--[[
    Mod: Scrolls of the Nine Barriers
	Author: Melchior Dahrk
--]]

local config = json.loadfile("config/ScrollsOfTheNineBarriers_Config")
if (not config) then
	config = {
		loreRequirement = true,

	}
end

local loreTable = {

["sc_firstbarrier"] = { 
	identifiedText = "\"The Scrolls of the Nine Barriers draw on the fundamental boundaries which influence the interactions between everything in the Aurbis. The First Barrier is between Matter and Man.\" - Gosleigh Horlington, Psijic",
	unidentifiedText = "B THE POWER OF THE FIRST BARRIER BETWEEN MATTER AND MAN I DEFEND AGAINST M ENEMIES"
	},
["sc_secondbarrier"] = {
	identifiedText = "\"The Scrolls of the Nine Barriers draw on the fundamental boundaries which influence the interactions between everything in the Aurbis. The Second Barrier is between Matter and Mundus.\" - Gosleigh Horlington, Psijic",
	unidentifiedText = "B THE POWER OF THE SECOND BARRIER BETWEEN MATTER AND MUNDUS I DEFEND AGAINST M ENEMIES"
	},
["sc_thirdbarrier"] = {
	identifiedText = "\"The Scrolls of the Nine Barriers draw on the fundamental boundaries which influence the interactions between everything in the Aurbis. The Third Barrier is between Man and Mundus.\" - Gosleigh Horlington, Psijic",
	unidentifiedText = "B THE POWER OF THE THIRD BARRIER BETWEEN MAN AND MUNDUS I DEFEND AGAINST M ENEMIES"
	},
["sc_fourthbarrier"] = {
	identifiedText = "\"The Scrolls of the Nine Barriers draw on the fundamental boundaries which influence the interactions between everything in the Aurbis. The Fourth Barrier is between Man and Oblivion.\" - Gosleigh Horlington, Psijic",
	unidentifiedText = "B THE POWER OF THE FOURTH BARRIER BETWEEN MAN AND OBLIVION I DEFEND AGAINST M ENEMIES"
	},
["sc_fifthbarrier"] = {
	identifiedText = "\"The Scrolls of the Nine Barriers draw on the fundamental boundaries which influence the interactions between everything in the Aurbis. The Fifth Barrier is between Man and Aetherius.\" - Gosleigh Horlington, Psijic",
	unidentifiedText = "B THE POWER OF THE FIFTH BARRIER BETWEEN MAN AND AETHERIUS I DEFEND AGAINST M ENEMIES"
	},
["sc_sixthbarrier"] = {
	identifiedText = "\"The Scrolls of the Nine Barriers draw on the fundamental boundaries which influence the interactions between everything in the Aurbis. The Sixth Barrier is between Mundus and Oblivion.\" - Gosleigh Horlington, Psijic",
	unidentifiedText = "B THE POWER OF THE SIXTH BARRIER BETWEEN MUNDUS AND OBLIVION I DEFEND AGAINST M ENEMIES"
	},
["sc_seventhbarrier"] = {
	identifiedText = "\"The Scrolls of the Nine Barriers draw on the fundamental boundaries which influence the interactions between everything in the Aurbis. The Seventh Barrier is between Mundus and Aetherius.\" - Gosleigh Horlington, Psijic",
	unidentifiedText = "B THE POWER OF THE SEVENTH BARRIER BETWEEN MUNDUS AND AETHERIUS I DEFEND AGAINST M ENEMIES"
	},
["sc_eighthbarrier"] = {
	identifiedText = "\"The Scrolls of the Nine Barriers draw on the fundamental boundaries which influence the interactions between everything in the Aurbis. The Eighth Barrier is between Oblivion and Aetherius.\" - Gosleigh Horlington, Psijic",
	unidentifiedText = "B THE POWER OF THE EIGHTH BARRIER BETWEEN OBLIVION AND AETHERIUS I DEFEND AGAINST M ENEMIES"
	},
["sc_ninthbarrier"] = {
	identifiedText = "\"The Scrolls of the Nine Barriers draw on the fundamental boundaries which influence the interactions between everything in the Aurbis. Unlike the others which I have experimentally confirmed, the Ninth Barrier remains theoretical. I model it between the Aurbis and the Void.\" - Gosleigh Horlington, Psijic",
	unidentifiedText = "THE NINTH BARRIER CANNOT EIST"
	}

}
local function loreTooltip(e)
    local loreForObject = loreTable[e.object.id]
    if loreForObject then
        -- Create a container for the lore text. TODO: Can these just be added to the label directly?
        local loreBlock = e.tooltip:createBlock{}
        loreBlock.minWidth = 1
        loreBlock.maxWidth = 440
        loreBlock.autoWidth = true
        loreBlock.autoHeight = true
        loreBlock.paddingAllSides = 6
        
        -- Create the label where our text will live.
        local loreLabel = loreBlock:createLabel{}
        loreLabel.color = tes3ui.getPalette("count_color")
        loreLabel.wrapText = true
		
		-- Configuration
        
        -- Assign the text/font to the label.
        if tes3.mobilePlayer.intelligence.current < 50 and tes3.getGlobal("md_barrier_lore") < 1 and config.loreRequirement == true then
			loreLabel.font = 2
            loreLabel.text = loreForObject.unidentifiedText
        else
            loreLabel.text = loreForObject.identifiedText
        end
    end
end

local function initialized(e)
        event.register("uiObjectTooltip", loreTooltip)

        print("Initialized ScrollsOfTheNineBarriers")
    end

event.register("initialized", initialized)

-- 
-- Handle mod config menu.
-- 

-- Package to send to the mod config.
local modConfig = {}

-- Callback for our button that binds to config.loreRequirement
local function modConfigToggleConfirm(e)
	-- Update our config.
	config.loreRequirement = not config.loreRequirement

	-- Update button text to the new value.
	local button = e.source
	button.text = config.loreRequirement and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value
	button.visible = false
	button.visible = true
end

-- Callback for when the mod config creates our UI. We specify this if we want to manually control
-- the look and functionality of our config, rather than leaving the logic entirely up to the mod
-- config system.
function modConfig.onCreate(container)
	local mainBlock = container:createThinBorder({})
	mainBlock.layoutWidthFraction = 1.0
	mainBlock.layoutHeightFraction = 1.0
	mainBlock.paddingAllSides = 6
	mainBlock.flowDirection = "top_to_bottom"
	
	local headerText = mainBlock:createLabel{ text = "Scrolls of the Nine Barriers" }
	headerText.color = tes3ui.getPalette("header_color")
	headerText.borderLeft = 12
	headerText.borderTop = 12
	
	local subText = mainBlock:createLabel{ text = "by Melchior Dahrk" }
	subText.borderLeft = 12
	subText.borderBottom = 12
	
	local playingText = mainBlock:createLabel{ text = "Playing the Mod :" }
	playingText.borderAllSides = 12
	
	local descriptionText = mainBlock:createLabel{ text = "Talk to someone in the Caldera, Guild of Mages about \"someone in particular\" to start the quest." }
	descriptionText.borderLeft = 36
	descriptionText.wrapText = true
	descriptionText.layoutWidthFraction = 1.0
	descriptionText.layoutHeightFraction = -1.0
	descriptionText.height = 1
	
	local optionsText = mainBlock:createLabel{ text = "Options :" }
	optionsText.borderAllSides = 12

	do
		-- The container is a scroll list. Create a row in that list that organizes elements horizontally.
		local horizontalBlock = mainBlock:createBlock({})
		horizontalBlock.flowDirection = "left_to_right"
		horizontalBlock.layoutWidthFraction = 1.0
		horizontalBlock.autoHeight = true
		
		-- The text for the config option.
		local label = horizontalBlock:createLabel({ text = "Show DAEDRIC text from scrolls unless the player has high enough INT or passes the LORE check (i.e. has initiated the quest and spoken with Minal about The Nine Barriers)." })
		label.wrapText = true
		label.borderTop = 36
		label.borderLeft = 36
		label.borderRight = 36
		label.borderBottom = 12
		label.layoutHeightFraction = -1.0
		label.layoutWidthFraction = 1.0
		label.height = 1

		-- Button that toggles the config value.
		local button = horizontalBlock:createButton({ text = (config.loreRequirement and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value) })
		button.layoutOriginFractionX = 1.0
		button.paddingTop = 3
		button:register("mouseClick", modConfigToggleConfirm)
	end
	
	local configImage = mainBlock:createImage { path = "textures/SotNB_Config_Identification.dds" }
	configImage.borderLeft = 16
	
end

-- Since we are taking control of the mod config system, we will manually handle saves. This is
-- called when the save button is clicked while configuring this mod.
function modConfig.onClose(container)
	mwse.log("ScrollsOfTheNineBarriers Saving mod configuration:")
	mwse.log(json.encode(config, { indent = true }))
	json.savefile("config/ScrollsOfTheNineBarriers_Config", config, { indent = true })
end

-- When the mod config menu is ready to start accepting registrations, register this mod.
local function registerModConfig()
	mwse.registerModConfig("Scrolls of the Nine Barriers", modConfig)
end
event.register("modConfigReady", registerModConfig)