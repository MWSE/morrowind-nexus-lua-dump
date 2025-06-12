local TileDropper = require("CraftingFramework.components.TileDropper")
local CarryableContainer = require("CraftingFramework.carryableContainers.components.CarryableContainer")
TileDropper.register{
    name = "CarryableContainers",
    highlightColor = { 1, 1, 1 },
    isValidTarget = function(e)
        return CarryableContainer.getContainerConfig(e.item) ~= nil
    end,
    canDrop = function(e)
        --Check if passes the container filter
        local container = CarryableContainer:new{
            item = e.target.item,
            itemData = e.target.itemData,
        }
        if not container then return false end
        if container.containerConfig.allowUnfiltered then return true end
        local filter = container:getFilter()
        if not filter then return true end
        return filter:isValid(e.held.item, e.held.itemData)
    end,
    --transfer
    onDrop = function(e)
        local container = CarryableContainer:new{
            item = e.target.item,
            itemData = e.target.itemData,
        }
        if not container then return end

        local doTransfer = function()
            container:transferPlayerToContainerWithDetails{ items = {
                {
                    item = e.held.item,
                    itemData = e.held.itemData,
                    count = e.held.count,
                }
            }
        }
        end
        if not container:isCopy() then
            container:replaceInInventory()
            timer.frame.delayOneFrame(function()
                doTransfer()
            end)
        else
            doTransfer()
        end
    end
}

