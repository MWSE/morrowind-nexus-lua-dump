local util = require("openmw.util")
local ui = require("openmw.ui")

local config = require("scripts.advanced_world_map.config.config")
local eventSys = require("scripts.advanced_world_map.eventSys")

local this = {}


---@class advancedWorldMap.ui.mapElementMeta
local mapElementMeta = {}
mapElementMeta.__index = mapElementMeta


---@param val boolean
function mapElementMeta:setVisibility(val)
    local isVisibleChanged = self._elemLayout.props.visible ~= val
    self._elemLayout.props.visible = val
    self._params.visible = val
    if isVisibleChanged then
        self._parent:setElementVisibility(self._id, self._layerId, val)
    end
end

---@return boolean
function mapElementMeta:getVisibility()
    if self._params.visible == false then
        return false
    end
    return true
end

---@param val number [0, 1]
function mapElementMeta:setAlpha(val)
    self._elemLayout.props.alpha = val
    self._params.alpha = val
end

---@return number [0, 1]
function mapElementMeta:getAlpha()
    return self._params.alpha or 1
end

---@param val integer
function mapElementMeta:setSize(val)
    if self._params.text then
        self._params.fontSize = val
        self._elemLayout.userData.fontSize = val
        self._elemLayout.props.textSize = (self._params.scaleFunc or self._parent.SCALE_FUNCTION.marker)(val, self._parent.zoom)
    elseif self._params.texture then
        self._params.size = util.vector2(val, val)
        self._elemLayout.userData.size = self._params.size
        self._elemLayout.props.size = (self._params.scaleFunc or self._parent.SCALE_FUNCTION.marker)(self._params.size, self._parent.zoom)
    end
end

---@return integer|{x : number, y : number}
function mapElementMeta:getSize()
    if self._params.text then
        return self._params.fontSize
    elseif self._params.texture then
        return self._params.size
    end
    return 0
end

---@return number[]?
function mapElementMeta:getColor()
    if self._params.text then
        return self._elemLayout.props.textColor
    elseif self._params.texture then
        return self._elemLayout.props.color
    end
end

function mapElementMeta:setColor(color)
    if self._params.text then
        self._elemLayout.props.textColor = color
        self._params.color = color
    elseif self._params.texture then
        self._elemLayout.props.color = color
        self._params.color = color
    end
end

function mapElementMeta:setPosition(pos)
    self._params.pos = pos
    self._elemLayout.props.relativePosition = self._parent:getRelativePositionByWorldPosition(pos)
end

function mapElementMeta:getPosition()
    return self._params.pos
end

function mapElementMeta:setTexture(texture)
    if self._elemLayout.type ~= ui.TYPE.Image then
        return false
    end
    self._params.texture = texture
    self._elemLayout.props.resource = texture
    return true
end

function mapElementMeta:setText(text)
    if self._elemLayout.type == ui.TYPE.Image then
        return false
    end
    self._params.text = text
    self._elemLayout.props.text = text
    return true
end


---@param data advancedWorldMap.ui.mapWidgetMeta.createTextMarker.params|advancedWorldMap.ui.mapWidgetMeta.createImageMarker.params
function mapElementMeta:updateLayout(data)
    if not data then data = {} end ---@diagnostic disable-line: missing-fields
    local props = self._elemLayout.props
    props.text = data.text or props.text
    props.size = data.size and (self._params.scaleFunc or self._parent.SCALE_FUNCTION.marker)(data.size, self._parent.zoom) or props.size
    props.textSize = data.fontSize and (self._params.scaleFunc or self._parent.SCALE_FUNCTION.marker)(data.fontSize, self._parent.zoom)
        or props.textSize
    props.anchor = data.anchor or props.anchor
    if data.pos then
        props.relativePosition = self._parent:getRelativePositionByWorldPosition(data.pos)
    end
    if data.color then
        props.textColor = props.text and data.color or nil
        props.color = props.resource and data.color or nil
    end
    if data.textShadow ~= nil then
        props.textShadow = data.textShadow
    end
    props.textShadowColor = data.shadowColor or props.shadowColor
    if data.visible ~= nil then
        local last = props.visible
        props.visible = data.visible
        if last ~= props.visible then
            self._parent:setElementVisibility(self._id, self._layerId, data.visible)
        end
    end
    props.alpha = data.alpha or props.alpha
    props.resource = data.texture or props.resource
    props.textAlignH = data.textAlignH or props.textAlignH
    props.textAlignV = data.textAlignV or props.textAlignV

    self._elemLayout.type = props.text and (data.autoHeight and ui.TYPE.TextEdit or ui.TYPE.Text) or ui.TYPE.Image
    props.autoSize = self._elemLayout.type ~= ui.TYPE.Image and props.size == nil or nil

    props.autoSize = data.autoHeight and true or props.autoSize
    props.multiline = data.autoHeight and true or props.multiline
    props.wordWrap = data.autoHeight and true or props.wordWrap
    props.readOnly = data.autoHeight and true or props.readOnly

    self._elemLayout.userData.forceChanged = true
