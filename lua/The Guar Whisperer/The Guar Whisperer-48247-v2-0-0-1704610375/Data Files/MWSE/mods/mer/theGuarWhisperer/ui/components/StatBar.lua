local Tooltip = require("mer.theGuarWhisperer.ui.components.Tooltip")


---@class GuarWhisperer.UI.StatBar
local StatBar = {}

---@class GuarWhisperer.UI.StatBar.newParams
---@field label string The label for the stat
---@field description string The description, shown in a tooltip]
---@field current number The current value for the stat
---@field max number The maximum value for the stat
---@field color table The color of the stat bar
---@field inMenu boolean Whether or not this is being rendered in a menu

---@param parent tes3uiElement
---@param e GuarWhisperer.UI.StatBar.newParams
function StatBar.new(parent, e)
    local fillbar = parent:createFillBar{
        current = e.current,
        max = e.max
    }
    fillbar.widthProportional = 1.0
    --fillbar.height = 10
    fillbar.widget.fillColor = e.color
    if e.inMenu then
        local label = fillbar:findChild("PartFillbar_text_ptr")
        label.text = string.format("%s: %d/%d", e.label, e.current, e.max)
        --fillbar:updateLayout()
    else
        fillbar.height = 10
        fillbar.widget.showText = false
    end

    fillbar:register("help", function()
        local header = e.label
        local description = e.description
        Tooltip.showTooltip{ header = header, text = description }
    end)
end

return StatBar