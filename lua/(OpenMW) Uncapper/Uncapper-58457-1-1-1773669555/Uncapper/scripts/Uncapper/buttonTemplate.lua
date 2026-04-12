local ui = require('openmw.ui')
local util = require('openmw.util')

local v2 = util.vector2

-- border texture coordinates
local sideParts = {
	left = v2(0, 0),
	right = v2(1, 0),
	top = v2(0, 0),
	bottom = v2(0, 1)
}
local cornerParts = {
	top_left = v2(0, 0),
	top_right = v2(1, 0),
	bottom_left = v2(0, 1),
	bottom_right = v2(1, 1)
}

-- texture paths
local borderSidePattern = 'textures/menu_button_frame_%s.dds'
local borderCornerPattern = 'textures/menu_button_frame_%s_corner.dds'

-- load border resources
local borderResources = {}
for k in pairs(sideParts) do
	borderResources[k] = ui.texture { path = borderSidePattern:format(k) }
end
for k in pairs(cornerParts) do
	borderResources[k] = ui.texture { path = borderCornerPattern:format(k) }
end

-- border piece templates
local borderPieces = {}
for k in pairs(sideParts) do
	local horizontal = k == 'top' or k == 'bottom'
	borderPieces[k] = {
		type = ui.TYPE.Image,
		props = {
			resource = borderResources[k],
			tileH = horizontal,
			tileV = not horizontal
		}
	}
end
for k in pairs(cornerParts) do
	borderPieces[k] = {
		type = ui.TYPE.Image,
		props = {
			resource = borderResources[k]
		}
	}
end

-- box button template
local borderSize = 4
local borderV = v2(1, 1) * borderSize

local boxButton = {
	type = ui.TYPE.Container,
	content = ui.content {}
}
-- side borders
for k, v in pairs(sideParts) do
	local horizontal = k == 'top' or k == 'bottom'
	local direction = horizontal and v2(1, 0) or v2(0, 1)
	boxButton.content:add {
		template = borderPieces[k],
		props = {
			position = (direction + v) * borderSize,
			relativePosition = v,
			size = (v2(1, 1) - direction) * borderSize,
			relativeSize = direction
		}
	}
end
-- corner borders
for k, v in pairs(cornerParts) do
	boxButton.content:add {
		template = borderPieces[k],
		props = {
			position = v * borderSize,
			relativePosition = v,
			size = borderV
		}
	}
end
-- content slot
boxButton.content:add {
	external = { slot = true },
	props = {
		position = borderV,
		relativeSize = v2(1, 1)
	}
}

return boxButton