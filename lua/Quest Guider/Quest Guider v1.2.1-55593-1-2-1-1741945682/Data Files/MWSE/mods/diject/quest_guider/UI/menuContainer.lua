local this = {}

this.containerMenuId = {
    id = "qGuider_container",
    buttonBlock = "qGuider_container_btnBlock",
    closeBtn = "qGuider_container_closeBtn",
}


---@param label string
---@param callback fun( menu : tes3uiElement, buttonBlock : tes3uiElement)?
---@return tes3uiElement? menuElement
---@return tes3uiElement? buttonBlock
function this.draw(label, callback)
    local element = tes3ui.createMenu{ id = this.containerMenuId.id, dragFrame = true, }
    element.text = label
    local frame = element:findChild("PartDragMenu_drag_frame")
    if not frame then return end
    local buttonBlock = frame:createBlock{ id = this.containerMenuId.buttonBlock }
    buttonBlock.autoHeight = true
    buttonBlock.autoWidth = true
    buttonBlock.flowDirection = tes3.flowDirection.leftToRight
    buttonBlock.widthProportional = 1
    buttonBlock.borderTop = 2
    buttonBlock.borderBottom = 1
    buttonBlock.childAlignX = 1

    if callback then
        callback(element, buttonBlock)
    end

    local closeButton = buttonBlock:createButton{ id = this.containerMenuId.closeBtn, text = "Close"}
    closeButton:register(tes3.uiEvent.mouseClick, function (e)
        element:destroy()
    end)

    return element, buttonBlock
end


---@param element tes3uiElement
function this.centerToCursor(element)
    local width, height = tes3.getViewportSize()
    local scale = tes3ui.getViewportScale()
    width = width / scale
    height = height / scale
    local halfWidth = width / 2
    local halfHeight = height / 2
    local curPos = tes3.getCursorPosition()

    element.positionX = math.clamp(curPos.x - element.width / 2, -halfWidth, halfWidth - element.width)
    element.positionY = math.clamp(curPos.y + 10, -halfHeight + element.height, halfHeight)

    element:getTopLevelMenu():updateLayout()
end

---@param mainBlock tes3uiElement
---@param scrollBlock tes3uiElement|nil
---@param defaultMainBlock tes3uiElement?
function this.updateContainerMenu(mainBlock, scrollBlock, defaultMainBlock)
    local topMenu = mainBlock:getTopLevelMenu()
    topMenu:updateLayout()

    if defaultMainBlock then
        topMenu:setLuaData("mainBlock", defaultMainBlock)
    end

    mainBlock = topMenu:getLuaData("mainBlock") or mainBlock

    if scrollBlock and scrollBlock.widget then
        scrollBlock.widget:contentsChanged()
    end

    if topMenu.name == this.containerMenuId.id then
        topMenu.maxWidth = nil
        topMenu.maxHeight = nil
        topMenu.minWidth = nil
        topMenu.minHeight = nil
        topMenu.height = mainBlock.height + 77
        topMenu.width = mainBlock.width + 24
        topMenu.maxWidth = topMenu.width
        topMenu.maxHeight = topMenu.height
        topMenu.minWidth = topMenu.width
        topMenu.minHeight = topMenu.height
        topMenu:updateLayout()
        if scrollBlock and scrollBlock.widget then
            scrollBlock.widget:contentsChanged()
        end
    end
end


---@param element tes3uiElement
function this.centerToScreen(element)
    element.positionX = -element.width / 2
    element.positionY = element.height / 2

    element:getTopLevelMenu():updateLayout()
end


return this