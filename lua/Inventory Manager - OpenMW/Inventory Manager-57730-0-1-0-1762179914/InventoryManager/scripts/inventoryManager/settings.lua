local I = require('openmw.interfaces')

local MOD_NAME = 'InventoryManager'
local prefix = 'SettingsPlayer'
local sectionKey = prefix .. MOD_NAME


local o = {
        listItemTextSize = {
                key = 'listItemTextSize',
                name = 'List items text size',
                description = 'default = 16',
                value = 16,
                default = 16,
                argument = {
                        min = 1,
                        integer = false,
                },
        },
        labelsSize = {
                key = 'labelsSize',
                name = 'Labels/Headers Size',
                description = 'default = 16',
                value = 16,
                default = 16,
                argument = {
                        min = 1,
                        integer = false,
                },
        },
        toolTipTextSize = {
                key = 'toolTipTextSize',
                name = 'Tooltip text size',
                description = 'default = 16',
                value = 16,
                default = 16,
                argument = {
                        min = 1,
                        integer = false,
                },
        },
        listScrollAmount = {
                key = 'listScrollAmount',
                name = 'List scroll amount',
                description = 'default = 1',
                value = 1,
                default = 1,
                argument = {
                        min = 1,
                        integer = true,
                },
        },
}



I.Settings.registerPage {
        key = MOD_NAME,
        l10n = MOD_NAME,
        name = MOD_NAME,
        description = "Inventory Manager"
}

I.Settings.registerGroup {
        key = sectionKey,
        l10n = MOD_NAME,
        name = MOD_NAME,
        page = MOD_NAME,
        permanentStorage = true,
        settings = {
                {
                        key = o.listItemTextSize.key,
                        name = o.listItemTextSize.name,
                        default = o.listItemTextSize.default,
                        description = o.listItemTextSize.description,
                        argument = o.listItemTextSize.argument,
                        renderer = "number",
                },
                {
                        key = o.labelsSize.key,
                        name = o.labelsSize.name,
                        default = o.labelsSize.default,
                        description = o.labelsSize.description,
                        argument = o.labelsSize.argument,
                        renderer = "number",
                },
                {
                        key = o.toolTipTextSize.key,
                        name = o.toolTipTextSize.name,
                        default = o.toolTipTextSize.default,
                        description = o.toolTipTextSize.description,
                        argument = o.toolTipTextSize.argument,
                        renderer = "number",
                },
                {
                        key = o.listScrollAmount.key,
                        name = o.listScrollAmount.name,
                        default = o.listScrollAmount.default,
                        description = o.listScrollAmount.description,
                        argument = o.listScrollAmount.argument,
                        renderer = "number",
                },
        }

}



return {
        o = o,
        sectionKey = sectionKey
}
