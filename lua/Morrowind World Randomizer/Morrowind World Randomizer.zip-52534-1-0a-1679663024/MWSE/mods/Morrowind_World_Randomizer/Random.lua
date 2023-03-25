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

return random