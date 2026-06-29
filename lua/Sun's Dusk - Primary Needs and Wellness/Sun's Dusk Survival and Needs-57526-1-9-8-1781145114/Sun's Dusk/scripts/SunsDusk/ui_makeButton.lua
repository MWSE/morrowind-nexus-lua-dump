-- button factory - uncapper-style menu_button_frame border, highlight on the label text
-- makeButton(label, props, func, ...) is the legacy positional wrapper; new code uses makeButton.create{ ... }
-- injected globals used: ui, util, core, async, v2, math, getTexture, getColorFromGameSettings, darkenColor, G_onFrameJobs
local makeBorder = require("scripts.SunsDusk.ui_makeBorder")

-- write an rgba colour onto an image as separate color + alpha props
local function setColorAlpha(props, color)
	props.color = util.color.rgb(color.r, color.g, color.b)
	props.alpha = color.a or 1
end

-- shallow merge of a config table over the defaults (config wins)
local function applyDefaults(config, defaults)
	local result = {}
	for k, v in pairs(defaults) do
		result[k] = v
	end
	if config then
		for k, v in pairs(config) do
			result[k] = v
		end
	end
	return result
end

------------------------------ defaults ------------------------------
-- override any of these per button via the config table
local defaults = {
	textSize = 24,
	clickDelay = 0.4,
	iconGap = 34,
	iconAlpha = 0.9,
	textShadow = true,
	textShadowColor = util.color.rgb(0, 0, 0),
	-- text colour per state
	textNormal = getColorFromGameSettings("fontColor_color_normal"),
	textHover = getColorFromGameSettings("fontColor_color_normal_over"),
	textPressed = getColorFromGameSettings("FontColor_color_normal_pressed"),
	-- background plate per state, rgba with alpha baked in
	bgNormal = util.color.rgba(0, 0, 0, 0.1),
	bgHover = util.color.rgba(0.45, 0.38, 0.22, 0.1),
	bgPressed = util.color.rgba(0.55, 0.46, 0.28, 0.2),
	-- button frame border
	frameSize = 4,
	frameTexture = 'menu_button_frame',
	-- icon border
	iconBorderFile = 'thin',
	iconBorderColor = util.color.rgb(0.5, 0.5, 0.5),
	iconBorderSize = 1,
	iconBorderAlpha = 0.5,
}

------------------------------ button frame ------------------------------
local sideParts = {
	left = v2(0, 0),
	right = v2(1, 0),
	top = v2(0, 0),
	bottom = v2(0, 1),
}
local cornerParts = {
	top_left = v2(0, 0),
	top_right = v2(1, 0),
	bottom_left = v2(0, 1),
	bottom_right = v2(1, 1),
}

-- vanilla menu button frame, assembled per texture + size and cached so identical frames are shared
local frameCache = {}
local function getFrame(texture, frameSize)
	local key = texture .. ':' .. frameSize
	if frameCache[key] then return frameCache[key] end
	local frameV = v2(1, 1) * frameSize
	local sidePattern = 'textures/' .. texture .. '_%s.dds'
	local cornerPattern = 'textures/' .. texture .. '_%s_corner.dds'
	local pieces = {}
	for k in pairs(sideParts) do
		local horizontal = k == 'top' or k == 'bottom'
		pieces[k] = {
			type = ui.TYPE.Image,
			props = {
				resource = getTexture(sidePattern:format(k)),
				tileH = horizontal,
				tileV = not horizontal,
			},
		}
	end
	for k in pairs(cornerParts) do
		pieces[k] = {
			type = ui.TYPE.Image,
			props = {
				resource = getTexture(cornerPattern:format(k)),
			},
		}
	end
	-- frame template overlays the widget edges and leaves an inset content slot
	local frame = { content = ui.content {} }
	for k, v in pairs(sideParts) do
		local horizontal = k == 'top' or k == 'bottom'
		local direction = horizontal and v2(1, 0) or v2(0, 1)
		frame.content:add{
			template = pieces[k],
			props = {
				position = (direction - v) * frameSize,
				relativePosition = v,
				size = (v2(1, 1) - direction * 3) * frameSize,
				relativeSize = direction,
			},
		}
	end
	for k, v in pairs(cornerParts) do
		frame.content:add{
			template = pieces[k],
			props = {
				position = -v * frameSize,
				relativePosition = v,
				size = frameV,
			},
		}
	end
	frame.content:add{
		external = { slot = true },
		props = {
			position = frameV,
			size = frameV * -2,
			relativeSize = v2(1, 1),
		},
	}
	frameCache[key] = frame
	return frame
end

------------------------------ icon border ------------------------------
-- thin frame around an optional icon, built via makeBorder and cached per file + colour + size + alpha
local iconBorderCache = {}
local function getIconBorder(file, color, size, alpha)
	local key = file .. ':' .. color:asHex() .. ':' .. size .. ':' .. alpha
	if iconBorderCache[key] then return iconBorderCache[key] end
	local border = makeBorder(file, color, size, {
		type = ui.TYPE.Image,
		props = {
			relativeSize = v2(1, 1),
			alpha = alpha,
		}
	}).borders
	iconBorderCache[key] = border
	return border
