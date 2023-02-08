local methods = {}
local randomSeed = math.random()

local priceData = require("ds22.priceConfig")

local function getPlayerRegion()
    -- Insert MWSE magic here to get a region id for the nearest exterior
end

methods.getPriceMultiplierForItem = function(item)
    local mult = 1.0
    local region = getPlayerRegion()

    if priceData.regions[region] then
       local priceMod = 0
       if priceData.regions[region].prices then
           priceMod = table.get(priceData.regions[region].prices, item, 0.25)
       end

       local neighborMod = 0
       local neighborCount = 0
       for _, neighbor in ipairs(priceData.regions[region].neighboringRegions) do
           if priceData.regions[neighbor] and priceData.regions[neighbor].prices then
                neighborCount = neighborCount + 1
                neighborMod = neighborMod + table.get(priceData.regions[region].prices, item, 0.25)
           end
       end
       neighborMod = ( neighborMod / neighborCount ) -- Take the average of all region modifiers

       mult = mult + ( priceMod + neighborMod ) -- Can be changed if we don't like the result this gives

       if priceData.regions[region].randomPriceMax and priceData.regions[region].randomPriceMin then
           math.randomseed(randomSeed) -- Use pseudorandomness to make sure that prices will stay the same between opening and closing the menu unless we want them to change
           mult = mult * math.random(priceData.regions[region].randomPriceMin, priceData.regions[region].randomPriceMax)
       end
    end

    return mult
end

methods.updateRandomSeed = function()
    -- This function should be run once every X in game days
    -- X could be configurable representing how long it takes for prices in the world to change
    
    randomSeed = math.random()
end

return methods