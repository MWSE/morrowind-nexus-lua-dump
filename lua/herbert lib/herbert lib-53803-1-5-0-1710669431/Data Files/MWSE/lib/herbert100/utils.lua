---@class herbert.lib.utils
local utils = {}



-- =========================================================================
-- FUNCTIONS
-- =========================================================================

--- registers an event if it should be registered, deregisters it otherwise.
---@class herbert.update_registration_params : {[1]:tes3.event, [2]:fun(e)}
---@field event tes3.event? the event to register/unregister
---@field callback fun(e)|nil
---@field priority integer?
---@field old_priority integer?
---@field livecoding boolean?
---@field filter any
---@field old_filter any
---@field register boolean? if true, the event will be registered. if false, the event will be unregistered. Default: `true`

--- registers an event if it should be registered, unregisters it otherwise.
-- you can pass an old priority or old filter to unregister events when settings have changed
---@param p herbert.update_registration_params
---@return boolean something_changed whether an event was registered/unregistered
function utils.update_registration(p)
    local e = p[1] or p.event
    local c = p[2] or p.callback
    if p.old_filter or p.old_priority then
        local old_options = {filter=p.old_filter, priority=p.old_priority}
        if event.isRegistered(e, c, old_options) then
            event.unregister(e, c, old_options)
        end
    end
    local options = (p.filter or p.priority) and {filter=p.filter, priority=p.priority} or nil

    local registered = event.isRegistered(e, c, options)
    
    if p.register ~= false then
        if not registered then
            if p.livecoding then
                local livecoding = include("herbert100.livecoding.livecoding")
                if livecoding then
                    livecoding.registerEvent(e, c, options)
                    return true
                end
            end
            event.register(e, c, options)
            return true
        end
    else
        if registered then 
            event.unregister(e, c, options)
            return true
        end
    end
    return false
end

---@class herbert.lib.utils.mod_info
---@field lua_path string relative lua path to the file
---@field path string the full path to the file
---@field lua_parent_name "mods"|"lib"|"core" the directory the `lua_path` is contained in
---@field lua_parts string[] the different parts of the directory (using the relative lua syntax)
---@field parts string[] the different parts of the directory
---@field dir string the directory the file is contained in 
---@field dir_has_author_name boolean? is the first entry of `dir_parts` the name of the mod author folder?
---@field filename string the name of the file (without the directory present)
---@field short_mod_name string? name of this mod
---@field mod_name string name of this mod
---@field mod_dir string directory of this mod
---@field metadata MWSE.Metadata? the metadata of the mod (if it has any)

local badfile_paths = {
    [string.lower("@Data Files\\MWSE\\core\\initialize.lua")] = true,
    [string.lower("@Data Files\\MWSE\\core\\startLuaMods.lua")] = true,
    [string.lower("=[C]")] = true,
}


