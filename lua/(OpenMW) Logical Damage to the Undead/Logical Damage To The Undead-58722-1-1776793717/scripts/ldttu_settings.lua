local I = require('openmw.interfaces')
local shared = require('scripts.ldttu_shared')
local DEFAULTS = shared.DEFAULTS

I.Settings.registerPage {
    key = 'LDTTU',
    l10n = 'LDTTU',
    name = 'page_name',
    description = 'page_desc',
}

I.Settings.registerGroup {
    key = 'SettingsLDTTU',
    page = 'LDTTU',
    l10n = 'LDTTU',
    name = 'settings_group_name',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'MOD_ENABLED',
            name = 'mod_enabled_name',
            description = 'mod_enabled_desc',
            renderer = 'checkbox',
            default = DEFAULTS.MOD_ENABLED,
        },
        {
            key = 'DEBUG_LOGGING',
            name = 'debug_logging_name',
            description = 'debug_logging_desc',
            renderer = 'checkbox',
            default = DEFAULTS.DEBUG_LOGGING,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsLDTTU_Ghosts',
    page = 'LDTTU',
    l10n = 'LDTTU',
    name = 'ghost_group_name',
    description = 'ghost_group_desc',
    permanentStorage = true,
    order = 2,
    settings = {
        {
            key = 'GHOST_BLADE_MULT',
            name = 'ghost_blade_mult_name',
            description = 'ghost_blade_mult_desc',
            renderer = 'number',
            default = DEFAULTS.GHOST_BLADE_MULT,
            argument = { min = 1.0, max = 5.0 },
        },
        {
            key = 'GHOST_HEAVY_MULT',
            name = 'ghost_heavy_mult_name',
            description = 'ghost_heavy_mult_desc',
            renderer = 'number',
            default = DEFAULTS.GHOST_HEAVY_MULT,
            argument = { min = 0.01, max = 1.0 },
        },
        {
            key = 'GHOST_MARKSMAN_MULT',
            name = 'ghost_marksman_mult_name',
            description = 'ghost_marksman_mult_desc',
            renderer = 'number',
            default = DEFAULTS.GHOST_MARKSMAN_MULT,
            argument = { min = 0.01, max = 1.0 },
        },
        {
            key = 'GHOST_H2H_MULT',
            name = 'ghost_h2h_mult_name',
            description = 'ghost_h2h_mult_desc',
            renderer = 'number',
            default = DEFAULTS.GHOST_H2H_MULT,
            argument = { min = 0.01, max = 1.0 },
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsLDTTU_Physical',
    page = 'LDTTU',
    l10n = 'LDTTU',
    name = 'physical_group_name',
    description = 'physical_group_desc',
    permanentStorage = true,
    order = 3,
    settings = {
        {
            key = 'PHYS_BLUNT_AXE_MULT',
            name = 'phys_blunt_axe_mult_name',
            description = 'phys_blunt_axe_mult_desc',
            renderer = 'number',
            default = DEFAULTS.PHYS_BLUNT_AXE_MULT,
            argument = { min = 1.0, max = 5.0 },
        },
        {
            key = 'PHYS_BLADE_MULT',
            name = 'phys_blade_mult_name',
            description = 'phys_blade_mult_desc',
            renderer = 'number',
            default = DEFAULTS.PHYS_BLADE_MULT,
            argument = { min = 0.01, max = 1.0 },
        },
        {
            key = 'PHYS_SPEAR_MULT',
            name = 'phys_spear_mult_name',
            description = 'phys_spear_mult_desc',
            renderer = 'number',
            default = DEFAULTS.PHYS_SPEAR_MULT,
            argument = { min = 0.01, max = 1.0 },
        },
        {
            key = 'PHYS_MARKSMAN_MULT',
            name = 'phys_marksman_mult_name',
            description = 'phys_marksman_mult_desc',
            renderer = 'number',
            default = DEFAULTS.PHYS_MARKSMAN_MULT,
            argument = { min = 0.01, max = 1.0 },
        },
        {
            key = 'PHYS_H2H_MULT',
            name = 'phys_h2h_mult_name',
            description = 'phys_h2h_mult_desc',
            renderer = 'number',
            default = DEFAULTS.PHYS_H2H_MULT,
            argument = { min = 0.01, max = 1.0 },
        },
    }
}