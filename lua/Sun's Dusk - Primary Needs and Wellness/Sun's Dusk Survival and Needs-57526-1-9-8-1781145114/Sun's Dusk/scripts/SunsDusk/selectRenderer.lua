local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local menu = require('openmw.menu')
local I = require('openmw.interfaces')
local v2 = util.vector2

-- example:
-- {
-- 	key = "MODE",
-- 	name = "Mode",
-- 	description = "Pick a mode",
-- 	renderer = "SuperSelect2",
-- 	default = "Normal",
-- 	argument = {
-- 		items = { "Slow", "Normal", "Fast" }, -- required: non-empty array
-- 		width = 150,                          -- default: 150, total row width in px
-- 		l10n = nil,                           -- optional: l10n context, items become translation keys
-- 		disabled = false,                     -- default: false
-- 		textSize = nil,                       -- optional: font size + row height (default: textNormal size)
-- 		icon = nil,                           -- optional table { [item] = "textures/path.dds" }
-- 		iconColor = nil,                      -- optional table { [item] = util.color.rgb(...) }, defaults to white
-- 		iconSize = nil,                       -- optional, defaults to ~1.3 * textSize
-- 		buttons = nil,                        -- optional array of extra buttons, see "extra buttons" below
-- 	},
-- },
--
-- each extra button (argument is serialized to storage, so no functions allowed):
-- {
-- 	width = 60,                       -- required: button content width in px
-- 	text = "Export",                  -- text or icon (mutually exclusive)
-- 	icon = "textures/path.dds",       -- texture path or resource
-- 	iconColor = nil,                  -- optional, static tint; omit to get hover feedback
-- 	side = "right",                   -- "left" or "right" of the select row (default "right")
-- 	event = "MyMod_SettingsButton",   -- global event sent on click (menu -> GLOBAL)
-- 	eventData = { action = "export" },-- optional payload table; { value = <current> } is merged in
-- }
-- the mod handles the event in a GLOBAL script and forwards to the player if needed.


------------------------------ constants ------------------------------
local SELECT_RENDERER_ID = "SuperSelect2"

local leftArrow = ui.texture { path = 'textures/omw_menu_scroll_left.dds' }
local rightArrow = ui.texture { path = 'textures/omw_menu_scroll_right.dds' }

local arrowSize = 12
local mwuiConstants = require('scripts.omw.mwui.constants')
local mwuiBorder = mwuiConstants.border -- 2px
local labelHeight = mwuiConstants.textNormalSize -- 18px
local screenSize = ui.screenSize()
local dropdownFallbackPos = v2(screenSize.x / 2, screenSize.y / 2)

local defaultArgument = {
	disabled = false,
	items = {},
	l10n = nil,
	width = 150,
	icon = nil,      -- table { [item] = "textures/path.dds" }
	iconColor = nil, -- optional table { [item] = util.color.rgb(...) }, white when missing
	iconSize = nil,  -- defaults to 1.3 * textSize
	textSize = nil,  -- defaults to the textNormal font size (also drives row height)
}
local fallbackIconSizeMult = 1.3

------------------------------ colors ------------------------------

local function getColorFromGameSettings(gmst)
	local result = core.getGMST(gmst)
	if not result then return util.color.rgb(1, 1, 1) end
	local rgb = {}
	for c in string.gmatch(result, '(%d+)') do
		table.insert(rgb, tonumber(c))
	end
	if #rgb ~= 3 then return util.color.rgb(1, 1, 1) end
	return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

-- label / list entries
local morrowindGold    = getColorFromGameSettings("fontColor_color_normal")
local morrowindLight   = getColorFromGameSettings("fontColor_color_normal_over")
local morrowindPressed = getColorFromGameSettings("FontColor_color_normal_pressed")
-- selected list entry
local morrowindActive        = getColorFromGameSettings("FontColor_color_active")
local morrowindActiveLight   = getColorFromGameSettings("FontColor_color_active_over")
local morrowindActivePressed = getColorFromGameSettings("FontColor_color_active_pressed")
-- invalid values
local morrowindRed        = util.color.rgb(1, 0, 0)
local morrowindRedLight   = util.color.rgb(1, 0.3, 0.3)
local morrowindRedPressed = util.color.rgb(1, 0.55, 0.55)

------------------------------ helpers ------------------------------

