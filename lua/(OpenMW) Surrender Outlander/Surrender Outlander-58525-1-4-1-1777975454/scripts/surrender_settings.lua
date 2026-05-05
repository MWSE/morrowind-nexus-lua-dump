local I      = require('openmw.interfaces')
local input  = require('openmw.input') 
local shared = require('scripts.surrender_shared')
local D      = shared.DEFAULTS

input.registerTrigger {
    key  = 'SurrenderThrowGold',
    l10n = 'SurrenderOutlander',
}

I.Settings.registerGroup {
    key              = 'SettingsSurrender',
    page             = 'SurrenderOutlander',
    l10n             = 'SurrenderOutlander',
    name             = 'group_general_name',
    permanentStorage = true,
    order            = 1,
    settings = {
        {
            key = 'MOD_ENABLED',
            renderer = 'checkbox',
            name = 'mod_enabled_name', 
            description = 'mod_enabled_desc', 
            default = D.MOD_ENABLED
        },
        {
            key         = 'SURRENDER_TO_GUARDS',
            name        = 'surrender_to_guards_name',
            description = 'surrender_to_guards_desc',
            renderer    = 'checkbox',
            default     = D.SURRENDER_TO_GUARDS,
        },
        {
            key      = 'GUARD_RADIUS',
            renderer = 'number',
            name     = 'guard_radius_name',
            description = 'guard_radius_desc',
            default  = D.GUARD_RADIUS,
            argument = { integer = true, min = 200, max = 600 }
        },
        {
            key = 'MIN_GOLD',
            renderer = 'number',
            name = 'min_gold_name',
            description = 'min_gold_desc',
            default = D.MIN_GOLD,
            argument = {integer = true, min = 1, max = 10000}
        },
        {
            key = 'CEASEFIRE',
            renderer = 'number',
            name = 'ceasefire_name',
            description = 'ceasefire_desc',
            default = D.CEASEFIRE,
            argument = {integer = true,min = 1, max = 300}
        },
        {
            key = 'BRIBE_RADIUS',
            renderer = 'number',
            name = 'bribe_radius_name',
            description = 'bribe_radius_desc',
            default = D.BRIBE_RADIUS,
            argument = {integer= true, min = 50, max = 2000}
        },
        {
            key = 'CLASS_CEASEFIRE',
            renderer = 'checkbox',
            name = 'class_ceasefire_name',
            description = 'class_ceasefire_desc',
            default = D.CLASS_CEASEFIRE
        },
        {
            key = 'THROW_GOLD_AMOUNT',
            renderer = 'number',
            name = 'throw_gold_amount_name',
            description = 'throw_gold_amount_desc',
            default = D.THROW_GOLD_AMOUNT,
            argument = { integer = true, min = 1, max = 10000}
        },
        {
            key         = 'USE_PHYSICS',
            name        = 'enable_lua_physics_name',
            description = 'enable_lua_physics_desc',
            renderer    = 'checkbox',
            default     = D.USE_PHYSICS,
        },
        {
            key         = 'LOG',
            renderer    = 'checkbox',
            name        = 'log_name',
            description = 'log_desc',
            default     = D.LOG,
        },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsSurrenderInput',
    page             = 'SurrenderOutlander',
    l10n             = 'SurrenderOutlander',
    name             = 'group_input_name',
    permanentStorage = true,
    order            = 2,
    settings = {
        {
            key         = 'THROW_GOLD_KEY',
            renderer    = 'inputBinding',
            name        = 'throw_gold_key_name',
            description = 'throw_gold_key_desc',
            default     = 'surrender_throw_gold_binding',
            argument    = {
                type = 'trigger',
                key  = 'SurrenderThrowGold',
            },
        },
    },
}