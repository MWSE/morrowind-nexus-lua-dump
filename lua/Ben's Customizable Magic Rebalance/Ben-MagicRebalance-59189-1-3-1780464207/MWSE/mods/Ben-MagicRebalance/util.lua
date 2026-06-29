local this = {}

--------------------------------------------------
-- SORT HELPERS
--------------------------------------------------

-- if sortFunction is nil, sorts by key asc
local function sortedPairs(sourceTable, sortFunction)

    local sortedTable = {}
    for key, _ in pairs(sourceTable) do table.insert(sortedTable, key) end
    table.sort(sortedTable, sortFunction)

    local i = 0 -- iterator variable
    local iteratorFunction = function ()

        i = i + 1
        if sortedTable[i] == nil then return nil
        else return sortedTable[i], sourceTable[sortedTable[i]] end

    end

    return iteratorFunction

end

this.sortedPairs = sortedPairs

local function sortFunction_ByStringKey(keyA, keyB)

    local keyLowerA = string.lower(keyA)
    local keyLowerB = string.lower(keyB)

    if keyLowerA ~= keyLowerB then return keyLowerA < keyLowerB end
    return keyA < keyB

end

this.sortFunction_ByStringKey = sortFunction_ByStringKey

local function getSortFunction_ByValueThenKey(tableToSort)

    return function(keyA, keyB)

        local valueA = tableToSort[keyA]
        local valueB = tableToSort[keyB]

        if valueA ~= valueB then return valueA < valueB end
        return keyA < keyB

    end

end

this.getSortFunction_ByValueThenKey = getSortFunction_ByValueThenKey

local function getSortFunction_ByKeyLengthDescThenKeyThenValue(tableToSort)

    return function (keyA, keyB)

        local keyLengthA = string.len(keyA)
        local keyLengthB = string.len(keyB)

        if keyLengthA ~= keyLengthB then return keyLengthA > keyLengthB end

        local keyLowerA = string.lower(keyA)
        local keyLowerB = string.lower(keyB)

        if keyLowerA ~= keyLowerB then return keyLowerA < keyLowerB end
        if keyA ~= keyB then return keyA < keyB end

        local valueA = tableToSort[keyA]
        local valueB = tableToSort[keyB]

        return valueA < valueB

    end

end

this.getSortFunction_ByKeyLengthDescThenKeyThenValue = getSortFunction_ByKeyLengthDescThenKeyThenValue

local function getSortFunction_ByValueNameThenKey(tableToSort)

    return function(keyA, keyB)

        local valueA = tableToSort[keyA]
        local valueB = tableToSort[keyB]

        if valueA.name ~= valueB.name then return valueA.name < valueB.name end
        return keyA < keyB

    end

end

this.getSortFunction_ByValueNameThenKey = getSortFunction_ByValueNameThenKey

--------------------------------------------------
-- TABLE HELPERS | RECURSIVE
--------------------------------------------------

-- tostring() alternative that handles tables
local function tableToString(var)

    if type(var) == "table" then

        local str = "{ "

        for key, value in sortedPairs(var) do
            str = str .. "[" .. tableToString(key) .. "] = " .. tableToString(value) .. ", "
        end

        return str .. "}"

    elseif type(var) == "string" then

        var = string.gsub(var, "\n", "|")
        return '"' .. var .. '"'

    end

    return tostring(var)

end

this.tableToString = tableToString

-- return deep copy of input
local function deepCopy(input)

    if type(input) ~= "table" then
        return input
    end

    local output = {}

    for key, value in pairs(input) do
        output[deepCopy(key)] = deepCopy(value)
    end

    return output

end

this.deepCopy = deepCopy

-- deep copy values in source to target
local function deepMerge(target, source)

    for key, value in pairs(source) do

        if type(value) == "table" then

            if target[key] == nil then target[key] = {} end
            deepMerge(target[key], value)

        else

            target[key] = value

        end

    end

end

this.deepMerge = deepMerge

-- if key does not exist in target, deep copy value from source
local function deepMergeWhenNil(target, source)

    for key, value in pairs(source) do

        if type(value) == "table" then

            if target[key] == nil then target[key] = {} end
            deepMergeWhenNil(target[key], value)

        elseif target[key] == nil then

            target[key] = value

        end

    end

end

this.deepMergeWhenNil = deepMergeWhenNil

