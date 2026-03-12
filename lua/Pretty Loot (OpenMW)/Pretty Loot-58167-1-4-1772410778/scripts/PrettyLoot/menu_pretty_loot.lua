local storage = require("openmw.storage")
local I = require("openmw.interfaces")

local MODNAME = "PrettyLoot"

--------------------------------------------------
-- SETTINGS PAGE
--------------------------------------------------
I.Settings.registerPage({
    key         = "PrettyLoot",
    l10n        = "Pretty_Loot",
    name        = "Pretty Loot",
    description = "Visual and behavior settings for Pretty Loot popups"
})

--------------------------------------------------
-- GENERAL GROUP
--------------------------------------------------
I.Settings.registerGroup({
    key              = "SettingsPrettyLoot",
    page             = "PrettyLoot",
    l10n             = "Pretty_Loot",
    name             = "General",
    permanentStorage = true,
    settings = {
        {
            key      = "enabled",
            name     = "Enable Pretty Loot",
            description = "Turns pretty loot off",
            renderer = "checkbox",
            default  = true,
        },
        {
            key      = "textureFolder",
            name     = "Popup Theme",
            description = "11 Popup Theme 6 = 9 are for Starwind ((Reload Required))",
            renderer = "number",
            default  = 1,
            argument = { min = 1, max = 11, integer = true },
        },
        {
            key      = "showGold",
            name     = "Enable Pretty Gold",
            renderer = "checkbox",
            default  = true,
        },
		{
            key      = "showGoldBackground",
            name     = "Show Gold Background",
            description = "Enable or disable the background texture behind the gold counter.",
            renderer = "checkbox",
            default  = true,
        },
        {
            key      = "side",
            name     = "Popup side",
            description = "1 = Left, 2 = Right ((Reload Required))",
            renderer = "number",
            default  = 1,
            argument = { min = 1, max = 2, integer = true },
        },
        {
            key      = "pinToCorner",
            name     = "Pin to corner",
            renderer = "checkbox",
            default  = false,
        },
        {
            key      = "corner",
            name     = "Corner position",
            description = "1:TL, 2:TR, 3:BL, 4:BR ((Reload Required)) for switching sides",
            renderer = "number",
            default  = 1,
            argument = { min = 1, max = 4, integer = true },
        },
    }
})

--------------------------------------------------
-- SCALING & POSITION GROUP
--------------------------------------------------
I.Settings.registerGroup({
    key              = "ScalingPrettyLoot",
    page             = "PrettyLoot",
    l10n             = "Pretty_Loot",
    name             = "Scaling & Position",
    permanentStorage = true,
    settings = {
        {
            key      = "goldIconStyle",
            name     = "Gold Icon Style",
            description = "Choose between standard Morrowind Gold or Starwind Credits.",
            renderer = "select",
            default  = "Morrowind",
            argument = {
            l10n = "PrettyLoot",
            items = { "Morrowind", "Starwind" },
        },
        },
        {
            key      = "fontScale",
            name     = "Loot Font Size",
            renderer = "number",
            default  = 18,
            argument = { min = 8, max = 32, integer = true },
        },
		{
            key      = "sidePadding",
            name     = "Side Padding (Gap)",
            description = "Horizontal gap from the screen edge. default = 0.005",
            renderer = "number",
            default  = 0.005,
            argument = { min = 0.0, max = 0.2, step = 0.005 },
        },
        {
            key      = "goldFontSize",
            name     = "Gold Font Size",
            renderer = "number",
            default  = 28,
            argument = { min = 12, max = 48, integer = true },
        },
        {
            key      = "goldPosX",
            name     = "Gold Position X",
            description = "Horizontal (0.0 = Left, 1.0 = Right)",
            renderer = "number",
            default  = 0.52,
            argument = { min = 0.0, max = 1.0 },
        },
        {
            key      = "goldPosY",
            name     = "Gold Position Y",
            description = "Vertical (0.0 = Top, 1.0 = Bottom)",
            renderer = "number",
            default  = 0.60,
            argument = { min = 0.0, max = 1.0 },
        },
    }
})

--------------------------------------------------
-- BEHAVIOR GROUP
--------------------------------------------------
I.Settings.registerGroup({
    key              = "BehaviorPrettyLoot",
    page             = "PrettyLoot",
    l10n             = "Pretty_Loot",
    name             = "Behavior",
    permanentStorage = true,
    settings = {
        {
            key      = "disableDropPopups",
            name     = "Disable Item Drop Popups",
            description = "Only show popups when items are added to inventory, not removed.(Good for GRIP Stance Toggle)",
            renderer = "checkbox",
            default  = false,
        },
        {
            key      = "disableDuringDialogue",
            name     = "Disable during Dialogue",
            description = "Hides popups while talking to NPCs. (Good for Dubious Concoctions)",
            renderer = "checkbox",
            default  = true,
        },
        {
            key      = "maxOnScreen",
            name     = "Max popups on screen",
            renderer = "number",
            default  = 4,
            argument = { min = 1, max = 8, integer = true },
        },
        {
            key      = "spacing",
            name     = "Popup spacing",
            renderer = "number",
            default  = 45,
            argument = { min = 25, max = 80, integer = true },
        },
        {
            key      = "fadeDuration",
            name     = "Fade duration",
            renderer = "number",
            default  = 1.0,
            argument = { min = 0.3, max = 3.0 },
        },
        {
            key      = "slideSpeed",
            name     = "Slide speed",
            renderer = "number",
            default  = 8.0,
            argument = { min = 2.0, max = 20.0 },
        },
        {
            key      = "useColors",
            name     = "Use item colors",
            description = "When off, text uses standard COLOR_NORMAL.",
            renderer = "checkbox",
            default  = true,
        },
        {
            key      = "goldStayTime",
            name     = "Gold display duration",
            renderer = "number",
            default  = 2.5,
            argument = { min = 1.0, max = 10.0 },
        },
        {
            key      = "goldRollSpeed",
            name     = "Gold counting speed",
            renderer = "number",
            default  = 12.0,
            argument = { min = 1.0, max = 50.0 },
        },
    }
})
