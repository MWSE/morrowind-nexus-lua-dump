local ui = require('openmw.ui')
local util = require('openmw.util')
local MWUI = require('openmw.interfaces').MWUI
local v2 = util.vector2

local foreground = ui.texture { path = "textures/menu_bar_gray.tga" }
local background = ui.texture { path = "white" }
local segment = ui.texture { path = "textures/segment100.tga" }
local foregroundEdge = ui.texture { path = "textures/foregroundedge.tga", size = v2(2, 1) }
local barWidth = 12

local bar = {
    type = ui.TYPE.Container,
	props = {
		visible = true,
		alpha = 1,
	},
	userData = {
		lerp = 0,
		borderLerp = 0,
		remainder = 0,
		remainderCap = 0,
		timer = 0,
		cache = 0,
		incomingRestoration = 0,

		-- For segments
		history = {},

		-- For damage taken
		statLoss = 0,
		accumulatedLoss = 0,
		lastStat = 0,
		cachedValue = 0,
		damageValueTimer = 0,

		enableFlash = true,
		enableBorderLerp = false,

	},
    content = ui.content {
		{
			name = 'background',
			type = ui.TYPE.Image,
			props = {
				resource = background,
				tileH = true,
				tileV = true,
			},
		},
		{
			name = 'remainder',
			type = ui.TYPE.Image,
			props = {
				resource = foreground,
				position = v2(2, 0),
				tileH = true,
				tileV = true,
				color = util.color.rgb(243/255,237/255,22/255)
			}
		},
		{
			name = 'healing',
			type = ui.TYPE.Image,
			props = {
				resource = foreground,
				position = v2(2, 0),
				tileH = true,
				tileV = true,
				color = util.color.rgb(255/255, 255/255, 255/255),
				alpha = 1
			},
		},
		{
			name = 'foreground',
			type = ui.TYPE.Image,
			props = {
				resource = foreground,
				position = v2(2, 0),
				tileH = true,
				tileV = true,
				color = util.color.rgb(200/255, 60/255, 30/255)
			},
		},
		{
			name = "edge",
			type = ui.TYPE.Image,
			props = {
				resource = foregroundEdge,
				position = v2(2, 0),
				size = v2(2, barWidth),
				tileH = true,
				tileV = true,
				alpha = 0.5
			},
		},
		{
			name = 'value',
			type = ui.TYPE.Text,
			props = {
				text = "",
				textColor = util.color.rgba(1, 1, 1, 0.5),
				position = v2(2.5, 6),
				textShadow = true,
				anchor = v2(0, 0.5),
				relativePosition = v2(0, 0.5),
			}
		},
		{
			name = 'border',
			template = MWUI.templates.borders,
			props = {
			},
		},
		{	
			name = 'segment50',
			type = ui.TYPE.Image,
			props = {
				resource = segment,
				position = v2(4, 0),
				tileH = true,
				tileV = true,
			},
		},
		{	
			name = 'segment100',
			type = ui.TYPE.Image,
			props = {
				resource = segment,
				position = v2(4, 0),
				tileH = true,
				tileV = true,
			},
		},
	},
}

return bar