---@param offset integer? how many levels deep this function is being called. default is 0,
-- but you should increase this by 1 for every layer of nesting that's going on
---@return herbert.lib.utils.mod_info? info about the mod, if possible
function utils.get_active_mod_info(offset)

    local debug_info, new_debug_info, src_lower
    local i = 1 + (offset or 0)

    while true do
        i = i + 1
        debug_info = new_debug_info
        new_debug_info = debug.getinfo(i, "S")
        
        if not new_debug_info then break end -- we've gone too high up the stack

        src_lower = new_debug_info.source:lower()

        if badfile_paths[src_lower] then -- we've gone too high up the stack
            break
        end
        if not src_lower:find("lib\\herbert100\\", 1, true) then -- weve gone just high enough to not hit a herbert lib file
            debug_info = new_debug_info
            break
        end

    end
         -- if we've gone too far up the stack
         -- we've gone just high enough to not hit a herbert lib file

    local src = debug_info and debug_info.source

    if not src then return end
    local parts = src:split("\\/")
    table.remove(parts, 1) -- first part will be "@^"
    -- without "Data Files"/"MWSE"/"mods"/
    local lua_parts = table.filterarray(parts, function(i) return i >= 4 end)

    ---@type herbert.lib.utils.mod_info
    ---@diagnostic disable-next-line: missing-fields
    local info = {
        parts = parts, 
        lua_parts = lua_parts, 
        filename = parts[#parts],
        lua_parent_name = parts[3],
        path = table.concat(parts, "\\"),
        lua_path = table.concat(lua_parts, "\\"),
    }
    info.dir = info.path:sub(1, -#info.filename - 2) -- -1 because it's lua, then another -1 to kill the "\\"
    local metadata = tes3.getLuaModMetadata(lua_parts[1] .. "." .. lua_parts[2]) ---@type MWSE.Metadata?
    if metadata then
        info.dir_has_author_name = true
        -- table.remove(parts, 1)
    else
        metadata = tes3.getLuaModMetadata(lua_parts[1])
        
    end
    if metadata then
        info.metadata = metadata
        info.dir_has_author_name = info.dir_has_author_name or false
    else
        local one_dir_up = table.concat({"Data Files", "MWSE", "mods", lua_parts[1]}, "\\")
        info.dir_has_author_name = not (lfs.fileexists(one_dir_up .. "\\main.lua") or lfs.fileexists(one_dir_up .. "\\init.lua"))
    end

    local mod_name, mod_dir

    if metadata then
        local package = metadata.package
        if package then
            ---@diagnostic disable-next-line: undefined-field
            info.short_mod_name = package.short_name or package.shortName
            mod_name = package.name
        end
        if metadata.tools and metadata.tools.mwse then
            mod_dir = metadata.tools.mwse["lua-mod"]
        end
    end

    -- actual mod information starts at index 2 if there's an author name
    local cutoff

    if info.dir_has_author_name and #lua_parts > 2 then
        -- e.g. mod_dir = "herbert100.more quickloot"
        mod_dir = mod_dir or (lua_parts[1] .. "." .. lua_parts[2])
        cutoff = 2
    else
        -- e.g. mod_dir = "Expeditious Exit"
        mod_dir = mod_dir or lua_parts[1]
        cutoff = 1
    end
    -- if the module name doesn't exist, use the mod folder name (excluding the author name)
    mod_name = mod_name or lua_parts[cutoff]

    info.mod_name = mod_name
    info.mod_dir = mod_dir

    return info
end



function utils.get_mod_name(offset)
    offset = offset
    local info = utils.get_active_mod_info(offset)
    if info then
        return info.mod_name
    end
end

function utils.get_mod_dir(offset)
    local info = utils.get_active_mod_info(offset)
    if info then
        return info.mod_dir
    end
end

--- given a relative path, this function will load the active mods `mod_name`, and then `require` the 
    -- file with path `mod_dir .. "." .. relative_path`
    -- the above moduel will be returned by this function
---@param relative_path string
---@param offset integer? how many levels deep this is getting called
---@return any module the module, if it exists
function utils.import(relative_path, offset)
    if not relative_path then
        error(debug.traceback("no path was provided."))
    end
    local mod_dir = utils.get_mod_dir((offset or 0) + 1)
    if not mod_dir then
        error(debug.traceback("mod directory could not be found."))
    end
    return require(table.concat{mod_dir, ".", relative_path})
end

--- given a relative path, this function will load the active mods `mod_name`, and then call `dofile` on the 
    -- file with path `mod_dir .. "." .. relative_path`
    -- the above module will be returned by this function
---@param relative_path string
---@param offset integer? how many levels deep this is getting called
---@return any module the module, if it exists
function utils.dofile(relative_path, offset)
    if not relative_path then
        error(debug.traceback("no path was provided."))
    end
    local mod_dir = utils.get_mod_dir((offset or 0) + 1)
    if not mod_dir then
        error(debug.traceback("mod directory could not be found."))
    end
    return dofile(table.concat{mod_dir, ".", relative_path})
end

--- returns the config of the active mod file. 
-- this is basically just a wrapper for `import` that sets `relative_path = "config"`
---@param offset integer?
function utils.get_mod_config(offset)
    local mod_dir = utils.get_mod_dir((offset or 0) + 1)
    if not mod_dir then
        error(debug.traceback("mod directory could not be found."))
    end
    return require(mod_dir .. ".config")
end

-- function utils.get_mod_config(offset)
    
--     offset = offset
--     local info = utils.get_active_mod_info(offset)
--     -- mwse.log("got info = %s. \n\tused offset = %s", json.encode(info), offset or "nil")
--     if info and info.mod_dir then
--         local cfg_path = info.mod_dir .. ".config"
--         -- mwse.log("trying to load cfg with path = %q", cfg_path)
--         local cfg = include(cfg_path)
--         return cfg
--     end
-- end

---@alias hlib.config {[string|integer]: any}

-- helper function for my suggested rewrite of `mwse.loadConfig`. but this is also useful for player data
-- this function is responsible for fixing tables that were encoded via `json.encode`. specifically:
-- 1) restoring numeric keys (i.e. keys that should be numbers, but were turned into strings by `json.encode`)
-- 2) adding missing values to `tbl` that are present in `default`
--
-- both of these things need to be done recursively, so it's not possible to use `table.copymissing`.
-- (i.e., we may need to alternate between converting integer keys and adding missing values)
---@generic T : hlib.config
---@param tbl table
---@param default T
---@return T
function utils.fix_decoded_table(tbl, default)
	local tbl_val
	for key, default_val in pairs(default) do
		tbl_val = tbl[key]

		-- check if we need to convert a string key to a numeric key
		if tbl_val == nil and type(key) == "number" and tbl[tostring(key)] ~= nil then
			tbl[key] = tbl[tostring(key)]
			tbl[tostring(key)] = nil
			tbl_val = tbl[key]
		end

		-- recheck the config value because it may have changed in the last code block
		if tbl_val ~= nil then
			-- if the default value is a table, we need to fix values recursively
			if type(default_val) == "table" and type(tbl_val) == "table" then
				utils.fix_decoded_table(tbl_val, default_val)
			else
				-- no change needed
			end
		else -- configValue == nil
			-- make sure the config gets a copy of any subtables
			if type(default_val) == "table" then
				tbl[key] = table.deepcopy(default_val)
			else
				tbl[key] = default_val
			end
		end
	end
    return tbl
