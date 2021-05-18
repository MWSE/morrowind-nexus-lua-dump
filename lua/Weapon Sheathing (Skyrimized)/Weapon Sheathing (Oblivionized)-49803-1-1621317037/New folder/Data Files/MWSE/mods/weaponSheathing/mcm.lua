local config = require("weaponSheathing.config")

local template = mwse.mcm.createTemplate{name="Weapon Sheathing"}
template:saveOnClose("weaponSheathing", config)
template:register()

-- Preferences Page
local preferences = template:createSideBarPage{label="Preferences"}
preferences.sidebar:createInfo{
    text = "Weapon Sheathing, Version 1.6\n\nWelcome to the configuration menu! Here you can customize which features of the mod will be turned on or off.\n\nMouse over the individual options for more information. Changes made here may require a reload of your save game to take effect.\n\nThis mod is only possible thanks to the contributions of our talented community members. You can use the links below to find more of their content.\n"
}

-- Sidebar Credits
local credits = preferences.sidebar:createCategory{label="Credits:"}
credits:createHyperlink{
    text = "akortunov",
    exec = "https://www.nexusmods.com/morrowind/users/39882615?tab=user+files",
}
credits:createHyperlink{
    text = "Greatness7",
    exec = "start https://www.nexusmods.com/morrowind/users/64030?tab=user+files",
}
credits:createHyperlink{
    text = "Heinrich",
    exec = "start https://www.nexusmods.com/morrowind/users/49330348?tab=user+files",
}
credits:createHyperlink{
    text = "Hrnchamd",
    exec = "start https://www.nexusmods.com/morrowind/users/843673?tab=user+files",
}
credits:createHyperlink{
    text = "London Rook",
    exec = "start https://www.nexusmods.com/users/9114769?tab=user+files",
}
credits:createHyperlink{
    text = "Lord Berandas",
    exec = "start https://www.nexusmods.com/morrowind/users/1858915?tab=user+files",
}
credits:createHyperlink{
    text = "Melchior Dahrk",
    exec = "start https://www.nexusmods.com/morrowind/users/962116?tab=user+files",
}
credits:createHyperlink{
    text = "MementoMoritius",
    exec = "start https://www.nexusmods.com/morrowind/users/20765944?tab=user+files",
}
credits:createHyperlink{
    text = "NullCascade",
    exec = "start https://www.nexusmods.com/morrowind/users/26153919?tab=user+files",
}
credits:createHyperlink{
    text = "Petethegoat",
    exec = "start https://www.nexusmods.com/morrowind/users/25319994?tab=user+files",
}
credits:createHyperlink{
    text = "PikachunoTM",
    exec = "start https://www.nexusmods.com/morrowind/users/16269634?tab=user+files",
}
credits:createHyperlink{
    text = "Remiros",
    exec = "start https://www.nexusmods.com/morrowind/users/899234?tab=user+files",
}

-- Feature Buttons
local buttons = preferences:createCategory{}
buttons:createOnOffButton{
    label = "Show unreadied weapons",
    description = "Show unreadied weapons\n\nThis option controls whether or not equipped weapons will be visible while unreadied. Objects blocked by exclusion lists do not respect this setting and will always have their visibility disabled.\n\nDefault: On",
    variable = mwse.mcm:createTableVariable{
        id = "showWeapon",
        table = config,
    },
}
buttons:createOnOffButton{
    label = "Show unreadied shields on back",
    description = "Show unreadied shields on back\n\nThis option controls whether or not equipped shields will be visible on the character's back while unreadied. Objects blocked by exclusion lists do not respect this setting and will always have their visibility disabled.\n\nDefault: Off",
    variable = mwse.mcm:createTableVariable{
        id = "showShield",
        table = config,
    },
}
buttons:createOnOffButton{
    label = "Show custom scabbards and quivers",
    description = "Show custom scabbards and quivers\n\nThis option controls whether or not custom art assets will be used in conjunction with the other mod features. Objects blocked by exclusion lists do not respect this setting and will always have their visibility disabled.\n\nDefault: On",
    variable = mwse.mcm:createTableVariable{
        id = "showCustom",
        table = config,
    },
}

-- Exclusions Page
template:createExclusionsPage{
    label = "Exclusions",
    description = "Weapon Sheathing by default will support all characters and equipment in your game. In some cases this is not ideal, and you may prefer to exclude certain objects from being processed. This page provides an interface to accomplish that. Using the lists below you can easily view or edit which objects are to be blocked and which are to be allowed.",
    variable = mwse.mcm:createTableVariable{
        id = "blocked",
        table = config,
    },
    filters = {
        {
            label = "Plugins",
            type = "Plugin",
        },
        {
            label = "Characters",
            type = "Object",
            objectType = tes3.objectType.npc,
        },
        {
            label = "Creatures",
            type = "Object",
            objectType = tes3.objectType.creature,
        },
        {
            label = "Shields",
            type = "Object",
            objectType = tes3.objectType.armor,
            objectFilters = {
                slot = tes3.armorSlot.shield
            },
        },
        {
            label = "Weapons",
            type = "Object",
            objectType = tes3.objectType.weapon,
        },
    },
}
