---@class herbert.lib.utils
local hlib = {
    -- =========================================================================
    -- FUNCTIONS
    -- =========================================================================

    

    --- append tables to the current ones. basically `table.copymissing`, 
    -- but with support for an arbitrary number of tables.
    -- tables passed earlier will take precedence
    ---@param tbl table
    ---@param ... table
    ---@return nil
    table_append = function(tbl, ...)
        for _, t in ipairs{...} do
            if t then 
                for k,v in pairs(t) do
                    if tbl[k] == nil then 
                        tbl[k] = v 
                    end
                end 
            end
        end
    end,

    --- append tables to the current ones. basically `table.copymissing`, 
    -- but with support for an arbitrary number of tables.
    -- tables passed last will take precedence
    ---@param tbl table
    ---@param ... table
    table_append_reverse_order = function(tbl, ...)
        local tables = {...}
        for i=#tables, 1, -1 do 
            local t = tables[i]
            if t then
                for k,v in pairs(t) do
                    if tbl[k] == nil then
                        tbl[k] = v
                    end
                end
            end
        end
    end,

    --- combine multiple tables together. later tables will take precedence over earlier tables.
    ---@param ... table tables to combine into one table
    ---@return table result the table formed by combining all of the passed tables
    table_combine = function(...)
        local tbl = {}
        for _, t in ipairs{...} do
            if t then
                for k,v in pairs(t) do
                    tbl[k] = v
                end
            end
        end
        return tbl
    end,

    --- registers an event if it should be registered, deregisters it otherwise.
    ---@class herbert.update_registration_params
    ---@field [1] tes3.event|nil
    ---@field [2] fun(e)|nil
    ---@field event tes3.event? the event to register/unregister
    ---@field callback fun(e)|nil
    ---@field priority integer?
    ---@field old_priority integer?
    ---@field filter any
    ---@field old_filter any
    ---@field register boolean? if true, the event will be registered. if false, the event will be unregistered. Default: `true`

    --- registers an event if it should be registered, unregisters it otherwise.
    -- you can pass an old priority or old filter to unregister events when settings have changed
    ---@param p herbert.update_registration_params
    ---@return boolean something_changed whether an event was registered/unregistered
    update_registration = function(p)
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
    end,

    --- copy all values 
    ---@param from table
    ---@param ... table
    ---@return table copied
    table_copy_except = function(from, ...)
        local to, filters
        if select("#", ...) >= 2 then
            to, filters = ...
        else
            to, filters = {}, ...
        end

        local excluded = {}
        if filters[1] == nil or filters[1] == true then
            excluded = filters
        else
            for _, v in ipairs(filters) do
                excluded[v] = true
            end
        end

        for k,v in pairs(from) do
            if not excluded[k] then
                to[k] = v
            end
        end

        return to
    end,

    



}
---@class herbert.lib.utils.mod_info
---@field lua_path string relative lua path to the file
---@field path string the full path to the file
---@field lua_parent_name "mods"|"lib"|"core" the directory the `lua_path` is contained in
---@field lua_parts string[] the different parts of the directory (using the relative lua syntax)
---@field parts string[] the different parts of the directory
---@field dir string the directory the file is contained in 
---@field dir_has_author_name boolean? is the first entry of `dir_parts` the name of the mod author folder?
---@field filename string the name of the file (without the directory present)
---@field metadata MWSE.Metadata? the metadata of the mod (if it has any)


---@param offset integer? how many levels deep this function is being called. default is 0,
-- but you should increase this by 1 for every layer of nesting that's going on
---@return herbert.lib.utils.mod_info? info about the mod, if possible
function hlib.get_active_mod_info(offset)
    local src = debug.getinfo(3 + (offset or 0), "S").source
    if not src then return end
    local parts = src:split("\\/")
    table.remove(parts, 1) -- first part will be "@^"
    -- without "Data Files"/"MWSE"/"mods"/
    local lua_parts = table.filterarray(parts, function (i) return i >= 4 end)

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
    return info
end



function hlib.table_combine_missing(...)
    local t = {}
    hlib.table_append(t, ...)
    return t
end


---@deprecated
hlib.table_concat = hlib.table_combine


return hlib