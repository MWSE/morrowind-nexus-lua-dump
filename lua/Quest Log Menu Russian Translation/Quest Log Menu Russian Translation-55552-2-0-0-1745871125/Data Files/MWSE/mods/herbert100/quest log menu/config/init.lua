
local hlib = require("herbert100")
local tbl_ext = hlib.tbl_ext

local info = hlib.get_mod_info()


assert(info, "Error: Mod metadata could not be retrieved. \z
    Make sure this mods metadata.toml file is properly installed."
)


local default = hlib.import("config.default") ---@type herbert.QLM.config
local cfg = require("herbert100").load_config(info.mod_name, default)

local version = hlib.semver(info.metadata.package.version)
default.version = version -- update version after loading config

---@type herbert.QLM.config

local log = hlib.Logger()

log:set_level(cfg.log_level) -- update the logging level now

if cfg.version ~= nil then 
    cfg.version = hlib.semver(cfg.version)
end

if cfg.version == version then return cfg end

local function update_config_key(old_key, new_key)
    local old_val = tbl_ext.recursive_get(cfg, old_key)
    if old_val ~= nil then
        log:trace('moving config["%s"] to config["%s"]', old_key, new_key)
        tbl_ext.recursive_set(cfg, new_key, old_val)
        tbl_ext.recursive_set(cfg, old_key, nil)
    else
        log:trace('config["%s"] was already nil. no need to move any values', old_key)

    end
end

-- update to v2.0.0
if cfg.version == nil then 
    log("updating config keys...")
    -- update_config_key("all_fzy", "search.all_fzy")
    update_config_key("keyword_search", "search.keywords")
    -- update_config_key("search_quest_text", "search.quest_progress")
    update_config_key("set_first_result_active", "search.set_first_result_active")
    update_config_key("show_hidden", "quest_list.show_hidden")
    update_config_key("show_completed", "quest_list.show_completed")
end

log:info("Updated from version %s to version %s", cfg.version or "???", version)

cfg.version = version

mwse.saveConfig(info.mod_name, cfg)

return cfg