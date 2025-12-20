
---@class ChargenScenarios.Util.Menu
local Menu = {}

---@param e { parent: tes3uiElement, id?: string, text: string }
function Menu.createHeading(e)
    local title = e.parent:createLabel{
        id = e.id,
        text = e.text
    }
    title.color = tes3ui.getPalette("header_color")
    title.absolutePosAlignX = 0.5
    title.borderTop = 4
    title.borderBottom = 4
    return title
end

function Menu.createSubheading(e)
    local title = e.parent:createLabel{
        id = e.id,
        text = e.text
    }
    title.color = tes3ui.getPalette("normal_color")
    title.absolutePosAlignX = 0.5
    title.borderTop = 4
    title.borderBottom = 4
    return title
end

---@param e { parent: tes3uiElement, id?: string}
---@return tes3uiElement
function Menu.createButtonsBlock(e)
    local buttonBlock = e.parent:createBlock{ id = e.id }
    buttonBlock.flowDirection = "left_to_right"
    buttonBlock.autoHeight = true
    buttonBlock.autoWidth = true
    buttonBlock.widthProportional = 1.0
    buttonBlock.childAlignX = 1.0
    return buttonBlock
end

---@param e { parent: tes3uiElement, text: string, id?: string, callback: function }
---@return tes3uiElement
function Menu.createButton(e)
    local okButton = e.parent:createButton{
        text = e.text,
        id = e.id,
    }
    okButton:register("mouseClick", e.callback)
    return okButton
end

---@param e { parent: tes3uiElement, id?: string }
---@return tes3uiElement
function Menu.createOuterBlock(e)
    local outerBlock = e.parent:createBlock{ id = e.id }
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.autoHeight = true
    outerBlock.autoWidth = true
    return outerBlock
end

---@param e { parent: tes3uiElement, id?: string, height: number }
---@return tes3uiElement
function Menu.createInnerBlock(e)
    local innerBlock = e.parent:createBlock{ id = e.id }
    innerBlock.height = e.height
    innerBlock.autoWidth = true
    innerBlock.flowDirection = "left_to_right"
    return innerBlock
end


return Menu