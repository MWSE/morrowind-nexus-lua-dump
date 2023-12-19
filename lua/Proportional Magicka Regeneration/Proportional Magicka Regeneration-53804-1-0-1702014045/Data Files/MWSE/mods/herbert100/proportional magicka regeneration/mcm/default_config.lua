-- defualt values
---@class MR_Config
local defaults = { 
    log_level = 1,
    player_regen = {
        enable = true,
        coeff = 0.75,
        poll_rate = 0.3,
    },
    npc_regen = {
        enable = true,
        coeff = 1.5,
        poll_rate = 1.2,
    },
    atronach_mult = 0.2,
    atronachs_can_sleep = false,
    atronachs_can_travel = false,
    formula_name = "gradual_growth",
    combat_mult = 0.75,
}
return defaults