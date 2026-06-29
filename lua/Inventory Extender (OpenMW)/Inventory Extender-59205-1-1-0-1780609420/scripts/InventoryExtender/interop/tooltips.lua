local vfs = require('openmw' .. '.vfs')

local tooltipsData = {}

local function putTooltip(id, text)
    if type(id) ~= 'string' or type(text) ~= 'string' then
        return
    end

    tooltipsData[id] = text
    tooltipsData[id:lower()] = text
end

local function mergeTooltipTable(data)
    if type(data) ~= 'table' then
        return
    end

    for _, tableData in pairs(data) do
        if type(tableData) == 'table' then
            for itemId, tooltipText in pairs(tableData) do
                putTooltip(itemId, tooltipText)
            end
        end
    end
end

-- Tooltips Complete built-in data table.
do
    local success, data = pcall(require, 'mwse.mods.Tooltips Complete.data')
    if success and type(data) == 'table' then
        mergeTooltipTable(data)
    end
end

local function decodeLuaString(value)
    if type(value) ~= 'string' then
        return value
    end

    return (value:gsub('\\([\\"\'nrt])', function(token)
        if token == 'n' then return '\n' end
        if token == 'r' then return '\r' end
        if token == 't' then return '\t' end
        return token
    end))
end

local function skipWhitespace(source, index)
    local len = #source
    while index <= len do
        local ch = source:sub(index, index)
        if ch ~= ' ' and ch ~= '\t' and ch ~= '\n' and ch ~= '\r' then
            break
        end
        index = index + 1
    end
    return index
end

local function parseQuotedString(source, index)
    index = skipWhitespace(source, index)

    local quote = source:sub(index, index)
    if quote ~= '"' and quote ~= '\'' then
        return nil, index
    end

    local i = index + 1
    local out = {}

    while i <= #source do
        local ch = source:sub(i, i)

        if ch == '\\' then
            local nextCh = source:sub(i + 1, i + 1)
            if nextCh == '' then
                break
            end
            out[#out + 1] = '\\' .. nextCh
            i = i + 2
        elseif ch == quote then
            return decodeLuaString(table.concat(out)), i + 1
        else
            out[#out + 1] = ch
            i = i + 1
        end
    end

    return nil, index
end

local function captureAddTooltipCalls(source)
    local cursor = 1

    while true do
        local _, endPos = source:find('addTooltip', cursor, true)
        if not endPos then
            break
        end

        local index = skipWhitespace(source, endPos + 1)
        if source:sub(index, index) == '(' then
            index = skipWhitespace(source, index + 1)
            local id, nextPos = parseQuotedString(source, index)
            if id then
                nextPos = skipWhitespace(source, nextPos)
                if source:sub(nextPos, nextPos) == ',' then
                    nextPos = skipWhitespace(source, nextPos + 1)
                    local description = parseQuotedString(source, nextPos)
                    if description then
                        putTooltip(id, description)
                    end
                end
            end
        end

        cursor = endPos + 1
    end
end

local function captureTooltipTableEntries(source)
    local cursor = 1

    while true do
        local _, idEq = source:find('id%s*=', cursor)
        if not idEq then
            break
        end

        local id, nextPos = parseQuotedString(source, idEq + 1)
        if id then
            local blockEnd = source:find('}', nextPos, true) or (#source + 1)
            local descStart, descEq = source:find('description%s*=', nextPos)
            if descEq and descStart < blockEnd then
                local description = parseQuotedString(source, descEq + 1)
                if description then
                    putTooltip(id, description)
                end
            end
        end

        cursor = idEq + 1
    end
end

local function readVfsFile(path)
    local handle = vfs.open(path)
    if not handle then
        return nil
    end

    local content = handle:read('*a')
    handle:close()
    return content
end

local function collectFromMwseScripts()
    for path in vfs.pathsWithPrefix('mwse') do
        local lowerPath = path:lower()
        if lowerPath:sub(-4) == '.lua' then
            local source = readVfsFile(path)
            if source and source:find('Tooltips Complete.interop', 1, true) then
                captureAddTooltipCalls(source)
                captureTooltipTableEntries(source)
            end
        end
    end
end

collectFromMwseScripts()

return tooltipsData