local function applyDefaults(argument)
	if argument == nil then return defaultArgument end
	local t = type(argument)
	if t ~= 'table' and t ~= 'userdata' then
		error('"' .. SELECT_RENDERER_ID .. '" renderer argument must be a table or userdata, got ' .. t)
	end
	local result = {}
	for k, v in pairs(defaultArgument) do
		result[k] = v
	end
	for k, v in pairs(argument) do
		result[k] = v
	end
	return result
end

local function paddedBox(layout)
	return {
		template = I.MWUI.templates.box,
		content = ui.content {
			{
				template = I.MWUI.templates.padding,
				content = ui.content { layout },
			},
		},
	}
end

local function resolveIcon(iconTable, iconColorTable, key)
	if iconTable == nil then return nil end
	local path = iconTable[key]
	if path == nil then return nil end
	local tex = type(path) == 'string' and ui.texture { path = path } or path
	local color = iconColorTable and iconColorTable[key] or util.color.rgb(1, 1, 1)
	return tex, color
end

local function disable(disabled, layout)
	if disabled then
		return {
			template = I.MWUI.templates.disabled,
			content = ui.content {
				layout,
			},
		}
	else
		return layout
	end
end

------------------------------ floating dropdown ------------------------------

local activeDropdown
local activeArgument

local function closeDropdown()
	if activeDropdown then
		activeDropdown:destroy()
		activeDropdown = nil
		activeArgument = nil
	end
end

-- opts: { key, topLeft, contentWidth, items, l10n, currentValue, onSelect, iconTable, iconColorTable, iconSize, textSize }
local function openDropdown(opts)
	closeDropdown()
	local contentWidth = opts.contentWidth
	local iconTable    = opts.iconTable
	local iconColorTable = opts.iconColorTable
	local iconSize     = opts.iconSize
	local textSize     = opts.textSize
	local items        = opts.items
	local onSelect     = opts.onSelect
	local currentValue = opts.currentValue
	local translator = opts.l10n and core.l10n(opts.l10n) or nil
	local hasIcons = iconTable ~= nil
	local rowHeight = hasIcons and math.max(textSize, iconSize) or textSize
	local textWidth = hasIcons and (contentWidth - iconSize - mwuiBorder) or contentWidth
	local textXOffset = hasIcons and (iconSize + mwuiBorder) or 0
	local rows = {}
	for _, item in ipairs(items) do
		local rowText = translator and translator(tostring(item)) or tostring(item)
		local isSelected = item == currentValue

		local focussed = false
		local pressed = false

		local textElement

		local function applyRowColor()
			local color
			if pressed then
				color = isSelected and morrowindActivePressed or morrowindPressed
			elseif focussed then
				color = isSelected and morrowindActiveLight or morrowindLight
			else
				color = isSelected and morrowindActive or morrowindGold
			end
			textElement.props.textColor = color
			if activeDropdown then activeDropdown:update() end
		end

		textElement = {
			template = I.MWUI.templates.textNormal,
			props = {
				text = rowText,
				textColor = isSelected and morrowindActive or morrowindGold,
				textSize = textSize,
				textAlignH = hasIcons and ui.ALIGNMENT.Start or ui.ALIGNMENT.Center,
				textAlignV = ui.ALIGNMENT.Center,
				autoSize = false,
				position = v2(textXOffset, 0),
				size = v2(textWidth, rowHeight),
			},
		}

		local rowEvents = {
			mouseClick = async:callback(function()
				onSelect(item)
				closeDropdown()
			end),
			focusGain = async:callback(function()
				focussed = true
				applyRowColor()
			end),
			focusLoss = async:callback(function()
				focussed = false
				pressed = false
				applyRowColor()
			end),
			mousePress = async:callback(function()
				pressed = true
				applyRowColor()
			end),
			mouseRelease = async:callback(function()
				pressed = false
				applyRowColor()
			end),
		}

		if hasIcons then
			local iconTex, iconColor = resolveIcon(iconTable, iconColorTable, item)
			local rowContent = ui.content { textElement }
			if iconTex then
				rowContent:add {
					type = ui.TYPE.Image,
					props = {
						resource = iconTex,
						color = iconColor,
						size = v2(iconSize, iconSize),
						position = v2(0, (rowHeight - iconSize) / 2),
					},
				}
			end
			table.insert(rows, {
				type = ui.TYPE.Widget,
				props = { size = v2(contentWidth, rowHeight) },
				content = rowContent,
				events = rowEvents,
			})
		else
			textElement.events = rowEvents
			table.insert(rows, textElement)
		end
	end
	activeArgument = opts.key
	local totalHeight = #items * rowHeight
	
	-- root blocks clicks outside of box
	activeDropdown = ui.create {
		layer = 'Settings',
		type = ui.TYPE.Widget,
		props = {
			relativeSize = v2(1, 1)
		},
		events = {
			keyPress = async:callback(function(e)
				if e.code == input.KEY.Escape then closeDropdown() end
			end),
			mousePress = async:callback(function() closeDropdown() end),
		},
		content = ui.content {
			-- floating dropdown
			{
				template = I.MWUI.templates.box, -- (borders)
				props = { position = opts.topLeft },
				content = ui.content {
					-- background
					{
						type = ui.TYPE.Image,
						props = {
							resource = ui.texture { path = 'black' },
							size = v2(contentWidth + 2 * mwuiBorder, totalHeight + 2 * mwuiBorder),
							alpha = 0.95,
						},
					},
					-- list
					{
						type = ui.TYPE.Flex,
						props = {
							horizontal = false,
							autoSize = false,
							position = v2(mwuiBorder, mwuiBorder),
							size = v2(contentWidth, totalHeight),
						},
						content = ui.content(rows),
					},
				},
			},
		},
	}
