local core = require("openmw.core")

local self = require("openmw.self")
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local storage = require('openmw.storage')
local async = require('openmw.async')
local util = require('openmw.util')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')

local settings = storage.playerSection("SettingsVoshondsQuickSelect")

I.Settings.registerPage {
    key = "SettingsVoshondsQuickSelect",
    l10n = "SettingsVoshondsQuickSelect",
    name = "voshond's QuickSelect",
    description = "These settings allow you to modify the behavior of the Quickselect bar."
}
I.Settings.registerGroup {
    key = "SettingsVoshondsQuickSelect",
    page = "SettingsVoshondsQuickSelect",
    l10n = "SettingsVoshondsQuickSelect",
    name = "Main Settings",
    permanentStorage = true,
    description = [[
    These settings allow you to modify the behavior of the Quickselect bar.

    It allows for up to 3 separate hotbars, and you can select an item with 1-10, or use the arrow keys(when enabled), or the DPad on a controller to pick a slot.

    You should unbind the normal quick items before enabling this mod.
    ]],
    settings = {
        {
            key = "visibleHotbars",
            renderer = "number",
            name = "Number of Visible Hotbars",
            description = "Set how many hotbars should be visible at once (1-3). Value of 1 shows only the current hotbar, 2 shows current and one additional, 3 shows all hotbars.",
            default = 1,
            argument = {
                min = 1,
                max = 3,
            },
        },
        {
            key = "toggleEquipment",
            renderer = "checkbox",
            name = "Toggle Equipment (Armor/Clothing/Rings)",
            description =
            "If enabled, selecting equipped armor, clothing, or accessories (rings, amulets, belts, etc.) will unequip them. If disabled, selecting already-equipped items will do nothing.",
            default = false
        },
        {
            key = "autoUnequipSheathedWeapons",
            renderer = "checkbox",
            name = "Auto-Unequip Sheathed Weapons",
            description =
            "If enabled, sheathing a weapon (by pressing its hotkey again) will also unequip it. If disabled, sheathing keeps the weapon equipped but sheathed. Only affects weapons, lockpicks, and probes.",
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
            key = "hotbarGutterSize",
            renderer = "number",
            name = "Hotbar Item Spacing",
            description = "Controls the spacing between items in the hotbar. Higher values create more space between items.",
            default = 5,
            argument = {
                min = 0,
                max = 20,
            },
        },
        {
            key = "hotbarVerticalSpacing",
            renderer = "number",
            name = "Hotbar Vertical Spacing",
            description = "Controls the vertical spacing between stacked hotbars when multiple bars are shown. Lower values create tighter spacing.",
            default = 60,
            argument = {
                min = 0,
                max = 100,
            },
        },
        {
            key = "iconSize",
            renderer = "number",
            name = "Icon Size",
            description = "Controls the size of icons in the hotbar. Use multiples of 32 (native icon size) for sharpest quality: 32, 64, 96.",
            default = 32,
            argument = {
                min = 20,
                max = 100,
            },
        },
        {
            key = "enableDebugLogging",
            renderer = "checkbox",
            name = "Enable Debug Logging",
            description = "If enabled, debug print statements will be shown in the console. Useful for troubleshooting but may impact performance.",
            default = false
        },
        {
            key = "enableFrameLogging",
            renderer = "checkbox",
            name = "Enable Frame Logging",
            description = "If enabled, logs high-frequency updates like UI refreshes and animations. Warning: Can be extremely verbose!",
            default = false
        },
        {
            key = "enableFadingBars",
            renderer = "checkbox",
            name = "Enable Fading Bars",
            description = "If enabled, the hotbar will automatically hide after 2 seconds of inactivity. It will reappear when you interact with items.",
            default = false
        },
    },
}

