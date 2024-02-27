
---@class herbert.HC.config
local default = {
    menu_multi = {
        enable = true,
        pollrate = 0.5,
        
        bars = {
            health = 0.90,
            fatigue = 0.90,
            magicka = 0.90,
        },
        show_bars_if_wpn = true,
        equipped = {
            weapon = true,
            magic = true
        },
    },
    companion_bars = {
        enable = true,
        health = 0.70,
        pollrate = 0.5,
        show_bars_if_wpn = true,

    },
    hide_map = 0,
    hide_magic_effect_icons = true,
}

---@type herbert.HC.config
local cfg = mwse.loadConfig(
    -- get the mods metadata, then get the name
    require("herbert100").get_active_mod_info(-1).metadata.package.name,
    default
)
return cfg