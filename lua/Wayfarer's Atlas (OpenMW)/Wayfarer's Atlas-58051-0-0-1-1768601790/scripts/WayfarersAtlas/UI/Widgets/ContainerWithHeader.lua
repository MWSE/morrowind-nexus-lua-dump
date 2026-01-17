local UI = require("openmw.ui")
local I = require("openmw.interfaces")
local OMWUtil = require("openmw.util")

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

function ContainerWithHeader.new()
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
		template = I.MWUI.templates.bordersThick,
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
