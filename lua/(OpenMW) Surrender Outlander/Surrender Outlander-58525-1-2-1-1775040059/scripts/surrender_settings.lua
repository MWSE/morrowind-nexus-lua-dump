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
        { key='MOD_ENABLED',  renderer='checkbox', name='mod_enabled_name',  description='mod_enabled_desc',  default=D.MOD_ENABLED },
        { key='MIN_GOLD',     renderer='number',   name='min_gold_name',     description='min_gold_desc',     default=D.MIN_GOLD,     argument={integer=true, min=1, max=10000} },
        { key='CEASEFIRE',    renderer='number',   name='ceasefire_name',    description='ceasefire_desc',    default=D.CEASEFIRE,    argument={integer=true, min=1, max=300} },
        { key='BRIBE_RADIUS',    renderer='number',   name='bribe_radius_name',    description='bribe_radius_desc',    default=D.BRIBE_RADIUS,    argument={integer=true, min=50, max=2000} },
        { key='CLASS_CEASEFIRE', renderer='checkbox', name='class_ceasefire_name', description='class_ceasefire_desc', default=D.CLASS_CEASEFIRE },
        { key='THROW_GOLD_AMOUNT', renderer='number', name='throw_gold_amount_name', description='throw_gold_amount_desc', default=D.THROW_GOLD_AMOUNT, argument={integer=true, min=1, max=10000} },
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
            default     = '',
            argument    = {
                type = 'trigger',
                key  = 'SurrenderThrowGold',
            },
        },
    },
}