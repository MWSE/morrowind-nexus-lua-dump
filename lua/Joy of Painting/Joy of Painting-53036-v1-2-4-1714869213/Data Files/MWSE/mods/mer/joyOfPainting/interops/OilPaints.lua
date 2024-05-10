local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("OilPaintsInterop")

local OilPaints = require("mer.joyOfPainting.items.OilPaints")
local CraftingFramework = require("CraftingFramework")
CraftingFramework.Indicator.register{
    objectId = OilPaints.id,
    additionalUI = function(indicator, parent)
        local oilPaints = OilPaints:new{
            reference = indicator.reference,
            item  = indicator.item,
            itemData = indicator.dataHolder --[[@as tes3itemData]],
        }
        if oilPaints then
            oilPaints:doTooltip(parent)
        end
    end

}