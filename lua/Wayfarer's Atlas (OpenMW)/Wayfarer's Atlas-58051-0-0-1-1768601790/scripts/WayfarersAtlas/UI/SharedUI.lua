local I = require("openmw.interfaces")
local UI = require("openmw.ui")
local OMWUtil = require("openmw.util")
local v2 = OMWUtil.vector2

local MouseButton = {
	Left = 1,
	Right = 3,
	None = nil,
}

local SharedUI = {}

SharedUI.MouseButton = MouseButton

---@param props {uiObject: WAY.UIObject, startClickPos: userdata?, onScroll: function, onScrollFinished: function}
function SharedUI.scrollableXY(props)
	local clickMousePos = props.startClickPos or v2(0, 0)
	local scrolling = not not props.startClickPos
	local disconnectFns = {}

	table.insert(
		disconnectFns,
		props.uiObject:connectEvent("mousePress", function(e)
			if e.button == MouseButton.Left then
				clickMousePos = e.position
				scrolling = true
			end
		end)
	)

	table.insert(
		disconnectFns,
		props.uiObject:connectEvent("mouseMove", function(e)
			if scrolling and e.button == MouseButton.Left then
				local offset = e.position - clickMousePos
				props.onScroll(offset)
			end
		end)
	)

	table.insert(
		disconnectFns,
		props.uiObject:connectEvent("mouseRelease", function(e)
			if scrolling and e.button == MouseButton.Left then
				scrolling = false
				local offset = e.position - clickMousePos
				props.onScroll(offset)
				props.onScrollFinished()
			end
		end)
	)

	return function()
		if scrolling then
			scrolling = false
			props.onScrollFinished()
		end

		for _, fn in pairs(disconnectFns) do
			fn()
		end
	end
end

function SharedUI.intervalH(size)
	return {
		props = {
			size = v2(size, 0),
		},
	}
end

function SharedUI.intervalV(size)
	return {
		props = {
			size = v2(0, size),
		},
	}
end

function SharedUI.padding(padding, layout)
	return {
		props = {
			position = v2(padding, padding),
			size = v2(-padding * 2, -padding * 2),
			relativeSize = v2(1, 1),
		},
		content = UI.content({ layout }),
	}
end

function SharedUI.paddedBox(layout)
	return {
		template = I.MWUI.templates.box,
		content = UI.content({
			{
				template = I.MWUI.templates.padding,
				content = UI.content({ layout }),
			},
		}),
	}
end

function SharedUI.paddingTemplate(size)
	local sizev2 = v2(size, size)

	return {
		type = UI.TYPE.Container,
		content = UI.content({
			{
				props = {
					size = sizev2,
				},
			},
			{
				external = { slot = true },
				props = {
					position = sizev2,
					relativeSize = v2(1, 1),
				},
			},
			{
				props = {
					position = sizev2,
					relativePosition = v2(1, 1),
					size = sizev2,
				},
			},
		}),
	}
end

return SharedUI
