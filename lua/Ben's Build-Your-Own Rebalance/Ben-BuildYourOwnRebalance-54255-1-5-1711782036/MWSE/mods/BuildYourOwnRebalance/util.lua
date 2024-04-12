this = {}

--------------------------------------------------
-- TABLE HELPERS | RECURSIVE
--------------------------------------------------

-- tostring() alternative that handles tables
function tableToString(var)
    
    if type(var) == "table" then
        
        local str = "{ "
        
        for key, value in pairs(var) do
            str = str .. "[" .. tableToString(key) .. "] = " .. tableToString(value) .. ", "
        end
        
        return str .. "}"
        
    elseif type(var) == "string" then
        
        var = string.gsub(var, "\n", "|")
        return '"' .. var .. '"'
        
    end
    
    return tostring(var)
    
end

this.tableToString = function(str)
    return tableToString(str)
end

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

this.deepCopy = function(input)
    return deepCopy(input)
end

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

this.deepMerge = function(target, source)
    deepMerge(target, source)
end

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

this.deepMergeWhenNil = function(target, source)
    deepMergeWhenNil(target, source)
end

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

this.deepRemoveMissingKeys = function(target, source)
    deepRemoveMissingKeys(target, source)
end

--------------------------------------------------
-- TABLE HELPERS | NON-RECURSIVE
--------------------------------------------------

this.count = function(tableToCount)
    
    local count = 0
    
    for key, _ in pairs(tableToCount) do
        count = count + 1
    end
    
    return count
    
end

this.getFirstKeyIfOnlyOneElement = function(tableToSearch)
    
    local count = 0
    local onlyKey = nil
    
    for key, _ in pairs(tableToSearch) do
        count = count + 1
        if count > 1 then return nil end
        onlyKey = key
    end
    
    return onlyKey
    
end

this.getFirstValueIfOnlyOneElement = function(tableToSearch)
    
    local count = 0
    local onlyValue = nil
    
    for _, value in pairs(tableToSearch) do
        count = count + 1
        if count > 1 then return nil end
        onlyValue = value
    end
    
    return onlyValue
    
end

this.getHighestValue = function(tableToSearch)
    
    local highestValue = nil
    
    for _, value in pairs(tableToSearch) do
        if highestValue == nil or value > highestValue then
            highestValue = value
        end
    end
    
    return highestValue
    
end

this.getSetFromRange = function(minKey, maxKey)
    
    local output = {}
    
    for i = minKey, maxKey do
        output[i] = true
    end
    
    return output
    
end

--------------------------------------------------
-- SORT HELPERS
--------------------------------------------------

-- if sortFunction is nil, sorts by key asc
this.sortedPairs = function(sourceTable, sortFunction)
    
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

this.sortFunction_ByStringKey =  function(keyA, keyB)
    
    local keyLowerA = string.lower(keyA)
    local keyLowerB = string.lower(keyB)
    
    if keyLowerA ~= keyLowerB then return keyLowerA < keyLowerB end
    return keyA < keyB
    
end

this.getSortFunction_ByValueThenKey = function(tableToSort)
    
    return function(keyA, keyB)
        
        local valueA = tableToSort[keyA]
        local valueB = tableToSort[keyB]
        
        if valueA ~= valueB then return valueA < valueB end
        return keyA < keyB
        
    end
    
end

this.getSortFunction_ByKeyLengthDescThenKeyThenValue = function(tableToSort)
    
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

--------------------------------------------------
-- NUMBER HELPERS
--------------------------------------------------

this.round = function(number, precision)
    return tonumber(string.format("%." .. precision .. "f", number))
end

local function clamp(number, minValue, maxValue)
    
    if minValue ~= nil and number < minValue then return minValue end
    if maxValue ~= nil and number > maxValue then return maxValue end
    
    return number
    
end

this.clamp = function(number, minValue, maxValue)
    return clamp(number, minValue, maxValue)
end

this.getNumber = function(var, defaultValue, minValue, maxValue)
    
    if type(var) ~= "number" then return defaultValue end
    return clamp(var, minValue, maxValue)
    
end

--------------------------------------------------
-- STRING HELPERS
--------------------------------------------------

this.capitalizeFirstLetter = function(str)
    return string.gsub(str, "^%l", string.upper)
end

this.getCaseInsensitivePattern = function(str)
    
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

--------------------------------------------------
-- BOOLEAN HELPERS
--------------------------------------------------

this.getYesNoString = function(bool)
    
    if bool then return "Yes" end
    return "No"
    
end

return this
