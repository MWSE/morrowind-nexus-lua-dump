
---@class GuarWhisperer.UI.Tooltip
local Tooltip = {}

---Show a tooltip with a header and description.
---@param e { header: string, text: string }
function Tooltip.showTooltip(e)
    local tooltip = tes3ui.createTooltipMenu()

    local outerBlock = tooltip:createBlock({ id = "GuarWhisperer:outerBlock" })
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.paddingTop = 6
    outerBlock.paddingBottom = 12
    outerBlock.paddingLeft = 6
    outerBlock.paddingRight = 6
    outerBlock.width = 300
    outerBlock.autoHeight = true

    local headerText = e.header
    local headerLabel = outerBlock:createLabel({ id = "GuarWhisperer:header", text = headerText })
    headerLabel.autoHeight = true
    headerLabel.width = 285
    headerLabel.color = tes3ui.getPalette("header_color")
    headerLabel.wrapText = true
    local descriptionText = e.text
    local descriptionLabel = outerBlock:createLabel({ id = "GuarWhisperer:description", text = descriptionText })
    descriptionLabel.autoHeight = true
    descriptionLabel.width = 285
    descriptionLabel.wrapText = true

    tooltip:updateLayout()
end

return Tooltip