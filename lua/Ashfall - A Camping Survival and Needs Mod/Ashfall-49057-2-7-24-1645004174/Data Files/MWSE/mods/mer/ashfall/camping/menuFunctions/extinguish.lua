local common = require ("mer.ashfall.common.common")
local LiquidContainer = require "mer.ashfall.objects.LiquidContainer"
local function filterWaterContainer(e)
    local liquidContainer = LiquidContainer.createFromInventory(e.item, e.itemData)
    if liquidContainer then
        local hasWater = liquidContainer and liquidContainer.waterAmount > 0
        local isStew = liquidContainer.waterType == "stew"
        return hasWater and not isStew
    end
    return false
end

return {
    text = "Extinguish",
    showRequirements = function(campfire)
        return campfire.data.isLit and not campfire.data.isStatic
    end,
    callback = function(campfire)
        timer.delayOneFrame(function()
            common.log:debug("Opening Inventory Select Menu")
            tes3ui.showInventorySelectMenu{
                title = "Select Firestarter",
                noResultsText = "You do not have any water to douse the fire.",
                filter = filterWaterContainer,
                callback = function(e)
                    if e.item then
                        local liquidContainer = LiquidContainer.createFromInventory(e.item, e.itemData)
                        if liquidContainer then
                            common.log:debug("showInventorySelectMenu Callback")
                            event.trigger("Ashfall:fuelConsumer_Extinguish", {fuelConsumer = campfire, playSound = true})
                            liquidContainer:transferLiquid(LiquidContainer.createInfiniteWaterSource(), 10)
                            tes3.playSound{ reference = tes3.player, sound = "Swim Left" }
                        end
                    end

                end,
            }
        end)
    end,


}