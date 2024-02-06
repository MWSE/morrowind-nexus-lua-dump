local log = require("herbert100").Logger.new "PPE/config/utils"

---@class PPE.config.utils
local utils = {
    profiles_dir = "config\\PPE\\profiles\\",
    current_profile_path = "config\\Proportional Progression Expanded",
}

utils.full_profiles_path = "Data Files\\MWSE\\" .. utils.profiles_dir
if not lfs.attributes("Data Files\\MWSE\\config\\PPE") then
    lfs.mkdir("Data Files\\MWSE\\config\\PPE")
end

local version_str = toml.loadMetadata("Proportional Progression Expanded").package.version ---@type any
local versions = string.split(version_str, "%.") ---@type any

utils.version = {
    major = tonumber(versions[1]) or 1,
    minor = tonumber(versions[2]) or 3,
    patch = tonumber(versions[3]) or 0,
}
utils.version.number = utils.version.major + utils.version.minor/100 + utils.version.patch/10000

version_str, versions = nil, nil


---@param config PPE.config
function utils.convert_numbers(config)
    for _, cfg in ipairs{config.level.modifiers, config.skill_level.modifiers} do
        for lvl, mult in pairs(table.copy(cfg)) do
            local new_lvl = lvl

            if type(lvl) == "string" then
                new_lvl = tonumber(lvl)
                cfg[lvl] = nil
            end
            if not new_lvl then goto next_lvl end

            if new_lvl % config.lvl_delta == 0 then
                cfg[new_lvl] = mult
            else
                cfg[new_lvl] = nil
            end
            ::next_lvl::
        end
    end
end

-- convert skill id names to skill id integers
---@param config PPE.config
function utils.convert_skill_ids(config)
        -- convert skill names to skill ids
    for name, id in pairs(tes3.skill) do
        if config.skill.modifiers[name] then
            config.skill.modifiers[id] = config.skill.modifiers[name]
            config.skill.modifiers[name] = nil
        end
    end
end

---@param config PPE.config
function utils.update_config_version(config)
    ---@diagnostic disable-next-line: inject-field
    config.version = utils.version
end

--- perform various sanitization checks on the config
function utils.sanitize(config)
    if type(config.log_level) == "number" then
        local ll = config.log_level
        config.log_level = ll == 0 and "NONE" or ll == 1 and "INFO" or ll == 2 and "DEBUG" or ll == 3 and "TRACE"
    end
    utils.convert_numbers(config)
    utils.convert_skill_ids(config)
    utils.update_config_version(config)
end

---@param config PPE.config
function utils.update_log_level(config)
    log:set_level(config.log_level)
end


---@param profile_name string
---@param fullpath boolean? should we get the full path?
---@return string
function utils.get_filepath(profile_name, fullpath)
    if type(profile_name) ~= "string" then
        error("invalid profile name provided to utils.get_filepath")
    end
    if fullpath then
        return utils.full_profiles_path .. profile_name
    end
    return utils.profiles_dir .. profile_name
end

-- copies all key, value pairs in `json_config` into `config`. subtables will be copied in place, and numeric keys will be converted to numbers.
---@param config PPE.config
---@param json_config PPE.config
local function recursive_copy_config(config, json_config)
    for k,v in pairs(json_config) do
        local new_key = tonumber(k) or k
        if type(v) == "table" then
            recursive_copy_config(config[new_key], v)
        else
            config[new_key] = v
        end
    end
end


---@param current_cfg PPE.config? current config (if any)
---@param profile_name string?
---@return boolean new_profile_exists did the new profile exist?
function utils.change_profile(current_cfg, profile_name)

    if current_cfg and profile_name == current_cfg.profile_name then return true end

    local fp = utils.get_filepath(profile_name)
    log:trace("trying to load profile %q with path %q", profile_name, fp)


    local json_config = json.loadfile(fp)

    if json_config then
        utils.save(current_cfg)
        recursive_copy_config(current_cfg, json_config)

        utils.sanitize(current_cfg)
        utils.update_log_level(current_cfg)

        log:trace("successfully loaded profile %q and sanitized config. triggering event: %q", profile_name, "PPE:profile_changed")

        event.trigger("PPE:profile_changed", {profile_name = profile_name})
        return true
    end
    log:trace("couldn't load profile %q with path %q", profile_name, fp)
    return false
