local Class = require("seph.class")

local tableExtensions = {}

--- Deep copies a table and all its nested tables. Shallowly copies assigned metatables and classes.
function tableExtensions.copy(source)
    assert(type(source) == "table", "source must be a table")
    local result = {}
	for key, value in pairs(source) do
        if type(value) == "table" and not Class.isClass(value) then
            if Class.isClass(value) then
                result[key] = value
                setmetatable(result[key], getmetatable(value))
            else
                result[key] = tableExtensions.copy(value)
            end
        else
	        result[key] = value
        end
	end
    setmetatable(result, getmetatable(source))
	return result
end

--- Copies the contents of one table into another table, creating or inserting into nested tables as needed. Does not copy metatables.
function tableExtensions.copyContents(source, target)
    for index, value in pairs(source) do
        if type(value) == "table" then
            target[index] = target[index] or {}
            tableExtensions.copyContents(value, target[index])
        else
            target[index] = value
        end
    end
end

function tableExtensions.setValueByPath(target, value, path, separator)
    local fields = string.split(path, separator or ".")
    for index, field in pairs(fields) do
        if index == #fields then
            target[field] = value
        else
            target[field] = target[field] or {}
            target = target[field]
        end
    end
end

function tableExtensions.getValueByPath(target, path, separator)
    local fields = string.split(path, separator or ".")
    for index, field in pairs(fields) do
        if index == #fields then
            return target[field]
        else
            if target[field] == nil then
                return nil
            else
                target = target[field]
            end
        end
    end
    return nil
end

return tableExtensions