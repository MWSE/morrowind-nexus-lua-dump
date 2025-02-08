local PreviewPane = require("mer.fishing.ui.PreviewPane")

---Creates a ui that displays a caught fish along with a description and stats
---@class Fishing.TrophyMenu
local TrophyMenu = {
    PREVIEW_WIDTH = 700,
    PREVIEW_HEIGHT = 500,
}

local uiids = {
    menu = "Fishing:TrophyMenu",
    previewBorder = "Fishing:TrophyMenu:PreviewBorder",
    nifPreviewBlock = "Fishing:TrophyMenu:NifPreviewBlock",
    nif = "Fishing:TrophyMenu:Nif",
}

local function getMenu()
    return tes3ui.findMenu(uiids.menu)
end


---@param parent tes3uiElement
---@param headerText string
---@param description string
local function createDescription(parent, headerText, description)
    --create text block
    local textBlock = parent:createThinBorder{ id = uiids.textBlock }
    textBlock.widthProportional = 1.0
    textBlock.autoHeight = true
    textBlock.flowDirection = "top_to_bottom"
    textBlock.borderAllSides = 4
    textBlock.paddingAllSides = 10

    ---create header
    local header = textBlock:createLabel{ id = uiids.header, text = headerText }
    header.color = tes3ui.getPalette("header_color")
    header.wrapText = true
    header.justifyText = "center"
    header.widthProportional = 1.0

    ---create description
    if description then
        local descriptionText = description
        local descriptionLabel = textBlock:createLabel{ id = uiids.description, text = descriptionText }
        descriptionLabel.wrapText = true
        descriptionLabel.justifyText = "center"
        descriptionLabel.widthProportional = 1.0
    end

    textBlock:updateLayout()
    return textBlock
end

local function createButtonsBlock(parent)
    local block = parent:createBlock()
    block.flowDirection = "left_to_right"
    block.widthProportional = 1.0
    block.autoHeight = true
    block.childAlignX = 1.0
    return block
end

local function createButton(parent, button)
    local closeButton = parent:createButton{ text = button.text }
    closeButton:register("mouseClick", function()
        local menu = getMenu()
        if menu then
            menu:destroy()
            tes3ui.leaveMenuMode()
        end
        if button.callback then
            button.callback()
        end
    end)
    return closeButton
end

---@class TrophyMenu.createMenu.params
---@field header string The header text
---@field description string The description text
---@field previewMesh string The mesh to be displayed in the trophy menu
---@field buttons TrophyMenu.createMenu.buttonConfig[] A list of buttons to be displayed

---@class TrophyMenu.createMenu.buttonConfig
---@field text string The text to be displayed on the button
---@field callback function The function to be called when the button is clicked

---@param e TrophyMenu.createMenu.params
function TrophyMenu.createMenu(e)
    local menu = tes3ui.createMenu{
        id = uiids.menu,
        fixedFrame = true
    }
    menu.minWidth = TrophyMenu.PREVIEW_WIDTH
    menu.minHeight = TrophyMenu.PREVIEW_HEIGHT
    menu.absolutePosAlignX = 0.5
    menu.flowDirection = "top_to_bottom"
    PreviewPane.new{
        meshID = e.previewMesh,
        parent = menu,
        previewWidth = TrophyMenu.PREVIEW_WIDTH,
        previewHeight = TrophyMenu.PREVIEW_HEIGHT
    }:create()

    createDescription(menu, e.header, e.description)
    local buttonsBlock = createButtonsBlock(menu)
    for _, button in ipairs(e.buttons) do
        createButton(buttonsBlock, button)
    end

    menu:updateLayout()
    tes3ui.enterMenuMode(uiids.menu)
end


return TrophyMenu