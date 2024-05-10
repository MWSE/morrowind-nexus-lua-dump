---@class herbert.lib.utils
local utils = {}

local tbl_ext = require("herbert100.tbl_ext")

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
---@field lua_root "mods"|"lib"|"core" the directory the `lua_path` is contained in
---@field lua_parts string[] the different parts of the directory (using the relative lua syntax)
---@field dir_has_author_name boolean? is the first entry of `dir_parts` the name of the mod author folder?
---@field short_mod_name string? name of this mod
---@field mod_name string name of this mod
---@field mod_dir string directory of this mod
---@field metadata MWSE.Metadata? the metadata of the mod (if it has any)

local badfile_paths = {
    [string.lower("@Data Files\\MWSE\\core\\initialize.lua")] = true,
    [string.lower("@Data Files\\MWSE\\core\\startLuaMods.lua")] = true,
    [string.lower("=[C]")] = true,
}

local relative_path_start = string.len("@.\\data files\\mwse\\") + 1

---@param offset integer? what part of the stack to start searching at. 
-- this function will go up the stack until it finds a match (or fails), 
-- so it's fine to pass a value that's lower than you need, but it's not fine to pass a value that's higher than you need.
-- the default is `0`, which aligns with calling this function outside of any functions.
---@return herbert.lib.utils.mod_info?
function utils.get_mod_info(offset)
    
    local debug_info, new_debug_info, src_lower

    do -- get debug info
        local i = 1 + (offset or 0)
        while true do
            i = i + 1
            debug_info = new_debug_info
            new_debug_info = debug.getinfo(i, "S")
            
            if not new_debug_info then break end -- we've gone too high up the stack

            src_lower = new_debug_info.source:lower()
            -- mwse.log("src_lower = %q", src_lower)
            if badfile_paths[src_lower] then -- we've gone too high up the stack
                -- mwse.log("%q is a bad filepath!", src_lower)
                break
            end

            if not src_lower:find("^@.\\data files\\mwse\\lib\\herbert100\\") then -- weve gone just high enough to not hit a herbert lib file
                debug_info = new_debug_info
                break
            else
                -- mwse.log("%q matched \"%s\"", src_lower, "^@.\\data files\\mwse\\lib\\herbert100\\")
            end
        end
    end
         -- if we've gone too far up the stack
         -- we've gone just high enough to not hit a herbert lib file
    if not debug_info then return end

    local relative_path = debug_info.source:sub(relative_path_start) ---@type string
    -- mwse.log("relative_path = %q", relative_path)
    
    local lua_root, lua_parts = nil, {}
    do -- make lua_parts
        local i = 0
        for part in relative_path:gmatch("[^\\]+") do
            lua_parts[i] = part
            i = i + 1
        end
        lua_root = lua_parts[0]
        lua_parts[0] = nil
    end

    
    local lua_path = relative_path:sub(#lua_root + 2)

    -- local metadata = tes3.getLuaModMetadata(author_mod_dir_root) ---@type MWSE.Metadata?
        
    ---@type MWSE.Metadata?, boolean?, string?, string?, string?
    local metadata, has_author_name, mod_name, mod_dir, short_mod_name 
    
    local author_mod_dir_root = lua_parts[1] .. "." .. lua_parts[2]


    -- using runtimes will properly detect mod author folders even when the mods dont have any metadata

    ---@diagnostic disable-next-line: undefined-field
    local runtime = mwse.activeLuaMods[author_mod_dir_root]
    
    if runtime then
        metadata = runtime.metadata
        has_author_name = true
        -- table.remove(parts, 1)
    else
        ---@diagnostic disable-next-line: undefined-field
        runtime = mwse.activeLuaMods[lua_parts[1]]
        if runtime then
            metadata = runtime.metadata
            has_author_name = false
        end
    end

    if has_author_name == nil then
        -- local root = table.concat({"Data Files", "MWSE", lua_root, lua_parts[1]}, "\\")
        -- has_author_name = not (lfs.fileexists(root .. "\\main.lua") or lfs.fileexists(root .. "\\init.lua"))
        local check_path = table.concat({"Data Files", "MWSE", lua_root, lua_parts[1], "main.lua"}, "\\")
        has_author_name = not lfs.fileexists(check_path)
    end


    if metadata ~= nil then
        local package = metadata.package
        if package then
            ---@diagnostic disable-next-line: undefined-field
            short_mod_name = package.short_name or package.shortName
            mod_name = package.name
        end
        mod_dir = tbl_ext.recursive_get(metadata, "tools.mwse.lua-mod") or nil
        -- mwse.log("mod dir = %q", mod_dir or "N/A")
    end

    if mod_name == nil or mod_dir == nil then
        if has_author_name and #lua_parts > 2 then
            -- e.g. mod_dir = "herbert100.more quickloot"
            mod_dir = mod_dir or author_mod_dir_root
            mod_name = mod_name or lua_parts[2]
        else
            -- e.g. mod_dir = "Expeditious Exit"
            mod_dir = mod_dir or lua_parts[1]
            mod_name = mod_name or lua_parts[1]
        end
        -- if the module name doesn't exist, use the mod folder name (excluding the author name)
    end

    ---@type herbert.lib.utils.mod_info
    local info = {
        lua_root = lua_root,
        dir_has_author_name = has_author_name,
        mod_dir = mod_dir,
        mod_name = mod_name,
        metadata = metadata,
        short_mod_name = short_mod_name,
        lua_parts = lua_parts, 
        lua_path = lua_path,
    }
    -- mwse.log("returning info = %s", json.encode(info))
    return info
end
---@deprecated use `get_mod_info` instead. the difference is that implementation returns less information and is faster.
-- to get the `filename`, use `info.lua_parts[#info.lua_parts]`
function utils.get_active_mod_info(offset)
    local info = utils.get_mod_info((offset or 0) + 1)
    if info then
        ---@diagnostic disable-next-line: inject-field
        info.filename = info.lua_parts[#info.lua_parts]
        return info
    end
end



function utils.get_mod_name(offset)
    offset = offset
    local info = utils.get_mod_info(offset)
    if info then
        return info.mod_name
    end
end

function utils.get_mod_dir(offset)
    local info = utils.get_mod_info(offset)
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


local function semideepcopy(tbl)
    local res = {}

    for k, v in pairs(tbl) do
        if type(v) == "table" then
            res[k] = semideepcopy(v)
        else
            res[k] = v
        end
    end
    local meta = getmetatable(tbl)
    if meta then
        return setmetatable(res, meta)
    end
    return res
end

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
				tbl[key] = semideepcopy(default_val)
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

        local info = utils.get_mod_info()
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
    if tes3.player == nil or key == nil then return end

    local player_data = tbl_ext.recursive_getset(tes3.player.data, key, {})
    
    return default_data and utils.fix_decoded_table(player_data, default_data)
        or player_data
end

-- -- tries to retrieve player data, without loading it
-- function utils.get_player_data(key)
--     return key ~= nil and tes3.player ~= nil
--         and tbl_ext.recursive_get(tes3.player.data, key)
-- end

-- checks if a mod is installed. this is used because `tes3.isLuaModActive` may not be accurate if this mod is executed before the mod in question
---@param mod_path string path to the mod, so that the main file is located at "Data Files/MWSE/mods/<mod_path>/main.lua"
---@return boolean whether the mod is installed or not
function utils.is_mod_installed(mod_path)
    return lfs.fileexists(string.format("Data Files/MWSE/mods/%s/main.lua", mod_path:gsub("%.", "/")))
end

-- gets the name of a `tes3.scanCode`, using the appropriate GMSTs
-- this will return the same string used by the in-game Controls menu
---@param code tes3.scanCode
---@return string key_name
function utils.get_key_name(code)
    -- taken from https://github.com/MWSE/MWSE/pull/498
    return tes3.findGMST(tes3.gmst[string.format("sKeyName_%02X", code)]).value
end


return utils



-- ---@param offset integer? how many levels deep this function is being called. default is 0,
-- -- but you should increase this by 1 for every layer of nesting that's going on
-- ---@return herbert.lib.utils.mod_info? info about the mod, if possible
-- function utils.get_active_mod_info2(offset)

--     local debug_info, new_debug_info, src_lower

--     do -- get debug info
--         local i = 1 + (offset or 0)
--         while true do
--             i = i + 1
--             debug_info = new_debug_info
--             new_debug_info = debug.getinfo(i, "S")
            
--             if not new_debug_info then break end -- we've gone too high up the stack

--             src_lower = new_debug_info.source:lower()
--             mwse.log("src_lower = %q", src_lower)
--             if badfile_paths[src_lower] then -- we've gone too high up the stack
--                 mwse.log("%q is a bad filepath!", src_lower)

--                 break
--             end

--             if not src_lower:find("^@.\\data files\\mwse\\lib\\herbert100\\") then -- weve gone just high enough to not hit a herbert lib file
--                 debug_info = new_debug_info
--                 break
--             end
--             -- if src_lower:find("^@.\\data files\\mwse\\core\\") then
--             --     mwse.log("%q is a bad filepath!", src_lower)
--             -- end
--         end
--     end
--          -- if we've gone too far up the stack
--          -- we've gone just high enough to not hit a herbert lib file
--     if not debug_info then return end

--     local relative_path = debug_info.source:sub(relative_path_start)
--     mwse.log("relative_path = %q", relative_path)
    
--     local src = debug_info and debug_info.source

--     -- local parts = r

--     local parts = src:split("\\/")
--     table.remove(parts, 1) -- first part will be "@^"

--     -- without "Data Files"/"MWSE"/"mods"/
--     local lua_parts = tbl_ext.splice(parts, 4)

--     local path = table.concat(parts, "\\")
--     local lua_path = table.concat(lua_parts, "\\")

--     local filename = parts[#parts]
--     local dir = path:sub(1, -(#filename + 2)) -- -1 because it's lua, then another -1 to kill the "\\"
--     local author_mod_dir_root = lua_parts[1] .. "." .. lua_parts[2]
    
--     local metadata = tes3.getLuaModMetadata(author_mod_dir_root) ---@type MWSE.Metadata?





--     local has_author_name, mod_name, mod_dir, cutoff, short_mod_name


    

--     if metadata ~= nil then
--         has_author_name = true
--         -- table.remove(parts, 1)
--     else
--         metadata = tes3.getLuaModMetadata(lua_parts[1])
--         if metadata ~= nil then
--            has_author_name = false
--         end
--     end

--     if has_author_name == nil then
--         local one_dir_up = "Data Files\\MWSE\\mods\\" .. lua_parts[1]
--         has_author_name = not (lfs.fileexists(one_dir_up .. "\\main.lua") or lfs.fileexists(one_dir_up .. "\\init.lua"))
--     end


--     if metadata ~= nil then
--         local package = metadata.package
--         if package then
--             ---@diagnostic disable-next-line: undefined-field
--             short_mod_name = package.short_name or package.shortName
--             mod_name = package.name
--         end
--         mod_dir = tbl_ext.recursive_get(metadata, "tools.mwse.lua-mod") or nil
--         mwse.log("mod dir = %q", mod_dir or "N/A")
--         -- mod_dir = metadata.tools and metadata.tools.mwse and metadata.tools.mwse["lua-mod"] or nil
--     end

--     if has_author_name and #lua_parts > 2 then
--         -- e.g. mod_dir = "herbert100.more quickloot"
--         mod_dir = mod_dir or author_mod_dir_root
--         cutoff = 2
--     else
--         -- e.g. mod_dir = "Expeditious Exit"
--         mod_dir = mod_dir or lua_parts[1]
--         cutoff = 1
--     end
--     -- if the module name doesn't exist, use the mod folder name (excluding the author name)
--     mod_name = mod_name or lua_parts[cutoff]

--     local info = {
--         parts = parts,
--         dir=dir,
--         mod_dir=mod_dir,
--         mod_name=mod_name,
--         dir_has_author_name=has_author_name,
--         metadata=metadata,
--         short_mod_name=short_mod_name,
--         lua_parts = lua_parts, 
--         filename = filename,
--         lua_parent_name = parts[3],
--         path = path,
--         lua_path = lua_path,
--     }
--     mwse.log("returning info = %s", json.encode(info))
--     return info
-- end