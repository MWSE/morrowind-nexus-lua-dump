return
{
    premade = {
        -- call `tostring` on each element of an array, for useful printing of arrays
        array_tostring = function (arr)
            local arr_strings = {}
            local offset = 0
            if arr[0] ~= nil then 
                arr_strings[1] = tostring(arr[0])
                offset = 1
            end
            for i, v in ipairs(arr) do
                arr_strings[i+offset] = tostring(v)
            end
            return string.format("{%s}", table.concat(arr_strings, ", "))
        end
    },
    generators = {
        --- converter: clamps the value between min and max
        clamp = function (min,max)
            local s, b = min, max
            return function(v)
                if v <= s then 
                    return s
                elseif b <= v then
                    return b
                else
                    return v
                end
            end
        end,
    
        --- `eq` will be evaluated by using `table.find(tbl, field)`
        ---@param t table the table to search
        ---@param default_str string? the string to display if the key isn't inside the table
        ---@return fun(field_val: any): any 
        table_find = function (t, default_str)
            local d = default_str or "N/A"
            return function(v) return v and table.find(t, v) or d end
        end,
        
        --- `eq` will be evaluated by using `field[index]`
        ---@param i any which `index` of `field` should we use when comparing this field?
        ---@return fun(field_val: any):any
        index = function (i)
            return function (v) return v[i] end
        end,
    }

}