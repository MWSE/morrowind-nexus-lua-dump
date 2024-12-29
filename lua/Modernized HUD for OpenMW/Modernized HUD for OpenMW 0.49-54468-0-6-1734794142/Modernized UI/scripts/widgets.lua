local ui = require('openmw.ui')
local util = require('openmw.util')
local v2 = util.vector2
local bar = require('scripts.bar')

local targetName = {
	type = ui.TYPE.Text,
	props = {
		text = "",
		textColor = util.color.rgb(1, 1, 1),
		textShadow = true,
		textSize = 14,
		alpha = 1
	}
}

local targetDamage = {
	type = ui.TYPE.Container,
	props = {
		alpha = 1,
		relativePosition = v2(1, 0),
		anchor = v2(1, 0),
		size = v2(100, 15),
		relativeSize = v2(1, 1),
	},
}

local targetBar = deepLayoutCopy(bar)
targetBar.name = "target"

return screen, bars, targetBar, targetName