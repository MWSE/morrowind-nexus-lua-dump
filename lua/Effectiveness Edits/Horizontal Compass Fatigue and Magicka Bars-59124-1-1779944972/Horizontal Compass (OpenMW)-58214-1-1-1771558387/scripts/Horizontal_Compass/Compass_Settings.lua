-- OpenMW 50 --
-- Horizontal Compass Settings --

local I = require("openmw.interfaces")

I.Settings.registerPage({
    key   = "Horizontal_Compass_menu",
    l10n  = "Horizontal_Compass_menu",
    name  = "Horizontal Compass",
    label = "My HUD Settings"
})

I.Settings.registerGroup({
    key   = "Horizontal_Compass_Settings",
    page  = "Horizontal_Compass_menu",
    l10n  = "Horizontal_Compass_menu",
    name  = "Compass Options",
	description = "A ((-RELOAD-)) is required for settings to take effect",
    permanentStorage = true,
    settings = {
        {
            key = "showCompass",
            renderer = "checkbox",
            name = "Enable Compass",
            default = true,
        }, 
        {
            key = "showCellName",
            renderer = "checkbox",
            name = "Show Cell Name",
            default = true,
        }, 
        {
            key = "stylePath",
            renderer = "number",
            name = "Compass Style Folder",
			description = "changes compass Style. 1 = 7 Styles. ((Reload Required))",
            min = 1, max = 7, integer = true,
            default = 1,
        }, 
        {
            key = "compassScale",
            renderer = "number",
            name = "Compass Scale",
            description = "Adjust size (50-150). ((Reload Required))",
            min = 50, max = 150, integer = true,
            default = 100,
        }, 
		{
            key = "cellTextSize",
            renderer = "number",
            name = "Location Text Size",
            description = "Adjust the size of the cell name text. Default is 20. ((Reload Required))",
            min = 10, max = 40, integer = true,
            default = 20,
        },

		{
            key = "posX",
            renderer = "number",
            name = "Horizontal Position",
            description = "Move left (0) to right (100). Default is 50. ((Reload Required))",
            min = 0, max = 100, integer = true,
            default = 50,
        },
        {
            key = "posY",
            renderer = "number",
            name = "Vertical Position",
            description = "Move top (0) to bottom (100). Default is 5. ((Reload Required))",
            min = 0, max = 100, integer = true,
            default = 5,
        },
    },
})

I.Settings.registerGroup({
    key   = "Horizontal_Compass_Settings_HB",
    page  = "Horizontal_Compass_menu",
    l10n  = "Horizontal_Compass_menu",
    name  = "Compass Health Bars Options",
    permanentStorage = true,
    settings = {
{
    key = "showHealthBar",
    renderer = "checkbox",
    name = "Enable Target Health Bars",
    default = false,
},
{
    key = "showLevel",
    renderer = "checkbox",
    name = "Show Target Level",
    description = "Toggles the numeric level display.",
    default = true,
},
{
    key = "showClassIcon",
    renderer = "checkbox",
    name = "Show Class Icon",
    description = "Toggles the role/class icon next to the bar.",
    default = true,
},
{
    key = "showTargetName",
    renderer = "checkbox",
    name = "Show Target Name",
    description = "Toggles the name text above the health bar.",
    default = true,
},
{
    key = "namePosY",
    renderer = "number",
    name = "Target Name Vert. Pos",
    description = "Move target name up (0) or down (100). Default is 50. ((Reload Required))",
    min = 0, max = 100, integer = true,
    default = 50,
},
{
    key = "hbScale",
    renderer = "number",
    name = "Health Bar Scale",
    description = "Adjust the size of the health bars (50-150). Default is 100. ((Reload Required))",
    min = 50, max = 150, integer = true,
    default = 100,
},
{
    key = "hbPosX",
    renderer = "number",
    name = "Health Bar Horiz. Pos",
    description = "Move health bars left to right (0-100). Default is 50. ((Reload Required))",
    min = 0, max = 100, integer = true,
    default = 50,
},
{
    key = "hbPosY",
    renderer = "number",
    name = "Health Bar Vert. Pos",
    description = "Move health bars top to bottom (0-100). Default is 0. ((Reload Required))",
    min = 0, max = 100, integer = true,
    default = 0,
},
    },
})

I.Settings.registerGroup({
    key   = "Horizontal_Compass_Settings_FB",
    page  = "Horizontal_Compass_menu",
    l10n  = "Horizontal_Compass_menu",
    name  = "Compass Fatigue Bars Options",
    permanentStorage = true,
    settings = {
{
    key = "showFatigueBar",
    renderer = "checkbox",
    name = "Enable Target Fatigue Bars",
    default = false,
},
{
    key = "fbScale",
    renderer = "number",
    name = "Fatigue Bar Scale",
    description = "Adjust the size of the fatigue bars (50-150). Default is 100. ((Reload Required))",
    min = 50, max = 150, integer = true,
    default = 100,
},
{
    key = "fbPosX",
    renderer = "number",
    name = "Fatigue Bar Horiz. Pos",
    description = "Move fatigue bars left to right (0-100). Default is 50. ((Reload Required))",
    min = 0, max = 100, integer = true,
    default = 50,
},
{
    key = "fbPosY",
    renderer = "number",
    name = "Fatigue Bar Vert. Pos",
    description = "Move fatigue bars top to bottom (0-100). Default is 5 (just under the health bar). ((Reload Required))",
    min = 0, max = 100, integer = true,
    default = 5,
},
    },
})

I.Settings.registerGroup({
    key   = "Horizontal_Compass_Settings_MB",
    page  = "Horizontal_Compass_menu",
    l10n  = "Horizontal_Compass_menu",
    name  = "Compass Magicka Bars Options",
    permanentStorage = true,
    settings = {
{
    key = "showMagickaBar",
    renderer = "checkbox",
    name = "Enable Target Magicka Bars",
    default = false,
},
{
    key = "mbScale",
    renderer = "number",
    name = "Magicka Bar Scale",
    description = "Adjust the size of the magicka bars (50-150). Default is 100. ((Reload Required))",
    min = 50, max = 150, integer = true,
    default = 100,
},
{
    key = "mbPosX",
    renderer = "number",
    name = "Magicka Bar Horiz. Pos",
    description = "Move magicka bars left to right (0-100). Default is 50. ((Reload Required))",
    min = 0, max = 100, integer = true,
    default = 50,
},
{
    key = "mbPosY",
    renderer = "number",
    name = "Magicka Bar Vert. Pos",
    description = "Move magicka bars top to bottom (0-100). Default is 10 (under the fatigue bar). ((Reload Required))",
    min = 0, max = 100, integer = true,
    default = 10,
},
    },
})

return {}
