---@diagnostic disable: inject-field
-- =============================================================================
-- CONFIG
-- =============================================================================
--[[
this file is responsible for:
- loading the default config, then loading this mods config file (if it exists)
- converting the config file of older versions to the newest version
- updating the default config file based on compatibility settings, so that things Just Work(tm).
]]

local defns = require("herbert100.more quickloot.defns")
local log = Herbert_Logger() ---@type herbert.Logger
local fmt = string.format
-- local log = Herbert_Logger() ---@type herbert.Logger


--- checks if a mod config is installed (i.e., if the mod has been previously installed)
---@param mod_path string the path of the mod, as in `require` statements
---@return boolean config_exists `true` if the config exists. `false` otherwise.
local function config_exists(mod_path)
    return lfs.attributes(fmt("Data Files/MWSE/config/%s.json", mod_path:gsub("[/\\]", "."))) ~= nil
end

-- checks if a mod is installed. this is used because `tes3.isLuaModActive` may not be accurate if this mod is executed before the mod in question
---@param mod_path string
---@return boolean
local function is_mod_installed(mod_path)
    return lfs.fileexists(fmt("Data Files/MWSE/mods/%s/main.lua", mod_path:gsub("%.", "/")))
end

---@type MQL.config
local config

local current_version

-- used to set default settings.
---@type MQL.defns.misc.gh
local gh_status = is_mod_installed("graphicHerbalism") and defns.misc.gh.installed
    or config_exists("graphicHerbalism") and defns.misc.gh.previously
    or defns.misc.gh.never

-- -----------------------------------------------------------------------------
-- UPDATE DEFAULT VALUES AND LOAD DEFAULT CONFIG
-- -----------------------------------------------------------------------------
local default = require("herbert100.more quickloot.config.default") ---@type MQL.config|any

do
    current_version = default.version

    -- if gh is installed, default settings should be to use GH
    if gh_status == defns.misc.gh.installed then
        default.organic.change_plants = defns.change_plants.gh
        default.organic.not_plants_src = defns.not_plants_src.gh

    -- if GH was previously installed, we should use its config to detect which organic containers arent plants
    elseif gh_status == defns.misc.gh.previously then
        default.organic.not_plants_src = defns.not_plants_src.gh
    end

    -- -----------------------------------------------------------------------------
    -- LOAD CONFIG FROM FILE AND SET LOG LEVEL
    -- -----------------------------------------------------------------------------
    config = mwse.loadConfig("More QuickLoot", default) ---@type MQL.config

    ---@diagnostic disable-next-line: param-type-mismatch
    log:set_level(config.log_level)
end

-- -----------------------------------------------------------------------------
-- UPDATE OLD CONFIGS TO NEWEST VERSION
-- -----------------------------------------------------------------------------
local changes_made = false ---@type boolean have we changed the config this time?

-- update old config settings so the user doesnt have to reset them
if config.version ~= current_version then

    -- there used to be more here, but it was causing problems so it had to go.

    -- percentages are no longer stored as whole numbers
    if config.version == nil or config.version < 1.5 then
        local function update_percent(cfg, key, min)
            if cfg and cfg[key] and cfg[key] >= min then
                cfg[key] = cfg[key] / 100
            end
        end

        for _, cfg in ipairs{config.organic, config.pickpocket} do
            update_percent(cfg, "min_chance", 1)
            update_percent(cfg, "max_chance", 1.1)
            update_percent(cfg.mi, "min_chance", 1.1)
            update_percent(cfg, "take_all_min_chance", 1)
        end
        update_percent(config.pickpocket, "determinism_cutoff", 1.1)

        table.copymissing(config.blacklist.containers, default.blacklist.containers)

        config.UI.show_tooltips = default.UI.show_tooltips
    end

    
    -- end of updates
    config.version = current_version
    changes_made = true
    current_version = nil -- dont need this variable anymore
end
default = nil




