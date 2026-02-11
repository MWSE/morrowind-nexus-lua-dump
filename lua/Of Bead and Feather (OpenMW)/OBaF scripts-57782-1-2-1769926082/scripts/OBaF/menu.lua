local I = require('openmw.interfaces')
local async = require('openmw.async')
local input = require('openmw.input')
local ui = require('openmw.ui')
local core = require('openmw.core')

local version = '1.1'

I.Settings.registerPage {
    key = 'OBaF',
    l10n = 'OBaF',
    name = 'OBaF',
    description = "settings_description"
}

I.Settings.registerGroup {
    key = 'SettingsPlayerOBaF',
    page = 'OBaF',
    l10n = 'OBaF',
    name = 'OBaFName',
    description = 'OBaFDesc',
    permanentStorage = true,
    settings = {{
        key = 'obafVariant',
        name = 'obafVariantName',
        default = "variant2",

        argument = {
            l10n = 'OBaF',
            items = {"variant1", "variant2", "variant3"}
        },
        renderer = 'select'
    }, {
        key = 'obafChangePrice',
        name = 'obafChangePriceName',
        default = true,
        renderer = 'checkbox'
    }, {
        key = 'obafReplaceName',
        name = 'obafReplaceNameName',
        description = 'obafReplaceNameDesc',
        default = true,
        renderer = 'checkbox'
    }, {
        key = 'obafCache',
        name = 'obafCacheName',
        description = "obafCacheDesc",
        default = false,
        renderer = 'checkbox'
    }}
}
