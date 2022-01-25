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
    mwse.registerModConfig("stealth", {onCreate=placeholderMCM})
    return
end

local config = require("stealth.config")

----------------------
-- EasyMCM Template --
----------------------
local template = EasyMCM.createTemplate{name="Stealth"}
template:saveOnClose("stealth", config)
template:register()

-- Preferences Page
local preferences = template:createSideBarPage{label="Preferences"}
preferences.sidebar:createInfo{text="Stealth 1.0"}

-- Sidebar Credits
local credits = preferences.sidebar:createCategory{label="Credits:"}
credits:createHyperlink{
    text = "mort - Creator scripter etc",
    exec = "start https://www.nexusmods.com/morrowind/users/4138441?tab=user+files",
}
credits:createHyperlink{
    text = "Nullcascade - base script, MWSE",
    exec = "start https://www.nexusmods.com/morrowind/users/26153919?tab=user+files",
}

-- Feature Toggles
local toggles = preferences:createCategory{label="Adjustables"}
toggles:createOnOffButton{
    label = "Enable Stealth",
    description = "You do want to use this mod right? Oh please say yes\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "modEnabled",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "[Experimental] Enable light-based Stealth",
    description = "Light affects NPC visibility.\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "lightStealthEnabled",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Show Light Bar",
    description = "Visual indicator of light level\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "showLightBar",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Attacks made from stealth always hit",
    description = "Default: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "sneakAttack",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Adjust the sneak icon transparency",
    description = "More transparent = less stealthy\n\nNo icon = not stealthed\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "adjustSneakIcon",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Break invisibility when looting",
    description = "Activating an object will remove invisibility and force a stealth check before activation\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "invisFix",
        table = config,
    },
}
toggles:createSlider{
    label = "Sneak difficulty threshold",
	min=10,
	max=100,
	jump=10,
	description = "Lower is easier\n\nDefault: 50",
    variable = EasyMCM:createTableVariable{
        id = "sneakDifficulty",
        table = config,
    },
}
toggles:createSlider{
    label = "Sneak Skill Effectiveness Percentage",
	min=10,
	max=200,
	jump=10,
	description = "Multiplier to enemy checks if they can see you directly\n\nDefault: 100",
    variable = EasyMCM:createTableVariable{
        id = "sneakSkillMult",
        table = config,
    },
}
toggles:createSlider{
    label = "Sneak Distance Base Multiplier",
	min=10,
	max=200,
	jump=10,
	description = "Distance / distanceMult * (this as a percentage) = distance term\n\nI do not recommend messing with this\n\nDefault: 70",
    variable = EasyMCM:createTableVariable{
        id = "sneakDistanceBase",
        table = config,
    },
}
toggles:createSlider{
    label = "Sneak Distance Multiplier",
	min=100,
	max=1000,
	jump=100,
	description = "Distance / this * base = distance term\n\nI do not recommend messing with this\n\nDefault: 500",
    variable = EasyMCM:createTableVariable{
        id = "sneakDistanceMultiplier",
        table = config,
    },
}
toggles:createSlider{
    label = "View Angle",
	min=10,
	max=180,
	jump=10,
	description = "Angle where you are considered 'in sight' of NPCs\n\nDefault: 100",
    variable = EasyMCM:createTableVariable{
        id = "viewAngle",
        table = config,
    },
}
toggles:createSlider{
    label = "View Multplier",
	min=1,
	max=5,
	jump=1,
	description = "Multiplier to enemy checks if they can see you directly\n\nDefault: 3",
    variable = EasyMCM:createTableVariable{
        id = "viewMultiplier",
        table = config,
    },
}

toggles:createSlider{
    label = "No-View Multplier",
	min=10,
	max=100,
	jump=10,
	description = "Multiplier to enemy checks if they cannot see you directly\n\nDefault: 50%",
    variable = EasyMCM:createTableVariable{
        id = "noViewMultiplier",
        table = config,
    },
}
toggles:createSlider{
    label = "Boot Armor-type Multiplier",
	min=0,
	max=30,
	jump=10,
	description = "Light=0\nMedium=1\nHeavy=2\n\nMultiplied by *this* number = the stealth penalty\n0 = Off\n\nDefault: 10",
    variable = EasyMCM:createTableVariable{
        id = "bootMultiplier",
        table = config,
    },
}
toggles:createSlider{
    label = "Invisibility Stealth Bonus",
	min=0,
	max=300,
	jump=10,
	description = "Remember this does NOT guarantee stealth\n\nDefault: 30",
    variable = EasyMCM:createTableVariable{
        id = "invisibilityBonus",
        table = config,
    },
}
toggles:createSlider{
    label = "Percentage Effectiveness of Chameleon",
	min=0,
	max=200,
	jump=10,
	description = "Lessens the effect of chameleon, which is otherwise very overpowered now\n\nDefault: 50%",
    variable = EasyMCM:createTableVariable{
        id = "chameleonMultiplier",
        table = config,
    },
}
toggles:createSlider{
    label = "NPC sneak bonus",
	min=0,
	max=100,
	jump=10,
	description = "Most NPCs have very low sneak, and it is way too easy to fool them\n\nDefault: 20",
    variable = EasyMCM:createTableVariable{
        id = "npcSneakBonus",
        table = config,
    },
}