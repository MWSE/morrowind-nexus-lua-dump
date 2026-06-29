-- json.lua
-- Minimal JSON decoder for companion dialogue files (decode-only, no dependencies).

local json = {}

local function skipWhitespace(str, pos)
    while pos <= #str do
        local c = str:sub(pos, pos)
        if c == " " or c == "\t" or c == "\n" or c == "\r" then
            pos = pos + 1
        else
            break
        end
    end
    return pos
end

local decodeValue

local function decodeString(str, pos)
    pos = pos + 1
    local parts = {}
    while pos <= #str do
        local c = str:sub(pos, pos)
        if c == '"' then
            return table.concat(parts), pos + 1
        elseif c == "\\" then
            pos = pos + 1
            local esc = str:sub(pos, pos)
            if esc == '"' or esc == "\\" or esc == "/" then
                parts[#parts + 1] = esc
            elseif esc == "b" then
                parts[#parts + 1] = "\b"
            elseif esc == "f" then
                parts[#parts + 1] = "\f"
            elseif esc == "n" then
                parts[#parts + 1] = "\n"
            elseif esc == "r" then
                parts[#parts + 1] = "\r"
            elseif esc == "t" then
                parts[#parts + 1] = "\t"
            elseif esc == "u" then
                local hex = str:sub(pos + 1, pos + 4)
                parts[#parts + 1] = string.char(tonumber(hex, 16))
                pos = pos + 4
            else
                parts[#parts + 1] = esc
            end
            pos = pos + 1
        else
            parts[#parts + 1] = c
            pos = pos + 1
        end
    end
    error("Unterminated JSON string at position " .. tostring(pos))
end

local function decodeNumber(str, pos)
    local numStr = str:match("^%-?%d+%.?%d*[eE]?[%+%-]?%d*", pos)
    if not numStr then
        error("Invalid JSON number at position " .. tostring(pos))
    end
    return tonumber(numStr), pos + #numStr
end

local function decodeLiteral(str, pos, literal, value)
    if str:sub(pos, pos + #literal - 1) == literal then
        return value, pos + #literal
    end
    error("Invalid JSON literal at position " .. tostring(pos))
end

local function decodeArray(str, pos)
    pos = pos + 1
    local arr = {}
    pos = skipWhitespace(str, pos)
    if str:sub(pos, pos) == "]" then
        return arr, pos + 1
    end
    while true do
        local val
        val, pos = decodeValue(str, pos)
        arr[#arr + 1] = val
        pos = skipWhitespace(str, pos)
        local c = str:sub(pos, pos)
        if c == "]" then
            return arr, pos + 1
        elseif c == "," then
            pos = skipWhitespace(str, pos + 1)
        else
            error("Expected ',' or ']' in JSON array at position " .. tostring(pos))
        end
    end
end

local function decodeObject(str, pos)
    pos = pos + 1
    local obj = {}
    pos = skipWhitespace(str, pos)
    if str:sub(pos, pos) == "}" then
        return obj, pos + 1
    end
    while true do
        pos = skipWhitespace(str, pos)
        if str:sub(pos, pos) ~= '"' then
            error("Expected string key in JSON object at position " .. tostring(pos))
        end
        local key
        key, pos = decodeString(str, pos)
        pos = skipWhitespace(str, pos)
        if str:sub(pos, pos) ~= ":" then
            error("Expected ':' in JSON object at position " .. tostring(pos))
        end
        pos = skipWhitespace(str, pos + 1)
        local val
        val, pos = decodeValue(str, pos)
        obj[key] = val
        pos = skipWhitespace(str, pos)
        local c = str:sub(pos, pos)
        if c == "}" then
            return obj, pos + 1
        elseif c == "," then
            pos = skipWhitespace(str, pos + 1)
        else
            error("Expected ',' or '}' in JSON object at position " .. tostring(pos))
        end
    end
end

decodeValue = function(str, pos)
    pos = skipWhitespace(str, pos)
    local c = str:sub(pos, pos)
    if c == '"' then
        return decodeString(str, pos)
    elseif c == "{" then
        return decodeObject(str, pos)
    elseif c == "[" then
        return decodeArray(str, pos)
    elseif c == "t" then
        return decodeLiteral(str, pos, "true", true)
    elseif c == "f" then
        return decodeLiteral(str, pos, "false", false)
    elseif c == "n" then
        return decodeLiteral(str, pos, "null", nil)
    elseif c == "-" or c:match("%d") then
        return decodeNumber(str, pos)
    end
    error("Unexpected character in JSON at position " .. tostring(pos) .. ": " .. c)
end

function json.decode(str)
    if type(str) ~= "string" then
        error("json.decode expects a string")
    end
    local value, pos = decodeValue(str, 1)
    pos = skipWhitespace(str, pos)
    if pos <= #str then
        error("Trailing characters in JSON at position " .. tostring(pos))
    end
    return value
end

return json
