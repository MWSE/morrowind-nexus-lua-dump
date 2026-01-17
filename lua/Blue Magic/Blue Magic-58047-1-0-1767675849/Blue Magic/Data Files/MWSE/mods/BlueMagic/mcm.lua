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
    mwse.registerModConfig("BlueMagic", {onCreate=placeholderMCM})
    return
end


-------------------
-- Utility Funcs --
-------------------
local config = require("BlueMagic.config")

local function getContainers()
    local list = {}
    for obj in tes3.iterateObjects(tes3.objectType.container) do
		list[#list+1] = (obj.baseObject or obj).id:lower()
    end
    table.sort(list)
    return list
end

----------------------
-- EasyMCM Template --
----------------------
local template = EasyMCM.createTemplate{name="Blue Magic"}
template:saveOnClose("BlueMagic", config)
template:register()

-- Preferences Page
local preferences = template:createSideBarPage{label="Preferences"}
preferences.sidebar:createInfo{text="MWSE Blue Magic"}

-- Sidebar Credits
local credits = preferences.sidebar:createCategory{label="Credits:"}
credits:createHyperlink{
    text = "mort",
    exec = "start https://www.nexusmods.com/morrowind/users/4138441?tab=user+files",
}

-- Feature Toggles
local toggles = preferences:createCategory{label="Feature Toggles"}
toggles:createOnOffButton{
    label = "Enable Blue Magic",
    description = "Default: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "enableBlueMagic",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Enable Creature Learning",
    description = "Whether or not the player can learn spells from creatures as well as NPCs. (Dagoth Ur/Alma/Vivec are creatures).\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "learnCreatureSpells",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Enable Spell Buying",
    description = "Whether or not the player can purchase new spells from vendors.\n\nDefault: Off\n\n",
    variable = EasyMCM:createTableVariable{
        id = "enablePurchasingSpells",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Enable Spellcrafting",
    description = "Whether or not the player can craft new spells.\n\nDefault: Off\n\n",
    variable = EasyMCM:createTableVariable{
        id = "enableCraftingSpells",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Remove Starting Spells",
    description = "Delete spells based on class/skills when making a new character. This only has an effect in new games.\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "removeStartingSpells",
        table = config,
    },
}
