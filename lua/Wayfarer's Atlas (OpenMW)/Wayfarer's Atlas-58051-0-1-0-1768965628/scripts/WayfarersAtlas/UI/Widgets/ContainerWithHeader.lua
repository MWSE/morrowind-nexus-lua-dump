local UI = require("openmw.ui")
local I = require("openmw.interfaces")
local OMWUtil = require("openmw.util")
local MWUIConstants = require("scripts.omw.mwui.constants")
local Async = require("openmw.async")

local UIObject = require("scripts/WayfarersAtlas/UI/UIObject")
local SharedUI = require("scripts/WayfarersAtlas/UI/SharedUI")

local v2 = OMWUtil.vector2

local HEADER_TEXTURES = {
	[1] = UI.texture({ path = "textures/menu_head_block_top_left_corner.dds" }),
	[2] = UI.texture({ path = "textures/menu_head_block_top.dds" }),
	[3] = UI.texture({ path = "textures/menu_head_block_top_right_corner.dds" }),
	[4] = UI.texture({ path = "textures/menu_head_block_left.dds" }),
	[5] = UI.texture({ path = "textures/menu_head_block_middle.dds" }),
	[6] = UI.texture({ path = "textures/menu_head_block_right.dds" }),
	[7] = UI.texture({ path = "textures/menu_head_block_bottom_left_corner.dds" }),
	[8] = UI.texture({ path = "textures/menu_head_block_bottom.dds" }),
	[9] = UI.texture({ path = "textures/menu_head_block_bottom_right_corner.dds" }),
}

local POINTER_TEXTURES = {
	["left"] = "hresize",
	["right"] = "hresize",
	["top"] = "vresize",
	["bottom"] = "vresize",
	["top_left"] = "dresize",
	["top_right"] = "dresize2",
	["bottom_left"] = "dresize2",
	["bottom_right"] = "dresize",
}

local SIDE_PARTS = {
	left = v2(0, 0),
	right = v2(1, 0),
	top = v2(0, 0),
	bottom = v2(0, 1),
}

local CORNER_PARTS = {
	top_left = v2(0, 0),
	top_right = v2(1, 0),
	bottom_left = v2(0, 1),
	bottom_right = v2(1, 1),
}

local DRAG_TYPE = {
	["left"] = SharedUI.DragType.ResizeL,
	["right"] = SharedUI.DragType.ResizeR,
	["top"] = SharedUI.DragType.ResizeT,
	["bottom"] = SharedUI.DragType.ResizeB,
	["top_left"] = SharedUI.DragType.ResizeTL,
	["top_right"] = SharedUI.DragType.ResizeTR,
	["bottom_left"] = SharedUI.DragType.ResizeBL,
	["bottom_right"] = SharedUI.DragType.ResizeBR,
}

local BORDER_SIDE_PATTERN = "textures/menu_thick_border_%s.dds"
local BORDER_CORNER_PATTERN = "textures/menu_thick_border_%s_corner.dds"

local BORDER_RESOURCES = {}
local BORDER_PIECES = {}
do
	for k in pairs(SIDE_PARTS) do
		BORDER_RESOURCES[k] = UI.texture({ path = BORDER_SIDE_PATTERN:format(k) })
	end
	for k in pairs(CORNER_PARTS) do
		BORDER_RESOURCES[k] = UI.texture({ path = BORDER_CORNER_PATTERN:format(k) })
	end

	for k in pairs(SIDE_PARTS) do
		local horizontal = k == "top" or k == "bottom"
		BORDER_PIECES[k] = {
			type = UI.TYPE.Image,
			props = {
				resource = BORDER_RESOURCES[k],
				tileH = horizontal,
				tileV = not horizontal,
			},
		}
	end

	for k in pairs(CORNER_PARTS) do
		BORDER_PIECES[k] = {
			type = UI.TYPE.Image,
			props = {
				resource = BORDER_RESOURCES[k],
			},
		}
	end
end