end

------------------------------ renderer registration ------------------------------
local keepHoverResource

local function arrowButton(resource, func, show)
	local button
	local focussed = false
	local pressed = false
	local function applyArrowColor()
		if pressed then
			button.layout.props.color = util.color.rgb(1, 1, 1)
		elseif focussed then
			button.layout.props.color = util.color.rgb(0.8, 0.8, 0.8)
		else
			button.layout.props.color = util.color.rgb(0.6, 0.6, 0.6)
		end
		button:update()
	end
	-- preserve hover on rebuild
	local hoverPreserved = keepHoverResource == resource
	if hoverPreserved then
		keepHoverResource = nil
	end
	button = ui.create{
		type = ui.TYPE.Image,
		props = {
			resource = resource,
			size = v2(arrowSize, arrowSize),
			color = hoverPreserved and util.color.rgb(0.8, 0.8, 0.8) or util.color.rgb(0.6, 0.6, 0.6),
			alpha = show and 1 or 0,
		},
		events = {
			mouseClick = func,
			focusGain = async:callback(function()
				focussed = true
				applyArrowColor()
			end),
			focusLoss = async:callback(function()
				focussed = false
				pressed = false
				applyArrowColor()
			end),
			mousePress = async:callback(function()
				pressed = true
				applyArrowColor()
			end),
			mouseRelease = async:callback(function()
				pressed = false
				applyArrowColor()
				keepHoverResource = resource
			end),
		},
	}
	return button
end

------------------------------ extra buttons ------------------------------

-- mod-supplied button spliced onto either side of the row; see header for the spec
local function extraButton(spec, rowHeight, textSize, value)
	local button
	local focussed = false
	local pressed = false
	local textElement
	local imageElement
	-- icons with an explicit color stay static, otherwise they tint like text
	local tintIcon = spec.icon ~= nil and spec.iconColor == nil

	local function applyColor()
		local color
		if pressed then
			color = morrowindPressed
		elseif focussed then
			color = morrowindLight
		else
			color = morrowindGold
		end
		if textElement then textElement.props.textColor = color end
		if tintIcon then imageElement.props.color = color end
		button:update()
	end

	-- inner content fills the button and carries no events, so update() stays a plain refresh
	local inner
	if spec.icon then
		local tex = type(spec.icon) == 'string' and ui.texture { path = spec.icon } or spec.icon
		-- fixed-size image drives the box size (a relatively-positioned child would
		-- not, collapsing the button); square at the row height keeps it aligned
		local iconButtonSize = rowHeight + mwuiBorder * 2
		imageElement = {
			type = ui.TYPE.Image,
			props = {
				resource = tex,
				color = spec.iconColor or morrowindGold,
				size = v2(iconButtonSize, iconButtonSize),
			},
		}
		inner = imageElement
	else
		textElement = {
			template = I.MWUI.templates.textNormal,
			props = {
				text = spec.text or '',
				textColor = morrowindGold,
				textSize = textSize,
				textAlignH = ui.ALIGNMENT.Center,
				textAlignV = ui.ALIGNMENT.Center,
				autoSize = true,
			},
		}
		inner = textElement
	end

	-- root widget owns the events (mirrors labelWidget, so update() inside a callback is safe);
	-- the border and inner content are event-free children that fill the widget
	button = ui.create {
		type = ui.TYPE.Container,
		props = {  },
		content = ui.content {
			{ template = I.MWUI.templates.box, content = ui.content{inner}},
		},
		events = {
			mouseClick = async:callback(function()
				-- only global scripts exist to receive it, and only while a game is loaded
				if not spec.event or menu.getState() ~= menu.STATE.Running then return end
				-- eventData is a read-only proxy; merge by iteration, fall back to a direct read
				local payload = { value = value }
				if spec.eventData ~= nil then
					local ok = pcall(function()
						for k, v in pairs(spec.eventData) do payload[k] = v end
					end)
					if not ok then payload.action = spec.eventData.action end
				end
				core.sendGlobalEvent(spec.event, payload)
			end),
			focusGain = async:callback(function()
				focussed = true
				applyColor()
			end),
			focusLoss = async:callback(function()
				focussed = false
				pressed = false
				applyColor()
			end),
			mousePress = async:callback(function()
				pressed = true
				applyColor()
			end),
			mouseRelease = async:callback(function()
				pressed = false
				applyColor()
			end),
		},
	}
	return button
