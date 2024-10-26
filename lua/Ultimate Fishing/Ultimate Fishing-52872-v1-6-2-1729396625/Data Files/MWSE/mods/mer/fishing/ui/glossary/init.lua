local common = require("mer.fishing.common")
local logger = common.createLogger("Glossary")
local config = require("mer.fishing.config")
local FishType = require("mer.fishing.Fish.FishType")
local PreviewPane = require("mer.fishing.ui.PreviewPane")

---@class Fishing.Glossary
local FishGlossary = {
    IDs = {
        MENU = "Fishing_Glossary_Menu",
    }
}

---@param parent tes3uiElement
---@param fishType Fishing.FishType
function FishGlossary.createFishEntry(parent, fishType)
    --TODO: Implement
    --[[
        Top row: Fish name, icon
        Middle row: left = habitat info, right = preview pane
        Bottom row: description
    ]]

    local fishObj = fishType:getBaseObject()


    local block = parent:createBlock{ id = "FishEntry" }
    block.flowDirection = "top_to_bottom"
    block.autoHeight = true
    block.widthProportional = 1.0

    local topRow = block:createBlock{ id = "FishEntry_TopRow" }
    topRow.flowDirection = "left_to_right"
    topRow.autoHeight = true
    topRow.widthProportional = 1.0



    local fishName = topRow:createLabel{ text = fishObj.name }
    fishName.autoHeight = true
    fishName.widthProportional = 1.0

    local icon = topRow:createImage{ path = fishObj.icon }
    icon.borderAllSides = 4

    local middleRow = block:createBlock{ id = "FishEntry_MiddleRow" }
    middleRow.flowDirection = "left_to_right"
    middleRow.autoHeight = true
    middleRow.widthProportional = 1.0

    local habitatBlock = middleRow:createBlock{ id = "FishEntry_HabitatBlock" }
    habitatBlock.flowDirection = "top_to_bottom"
    habitatBlock.autoHeight = true
    habitatBlock.widthProportional = 0.5
end

function FishGlossary.createGlossary()
    local menu = tes3ui.createMenu{ id = FishGlossary.IDs.MENU, fixedFrame = true }
    menu.minWidth = 800
    menu.minHeight = 600

    local outerBlock = menu:createBlock()
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.autoWidth = true
    outerBlock.autoHeight = true

    local title = outerBlock:createLabel{ text = "Fishing Glossary" }
end


