local core = require('openmw.core')

local l10n = core.l10n('Bardcraft')

-- Helper function to check if a node's criteria match the context
local function checkCriteria(criteria, context)
    if not criteria then return true end
    for key, value in pairs(criteria) do
        local contextValue = nil
        local checkType = "exact"
        if key == "randomChance" then
            checkType = "max"
            contextValue = math.random()
        elseif key:match("Min$") then
            checkType = "min"
            local baseKey = key:sub(1, -4)
            contextValue = context[baseKey]
        elseif key:match("Max$") then
            checkType = "max"
            local baseKey = key:sub(1, -4)
            contextValue = context[baseKey]
        else
            contextValue = context[key]
        end
        if contextValue == nil then 
            return false 
        end
        if checkType == "min" then
            if not (contextValue >= value) then return false end
        elseif checkType == "max" then
            if not (contextValue < value) then return false end
        elseif checkType == "exact" then
            if contextValue ~= value then return false end
        end
    end
    return true
end

-- Recursively build a flat weighted pool from nested pools
local function buildWeightedPool(pool, context)
    local result = {}
    local totalWeight = 0

    for _, entry in ipairs(pool or {}) do
        if entry.pool then
            -- Nested pool: recursively process
            local nestedItems, sumOfNestedWeights = buildWeightedPool(entry.pool, context)
            
            -- If the nested pool has valid items
            if #nestedItems > 0 and sumOfNestedWeights > 0 then
                local nestedPoolWeight = entry.weight or 1
                -- Distribute the nested pool's weight among its valid children
                for _, nestedItem in ipairs(nestedItems) do
                    -- nestedItem.weight is its weight relative to sumOfNestedWeights
                    -- The effective weight in the parent pool is:
                    -- (nestedPoolWeight) * (nestedItem.weight / sumOfNestedWeights)
                    local effectiveWeight = nestedPoolWeight * (nestedItem.weight / sumOfNestedWeights)
                    
                    table.insert(result, {
                        prefix = nestedItem.prefix,
                        weight = effectiveWeight
                    })
                    totalWeight = totalWeight + effectiveWeight
                end
            end
        else
            -- Leaf entry: check criteria and localization
            if checkCriteria(entry.criteria, context) then
                local prefix = entry.prefix and entry.prefix
                    :gsub('%%NPCRace', context.race or "")
                    :gsub('%%PerfImpr', context.impressiveness or "")
                    :gsub('%%PerfQual', context.quality or "")
                    :gsub('%%CellRegion', context.region or "")
                    :gsub('%%CellDistrict', context.district or "")
                    :gsub('%%CellTerritory', context.territory or "")
                    :gsub('%%CellProvince', context.province or "")
                    :gsub('%%Weather', context.weather or "")
                    or nil

                if prefix and l10n(prefix .. '_1') ~= (prefix .. '_1') then
                    local weight = entry.weight or 1
                    table.insert(result, {prefix = prefix, weight = weight})
                    totalWeight = totalWeight + weight
                end
            end
        end
    end

    return result, totalWeight
end

local function findMatchingNode(dataTree, context)
    -- Flatten all top-level pools into a single pool
    local pool, totalWeight = buildWeightedPool(dataTree, context)

    -- Weighted random selection
    if #pool > 0 then
        local pick = math.random() * totalWeight
        local accum = 0
        for _, entry in ipairs(pool) do
            accum = accum + entry.weight
            if pick <= accum then
                return entry.prefix
            end
        end
        -- Fallback (shouldn't happen if totalWeight > 0 and pool is not empty)
        if #pool > 0 then
             return pool[#pool].prefix
        end
    end

    return nil
end

return {
    findMatchingNode = findMatchingNode,
}

