local StringUtils = {}

--Finds the last index of a character sequence in a string.
---@param str string The string to search.
---@param chars string The separator that should be used for splitting.
---@return integer|nil index The index where the character sequence occurs or nil it the sequence was not found.
function StringUtils.findLastIndex(str, chars)
    local reversedString = string.reverse(str)
    local reversedIndex = string.find(reversedString, chars)

    if reversedIndex then
        return #str - reversedIndex + 1
    else
        return nil
    end
end

--Splits a string by a separator and retruns the splitted strings in a new table.
---@param string string The string to split.
---@param separator string The separator that should be used for splitting.
---@return table<string> splitted The nwe table with the splittet substrings.
function StringUtils.split(string, separator)
    local t = {}
    for str in string.gmatch(string, "([^" .. separator .. "]+)") do
        table.insert(t, str)
    end
    return t
end

return StringUtils