-- if key does not exist in source, remove it from target
local function deepRemoveMissingKeys(target, source)

    for key, value in pairs(target) do

        if type(value) ~= type(source[key]) then

            target[key] = nil

        elseif type(value) == "table" then

            deepRemoveMissingKeys(value, source[key])

        end

    end
end

this.deepRemoveMissingKeys = deepRemoveMissingKeys

local function fixNumberKeys(var)

    -- Lua does not support non-string keys in JSON
    -- number keys are converted to strings when serialized
    -- this function converts those keys back to numbers

    local keysToFix = {}

    for key, value in pairs(var) do

        if type(key) == "string" then
            local number = tonumber(key)
            if number ~= nil then keysToFix[key] = number end
        end

        if type(value) == "table" then
            fixNumberKeys(value)
        end

    end

    -- do not modify var in the loop above, that results
    -- in unpredictable table iteration and missed keys
    for stringKey, numberKey in pairs(keysToFix) do
        var[numberKey] = var[stringKey]
        var[stringKey] = nil
    end

end

this.fixNumberKeys = fixNumberKeys

--------------------------------------------------
-- TABLE HELPERS | NON-RECURSIVE
--------------------------------------------------

local function isEmpty(table)

    for _, _ in pairs(table) do
        return false
    end

    return true

end

this.isEmpty = isEmpty

local function count(tableToCount)

    local count = 0

    for key, _ in pairs(tableToCount) do
        count = count + 1
    end

    return count

end

this.count = count

local function removeAllElements(table)

    for key, _ in pairs(table) do
        table[key] = nil
    end

end

this.removeAllElements = removeAllElements

local function getFirstKeyIfOnlyOneElement(tableToSearch)

    local count = 0
    local onlyKey = nil

    for key, _ in pairs(tableToSearch) do
        count = count + 1
        if count > 1 then return nil end
        onlyKey = key
    end

    return onlyKey

end

this.getFirstKeyIfOnlyOneElement = getFirstKeyIfOnlyOneElement

local function getFirstValueIfOnlyOneElement(tableToSearch)

    local count = 0
    local onlyValue = nil

    for _, value in pairs(tableToSearch) do
        count = count + 1
        if count > 1 then return nil end
        onlyValue = value
    end

    return onlyValue

end

this.getFirstValueIfOnlyOneElement = getFirstValueIfOnlyOneElement

local function getHighestValue(tableToSearch)

    local highestValue = nil

    for _, value in pairs(tableToSearch) do
        if highestValue == nil or value > highestValue then
            highestValue = value
        end
    end

    return highestValue

end

this.getHighestValue = getHighestValue

local function getSetFromRange(minKey, maxKey)

    local output = {}

    for i = minKey, maxKey do
        output[i] = true
    end

    return output

end

this.getSetFromRange = getSetFromRange

--------------------------------------------------
-- NUMBER HELPERS
--------------------------------------------------

local function numberToString(number, precision)
    return string.format("%." .. precision .. "f", number)
end

this.numberToString = numberToString

local function round(number, precision)
    return tonumber(numberToString(number, precision))
end

this.round = round

local function clamp(number, minValue, maxValue)

    if minValue ~= nil and number < minValue then return minValue end
    if maxValue ~= nil and number > maxValue then return maxValue end

    return number

end

this.clamp = clamp

local function getNumber(var, defaultValue, minValue, maxValue)

    if type(var) ~= "number" then return defaultValue end
    return clamp(var, minValue, maxValue)

end

this.getNumber = getNumber

local function zeroAsNil(number)
    if number == 0 then return nil end
    return number
end

this.zeroAsNil = zeroAsNil

--------------------------------------------------
-- STRING HELPERS
--------------------------------------------------

local function capitalizeFirstLetter(str)
    return string.gsub(str, "^%l", string.upper)
end

this.capitalizeFirstLetter = capitalizeFirstLetter

local function getCaseInsensitivePattern(str)

    -- escape magic characters
    str = string.gsub(str, "[%(%)%.%%%+%-%*%?%[%^%$]", function(magicCharacter)
        return "%" .. magicCharacter
    end)

    -- make letters case-insensitive
    str = string.gsub(str, "%a", function(letter)
        return string.format("[%s%s]", letter:lower(), letter:upper())
    end)

    return str

end

this.getCaseInsensitivePattern = getCaseInsensitivePattern

--------------------------------------------------
-- BOOLEAN HELPERS
--------------------------------------------------

local function getYesNoString(bool)

    if bool then return "Yes" end
    return "No"

end

this.getYesNoString = getYesNoString

return this
