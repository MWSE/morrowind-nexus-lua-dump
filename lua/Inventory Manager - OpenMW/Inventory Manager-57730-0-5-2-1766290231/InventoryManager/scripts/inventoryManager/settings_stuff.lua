local MOD_NAME = 'Inventory Manager'
local MOD_ID = 'InventoryManager'
local prefix = 'SettingsPlayer'
local sectionKey = prefix .. MOD_ID
local dataSectionKey = prefix .. MOD_ID .. '_DATA_'


local renderers = {
        checkbox = 'checkbox',
        number = 'number',
        select = 'select',
        color = 'color',
        inputBinding = 'inputBinding',
        textLine = 'textLine',
        inputRenderer = 'inputRenderer'
        -- separator = 'separator'
}

local o = {

        showWhenInventory = {
                key = 'showWhenInventory',
                name = 'Show window when opening inventory',
                default = true,
                value = true,
                renderer = renderers.checkbox,
        },


        showWindowKey = {
                key = 'showWindowKey',
                name = 'Show window key',
                default = MOD_ID,
                value = MOD_ID,
                renderer = "inputBinding",
                argument = {
                        key = 'showWindowKey_NEWKEY',
                        type = 'trigger'
                }
        },
        -- showWindowKey = {
        --         key = 'showWindowKey',
        --         name = 'Show window key',
        --         default = 'v',
        --         value = 'v',
        --         renderer = renderers.inputRenderer,
        --         argument = {},
        -- },

        listItemTextSize = {
                key = 'listItemTextSize',
                name = 'List items text size',
                description = 'default = 16',
                value = 16,
                default = 16,
                renderer = renderers.number,
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
                renderer = renderers.number,
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
                renderer = renderers.number,
                argument = {
                        min = 1,
                        integer = false,
                },


        },
        toolTipDelay = {
                key = 'toolTipDelay',
                name = 'Tooltip show delay',
                description = 'default = 0.18',
                value = 0.18,
                default = 0.18,
                renderer = renderers.number,
                argument = {
                        min = 0,
                        max = 1,
                        integer = false,
                },


        },

        listScrollAmount = {
                key = 'listScrollAmount',
                name = 'List scroll amount',
                description = 'default = 1',
                value = 1,
                default = 1,
                renderer = renderers.number,
                argument = {
                        min = 1,
                        integer = true,
                },

        },
        listAlignNumbers = {
                key = 'listAlignNumbers',
                name = 'Align numbers',
                description = 'default = Center',
                value = 'Center',
                default = 'Center',
                renderer = renderers.select,
                argument = {
                        l10n = MOD_ID,
                        items = { 'Center', 'End' },
                },

        },
        scrollDirection = {
                key = 'scrollDirection',
                name = 'List scroll direction',
                description = 'default = Reversed',
                value = 'Reversed',
                default = 'Reversed',
                renderer = renderers.select,
                argument = {
                        l10n = MOD_ID,
                        items = { 'Natural', 'Reversed' }
                },

        },
        bookPreviewLength = {
                key = 'bookPreviewLength',
                name = 'Book text preview length',
                description = 'default = 500',
                value = 500,
                default = 500,
                renderer = renderers.number,
                argument = {
                        min = 0
                },

        },
        bookPreviewWordsPerLine = {
                key = 'bookPreviewWordsPerLine',
                name = 'Book text preview words per line',
                description = 'default = 10',
                value = 10,
                default = 10,
                renderer = renderers.number,
                argument = {
                        min = 4
                },

        },

        showWhenStealing = {
                key = 'showWhenStealing',
                name = 'Ignore mode/owenership checks',
                description =
                'Will allow free taking/putting back items through the window during stealing and bartering. And will allow placing items into organic/respawning containers (ITEMS WILL BE LOST!)',
                value = false,
                default = false,
                renderer = renderers.checkbox,
        },
}





return {
        o = o,
        sectionKey = sectionKey,
        MOD_NAME = MOD_NAME,
        MOD_ID = MOD_ID,
        dataSectionKey = dataSectionKey,
}
