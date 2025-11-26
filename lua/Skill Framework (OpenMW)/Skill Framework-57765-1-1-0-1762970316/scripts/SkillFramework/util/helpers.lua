local Helpers = {}

Helpers.shallowCopy = function(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

Helpers.deepCopy = function(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            copy[k] = Helpers.deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

Helpers.deepPrint = function(tbl, indent)
    indent = indent or 0
    local toprint = string.rep(" ", indent) .. "{\n"
    indent = indent + 2 
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint  .. k ..  " = "   
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\n"
        elseif (type(v) == "table") then
            toprint = toprint .. Helpers.deepPrint(v, indent + 2) .. ",\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent-2) .. "}"
    return toprint
end

Helpers.uiDeepPrint = function(layoutOrElement, lvl)
    lvl = lvl or 0
    local isElement = type(layoutOrElement) == 'userdata'
    local layout = isElement and layoutOrElement.layout or layoutOrElement
    if layout.name then
        print(string.rep('-', lvl), layoutOrElement, layout.name)
    end
    if layout.content then
        for _, child in pairs(layout.content) do
            Helpers.uiDeepPrint(child, lvl + 1)
        end
    end
end

-- Checks if two tables contain the same elements (ignoring order)
Helpers.tableEquals = function(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then
        return t1 == t2
    end
    local t1Keys = {}
    local t2Keys = {}
    for k in pairs(t1) do table.insert(t1Keys, k) end
    for k in pairs(t2) do table.insert(t2Keys, k) end
    table.sort(t1Keys)
    table.sort(t2Keys)
    if #t1Keys ~= #t2Keys then return false end
    for i = 1, #t1Keys do
        if t1Keys[i] ~= t2Keys[i] then return false end
        if not Helpers.tableEquals(t1[t1Keys[i]], t2[t2Keys[i]]) then return false end
    end
    return true
end

Helpers.roundToPlaces = function(num, places)
    local mult = 10^(places or 0)
    return math.floor(num * mult + 0.5) / mult
end

--- @generic T
--- @param tbl T The table to make read-only
--- @param whitelist? table A table of keys that are allowed to be modified
--- @param blacklist? table A table of keys that are not allowed to be modified
--- @param changedCallback? fun(before: T, after: T) A callback function that is called with copies of the table before and after a writable key is changed
--- @return T proxy A read-only proxy of the input table
Helpers.makeReadOnly = function(tbl, whitelist, blacklist, changedCallback)
    local proxy = {}
    local mt = {
        __index = tbl,
        __newindex = function(t, key, value)
            if (whitelist and not whitelist[key]) or (blacklist and blacklist[key]) then
                error("Attempt to modify read-only key: " .. tostring(key), 2)
            else
                local beforeCopy = Helpers.deepCopy(tbl)
                rawset(tbl, key, value)
                local afterCopy = Helpers.deepCopy(tbl)
                if changedCallback then
                    changedCallback(beforeCopy, afterCopy)
                end
            end
        end,
        __pairs = function()
            return pairs(tbl)
        end,
        __ipairs = function()
            return ipairs(tbl)
        end,
        __len = function()
            return #tbl
        end
    }
    setmetatable(proxy, mt)
    return proxy
end

--- Iterates over an array of event handlers, calling each in turn until one returns false.
--- @source OpenMW latest: aux_util.callEventHandlers
--- @param handlers? function[] An array of event handler functions.
--- @param ...? any Arguments to pass to each handler.
--- @return boolean handled True if no further handlers should be called.
Helpers.callEventHandlers = function(handlers, ...)
    if handlers then
        for i = #handlers, 1, -1 do
            if handlers[i](...) == false then
                return true
            end
        end
    end
    return false
end

return Helpers