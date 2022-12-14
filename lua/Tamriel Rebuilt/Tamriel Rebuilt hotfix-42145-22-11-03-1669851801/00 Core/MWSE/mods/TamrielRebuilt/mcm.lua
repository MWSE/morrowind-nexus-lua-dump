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
    mwse.registerModConfig("Tamriel Rebuilt", {onCreate=placeholderMCM})
    return
end

local config = require("tamrielRebuilt.config")

----------------------
-- EasyMCM Template --
----------------------
local template = EasyMCM.createTemplate{name="Tamriel Rebuilt"}
template:saveOnClose("tamrielRebuilt", config)
template:register()

-- Preferences Page
local preferences = template:createSideBarPage{label="Preferences"}
preferences.sidebar:createInfo{text="Tamriel Rebuilt MWSE-Lua v1.0"}

-- Sidebar Credits
local credits = preferences.sidebar:createCategory{label="Credits:"}
credits:createHyperlink{
    text = "mort - Scripting",
    exec = "start https://www.nexusmods.com/morrowind/users/4138441/?tab=user+files",
}
credits:createHyperlink{
    text = "chef - TD_addon Management",
    exec = "start https://github.com/cheflul/Chefmod",
}
credits:createHyperlink{
    text = "Cicero - Icons",
    exec = "start https://www.nexusmods.com/morrowind/users/64610026?tab=user+files",
}
credits:createHyperlink{
    text = "Greatness7 - MCM Template",
    exec = "start https://www.nexusmods.com/morrowind/users/64030?tab=user+files",
}
credits:createHyperlink{
    text = "NullCascade - MWSE Support",
    exec = "start https://www.nexusmods.com/morrowind/users/26153919?tab=user+files",
}

-- Feature Toggles
local toggles = preferences:createCategory{label="Feature Toggles"}
toggles:createOnOffButton{
    label = "Add New Summoning Spells",
    description = "Add new summoning spells using creatures from Tamriel Rebuilt, Project Cyrodiil, and Skyrim: Home of the Nords.\nRequires reload.\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "summoningSpells",
        table = config,
    },
}