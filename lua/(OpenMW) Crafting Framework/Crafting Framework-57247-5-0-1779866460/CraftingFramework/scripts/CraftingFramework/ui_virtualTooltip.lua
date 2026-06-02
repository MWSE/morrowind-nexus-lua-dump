local makeBorder = require("scripts.CraftingFramework.ui_makeborder")
local background = ui.texture { path = 'black' }
local borderOffset = 1
local OPACITY = 0.8

-- thin border, matches description tooltip
local borderTemplate = makeBorder("thin", nil, borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = background,
		relativeSize = v2(1, 1),
		alpha = OPACITY,
	}
}).borders

-- virtual tooltip; availableText/requiredText pre-formatted
return function(def, availableText, requiredText, available, required)
	local shadow = util.color.rgba(0, 0, 0, 1)

	-- title
	local nameLine = {
		type = ui.TYPE.Text,
		props = {
			text = virtualName(def, available, required) or "",
			textColor = morrowindGold,
			textShadow = true,
			textShadowColor = shadow,
			textSize = S_FONT_SIZE,
			autoSize = true,
		},
	}

	-- available line
	local availLine = {
		type = ui.TYPE.Text,
		props = {
			text = "Available: " .. (availableText or "-"),
			textColor = textColor,
			textShadow = true,
			textShadowColor = shadow,
			textSize = S_FONT_SIZE - 2,
			autoSize = true,
		},
	}

	-- required line
	local needLine = {
		type = ui.TYPE.Text,
		props = {
			text = "Required: " .. (requiredText or "-"),
			textColor = textColor,
			textShadow = true,
			textShadowColor = shadow,
			textSize = S_FONT_SIZE - 2,
			autoSize = true,
		},
	}

	-- text column
	local textColumn = {
		type = ui.TYPE.Flex,
		props = {
			autoSize = true,
			arrange = ui.ALIGNMENT.Start,
		},
		content = ui.content { nameLine },
	}

	-- flavor description
	local descText = virtualDescription(def, available, required)
	if descText and descText ~= "" then
		textColumn.content:add({ props = { size = v2(1, 2) } })
		textColumn.content:add({
			type = ui.TYPE.Text,
			props = {
				text = descText,
				textColor = darkenColor(morrowindGold, 0.8),
				textShadow = true,
				textShadowColor = shadow,
				textSize = S_FONT_SIZE - 2,
				autoSize = true,
			},
		})
		textColumn.content:add({ props = { size = v2(1, 2) } })
	end

	textColumn.content:add(availLine)
	textColumn.content:add(needLine)

	-- outer frame
	return ui.create {
		type = ui.TYPE.Flex,
		layer = 'Notification',
		template = borderTemplate,
		props = {
			autoSize = true,
		},
		content = ui.content {
			{ props = { size = v2(2, 2) } },
			{
				type = ui.TYPE.Flex,
				props = { horizontal = true },
				content = ui.content {
					{ props = { size = v2(2, 2) } },
					textColumn,
					{ props = { size = v2(2, 2) } },
				},
			},
			{ props = { size = v2(2, 2) } },
		},
	}
end
