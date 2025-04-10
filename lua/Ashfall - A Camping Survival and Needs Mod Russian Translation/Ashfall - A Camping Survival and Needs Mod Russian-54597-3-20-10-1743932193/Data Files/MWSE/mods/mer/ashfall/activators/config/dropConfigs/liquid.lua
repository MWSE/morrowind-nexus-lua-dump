local common = require ("mer.ashfall.common.common")
local LiquidContainer = require("mer.ashfall.liquid.LiquidContainer")
return {
    dropText = function(target, item, itemData)
        --Liquids
        local isModifierKeyPressed = common.helper.isModifierKeyPressed()
        if isModifierKeyPressed then --retrieving water from target
            local liquidContainer = LiquidContainer.createFromReference(target)
            return string.format("Получить %s", liquidContainer and liquidContainer:getLiquidName())
        else --adding water to target
            local liquidContainer = LiquidContainer.createFromInventory(item, itemData)
            return string.format("Добавить %s", liquidContainer and liquidContainer:getLiquidName())
        end
    end,
    --onDrop for Stew handled separately, this only does tea
    canDrop = function(target, item, itemData)
        local itemLiquidContainer = LiquidContainer.createFromInventory(item, itemData)
        local targetLiquidContainer = LiquidContainer.createFromReference(target)
        if not itemLiquidContainer then return false end
        if not targetLiquidContainer then return false end

        local isModifierKeyPressed = common.helper.isModifierKeyPressed()
        if isModifierKeyPressed then --retrieving water from target
            if targetLiquidContainer.waterAmount <= 0 then
                return false, "Нет воды для получения"
            end
            local canTransfer, errorMsg = targetLiquidContainer:canTransfer(itemLiquidContainer)
            if not canTransfer then
                return false, errorMsg
            end
        else --adding water to target
            if not (itemLiquidContainer.waterAmount > 0) then
                return false, "У вас отсутствует вода для добавления"
            end
            local canTransfer, errorMsg = itemLiquidContainer:canTransfer(targetLiquidContainer)
            if not canTransfer then
                return false, errorMsg
            end
        end
        return true
    end,
    onDrop = function(target, reference)
        local from = LiquidContainer.createFromReference(reference)
        local to = LiquidContainer.createFromReference(target)
        if from and to then
            local waterAdded
            local errorMsg
            if common.helper.isModifierKeyPressed() then --retrieving water from target
                waterAdded, errorMsg = to:transferLiquid(from)
            else --adding water to target
                waterAdded, errorMsg = from:transferLiquid(to)
            end
            if waterAdded <= 0 then
                tes3.messageBox(errorMsg or "Невозможно перелить жидкость.")
            end
            common.helper.pickUp(reference)
        end
    end
}

