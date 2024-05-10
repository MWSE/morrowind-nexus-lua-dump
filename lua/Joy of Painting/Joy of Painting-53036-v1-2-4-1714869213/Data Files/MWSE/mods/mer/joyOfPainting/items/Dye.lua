local ashfall = include("mer.ashfall.interop")

---@class JOP.Dye
local Dye = {}

Dye.customRequirements = {
    {
        getLabel = function() return "Water: 10 units" end,
        check = function()
            if not ashfall then
                return false
            end
            ---@param stack tes3itemStack
            for _, stack in pairs(tes3.player.object.inventory) do
                if stack.variables then
                    for _, itemData in ipairs(stack.variables) do
                        local liquidContainer = ashfall.LiquidContainer.createFromInventory(stack.object, itemData)
                        local hasEnoughWater = liquidContainer ~= nil
                            and liquidContainer:hasWater()
                            and liquidContainer:isWater()
                            and liquidContainer.waterAmount >= 10
                        if hasEnoughWater then
                            return true
                        end
                    end
                end
            end
            return false
        end
    },
    {
        getLabel = function() return "Mortar and Pestle" end,
        check = function()
            ---@param stack tes3itemStack
            for _, stack in pairs(tes3.player.object.inventory) do
                local isMortarAndPestle = stack.object.objectType == tes3.objectType.apparatus
                    and stack.object.type == tes3.apparatusType.mortarAndPestle
                if isMortarAndPestle then
                    return true
                end
            end
            return false
        end
    }
}

Dye.craftCallback = function(_craftable)
    if not ashfall then
        return
    end
    ---@param stack tes3itemStack
    for _, stack in pairs(tes3.player.object.inventory) do
        if stack.variables then
            for _, itemData in ipairs(stack.variables) do
                local liquidContainer = ashfall.LiquidContainer.createFromInventory(stack.object, itemData)
                local hasEnoughWater = liquidContainer ~= nil
                    and liquidContainer:hasWater()
                    and liquidContainer:isWater()
                    and liquidContainer.waterAmount >= 10
                if liquidContainer ~= nil and hasEnoughWater then
                    liquidContainer:reduce(10)
                    return
                end
            end
        end
    end
end

return Dye