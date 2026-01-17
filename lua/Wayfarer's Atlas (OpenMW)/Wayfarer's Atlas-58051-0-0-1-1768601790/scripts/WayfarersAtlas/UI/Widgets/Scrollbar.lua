local UI = require("openmw.ui")
local I = require("openmw.interfaces")
local OMWUtil = require("openmw.util")
local Async = require("openmw.async")

local UIObject = require("scripts/WayfarersAtlas/UI/UIObject")

local v2 = OMWUtil.vector2

local SCROLL_BAR_OUTER_WIDTH = 16
local SCROLL_BAR_INNER_WIDTH = 14

---@class WAY.Scrollbar: WAY.UIObject
local Scrollbar = UIObject:extend("Scrollbar")

---@param scrollable WAY.Scrollable
function Scrollbar.new(scrollable)
	local scrollbarContent = UI.content({})
	---@class WAY.Scrollbar
	local self = Scrollbar.bind({
		type = UI.TYPE.Flex,
		name = "scrollBarWrapper",
		props = {
			position = v2(-SCROLL_BAR_OUTER_WIDTH + (SCROLL_BAR_OUTER_WIDTH - SCROLL_BAR_INNER_WIDTH) / 2 - 2, 0),
			relativePosition = v2(1, 0),
		},
		content = scrollbarContent,
	})

	local function calcScrollBarSize()
		return v2(SCROLL_BAR_INNER_WIDTH, scrollable:getProps().size.y - (SCROLL_BAR_INNER_WIDTH * 2))
	end
	local function calcHandleSize()
		return math.max(
			(scrollable:getProps().size.y / (scrollable.scrollLimit + scrollable:getProps().size.y))
				* (scrollable:getProps().size.y - (SCROLL_BAR_INNER_WIDTH * 2)),
			SCROLL_BAR_INNER_WIDTH
		)
	end

	local function handlePosToScrollPos(y)
		local scrollBarSize = calcScrollBarSize()
		local handleSize = calcHandleSize()

		y = OMWUtil.clamp(y - (handleSize / 2), 0, scrollBarSize.y - handleSize)
		local progress = y / (scrollBarSize.y - handleSize)
		return -progress * scrollable.scrollLimit
	end

	local scrollbar = UIObject.bind({
		template = I.MWUI.templates.borders,
		name = "scrollbar",
		props = {
			size = calcScrollBarSize(),
		},
		content = UI.content({
			{
				type = UI.TYPE.Image,
				name = "handle",
				props = {
					resource = UI.texture({
						path = "textures/omw_menu_scroll_center_v.dds",
					}),
					size = v2(SCROLL_BAR_INNER_WIDTH - 4, calcHandleSize()),
					tileV = true,
					propagateEvents = true,
				},
				events = {
					mousePress = Async:callback(function(e, layout)
						-- ambient.playSound("menu click")
						layout.userData.dragOffset = e.offset.y
						return false
					end),
					mouseRelease = Async:callback(function(_e, layout)
						layout.userData.dragOffset = nil
						return false
					end),
				},
				userData = {
					dragOffset = nil,
				},
			},
		}),
	})

	self._innerScrollbar = scrollbar

	scrollbar:registerEvent("custom_globalMouseWheel", function(steps)
		if not scrollable.focused then
			return
		end

		local scrollArea = scrollable:getScrollArea()
		local scrollAreaProps = scrollArea:getProps()
		scrollAreaProps.position = scrollAreaProps.position + v2(0, scrollable.scrollStep * steps)
		scrollAreaProps.position = v2(0, OMWUtil.clamp(scrollAreaProps.position.y, -scrollable.scrollLimit, 0))

		self:triggerEvent("custom_scrolled")
	end)

	scrollbar:registerEvent("mouseMove", function(e, layout)
		if e.button == 1 then
			local scrollAreaProps = scrollable:getScrollArea():getProps()

			local adjustedY = e.offset.y
				- (layout.content[1].userData.dragOffset or (calcHandleSize() / 2))
				+ (calcHandleSize() / 2)
			scrollAreaProps.position = v2(0, handlePosToScrollPos(adjustedY))
			scrollAreaProps.position = v2(0, OMWUtil.clamp(scrollAreaProps.position.y, -scrollable.scrollLimit, 0))

			self:triggerEvent("custom_scrolled")
		end
	end)

	scrollbar:registerEvent("mousePress", function(e)
		if e.button == 1 then
			-- ambient.playSound("menu click")
			local scrollAreaProps = scrollable:getScrollArea():getProps()

			scrollAreaProps.position = v2(0, handlePosToScrollPos(e.offset.y))
			scrollAreaProps.position = v2(0, OMWUtil.clamp(scrollAreaProps.position.y, -scrollable.scrollLimit, 0))

			self:triggerEvent("custom_scrolled")
		end
	end)

	scrollbarContent:add(scrollbar:getBound())

	return self
end

function Scrollbar:getInnerScrollbar()
	return self._innerScrollbar
end

return Scrollbar
