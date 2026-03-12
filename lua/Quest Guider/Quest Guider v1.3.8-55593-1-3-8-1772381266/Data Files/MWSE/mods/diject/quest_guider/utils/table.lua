local this = {}

function this.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[this.deepcopy(orig_key)] = this.deepcopy(orig_value)
        end
        setmetatable(copy, this.deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function this.copy(orig)
    local out = {}
    for i, val in pairs(orig) do
        if type(val) == "userdata" or type(val) == "table" then
            out[i] = this.copy(val)
        else
            out[i] = val
        end
    end
    return out
end

function this.addMissing(toTable, fromTable)
    for label, val in pairs(fromTable) do
        if type(val) == "table" then
            if toTable[label] == nil then
                toTable[label] = this.deepcopy(val)
            else
                if type(toTable[label]) ~= "table" then toTable[label] = {} end
                this.addMissing(toTable[label], val)
            end
        elseif toTable[label] == nil then
            toTable[label] = val
        elseif type(val) ~= type(toTable[label]) then
            toTable[label] = val
        end
    end
end

function this.applyChanges(toTable, fromTable)
    for label, val in pairs(fromTable) do
        if type(val) == "table" then
            if toTable[label] == nil then
                toTable[label] = this.deepcopy(val)
            else
                if type(toTable[label]) ~= "table" then toTable[label] = {} end
                this.applyChanges(toTable[label], val)
            end
        else
            toTable[label] = val
        end
    end
end

---@param to table
---@param from table|nil
function this.addTableValuesToTable(to, from)
    if not to then return end
    for _, val in pairs(from or {}) do
        table.insert(to, val)
    end
end

---@return boolean
function this.isContains(table, value)
    for _, val in pairs(table) do
        if val == value then return true end
    end
    return false
end

---@param table table
---@param path string
---@return any
function this.getValueByPath(table, path)
    local value = table
    if value ~= nil and #path > 0 then
        for valStr in (path.."."):gmatch("(.-)".."[.]") do
            value = value[valStr]
            if value == nil then
                return nil
            end
        end
    end
    return value
end

---@param table table
---@param path string
---@param newValue any
---@return boolean
function this.setValueByPath(table, path, newValue)
    local value = table
    if value == nil and #path == 0 then
        return false
    end
    local lastTable = value
    local lastName = nil
    for valStr in (path.."."):gmatch("(.-)".."[.]") do
        lastName = valStr
        lastTable = value
        value = value[valStr]
        if value == nil then
            value = {}
            lastTable[valStr] = value
        end
    end
    if lastName then
        lastTable[lastName] = newValue
    else
        lastTable = newValue
    end
    return true
end

---@param table table
---@return string
function this.valuesToStr(table)
    local str = ""

    for _, val in ipairs(table) do
        str = str..tostring(val)..", "
    end
    if #str > 0 then
        str = str:sub(1, -3)
    end

    return str
end

---@param table table
---@return string
function this.tableToStrLine(table)
    local str = ""

    for n, val in pairs(table) do
        str = str..tostring(n)..": "..tostring(val)..", "
    end
    if #str > 0 then
        str = str:sub(1, -3)
    end

    return str
end

function this.tableIndexesToArray(tb)
    local arr = {}
    for index, _ in pairs(tb or {}) do
        table.insert(arr, index)
    end
    return arr
end

return this