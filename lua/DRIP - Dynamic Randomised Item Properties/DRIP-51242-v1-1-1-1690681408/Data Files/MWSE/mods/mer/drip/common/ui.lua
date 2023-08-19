local UI = {}
local doIcon = false

---@return tes3uiElement
function UI.addLabelToTooltip(e)
    local tooltip, text, color = e.tooltip, e.text, e.color
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

    local outerBlock = mainBlock:createBlock{ id = "DRIP_EffectBlock" }
    setupOuterBlock(outerBlock)

    local insertBefore = mainBlock:findChild("HelpMenu_armorRating")
        or mainBlock:findChild("HelpMenu_weaponType") or -2

    mainBlock:reorderChildren(insertBefore, -1, 1)
    mainBlock:updateLayout()

    if text then
        local label = outerBlock:createLabel({text = text})
        label.autoHeight = true
        label.autoWidth = true
        label.widthProportional = 1.0
        if color then label.color = color end
        return label
    end
    return outerBlock
end

function UI.createEffectBlock(e)
    local block = UI.addLabelToTooltip(e)

    -- if doIcon then
    --     local icon = effectBlock:createImage{ path = e.icon }
    --     icon.height = 16
    --     icon.width = 16
    --     icon.scaleMode = true
    --     icon.borderAllSides = 1
    -- end
    -- local effectLabel = effectBlock:createLabel{ text = e.text }
    -- effectLabel.borderLeft = 4
end

return UI