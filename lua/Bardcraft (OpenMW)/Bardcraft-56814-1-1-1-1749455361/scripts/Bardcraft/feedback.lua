--[[
  Parses a predefined data structure (loaded from YAML) to find matching
  dialogue choices and game effects based on performance context.

  Args:
    dataTree (table): The Lua table representing the loaded YAML structure
                      (e.g., the content under the 'publican:' key).
    context (table): A table containing the current context values, e.g.,
                     { perfDensity = 5.0, perfQuality = 75, race = "dark elf" }

  Returns:
    table: A table containing { prefix = {localization prefix string}, effects = {key-value pairs} }
           if a match is found, otherwise nil.
]]
local function findMatchingNode(dataTree, context)
    -- Helper function to check if a node's criteria match the context
    local function checkCriteria(criteria, context)
        if not criteria then return true end -- No criteria means it's a potential match or default
        for key, value in pairs(criteria) do
            local contextValue = nil
            local checkType = "exact" -- Default check type

            -- Determine check type (Min/Max/Exact)
            if key == "randomChance" then
                checkType = "max"
                contextValue = math.random()
            elseif key:match("Min$") then
                checkType = "min"
                local baseKey = key:sub(1, -4) -- Remove "Min" suffix
                contextValue = context[baseKey]
            elseif key:match("Max$") then
                checkType = "max"
                local baseKey = key:sub(1, -4) -- Remove "Max" suffix
                contextValue = context[baseKey]
            else
                -- Exact match key
                contextValue = context[key]
            end

            -- Perform the check
            if contextValue == nil then 
                return false 
            end -- Context value missing, cannot satisfy criteria

            if checkType == "min" then
                if not (contextValue >= value) then return false end
            elseif checkType == "max" then
                if not (contextValue < value) then return false end
            elseif checkType == "exact" then
                if contextValue ~= value then return false end
            end
        end
        -- If all criteria passed
        return true
    end

    -- Recursive function to traverse the tree
    local function traverse(nodes, context)
        if not nodes then return nil end

        for _, node in ipairs(nodes) do
            if checkCriteria(node.criteria, context) then
                local result = nil
                if node.subcriteria then
                    -- Recurse into subcriteria
                    result = traverse(node.subcriteria, context)
                end

                -- If there's no result from subcriteria or if this node has its own prefix/effects
                if result == nil and (node.prefix or node.effects) then
                    result = {
                        prefix = node.prefix,
                        effects = node.effects or {}
                    }
                end

                -- If we have a result, merge parent node effects with child node effects
                if result then
                    -- Create a new effects table that combines parent and child effects
                    local mergedEffects = {}
                    
                    -- First add parent effects if they exist
                    if node.effects then
                        for k, v in pairs(node.effects) do
                            mergedEffects[k] = v
                        end
                    end
                    
                    -- Then merge child effects
                    if result.effects then
                        for k, v in pairs(result.effects) do
                            mergedEffects[k] = v
                        end
                    end
                    
                    -- Update the result with merged effects
                    result.effects = mergedEffects
                    return result
                end
            end
        end

        return nil
    end

    -- Start traversal from the root list
    return traverse(dataTree, context)
end

return {
    findMatchingNode = findMatchingNode,
}