end
-- loads a config. unlike `mwse.loadConfig`, this function will add missing entries to subtables that have integer keys. 
-- (at least, as of writing this. i made a PR that attempts to fix that bug)
-- this function also does not require specifying a `mod_name` or a `default_config`. (both will be fetched automatically if they exist)
---@generic C : hlib.config
---@param modname_or_default_or_nil nil|string|C
---@param default_config_or_nil nil|C the default config, or the relative path to the default config. if not provided, then the path `config.default` will be used.
---@return C?
function utils.load_config(modname_or_default_or_nil, default_config_or_nil)

    local mod_name, default_config
    
    if default_config_or_nil then
        mod_name = modname_or_default_or_nil
        default_config = default_config_or_nil
    else

        if modname_or_default_or_nil and type(modname_or_default_or_nil) ~= "string" then
            default_config = modname_or_default_or_nil
        end
    end
    
    if default_config and type(default_config) ~= "table" then
        -- if type(default_config) == "string" then
        --     default_path = default_config
        -- end
        default_config = nil
    end

    if not mod_name or not default_config then

        local info = utils.get_active_mod_info()
        if not info then -- we know one of `mod_name` or `default_config` is `nil`
            return mod_name and json.decode("config/" .. mod_name)
                or default_config and table.deepcopy(default_config)
        end

        mod_name = mod_name or info.mod_name
        default_config = default_config or include(info.mod_dir .. ".config.default")
        -- if not default_config then
        --     -- default_path = default_path:gsub("[/\\]", ".")
        --     -- if not default_path:startswith(".") then 
        --     --     default_path = "." .. default_path 
        --     -- end
        --     default_config = include(info.mod_dir .. default_path)
        -- end
    end

    local cfg = mod_name and json.loadfile("config/" .. mod_name)

    return cfg and default_config and utils.fix_decoded_table(cfg, default_config) 
        or cfg
        or default_config and table.deepcopy(default_config) 
end


-- this is like `mwse.loadConfig`, but for player data. you pass in a `key` and a `player_data` structure, and then the player
-- data is loaded from `tes3.player` and returned. this function also sanitizes the player data in the following ways:
-- 1) if `tes3.player.data[key]` doesnt exist, then it will be created.
-- 2) missing values in `tes3.player.data[key]` will be created using `default_data`.
-- 3) `string` keys will be converted to `number` keys using `default_data` (just like in `mwse.loadConfig`)
---@generic D
---@param key string|integer key to the player data in `tes3.player.data`. if `key` contains ".", then subtables will be checked (and created if necessary)
---@param default_data nil|D the default config, or the relative path to the default config. if not provided, then the path `config.default` will be used.
---@return nil|D player_data if this was successful. otherwise `nil`. (which can happen if `tes3.player` is `nil`, for example. or if `key` or `default_data` weren't provided)
function utils.load_player_data(key, default_data)
    if not tes3.player or not key then return end

    local player_data
    local tk = type(key)
    if tk == "number" or tk == "string" and not key:find(".", 1, true) then
        player_data = table.getset(tes3.player.data, key, {})
    else
        for k in key:gmatch("[^%.]") do
            player_data =  table.getset(tes3.player.data, k, {})
        end
    end
    return default_data and utils.fix_decoded_table(player_data, default_data)
        or player_data
end

return utils