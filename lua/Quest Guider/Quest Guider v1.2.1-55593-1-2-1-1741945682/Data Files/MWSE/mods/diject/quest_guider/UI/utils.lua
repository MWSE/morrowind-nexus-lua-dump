local this = {}


local function isColorsEqual(color1, color2)
    if not color1 or not color2 then return end
    return color1[1] == color2[1] and color1[2] == color2[2] and color1[3] == color2[3]
end

---@param element tes3uiElement
---@param color number[]|nil
function this.makeLabelSelectable(element, color)
    local originalColor
    element:registerAfter(tes3.uiEvent.mouseOver, function (e)
        if not isColorsEqual(element.color, {1, 1, 1}) then
            originalColor = table.copy(element.color)
            element.color = color or {1, 1, 1}
            element:getTopLevelMenu():updateLayout()
        end
    end)
    element:registerAfter(tes3.uiEvent.mouseLeave, function (e)
        element.color = originalColor or element.color
        element:getTopLevelMenu():updateLayout()
    end)
end

return this