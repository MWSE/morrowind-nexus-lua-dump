--[[
    Common UI functions
]]

local UI = {}
function UI.addLabelToTooltip(tooltip, labelText, color)
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
    --Get main block inside tooltip
    local partmenuID = tes3ui.registerID('PartHelpMenu_main')
    local mainBlock = tooltip:findChild(partmenuID)
        and tooltip:findChild(partmenuID):findChild(partmenuID):findChild(partmenuID)
        or tooltip

    local outerBlock = mainBlock:createBlock()
    setupOuterBlock(outerBlock)

    mainBlock:reorderChildren(1, -1, 1)
    mainBlock:updateLayout()
    if labelText then
        local label = outerBlock:createLabel({text = labelText})
        label.autoHeight = true
        label.autoWidth = true
        label.widthProportional = 1.0
        if color then label.color = color end
        return label
    end
    return outerBlock
end



return UI