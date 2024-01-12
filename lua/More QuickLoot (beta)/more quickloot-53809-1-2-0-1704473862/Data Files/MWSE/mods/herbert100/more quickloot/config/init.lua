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
local log = require("herbert100.Logger")("More QuickLoot/config") ---@type herbert.Logger


--- checks if a mod is installed
---@param mod_path string
---@return boolean mod_installed `true` if the mod is installed, `false` otherwise
local function mod_installed(mod_path)
    return lfs.attributes(string.format("Data Files/MWSE/mods/%s/main.lua", mod_path)) ~= nil
end
--- checks if a mod config is installed (i.e., if the mod has been previously installed)
---@param mod_path string the path of the mod, as in `require` statements
---@return boolean config_exists `true` if the config exists. `false` otherwise.
local function config_exists(mod_path)
    return lfs.attributes(string.format("Data Files/MWSE/config/%s.json", mod_path)) ~= nil
end

---@type MQL.config
local config



-- used to set default settings.
---@type MQL.defns.misc.gh
local gh_status = mod_installed("graphicHerbalism") and defns.misc.gh.installed
    or config_exists("graphicHerbalism") and defns.misc.gh.previously
    or defns.misc.gh.never

-- -----------------------------------------------------------------------------
-- UPDATE DEFAULT VALUES AND LOAD DEFAULT CONFIG
-- -----------------------------------------------------------------------------
do
    local default = require("herbert100.more quickloot.config.default") ---@type MQL.config
    

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
if config.version ~= defns.misc.version then

    -- do stuff if the old config exists
        -- if it exists, we'll load it once, then mark it as being loaded and ignore it from then on
    if config_exists("More Quick Loot") then -- if the old config exists
        
        local old_config = mwse.loadConfig("More Quick Loot", config) -- load old config, using the current config as the default settings

        -- if we haven't imported this config already, then we should import it
        if old_config.compat == nil or old_config.compat.imported == nil then
            -- mark the old config as imported
            old_config.compat = old_config.compat or {}
            old_config.compat.imported = true
            -- save the config so that the `imported` flag gets set
            mwse.saveConfig("More Quick Loot", old_config)
            -- remove the imported flag after saving the old config (to """declutter""" the current config)
            old_config.compat.imported = nil
            config = old_config
        end
    end
    

    -- first few versions didnt have a config number, so we'll treat it as v0.5
    if config.version == nil then
        config.version = 0.5
    end

    -- update a config setting location from an old location to a new location
    ---@param old_key string location of old setting. can use "." to specify subtables
    ---@param new_key string location of new setting. can use "." to specify subtables
    local function update_setting_location(old_key, new_key)
        log('updating "%s" to "%s"', old_key, new_key)
        local old_keys = old_key:split(".")
        local new_keys = new_key:split(".")

        local old_tbl, new_tbl = config, config

        if old_keys and #old_keys > 1 then
            for i=1,#old_keys-1 do old_tbl = old_tbl[old_keys[i]] end
            old_key = old_keys[#old_keys]
        end
        if new_keys and #new_keys > 1 then
            for i=1,#new_keys-1 do new_tbl = new_tbl[new_keys[i]] end
            new_key = new_keys[#new_keys]
        end

        if log.level == log.LEVEL.TRACE then
            local inspect = include("inspect")
            log:trace([[in update_setting_location with:
    old_key: "%s"
    new_key: "%s"
    ------------
    old_keys: %s
    new_keys: %s
    ------------
    old_tbl: %s
    new_tbl: %s
            ]], old_key, new_key, inspect(old_keys), inspect(new_keys), json.encode(old_tbl), json.encode(new_tbl))
        end
        -- set the old_key and new_key to be only the relevant part

        if old_tbl[old_key] ~= nil then
            new_tbl[new_key] = old_tbl[old_key]
            old_tbl[old_key] = nil
        end
    end
    -- -------------------------------------------------------------------------
    -- UPDATE TO v0.9
    -- -------------------------------------------------------------------------
    if config.version < 0.9 then 
        -- import old settings into their new place, then delete the old values
        for _,k in ipairs{"menu_x_pos", "menu_y_pos", "show_lucky_msg", "max_disp_items" } do
            update_setting_location(k, "UI." .. k)
        end
        -- old versions used to store `dead` and `inanimate` settings (along with some UI settings) inside a `quick_loot` table.
        config.quick_loot = nil

        -- `plants_blacklist` used to be called `destroy_blacklist`
        update_setting_location("organic.destroy_blacklist", "organic.plants_blacklist")
        
        -- this setting is now called `change_plants`. its functionality is too different to be properly imported
        config.organic.destroy_plants = nil
    end

    -- -------------------------------------------------------------------------
    -- UPDATE TO v1.0
    -- -------------------------------------------------------------------------
    if config.version < 1.0 then
        -- renamed this setting for consistency
        update_setting_location("keys.use_interact_btn", "keys.use_activate_btn")
    end

    -- -------------------------------------------------------------------------
    -- UPDATE TO v1.1
    -- -------------------------------------------------------------------------
    if config.version < 1.1 then
        update_setting_location("barter.enable_status_bar", "UI.enable_status_bar")
        update_setting_location("barter.modified_controls", "UI.show_modified_controls")
        -- now lives in `services` settings
        if config.barter.allow_skooma ~= nil  or config.training.allow_skooma ~= nil then
            config.services.allow_skooma = config.barter.allow_skooma or config.training.allow_skooma
            config.barter.allow_skooma = nil
            config.training.allow_skooma = nil
        end

        -- the barter mode used to be stored as an `enum` because i wasn't sure how i would add support for multiple
        -- services later
        -- `0` was `buying` and `1` was `selling`
        if config.barter.initial_mode ~= nil then
            config.barter.start_buying = (config.barter.initial_mode == 0)
            config.barter.initial_mode = nil
        end
    end
    
    -- -------------------------------------------------------------------------
    -- UPDATE TO v1.2
    -- -------------------------------------------------------------------------
    if config.version < 1.2 then
        do -- rename the multiple items settings (what was i thinking)
            update_setting_location("multiple_items_m", "mi.mode_m")
            local mi_names = { -- multiple item settings were moved to their own subtable and given slightly more readable names
                {"multiple_items",      "mi.mode"},
                {"multiple_items_m",    "mi.mode_m"},
                {"mi_inv_take_all",     "mi.inv_take_all"},
                {"mi_ratio",            "mi.min_ratio"},
                {"mi_tweight",          "mi.max_total_weight"},
                {"mi_chance",           "mi.min_chance"},
            }
            local old_key, new_key
            for _, sub_tbl in ipairs{"reg", "pickpocket", "organic"} do
                for i = 1, #mi_names do
                    if sub_tbl == "reg" then
                        old_key = mi_names[i][1]
                    else
                        old_key = sub_tbl .. "." .. mi_names[i][1]
                    end
                    new_key = sub_tbl .. "." .. mi_names[i][2]
                    update_setting_location(old_key, new_key)
                end
            end
        end
        do -- rename the equipped item settings (again, what was i thinking)
            -- this code basically moves 
            --      `config.pickpocket.allow_equipped_weapons` -> `config.pickpocket.equipped.weapons`
            -- and so on (for other equipped item settings as well as the `barter` settings)
            for _, sub_tbl in ipairs{"pickpocket", "barter"} do
                for _, name in ipairs{"weapons", "jewelry", "armor", "accessories", "clothing"} do
                    local old_key = string.format("%s.allow_equipped_%s", sub_tbl, name)
                    local new_key = string.format("%s.equipped.%s", sub_tbl, name)
                    update_setting_location(old_key, new_key)
                end
                update_setting_location(sub_tbl .. ".show_equipped_items", sub_tbl .. ".equipped.show")
            end
        end
        do -- update blacklist locations
            if type(config.blacklist.containers) ~= "table" then
                local blacklist = config.blacklist
                config.blacklist = {containers = blacklist}
            end
            update_setting_location("organic.plants_blacklist", "blacklist.organic")
        end
    end

    -- end of updates
    config.version = defns.misc.version
    changes_made = true
end



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
    config.compat.ttip = mod_installed("rev_TTIP")
    -- config.compat.ttip = include("rev_TTIP.config") ~= nil

    -- -----------------------------------------------------------------------------
    -- BUYING GAME
    -- -----------------------------------------------------------------------------
    config.compat.bg = mod_installed("buyingGame")
    -- config.compat.bg = include("buyingGame.strings") ~= nil

    -- =========================================================================
    -- ANIMATED CONTAINERS
    -- =========================================================================
    config.compat.ac = mod_installed("MWCA")
    -- config.compat.ac = include("MWCA.interop2") ~= nil

    local bxp_installed = mod_installed("herbert100/barter xp overhaul")

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
        return string.format("%-20s %s", mod_name, 
            ((status == true or status == defns.misc.gh.installed) and "installed"      
            or (status == false or status == defns.misc.gh.never) and  "not installed" 
            or status == defns.misc.gh.previously and "previously installed"
        )) 
    end
    local info = { install_status_str("Buying Game:", config.compat.bg), install_status_str("Just the Tooltip:", config.compat.ttip), install_status_str("Graphic Herbalism:", config.compat.gh_current), install_status_str("Barter XP Overhaul:", config.compat.bxp), --[[install_status_str("Animated Containers:", config.compat.ac)]] }
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