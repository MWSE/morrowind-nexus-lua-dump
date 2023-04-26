local random = {}

function random.GetRandom(pos, itemsCount, lower, upper)
    if pos > itemsCount then pos = itemsCount end
    local upperLimit = pos + math.floor(itemsCount * upper)
    if upperLimit > itemsCount then upperLimit = itemsCount elseif upperLimit < 1 then upperLimit = 1 end
    local lowerLimit = pos - math.floor(itemsCount * lower)
    if lowerLimit < 1 then lowerLimit = 1 elseif lowerLimit > itemsCount then lowerLimit = itemsCount end
    if lowerLimit > upperLimit then lowerLimit = upperLimit end
    if upperLimit - lowerLimit < 3 then
        local cnt = math.floor(itemsCount * 0.05)
        if cnt < 1 then cnt = 1 end
        upperLimit = upperLimit + cnt
        lowerLimit = lowerLimit - cnt
        if upperLimit > itemsCount then upperLimit = itemsCount end
        if lowerLimit < 1 then lowerLimit = 1 end
    end
    return math.random(lowerLimit, upperLimit)
end

function random.GetBetween(min, max)
    return min + math.random() * (max - min)
end

function random.GetBetweenForMulDiv(min, max)
    if min < 1 and min > 0 and max > 1 then
        if math.random() < 0.5 then
            return min + math.random() * (1 - min)
        else
            return 1 + math.random() * (max - 1)
        end
    else
        return min + math.random() * (max - min)
    end
end

function random.GetRandomFromGroup(group, exceptTable)
    local effectId
    local pos = math.random(1, #group)
    if exceptTable[group[pos]] then
        local newGr = {}
        for i, val in pairs(group) do
            if not exceptTable[val] then
                table.insert(newGr, val)
            end
        end
        if #newGr > 0 then
            return random.GetRandomFromGroup(newGr, {})
        else
            return nil
        end
    else
        effectId = group[pos]
    end
    return effectId
end

return random