-- Register text appearance settings group
I.Settings.registerGroup {
    key = "SettingsVoshondsQuickSelectText",
    page = "SettingsVoshondsQuickSelect",
    l10n = "SettingsVoshondsQuickSelect",
    name = "Text Appearance",
    permanentStorage = true,
    description = "These settings control the appearance of text in the QuickSelect interface.",
    settings = {
        {
            key = "showSlotNumbers",
            renderer = "checkbox",
            name = "Show Slot Numbers",
            description = "If enabled, slot numbers will be displayed in the bottom right of each item.",
            default = true
        },
        {
            key = "showItemCounts",
            renderer = "checkbox",
            name = "Show Item Counts",
            description = "If enabled, the count of stackable items will be displayed in the top left of each item.",
            default = true
        },
        {
            key = "slotNumberTextSize",
            renderer = "number",
            name = "Slot Number Text Size",
            description = "Controls the font size of the slot number text.",
            default = 14,
            argument = {
                min = 6,
                max = 32,
            },
        },
        {
            key = "itemCountTextSize",
            renderer = "number",
            name = "Item Count Text Size",
            description = "Controls the font size of the item count text.",
            default = 12,
            argument = {
                min = 6,
                max = 32,
            },
        },
        {
            key = "slotTextColor",
            renderer = "color",
            name = "Slot Text Color",
            description = "Controls the color of the slot numbers and item counts.",
            default = util.color.rgba(0.792, 0.647, 0.376, 1.0),
        },
        {
            key = "slotTextAlpha",
            renderer = "number",
            name = "Slot Text Opacity",
            description = "Controls the transparency of the slot text. Higher values make the text more opaque.",
            default = 100,
            argument = {
                min = 0,
                max = 100,
            },
        },
        {
            key = "slotTextShadowColor",
            renderer = "color",
            name = "Text Shadow Color",
            description = "Controls the color of the shadow behind slot numbers and item counts.",
            default = util.color.rgba(0, 0, 0, 1.0), -- Black default
        },
        {
            key = "slotTextShadowAlpha",
            renderer = "number",
            name = "Text Shadow Opacity",
            description = "Controls the transparency of the text shadow. Higher values make the shadow more visible.",
            default = 100,
            argument = {
                min = 0,
                max = 100,
            },
        },
        {
            key = "enableTextShadow",
            renderer = "checkbox",
            name = "Enable Text Shadow",
            description = "If enabled, text will have a shadow effect to improve readability.",
            default = true
        },
        {
            key = "enableQuantityThresholdColor",
            renderer = "checkbox",
            name = "Enable Item Quantity Threshold Colour",
            description = "If enabled, item counts will change color based on quantity thresholds.",
            default = false
        },
        {
            key = "quantityCriticalThreshold",
            renderer = "number",
            name = "Critical Quantity Threshold",
            description = "Item counts at or below this value will be shown in red.",
            default = 1,
            argument = {
                min = 0,
                max = 1000,
            },
        },
        {
            key = "quantityWarningThreshold",
            renderer = "number",
            name = "Warning Quantity Threshold",
            description = "Item counts at or below this value (but above critical) will be shown in orange.",
            default = 5,
            argument = {
                min = 0,
                max = 1000,
            },
        },
    },
}

I.Settings.registerGroup {
    key = "SettingsVoshondsQuickSelectMagicCharges",
    page = "SettingsVoshondsQuickSelect",
    l10n = "SettingsVoshondsQuickSelect",
    name = "Magic Charges",
    permanentStorage = true,
    description = "These settings control the appearance and behavior of magic charge displays for enchanted items in the QuickSelect interface.",
    settings = {
        {
            key = "showMagicCharges",
            renderer = "checkbox",
            name = "Show Magic Charges",
            description = "If enabled, the current charge of enchanted items will be displayed.",
            default = true
        },
        {
            key = "showMaxMagicCharges",
            renderer = "checkbox",
            name = "Show Max Charges",
            description = "If enabled, the maximum charge value will be shown alongside the current charge (e.g. 20/100).",
            default = true
        },
        {
            key = "enableChargeThresholdColor",
            renderer = "checkbox",
            name = "Enable Charge Thresholds",
            description = "If enabled, enchantment charges will be color-coded based on their percentage of maximum charge. Red for ≤10%, orange for ≤30%.",
            default = true
        },
        {
            key = "magicChargeTextSize",
            renderer = "number",
            name = "Magic Charge Text Size",
            description = "Controls the font size of the magic charge text.",
            default = 14,
            argument = {
                min = 6,
                max = 32,
            },
        },
        {
            key = "magicChargeTextColor",
            renderer = "color",
            name = "Magic Charge Text Color",
            description = "Controls the color of the magic charge text.",
            default = util.color.rgba(0.2, 0.6, 1, 1), -- blue default
        },
        {
            key = "magicChargeTextAlpha",
            renderer = "number",
            name = "Magic Charge Text Opacity",
            description = "Controls the transparency of the magic charge text. Higher values make the text more opaque.",
            default = 100,
            argument = {
                min = 0,
                max = 100,
            },
        },
        {
            key = "magicChargeTextShadow",
            renderer = "checkbox",
            name = "Enable Magic Charge Text Shadow",
            description = "If enabled, a shadow will be drawn behind the magic charge text.",
            default = true
        },
        {
            key = "magicChargeTextShadowColor",
            renderer = "color",
            name = "Magic Charge Text Shadow Color",
            description = "Controls the color of the shadow behind the magic charge text.",
            default = util.color.rgba(0, 0, 0, 1.0), -- Black default
        },
    },
}

