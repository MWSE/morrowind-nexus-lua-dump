local table = {}

function table.setValueByPath(target, value, path, separator)
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

function table.getValueByPath(target, path, separator)
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

return table