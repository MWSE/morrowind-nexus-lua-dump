local I       = require('openmw.interfaces')
local storage = require('openmw.storage')
local async   = require('openmw.async')

local MODNAME = 'MakeAProfit'

local Settings = {}

Settings.templates = {}

Settings.templates.PRICING = {
    key = 'Settings'..MODNAME..'PRICING',
    page = MODNAME..'MAIN',
    l10n = 'none',
    name = 'Toggles', -- 'Gold Display',
    description = 'Enable and Disable features here. Requires reload to take effect.',
    permanentStorage = true,
    order = 0,
    settings = {
		-- {
        --     key = 'DEBUG',
        --     name = 'Debug Mode',
        --     description = 'Lots of prints',
        --     renderer = 'checkbox',
        --     default = true,
        -- },
        {
            key = 'S_SHOW_MESSAGES',
            name = 'Show Notification Messages',
            description = 'Show mod notification popups such for unlocking new merc skills.',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'S_ENABLE_INVESTMENT',
            name = 'Enable Investment',
            description = "Allows spending gold to boost a merchant's barter gold permanently.\n\nIf Inventory Extender is installed, this appears as a button on the barter UI.",
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'S_INVESTMENT_THRESHOLD',
            name = 'Investment Threshold',
            description = 'Mercantile skill level required before you can invest.\nSet to 0 to always allow investment.',
            renderer = 'number',
            default = 25,
            argument = { integer = true, min = 0, max = 500 },
        },
        {
            key = 'S_INVEST_CREATURES',
            name = 'Creeper and Mudcrab Merchant too?',
            description = "The creatures of Vvardenfell deserve some love too. Also applies to other creature merchants.\n\nNote that creatures have no disposition so you won't get any bonuses there.",
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'S_INVEST_EFFICIENCY',
            name = 'Investment Efficiency (%)',
            description = "Percentage of invested gold that becomes the merchant's barter gold increase.\nLower values make investment less efficient; the rest is treated as taxes and fees.\nApplied retroactively to past investments.",
            renderer = 'number',
            default = 100,
            argument = { integer = true, min = 1, max = 100 },
        },
        {
            key = 'S_ENABLE_SERVICE_HAGGLE',
            name = 'Enable Service Haggling',
            description = "When you purchase an NPC service there is a chance to refund some of the cost.\n\n\nI recommend playing with mods that increase costs from GMSTs which isn't included in this mod so that service prices are actually meaningful",
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'S_SERVICE_CRIT_DISCOUNT',
            name = 'Critical Success Discount',
            description = 'Percentage of the cost refunded when you perfectly haggle for a service',
            renderer = 'number',
            default = 50,
            argument = { integer = true, min = 1, max = 1000 },
        },
        {
            key = 'S_SERVICE_DISCOUNT',
            name = 'Normal Success Discount (%)',
            description = 'Percentage of the cost refunded when you successfully haggle for a service',
            renderer = 'number',
            default = 25,
            argument = { integer = true, min = 1, max = 1000 },
        },
        {
            key = 'S_SKILL_THRESHOLD',
            name = 'Obscure Item Value',
            description = 'Item values are obscured below this Mercantile skill level.\n\nRequires Inventory Extender',
            renderer = 'number',
            default = 15,
            argument = { integer = true, min = 0, max = 300 },
        },
        {
            key = 'S_KNOWS_SPECIALIZATION',
            name = 'Specialization Knowledge Threshold',
            description = 'Merchants offer better prices on items matching their trade.\nMercantile skill level needed before specialization\nbonuses apply and show in tooltips.\nSet to 0 to always show.\n\nRequires Inventory Extender',
            renderer = 'number',
            default = 35,
            argument = { integer = true, min = 0, max = 300 },
        },
        {
            key = 'S_ENABLE_SELL_ANYTHING',
            name = 'Enable Sell Anything',
            description = 'Trade any item when your mercantile skill is high enough,\nbypassing merchant service restrictions.\n\nRequires Inventory Extender',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'S_SELL_ANYTHING_THRESHOLD',
            name = 'Sell Anything skill',
            description = 'Mercantile skill level needed to trade any item.\nSet to 0 to always allow.\n\nRequires Inventory Extender',
            renderer = 'number',
            default = 100,
            argument = { integer = true, min = 0, max = 1000 },
        },
        {
            key = 'S_ENABLE_PAWNBROKER',
            name = 'Pawnbroker Rules',
            description = 'Pawnbrokers will only buy and sell weapons and armor that are damaged.\n\nRequires Inventory Extender',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'S_ENABLE_CONTRABAND',
            name = 'Hide Contraband in Barter (Experimental)', -- Skooma, moon sugar, raw ebony, raw glass, and dwemer artifacts per lore.
            description = 'Prevents you from offering contraband to law-abiding merchants.\nIllicit traders (smugglers, Thieves Guild, Camonna Tong) still accept it.\n\nRequires Inventory Extender.',
            renderer = 'checkbox',
            default = false,
        },
    },
}