I.Settings.registerGroup {
    key = "SettingsVoshondsQuickSelectItemCountThresholds",
    page = "SettingsVoshondsQuickSelect",
    l10n = "SettingsVoshondsQuickSelect",
    name = "Item Count Thresholds",
    permanentStorage = true,
    description = "These settings control the appearance, display, and threshold coloring of item counts for potions, repair items, probes, lockpicks, and ammo in the QuickSelect interface.",
    settings = {
        -- Potions
        {
            key = "showPotionCounts",
            renderer = "checkbox",
            name = "Show Potion Counts",
            description = "If enabled, the count of potions will be displayed.",
            default = true
        },
        {
            key = "enablePotionThresholdColor",
            renderer = "checkbox",
            name = "Enable Potion Quantity Threshold Colour",
            description = "If enabled, potion counts will change color based on quantity thresholds.",
            default = false
        },
        {
            key = "potionCriticalThreshold",
            renderer = "number",
            name = "Potion Critical Quantity Threshold",
            description = "Potion counts at or below this value will be shown in red.",
            default = 1,
            argument = {
                min = 0,
                max = 1000,
            },
        },
        {
            key = "potionWarningThreshold",
            renderer = "number",
            name = "Potion Warning Quantity Threshold",
            description = "Potion counts at or below this value (but above critical) will be shown in orange.",
            default = 5,
            argument = {
                min = 0,
                max = 1000,
            },
        },
        -- Repair
        {
            key = "showRepairCounts",
            renderer = "checkbox",
            name = "Show Repair Counts",
            description = "If enabled, the count of repair items will be displayed.",
            default = true
        },
        {
            key = "enableRepairThresholdColor",
            renderer = "checkbox",
            name = "Enable Repair Item Quantity Threshold Colour",
            description = "If enabled, repair item counts will change color based on quantity thresholds.",
            default = false
        },
        {
            key = "repairCriticalThreshold",
            renderer = "number",
            name = "Repair Item Critical Quantity Threshold",
            description = "Repair item counts at or below this value will be shown in red.",
            default = 1,
            argument = {
                min = 0,
                max = 1000,
            },
        },
        {
            key = "repairWarningThreshold",
            renderer = "number",
            name = "Repair Item Warning Quantity Threshold",
            description = "Repair item counts at or below this value (but above critical) will be shown in orange.",
            default = 5,
            argument = {
                min = 0,
                max = 1000,
            },
        },
        -- Probes
        {
            key = "showProbeCounts",
            renderer = "checkbox",
            name = "Show Probe Counts",
            description = "If enabled, the count of probes will be displayed.",
            default = true
        },
        {
            key = "enableProbeThresholdColor",
            renderer = "checkbox",
            name = "Enable Probe Quantity Threshold Colour",
            description = "If enabled, probe counts will change color based on quantity thresholds.",
            default = false
        },
        {
            key = "probeCriticalThreshold",
            renderer = "number",
            name = "Probe Critical Quantity Threshold",
            description = "Probe counts at or below this value will be shown in red.",
            default = 1,
            argument = {
                min = 0,
                max = 1000,
            },
        },
        {
            key = "probeWarningThreshold",
            renderer = "number",
            name = "Probe Warning Quantity Threshold",
            description = "Probe counts at or below this value (but above critical) will be shown in orange.",
            default = 5,
            argument = {
                min = 0,
                max = 1000,
            },
        },
        -- Lockpicks
        {
            key = "showLockpickCounts",
            renderer = "checkbox",
            name = "Show Lockpick Counts",
            description = "If enabled, the count of lockpicks will be displayed.",
            default = true
        },
        {
            key = "enableLockpickThresholdColor",
            renderer = "checkbox",
            name = "Enable Lockpick Quantity Threshold Colour",
            description = "If enabled, lockpick counts will change color based on quantity thresholds.",
            default = false
        },
        {
            key = "lockpickCriticalThreshold",
            renderer = "number",
            name = "Lockpick Critical Quantity Threshold",
            description = "Lockpick counts at or below this value will be shown in red.",
            default = 1,
            argument = {
                min = 0,
                max = 1000,
            },
        },
        {
            key = "lockpickWarningThreshold",
            renderer = "number",
            name = "Lockpick Warning Quantity Threshold",
            description = "Lockpick counts at or below this value (but above critical) will be shown in orange.",
            default = 5,
            argument = {
                min = 0,
                max = 1000,
            },
        },
        -- Ammo
        {
            key = "showAmmoCounts",
            renderer = "checkbox",
            name = "Show Ammo Counts",
            description = "If enabled, the count of ammo will be displayed.",
            default = true
        },
        {
            key = "enableAmmoThresholdColor",
            renderer = "checkbox",
            name = "Enable Ammo Quantity Threshold Colour",
            description = "If enabled, ammo counts will change color based on quantity thresholds.",
            default = false
        },
        {
            key = "ammoCriticalThreshold",
            renderer = "number",
            name = "Ammo Critical Quantity Threshold",
            description = "Ammo counts at or below this value will be shown in red.",
            default = 1,
            argument = {
                min = 0,
                max = 1000,
            },
        },
        {
            key = "ammoWarningThreshold",
            renderer = "number",
            name = "Ammo Warning Quantity Threshold",
            description = "Ammo counts at or below this value (but above critical) will be shown in orange.",
            default = 5,
            argument = {
                min = 0,
                max = 1000,
            },
        },
    },
}

return settings
