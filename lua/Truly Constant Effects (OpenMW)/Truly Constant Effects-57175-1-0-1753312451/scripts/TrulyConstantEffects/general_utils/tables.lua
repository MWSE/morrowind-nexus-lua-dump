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

---Returns amount of keys in the list.
---@param list table
---@return integer
function TableSize(list)
    if TableIsEmpty(list) then
        return 0
    end

    local size = 0
    for _ in pairs(list) do
        size = size + 1
    end
    return size
end

---Prints the provided table in the console. Example:
---
---\> key: {k} | value: {v}
---
---@param list table
function PrintTable(list)
    if not TableIsEmpty(list) then
        for k, v in pairs(list) do
            print("> key: " .. tostring(k) .. " | value: " .. tostring(v))
        end
        print("")
    else
        print("Provided " .. tostring(list) .. " was empty")
        print("")
    end
end

---Returns copy of the provided table.
---@param list table
---@return table
function CopyTable(list)
    return { table.unpack(list) }
end

---Check if both tables have same values
---@param t1 table
---@param t2 table
---@return boolean
function TablesAreSame(t1, t2)
    if #t1 ~= #t2 then return false end
    for k, v in pairs(t1) do
        if t2[k] ~= v then return false end
    end
    for k, v in pairs(t2) do
        if t1[k] ~= v then return false end
    end
    return true
end
