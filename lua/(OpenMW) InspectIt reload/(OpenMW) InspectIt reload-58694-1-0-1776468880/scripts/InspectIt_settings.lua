local I     = require('openmw.interfaces')
local input = require('openmw.input')

I.Settings.registerPage({
    key = "InspectIt",
    l10n = "InspectIt",
    name = "InspectIt mod",
    description = "Settings of Inspect items mod",
})

input.registerAction({
    key  = 'inspectItemAction',
    type = input.ACTION_TYPE.Boolean,
    l10n = 'InspectIt',
    name = 'Inspect Item',
    description = 'Use this action to inspect item',
    defaultValue = false,
})

input.registerAction({
    key = 'DetailItemAction',
    type = input.ACTION_TYPE.Boolean,
    l10n = 'InspectIt',
    name = 'Inspect Details',
    description = 'Use this action to Inspect Details',
    defaultValue = false,
})

input.registerAction({
    key = 'InventoryInspectAction',
    type = input.ACTION_TYPE.Boolean,
    l10n = 'InspectIt',
    name = 'Inspect inventory',
    description = 'Use this action to Inspect inventory items',
    defaultValue = false,
})

input.registerAction({
    key = 'InventoryInspectSelectNext',
    type = input.ACTION_TYPE.Boolean,
    l10n = 'InspectIt',
    name = 'Next item',
    description = 'Use this action to select next item',
    defaultValue = false,
})

input.registerAction({
    key = 'InventoryInspectSelectPrev',
    type = input.ACTION_TYPE.Boolean,
    l10n = 'InspectIt',
    name = 'Previous item',
    description = 'Use this action to select previous item',
    defaultValue = false,
})


I.Settings.registerGroup({
    key = "Settings_tt_InspectIT",
    page = "InspectIt",
    l10n = "InspectIt",
    name = "InspectIt settings",
    permanentStorage = true,
    settings = {
        {
            key = 'INIT_FreezeTimeDefault',
            renderer = 'checkbox',
            name = 'Freeze Time Automatically',
            description = 'Freeze time when inspecting',
            default = true
        },
        {
            key      = "inspectItemAction", 
            renderer = 'inputBinding',
            name     = 'choose inspect key',
            description = 'key to inspect items',
            default  = 'Y',  
            argument = { type = "action", key = 'inspectItemAction' },
        },
        {
            key = "DetailItemAction",
            renderer = 'inputBinding',
            name = 'Choose Inspect Details key',
            description = 'Key to Inspect Details',
            default = 'U',
            argument = { type = "action", key = 'DetailItemAction' },
        },		
		{
            key = "InventoryInspectAction",
            renderer = 'inputBinding',
            name = 'Inspect inventory',
            description = 'Key to Inspect inventory',
            default = 'P',
            argument = { type = "action", key = 'InventoryInspectAction' },
        },		
		{
            key = "InventoryInspectSelectNext",
            renderer = 'inputBinding',
            name = 'Next item',
            description = 'Key to Inspect Next item',
            default = '>',
            argument = { type = "action", key = 'InventoryInspectSelectNext' },
        },	
		{
            key = "InventoryInspectSelectPrev",
            renderer = 'inputBinding',
            name = 'Previous item',
            description = 'Key to Inspect Previous item',
            default = '<',
            argument = { type = "action", key = 'InventoryInspectSelectPrev' },
        },	
    },
})

return
