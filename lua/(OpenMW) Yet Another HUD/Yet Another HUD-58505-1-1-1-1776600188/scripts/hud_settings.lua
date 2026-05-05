local I        = require('openmw.interfaces')
local shared   = require('scripts.hud_shared')
local DEFAULTS = shared.DEFAULTS

I.Settings.registerPage {
    key         = 'Yet Another HUD',
    l10n        = 'YAHUD',
    name        = 'page_name',
    description = 'page_desc',
}

I.Settings.registerGroup {
    key              = 'SettingsHudToggles',
    page             = 'Yet Another HUD',
    l10n             = 'YAHUD',
    name             = 'toggles_groupName',
    permanentStorage = true,
    order            = 1,
    settings = {
        {
            key         = 'ICONS_BELOW_BARS',
            name        = 'icons_below_bars_name',
            description = 'icons_below_bars_desc',
            renderer    = 'checkbox',
            default     = DEFAULTS.ICONS_BELOW_BARS,
        },
        {
            key         = 'SHOW_ENEMY_FATIGUE',
            name        = 'show_enemy_fatigue_name',
            description = 'show_enemy_fatigue_desc',
            renderer    = 'checkbox',
            default     = DEFAULTS.SHOW_ENEMY_FATIGUE,
        },
        {
            key         = 'SHOW_ENCUMBRANCE',
            name        = 'show_encumbrance_name',
            description = 'show_encumbrance_desc',
            renderer    = 'checkbox',
            default     = DEFAULTS.SHOW_ENCUMBRANCE,
        },
    }
}

I.Settings.registerGroup {
    key              = 'SettingsHudColors',
    page             = 'Yet Another HUD',
    l10n             = 'YAHUD',
    name             = 'colors_groupName',
    description      = 'colors_groupDesc',
    permanentStorage = true,
    order            = 2,
    settings = {
        {
            key         = 'COLOR_HP_R',
            name        = 'color_hp_r_name',
            description = 'color_hp_r_desc',
            renderer    = 'number',
            default     = DEFAULTS.COLOR_HP_R,
            argument    = { min = 0, max = 1 },
        },
        {
            key         = 'COLOR_HP_G',
            name        = 'color_hp_g_name',
            description = 'color_hp_g_desc',
            renderer    = 'number',
            default     = DEFAULTS.COLOR_HP_G,
            argument    = { min = 0, max = 1 },
        },
        {
            key         = 'COLOR_HP_B',
            name        = 'color_hp_b_name',
            description = 'color_hp_b_desc',
            renderer    = 'number',
            default     = DEFAULTS.COLOR_HP_B,
            argument    = { min = 0, max = 1 },
        },
        {
            key         = 'COLOR_MAGICKA_R',
            name        = 'color_magicka_r_name',
            description = 'color_magicka_r_desc',
            renderer    = 'number',
            default     = DEFAULTS.COLOR_MAGICKA_R,
            argument    = { min = 0, max = 1 },
        },
        {
            key         = 'COLOR_MAGICKA_G',
            name        = 'color_magicka_g_name',
            description = 'color_magicka_g_desc',
            renderer    = 'number',
            default     = DEFAULTS.COLOR_MAGICKA_G,
            argument    = { min = 0, max = 1 },
        },
        {
            key         = 'COLOR_MAGICKA_B',
            name        = 'color_magicka_b_name',
            description = 'color_magicka_b_desc',
            renderer    = 'number',
            default     = DEFAULTS.COLOR_MAGICKA_B,
            argument    = { min = 0, max = 1 },
        },
        {
            key         = 'COLOR_FATIGUE_R',
            name        = 'color_fatigue_r_name',
            description = 'color_fatigue_r_desc',
            renderer    = 'number',
            default     = DEFAULTS.COLOR_FATIGUE_R,
            argument    = { min = 0, max = 1 },
        },
        {
            key         = 'COLOR_FATIGUE_G',
            name        = 'color_fatigue_g_name',
            description = 'color_fatigue_g_desc',
            renderer    = 'number',
            default     = DEFAULTS.COLOR_FATIGUE_G,
            argument    = { min = 0, max = 1 },
        },
        {
            key         = 'COLOR_FATIGUE_B',
            name        = 'color_fatigue_b_name',
            description = 'color_fatigue_b_desc',
            renderer    = 'number',
            default     = DEFAULTS.COLOR_FATIGUE_B,
            argument    = { min = 0, max = 1 },
        },
        {
            key         = 'COLOR_ENEMY_FATIGUE_R',
            name        = 'color_enemy_fatigue_r_name',
            description = 'color_enemy_fatigue_r_desc',
            renderer    = 'number',
            default     = DEFAULTS.COLOR_ENEMY_FATIGUE_R,
            argument    = { min = 0, max = 1 },
        },
        {
            key         = 'COLOR_ENEMY_FATIGUE_G',
            name        = 'color_enemy_fatigue_g_name',
            description = 'color_enemy_fatigue_g_desc',
            renderer    = 'number',
            default     = DEFAULTS.COLOR_ENEMY_FATIGUE_G,
            argument    = { min = 0, max = 1 },
        },
        {
            key         = 'COLOR_ENEMY_FATIGUE_B',
            name        = 'color_enemy_fatigue_b_name',
            description = 'color_enemy_fatigue_b_desc',
            renderer    = 'number',
            default     = DEFAULTS.COLOR_ENEMY_FATIGUE_B,
            argument    = { min = 0, max = 1 },
        },
        {
            key         = 'COLOR_ENCUMBRANCE_R',
            name        = 'color_encumbrance_r_name',
            description = 'color_encumbrance_r_desc',
            renderer    = 'number',
            default     = DEFAULTS.COLOR_ENCUMBRANCE_R,
            argument    = { min = 0, max = 1 },
        },
        {
            key         = 'COLOR_ENCUMBRANCE_G',
            name        = 'color_encumbrance_g_name',
            description = 'color_encumbrance_g_desc',
            renderer    = 'number',
            default     = DEFAULTS.COLOR_ENCUMBRANCE_G,
            argument    = { min = 0, max = 1 },
        },
        {
            key         = 'COLOR_ENCUMBRANCE_B',
            name        = 'color_encumbrance_b_name',
            description = 'color_encumbrance_b_desc',
            renderer    = 'number',
            default     = DEFAULTS.COLOR_ENCUMBRANCE_B,
            argument    = { min = 0, max = 1 },
        },
    }
}
