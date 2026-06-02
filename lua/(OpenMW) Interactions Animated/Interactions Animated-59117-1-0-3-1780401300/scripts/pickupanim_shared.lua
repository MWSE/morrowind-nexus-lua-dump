local M = {}

M.ANIM_TUNING = {
    door      = { speed = 2,   duration = 0.33   },
    container = { speed = 2,   duration = 0.33   },
    default   = { speed = 1.0,   duration = 0.50 },
}

-- don't change these
M.DEFAULTS = {
    ENABLED_ITEMS      = true,
    ENABLED_DOORS      = true,
    ENABLED_CONTAINERS = true,
    ITEM_SPEED         = 1.0,
    DISABLE_CAMERA_SHAKE = false,
}

return M