local I = require('openmw.interfaces')
local async = require('openmw.async')
local input = require('openmw.input')
local ui = require('openmw.ui')
local core = require('openmw.core')

local version = '1.1'

I.Settings.registerPage {
    key = 'SaneMagic',
    l10n = 'SaneMagic',
    name = 'SaneMagic',
    description = "settings_description"
}

I.Settings.registerGroup {
    key = 'SettingsPlayerSaneMagic',
    page = 'SaneMagic',
    l10n = 'SaneMagic',
    name = 'SaneMagicName',
    description = '',
    permanentStorage = true,
    settings = { 
        {
        key = 'smMessage',
        name = 'smMessageName',
        description = 'smMessageDesc',
        default = true,
        renderer = 'checkbox'
    },
        {
        key = 'smSummon',
        name = 'smSummonName',
        description = 'smSummonDesc',
        default = true,
        renderer = 'checkbox'
    },
    { 
        key = 'smFrenzyCrime',
        name = 'smFrenzyCrimeName',
        description = 'smFrenzyCrimeDesc',
        default = true,
        renderer = 'checkbox'
    },
    { 
        key = 'smFrenzySneakLimit',
        name = 'smFrenzySneakLimitName',
        description = 'smFrenzySneakLimitDesc',
        default = false,
        renderer = 'checkbox'
    },
    { 
        key = 'smFortifyPerson',
        name = 'smFortifyPersonName',
        description = 'smFortifyPersonDesc',
        default = true,
        renderer = 'checkbox'
    },    
    { 
        key = 'smFortifyPersonMaxPerosonFix',
        name = 'smFortifyPersonMaxPerosonFixName',
        description = 'smFortifyPersonMaxPerosonFixDesc',
        default = false,
        renderer = 'checkbox'
    },
    { 
        key = 'smCharm',
        name = 'smCharmName',
        description = 'smCharmDesc',
        default = true,
        renderer = 'checkbox'
    },
    { 
        key = 'smOpen',
        name = 'smOpenName',
        description = 'smOpenDesc',
        default = true,
        renderer = 'checkbox'
    },
    { 
        key = 'smChameleon',
        name = 'smChameleonName',
        description = 'smChameleonDesc',
        default = true,
        renderer = 'checkbox'
    },
}
}
