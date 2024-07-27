--event handler for UI tooltips etc

local UI = require("mer.fishing.ui.Helper")
local FishType = require("mer.fishing.Fish.FishType")
local config = require("mer.fishing.config")
local FishingRod = require("mer.fishing.FishingRod.FishingRod")
local Bait = require("mer.fishing.Bait.Bait")

---@param e uiObjectTooltipEventData
event.register("uiObjectTooltip", function(e)
    local bait = Bait.get(e.object.id:lower())
    if bait then
        --Don't show tooltip on cooked bait
        local isCooked = e.itemData and Bait.isCooked(e.itemData.data)
        if not isCooked then
            UI.addLabelToTooltip(
                e.tooltip,
                bait:getTypeName(),
                config.constants.TOOLTIP_COLOR_BAIT
            )
            return
        end
    end

    local fishType = FishType.get(e.object.id)
    if fishType and fishType:canHarvest() then
        UI.addLabelToTooltip(
            e.tooltip,
            "Улов",
            config.constants.TOOLTIP_COLOR_BAIT
        )
        return
    end

    local fishingRod = FishingRod.new{
        item = e.object,
        itemData = e.itemData
    }
    if fishingRod then
        local equippedBait = fishingRod:getEquippedBait()
        if equippedBait then

            local labelText = string.format("%s - %s",
                equippedBait:getTypeName(),
                equippedBait:getName()
            )
            if equippedBait.uses then
                labelText = string.format("%s (%d ост.)", labelText, equippedBait.uses)
            end
            UI.addLabelToTooltip( e.tooltip,  labelText, config.constants.TOOLTIP_COLOR_BAIT )
        end
    end
end, { priority = -50 })