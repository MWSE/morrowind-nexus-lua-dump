local ashfall = include("mer.ashfall.interop")
local CraftingFramework = include("CraftingFramework")

---@class JOP.Dye
local Dye = {}

Dye.customRequirements = {
    {
        getLabel = function() return "Вода: 10 порций" end,
        check = function()
            if not ashfall then
                return false
            end
            for _, result in pairs(CraftingFramework.CarryableContainer.getInventory()) do
                local stack = result.stack
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
        getLabel = function() return "Ступка и пестик" end,
        check = function()
            for _, result in pairs(CraftingFramework.CarryableContainer.getInventory()) do
                local stack = result.stack
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
    for _, result in pairs(CraftingFramework.CarryableContainer.getInventory()) do
        local stack = result.stack
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