local I     = require('openmw.interfaces')

I.Settings.registerPage({
    key         = 'FASHIONWINDCOMP',
    l10n        = 'Fashionwind',
    name        = 'Fashionwind Compilation',
    description = 'Settings to toggle and change glasses, masks, scarves and backpacks',
})

I.Settings.registerGroup({
    key              = 'Settings_tt_FashionMA',
    page             = 'FASHIONWINDCOMP',
    l10n             = 'Fashionwind',
    name             = 'Masks settings',
    permanentStorage = true,
    settings = {
        {
            key      = 'MASKBUFFS',
            name     = 'Enable mask buffs',
            default  = false,
            renderer = 'checkbox',
        },
    },
})

I.Settings.registerGroup({
    key              = 'Settings_tt_fashionwind_scarves_ui',
    page             = 'FASHIONWINDCOMP',
    l10n             = 'Fashionwind',
    name             = 'Scarves settings',
    permanentStorage = true,
    settings = {
        {
            key      = 'SKARFBUFFS',
            name     = 'Enable skarf buffs',
            default  = false,
            renderer = 'checkbox',
        },
    },
})

I.Settings.registerGroup({
    key              = 'Settings_tt_fashionwindHG',
    page             = 'FASHIONWINDCOMP',
    l10n             = 'Fashionwind',
    name             = 'Circlets settings',
    permanentStorage = true,
    settings = {
        {
            key      = 'HGBUFFS',
            name     = 'Enable Circlets buffs',
            default  = false,
            renderer = 'checkbox',
        },
    },
})

I.Settings.registerGroup({
    key              = 'Settings_tt_fashionwindANTL',
    page             = 'FASHIONWINDCOMP',
    l10n             = 'Fashionwind',
    name             = 'Horns settings',
    permanentStorage = true,
    settings = {
        {
            key      = 'HORBUFFS',
            name     = 'Enable Horns buffs',
            default  = false,
            renderer = 'checkbox',
        },
    },
})

I.Settings.registerGroup({
    key              = 'Settings_tt_fashionwindEAR',
    page             = 'FASHIONWINDCOMP',
    l10n             = 'Fashionwind',
    name             = 'Earrings settings',
    permanentStorage = true,
    settings = {
        {
            key      = 'EARBUFFS',
            name     = 'Enable Earrings buffs',
            default  = false,
            renderer = 'checkbox',
        },
    },
})

return
