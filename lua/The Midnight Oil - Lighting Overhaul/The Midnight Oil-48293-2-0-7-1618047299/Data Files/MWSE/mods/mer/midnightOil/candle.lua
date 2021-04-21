local common = require("mer.midnightOil.common")

local function equipCandle(e1)
    if not common.modActive() then return end
    if common.isCandle(e1.item) then
        tes3ui.leaveMenuMode()
        timer.delayOneFrame(function()
            tes3ui.showInventorySelectMenu{
                title = "Replace Candle",
                noResultsText = "You have no candles to replace.",
                filter = function(e2)
                    return (
                        common.isCandleLantern(e2.item) == true and
                        not common.isOilLantern(e2.item) == true and
                        ( not e2.itemData or e2.itemData.timeLeft < e2.item.time  )    
                    )
                end,
                callback = function(e3)
                    if not e3.item then return end
                    e3.itemData.timeLeft = e3.item.time
                    tes3.messageBox("You replace the candle in your %s.", e3.item.name)
                    tes3.removeItem{
                        reference = tes3.player,
                        item = e1.item,
                        playSound = false
                    }
                end
            }
        end)
        return false
    end
end
event.register("equip", equipCandle, { filter = tes3.player, priority = -1000 } )