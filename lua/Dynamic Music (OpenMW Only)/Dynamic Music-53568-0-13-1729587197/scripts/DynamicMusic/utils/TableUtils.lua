local TableUtils = {}

function TableUtils.addAll(tab, newElements)
    for _, e in pairs(newElements) do
        table.insert(tab, e)
    end
end

function TableUtils.clear(tab)
    for k, _ in pairs(tab) do
        tab[k] = nil
    end
end

function TableUtils.getFirstElement(tab)
    for _, e in pairs(tab) do
        return e
    end
end

function TableUtils.map(elements, mapper)
    local mappedElements = {}

    for _, e in pairs(elements) do
        table.insert(mappedElements, mapper(e))
    end

    return mappedElements
end

function TableUtils.countKeys(tab)
    local counter = 0

    for _, e in pairs(tab) do
        counter = counter + 1
    end

    return counter
end

function TableUtils.setAll(tab, newElements)
    TableUtils.clear(tab)
    TableUtils.addAll(tab, newElements)
end

return TableUtils
