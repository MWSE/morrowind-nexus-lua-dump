local common = require("mer.midnightOil.common")

local defaultOilAmount = 500

local function equipOil(e1)
    if not common.modActive() then return end
    if common.isOil(e1.item) then
        local itemData = e1.itemData
        tes3ui.leaveMenuMode()
        timer.delayOneFrame(function()
            if not itemData then
                itemData = tes3.addItemData{
                    to = tes3.player,
                    item = e1.item,
                }
                itemData.data.oilRemaining = defaultOilAmount
            end

            local flaskOilRemaining = itemData.data.oilRemaining
            tes3ui.showInventorySelectMenu{
                title = "Refill Oil Lamp",
                noResultsText = "You have no oil lamps to refill.",
                filter = function(e2)
                    return (
                        common.isOilLantern(e2.item) == true and
                        ( not e2.itemData or e2.itemData.timeLeft < e2.item.time  )    
                    )
                end,
                callback = function(e3)
                    if not e3.item then return end
                    local amountToRefill = e3.item.time - e3.itemData.timeLeft
                    local amountAvailable = flaskOilRemaining
                    local finalAmount = math.min(amountToRefill, amountAvailable)

                    itemData.data.oilRemaining = flaskOilRemaining - finalAmount
                    e3.itemData.timeLeft = e3.itemData.timeLeft + finalAmount

                    tes3.playSound{ reference = tes3.player, sound = "potion success"}
                    tes3.messageBox("You replenish your lantern oil.")
                end
            }
        end)
        return false
    end
end
event.register("equip", equipOil, { filter = tes3.player, priority = -1000 } )


local function onTooltip(e)
    if not common.modActive() then return end
    if e.object ~= nil then 
        if common.isOil(e.object) then
            local amount = e.itemData and e.itemData.data.oilRemaining or defaultOilAmount
            local block = e.tooltip:createBlock()
            block.flowDirection = "left_to_right"
            block.autoHeight = true
            block.autoWidth = true
            block.borderAllSides = 10
            local label = block:createLabel{ text = "Oil remaining: " }
            label.borderRight = 10
            local oilFillbar = block:createFillBar{
                current = amount,
                max = defaultOilAmount
            }
            oilFillbar.width = 200
            
        end
    end
end
event.register("uiObjectTooltip", onTooltip, { priority = 100000 })


local function onActivateAshMire(e)
    if not common.modActive() then return end
    if e.target and common.isOilSource(e.target.object) then
        tes3ui.showInventorySelectMenu{
            title = "Refill Oil Flask",
            noResultsText = "You have no oil flasks to refill.",
            filter = function(e2)
                return ( 
                    common.isOil(e2.item) == true and
                    ( 
                        not e2.itemData or 
                        not e2.itemData.data.oilRemaining or 
                        e2.itemData.data.oilRemaining < defaultOilAmount  
                    )  
                )
            end,
            callback = function(e3)
                if not e3.item then return end
                e3.itemData.data.oilRemaining = defaultOilAmount
                tes3.playSound{ reference = tes3.player, sound = "potion success"}
                tes3.messageBox("You refill your oil flask.")
            end
        }
    end
end

event.register("activate", onActivateAshMire)

local function calcOilPrice(e)
    if not common.modActive() then return end
    if common.isOil(e.item) then
        local oilAmount = e.itemData and e.itemData.data.oilRemaining or defaultOilAmount
        local percentage = oilAmount / defaultOilAmount
        e.price = math.max(1, e.price * percentage)
    end
end

event.register("calcBarterPrice", calcOilPrice)