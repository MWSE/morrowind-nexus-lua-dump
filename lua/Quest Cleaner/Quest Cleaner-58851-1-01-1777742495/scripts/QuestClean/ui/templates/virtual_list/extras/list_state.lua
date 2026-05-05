---@class ListState
---@field private element VirtualListElement
---@field private pressedIndex number?
---@field private selectedIndex number?
local ListState = {}
ListState.__index = ListState

-- We need to embed the types for the whole Element->Layout->UserData chain so
-- that LLS understands it.

---@class VirtualListExtUserData
---@field listState ListState

---@class VirtualListExtLayout
---@field userData VirtualListExtUserData

---@class VirtualListExt : VirtualListElement
---@field layout VirtualListLayout | VirtualListExtLayout


---@param element VirtualListElement
---@return ListState
function ListState.new(element)
    return setmetatable({ element = element }, ListState):resetSelection()
end


---@param element VirtualListElement
---@return ListState
function ListState.from(element)
    local layout = element.layout
    local userData = layout.userData
    if userData.listState == nil then
        userData.listState = ListState.new(element)
    end
    return userData.listState
end


--- Reset the lists internal selection state. Does not trigger UI updates!
---
---@return ListState
function ListState:resetSelection()
    self.pressedIndex = nil
    self.selectedIndex = nil
    return self
end


---@return number?
function ListState:getSelectedIndex()
    return self.selectedIndex
end


---@param index number?
function ListState:setSelectedIndex(index)
    self.selectedIndex = index
end


---@param index number
---@return boolean
function ListState:isSelected(index)
    return self.selectedIndex == index
end


---@return number?
function ListState:getPressedIndex()
    return self.pressedIndex
end


---@param index number?
function ListState:setPressedIndex(index)
    self.pressedIndex = index
end


---@param index number
---@return boolean
function ListState:isPressed(index)
    return self.pressedIndex == index
end


---
--- Font Color Methods
---
local dir = (...):match("(.+)%.[^.]+$")

---@type FontColors
local FontColors = require(dir .. ".font_color")


---@param index number
---@return Color
function ListState:getOverColor(index)
    return FontColors.getOverColor(self:isSelected(index))
end


---@param index number
---@return Color
function ListState:getColor(index)
    return FontColors.getColor(self:isSelected(index), self:isPressed(index))
end


---@param layout Layout
---@param index number
function ListState:updateColor(layout, index)
    local textColor = self:getColor(index)
    if layout.props.textColor ~= textColor then
        layout.props.textColor = textColor
        pcall(function() self.element:update() end)
    end
end


---@param layout Layout
---@param index number
function ListState:updateOverColor(layout, index)
    local textColor = self:getOverColor(index)
    if layout.props.textColor ~= textColor then
        layout.props.textColor = textColor
        pcall(function() self.element:update() end)
    end
end


--- Convenience method to change the selected item and update the appropriate text colors.
---
---@param newIndex number
---@param getTextLayout (fun(i: number?): Layout?)?
function ListState:changeSelection(newIndex, getTextLayout)
    local oldIndex = self:getSelectedIndex() --[[@as number]]

    -- Defaults to the first content item for basic lists with just a single text element.
    getTextLayout = getTextLayout or function(i)
        local layout = self.element.layout.userData.scrollData:getItemLayout(i)
        return layout and layout.content[1]
    end

    self:setSelectedIndex(newIndex)

    local previous = getTextLayout(oldIndex)
    if previous then
        self:updateColor(previous, oldIndex)
    end

    local current = getTextLayout(newIndex)
    if current then
        self:updateColor(current, newIndex)
    end
end


return ListState
