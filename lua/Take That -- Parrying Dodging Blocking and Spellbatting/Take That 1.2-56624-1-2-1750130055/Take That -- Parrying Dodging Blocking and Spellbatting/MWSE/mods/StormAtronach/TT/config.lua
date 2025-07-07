-- Set up the configuration
local default_config = {
    log_level               = "error",
    enabled                 = true,
    name                    = "Take That!",
    hotkey                  = {keyCode = tes3.scanCode.b},
    block_cool_down_time    = 3,
    parry_cool_down_time    = 3,
    dodge_cool_down_time    = 3,
    block_start_delay       = 0.05, 
    block_window            = 0.7,
    parry_window            = 0.2,
    parry_red_per_attack    = 2,
    parry_red_duration      = 3,
    bat_min_skill           = 25,
    bat_start_delay         = 0.05,
    bat_window              = 0.5, -- Window for spell batting, in seconds
    block_shield_base_pc    = 50,
    block_shield_skill_mult = 0.5,
    block_weapon_base_pc    = 20,
    block_weapon_skill_mult = 0.6,
    -- NPC parry
    enemy_parry_active      = false,
    enemy_parry_window      = 0.2,
    enemy_min_attackSwing   = 0.75,
    -- Alternative mechanic for the weapon block
    block_skill_bonus_active        = false,
    block_weapon_blockSkill_bonus   = 0.2,
    -- Deactivating vanilla blocking
    vanilla_blocking_cap    = 0,
    -- Training
    block_skill_gain        = 5,
    parry_skill_gain        = 3,
    dodge_skill_gain        = 5,
    -- Visual
    parry_light_magnitude   = 20,
    parry_light_duration    = 0.25,
    allow_vanilla_block = true,
}
local config        = mwse.loadConfig("sa_TT_config", default_config) ---@cast config table
config.confPath     = "sa_TT_config"
config.default      = default_config

return config