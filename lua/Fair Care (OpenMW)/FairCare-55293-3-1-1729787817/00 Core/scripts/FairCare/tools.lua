local module = {}

local function isObjectInvalid(obj)
    return tostring(obj) == "null object"
            or string.sub(tostring(obj), 1, 14) == "deleted object"
            or string.sub(tostring(obj), -12) == " (not found)"
end
module.isObjectInvalid = isObjectInvalid

local function areObjectEquals(obj1, obj2)
    return (obj1 and obj1.id or "") == (obj2 and obj2.id or "")
end
module.areObjectEquals = areObjectEquals

local function clamp(value, min, max)
    return math.min(max, math.max(min, value))
end
module.clamp = clamp

-- loop over sorted values
local spairs = function(t, order)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end

    if order then
        table.sort(keys, function(a, b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end
module.spairs = spairs

-- loop over multiple tables
local mpairs = function(t, ...)
    local i, a, k, v = 1, { ... }
    return
    function()
        repeat
            k, v = next(t, k)
            if k == nil then
                i, t = i + 1, a[i]
            end
        until k ~= nil or not t
        return k, v
    end
end
module.mpairs = mpairs

return module