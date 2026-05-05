local this = {
    --mcm general
    ["mcm.modname"] = "QuickKeys Hotbar Extended",
    ["mcm.version"] = "\nVersion: ",
    ["mcm.TESAll"] = "Mod page on TESAll",
    ["mcm.FullRest"] = "Mod page on FullRest",
    ["mcm.Nexus"] = "Mod page on Nexusmods",
    ["mcm.Pirate"] = "Pirate: assembled everything into a single whole and refined it.",
    ["mcm.Spammer"] = "Spammer: author of QuickKeys Hotbar - MWSE and \"QuickKey Outlander - MWSE\"",
    ["mcm.Virnetch"] = "Virnetch: author of Hotkeys Extended",
    ["mcm.ModDescription"] = "This mod adds a hotkey bar to the game interface.\n\z
    Can work in two modes:\n\z
    1. Display of the vanilla Hotkey Bar. (Default)\n\z
    2. Hotkey Bar Extended.\n\z
    Allows you to use 3 sets of keys. To start using the hotkey bar extended, you need to clear all slots in the vanilla Quick Keys and enable the hotkey bar extended in the \"Hotkey Bar Extended\" menu tab.\n\n\z
    Also adds 2 new ways to bind items and spells to hotkey slots.\n\z
    1. Drag and drop an item from the inventory onto a slot.\n\z
    2. Hold down a slot key (or key combination for the extended panel) + click on an item in the inventory\\spell name in the magic menu.\n\n\z
    The mod is based on a compilation of the mods \"QuickKeys Hotbar - MWSE\", \"Hotkeys Extended\" and \"QuickKey Outlander - MWSE\".",
    ["mcm.Links"] = "Links",
    ["mcm.Credits"] = "Credits",
    --mcm HotBar
    ["mcm.generalSettings"] = "General Settings",
    ["mcm.displayHotBar.label"] = "Hotkey Bar Display Settings",
    ["mcm.displayHotBar.desc"] = "Hotkey Bar Display Settings.",
    ["mcm.HotBar.YesNo.label"] = "Show Hotkey Bar?",
    ["mcm.HotBar.YesNo.desc"] = "This option allows you to enable\\disable the display of the hotkey bar on the screen.\n\n\z
    Hotkeys will work even if the panel is hidden.",
    ["mcm.HotBar.Orient.label"] = "Hotkey Bar Orientation:",
    ["mcm.HotBar.Orient.desc"] = "This parameter determines whether the hotkey bar will be positioned horizontally or vertically on the screen.",
    ["mcm.HotBar.Orient.hor"] = "Horizontal",
    ["mcm.HotBar.Orient.ver"] = "Vertical",
    ["mcm.seph.YesNo.label"] = "Use \"Seph's HUD Customizer\"?",
    ["mcm.seph.YesNo.desc"] = "This option activates precise positioning of the Hotkey Bar using the \"Seph's HUD Customizer\".\nThe option is available when the \"Seph's HUD Customizer\" mod is installed. Before adjusting the position, select the Hotkey Bar orientation.\n\n\z
    If you want to use the built-in position settings from this menu, disable this option.\nAfter enabling\\disabling this option, you need to restart the game!",
    ["mcm.HotBar.PosX.label"] = "Hotkey Bar Horizontal Position:",
    ["mcm.HotBar.PosX.desc"] = "This parameter determines the horizontal position of the hotkey bar on the screen.",
    ["mcm.HotBar.PosY.label"] = "Hotkey Bar Vertical Position:",
    ["mcm.HotBar.PosY.desc"] = "This parameter determines the vertical position of the hotkey bar on the screen.",
    ["mcm.BgUpdate.OnOff.label"] = "Background Hotkey Bar Update",
    ["mcm.BgUpdate.OnOff.desc"] = "This option allows you to enable\\disable background updating of the hotkey bar when the player is not interacting with the bar or items bound to it.\n\n\z
    This feature may affect game performance. If background updates slow down the game, increase the update interval or disable the feature.\n\z
    If background updates are disabled, the bar will still update when interacting with slots and items.",
    ["mcm.BgUpdate.Interval.label"] = "Background Update Interval:",
    ["mcm.BgUpdate.Interval.desc"] = "This parameter determines the time interval in milliseconds between background updates of the hotkey bar.\n\z
    This value may affect game performance. If background updates slow down the game, increase the update interval or disable the feature.\n\n\z
    A game restart is required for this value to take effect.",
    ["mcm.MS"] = "ms",
    ["mcm.category1.label"] = "Hotkey Bar Settings",
    ["mcm.category1.desc"] = "Hotkey Bar Settings",
    ["mcm.HotBar.Spacing.label"] = "Slot Spacing",
    ["mcm.HotBar.Spacing.desc"] = "This parameter determines the distance between slots in the hotkey bar.\n\n\z
    Changing this parameter also affects the overall size of the hotkey bar.",
    ["mcm.HotBar.iconSize.label"] = "Icon Size",
    ["mcm.HotBar.iconSize.desc"] = "This parameter determines the size of item\\magic icons displayed in the hotkey bar.\n\n\z
    Changing this parameter also affects the overall size of the hotkey bar.",
    ["mcm.HotBar.equipBorderSize.label"] = "Equipped Item Border Size",
    ["mcm.HotBar.equipBorderSize.desc"] = "This parameter determines the size of the border for equipped items.\n\n\z
    Changing this parameter also affects the overall size of the hotkey bar.",
    ["mcm.Slot.BgAlpha.label"] = "Slot Background Alpha:",
    ["mcm.Slot.BgAlpha.desc"] = "This parameter determines the opacity of the slot background.\n\n\z
    At 0, the slot background is fully transparent.\n\z
    At 100, the slot background is fully opaque.",
    ["mcm.icon.BgAlpha.label"] = "Item Icon Background Alpha:",
    ["mcm.icon.BgAlpha.desc"] = "This parameter determines the opacity of the item icon background.\n\n\z
    At 0, the item icon background is fully transparent.\n\z
    At 100, the item icon background is fully opaque.",
    ["mcm.icon.BgTexture.label"] = "Icon Background Texture",
    ["mcm.icon.BgTexture.desc"] = "This option controls the display of the background texture for enchanted item icons.",
    ["mcm.StatusBar.OnOff.label"] = "Status Bar",
    ["mcm.StatusBar.OnOff.desc"] = "This option controls the display of the condition\\charge status bar for items.\n\n\z
    Changing this parameter also affects the overall size of the hotkey bar.",
    ["mcm.ItemCount.PosX.label"] = "Item Counter Horizontal Position:",
    ["mcm.ItemCount.PosX.desc"] = "This parameter determines the horizontal position of the item counter.",
    ["mcm.ItemCount.PosY.label"] = "Item Counter Vertical Position:",
    ["mcm.ItemCount.PosY.desc"] = "This parameter determines the vertical position of the item counter.",
    ["mcm.SlotNumber.OnOff.label"] = "Slot Number",
    ["mcm.SlotNumber.OnOff.desc"] = "This option controls the display of the slot number to which an item or magic is assigned.",
    ["mcm.SlotNumber.PosX.label"] = "Slot Number Horizontal Position:",
    ["mcm.SlotNumber.PosX.desc"] = "This parameter determines the horizontal position of slot number.",
    ["mcm.SlotNumber.PosY.label"] = "Slot Number Vertical Position:",
    ["mcm.SlotNumber.PosY.desc"] = "This parameter determines the vertical position of slot number.",
    ["mcm.effectIconCategory.label"] = "Effect Icon Settings",
    ["mcm.effectIconCategory.desc"] = "Settings for effect icons for potions, enchanted items, and scrolls.",
    ["mcm.effectIcon.Alchemy.label"] = "Effect Icons for Potions",
    ["mcm.effectIcon.Alchemy.desc"] = "This option controls the display of effect icons for potions. The icon of the first effect is displayed.",
    ["mcm.effectIcon.Scroll.label"] = "Effect Icons for Scrolls",
    ["mcm.effectIcon.Scroll.desc"] = "This option controls the display of effect icons for magic scrolls. The icon of the first effect is displayed.",
    ["mcm.effectIcon.Enchant.label"] = "Effect Icons for Enchanted Items",
    ["mcm.effectIcon.Enchant.desc"] = "This option controls the display of effect icons for enchanted items. The icon of the first effect is displayed.",
    ["mcm.effectIcon.Style.label"] = "Effect Icon Style:",
    ["mcm.effectIcon.Style.desc"] = "This parameter determines the style of effect icons.",
    ["mcm.effectIcon.Style.icon"] = "Simple",
    ["mcm.effectIcon.Style.bigIcon"] = "Detailed",
    ["mcm.effectIcon.Size.label"] = "Effect Icon Size:",
    ["mcm.effectIcon.Size.desc"] = "This parameter determines the size of the effect icon relative to the item icon.",
    ["mcm.effectIcon.PosX.label"] = "Effect Icons Horizontal Position:",
    ["mcm.effectIcon.PosX.desc"] = "This parameter determines the horizontal position of effect icons.",
    ["mcm.effectIcon.PosY.label"] = "Effect Icons Vertical Position:",
    ["mcm.effectIcon.PosY.desc"] = "This parameter determines the vertical position of effect icons.",
    --mcm HotBarExtended
    ["mcm.extendedSettings"] = "Hotkey Bar Extended",
    ["mcm.category2.label"] = "Hotkey Bar Extended Settings",
    ["mcm.category2.desc"] = "Settings for the extended hotkey bar.",
    ["mcm.HotBarExtended.OnOf.label"] = "Hotkey Bar Extended",
    ["mcm.HotBarExtended.OnOf.desc"] = "Enable\\disable the hotkey bar extended.\n\n\z
    After enabling/disabling this option, you need to restart the game!",
    ["mcm.modifierKey2.label"] = "Modifier key for hotbar 2",
    ["mcm.modifierKey2.desc"] = "Select a modifier for the hotkeys of hotbar 2.",
    ["mcm.modifierKey3.label"] = "Modifier key for hotbar 3",
    ["mcm.modifierKey3.desc"] = "Select a modifier for the hotkeys of hotbar 3.",
    ["mcm.numberVisiblePanels.label"] = "Number of Visible Panels:",
    ["mcm.numberVisiblePanels.desc"] = "This parameter determines how many hotkey bar are displayed in the game interface.\n\n\z
    Affects only the display; the hotkeys of each panel can be used regardless of panel visibility.",
    ["mcm.numberVisibleSlot.label"] = "Number of Visible Slots:",
    ["mcm.numberVisibleSlot.desc"] = "This parameter determines how many hotkey slots are displayed in the panel.\n\z
    Can be used for a more compact layout.\n\n\z
    Affects only the display; the hotkeys of each panel can be used regardless of panel visibility.",
    ["mcm.PanelsInOneLine.label"] = "Arrange panels in one line",
    ["mcm.PanelsInOneLine.desc"] = "When this option is enabled, the slots of all panels will be arranged in one line without separation into separate blocks.",
    ["mcm.miscSetting.label"] = "Miscellaneous Settings",
    ["mcm.miscSetting.desc"] = "Miscellaneous Settings",
    --hotbar
    ["HotBar1.Label"] = "Hotbar 1 (1-0)",
    ["HotBar2.Label"] = "Hotbar 2 (%{modifierKey} 1-9)",
    ["HotBar3.Label"] = "Hotbar 3 (%{modifierKey} 1-9)",
    ["HotBar.message.VanillaNotEmpty"] = "Delete all Quick Keys from the vanilla Quick Key Menu before using Hotkeys Extended",
    ["HotBar.error.EnchantBinding"] = "Unable to bind the Item. Make sure it has a Valid Enchantment. (\"Cast When Used\" or \"Cast Once\" required)",
    --mcm KeyBinding
    ["mcm.KeyBindSettings"] = "Key Binding",
    ["mcm.KeyBindCat.label"] = "Key Binding Settings",
    ["mcm.KeyBindCat.desc"] = "Key binding settings.",
    ["mcm.BindHoldClick.OnOff.label"] = "Bind by holding slot key + click",
    ["mcm.BindHoldClick.OnOff.desc"] = "This option allows you to enable\\disable binding an item\\spell by holding down a slot key (or key combination for the extended panel) and left-clicking on an item in the inventory\\spell name in the magic window.",
    ["mcm.BindMessage.OnOff.label"] = "Binding Message",
    ["mcm.BindMessage.OnOff.desc"] = "This option allows you to enable\\disable the popup message about binding an item\\spell to a hotkey slot.",
    ["mcm.TooltipCat.label"] = "Tooltip Settings",
    ["mcm.TooltipCat.desc"] = "Tooltip settings.",
    ["mcm.BindTooltip.OnOff.label"] = "Binding Information",
    ["mcm.BindTooltip.OnOff.desc"] = "This option allows you to enable\\disable the display of binding information about an item\\spell to a hotkey slot in the tooltip.",
    ["mcm.BindTooltip.Pos.label"] = "Information Display Order:",
    ["mcm.BindTooltip.Pos.desc"] = "This parameter determines where in the tooltip the line with binding information about an item\\spell to a hotkey slot will be displayed.",
    ["mcm.BindTooltip.Pos.Top"] = "Top most",
    ["mcm.BindTooltip.Pos.First"] = "First after the Item name",
    ["mcm.BindTooltip.Pos.Last"] = "Last",
    --Key binding Tooltip
    ["HotBar.BindType.Item"] = "Item",
    ["HotBar.BindType.Magic"] = "Magic",
    ["HotBar.BindText.Item"] = "[%{type} bound to slot %{slot}]",
    ["HotBar.BindText.Magic"] = "[%{type} bound to slot %{slot}]",
    ["HotBar.BindMessage.Item"] = "%{name} successfully bound to slot %{slot}",
    ["HotBar.BindMessage.Magic"] = "%{name} successfully bound to slot %{slot}",
}
return this
