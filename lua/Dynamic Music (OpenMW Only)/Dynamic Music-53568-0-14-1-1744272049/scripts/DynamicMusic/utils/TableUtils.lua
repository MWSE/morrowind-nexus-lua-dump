local TableUtils = {}

---Adds all the keys and values from the secondary table to the primary table.
---@param primaryTable table The primary table.
---@param secondaryTable table The secondary table.
function TableUtils.addAll(primaryTable, secondaryTable)
    for _, e in pairs(secondaryTable) do
        table.insert(primaryTable, e)
    end
end

---Removes all elements from a table and sets the keys to nil
---@param tab table
function TableUtils.clear(tab)
    for k, _ in pairs(tab) do
        tab[k] = nil
    end
end

---Returns the first element of a table if it has one.
---@generic K, V
---@param tab table<K,V>
---@return K
function TableUtils.getFirstElement(tab)
    for _, e in pairs(tab) do
        return e
    end
end

---Maps elements of a table into a new new table.
---@generic T, U
---@param tab table<T> Table with elements of `T` that should be mapped to `U`.
---@param mapper fun(t: T):U Function that maps objects of `T` to `U`.
---@return table<U> table A new table that contains the mapped elements.
function TableUtils.map(tab, mapper)
    local mappedElements = {}

    for _, e in pairs(tab) do
        table.insert(mappedElements, mapper(e))
    end

    return mappedElements
end

---Counts the keys in the given table.
---@param tab table
---@return integer count The number of keys in the given table.
function TableUtils.countKeys(tab)
    local counter = 0

    for _, _ in pairs(tab) do
        counter = counter + 1
    end

    return counter
end

---Clears the given primary table and then adds all the keys and values from the secondary table to the primary table.
---@param primaryTable table The primary table.
---@param secondaryTable table The secondary table.
function TableUtils.setAll(primaryTable, secondaryTable)
    TableUtils.clear(primaryTable)
    TableUtils.addAll(primaryTable, secondaryTable)
end

return TableUtils
