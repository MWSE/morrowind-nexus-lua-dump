local ui = require('openmw.ui')
local util = require('openmw.util')
local self = require('openmw.self')
local Actor = require('openmw.types').Actor
local time = require('openmw_aux.time')
local MWUI = require('openmw.interfaces').MWUI
local helpers = require('scripts.helpers')

local cornerMargin = 36
local hOffset, vOffset  = -45, -21
local white = ui.texture { path = 'white' }
local gold = ui.texture { path = 'icons/m/Tx_Gold_001.tga' }

local widget = {
	type = ui.TYPE.Widget,
	props = {
		alpha = 1,
		size = util.vector2(40, 16),
	},
	content = ui.content { 
		{	-- Gold
			name = 'text',
			type = ui.TYPE.Text,
			props = {
				text = "",
				textSize = 10,
				textColor = util.color.rgba(1, 1, 1, 0.8),
				anchor = util.vector2(1, 0.5),
				relativePosition = util.vector2(1, 0.5),
                position = util.vector2(-13, 0.5),
				inheritAlpha = false,
                textShadow = true,
			},
		},
        {
            type = ui.TYPE.Image,
            props = {
                resource = gold,
                size = util.vector2(10, 10),
                anchor = util.vector2(1, 0.5),
                relativePosition = util.vector2(1, 0.5),
                position = util.vector2(-2, -1),
            }
        },
	}
}

local wrapper = ui.create {
	layer = 'HUD',
	type = ui.TYPE.Container,
    template = MWUI.templates.boxSolid,
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
	local gold = Actor.inventory(self):countOf("Gold_001")
	widget.content['text'].props.text = tostring(abbreviateNumber(gold))
	wrapper:update()
end

time.runRepeatedly(updateTime, 1 * time.minute, { type = time.GameTime })