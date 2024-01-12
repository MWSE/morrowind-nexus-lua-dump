local useful_functions = {}

--- append tables to the current ones
---@param tbl table
---@param ... table
function useful_functions.table_append(tbl, ...)
    for _, t in ipairs({...}) do
        if type(t) == "table" then
            for k,v in pairs(t) do
                if tbl[k] == nil then
                    tbl[k] = v
                end
            end
        end
    end
end
--- append tables to the current ones. earlier values will take precedence. nothing will be overwritten.
---@param tbl table
---@param ... table
function useful_functions.table_append_reverse_order(tbl, ...)
    local tables = {...}
    for i=#tables, 1, -1 do 
        local t = tables[i]
        if type(t) == "table" then
            for k,v in pairs(t) do
                if tbl[k] == nil then
                    tbl[k] = v
                end
            end
        end
    end
end
--- concatenate multiple tables together. later tables will take precedence over earlier tables.
---@param ... table
---@return table
function useful_functions.table_concat(...)
    local table, tables = {}, {...}
    for _, t in ipairs(tables) do
        if type(t) == "table" then
            for k,v in pairs(t) do
                table[k] = v
            end
        end
    end
    return table
end
--- make a copy of a table
---@param t table the taby to make a copy of
---@return table t_copy a copy of `t`
function useful_functions.table_copy(t)
    local t_copy = {}
    for k,v in pairs(t) do 
        t_copy[k] = v
    end
    return t
end

--- tostring method for tabletraverse
---@param t table # the table to print as a string
---@param depth integer? # the current printing depth, to make sure we dont loop forever with weirdly defined tables
---@param debug_mode boolean? # should we print everything? if false|nil, we ignore things starting with "_"
---@return string
local function ts(t, depth, debug_mode, padding_offset)
    depth = depth or 0
    padding_offset = padding_offset or 0
    local s = ""
    local padding = string.rep("    ", depth+padding_offset+1)
    for k,v in pairs(t) do
        -- only print strings that don't start with "_", unless we're in debug mode
        if (not (type(k) == "string" and k:byte(1) == string.byte("_"))) or debug_mode  then
            -- print(debug_mode)
            local v_str = ""
            if type(v) == "table" then
                -- recursively print it if the depth is okay
                if depth <= 3 then
                    v_str = ts(v, depth + 1,debug_mode)
                else
                    -- just print that its a table and move on
                    v_str = type(v) 
                end
            elseif type(v) == "function" then 
                v_str = type(v)
            else
                v_str = tostring(v) 
            end
            
            s = s .. "\n" .. padding .. k .. " = " .. v_str .. ","
        end
    end
    return "{" .. s .. "\n" .. string.rep("    ", depth+padding_offset) .. "}"
end

useful_functions.tostring = ts



--- registers an event if it should be registered, deregisters it otherwise.
---@class herbert.update_registration_params
---@field event tes3.event the event to register/unregister
---@field callback fun(e)
---@field priority integer?
---@field filter any
---@field register boolean if true, the event will be registered. if false, the event will be unregistered

--- registers an event if it should be registered, unregisters it otherwise.
---@param params herbert.update_registration_params
function useful_functions.update_registration(params)
    local options
    if params.filter or params.priority then
        options = {filter=params.filter, priority=params.priority}
    end

	local registered = event.isRegistered(params.event, params.callback, options)
	if params.register then
		if not registered then event.register(params.event, params.callback, options) end
	else
		if registered then event.unregister(params.event, params.callback, options) end
	end
end

return useful_functions