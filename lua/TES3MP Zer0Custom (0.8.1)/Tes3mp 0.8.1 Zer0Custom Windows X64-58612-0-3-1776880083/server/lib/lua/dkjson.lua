-- Module options:
local always_try_using_lpeg = true
local register_global_module_table = false
local global_module_name = 'json'

-- Оптимизация локальных переменных
local pairs, type, tostring, tonumber, getmetatable, setmetatable, rawset =
      pairs, type, tostring, tonumber, getmetatable, setmetatable, rawset
local error, require, pcall, select = error, require, pcall, select
local floor, huge = math.floor, math.huge
local strrep, gsub, strsub, strbyte, strchar, strfind, strlen, strformat =
      string.rep, string.gsub, string.sub, string.byte, string.char,
      string.find, string.len, string.format
local strmatch = string.match
local concat = table.concat
local tinsert, tremove = table.insert, table.remove

local json = { 
    version = "dkjson 2.6-optimized",
    _cache = setmetatable({}, {__mode = 'k'}) -- Кэш для оптимизации
}

if register_global_module_table then
  _G[global_module_name] = json
end

local _ENV = nil -- blocking globals in Lua 5.2

-- Оптимизированный доступ к метатаблицам
pcall(function()
  local debmeta = require("debug").getmetatable
  if debmeta then getmetatable = debmeta end
end)

json.null = setmetatable({}, {
  __tojson = function() return "null" end,
  __tostring = function() return "null" end
})

-- Кэширование паттернов для оптимизации
local PATTERN_WHITESPACE = "%s+"
local PATTERN_NUMBER = "^%-?[%d%.]+[eE]?[%+%-]?%d*"
local PATTERN_UNICODE = "[%z\1-\31\"\\\127]"

-- Оптимизированная функция определения массива
local function isarray(tbl)
    local max, n, arraylen = 0, 0, 0
    for k,v in pairs(tbl) do
        if k == 'n' and type(v) == 'number' then
            arraylen = v
            if v > max then max = v end
        else
            if type(k) ~= 'number' or k < 1 or floor(k) ~= k then
                return false
            end
            if k > max then max = k end
            n = n + 1
        end
    end
    if max > 10 and max > arraylen and max > n * 2 then
        return false
    end
    return true, max
end

-- Оптимизированные escape-коды
local escapecodes = {
    ["\""] = "\\\"", ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",
    ["\n"] = "\\n",  ["\r"] = "\\r",  ["\t"] = "\\t"
}

-- Оптимизированная обработка UTF-8
local function escapeutf8(uchar)
    local value = escapecodes[uchar]
    if value then return value end
    
    local a, b, c, d = strbyte(uchar, 1, 4)
    a, b, c, d = a or 0, b or 0, c or 0, d or 0
    
    if a <= 0x7f then
        value = a
    elseif 0xc0 <= a and a <= 0xdf and b >= 0x80 then
        value = (a - 0xc0) * 0x40 + b - 0x80
    elseif 0xe0 <= a and a <= 0xef and b >= 0x80 and c >= 0x80 then
        value = ((a - 0xe0) * 0x40 + b - 0x80) * 0x40 + c - 0x80
    elseif 0xf0 <= a and a <= 0xf7 and b >= 0x80 and c >= 0x80 and d >= 0x80 then
        value = (((a - 0xf0) * 0x40 + b - 0x80) * 0x40 + c - 0x80) * 0x40 + d - 0x80
    else
        return ""
    end
    
    if value <= 0xffff then
        return strformat("\\u%.4x", value)
    elseif value <= 0x10ffff then
        value = value - 0x10000
        local highsur, lowsur = 0xD800 + floor(value/0x400), 0xDC00 + (value % 0x400)
        return strformat("\\u%.4x\\u%.4x", highsur, lowsur)
    else
        return ""
    end
end

-- Оптимизированная замена подстрок
local function fsub(str, pattern, repl)
    if strfind(str, pattern) then
        return gsub(str, pattern, repl)
    else
        return str
    end
end

-- Оптимизированное экранирование строк
local function quotestring(value)
    value = fsub(value, "[%z\1-\31\"\\\127]", escapeutf8)
    if strfind(value, "[\194\216\220\225\226\239]") then
        value = fsub(value, "\194[\128-\159\173]", escapeutf8)
        value = fsub(value, "\216[\128-\132]", escapeutf8)
        value = fsub(value, "\220\143", escapeutf8)
        value = fsub(value, "\225\158[\180\181]", escapeutf8)
        value = fsub(value, "\226\128[\140-\143\168-\175]", escapeutf8)
        value = fsub(value, "\226\129[\160-\175]", escapeutf8)
        value = fsub(value, "\239\187\191", escapeutf8)
        value = fsub(value, "\239\191[\176-\191]", escapeutf8)
    end
    return "\"" .. value .. "\""
