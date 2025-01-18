local UIHelper = {}
local PaintService = require("mer.joyOfPainting.services.PaintService")
local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("UIHelper")

---@class JOP.UIHelper.addLabelToTooltip.params
---@field tooltip tes3uiElement
---@field labelText string
---@field color tes3vector3

local function setupOuterBlock(e)
    e.flowDirection = 'left_to_right'
    e.paddingTop = 0
    e.paddingBottom = 2
    e.paddingLeft = 6
    e.paddingRight = 6
    e.autoWidth = true
    e.autoHeight = true
    e.childAlignX = 0.5
end

---@param params JOP.UIHelper.addLabelToTooltip.params
function UIHelper.addLabelToTooltip(params)
    assert(params.tooltip, 'params.tooltip is required')
    assert(params.labelText, 'params.labelText is required')
    assert(params.color, 'params.color is required')

    --Get main block inside tooltip
    local partmenuID = tes3ui.registerID('PartHelpMenu_main')
    local mainBlock = params.tooltip:findChild(partmenuID)
        and params.tooltip:findChild(partmenuID):findChild(partmenuID):findChild(partmenuID)
        or params.tooltip

    local outerBlock = mainBlock:createBlock()
    setupOuterBlock(outerBlock)
    mainBlock:reorderChildren(1, -1, 1)
    mainBlock:updateLayout()
    if params.labelText then
        local label = outerBlock:createLabel({text = params.labelText})
        label.autoHeight = true
        label.autoWidth = true
        label.widthProportional = 1.0
        if params.color then label.color = params.color end
        return label
    end
    return outerBlock
end

---@class JOP.UIHelper.createNamePainting.params
---@field dataHolder table The table holding the paintingName field to update
---@field callback function? The function to call when the okay button is pressed
---@field setNameText string? The text to display on the rename button

---@param e JOP.UIHelper.createNamePainting.params
function UIHelper.createNamePaintingField(parent, e)
    local textField = mwse.mcm.createTextField(parent, {
        buttonText = e.setNameText or "Rename",
        variable = mwse.mcm.createTableVariable {
            id = "paintingName",
            table = e.dataHolder
        },
        callback = function()
            e.dataHolder.paintingName = string.trim(e.dataHolder.paintingName)
            if e.dataHolder.paintingName:len() > 31 then
                tes3ui.showMessageMenu{
                    message = "Name too long. Max 22 characters.",
                    buttons = {
                        {
                            text = "OK"
                        }
                    }
                }
                return
            else
                logger:debug("Painting name set to %s", e.dataHolder.paintingName)
                if e.callback then e.callback() end
            end
        end,
        indent = 4,
        paddingBottom = 0
    })
    textField.elements.outerContainer.borderLeft = 4
    tes3ui.acquireTextInput(textField.elements.inputField)
    return textField
end

function UIHelper.createBaseMenu(menuId)
    local menu = tes3ui.createMenu{
        id = menuId,
        fixedFrame = true
    }
    menu.minWidth = 300
    menu.absolutePosAlignX = 0.5
    menu.absolutePosAlignY = 0.5
    return menu
end

---@class JOP.UIHelper.openNamePaintingMenu.button
---@field text string The button text
---@field id string? Button id
---@field callback? function The function to call when the button is pressed
---@field closesMenu boolean True if clicking this button also closes the menu

---@class JOP.UIHelper.openNamePaintingMenu.params
---@field dataHolder table The table holding the paintingName field to update
---@field canvasId string The id of the canvas it is painted on
---@field paintingTexture string
---@field callback function? The function to call when the Name "Submit" button is pressed
---@field cancelCallback function? The function to call whe the cancel button is pressed
---@field tooltipHeader string? The header to show in the on-hover tooltip
---@field tooltipText string? The text to show in the on-hover tooltip
---@field buttons JOP.UIHelper.openNamePaintingMenu.button[]? list of additional buttons to show at the bottom of the menu
---@field cancels? boolean True if the menu has a cancel button
---@field setNameText string? The text to display on the rename button

