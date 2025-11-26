--- Normalize a table of weights so that all values sum to 1.0
--- @param weights table<string, number>  Table of weights (e.g. { a = 30, b = 50 })
--- @return table<string, number> normalized  New table with normalized probabilities
function NormalizeWeights(weights)
    local total = 0
    for _, w in pairs(weights) do
        total = total + w
    end

    local normalized = {}
    if total == 0 then
        -- Avoid divide-by-zero; return zeroed table
        for key in pairs(weights) do
            normalized[key] = 0
        end
        return normalized
    end

    for key, w in pairs(weights) do
        normalized[key] = w / total
    end

    return normalized
end

function RandomChoice(list)
    return list[math.random(#list)]
end

function PickRandomWeightedKey(weights)
    local r = math.random()
    local cumulative = 0

    for group, weight in pairs(weights) do
        cumulative = cumulative + weight
        if r <= cumulative then
            return group
        end
    end
end