Settings.templates.CATEGORIES = {
    key = 'Settings'..MODNAME..'CATEGORIES',
    page = MODNAME..'MAIN',
    l10n = 'none',
    name = 'UI and Display Settings.',
    description = "Filtering, Tooltip and other display settings. Requires Ralts' Inventory Extender.",
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'S_ENABLE_CATEGORY_HIDING',
            name = 'Hide Irrelevant Categories',
            description = 'Hides categories for items the merchant does not buy or sell.',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'S_HIDDEN_TEXT',
            name = 'Obscured Item Value Text',
            description = "Text shown in place of an item's value when your Mercantile is too low.\n",
            renderer = 'textLine',
            default = '???',
        },
        {
            key = 'S_EXPORT_LINE',
            name = 'Display tooltip for regional item modifiers',
            description = 'Appears like "Regional import (+25%)"',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'S_SPEC_LINE',
            name = 'Show prices for merchant specializations',
            description = 'Display tooltip for merchant specializations, like "Smith specialty (-10%)".',
            renderer = 'checkbox',
            default = true,
        },		
    },
}

Settings.templates.REGIONS = {
    key = 'Settings'..MODNAME..'REGIONS',
    page = MODNAME..'MAIN',
    l10n = 'none',
    name = 'Regional Pricing',
    description = "Supply and demand pricing varies by region.\nRequires Inventory Extender and Sun's Dusk.",
    permanentStorage = true,
    order = 2,
    settings = {
        {
            key = 'S_SD_MODIFIER',
            name = 'Supply and Demand Modifier',
            description = '% price adjustment for regional imports and exports.\nExports are cheaper when bought and sold, imports are more expensive.\nSet to 0 to disable regional pricing.',
            renderer = 'number',
            default = 25,
            argument = { integer = true, min = 0, max = 100 },
        },
        {
            key = 'S_KNOWS_EXPORT',
            name = 'Export Knowledge Threshold',
            description = 'Mercantile skill level needed to see and benefit from\nexport/import pricing advantages when trading.',
            renderer = 'number',
            default = 40,
            argument = { integer = true, min = 0, max = 300 },
        },
    },
}

Settings.templates.OTHER = {
    key = 'Settings'..MODNAME..'OTHER',
    page = MODNAME..'MAIN',
    l10n = 'none',
    name = 'Other',
    description = "Settings that couldn't fit anywhere else",
    permanentStorage = true,
    order = 3,
    settings = {
        {
            key = 'S_ENABLE_DROP_TELEKINESIS',
            name = 'Telekinesis While Dragging',
            description = 'Temporarily grants a telekinesis effect while placing an item out of your inventory,\nletting you drop it further away without closing the window.',
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'S_DROP_TELEKINESIS_RANGE',
            name = 'Drag Telekinesis Range',
            description = 'Extra range added while dragging.\nVanilla reach is around 192 units.',
            renderer = 'number',
            default = 100,
            argument = { integer = true, min = 0, max = 2000 },
        },
    },
}

function Settings.init()
    I.Settings.registerPage {
        key = MODNAME..'MAIN',
        l10n = 'none',
        name = 'Make A Profit',
        description = 'Trade overhaul for Mercantile skill.',
    }
	
    for _, template in pairs(Settings.templates) do
        I.Settings.registerGroup(template)
        local sect = storage.playerSection(template.key)
        for _, entry in pairs(template.settings) do
			local val = sect:get(entry.key)
			if val == nil then val = entry.default end
            _G[entry.key] = val
        end
        sect:subscribe(async:callback(function(_, setting)
            _G[setting] = sect:get(setting)
        end))
    end
end

return Settings