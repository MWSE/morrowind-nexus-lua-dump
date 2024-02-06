local defns =  require("herbert100.animated containers.defns")
---@class herbert.AC.config
local default = {
    auto_close = true,
    version = 0.5,
    play_sound = true,

    stay_open_between_loads = true,
    -- delay before opening containers (in milliseconds)
    open_wait_percent = 1.0,
    activate_on_open = true,
    activate_to_close = true,


    activate_event_priority = 301,
    -- set of objects that should not be checked
    blacklist = {},
    collision = {

        check = true,

        reset_on_load = false,

        initial_raytest_max_dist = 12.8,
        obj_raytest_max_dist = 29.8,

        max_degree = 45,

        max_xy_dist = 104,
        max_z_dist = 128.9,
        bb_check = true,
        bb_xy_scale = 1.1,
        bb_other_max_diagonal = 205,

        bb_z_top_scale = 1.2,
        bb_z_ignore_bottom_percent = 0.8,

        bb_min_radius = 7.5,


        blacklist = {
            -- this thing has stupid mesh origin, changes its position with scale
            furn_woodbar_01 = true,
        },
    },
    log_settings = {
        log_replace_table = true,
        log_every_replacement = false,
        log_add_interop_data = true,
    },
}

local version_str = toml.loadMetadata("Animated Containers Rewritten").package.version
local major, minor, patch = table.unpack(string.split(version_str, "%."))
default.version = tonumber(major) + tonumber(minor)/10 + tonumber(patch)/100

---@type herbert.AC.config
local config = mwse.loadConfig(defns.mod_name, default)

return config