local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("douse")
local LiquidContainer = require("mer.ashfall.liquid.LiquidContainer")
return {
    dropText = function(campfire, item, itemData)
        return "Потушить"
    end,
    canDrop = function(campfire, item, itemData)
        if not common.helper.isModifierKeyPressed() then
            return false
        end
        local liquidContainer = LiquidContainer.createFromInventory(item, itemData)

        if not liquidContainer then
            return false
        end

        if not liquidContainer:hasWater() then
            return false
        end

        local fireLit = campfire.data.isLit
        if not fireLit then
            return false, "Костер не зажжен."
        end

        if not (liquidContainer:isWater() or liquidContainer:isTea() ) then
            return false, "Недопустимый тип жидкости."
        end

        return true
    end,
    onDrop = function(campfire, reference)
        if not common.helper.isModifierKeyPressed() then return end
        local liquidContainer = LiquidContainer.createFromReference(reference)
        if liquidContainer then
            event.trigger("Ashfall:fuelConsumer_Extinguish", {fuelConsumer = campfire, playSound = true})
            liquidContainer:reduce(10)
            tes3.playSound{ reference = tes3.player, sound = "ashfall_water" }
            common.helper.pickUp(reference)
        else
            logger:error("Not a liquid container somehow")
        end
    end
}