local function newBorderPointers(onDragChanged)
	local borderPointers = { content = UI.content({}) }

	local borderSize = MWUIConstants.thickBorder
	local borderV = v2(1, 1) * borderSize

	local currentDragType = nil
	local events = {
		focusGain = Async:callback(function(_, layout)
			if layout.dragType ~= currentDragType then
				currentDragType = layout.dragType
				onDragChanged(layout.dragType)
			end
		end),
		focusLoss = Async:callback(function(_, layout)
			if layout.dragType == currentDragType then
				currentDragType = nil
				onDragChanged(nil)
			end
		end),
	}

	for k, v in pairs(SIDE_PARTS) do
		local horizontal = k == "top" or k == "bottom"
		local direction = horizontal and v2(1, 0) or v2(0, 1)

		borderPointers.content:add({
			template = BORDER_PIECES[k],
			props = {
				position = (direction - v) * borderSize,
				relativePosition = v,
				size = (v2(1, 1) - direction * 3) * borderSize,
				relativeSize = direction,
				pointer = POINTER_TEXTURES[k],
			},
			events = events,
			dragType = DRAG_TYPE[k],
		})
	end

	for k, v in pairs(CORNER_PARTS) do
		borderPointers.content:add({
			template = BORDER_PIECES[k],
			props = {
				position = -v * borderSize,
				relativePosition = v,
				size = borderV,
			},
		})

		-- Add larger corners for mouse detection.
		-- Make sure they are ordered before the content.
		-- The content should obscure them and turn them into L shapes instead of squares.
		borderPointers.content:add({
			-- type = UI.TYPE.Image,
			props = {
				-- resource = UI.texture({ path = "white" }),
				position = -v * 16,
				relativePosition = v,
				size = v2(16, 16),
				pointer = POINTER_TEXTURES[k],
			},
			events = events,
			dragType = DRAG_TYPE[k],
		})
	end

	borderPointers.content:add({
		external = { slot = true },
		props = {
			position = borderV,
			size = borderV * -2,
			relativeSize = v2(1, 1),
		},
	})

	return borderPointers
end

local function headerImage(i, tile, size)
	return {
		type = UI.TYPE.Image,
		props = {
			resource = HEADER_TEXTURES[i],
			size = size or v2(0, 0),
			tileH = tile,
			tileV = false,
		},
		external = {
			grow = 1,
			stretch = 1,
		},
	}
end

local HEADER_SECTION = {
	type = UI.TYPE.Flex,
	props = {
		horizontal = true,
	},
	external = {
		grow = 1,
		stretch = 1,
	},
	content = UI.content({
		{
			type = UI.TYPE.Flex,
			props = {
				autoSize = false,
				size = v2(2, 20),
			},
			content = UI.content({
				headerImage(1, false, v2(2, 2)),
				headerImage(4, false, v2(2, 16)),
				headerImage(7, false, v2(2, 2)),
			}),
		},
		{
			type = UI.TYPE.Flex,
			props = {
				autoSize = false,
				size = v2(0, 20),
			},
			content = UI.content({
				headerImage(2, true, v2(0, 2)),
				headerImage(5, true, v2(0, 16)),
				headerImage(8, true, v2(0, 2)),
			}),
			external = {
				grow = 1,
				stretch = 1,
			},
		},
		{
			type = UI.TYPE.Flex,
			props = {
				autoSize = false,
				size = v2(2, 20),
			},
			content = UI.content({
				headerImage(3, false, v2(2, 2)),
				headerImage(6, false, v2(2, 16)),
				headerImage(9, false, v2(2, 2)),
			}),
		},
	}),
}

---@class WAY.ContainerWithHeader: WAY.UIObject
local ContainerWithHeader = UIObject:extend("ContainerWithHeader")

---@param onDragChanged fun(dragType)
function ContainerWithHeader.new(onDragChanged)
	local containerContent = UI.content({})
	local titleLayout = {
		name = "title",
		template = I.MWUI.templates.textNormal,
		props = {
			text = "",
		},
	}

	---@class WAY.ContainerWithHeader
	local self = ContainerWithHeader.bind({
		template = newBorderPointers(onDragChanged),

		props = {
			relativeSize = v2(1, 1),
		},
		content = UI.content({
			{
				name = "background",
				type = UI.TYPE.Image,
				props = {
					resource = UI.texture({ path = "black" }),
					relativeSize = v2(1, 1),
					alpha = UI._getMenuTransparency(),
				},
			},
			{
				name = "foreground",
				type = UI.TYPE.Flex,
				props = {
					relativeSize = v2(1, 1),
				},
				content = UI.content({
					{
						name = "header",
						type = UI.TYPE.Flex,
						props = {
							horizontal = true,
						},
						events = {
							mousePress = Async:callback(function(e)
								if e.button == SharedUI.MouseButton.Left then
									onDragChanged(SharedUI.DragType.Move)
									return true
								end
							end),
							mouseRelease = Async:callback(function(e)
								if e.button == SharedUI.MouseButton.Left then
									onDragChanged(nil)
									return true
								end
							end),
						},
						external = {
							stretch = 1,
						},
						content = UI.content({
							HEADER_SECTION,
							SharedUI.intervalH(8),
							titleLayout,
							SharedUI.intervalH(8),
							HEADER_SECTION,
						}),
					},
					{
						name = "body",
						template = I.MWUI.templates.bordersThick,
						external = {
							grow = 1,
							stretch = 1,
						},
						content = containerContent,
					},
				}),
			},
		}),
	})

	self._containerContent = containerContent
	self._titleLayout = titleLayout

	return self
end

function ContainerWithHeader:setTitle(title)
	self._titleLayout.props.text = title
end

function ContainerWithHeader:getContainerContent()
	return self._containerContent
end

return ContainerWithHeader