-- -----------------------------------------------------------------------------
-- UPDATE CONFIG WITH COMPATIBILITY SETTINGS
-- -----------------------------------------------------------------------------
do

    -- -------------------------------------------------------------------------
    -- GRAPHIC HERBALISM
    -- -------------------------------------------------------------------------
    do
        -- see if we should update the config depending on the GH install history, and the current GH install status
        -- if GH was never run in conjunction with this mod
        if config.compat.gh_history < defns.misc.gh.installed then

            -- if this mod has never been run while GH has been previously installed, and if GH was previously installed
            if config.compat.gh_history < defns.misc.gh.previously 
                and gh_status >= defns.misc.gh.previously 
            then
                log:info("You've previously installed Graphic Herbalism, updating the relevant compatibility settings...")
                -- we should update the way the mod detects whether something isnt a plant
                config.organic.not_plants_src = defns.not_plants_src.gh
                -- update the history to signify that GH has been previously installed
                config.compat.gh_history = defns.misc.gh.previously
                changes_made = true
            end
            
            -- if GH is currently installed, and if the mod has never been run while GH was installed 
            if gh_status == defns.misc.gh.installed then 
                log:info("This is your first time running the mod while Graphic Herbalism is actively installed, updating settings...")
                -- update the change plants behavior, and update the `gh` history
                config.organic.change_plants = defns.change_plants.gh
                config.compat.gh_history = defns.misc.gh.installed
                changes_made = true
            end
        end

        -- if GH isn't currently installed, make sure `change_plants` is not set to the GH option.
        if gh_status <  defns.misc.gh.installed and config.organic.change_plants == defns.change_plants.gh then

            config.organic.change_plants = defns.change_plants.none
            changes_made = true
        end

        -- update the current install status of graphic herbalism. don't record this as a change worth saving, because it gets set on each launch
        -- i.e., the saved value does not matter
        config.compat.gh_current = gh_status
    end

    -- the `include(...) ~= nil` just checks if the file exists
    -- i did my best to pick files that dont do anything when executed (e.g. register events and so on)

    -- -----------------------------------------------------------------------------
    -- JUST THE TOOLTIP
    -- -----------------------------------------------------------------------------
    config.compat.ttip = is_mod_installed("rev_TTIP")
    -- config.compat.ttip = include("rev_TTIP.config") ~= nil

    -- -----------------------------------------------------------------------------
    -- BUYING GAME
    -- -----------------------------------------------------------------------------
    config.compat.bg = is_mod_installed("buyingGame")
    -- config.compat.bg = include("buyingGame.strings") ~= nil

    -- =========================================================================
    -- ANIMATED CONTAINERS
    -- =========================================================================
    config.compat.ac = is_mod_installed("herbert100.animated containers")

    local bxp_installed = is_mod_installed("herbert100.barter xp overhaul")

    if bxp_installed then
        -- if the mod is currently installed, but it wasn't previously installed, enable barter xp
        if not config.compat.bxp then
            config.barter.award_xp = true
            changes_made = true
        end
    else -- if bxp is not installed
        
        -- if it was previously installed, or if the award xp setting is enabled
        if config.compat.bxp or config.barter.award_xp then 
            config.barter.award_xp = false
            changes_made = true
        end
    end
    -- update install status
    config.compat.bxp = bxp_installed
end



do -- print compatibility information

    local function install_status_str(mod_name, status) 
        local gh_defn = defns.misc.gh
        return string.format("%-20s %s", mod_name .. ":", 
            (status == true or status == gh_defn.installed) and "installed"      
            or (status == false or status == gh_defn.never) and  "not installed" 
            or status == gh_defn.previously and "previously installed"
        ) 
    end
    local info = { 
        install_status_str("Buying Game", config.compat.bg), 
        install_status_str("Just the Tooltip", config.compat.ttip), 
        install_status_str("Graphic Herbalism", config.compat.gh_current), 
        install_status_str("Barter XP Overhaul", config.compat.bxp), 
        install_status_str("Animated Containers", config.compat.ac)
    }
    -- sort first by install status, then by mod name
    table.sort(info, function (a, b)
        local a1,a2 = unpack(a:split(":")) ---@type string, string
        local b1,b2 = unpack(b:split(":")) ---@type string, string
        a2 = a2:trim(); b2 = b2:trim(); if a2 == b2 then return a1 < b1 end; return a2 < b2
    end)
    log:info("printing compatibility information:\n\t%s", table.concat(info,"\n\t"))
end


-- if we've made changes, we should save the config
if changes_made then 
    mwse.saveConfig("More QuickLoot", config, defns.misc.json_options) 
end


return config ---@type MQL.config