-- =============================================================================
-- CONFIG
-- =============================================================================
--[[
this file is responsible for:
- loading the default config, then loading this mods config file (if it exists)
- converting the config file of older versions to the newest version
- updating the default config file based on compatibility settings, so that things Just Work(tm).
]]

local semver = require("semver")


local log = mwse.Logger.new()
local defns = require("herbert100.more quickloot.defns") ---@type herbert.MQL.defns
local fmt = string.format


--- checks if a mod config is installed (i.e., if the mod has been previously installed)
---@param mod_path string the path of the mod, as in `require` statements
---@return boolean config_exists `true` if the config exists. `false` otherwise.
local function config_exists(mod_path)
    return lfs.attributes(("Data Files/MWSE/config/%s.json"):format(mod_path:gsub("[/\\]", ".")))
        ~= nil
end


-- checks if a mod is installed. this is used because `tes3.isLuaModActive` may not be accurate if this mod is executed before the mod in question
---@param mod_path string
---@return boolean
local function is_mod_installed(mod_path)
    return lfs.fileexists(("Data Files/MWSE/mods/%s/main.lua"):format(mod_path:gsub("%.", "/")))
end

-- used to set default settings.
---@type herbert.MQL.defns.misc.gh
local gh_status = is_mod_installed("graphicHerbalism") and defns.misc.gh.installed
    or config_exists("graphicHerbalism") and defns.misc.gh.previously
    or defns.misc.gh.never

-- -----------------------------------------------------------------------------
-- UPDATE DEFAULT VALUES AND LOAD DEFAULT CONFIG
-- -----------------------------------------------------------------------------
local default = require("herbert100.more quickloot.config.default")

-- if gh is installed, default settings should be to use GH
if gh_status == defns.misc.gh.installed then
    default.organic.change_plants = defns.change_plants.gh
    default.organic.not_plants_src = defns.not_plants_src.gh

    -- if GH was previously installed, we should use its config to detect which organic containers arent plants
elseif gh_status == defns.misc.gh.previously then
    default.organic.not_plants_src = defns.not_plants_src.gh
end



---@type herbert.MQL.config
local config = mwse.loadConfig("More QuickLoot", default) --[[@as herbert.MQL.config]]
log:setLevel(config.log_level)


local version_str = tes3.getLuaModMetadata("herbert100.more quickloot").package.version
local current_version = semver(version_str)


-- -----------------------------------------------------------------------------
-- UPDATE OLD CONFIGS TO NEWEST VERSION
-- -----------------------------------------------------------------------------
local changes_made = false ---@type boolean have we changed the config this time?


if not config.version then
    config.version = version_str
    changes_made = true
else
    local cfg_version

    -- initialize the cfg_version
    if type(config.version) == "number" then
        local major = math.floor(config.version)
        local minor = math.floor(10 * (config.version % 1))
        local patch = math.floor(100 * (config.version % 0.1))

        cfg_version = semver(table.concat({ major, minor, patch }, "."))
    else
        cfg_version = semver(config.version)
    end


    -- update the config
    if cfg_version ~= current_version then
        -- percentages are no longer stored as whole numbers
        if cfg_version < semver("1.5.0") then
            local function update_percent(cfg, key, min)
                if cfg and cfg[key] and cfg[key] >= min then
                    cfg[key] = cfg[key] / 100
                end
            end

            for _, cfg in ipairs { config.organic, config.pickpocket } do
                update_percent(cfg, "min_chance", 1)
                update_percent(cfg, "max_chance", 1.1)
                update_percent(cfg.mi, "min_chance", 1.1)
            end
            update_percent(config.pickpocket, "determinism_cutoff", 1.1)

            table.copymissing(config.blacklist.containers, default.blacklist.containers)
            config.UI.show_tooltips = default.UI.show_tooltips
        end
        if cfg_version < semver("2.0.0") then
            for _, equipped_cfg in ipairs { config.pickpocket.equipped, config.barter.equipped } do
                for name, equipped_type in pairs(defns.equipped_types) do
                    local old_val = rawget(equipped_cfg, name)
                    if old_val ~= nil then
                        rawset(equipped_cfg, name, nil)
                        equipped_cfg.allowed_type_defns[equipped_type] = old_val
                        log("updating equipped type config setting")
                        log('\tsetting equipped_cfg.allowed_type_defns[%s] = equipped_cfg["%s"] == %s', equipped_type,
                            name, old_val)
                    end
                end
            end
            if type(config.dead.dispose) == "number" then
                config.dead.dispose = config.dead.dispose >= 1
            end
        end


        -- end of updates
        config.version = version_str
        changes_made = true
    end
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
                log:info(
                "You've previously installed Graphic Herbalism, updating the relevant compatibility settings...")
                -- we should update the way the mod detects whether something isnt a plant
                config.organic.not_plants_src = defns.not_plants_src.gh
                -- update the history to signify that GH has been previously installed
                config.compat.gh_history = defns.misc.gh.previously
                changes_made = true
            end

            -- if GH is currently installed, and if the mod has never been run while GH was installed
            if gh_status == defns.misc.gh.installed then
                log:info(
                "This is your first time running the mod while Graphic Herbalism is actively installed, updating settings...")
                -- update the change plants behavior, and update the `gh` history
                config.organic.change_plants = defns.change_plants.gh
                config.compat.gh_history = defns.misc.gh.installed
                changes_made = true
            end
        end

        -- if GH isn't currently installed, make sure `change_plants` is not set to the GH option.
        if gh_status < defns.misc.gh.installed and config.organic.change_plants == defns.change_plants.gh then
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


-- print compatibility information
log:info("printing compatibility information:\n%s", function()
    local STATUS_STRS = {
        [true] = "installed",
        [defns.misc.gh.installed] = "installed",
        [false] = "not installed",
        [defns.misc.gh.never] = "not installed",
        [defns.misc.gh.previously] = "previously installed",
    }
    local mod_infos = {
        { "Buying Game",         STATUS_STRS[config.compat.bg] },
        { "Just the Tooltip",    STATUS_STRS[config.compat.ttip] },
        { "Graphic Herbalism",   STATUS_STRS[config.compat.gh_current] },
        { "Barter XP Overhaul",  STATUS_STRS[config.compat.bxp] },
        { "Animated Containers", STATUS_STRS[config.compat.ac] },
    }
    ---@cast mod_infos +string[]

    table.sort(mod_infos, function(a, b)
        if a[2] ~= b[2] then
            return a[2] < b[2]
        else
            return a[1] < b[1]
        end
    end)
    for i = 1, #mod_infos do
        local v = mod_infos[i]
        mod_infos[i] = string.format("\t%-20s %s\n", v[1] .. ":", v[2])
    end
    return table.concat(mod_infos)
end)

-- if we've made changes, we should save the config
if changes_made then
    local formatting_options = {
        indent = true,
        keyorder = { "version",
            "take_nearby_dist", "show_scripted", "keys",
            -- pages/big categories
            "UI", "reg", "dead", "inanimate", "organic", "pickpocket",
            "services", "training", "barter", "blacklist", "advanced", "compat",
            -- important settings/small categories
            "enable", "mi", "xp", "mode", "mode_m", "default_service",
        },
    }
    mwse.saveConfig("More QuickLoot", config, formatting_options)
end

return config ---@type herbert.MQL.config
