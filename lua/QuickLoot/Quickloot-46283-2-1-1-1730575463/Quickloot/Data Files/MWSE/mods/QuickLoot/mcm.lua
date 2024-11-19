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
    mwse.registerModConfig("Quick Loot", {onCreate=placeholderMCM})
    return
end


-------------------
-- Utility Funcs --
-------------------
local config = require("QuickLoot.config")

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
local template = EasyMCM.createTemplate{name="Quick Loot"}
template:saveOnClose("QuickLoot", config)
template:register()

-- Preferences Page
local preferences = template:createSideBarPage{label="Preferences"}
preferences.sidebar:createInfo{text="MWSE Quick Loot Version 2.0"}

-- Sidebar Credits
local credits = preferences.sidebar:createCategory{label="Credits:"}
credits:createHyperlink{
    text = "mort - Creator scripter etc",
    exec = "start https://www.nexusmods.com/morrowind/users/4138441?tab=user+files",
}
credits:createHyperlink{
    text = "Svengineer99 - Scripting help",
    exec = "start https://www.nexusmods.com/morrowind/users/1121630?tab=user+files",
}
credits:createHyperlink{
    text = "Greatness7 - Scripting help (also this MCM menu)",
    exec = "start https://www.nexusmods.com/users/64030?tab=user+files",
}
credits:createHyperlink{
    text = "Nullcascade - MWSE",
    exec = "start https://www.nexusmods.com/morrowind/users/26153919?tab=user+files",
}
credits:createHyperlink{
    text = "Hrnchamd - MWSE",
    exec = "start https://www.nexusmods.com/morrowind/users/843673?tab=user+files",
}
credits:createHyperlink{
    text = "PeteTheGoat - Extensive testing",
    exec = "start https://www.nexusmods.com/morrowind/users/25319994",
}


-- Feature Toggles
local toggles = preferences:createCategory{label="Feature Toggles"}
toggles:createOnOffButton{
    label = "Disable QuickLoot",
    description = "Default: Off\n\n",
    variable = EasyMCM:createTableVariable{
        id = "modDisabled",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Display messagebox on loot",
    description = "Show a default Morrowind MessageBox whenever you loot an item.\n\nDefault: Off\n\n",
    variable = EasyMCM:createTableVariable{
        id = "showMessageBox",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Hide trapped containers items",
    description = "False will show you the items but trigger the trap if you attempt to take one.\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "hideTrapped",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Hide lock status",
    description = "False will display Locked when chests are locked and nothing when set to true.\n\nDefault: Off\n\n",
    variable = EasyMCM:createTableVariable{
        id = "hideLocked",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Show quickloot menu on plant / organic containers",
    description = "An organic container is any container that respawns. Black/whitelist will override this feature.\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "showPlants",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Show containers with scripted onActivate",
    description = "Many containers have scripts on them that utilize the onActivate function to determine when the player triggers them. In many cases you will be fine, in some rare cases you will break the script. Activating a chest manually will trigger the script normally.\n\nDefault: Off\n\n",
    variable = EasyMCM:createTableVariable{
        id = "showScripted",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Hide vanilla container tooltips",
    description = "The tooltip box that normally appears when you hover over items. Some people like this.\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "hideTooltip",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Use activate key as take single item",
    description = "Press space bar to quickloot single item.\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "activateMode",
        table = config,
    },
}
toggles:createSlider{
    label = "Number of items to display by default:",
	min=4,
	max=25,
	jump=2,
    variable = EasyMCM:createTableVariable{
        id = "maxItemDisplaySize",
        table = config,
    },
}
toggles:createSlider{
    label = "Menu X position (higher = right)",
	max=10,
	jump=1,
    variable = EasyMCM:createTableVariable{
        id = "menuX",
        table = config,
    },
}
toggles:createSlider{
    label = "Menu Y position (higher = down)",
	max=10,
	jump=1,
    variable = EasyMCM:createTableVariable{
        id = "menuY",
        table = config,
    },
}

local keybinds = preferences:createCategory{label="Keybindings"}
keybinds:createKeyBinder{
    label = "Take Single Item",
    allowCombinations = true,
    variable = EasyMCM.createTableVariable{
        id = "takeKey",
        table = config,
        defaultSetting = {
            keyCode = tes3.scanCode['z'],
            --These default to false
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        }
    }
}
keybinds:createKeyBinder{
    label = "Take All Items",
    allowCombinations = true,
    variable = EasyMCM.createTableVariable{
        id = "takeAllKey",
        table = config,
        defaultSetting = {
            keyCode = tes3.scanCode['x'],
            --These default to false
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        }
    }
}
keybinds:createKeyBinder{
    label = "Toggle Quickloot on/off key (\"x\" to disable)",
    allowCombinations = true,
    variable = EasyMCM.createTableVariable{
        id = "svengKey",
        table = config,
        defaultSetting = {
            keyCode = tes3.scanCode['x'],
            --These default to false
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        }
    }
}

-- Blacklist Page
template:createExclusionsPage{
    label = "Blacklist",
    description = "All organic containers are treated like flora. Guild chests are blacklisted by default, as are several TR containers. Others can be added manually in this menu.",
    leftListLabel = "Blacklist",
    rightListLabel = "Objects",
    variable = EasyMCM:createTableVariable{
        id = "blacklist",
        table = config,
    },
    filters = {
        {callback = getContainers},
    },
}

-- Whitelist Page
template:createExclusionsPage{
    label = "Whitelist",
    description = "Scripted containers are automatically skipped, but can be enabled in this menu. Containers altered by Piratelord's Expanded Sounds are whitelisted by default. Be careful about whitelisting containers using OnActivate, as that can break their scripts.",
    leftListLabel = "Whitelist",
    rightListLabel = "Objects",
    variable = EasyMCM:createTableVariable{
        id = "whitelist",
        table = config,
    },
    filters = {
        {callback = getContainers},
    },
}
