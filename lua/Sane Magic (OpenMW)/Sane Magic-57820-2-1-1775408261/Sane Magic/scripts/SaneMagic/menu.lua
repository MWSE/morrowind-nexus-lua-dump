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
        key = 'smFortifyPerson',
        name = 'smFortifyPersonName',
        description = 'smFortifyPersonDesc',
        default = true,
        renderer = 'checkbox'
    },    
    { 
        key = 'smFortifyPersonPotions',
        name = 'smFortifyPersonPotionsName',
        description = 'smFortifyPersonPotionsDesc',
        default = true,
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
        default = false,
        renderer = 'checkbox'
    },
    { 
        key = 'smChameleon',
        name = 'smChameleonName',
        description = 'smChameleonDesc',
        default = false,
        renderer = 'checkbox'
    },
    { 
        key = 'smSaneMagicCap',
        name = 'smSaneMagicCapName',
        description = 'smSaneMagicCapDesc',
        default = "Lax",
        argument = {
            l10n = 'SaneMagic',
            items = {"OnlySpells", "Strict", "Lax", "Disabled"}
        },
        renderer = 'select'
    }, 
    { 
        key = 'sm100Unlimit',
        name = 'sm100UnlimitName',
        description = 'sm100UnlimitDesc',
        default = true,
        renderer = 'checkbox'
    },   
    { 
        key = 'smSuspiciousEffect',
        name = 'smSuspciousEffectName',
        description = 'smSuspciousEffectDesc',
        default = true,
        renderer = 'checkbox'
    },       
   {
        key = 'smQuickKeyCompatible',
        name = 'smQuickKeyCompatibleName',
	    description = 'smQuickKeyCompatibleDesc',
        default = "None",

        argument = {
            l10n = 'SaneMagic',
            items = {"None", "ZerkishHotbar", "QuickCast"}
        },
        renderer = 'select'
   
    }, 
}
}
