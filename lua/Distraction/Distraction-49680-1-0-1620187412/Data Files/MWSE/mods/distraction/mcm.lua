local EasyMCM = include("easyMCM.EasyMCM")

-- Create a placeholder page if EasyMCM is not installed.
if (EasyMCM == nil) or (EasyMCM.version < 1.4) then
    local function placeholderMCM(element)
        element:createLabel{text="This mod config menu requires EasyMCM v1.4 or later."}
        local link = element:createTextSelect{text="Go to EasyMCM Nexus Page"}
        link.color = tes3ui.getPalette("link_color")
        link.widget.idle = tes3ui.getPalette("link_color")
        link.widget.over = tes3ui.getPalette("link_over_color")
        link.widget.pressed = tes3ui.getPalette("link_pressed_color")
        link:register("mouseClick", function()
            os.execute("start https://www.nexusmods.com/morrowind/mods/46427?tab=files")
        end)
    end
    mwse.registerModConfig("distraction", {onCreate=placeholderMCM})
    return
end

local config = require("distraction.config")

----------------------
-- EasyMCM Template --
----------------------
local template = EasyMCM.createTemplate{name="Distraction"}
template:saveOnClose("distraction", config)
template:register()

-- Preferences Page
local preferences = template:createSideBarPage{label="Preferences"}
preferences.sidebar:createInfo{text="Distraction 1.0"}

-- Sidebar Credits
local credits = preferences.sidebar:createCategory{label="Credits:"}
credits:createHyperlink{
    text = "mort - Creator scripter etc",
    exec = "start https://www.nexusmods.com/morrowind/users/4138441?tab=user+files",
}

-- Feature Toggles
local toggles = preferences:createCategory{label="Adjustables"}
toggles:createOnOffButton{
    label = "Enable Distraction",
    description = "Enable distraction functionality\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "modEnabled",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Distractions reset on cell change",
    description = "Reset the number of times an NPC is distracted when you change cells. If off, NPCs have a permanent cap to their distraction number.\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "cellChangeReset",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Enable NPC Voice Lines",
    description = "Play NPC voice clips when they get distracted\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "playNPCSounds",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Beta - Enable NPC Voice Lines when they return",
    description = "Very few voice lines of this kind were recorded, so only relevant on certain race/sex combos.\n\nDefault: Off\n\n",
    variable = EasyMCM:createTableVariable{
        id = "playNPCReturnSounds",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Enable Sound Spell Distraction",
    description = "Allow spells with the Sound Magic Effect to distract NPCs\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "soundMagicEnabled",
        table = config,
    },
}
toggles:createSlider{
    label = "Maximum distance NPCs will react to distractions",
	min=100,
	max=2000,
	jump=100,
	description = "Default: 600",
    variable = EasyMCM:createTableVariable{
        id = "strikeDistance",
        table = config,
    },
}
toggles:createSlider{
    label = "Distract Count Limit",
	min=1,
	max=10,
	jump=1,
	description = "Maximum number of times you can distract NPCs before they stop noticing\n\nDefault: 2",
    variable = EasyMCM:createTableVariable{
        id = "distractCountLimit",
        table = config,
    },
}
toggles:createSlider{
    label = "Distraction Time",
	min=2,
	max=20,
	jump=1,
	description = "How long NPCs are distracted before they reset\n\nDefault: 8",
    variable = EasyMCM:createTableVariable{
        id = "distractTime",
        table = config,
    },
}
toggles:createSlider{
    label = "Max distance for Sound Spells",
	min=500,
	max=2000,
	jump=100,
	description = "Average magnitude*50 = Distract distance, capped by this number\n\nDefault: 1200",
    variable = EasyMCM:createTableVariable{
        id = "soundMagicDistanceMax",
        table = config,
    },
}