--TODO
local common = require ("mer.ashfall.common.common")
return {
    dropText = function(campfire, item, itemData)
        if itemData and itemData.data.teaProgress and itemData.data.teaProgress > 0 then
            return true, "Нагреть чай"
        else
            return true, "Нагреть воду"
        end
    end,
    canDrop = function(ref, item, itemData)
        if common.helper.isModifierKeyPressed() then return false end
        local isUtensil = common.staticConfigs.utensils[item.id:lower()]
        if not isUtensil then
            return false
        end

        local isLit = ref.data.isLit
        if not isLit then
            return false
        end

        local hasWater = itemData
            and itemData.data.waterAmount
            and itemData.data.waterAmount > 0
        if not hasWater then
            return false
        end

        return true
    end,
}