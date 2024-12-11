local SigilStone = require("mer.sigilStones.components.SigilStone")
local SigilStoneMenu = require("mer.sigilStones.components.SigilStoneMenu")

---@param e equippedEventData
event.register("equip", function(e)
    local sigilStone = SigilStone.getFromItem{
        item = e.item,
        itemData = e.itemData
    }
    if sigilStone then
        local menu = SigilStoneMenu:new{
            sigilStone = sigilStone
        }

        menu:open()
    end
end)

---@param e uiObjectTooltipEventData
event.register("uiObjectTooltip", function(e)
    local sigilStone = SigilStone.getFromItem{
        item = e.object,
        itemData = e.itemData
    }
    if not sigilStone then return end
    local description = sigilStone:getDescription()
    if not description then return end
    e.tooltip:createLabel{
        text = description
    }
end)