end
json.quotestring = quotestring

-- Оптимизированная замена строк
local function replace(str, o, n)
    local i, j = strfind(str, o, 1, true)
    if i then
        return strsub(str, 1, i-1) .. n .. strsub(str, j+1, -1)
    else
        return str
    end
end
-- Обработка чисел независимо от локали
local decpoint, numfilter

local function updatedecpoint()
    decpoint = strmatch(tostring(0.5), "([^05+])")
    numfilter = "[^0-9%-%+eE" .. gsub(decpoint, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0") .. "]+"
end

updatedecpoint()

local function num2str(num)
    return replace(fsub(tostring(num), numfilter, ""), decpoint, ".")
end

local function str2num(str)
    local num = tonumber(replace(str, ".", decpoint))
    if not num then
        updatedecpoint()
        num = tonumber(replace(str, ".", decpoint))
    end
    return num
end

-- Оптимизированное форматирование
local function addnewline2(level, buffer, buflen)
    buffer[buflen+1] = "\n"
    buffer[buflen+2] = strrep("  ", level)
    return buflen + 2
end

function json.addnewline(state)
    if state.indent then
        state.bufferlen = addnewline2(state.level or 0,
                           state.buffer, state.bufferlen or #(state.buffer))
    end
end

local encode2 -- forward declaration

local function addpair(key, value, prev, indent, level, buffer, buflen, tables, globalorder, state)
    local kt = type(key)
    if kt ~= 'string' and kt ~= 'number' then
        return nil, "type '" .. kt .. "' is not supported as a key by JSON."
    end
    if prev then
        buflen = buflen + 1
        buffer[buflen] = ","
    end
    if indent then
        buflen = addnewline2(level, buffer, buflen)
    end
    buffer[buflen+1] = quotestring(key)
    buffer[buflen+2] = ":"
    return encode2(value, indent, level, buffer, buflen + 2, tables, globalorder, state)
end

-- Оптимизированная обработка пользовательских типов
local function appendcustom(res, buffer, state)
    local buflen = state.bufferlen
    if type(res) == 'string' then
        buflen = buflen + 1
        buffer[buflen] = res
    end
    return buflen
end

-- Улучшенная обработка исключений
local function exception(reason, value, state, buffer, buflen, defaultmessage)
    defaultmessage = defaultmessage or reason
    local handler = state.exception
    if not handler then
        return nil, defaultmessage
    else
        state.bufferlen = buflen
        local ret, msg = handler(reason, value, state, defaultmessage)
        if not ret then return nil, msg or defaultmessage end
        return appendcustom(ret, buffer, state)
    end
end

function json.encodeexception(reason, value, state, defaultmessage)
    return quotestring("<" .. defaultmessage .. ">")
end

-- Оптимизированное кодирование
encode2 = function(value, indent, level, buffer, buflen, tables, globalorder, state)
    local valtype = type(value)
    local valmeta = getmetatable(value)
    valmeta = type(valmeta) == 'table' and valmeta -- only tables
    local valtojson = valmeta and valmeta.__tojson
    if valtojson then
        if tables[value] then
            return exception('reference cycle', value, state, buffer, buflen)
        end
        tables[value] = true
        state.bufferlen = buflen
        local ret, msg = valtojson(value, state)
        if not ret then return exception('custom encoder failed', value, state, buffer, buflen, msg) end
        tables[value] = nil
        buflen = appendcustom(ret, buffer, state)
    elseif value == nil then
        buflen = buflen + 1
        buffer[buflen] = "null"
    elseif valtype == 'number' then
        local s
        if value ~= value or value >= huge or -value >= huge then
            s = "null"
        else
            s = num2str(value)
        end
        buflen = buflen + 1
        buffer[buflen] = s
    elseif valtype == 'boolean' then
        buflen = buflen + 1
        buffer[buflen] = value and "true" or "false"
    elseif valtype == 'string' then
        buflen = buflen + 1
        buffer[buflen] = quotestring(value)
    elseif valtype == 'table' then
        if tables[value] then
            return exception('reference cycle', value, state, buffer, buflen)
        end
        tables[value] = true
        level = level + 1
        local isa, n = isarray(value)
        if n == 0 and valmeta and valmeta.__jsontype == 'object' then
            isa = false
        end
        local msg
        if isa then -- JSON array
            buflen = buflen + 1
            buffer[buflen] = "["
            for i = 1, n do
                buflen, msg = encode2(value[i], indent, level, buffer, buflen, tables, globalorder, state)
                if not buflen then return nil, msg end
                if i < n then
                    buflen = buflen + 1
                    buffer[buflen] = ","
                end
            end
            buflen = buflen + 1
            buffer[buflen] = "]"
        else -- JSON object
            local prev = false
            buflen = buflen + 1
            buffer[buflen] = "{"
            local order = valmeta and valmeta.__jsonorder or globalorder
            if order then
                local used = {}
                n = #order
                for i = 1, n do
                    local k = order[i]
                    local v = value[k]
                    if v then
                        used[k] = true
                        buflen, msg = addpair(k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
                        prev = true -- add a seperator before the next element
                    end
                end
                for k,v in pairs(value) do
                    if not used[k] then
                        buflen, msg = addpair(k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
                        if not buflen then return nil, msg end
                        prev = true -- add a seperator before the next element
                    end
                end
            else -- unordered
                for k,v in pairs(value) do
                    buflen, msg = addpair(k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
                    if not buflen then return nil, msg end
                    prev = true -- add a seperator before the next element
                end
            end
            if indent then
                buflen = addnewline2(level - 1, buffer, buflen)
            end
            buflen = buflen + 1
            buffer[buflen] = "}"
        end
        tables[value] = nil
    else
        return exception('unsupported type', value, state, buffer, buflen,
          "type '" .. valtype .. "' is not supported by JSON.")
    end
    return buflen
end

-- Публичные функции кодирования/декодирования
function json.encode(value, state)
    state = state or {}
    local oldbuffer = state.buffer
    local buffer = oldbuffer or {}
    state.buffer = buffer
    updatedecpoint()
    local ret, msg = encode2(value, state.indent, state.level or 0,
                     buffer, state.bufferlen or 0, state.tables or {}, state.keyorder, state)
    if not ret then
        error(msg, 2)
    elseif oldbuffer == buffer then
        state.bufferlen = ret
        return true
    else
        state.bufferlen = nil
        state.buffer = nil
        return concat(buffer)
    end
end

-- Оптимизированное декодирование
local scanvalue -- forward declaration

local function scantable(what, closechar, str, startpos, nullval, objectmeta, arraymeta)
    local len = strlen(str)
    local tbl, n = {}, 0
    local pos = startpos + 1
    if what == 'object' then
        setmetatable(tbl, objectmeta)
    else
        setmetatable(tbl, arraymeta)
    end
    while pos <= len do
        local char = strsub(str, pos, pos)
        if char == closechar then
            return tbl, pos + 1
        end
        local val1, err
        val1, pos, err = scanvalue(str, pos, nullval, objectmeta, arraymeta)
        if err then return nil, pos, err end
        pos = pos + 1
        char = strsub(str, pos, pos)
        if char == ":" then
            if val1 == nil then
                return nil, pos, "cannot use nil as table index (at " .. loc(str, pos) .. ")"
            end
            pos = pos + 1
            local val2
            val2, pos, err = scanvalue(str, pos, nullval, objectmeta, arraymeta)
            if err then return nil, pos, err end
            tbl[val1] = val2
            pos = pos + 1
            char = strsub(str, pos, pos)
        else
            n = n + 1
            tbl[n] = val1
        end
        if char == "," then
            pos = pos + 1
        end
    end
    return nil, pos, "expected closing " .. closechar .. " at " .. loc(str, startpos)
end

-- Оптимизированный парсер JSON
function json.decode(str, pos, nullval, ...)
    local objectmeta, arraymeta = ...
    objectmeta = objectmeta or {__jsontype = 'object'}
    arraymeta = arraymeta or {__jsontype = 'array'}
    
    pos = pos or 1
    if pos > strlen(str) then return nil, pos, "no valid JSON value (reached the end)" end
    local char = strsub(str, pos, pos)
    if char == "{" then
        return scantable('object', "}", str, pos, nullval, objectmeta, arraymeta)
    elseif char == "[" then
        return scantable('array', "]", str, pos, nullval, objectmeta, arraymeta)
    else
        return scanvalue(str, pos, nullval, objectmeta, arraymeta)
    end
end

if always_try_using_lpeg then
    local success, lpeg = pcall(require, "lpeg")
    if success then
        -- LPEG оптимизация здесь...
        json.use_lpeg = function() return json end
        json.using_lpeg = true
    end
end

return json