end


---@param data advancedWorldMap.ui.mapWidgetMeta.createTextMarker.params|advancedWorldMap.ui.mapWidgetMeta.createImageMarker.params
function mapElementMeta:updateParams(data)
    if not data then data = {} end ---@diagnostic disable-line: missing-fields

    self._params.text = data.text or self._params.text
    self._params.size = data.size or self._params.size
    self._params.fontSize = data.fontSize or self._params.fontSize
    self._params.anchor = data.anchor or self._params.anchor
    self._params.pos = data.pos or self._params.pos
    self._params.color = data.color or self._params.color
    if data.textShadow ~= nil then
        self._params.textShadow = data.textShadow
    end
    self._params.shadowColor = data.shadowColor or self._params.shadowColor
    if data.visible ~= nil then
        self._params.visible = data.visible
    end
    self._params.alpha = data.alpha or self._params.alpha
    self._params.texture = data.texture or self._params.texture
    self._params.scaleFunc = data.scaleFunc or self._params.scaleFunc
    if data.autoHeight ~= nil then
        self._params.autoHeight = data.autoHeight
    end
    self._params.textAlignH = data.textAlignH or self._params.textAlignH
    self._params.textAlignV = data.textAlignV or self._params.textAlignV
end


function mapElementMeta:restoreLayout()
    local isVisibleChanged = self._elemLayout.props.visible ~= self._params.visible
    self._elemLayout.props = {
        text = self._params.text,
        textSize = self._params.text and (self._params.scaleFunc or self._parent.SCALE_FUNCTION.marker)(self._params.fontSize or 18, self._parent.zoom) or nil,
        anchor = self._params.anchor or util.vector2(0.5, 0.5),
        relativePosition = self._parent:getRelativePositionByWorldPosition(self._params.pos),
        textColor = self._params.text and (self._params.color or config.data.ui.defaultColor) or nil,
        textShadow = self._params.text and self._params.textShadow or nil,
        textShadowColor = self._params.text and self._params.shadowColor or nil,
        visible = self._params.visible,
        alpha = self._params.alpha or 1,
        resource = self._params.texture,
        size = self._params.size and (self._params.scaleFunc or self._parent.SCALE_FUNCTION.marker)(self._params.size, self._parent.zoom),
        color = self._params.texture and (self._params.color or config.data.ui.defaultColor),
        propagateEvents = false,
        textAlignH = self._params.textAlignH,
        textAlignV = self._params.textAlignV,
        multiline = self._params.autoHeight and true or nil,
        wordWrap = self._params.autoHeight and true or nil,
        readOnly = self._params.autoHeight and true or nil,
        autoSize = self._params.autoHeight and true or nil,
    }
    self._elemLayout.type = self._params.text and (self._params.autoHeight and ui.TYPE.TextEdit or ui.TYPE.Text) or ui.TYPE.Image
    self._elemLayout.userData.scaleFunc = self._params.scaleFunc
    self._elemLayout.userData.autoScale = true
    self._elemLayout.userData.fontSize = self._params.text and (self._params.fontSize or 18) or nil
    self._elemLayout.userData.size = self._params.size

    self._elemLayout.userData.forceChanged = false

    if isVisibleChanged then
        self._parent:setElementVisibility(self._id, self._layerId, self._params.visible)
    end
end


function mapElementMeta:getUserData()
    return self._elemLayout.userData.userData
end


---@return string
function mapElementMeta:getId()
    return self._id
end

---@return integer
function mapElementMeta:getLayerId()
    return self._layerId
end


function mapElementMeta:destroy()
    self.invalid = true
    if self._parent:removeMarker(self._id, self._layerId) then
        eventSys.triggerEvent(eventSys.EVENT.onMapElementRemoved, {mapWidget = self._parent, marker = self})
    end
end


function mapElementMeta:isValid()
    if self.invalid then return false end
    if not self._parent:hasMarker(self._id) then
        self.invalid = true
        return false
    end
    if not self._parent:isValid() then
        self.invalid = true
        return false
    end
    return true
end


---@param parentMeta advancedWorldMap.ui.mapWidgetMeta
---@param elemParams advancedWorldMap.ui.mapWidgetMeta.createTextMarker.params|advancedWorldMap.ui.mapWidgetMeta.createImageMarker.params
---@return advancedWorldMap.ui.mapElementMeta
function this.new(parentMeta, id, layerId, elemParams, elemLayout)
    ---@class advancedWorldMap.ui.mapElementMeta
    local meta = setmetatable({}, mapElementMeta)

    meta._id = id
    meta._layerId = layerId
    meta._parent = parentMeta
    meta._params = elemParams
    meta._elemLayout = elemLayout

    return meta
end


return this