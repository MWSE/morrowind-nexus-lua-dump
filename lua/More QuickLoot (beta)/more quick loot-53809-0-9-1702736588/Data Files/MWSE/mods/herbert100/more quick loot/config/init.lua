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

local defns = require("herbert100.more quick loot.defns")
local log = require("herbert100.Logger")(defns) ---@type Herbert_Logger
-- -----------------------------------------------------------------------------
-- UPDATE DEFAULT VALUES
-- -----------------------------------------------------------------------------
local default = require("herbert100.more quick loot.config.default") ---@type MQL.config
-- if graphic herbalism is installed, the default `change_plants` setting should be "use graphic herbalism"


-- whether graphic herbalism is currently installed
local current_gh_status ---@type MQL.defns.gh_status

do -- set current gh status 
    local gh_installed = include("graphicHerbalism.interop") ~= nil
    -- local gh_config = json.loadfile("config.graphicHerbalism")
    -- local gh_blacklist = (gh_config ~= nil and gh_config.blacklist)
    if gh_installed then
        current_gh_status = defns.gh_status.currently
    -- if the config exists
    elseif lfs.attributes("Data Files/MWSE/config/graphicHerbalism.json") then
        current_gh_status = defns.gh_status.previously
    else
        current_gh_status = defns.gh_status.never
    end
end

-- print the current GH status
if log > 1 then
    log("Detecting Graphic Herbalism installation status...")
    if current_gh_status == defns.gh_status.never then
        log("Graphic Herbalism was never installed.")
    elseif current_gh_status == defns.gh_status.previously then
        log("Graphic Herbalism is not currently installed, but it was previously installed.")
    elseif current_gh_status == defns.gh_status.currently then
        log("Graphic Herbalism is currently installed.")
    end
end

-- if gh was previously installed, or if it's currently installed, update the default settings
if current_gh_status >= defns.gh_status.previously then 
    default.organic.change_plants = defns.change_plants.gh

    if current_gh_status == defns.gh_status.currently then
        default.organic.not_plants_src = defns.not_plants_src.gh
    end

end
-- -----------------------------------------------------------------------------
-- LOAD CONFIG FROM FILE AND SET LOG LEVEL
-- -----------------------------------------------------------------------------


local config = mwse.loadConfig(defns.mod_name, default) ---@type MQL.config
---@diagnostic disable-next-line: param-type-mismatch
log:set_level(config.log_level)

-- -----------------------------------------------------------------------------
-- UPDATE OLD CONFIGS TO NEWEST VERSION
-- -----------------------------------------------------------------------------
-- update old config settings so the user doesnt have to reset them

local changes_made = false ---@type boolean have we changed the config this time?


-- this code will look weird now, but it'll make it easier to sequentially update the config when newer versions come out
-- unless i refactor it for reason lol
if config.version ~= defns.version then
    -- update to v0.9
    if config.version == nil then 
        -- import old settings into their new place, then delete the old values
        for _,k in ipairs({"menu_x_pos", "menu_y_pos", "show_lucky_msg", "max_disp_items" }) do
            if config[k] then
                config.UI[k] = config[k]
                config[k] = nil
            end
        end
        if config.quick_loot then
            -- im too scared to try to import the last config
            config.quick_loot = nil
            --[[
            local qlc = config.quick_loot
            if qlc.enable ~= nil then
                config.inanimate.enable = qlc.enable
                config.dead.enable = qlc.enable
            end
        --     show_msgbox = false,
            if qlc.hide_trapped ~= nil then
                config.inanimate.show_trapped = not qlc.hide_trapped
            end
            -- further refactoring made this part unnecessary. someone help me. 
            -- if qlc.hide_scripted ~= nil then
                
            --     ---@diagnostic disable-next-line: inject-field
            --     config.show_scripted = not qlc.hide_scripted 
            -- end
            -- if qlc.hide_tooltips ~= nil then
            --     config.UI.hide_tooltips = qlc.hide_tooltips
            -- end
            if qlc.show_msgbox ~= nil then 
                config.UI.show_msgbox = qlc.show_msgbox
            end
            -- delete it from the config file now that it has been imported.
            ---@diagnostic disable-next-line: inject-field
            config.quick_loot = nil
            ]]
        end
        if config.organic.destroy_blacklist ~= nil then 
            config.organic.plants_blacklist = config.organic.destroy_blacklist
            config.organic.destroy_blacklist = nil
        end
        
        if config.organic.destroy_plants ~= nil then
            config.organic.destroy_plants = nil
        end
    
        changes_made = true
        -- update the current version
    end
    config.version = defns.version
end



-- -----------------------------------------------------------------------------
-- UPDATE CONFIG WITH COMPATIBILITY SETTINGS
-- -----------------------------------------------------------------------------

-- see if we should update the config depending on the GH install history, and the current GH install status

-- if GH was never run in conjunction with this mod
if config.compat.gh_history < defns.gh_status.currently then

    -- if this mod has never been run while GH has been previously installed, and if GH was previously installed
    if config.compat.gh_history < defns.gh_status.previously 
        and current_gh_status >= defns.gh_status.previously 
    then
        log:info("You've previously installed Graphic Herbalism, updating the relevant compatibility settings...")
        -- we should update the way the mod detects whether something isnt a plant
        config.organic.not_plants_src = defns.not_plants_src.gh
        -- update the history to signify that GH has been previously installed
        config.compat.gh_history = defns.gh_status.previously
        changes_made = true
    end
    
    -- if GH is currently installed, and if the mod has never been run while GH was installed 
    if current_gh_status == defns.gh_status.currently then 
        log:info("This is your first time running the mod while Graphic Herbalism is actively installed, updating settings...")
        -- update the change plants behavior, and update the `gh` history
        config.organic.change_plants = defns.change_plants.gh
        config.compat.gh_history = defns.gh_status.currently
        changes_made = true
    end
end

-- if GH isn't currently installed, make sure `change_plants` is not set to the GH option.
if current_gh_status <  defns.gh_status.currently and config.organic.change_plants == defns.change_plants.gh then

    config.organic.change_plants = defns.change_plants.none
    changes_made = true
end

-- update the current install status of graphic herbalism. don't record this as a change worth saving, because it gets set on each launch
-- i.e., the saved value does not matter
config.compat.gh_current = current_gh_status


-- if we've made changes, we should save the config
if changes_made then
    mwse.saveConfig(defns.mod_name, config)
end


return config ---@type MQL.config