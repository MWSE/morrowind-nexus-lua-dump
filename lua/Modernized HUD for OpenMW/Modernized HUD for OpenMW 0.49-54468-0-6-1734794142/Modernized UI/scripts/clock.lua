local ui = require('openmw.ui')
local util = require('openmw.util')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')
local MWUI = require('openmw.interfaces').MWUI

local cornerMargin = 36
local hOffset, vOffset  = -45, 1
local white = ui.texture { path = 'white' }

local widget = {
	type = ui.TYPE.Image,
	props = {
		alpha = 1,
		size = util.vector2(40, 16),
	},
	content = ui.content { 
		{	-- The 24 hour clock
			name = 'text',
			type = ui.TYPE.Text,
			props = {
				text = calendar.formatGameTime('%H:%M'),
				textSize = 12,
				textColor = util.color.rgba(1, 1, 1, 0.8),
				anchor = util.vector2(0.5, 0.5),
				relativePosition = util.vector2(0.5, 0.5),
				inheritAlpha = false,
				textShadow = true,
				position = util.vector2(0, 0),
			},
		},
	}
}

local wrapper = ui.create {
	layer = 'HUD',
	type = ui.TYPE.Container,
	template = MWUI.templates.boxTransparent,
	props = {
		relativePosition = util.vector2(1, 1),
		anchor = util.vector2(1, 1),
		position = util.vector2(-cornerMargin + hOffset, -cornerMargin + vOffset),
	},
	content = ui.content {
		{
			template = widget
		}
	}
}

local function updateTime()
	widget.content['text'].props.text = calendar.formatGameTime('%H:%M')
	wrapper:update()
end

time.runRepeatedly(updateTime, 1 * time.minute, { type = time.GameTime })
