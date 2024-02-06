---@class herbert.lib
local hlib = {
    Class = require("herbert100.Class"),
    Logger = require("herbert100.Logger"),
    math = require("herbert100.math"),
    MCM = require("herbert100.MCM"),

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
    ---@field register boolean if true, the event will be registered. if false, the event will be unregistered

    --- registers an event if it should be registered, unregisters it otherwise.
    -- you can pass an old priority or old filter to unregister events when settings have changed
    ---@param p herbert.update_registration_params
    ---@return boolean something_changed whether an event was registered/unregistered
    update_registration = function(p)
        local e = p[1] or p.event
        local c = p[2] or p.callback
        if p.old_filter or p.old_priority then
            local old_options = {filter=p.old_filter, priority=p.old_priority}
            if event.isRegistered(p.event, p.callback, old_options) then
                event.unregister(p.event, p.callback, old_options)
            end
        end
        local options = (p.filter or p.priority) and {filter=p.filter, priority=p.priority} 
            or nil

        local registered = event.isRegistered(p.event, p.callback, options)
        
        if p.register then
            if not registered then 
                event.register(p.event, p.callback, options)
                return true
            end
        else
            if registered then 
                event.unregister(p.event, p.callback, options)
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




function hlib.table_combine_missing(...)
    local t = {}
    hlib.table_append(t, ...)
    return t
end


---@deprecated
hlib.table_concat = hlib.table_combine


return hlib