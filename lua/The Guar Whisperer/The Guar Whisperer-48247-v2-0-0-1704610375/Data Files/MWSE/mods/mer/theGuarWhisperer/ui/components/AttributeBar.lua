local Formatter = require("mer.theGuarWhisperer.services.Formatter")


---@class GuarWhisperer.UI.AttributeBar
local AttributeBar = {}

---@class GuarWhisperer.UI.AttributeBar.newParams
---@field label string The name of the attribute
---@field current number The current value for the attribute

---@param parent tes3uiElement
---@param e GuarWhisperer.UI.AttributeBar.newParams
function AttributeBar.new(parent, e)
    local attrBlock = parent:createBlock()
    attrBlock.flowDirection = "left_to_right"
    attrBlock.widthProportional = 1.0
    attrBlock.autoHeight = true
    attrBlock:createLabel { text = Formatter.capitaliseFirst(e.label) }
    local value = tostring(e.current)
    local valueLabel = attrBlock:createLabel { text = value }
    valueLabel.absolutePosAlignX = 1.0
end

return AttributeBar