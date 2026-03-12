local this = {}

function this.count(table)
    local count = 0
    for _, _ in pairs(table) do
        count = count + 1
    end
    return count
end


--- @param t table
--- @param sort boolean|(fun(a: any, b: any):boolean)|nil
--- @return table values
function this.values(t, sort)
    local ret = {}
    for _, v in pairs(t) do
        table.insert(ret, v)
    end

    if sort then
        if sort == true then
            sort = nil
        end
        table.sort(ret, sort)
    end

    return ret
end


---@param t table
---@return table
function this.deepcopy(t)
	local copy = nil
	if type(t) == "table" then
		copy = {}
		for k, v in next, t, nil do
			copy[this.deepcopy(k)] = this.deepcopy(v)
		end
		setmetatable(copy, this.deepcopy(getmetatable(t)))
	else
		copy = t
	end
	return copy
end


---@param t table
function this.clear(t)
    for id, _ in pairs(t) do
        t[id] = nil
    end
end


---@param from table
---@param to table?
---@return table
function this.copy(from, to)
	if not to then to = {} end

	for n, v in pairs(from) do
		to[n] = v
	end

	return to
end


---@param from table
---@param to table?
---@return table
function this.addValues(from, to)
    if not to then to = {} end

	for _, v in pairs(from or {}) do
		table.insert(to, v)
	end

	return to
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


---@param t table
---@return table
function this.invertIndexes(t)
	local out = {}
	for i = #t, 1, -1 do
        table.insert(out, t[i])
	end
	return out
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


---@param tb table
---@return integer
function this.size(tb)
    if not tb then return 0 end
    local count = 0
    for _, _ in pairs(tb) do
        count = count + 1
    end

    return count
end


---@param tb table
---@return table
function this.keys(tb)
    local out = {}
    for key, _ in pairs(tb) do
        table.insert(out, key)
    end

    return out
end


---from MWSE
function this.shuffle(t, n)
	n = n or #t
	for i = n, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
end


function this.contains(tb, val)
    for i, v in pairs(tb) do
        if v == val then return i end
    end
end


function this.getFirst(tb, num)
    if not num then num = 1 end
    local res = {}
    for _, v in ipairs(tb) do
        if num > 0 then
            table.insert(res, v)
            num = num - 1
        else
            break
        end
    end
    return res
end


return this