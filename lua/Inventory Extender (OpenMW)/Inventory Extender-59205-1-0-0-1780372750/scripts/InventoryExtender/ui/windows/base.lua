local auxUi = require('openmw_aux.ui')

local util = require('openmw.util')
local v2 = util.vector2
local ui = require('openmw.ui')
local helpers = require('scripts.InventoryExtender.util.helpers')

local Window = {}

Window.__index = Window
function Window:new()
    local o = setmetatable({}, self)
    self.__index = self
    self.element = nil
    return o
end

function Window:update(deep)
    if self.element then
        if deep then
            auxUi.deepUpdate(self.element)
        else
            self.element:update()
        end
    end
end

function Window:isVisible()
    if not self.element then return false end

    return self.element.layout.props.visible
end

function Window:setVisible(visible)
    if not self.element then return end

    self.element.layout.props.visible = visible
    self:update()
end

function Window:isPinnable()
    if not self.element then return false end

    return self.element.layout.userData.pinnable
end

function Window:isPinned()
    if not self.element then return false end

    return self.element.layout.userData.pinned
end

function Window:isFocused()
    if not self.element then return false end

    return self.element.layout.userData.focused
end

function Window:setFocused(focused)
    if not self.element then return end

    self.element.layout.userData.focused = focused
end

function Window:getDimensions()
    if not self.element then return nil end

    local layerSize = ui.layers[ui.layers.indexOf('Windows')].size

    local props = self.element.layout.props
    if not props or not props.position or not props.size then return nil end
    return {
        x = helpers.roundToPlaces(props.position.x / layerSize.x, 6),
        y = helpers.roundToPlaces(props.position.y / layerSize.y, 6),
        w = helpers.roundToPlaces(props.size.x / layerSize.x, 6),
        h = helpers.roundToPlaces(props.size.y / layerSize.y, 6),
    }
end

function Window:setDimensions(dimensions)
    if not self.element then return end

    local layerSize = ui.layers[ui.layers.indexOf('Windows')].size

    self.element.layout.props.position = v2(dimensions.x * layerSize.x, dimensions.y * layerSize.y)
    self.element.layout.props.size = v2(dimensions.w * layerSize.x, dimensions.h * layerSize.y)
    self:update()
end

-- Stub methods to be overridden
function Window:saveState() end
function Window:loadState() end

return Window