end

------------------------------ tooltip ------------------------------
-- dark bordered container shown next to the cursor when a button has tooltip content
local tooltipTemplate = makeBorder("thin", util.color.rgb(0.5, 0.5, 0.5), 1, {
	type = ui.TYPE.Image,
	props = {
		resource = ui.texture{ path = 'black' },
		relativeSize = v2(1, 1),
		alpha = 0.93,
	}
}).borders

local function makeTooltip(content)
	return ui.create{
		name = 'buttonTooltip',
		type = ui.TYPE.Container,
		layer = 'Notification',
		template = tooltipTemplate,
		props = {},
		content = ui.content { content },
	}
end

------------------------------ factory ------------------------------
-- config (all optional): label, props, onClick, highlightColor, icon, iconTint, hoverIcon,
-- pressedIcon, tooltip, selected, name, layer, onFocus, onBlur, onPress + any defaults key above
-- returns a handle: box, clickbox, image, applyColor + setSelected/setHighlight/setLabel/setIcon/setIconTint/refresh/destroy
local function makeButtonEx(config)
	local cfg = applyDefaults(config, defaults)
	local label = cfg.label
	local props = cfg.props or {}
	local onClick = cfg.onClick
	local highlightColor = cfg.highlightColor or cfg.textNormal
	local iconResource = cfg.icon
	local hoverIcon = cfg.hoverIcon
	local pressedIcon = cfg.pressedIcon
	local tooltipContent = cfg.tooltip
	local clickDelay = cfg.clickDelay
	local creationTime = core.getRealTime()
	local jobKey = "" .. math.random()

	local box = ui.create{
		name = cfg.name or jobKey,
		layer = cfg.layer,
		type = ui.TYPE.Widget,
		props = props,
		content = ui.content {}
	}

	-- background plate
	local buttonBackground = {
		name = 'background',
		type = ui.TYPE.Image,
		props = {
			relativeSize = v2(1, 1),
			resource = getTexture('white'),
		},
	}
	setColorAlpha(buttonBackground.props, cfg.bgNormal)
	box.layout.content:add(buttonBackground)

	-- button frame
	box.layout.content:add{
		name = 'frame',
		template = getFrame(cfg.frameTexture, cfg.frameSize),
		props = {
			relativeSize = v2(1, 1),
		},
	}

	-- optional icon
	local image
	if iconResource then
		local iconSize = (props.size and props.size.y) or 24
		local iconWithBorder = {
			name = 'icon',
			type = ui.TYPE.Widget,
			props = {
				size = v2(iconSize, iconSize),
			},
			content = ui.content {}
		}
		-- icon backing, only when paired with a label
		if label then
			iconWithBorder.content:add{
				name = 'iconBackground',
				type = ui.TYPE.Image,
				props = {
					relativeSize = v2(1, 1),
					resource = getTexture('white'),
					color = darkenColor(cfg.textNormal, 0.1),
					alpha = 0.8,
				},
			}
		end
		-- icon glyph
		image = {
			type = ui.TYPE.Image,
			template = getIconBorder(cfg.iconBorderFile, cfg.iconBorderColor, cfg.iconBorderSize, cfg.iconBorderAlpha),
			props = {
				resource = iconResource,
				color = cfg.iconTint,
				relativeSize = v2(1, 1),
				relativePosition = v2(0.5, 0.5),
				anchor = v2(0.5, 0.5),
				alpha = cfg.iconAlpha,
				size = v2(-2, -2),
			}
		}
		iconWithBorder.content:add(image)
		box.layout.content:add(iconWithBorder)
	end

	-- optional label
	local text
	if label then
		text = {
			name = 'text',
			type = ui.TYPE.Text,
			props = {
				relativePosition = iconResource and v2(0, 0.5) or v2(0.5, 0.5),
				anchor = iconResource and v2(0, 0.5) or v2(0.5, 0.5),
				position = iconResource and v2(cfg.iconGap, 0) or v2(0, 0),
				text = tostring(label),
				textColor = cfg.textNormal,
				textShadow = cfg.textShadow,
				textShadowColor = cfg.textShadowColor,
				textSize = cfg.textSize,
				textAlignH = iconResource and ui.ALIGNMENT.Start or ui.ALIGNMENT.Center,
				textAlignV = ui.ALIGNMENT.Center,
			},
		}
		box.layout.content:add(text)
	end

	-- click target and interaction state
	local clickbox = {
		name = 'clickbox',
		props = {
			relativeSize = v2(1, 1),
		},
		userData = {
			focus = false,
			pressed = false,
			selected = cfg.selected or false,
			highlightAlpha = 0,
		},
	}

	local previousResource
	local previousColor
	local function applyColor(elem)
		elem = elem or clickbox
		local ud = elem.userData

		-- pick text + plate colour for the current state (selected reads as hover)
		local tcol, bcol
		if ud.pressed then
			tcol, bcol = cfg.textPressed, cfg.bgPressed
		elseif ud.focus or ud.selected then
			tcol, bcol = cfg.textHover, cfg.bgHover
		elseif ud.highlightAlpha and ud.highlightAlpha > 0 then
			tcol = cfg.textNormal
			bcol = util.color.rgba(highlightColor.r, highlightColor.g, highlightColor.b, ud.highlightAlpha)
		else
			tcol, bcol = cfg.textNormal, cfg.bgNormal
		end
		if text then text.props.textColor = tcol end
		setColorAlpha(buttonBackground.props, bcol)

		-- icon swap and tint, preserving externally set resource / colour
		if image then
			if ud.pressed and pressedIcon then
				if not previousResource then previousResource = image.props.resource end
				image.props.resource = pressedIcon
			elseif ud.focus and hoverIcon then
				if not previousResource then previousResource = image.props.resource end
				image.props.resource = hoverIcon
			elseif previousResource then
				image.props.resource = previousResource
				previousResource = nil
			end
			-- a tinted icon follows the text colour, full-colour art is left untouched
			if image.props.color or previousColor then
				if ud.pressed then
					if not previousColor then previousColor = image.props.color end
					image.props.color = cfg.textPressed
				elseif ud.focus or ud.selected then
					if not previousColor then previousColor = image.props.color end
					image.props.color = cfg.textHover
				elseif previousColor then
					image.props.color = previousColor
					previousColor = nil
				end
			end
		end

		box:update()
	end
	clickbox.userData.applyColor = applyColor

	-- tooltip, created lazily on hover
	local tooltip
	local function showTooltip()
		if tooltipContent and not tooltip then tooltip = makeTooltip(tooltipContent) end
	end
	local function hideTooltip()
		if tooltip then tooltip:destroy(); tooltip = nil end
	end

	clickbox.events = {
		mouseRelease = async:callback(function(_, elem)
			elem.userData.pressed = false
			G_onFrameJobs[jobKey] = function()
				if elem.userData.focus and core.getRealTime() > creationTime + clickDelay then
					if onClick then onClick(elem) end
				end
				applyColor(elem)
				G_onFrameJobs[jobKey] = nil
			end
		end),
		focusGain = async:callback(function(_, elem)
			elem.userData.focus = true
			applyColor(elem)
			showTooltip()
			if cfg.onFocus then cfg.onFocus(elem) end
		end),
		focusLoss = async:callback(function(_, elem)
			elem.userData.focus = false
			elem.userData.pressed = false
			applyColor(elem)
			hideTooltip()
			if cfg.onBlur then cfg.onBlur(elem) end
		end),
		mousePress = async:callback(function(_, elem)
			elem.userData.focus = true
			elem.userData.pressed = true
			applyColor(elem)
			if cfg.onPress then cfg.onPress(elem) end
		end),
	}
	if tooltipContent then
		clickbox.events.mouseMove = async:callback(function(data, elem)
			showTooltip()
			if tooltip then
				tooltip.layout.props.position = v2(data.position.x + 13, data.position.y + 25)
				tooltip:update()
			end
		end)
	end
	box.layout.content:add(clickbox)

	-- handle: legacy fields plus convenience methods
	local handle = {
		box = box,
		clickbox = clickbox,
		image = image,
		applyColor = applyColor,
	}
	function handle:setSelected(value)
		clickbox.userData.selected = value and true or false
		applyColor(clickbox)
	end
	function handle:setHighlight(alpha)
		clickbox.userData.highlightAlpha = alpha or 0
		applyColor(clickbox)
	end
	function handle:setLabel(str)
		if not text then return end
		text.props.text = tostring(str)
		box:update()
	end
	function handle:setIcon(resource)
		if not image then return end
		previousResource = nil
		image.props.resource = resource
		box:update()
	end
	function handle:setIconTint(color)
		if not image then return end
		previousColor = nil
		image.props.color = color
		applyColor(clickbox)
	end
	function handle:refresh()
		applyColor(clickbox)
	end
	function handle:destroy()
		hideTooltip()
		G_onFrameJobs[jobKey] = nil
		box:destroy()
	end

	if cfg.selected then applyColor(clickbox) end
	return handle
end

------------------------------ legacy wrapper ------------------------------
-- positional makeButton(label, props, func, highlightColor, parent, iconResource, hoverResource, pressedResource)
local function makeButton(label, props, func, highlightColor, parent, iconResource, hoverResource, pressedResource)
	return makeButtonEx{
		label = label,
		props = props,
		onClick = func,
		highlightColor = highlightColor,
		icon = iconResource,
		hoverIcon = hoverResource,
		pressedIcon = pressedResource,
	}
end

-- callable for legacy makeButton(...), .create exposes the config-table factory
return setmetatable({ create = makeButtonEx }, {
	__call = function(_, ...)
		return makeButton(...)
	end,
})
