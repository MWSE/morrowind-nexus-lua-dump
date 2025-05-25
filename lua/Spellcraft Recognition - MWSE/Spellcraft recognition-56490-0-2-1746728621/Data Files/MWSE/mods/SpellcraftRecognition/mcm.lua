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
    mwse.registerModConfig("SpellcraftRecognition", {onCreate=placeholderMCM})
    return
end

local config = require("SpellcraftRecognition.config")


local template = EasyMCM.createTemplate{name="Spellcraft Recognition"}
template:saveOnClose("SpellcraftRecognition", config)
template:register()


local preferences = template:createSideBarPage{label="Preferences"}

-- Sidebar Credits
local compl = preferences.sidebar:createCategory{label="Complementary"}
compl:createHyperlink{
    text = "Spell chance formula",
    exec = "start https://en.uesp.net/wiki/Morrowind:Spells#Success_Chance",
}



-- Feature Toggles
local settings = preferences:createCategory{label="Settings"}
settings:createSlider{
	label = "Recognition Threshold",
	description = "Cast chance threshold for successful recognition check.",
	min = 0,
	max = 100,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{
		id = "threshold",
		table = config
	}
}