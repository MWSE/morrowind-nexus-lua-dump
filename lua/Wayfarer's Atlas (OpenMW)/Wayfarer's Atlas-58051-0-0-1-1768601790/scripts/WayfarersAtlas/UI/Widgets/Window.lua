local UI = require("openmw.ui")
local OMWUtil = require("openmw.util")

local UIObject = require("scripts/WayfarersAtlas/UI/UIObject")
local SharedUI = require("scripts/WayfarersAtlas/UI/SharedUI")
local Utils = require("scripts/WayfarersAtlas/Utils")
local Cursor = require("scripts/WayfarersAtlas/UI/Widgets/Cursor")
local ContainerWithHeader = require("scripts/WayfarersAtlas/UI/Widgets/ContainerWithHeader")

local v2 = OMWUtil.vector2

local function sign(x)
	if x > 0 then
		return 1
	elseif x == 0 then
		return 0
	else
		return -1
	end
end

local DRAG_TYPE = {
	ResizeL = 1,
	ResizeR = 2,
	ResizeT = 3,
	ResizeB = 4,
	ResizeTL = 5,
	ResizeBR = 6,
	ResizeTR = 7,
	ResizeBL = 8,
	Move = 9,
}

local DRAG_TYPE_ICONS = {
	[DRAG_TYPE.ResizeL] = "resize_h",
	[DRAG_TYPE.ResizeR] = "resize_h",
	[DRAG_TYPE.ResizeT] = "resize_v",
	[DRAG_TYPE.ResizeB] = "resize_v",
	[DRAG_TYPE.ResizeTL] = "resize_d1",
	[DRAG_TYPE.ResizeBR] = "resize_d1",
	[DRAG_TYPE.ResizeTR] = "resize_d2",
	[DRAG_TYPE.ResizeBL] = "resize_d2",
	[DRAG_TYPE.Move] = "move",
}

---@class WAY.Window: WAY.UIObject
local Window = UIObject:extend("Window")

---@class WAY.Window.Props
---@field minSize unknown
---@field layer string?
---@field onDragged fun(pos)
---@field onResized fun(size)

---@param props WAY.Window.Props
function Window.new(props)
	---@class WAY.Window
	local self = Window.bind(UI.create({
		layer = props.layer or "Windows",
	}))

	self._props = props
	self._cursor = Cursor.new()
	self:getProps().size = v2(0, 0)

	self._container = ContainerWithHeader.new()
	self:addChild(self._container:getBound())

	self:_onInit()

	return self
end

function Window:setTitle(title)
	self._container:setTitle(title)
	self:queueUpdate()
end

function Window:setPosition(newPos)
	self._windowOffset = newPos
	self:queueUpdate()
end

function Window:setSize(newSize)
	self:getProps().size = newSize
	self:queueUpdate()
end

function Window:getWindowContent()
	return self._container:getContainerContent()
end

function Window:_onInit()
	self:registerEvent("focusLoss", function()
		self._cursor:setVisible(false)
	end)

	self:registerEvent("mousePress", function(e)
		self:_onMousePress(e)
	end)

	self:registerEvent("mouseMove", function(e)
		self:_onMouseMove(e)
	end)

	self:registerEvent("mouseRelease", function(e)
		self:_onMouseRelease(e)
	end)
end

function Window:onUpdate()
	local props = self:getProps()
	local screenSize = UI.screenSize()

	props.size = Utils.v2clamp(props.size, self._props.minSize, screenSize)
	props.position = Utils.v2clamp(self._windowOffset, v2(0, 0), screenSize - props.size)
end

function Window:onDestroyed()
	self._cursor:destroy()
end

function Window:_resizeWindow(sizeDelta, offsetDir)
	local newSize = self._dragStartSize + sizeDelta
	local clampedSize = Utils.v2clamp(newSize, self._props.minSize, UI.screenSize())
	local sizeChange = clampedSize - self._dragStartSize

	self:setSize(clampedSize)

	local correctedOffsetDelta = Utils.v2mul(offsetDir, v2(math.abs(sizeChange.x), math.abs(sizeChange.y)))
	self:setPosition(self._dragStartPos + correctedOffsetDelta)
end

function Window:_onMousePress(e)
	if e.button == SharedUI.MouseButton.Left then
		self._dragging = true
		self._dragStartAbs = e.position
		self._dragStartSize = self:getProps().size
		self._dragStartPos = self._windowOffset
	end
end

function Window:_dragTypeFromOffset(offset)
	local topEdge = offset.y < 8
	local bottomEdge = offset.y > self:getProps().size.y - 12
	local leftEdge = offset.x < 12
	local rightEdge = offset.x > self:getProps().size.x - 12
	local header = offset.y < 28

	if topEdge and leftEdge then
		return DRAG_TYPE.ResizeTL
	elseif bottomEdge and rightEdge then
		return DRAG_TYPE.ResizeBR
	elseif topEdge and rightEdge then
		return DRAG_TYPE.ResizeTR
	elseif bottomEdge and leftEdge then
		return DRAG_TYPE.ResizeBL
	elseif leftEdge then
		return DRAG_TYPE.ResizeL
	elseif rightEdge then
		return DRAG_TYPE.ResizeR
	elseif topEdge then
		return DRAG_TYPE.ResizeT
	elseif bottomEdge then
		return DRAG_TYPE.ResizeB
	elseif header then
		return DRAG_TYPE.Move
	else
		return nil
	end
end

function Window:_onMouseMove(e)
	if not self._dragging then
		self._dragType = self:_dragTypeFromOffset(e.offset)
	else
		local delta = e.position - self._dragStartAbs

		if self._dragType == DRAG_TYPE.ResizeL then
			self:_resizeWindow(v2(-delta.x, 0), v2(sign(delta.x), 0))
		elseif self._dragType == DRAG_TYPE.ResizeR then
			self:_resizeWindow(v2(delta.x, 0), v2(0, 0))
		elseif self._dragType == DRAG_TYPE.ResizeT then
			self:_resizeWindow(v2(0, -delta.y), v2(0, sign(delta.y)))
		elseif self._dragType == DRAG_TYPE.ResizeB then
			self:_resizeWindow(v2(0, delta.y), v2(0, 0))
		elseif self._dragType == DRAG_TYPE.ResizeTL then
			self:_resizeWindow(v2(-delta.x, -delta.y), v2(sign(delta.x), sign(delta.y)))
		elseif self._dragType == DRAG_TYPE.ResizeBR then
			self:_resizeWindow(v2(delta.x, delta.y), v2(0, 0))
		elseif self._dragType == DRAG_TYPE.ResizeTR then
			self:_resizeWindow(v2(delta.x, -delta.y), v2(0, sign(delta.y)))
		elseif self._dragType == DRAG_TYPE.ResizeBL then
			self:_resizeWindow(v2(-delta.x, delta.y), v2(sign(delta.x), 0))
		elseif self._dragType == DRAG_TYPE.Move then
			self._windowOffset = self._dragStartPos + delta
		end

		self:queueUpdate()
	end

	if self._dragType then
		self._cursor:changeIcon(UI.texture({
			path = "icons/WayfarersAtlas/cursor/" .. DRAG_TYPE_ICONS[self._dragType] .. ".dds",
		}))
		self._cursor:move(e.position)
		self._cursor:setVisible(true)
	else
		self._cursor:setVisible(false)
	end
end

function Window:_onMouseRelease(e)
	if self._dragging and e.button == SharedUI.MouseButton.Left then
		self._dragging = false
		self._dragType = nil

		self._props.onDragged(self._windowOffset)
		self._props.onResized(self:getProps().size)
	end
end

return Window
