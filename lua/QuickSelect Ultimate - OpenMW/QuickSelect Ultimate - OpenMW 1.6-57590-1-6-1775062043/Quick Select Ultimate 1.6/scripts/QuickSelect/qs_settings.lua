local core = require("openmw.core")

local self = require("openmw.self")
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local storage = require('openmw.storage')
local async = require('openmw.async')
local util = require('openmw.util')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')

local settings = storage.playerSection("SettingsQuickSelect")
local mouseSettings = storage.playerSection("SettingsQuickSelectMouse")  -- Mouse settings storage
local gamepadSettings = storage.playerSection("SettingsQuickSelectGamepad")
local keyboardSettings = storage.playerSection("SettingsQuickSelectKeyboard")
local colorsSettings = storage.playerSection("SettingsQuickSelectColors")
local dimensionsSettings = storage.playerSection("SettingsQuickSelectDimensions")
I.Settings.registerPage({
    key = "SettingsQuickSelect",
    l10n = "SettingsQuickSelect",
    name = "QuickSelectUltimate",
    description = [[
QuickSelectUltimate v1.6
Base mod: SkyHasACat || Rework: Skrow42
Modify the mod behavior to your needs below.
You MUST unbind the default MW quick action binds before using this mod. ]],
})
I.Settings.registerGroup({
    key = "SettingsQuickSelect",
    page = "SettingsQuickSelect",
    l10n = "SettingsQuickSelect",
    name = "Display & Gameplay Settings",
    permanentStorage = true,
description = [[
General settings for the QuickSelect mod.]],
    settings = {
        {
            key = "pauseWhenSelecting",
            renderer = "checkbox",
            name = "Pause While Selecting",
            description =
            "If enabled, the game will pause while selecting a slot on the hotbar. If disabled, the game will continue.",
            default = false
        },
        {
            key = "persistMode",
            renderer = "select",
            name = "Hotbar Visibility Mode",
            description =
            "Choose when the hotbar should be visible. 'Always' keeps it on screen. 'Fade Only' will hide the hotbar after a delay of inactivity.",
            default = "Fade Only",
            argument = {
                disabled = false,
                l10n = "SettingsQuickSelect",
                items = { "Never", "Always", "Fade Only" }
            }
        },
        {
            key = "fadeDelay",
            renderer = "number",
            name = "Fade Start Delay (seconds)",
            description = "Time of inactivity before the hotbar starts to fade.",
            default = 15,
            argument = {
                min = 1,
                max = 120,
            }
        },
        {
            key = "fadeTime",
            renderer = "number",
            name = "Fade Transition Time (seconds)",
            description = "Time it takes for the hotbar to go from full visibility to invisible.",
            default = 1,
            argument = {
                min = 0.1,
                max = 10,
                step = 0.1
            }
        },
        {
            key = "unEquipOnHotkey",
            renderer = "checkbox",
            name = "Unequip when selecting equipped items",
            description =
            "If enabled, selecting an item that is already equipped will unequip it. If disabled, selecting an item that is already equipped will do nothing.",
            default = false
        },
        {
            key = "showNumbersForEmptySlots",
            renderer = "checkbox",
            name = "Show numbers for empty slots",
            description =
            "If enabled, empty slots will show a number indicating the slot number. If disabled, empty slots will be blank.",
            default = true
        },
        {
            key = "hotBarOnTop",
            renderer = "checkbox",
            name = "Set Hotbar on Top",
            description =
            "If enabled, the hotbar will be displayed at the top.",
            default = false
        },
        {
            key = "hotbarCount",
            renderer = "select",
            name = "Main Hotbar Row Count",
            description = "Choose how many hotkey bars (10 slots each) to show in the QuickSelect menu.",
            default = 3,
            argument = {
                disabled = false,
                l10n = "SettingsQuickSelect",
                items = { 2, 3, 4, 5 }
            }
        },
        {
            key = "spellsExpandedDefault",
            renderer = "checkbox",
            name = "Spell Categories Expanded by Default",
            description = "If enabled, Powers/Spells/Enchantments lists will be open when you open the magic menu.",
            default = true
        },
    },
})
I.Settings.registerGroup({
    key = "SettingsQuickSelectGamepad",
    page = "SettingsQuickSelect",
    l10n = "SettingsQuickSelect",
    name = "Gamepad Settings",
    permanentStorage = true,
description = [[
Settings for gamepad behavior.]],
    settings = {
        {
            key = "enableGamepadControls",
            renderer = "checkbox",
            name = "Enable Gamepad Controls",
            description = "If enabled, gamepad buttons are active for hotbar navigation/selection.",
            default = true
        },
        {
            key = "confirmButton",
            renderer = "select",
            name = "Gamepad Confirm Button",
            default = "A",
            description = "Button used to confirm selections in the menu.",
            argument = {
                disabled = false,
                l10n = "SettingsQuickSelect",
                items = { "A", "B", "X", "Y", "Start", "Back", "L1", "R1", "L3", "R3" }
            }
        },
        {
            key = "cancelButton",
            renderer = "select",
            name = "Gamepad Cancel Button",
            default = "B",
            description = "Button used to cancel/close the menu.",
            argument = {
                disabled = false,
                l10n = "SettingsQuickSelect",
                items = { "A", "B", "X", "Y", "Start", "Back", "L1", "R1", "L3", "R3" }
            }
        },
        {
            key = "compatibilitymode",
            renderer = "checkbox",
            name = "Compatibility Mode",
            description = "If enabled, DPAD Down will start picking mode if the hotbar is not visible.",
            default = false
        },
    }
})
I.Settings.registerGroup({
    key = "SettingsQuickSelectMouse",
    page = "SettingsQuickSelect",
    l10n = "SettingsQuickSelect",
    name = "Mouse Settings",
    permanentStorage = true,
description = [[
Settings for mouse behavior.]],
    settings = {
        {
            key = "enableMouseControls",
            renderer = "checkbox",
            name = "Enable Mouse Controls",
            description =
            "If enabled, mouse wheel and middle mouse button controls are active for hotbar and menu navigation/selection.",
            default = true
        },
        {
            key = "mouseHotbarButton",
            renderer = "select",
            name = "Mouse Hotbar Button",
            default = "Mouse3",
            description = "Decide which mouse button will be used for confirming the hotbar choice.",
            argument = {
                disabled = false,
                l10n = "AshlanderArchitectButtons",
                items = { "Mouse3", "Mouse5" }
            },
        },
    }
})
I.Settings.registerGroup({
    key = "SettingsQuickSelectColors",
    page = "SettingsQuickSelect",
    l10n = "SettingsQuickSelect",
    name = "Colors",
    permanentStorage = true,
description = [[
Settings for colors and opacity.]],
    settings = {
        {
            key = "conditionColor",
            renderer = "color",
            name = "Condition Bar Color (default e53326)",
            default = util.color.rgba(0.90, 0.20, 0.15, 1.00),
            description = "Color of the condition bars below items, including alpha.",
        },
        {
            key = "chargeColor",
            renderer = "color",
            name = "Charge Bar Color  (default 7f99e5)",
            default = util.color.rgba(0.50, 0.60, 0.90, 1.00),
            description = "Color of the charge bars below items, including alpha.",
        },
        {
            key = "castChanceColor",
            renderer = "color",
            name = "Spell Cast Chance Bar Color  (default dfb34d)",
            default = util.color.rgba(0.87, 0.70, 0.30, 1.00),
            description = "Color of the spell cast chance bars below spells, including alpha.",
        },
        {
            key = "hotbarOpacity",
            renderer = "number",
            name = "Hotbar Opacity - Range: (0.00-1.00)",
            default = 1.00,
            description = "Set the opacity of the hotbar. 1.00 is fully visible, 0.00 is fully transparent.",
            argument = {
                min = 0.00,
                max = 1.00,
                format = "%.2f"
            },
        },
        {
            key = "equippedItemOpacity",
            renderer = "number",
            name = "Equipped Item Hotbar Opacity - Range: (0.00-1.00)",
            default = 1.00,
            description = "Set the opacity of the equipped item boxes in the hotbar. 1.00 is fully visible, 0.00 is fully transparent.",
            argument = {
                min = 0.00,
                max = 1.00,
                format = "%.2f"
            },
        },
        {
            key = "durabilityChargeBarsOpacity",
            renderer = "number",
            name = "Durability/Charge/Cast Bars Opacity - Range: (0.00-1.00)",
            default = 1.00,
            description = "Set the opacity of the durability, charge, and spell cast chance bars below applicable hotbar items. 1.00 is fully visible, 0.00 is fully transparent.",
            argument = {
                min = 0.00,
                max = 1.00,
                format = "%.2f"
            },
        },
    }
})
I.Settings.registerGroup({
    key = "SettingsQuickSelectDimensions",
    page = "SettingsQuickSelect",
    l10n = "SettingsQuickSelect",
    name = "Dimensions",
    permanentStorage = true,
description = [[
Settings for dimensions and scaling.]],
    settings = {
        {
            key = "dataBarHeight",
            renderer = "number",
            name = "Item Status Bars Height - Range: (5-12)",
            default = 6,
            description = "Choose height of the condition and charge bars below items.",
            argument = {
                min = 5,
                max = 12,
                integer = true
            },
        },
        {
            key = "hotbarScale",
            renderer = "number",
            name = "Hotbar Position - Range: (0.965-21.00)",
            default = 0.965,
            description = "Fine-tune where you want your hotbar to be exactly placed on the screen. \n\n Horizontal - Up&Down\n Vertical - Left&Right",
            argument = {
                min = 0.965,
                max = 21.00,
                format = "%.2f"
            },
        },
        {
            key = "hotbarVertical",
            renderer = "checkbox",
            name = "Vertical Orientation",
            description = "If enabled, the hotbar will be vertical on the left side of the screen.",
            default = false
        },
    }
})
I.Settings.registerGroup({
    key = "SettingsQuickSelectKeyboard",
    page = "SettingsQuickSelect",
    l10n = "SettingsQuickSelect",
    name = "Keyboard Settings",
    permanentStorage = true,
    description = [[ Settings for keyboard behavior. ]],
    settings = {
        {
            key = "confirmKey",
            renderer = "textLine",
            name = "Keyboard Confirm Key",
            default = "F",
            description = "Type the key name (e.g. F, Space, Enter). Case sensitive.",
        },
        {
            key = "useArrowKeys",
            renderer = "checkbox",
            name = "Use Arrow Keys for Selection",
            description = "If enabled, use arrow keys for DPad-style navigation.",
            default = false
        },
        {
            key = "barSelectionMode",
            renderer = "select",
            name = "Hotbar Switch Key",
            default = "Shift Modifier",
            description = "The modifier key used with 1-5 keys to change the active hotbar page.",
            argument = {
                disabled = false,
                l10n = "AshlanderArchitectButtons",
                items = { "Shift Modifier", "Ctrl Modifier", "Alt Modifier" },
            },
        },
    }
})
settings:get("unEquipOnHotkey")
return settings