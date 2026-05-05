local M = {}

M.DEFAULTS = {
    -- Shared HP color (player and enemy)
    COLOR_HP_R = 0.75,
    COLOR_HP_G = 0.05,
    COLOR_HP_B = 0.15,

    -- Player fatigue color
    COLOR_FATIGUE_R = 0.15,
    COLOR_FATIGUE_G = 0.65,
    COLOR_FATIGUE_B = 0.15,

    -- Enemy fatigue color
    COLOR_ENEMY_FATIGUE_R = 0.85,
    COLOR_ENEMY_FATIGUE_G = 0.75,
    COLOR_ENEMY_FATIGUE_B = 0.30,

    -- Magicka color
    COLOR_MAGICKA_R = 0.10,
    COLOR_MAGICKA_G = 0.25,
    COLOR_MAGICKA_B = 0.80,

    -- Encumbrance color
    COLOR_ENCUMBRANCE_R = 0.70,
    COLOR_ENCUMBRANCE_G = 0.60,
    COLOR_ENCUMBRANCE_B = 0.40,

    -- Toggles
    SHOW_ENEMY_FATIGUE = false,
    SHOW_ENCUMBRANCE   = false,
    ICONS_BELOW_BARS   = false,
}

return M
