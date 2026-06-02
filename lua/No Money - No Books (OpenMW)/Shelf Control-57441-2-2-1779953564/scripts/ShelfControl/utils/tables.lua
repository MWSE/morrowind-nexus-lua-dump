---Checks if table is empty.
---
---Edgecases:
---
--- - list == nil -> true
---@param list table
---@return boolean
function TableIsEmpty(list)
    if list == nil then
        return true
    end
    return next(list) == nil
end

function AppendArray(dest, src)
    for _, v in ipairs(src) do
        table.insert(dest, v)
    end
end

--- Recursively print a table with indentation.
--- Handles nested tables and avoids infinite loops via cycle detection.
--- @param t table             Table to print
--- @param indent number|nil   Current indentation level (internal)
--- @param visited table|nil   Cycle tracking table (internal)
function PrintTable(t, indent, visited)
    indent  = indent or 0
    visited = visited or {}

    if visited[t] then
        print(string.rep(" ", indent) .. "*CYCLE*")
        return
    end

    visited[t] = true

    for k, v in pairs(t) do
        local prefix = string.rep(" ", indent) .. tostring(k) .. ": "

        if type(v) == "table" then
            print(prefix)
            PrintTable(v, indent + 2, visited)
        else
            print(prefix .. tostring(v))
        end
    end
end
