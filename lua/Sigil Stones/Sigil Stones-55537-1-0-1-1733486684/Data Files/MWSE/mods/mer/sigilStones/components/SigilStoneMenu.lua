local common = require("mer.sigilStones.common")
local logger = common.createLogger("SigilStoneMenu")

---@class SigilStones.SigilStoneMenu.Config
---@field sigilStone SigilStones.SigilStone

---@class SigilStones.SigilStoneMenu : SigilStones.SigilStoneMenu.Config
local SigilStoneMenu = {}

---@param e SigilStones.SigilStoneMenu.Config
---@return SigilStones.SigilStoneMenu
function SigilStoneMenu:new(e)
    local self = table.copy(e)
    setmetatable(self, {__index = SigilStoneMenu})
    return self
end

---Get the filter function for the inventory select menu
---@return function
function SigilStoneMenu:getInventoryFilter()
    ---@param e tes3ui.showInventorySelectMenu.filterParams
    return function(e)
        return self.sigilStone:canEnchant(e.item)
    end
end

---Get the callback for the inventory select menu
---to use the sigil stone on the selected item
---@return function
function SigilStoneMenu:getUseStoneCallback()
    ---@param e tes3ui.showInventorySelectMenu.callbackParams
    return function(e)
        local item = e.item
        if not item then
            logger:debug("No item selected")
            return
        end
        logger:debug("Using sigil stone on %s", item.name)
        self.sigilStone:use{
            object = item,
            reference = tes3.player,
            itemData = e.itemData
        }
    end
end

function SigilStoneMenu:open()
    logger:debug("Opening sigil stone menu")
    tes3ui.showInventorySelectMenu{
        title = self.sigilStone.object.name,
        noResultsText = "You have no compatible items",
        filter = self:getInventoryFilter(),
        callback = self:getUseStoneCallback()
    }
end

return SigilStoneMenu