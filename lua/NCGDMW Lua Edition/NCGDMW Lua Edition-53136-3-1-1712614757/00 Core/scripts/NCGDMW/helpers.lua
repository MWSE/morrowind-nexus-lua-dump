local function findIndex(table, value)
    for i = 1, #table do
        if table[i] == value then
            return i
        end
    end
end

local function capitalize(s)
    -- THANKS: https://stackoverflow.com/a/2421843
    return s:sub(1, 1):upper() .. s:sub(2)
end

local function randInt(rangeStart, rangeEnd)
    math.randomseed(os.time())
    return math.random(rangeStart, rangeEnd)
end

local function replaceTableValues(target, source)
    for k, _ in pairs(target) do
        target[k] = nil
    end
    for k, v in pairs(source) do
        target[k] = v
    end
end

local function insertMultipleInArray(source, values)
    for _, value in ipairs(values) do
        table.insert(source, value)
    end
end

local function insertAtMultipleInArray(source, pos, values)
    for i, value in ipairs(values) do
        table.insert(source, pos + i - 1, value)
    end
end

return {
    findIndex = findIndex,
    capitalize = capitalize,
    randInt = randInt,
    replaceTableValues = replaceTableValues,
    insertMultipleInArray = insertMultipleInArray,
    insertAtMultipleInArray = insertAtMultipleInArray,
}
