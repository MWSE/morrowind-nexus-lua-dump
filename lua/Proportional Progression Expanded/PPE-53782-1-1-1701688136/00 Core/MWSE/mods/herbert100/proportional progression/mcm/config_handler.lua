---@diagnostic disable: inject-field

-- this file will deal with loading the config, initializing it, and importing the previous config


local CONSTANTS = require("herbert100.proportional progression.CONSTANTS")

local log = require("herbert100.proportional progression.log")
local mcm_config = nil ---@type PPE_Config

local default_config = require("herbert100.proportional progression.mcm.default_config")

--[[ the loadConfig handles converting string keys to integer keys, but only if those keys exist in the provided defaults table
    changing the `lvl_delta` or `max_lvl` settings in the config will lead to keys being in the stored config file that aren't present in the default config file;
    those keys will need to be converted manually.
    there are a number of ways to do this, but i thought the following way was a good compromise between being "straightforward" and not causing too many problems.
        - another option would have been to fill the default_config file with a a key for every integer we'll feasibly need, but then that could mess with interpolating values later.
        - we could also load the config once to get the `lvl_delta` and `max_lvl` settings, generate a default config, and then load the config again, but that seems like overkill (unlike anything else in this mod, of course)
]]

mcm_config =  mwse.loadConfig(CONSTANTS.mod_name, default_config) ---@type PPE_Config

-- set the log level here. it's not ideal, but whatever
log:setLogLevel(CONSTANTS.log_levels[mcm_config.log_level])



-- if these settings are different from default, then the loadConfig function won't properly load the config 
if mcm_config.lvl_delta ~= default_config.lvl_delta or mcm_config.max_lvl ~= default_config.max_lvl then
    for _, tbl_index in pairs({"level", "skill_level"}) do 
        local bad_keys = {}
        -- everything in this table should be indexed by a number
        local tbl = mcm_config[tbl_index].modifiers
        -- we're looping twice because lua can be finicky about deleting things from a table during loops.

        -- loop once to find the keys that weren't imported properly
        for k,v in pairs(tbl) do 
            if type(k) ~= "number" then 
                bad_keys[#bad_keys+1] = k
            end
        end
        -- loop again to fix them
        for _, k in ipairs(bad_keys) do 
            tbl[tonumber(k)] = tbl[k]
            tbl[k] = nil
        end
    end
end



--[[import the old config if it exists. we only try to do this the very first time the mod is launched (unless the new config file gets deleted)
    *) this will update the defaults to use those from the original config file, if it exists.
        *) only doing the import once means that the old config values will be ignored if settings are changed in the MCM
]]
if mcm_config.first_time then


    log:info("Detecting this is the first launch... trying to import the old config file.")
    log:info("This process will only happen once (unless the new config file is deleted).")
    log:info("...")
    -- Raw config file data. We'll want to manipulate it.
    -- first, see if the original config exists.
    local old_config = json.loadfile("nc_xpscale_config")

    if old_config then
        log:info("Original config file found! Importing values.")

        -- Get the global scale, or assume it is 1.
        mcm_config.scale = tonumber(old_config.scale or 1)
    
        -- this is a translation table, because the tables have different names (why did i change them)
        local indices = {{"skill", "skillSpecific"}, {"level", "levelSpecific"}, {"skill_level", "skillLevelSpecific"}}
        for _, index_pair in pairs(indices) do
    
            -- these are the values of the old version of the config 
            local new_index, old_index = table.unpack(index_pair)
            local new_table, old_table = mcm_config[new_index], old_config[old_index]
    
            -- these will be the updated values, compatible with MCM
            new_table.enable = old_table.use
    
            -- iterate over values, we'll have to convert the numbers, and maybe the keys too
            for old_key,old_value in pairs(old_table.values) do 

                local new_key, new_value = old_key, math.round(tonumber(old_value),2)
    
                -- if we're not going through skill modifiers, then the table is being indexed by a string that should be a number (eg, `"10"` instead of `10`)
                if old_index ~= "skillSpecific" then 
                    new_key = tonumber(old_key) 
                end
                ---@diagnostic disable-next-line: need-check-nil
                new_table.modifiers[new_key] = new_value
            end
        end
    
        log:info([[Original config data imported successfully. The original config file can now be deleted as it will no longer be used.
                The imported values are reflected in the MCM.
                ]])
        event.register(tes3.event.initialized, function()
            tes3.messageBox(string.format("[%s]: Original config file imported successfully. \z
                The original config file can now be deleted as it will no longer be used. \z
                Make sure the original mod is uninstalled or the NC Patch is enabled. \z
                This message will only be displayed once.", 
                CONSTANTS.mod_name))
        end)


    -- do nothing if file doesn't exist
    else
        log:warn([[Original config file not found. It probably doesn't exist. Initializing with default values.
        You can ignore this message if you didn't use the original mod or don't want to import its config.
        If you did use the original mod, and you wish to import your old config, you should delete the new config file, located at:
            'Data Files/MWSE/config/Proportional Progression.json'
        and then make sure the old config file is in the default location:
            'Data Files/MWSE/nc_xpscale_config.json'
        ]])
        event.register(tes3.event.initialized, function()
            tes3.messageBox(string.format("[%s]: Original config file not found. Initializing with default values. \z
            You can ignore this message if you didn't use the original mod, it will only be displayed once. \z
            Directions for importing an old config can be found on the mod page.", 
            CONSTANTS.mod_name)) 
        end)
    end
    --[[ save the config with `first_time == false`. this will cause two things to happen
        1) the old config won't be loaded again
        2) the loaded values from the old config will be in the new config.
    ]]
    mcm_config.first_time = false
    mwse.saveConfig(CONSTANTS.mod_name, mcm_config)
end


return mcm_config