--[[
    The UI for showing the painting and allowing the user to name it
]]
---@param e JOP.UIHelper.openNamePaintingMenu.params
function UIHelper.openPaintingMenu(e)
    logger:debug("Creating Menu")
    local menu = UIHelper.createBaseMenu("JOP.NamePaintingMenu")
    UIHelper.createPaintingImage(menu, {
        paintingName = e.dataHolder.paintingName,
        paintingTexture = e.paintingTexture,
        canvasId = e.canvasId,
        tooltipHeader = e.tooltipHeader,
        tooltipText = e.tooltipText,
    })
    -- --build button block
    -- local nameBlock = menu:createBlock()
    -- nameBlock.flowDirection = 'left_to_right'
    -- nameBlock.autoHeight = true
    -- nameBlock.widthProportional = 1.0

    local buttonBlock
    buttonBlock = menu:createBlock()
    buttonBlock.flowDirection = 'left_to_right'
    buttonBlock.autoHeight = true
    buttonBlock.widthProportional = 1.0
    buttonBlock.childAlignX = 1.0

    UIHelper.createNamePaintingField(buttonBlock, {
        dataHolder = e.dataHolder,
        setNameText = e.setNameText,
        callback = function()
            tes3ui.leaveMenuMode()
            tes3ui.findMenu(menu.id):destroy()
            if e.callback then e.callback() end
        end
    })

    if e.buttons then
        --add buttons
        for _, b in ipairs(e.buttons) do
            assert(b.text, "Button needs text")
            local button = buttonBlock:createButton{ text = b.text, id = b.id }
            button:register("mouseClick", function()
                if b.closesMenu then
                    tes3ui.leaveMenuMode()
                    tes3ui.findMenu(menu.id):destroy()
                end
                b.callback()
            end)
        end
    end
    --do cancel
    if e.cancels then
        local button = buttonBlock:createButton{ text = "Cancel", id = "JOP.CloseButton" }
        button.borderAllSides = 0
        button.paddingTop = 2
        button.paddingBottom = 4
        button:register("mouseClick", function()
            tes3ui.leaveMenuMode()
            tes3ui.findMenu(menu.id):destroy()
            if e.cancelCallback then e.cancelCallback() end
        end)
    end

    tes3ui.enterMenuMode(menu.id)
end

function UIHelper.scrapePaintingMessage(callback)
    tes3ui.showMessageMenu{
        message = "Scrape the painting from the canvas?",
        buttons = {
            {
                text = "Yes",
                callback = function()
                    callback()
                    tes3.messageBox("You scrape the paint from the canvas.")
                    tes3.playSound{
                        reference = tes3.player,
                        sound = "Item Misc Up"
                    }
                end
            },
        },
        cancels = true,
    }
end

---@param e { header: string, text: string}
function UIHelper.createTooltipMenu(e)
    local thisHeader, thisLabel = e.header, e.text
    local tooltip = tes3ui.createTooltipMenu()

    local outerBlock = tooltip:createBlock()
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.paddingTop = 6
    outerBlock.paddingBottom = 12
    outerBlock.paddingLeft = 6
    outerBlock.paddingRight = 6
    outerBlock.maxWidth = 300
    outerBlock.autoWidth = true
    outerBlock.autoHeight = true

    if thisHeader then
        local headerText = thisHeader
        local headerLabel = outerBlock:createLabel({text = headerText })
        headerLabel.autoHeight = true
        headerLabel.width = 285
        headerLabel.color = tes3ui.getPalette("header_color")
        headerLabel.wrapText = true
    end
    if thisLabel then
        local descriptionText = thisLabel
        local descriptionLabel = outerBlock:createLabel({text = descriptionText })
        descriptionLabel.autoHeight = true
        descriptionLabel.width = 285
        descriptionLabel.wrapText = true
    end
    tooltip:updateLayout()
end


---@class JOP.UIHelper.viewPainting.params
---@field paintingTexture string
---@field canvasId string
---@field tooltipText? string
---@field tooltipHeader? string
---@field height? number The height of the rendered image

--Display a painting in a UI menu
---@param parent tes3uiElement
---@param e JOP.UIHelper.viewPainting.params
---@return { block: tes3uiElement, image: tes3uiElement }?
function UIHelper.createPaintingImage(parent, e)
    --get dimensions
    local _, maxHeight = tes3ui.getViewportSize()
    maxHeight = maxHeight * 0.75
    logger:debug("Max Height: %s", maxHeight)
    local dimensions = PaintService.getPaintingDimensions(e.canvasId, maxHeight)
    if not dimensions then
        logger:error("Could not get dimensions for painting %s", e.canvasId)
        return
    end
    local outerBlock = parent:createBlock{ id = "JOP_PaintingImage_block"}
    outerBlock.flowDirection = "left_to_right"
    outerBlock.borderAllSides = 6
    outerBlock.autoHeight = true
    outerBlock.autoWidth = true

    --create image
    local paintingPath = PaintService.getPaintingTexturePath(e.paintingTexture)
    if tes3.getFileExists(paintingPath) then
        local image = outerBlock:createImage{
            id = "JOP_PaintingImage",
            path = paintingPath
        }

        image.height = e.height or dimensions.height
        image.width = dimensions.width * (image.height / dimensions.height)
        image.scaleMode = true

        -- image.height = dimensions.height
        -- image.scaleMode = true
            --tooltip shows location of painting
        if e.tooltipText then
            image:register("help", function()
                UIHelper.createTooltipMenu{
                    header = e.tooltipHeader,
                    text = e.tooltipText
                }
            end)
        end
        return { block = outerBlock, image = image }
    else
        logger:warn("Painting texture '%s' does not exist", paintingPath)
    end
end

---Display the painting in a tooltip
---@param parent tes3uiElement
---@param painting JOP.Painting
function UIHelper.showTooltipPainting(parent, painting)
    local paintingTexture = painting.data.paintingTexture
    local canvasId = painting.data.canvasId
    UIHelper.createPaintingImage(parent, {
        paintingTexture = paintingTexture,
        canvasId = canvasId,
        height = config.mcm.tooltipPaintingHeight
    })
end


return UIHelper