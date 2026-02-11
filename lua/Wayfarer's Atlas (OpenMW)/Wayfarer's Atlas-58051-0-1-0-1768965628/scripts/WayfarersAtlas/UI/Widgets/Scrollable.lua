local UI = require("openmw.ui")
local I = require("openmw.interfaces")
local OMWUtil = require("openmw.util")
local OMWConstants = require("scripts.omw.mwui.constants")

local UIObject = require("scripts/WayfarersAtlas/UI/UIObject")
local Scrollbar = require("scripts/WayfarersAtlas/UI/Widgets/Scrollbar")

local v2 = OMWUtil.vector2

local BORDER_THICKNESS = OMWConstants.border
local SCROLL_BAR_OUTER_WIDTH = 16
local SCROLL_BAR_INNER_WIDTH = 14

---@class WAY.Scrollable: WAY.UIObject
local Scrollable = UIObject:extend("Scrollable")

---@class WAY.Scrollable.Props
---@field size unknown
---@field content unknown?
---@field flexSize unknown Appears to be the size that can be scrolled.
---@field onFocusGain function
---@field onFocusLoss function
---@field startScrollPos unknown?

---@param props WAY.Scrollable.Props
function Scrollable.new(props)
	---@class WAY.Scrollable
	local self = Scrollable.bind(UI.create({
		props = { size = props.size },
	}))

	self.scrollStep = 15
	self.scrollLimit = math.max(props.flexSize.y - props.size.y, 0)
	self.canScroll = props.flexSize.y > props.size.y

	local scrollArea = self:addChild(UIObject.bind({
		type = UI.TYPE.Flex,
		props = {
			autoSize = false,
			size = props.flexSize,
			relativeSize = v2(1, 0),
			position = v2(0, 0),
		},
		content = props.content or UI.content({}),
	}))

	self._scrollArea = scrollArea
	self._params = props

	self.focused = false
	self:registerEvent("focusGain", function()
		self.focused = true
		props.onFocusGain(self)
	end)

	self:registerEvent("focusLoss", function()
		self.focused = false
		props.onFocusLoss(self)
	end)

	local scrollbar = Scrollbar.new(self)
	self._scrollbar = scrollbar
	self:addChild(scrollbar)

	local innerScrollbar = scrollbar:getInnerScrollbar()
	innerScrollbar:getProps().anchor = v2(1, 0)
	self._innerScrollbar = innerScrollbar

	scrollbar:registerEvent("custom_scrolled", function()
		scrollArea:getProps().position = v2(0, OMWUtil.clamp(scrollArea:getProps().position.y, -self.scrollLimit, 0))
		local handle = innerScrollbar:findFirst("handle")
		local scrollProgress = -scrollArea:getProps().position.y / self.scrollLimit
		local handleProgress = (self:getProps().size.y - (SCROLL_BAR_OUTER_WIDTH * 2) - handle.props.size.y - 4)
			* scrollProgress
		handle.props.position = v2(0, handleProgress)

		self:queueUpdate()
	end)

	if props.startScrollPos then
		scrollArea:getProps().position = v2(0, OMWUtil.clamp(props.startScrollPos, -self.scrollLimit, 0))
	end

	self:queueUpdate()

	return self
end

function Scrollable:getScrollArea()
	return self._scrollArea
end

function Scrollable:onUpdate()
	local props = self:getProps()
	local scrollAreaProps = self._scrollArea:getProps()
	local outerSize = props.size
	local innerSize = self._params.flexSize

	local scrollLimit = math.max(innerSize.y - outerSize.y, 0)
	local canScroll = scrollLimit > 0

	props.size = outerSize
	scrollAreaProps.size = innerSize

	self.scrollLimit = scrollLimit
	self.canScroll = canScroll

	self._innerScrollbar:getProps().size = v2(SCROLL_BAR_INNER_WIDTH, props.size.y - (SCROLL_BAR_OUTER_WIDTH * 2))
	if canScroll then
		self._innerScrollbar:findFirst("handle").props.size = v2(
			SCROLL_BAR_INNER_WIDTH - BORDER_THICKNESS * 2 - 1,
			math.max(
				(props.size.y / (self.scrollLimit + props.size.y)) * (props.size.y - (SCROLL_BAR_OUTER_WIDTH * 2)),
				SCROLL_BAR_INNER_WIDTH
			)
		)
	else
		self._innerScrollbar:findFirst("handle").props.size = v2(0, 0)
	end

	if canScroll then
		scrollAreaProps.size = v2(-SCROLL_BAR_OUTER_WIDTH - BORDER_THICKNESS * 2, scrollAreaProps.size.y)
		self._innerScrollbar:getProps().visible = true
	else
		scrollAreaProps.size = v2(0, scrollAreaProps.size.y)
		self._innerScrollbar:getProps().visible = false
	end

	self._scrollbar:update()

	self:triggerEvent("custom_scrolled")
end

return Scrollable
