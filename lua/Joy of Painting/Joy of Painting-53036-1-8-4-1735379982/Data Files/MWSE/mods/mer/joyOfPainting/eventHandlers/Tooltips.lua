local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("Tooltips")
local UIHelper = require("mer.joyOfPainting.services.UIHelper")
local Painting = require("mer.joyOfPainting.items.Painting")

local function doPaintingTooltips(e, painting)
    local labelText
    if painting.data.paintingName then
        local paintingName = painting.data.paintingName
        labelText = string.format('"%s"', paintingName)
    elseif painting.data.canvasId then
        labelText = tes3.getObject(painting.data.canvasId).name
    end
    if labelText then
        UIHelper.addLabelToTooltip{
            tooltip = e.tooltip,
            labelText = labelText,
            color = tes3ui.getPalette("normal_color")
        }
    end
end

---@param e uiObjectTooltipEventData
local function manageTooltips(e)
    local painting = Painting:new{
        reference = e.reference,
        item = e.object --[[@as JOP.tes3itemChildren]],
        itemData = e.itemData
    }
    if painting:hasPaintingData() then
        doPaintingTooltips(e, painting)
    end
end
event.register(tes3.event.uiObjectTooltip, manageTooltips)

---Adds the painting names to the inventory select menu
---@param e uiActivatedEventData
local function onMenuInventorySelectMenu(e)
    logger:debug("Entering InventorySelectMenu")
    local scrollpane = e.element:findChild("MenuInventorySelect_scrollpane")
    local itemList = scrollpane:findChild("PartScrollPane_pane")
    for _, block in pairs(itemList.children) do
        local itemData = block:getPropertyObject("MenuInventorySelect_extra", "tes3itemData")
        local data = itemData
            and itemData.data
            and itemData.data.joyOfPainting
        if data and data.paintingName then
            logger:debug("Found painting with name: %s", data.paintingName)
            local textElement = block:findChild("MenuInventorySelect_item_brick")
            textElement.text = string.format('%s - "%s"',textElement.text, data.paintingName)
        end
    end
end
event.register("uiActivated", onMenuInventorySelectMenu, { priority = -10, filter = "MenuInventorySelect"})