end


---@return boolean successful will be `false` if the file already exists
function utils.create_profile(current_cfg, profile_name)
    local fp = utils.get_filepath(profile_name, true)
    log:trace("trying to create profile %q with path %q", profile_name, fp)
    if not lfs.attributes(fp) then

        log:trace("profile %q doesn't exist, making new profile and triggering event: %q", profile_name, "PPE:profile_created")
        utils.save(current_cfg)
        current_cfg.profile_name = profile_name
        utils.save(current_cfg)

        event.trigger("PPE:profile_created", {profile_name = profile_name})
        return true
    end
    log:trace("could not create profile %q because a profile with the same name already exists", profile_name, fp)

    return false
end


---@param config PPE.config
---@param current_cfg_path_too boolean? should we also save to the current config path?
function utils.save(config, current_cfg_path_too)
    local fp = utils.get_filepath(config.profile_name)
    json.savefile(fp, config)
    if current_cfg_path_too then
        json.savefile(utils.current_profile_path, config)
    end
end

--- load the config 
---@return PPE.config
function utils.load_first_config()
    -- see if the profiles folder exists
    local default = require("herbert100.proportional progression.config.default")
    
    local config = table.deepcopy(default)
    local json_config = json.loadfile(utils.current_profile_path)

    local try_to_import_nc_config = false

    if json_config then
        recursive_copy_config(config, json_config)
    else
        try_to_import_nc_config = true
    end

    utils.sanitize(config)
    utils.update_log_level(config)

    local need_to_save = false

    if not lfs.attributes(utils.full_profiles_path) then
        lfs.mkdir(utils.full_profiles_path)
        need_to_save = true
    end

    

    if try_to_import_nc_config then
        if utils.import_NC_config(config) then
            event.register("initialized", function (e)
                tes3.messageBox("[PPE] Imported original Proportional Progression config. (This message will only be shown once.)")
            end)
        end
        need_to_save = true
    end

    if need_to_save then
        utils.save(config, true)
    end

    return config
end


function utils.reset_to_default(config)
    local default = require("herbert100.proportional progression.config.default")
    local profile_name = config.profile_name
    recursive_copy_config(config, default)
    config.profile_name = profile_name
end

---@return string[] profile_names
function utils.get_all_profile_names()
    local profile_names = {}
    local pattern = "^" .. utils.full_profiles_path .. "(.*)%.json$"
    for file in lfs.walkdir(utils.full_profiles_path) do
        local _, _, profile_name = string.find(file, pattern)
        if profile_name then
            table.insert(profile_names, profile_name)
        end
    end
    return profile_names
end

local function import_NC_lvl_multipliers(new_config, old_config)
    new_config.enable = old_config.use
    for k, v in pairs(old_config.values) do
        new_config.modifiers[tonumber(k)] = math.round(tonumber(v), 2)
    end
end

local function import_NC_skill_multipliers(new_config, old_config)
    new_config.enable = old_config.use
    for k, v in pairs(old_config.values) do
        local id = tes3.skill[k]
        new_config.modifiers[id] = math.round(tonumber(v), 2)
    end
end

--- tries to import the config from the NC version of Proportional Progression, returns `true` if successful, `false` otherwise
---@param config PPE.config
---@return boolean successful
function utils.import_NC_config(config)
    log:info("Attempting to import original Proportional Progression config")
    log:info("This process will happen automatically on the first launch, and can be triggered manually later in the MCM.")

    local old_config = json.loadfile("nc_xpscale_config")
    if old_config then
        -- Get the global scale, or assume it is 1.
        ---@diagnostic disable-next-line: inject-field
        config.scale = tonumber(old_config.scale or 1)

        import_NC_skill_multipliers(config.skill, old_config.skillSpecific)
        import_NC_lvl_multipliers(config.level, old_config.levelSpecific)
        import_NC_lvl_multipliers(config.skill_level, old_config.skillLevelSpecific)
        return true
    end
    return false
end




return utils