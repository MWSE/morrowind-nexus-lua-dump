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
    mwse.registerModConfig("Graphic Herbalism", {onCreate=placeholderMCM})
    return
end


-------------------
-- Utility Funcs --
-------------------
local config = require("graphicHerbalism.config")

local function getHerbalismObjects()
    local list = {}
    for obj in tes3.iterateObjects(tes3.objectType.container) do
        if obj.organic then
            list[#list+1] = (obj.baseObject or obj).id:lower()
        end
    end
    table.sort(list)
    return list
end

local function getVolumeAsInteger(self)
    return math.round(config.volume * 100)
end

local function setVolumeAsDecimal(self, value)
    config.volume = math.round(value / 100, 2)
end


----------------------
-- EasyMCM Template --
----------------------
local template = EasyMCM.createTemplate{name="Graphic Herbalism"}
template:saveOnClose("graphicHerbalism", config)
template:register()

-- Preferences Page
local preferences = template:createSideBarPage{label="Preferences"}
preferences.sidebar:createInfo{text="MWSE Graphic Herbalism Version 1.03"}

-- Sidebar Credits
local credits = preferences.sidebar:createCategory{label="Credits:"}
credits:createHyperlink{
    text = "Greatness7 - Scripting",
    exec = "start https://www.nexusmods.com/morrowind/users/64030?tab=user+files",
}
credits:createHyperlink{
    text = "Merlord - MCM Support",
    exec = "start https://www.nexusmods.com/morrowind/users/3040468?tab=user+files",
}
credits:createHyperlink{
    text = "NullCascade - MWSE Support",
    exec = "start https://www.nexusmods.com/morrowind/users/26153919?tab=user+files",
}
credits:createHyperlink{
    text = "Petethegoat - Script Help and Feedback",
    exec = "start https://www.nexusmods.com/morrowind/users/25319994?tab=user+files",
}
credits:createHyperlink{
    text = "Remiros - MOP Meshes",
    exec = "start https://www.nexusmods.com/morrowind/users/899234?tab=user+files",
}
credits:createHyperlink{
    text = "Stuporstar - Mesh Conversion and Smoothing",
    exec = "start http://stuporstar.sarahdimento.com/",
}
credits:createHyperlink{
    text = "Sveng - Feedback and Playtesting",
    exec = "start https://www.nexusmods.com/morrowind/users/1121630?tab=user+files",
}
credits:createHyperlink{
    text = "Gruntella - Graphic Herbalism Univeral Textures",
    exec = "start https://www.nexusmods.com/morrowind/users/2356095?tab=user+files",
}
credits:createHyperlink{
    text = "Skrawafunda and Manauser - Original Graphic Herbalism Textures",
    exec = "start https://www.nexusmods.com/morrowind/users/13100210?tab=user+files",
}
credits:createHyperlink{
    text = "Moranar - Smoothed Meshes",
    exec = "start https://www.nexusmods.com/morrowind/users/6676263?tab=user+files",
}
credits:createHyperlink{
    text = "Tyddy - Smoothed Meshes",
    exec = "start https://www.nexusmods.com/morrowind/users/3281858?tab=user+files",
}
credits:createHyperlink{
    text = "Articus - Mesh Help and Feedback",
    exec = "start https://www.nexusmods.com/morrowind/users/51799631?tab=user+files",
}
credits:createHyperlink{
    text = "DassiD - Texture Upscaling",
    exec = "start https://www.nexusmods.com/morrowind/users/6344059?tab=user+files",
}
credits:createHyperlink{
    text = "Nich and CJW-Craigor - Diverse Correct UV Ore",
    exec = "start http://mw.modhistory.com/download-1-13484",
}

-- Feature Toggles
local toggles = preferences:createCategory{label="Feature Toggles"}
toggles:createOnOffButton{
    label = "Show ingredient tooltips",
    description = "Show ingredient tooltips\n\nThis option controls whether or not ingredient tooltips will be shown when targeting a valid herbalism container.\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "showTooltips",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Show picked message",
    description = "Show picked messagebox\n\nThis option controls whether or not picked messagebox will be shown after activating a herbalism container.\n\nDefault: On\n\n",
    variable = EasyMCM:createTableVariable{
        id = "showPickedMessage",
        table = config,
    },
}

-- Feature Controls
local controls = preferences:createCategory{label="Feature Controls"}
controls:createSlider{
    label = "Pick Volume: %s%%",
    description = "Pick Volume Description",
    variable = EasyMCM:createVariable{
        get = getVolumeAsInteger,
        set = setVolumeAsDecimal,
    },
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
        {callback = getHerbalismObjects},
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
        {callback = getHerbalismObjects},
    },
}
