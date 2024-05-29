--[[
    Mod: Perfect Placement OpenMW
    Author: Hrnchamd
    Version: 2.2beta
]]--

local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')

local l10n = core.l10n('PerfectPlacement')

-- Key guide window

local flexSpacer = {
	props = { size = util.vector2(16, 0) },
}
local textSpacer = {
	props = { size = util.vector2(0, 16) },
}

local function makeLabel()
	return { template = I.MWUI.templates.textNormal, props = {} }
end

local labelsLayout = {
	name = 'LabelColumn',
	type = ui.TYPE.Flex,
	props = { autoSize = true, size = util.vector2(250, 0) },
	--external = { grow = 0.75 },
	content = ui.content {
		makeLabel(), textSpacer,
		makeLabel(), textSpacer,
		makeLabel(), textSpacer,
		makeLabel(), textSpacer,
		makeLabel(), textSpacer,
		makeLabel(), textSpacer,
		makeLabel(), textSpacer,
	}
}

local bindingsLayout = {
	name = 'BindingColumn',
	type = ui.TYPE.Flex,
	--external = { grow = 0.25 },
	props = { autoSize = true, size = util.vector2(100, 0), arrange = ui.ALIGNMENT.End },
	content = ui.content {
		makeLabel(), textSpacer,
		makeLabel(), textSpacer,
		makeLabel(), textSpacer,
		makeLabel(), textSpacer,
		makeLabel(), textSpacer,
		makeLabel(), textSpacer,
		makeLabel(), textSpacer,
	}
}

local controlsGuideLayout = {
	layer = 'HUD',
	name = 'PlacementControlsGuide',
    type = ui.TYPE.Container,
    props = {
        relativePosition = util.vector2(0.02, 0.04),
	},
	content = ui.content {
		{
			type = ui.TYPE.Image,
			props = {
				relativeSize = util.vector2(1, 1),
				size = util.vector2(395, 235),
				resource = ui.texture { path = 'white' },
				color = util.color.rgb(0, 0, 0),
				alpha = 0.8,
			},
		},
		{
			name = 'Table',
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
				position = util.vector2(0, 12),
			},
			content = ui.content {
				flexSpacer,
				labelsLayout,
				bindingsLayout,
				flexSpacer,
			},
		},
	},
}


local menu

local function hideGuide()
	if menu then
		menu:destroy()
		menu = nil
	end
end

local function setLine(n, label, verb, binding)
	local i = 2 * n - 1
	labelsLayout.content[i].props.text = label
	bindingsLayout.content[i].props.text = verb .. input.getKeyName(binding)
end

local function showGuide(config)
	if not menu then
		menu = ui.create(controlsGuideLayout)
	end
	
    setLine(1, l10n('RotateItem'), l10n('HoldPrefix'), config.keybindRotate)
    setLine(2, l10n('VerticalMode'), '', config.keybindVertical)
    setLine(3, l10n('MatchLast'), l10n('HoldPrefix'), config.keybindVertical)
    setLine(4, l10n('OrientToSurface'), '', config.keybindSurfaceAlign)
    setLine(5, l10n('SnapRotation'), '', config.keybindSnap)
    setLine(6, l10n('DropItem'), '', config.keybindPlace)
    setLine(7, l10n('HangItem'), input.getKeyName(config.keybindRotate) .. ' + ', config.keybindPlace)

	menu:update()
end

return {
	hideGuide = hideGuide,
	showGuide = showGuide,
}