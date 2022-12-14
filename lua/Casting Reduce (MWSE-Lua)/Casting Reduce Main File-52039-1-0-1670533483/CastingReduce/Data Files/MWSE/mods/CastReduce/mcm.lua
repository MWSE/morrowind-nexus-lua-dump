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
    mwse.registerModConfig("Casting Reduce", {onCreate=placeholderMCM})
    return
end

local config = require("castReduce.config")

----------------------
-- EasyMCM Template --
----------------------
local template = EasyMCM.createTemplate{name="Casting Reduce"}
template:saveOnClose("castReduce", config)
template:register()

-- Preferences Page
local preferences = template:createSideBarPage{label="Preferences"}
preferences.sidebar:createInfo{text="Cast Reduce v1.0"}

-- Sidebar Credits
local credits = preferences.sidebar:createCategory{label="Credits:"}
credits:createHyperlink{
    text = "Trainwiz - Scripting",
    exec = "start https://www.nexusmods.com/morrowind/users/370317",
}


-- Feature Toggles
local settings = preferences:createCategory{label="Settings"}
settings:createSlider{
	label = "Spell Reduction Amount",
	description = "Percentage per level to reduce cast by. By default, at level 100 a skill will reduce the spell cost by 50%",
	min = 0,
	max = 100,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{
		id = "spellReductionCost",
		table = config
	}
}