end

I.Settings.registerRenderer(SELECT_RENDERER_ID, function(value, set, argument)
	local originalArgument = argument
	argument = applyDefaults(argument)
	
	if (type(argument.items) ~= 'table' and type(argument.items) ~= 'userdata') or #argument.items == 0 then
		error('"' .. SELECT_RENDERER_ID .. '" renderer requires a non-empty "items" array')
	end
	
	local itemCount = #argument.items
	
	local index
	for i, item in ipairs(argument.items) do
		if item == value then
			index = i
			break
		end
	end
	
	local label = argument.l10n and core.l10n(argument.l10n)(tostring(value)) or tostring(value)
	local isUnknown = index == nil
	
	local selectPrev = async:callback(function()
		if not index then
			set(argument.items[#argument.items])
			return
		end
		index = (index - 2) % itemCount + 1
		set(argument.items[index])
	end)
	
	local selectNext = async:callback(function()
		if not index then
			set(argument.items[1])
			return
		end
		index = index % itemCount + 1
		set(argument.items[index])
	end)
	
	-- left arrow
	local leftButton = arrowButton(leftArrow, selectPrev, itemCount > 1)
	
	-- size cascade: textSize drives font + row height; iconSize defaults from textSize;
	-- rowHeight is the larger of the two when an icon is shown so icons can exceed the text
	local contentWidth = argument.width
	local labelWidth = contentWidth - 2 * (arrowSize + mwuiBorder)
	local textSize = argument.textSize or labelHeight
	local iconSize = argument.iconSize or textSize * fallbackIconSizeMult
	local iconTex, iconColor = resolveIcon(argument.icon, argument.iconColor, value)
	local rowHeight = argument.icon and math.max(textSize, iconSize) or textSize

	-- detecting the position on the screen
	local mouseOffset = v2(-(arrowSize + 3 * mwuiBorder), rowHeight + 2 * mwuiBorder)
	local cachedTopLeft = dropdownFallbackPos

	local toggleDropdown = async:callback(function()
		if activeArgument == originalArgument then
			closeDropdown()
			return
		end
		openDropdown {
			key            = originalArgument,
			topLeft        = cachedTopLeft + mouseOffset,
			contentWidth   = contentWidth,
			items          = argument.items,
			l10n           = argument.l10n,
			currentValue   = value,
			onSelect       = set,
			iconTable      = argument.icon,
			iconColorTable = argument.iconColor,
			iconSize       = iconSize,
			textSize       = textSize,
		}
	end)

	local focussed = false
	local pressed = false
	local labelWidget
	-- inner text element; color updates mutate it directly then refresh labelWidget
	local labelText = {
		template = I.MWUI.templates.textNormal,
		props = {
			text = label,
			textColor = isUnknown and morrowindRed or morrowindGold,
			textSize = textSize,
			textAlignV = ui.ALIGNMENT.Center,
		},
	}
	local function applyButtonColor()
		local color
		if pressed then
			color = isUnknown and morrowindRedPressed or morrowindPressed
		elseif focussed then
			color = isUnknown and morrowindRedLight or morrowindLight
		else
			color = isUnknown and morrowindRed or morrowindGold
		end
		labelText.props.textColor = color
		labelWidget:update()
	end

	-- label area: either the text fills it (centered), or an icon+text Flex auto-sizes and centers itself
	local labelInner
	if argument.icon then
		labelText.props.autoSize = true
		local flexContent = ui.content {}
		if iconTex then
			flexContent:add {
				type = ui.TYPE.Image,
				props = {
					resource = iconTex,
					color = iconColor,
					size = v2(iconSize, iconSize),
				},
			}
			flexContent:add { template = I.MWUI.templates.interval }
		end
		flexContent:add(labelText)
		-- autoSize Flex shrinks to fit icon+text; relativePosition+anchor center the pair inside labelWidget
		labelInner = {
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
				autoSize = true,
				arrange = ui.ALIGNMENT.Center,
				relativePosition = v2(0.5, 0.5),
				anchor = v2(0.5, 0.5),
			},
			content = flexContent,
		}
	else
		labelText.props.textAlignH = ui.ALIGNMENT.Center
		labelText.props.autoSize = false
		labelText.props.size = v2(labelWidth, textSize)
		labelInner = labelText
	end

	labelWidget = ui.create {
		type = ui.TYPE.Widget,
		props = {
			size = v2(labelWidth, rowHeight),
		},
		content = ui.content { labelInner },
		events = {
			mouseClick = toggleDropdown,
			mouseMove = async:callback(function(e)
				focussed = true
				cachedTopLeft = e.position - e.offset
			end),
			keyPress = async:callback(function(e)
				if e.code == input.KEY.Escape and activeArgument == originalArgument then closeDropdown() end
			end),
			focusGain = async:callback(function()
				-- engine refires focusGain on this label when the dropdown root is destroyed;
				-- focussed is set in mouseMove instead so the label only highlights from real cursor activity
				applyButtonColor()
			end),
			focusLoss = async:callback(function()
				focussed = false
				pressed = false
				applyButtonColor()
			end),
			mousePress = async:callback(function()
				pressed = true
				applyButtonColor()
			end),
			mouseRelease = async:callback(function()
				pressed = false
				applyButtonColor()
			end),
		},
	}

	-- right arrow
	local rightButton = arrowButton(rightArrow, selectNext, itemCount > 1)

	-- the select row, wrapped in its own border
	local selectBody = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			arrange = ui.ALIGNMENT.Center,
		},
		content = ui.content {
			leftButton,
			{ template = I.MWUI.templates.interval },
			labelWidget,
			{ template = I.MWUI.templates.interval },
			rightButton,
		},
	}

	-- outer row keeps the extra buttons beside the bordered select, not inside its border
	-- argument round-trips through storage as a read-only proxy, so accept userdata too
	local outer = { paddedBox(selectBody) }
	if type(argument.buttons) == 'table' or type(argument.buttons) == 'userdata' then
		-- left buttons keep their listed order by inserting at an advancing front index
		local leftAt = 1
		for _, spec in ipairs(argument.buttons) do
			local button = extraButton(spec, rowHeight, textSize, value)
			if spec.side == 'left' then
				table.insert(outer, leftAt, button)
				table.insert(outer, leftAt + 1, { template = I.MWUI.templates.interval })
				leftAt = leftAt + 2
			else
				outer[#outer + 1] = { template = I.MWUI.templates.interval }
				outer[#outer + 1] = button
			end
		end
	end

	local root = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			arrange = ui.ALIGNMENT.Center,
		},
		content = ui.content(outer),
	}

	return disable(argument.disabled, root)
end)

------------------------------ mousewheel support ------------------------------

-- bonus function for letting mods use the mousewheel in menu scripts
local ownsMouseWheelTriggers = false
if not input.triggers["MenuMouseWheelUp"] then
	input.registerTrigger({
		key = "MenuMouseWheelUp",
		l10n = "none",
		name = "MenuMouseWheelUp",
		description = "",
	})
	input.registerTrigger({
		key = "MenuMouseWheelDown",
		l10n = "none",
		name = "MenuMouseWheelDown",
		description = "",
	})
	ownsMouseWheelTriggers = true
end

local function onMouseWheel(direction)
	closeDropdown()
	if ownsMouseWheelTriggers then
		if direction > 0 then
			input.activateTrigger("MenuMouseWheelUp")
		else
			input.activateTrigger("MenuMouseWheelDown")
		end
	end
end

------------------------------ engine handlers ------------------------------

return {
	engineHandlers = {
		onMouseWheel = onMouseWheel,
	},
}