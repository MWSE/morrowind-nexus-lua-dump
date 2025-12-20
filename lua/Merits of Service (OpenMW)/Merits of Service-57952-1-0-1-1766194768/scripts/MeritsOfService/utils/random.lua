function RandomChoice(list)
    return list[math.random(#list)]
end

--- Pick a random key from a weight table
--- @param weights table<string, number>   -- e.g. { a = 30, b = 50, c = 20 }
--- @return string key                    -- chosen key
function WeightedRandom(weights)
    -- compute total weight
    local total = 0
    for _, w in pairs(weights) do
        total = total + w
    end

    if total == 0 then
        ---@diagnostic disable-next-line: return-type-mismatch
        return nil -- no valid weights at all
    end

    -- pick a random number in [0, total)
    local threshold = math.random() * total

    -- walk through keys until threshold is crossed
    local cumulative = 0
    for key, w in pairs(weights) do
        cumulative = cumulative + w
        if threshold <= cumulative then
            return key
        end
    end

    -- fallback (floating point edge cases)
    -- return any key
    for key in pairs(weights) do
        return key
    end
end
