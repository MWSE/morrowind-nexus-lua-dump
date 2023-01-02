---@param v number
---@param kvp table<string, number>
---@return string | nil
return function(v, kvp)
    ---@param key string
    ---@param value number
    for key, value in pairs(kvp) do
        if (v == value) then
            return key
        end
    end
    return nil
end
