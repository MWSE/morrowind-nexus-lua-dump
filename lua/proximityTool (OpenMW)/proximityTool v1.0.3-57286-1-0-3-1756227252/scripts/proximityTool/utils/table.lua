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


---@param from table
---@return table
function this.deepcopy(from, to)
	local copy = nil
	if type(from) == "table" then
		copy = to or {}
		for k, v in next, from, nil do
			copy[this.deepcopy(k)] = this.deepcopy(v)
		end
		setmetatable(copy, this.deepcopy(getmetatable(from)))
	else
		copy = from
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


---@param from any[]
---@param to any[]
---@return any[]
function this.add(from, to)
	if not to then to = {} end

	for n, v in pairs(from) do
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



return this