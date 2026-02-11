local UI = require("openmw.ui")
local OMWUtil = require("openmw.util")

local UIObject = require("scripts/WayfarersAtlas/UI/UIObject")
local SharedUI = require("scripts/WayfarersAtlas/UI/SharedUI")
local Utils = require("scripts/WayfarersAtlas/Utils")
local ContainerWithHeader = require("scripts/WayfarersAtlas/UI/Widgets/ContainerWithHeader")
local UIContext = require("scripts/WayfarersAtlas/UI/UIContext")

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

---@class WAY.Window: WAY.UIObject
local Window = UIObject:extend("Window")

---@class WAY.Window.Props
---@field minSize unknown
---@field layer string?

---@param props WAY.Window.Props
function Window.new(props)
	---@class WAY.Window
	local self = Window.bind(UI.create({
		layer = props.layer or "Windows",
	}))

	self._props = props
	self:getProps().size = v2(0, 0)
	self:getProps().position = v2(0, 0)

	self._container = ContainerWithHeader.new(function(dragType)
		self._dragType = dragType
	end)
	self:addChild(self._container:getBound())

	self:_onInit()

	return self
end

function Window:setSaveId(saveId)
	self._saveId = saveId

	if UIContext.saveData.windowPositions[saveId] then
		self:setPosition(UIContext.saveData.windowPositions[saveId])
	end

	if UIContext.saveData.windowSizes[saveId] then
		self:setSize(UIContext.saveData.windowSizes[saveId])
	end
end

function Window:setTitle(title)
	self._container:setTitle(title)
	self:queueUpdate()
end

function Window:setPosition(newPos)
	self:getProps().position = newPos
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
	local screenSpace = UIContext.getScreenSpace()

	props.size = Utils.v2clamp(props.size, self._props.minSize, screenSpace)
	props.position = Utils.v2clamp(props.position, v2(0, 0), screenSpace - props.size)

	if self._saveId then
		UIContext.saveData.windowPositions[self._saveId] = self:getProps().position
		UIContext.saveData.windowSizes[self._saveId] = self:getProps().size
	end
end

function Window:_resizeWindow(sizeDelta, offsetDir)
	local newSize = self._dragStartSize + sizeDelta
	local clampedSize = Utils.v2clamp(newSize, self._props.minSize, UIContext.getScreenSpace())
	local sizeChange = clampedSize - self._dragStartSize

	self:setSize(clampedSize)

	local correctedOffsetDelta = Utils.v2mul(offsetDir, v2(math.abs(sizeChange.x), math.abs(sizeChange.y)))
	self:setPosition(self._dragStartPos + correctedOffsetDelta)

	self:triggerEvent("custom_resized")
end

function Window:_onMousePress(e)
	if e.button == SharedUI.MouseButton.Left then
		self._dragging = true
		self._dragStartAbs = e.position
		self._dragStartSize = self:getProps().size
		self._dragStartPos = self:getProps().position
	end
end

function Window:_onMouseMove(e)
	if self._dragging then
		local delta = e.position - self._dragStartAbs

		if self._dragType == SharedUI.DragType.ResizeL then
			self:_resizeWindow(v2(-delta.x, 0), v2(sign(delta.x), 0))
		elseif self._dragType == SharedUI.DragType.ResizeR then
			self:_resizeWindow(v2(delta.x, 0), v2(0, 0))
		elseif self._dragType == SharedUI.DragType.ResizeT then
			self:_resizeWindow(v2(0, -delta.y), v2(0, sign(delta.y)))
		elseif self._dragType == SharedUI.DragType.ResizeB then
			self:_resizeWindow(v2(0, delta.y), v2(0, 0))
		elseif self._dragType == SharedUI.DragType.ResizeTL then
			self:_resizeWindow(v2(-delta.x, -delta.y), v2(sign(delta.x), sign(delta.y)))
		elseif self._dragType == SharedUI.DragType.ResizeBR then
			self:_resizeWindow(v2(delta.x, delta.y), v2(0, 0))
		elseif self._dragType == SharedUI.DragType.ResizeTR then
			self:_resizeWindow(v2(delta.x, -delta.y), v2(0, sign(delta.y)))
		elseif self._dragType == SharedUI.DragType.ResizeBL then
			self:_resizeWindow(v2(-delta.x, delta.y), v2(sign(delta.x), 0))
		elseif self._dragType == SharedUI.DragType.Move then
			self:getProps().position = self._dragStartPos + delta
		end

		self:queueUpdate()
	end
end

function Window:_onMouseRelease(e)
	if self._dragging and e.button == SharedUI.MouseButton.Left then
		self._dragging = false
		self._dragType = nil
	end
end

return Window
