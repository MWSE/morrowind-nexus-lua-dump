if errorDialogue then
	errorDialogue:destroy()
	errorDialogue = nil
end

local makeBorder = require("scripts.SunsDusk.ui_makeborder")

local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local v2 = util.vector2
local I = require('openmw.interfaces')
local async = require('openmw.async')

if not G_hudLayerSize then
	local layerId = ui.layers.indexOf("Modal")
	G_hudLayerSize = ui.layers[layerId].size
end

if not I.UI.getMode() then
	I.UI.setMode("Interface",{windows = {}})
end

-- ===================================================================
-- Global variables (NEED to be assigned before requiring this file)
-- ===================================================================
errorMessage = errorMessage or "An error occurred"
errorDetails = errorDetails or ""


-- Convert errorMessage to array if it's a string
if type(errorMessage) == "string" then
	local lines = {}
	for line in errorMessage:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end
	errorMessage = lines
elseif type(errorMessage) ~= "table" then
	errorMessage = {tostring(errorMessage)}
end

-- Button Setup
local borderOffset = 1
local borderFile = "thin"
local textSize = 18
local fontSize = 16

-- Color helper
local function getColorFromGameSettings(colorTag)
	local result = core.getGMST(colorTag)
	if not result then
		return util.color.rgb(1,1,1)
	end
	local rgb = {}
	for color in string.gmatch(result, '(%d+)') do
		table.insert(rgb, tonumber(color))
	end
	if #rgb ~= 3 then
		print("UNEXPECTED COLOR: rgb of size=", #rgb)
		return util.color.rgb(1, 1, 1)
	end
	return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

local function darkenColor(color, factor)
	return util.color.rgb(color.r * factor, color.g * factor, color.b * factor)
end

local textColor = getColorFromGameSettings("fontColor_color_normal_over")
local morrowindGold = getColorFromGameSettings("fontColor_color_normal")
local errorColor = util.color.rgb(0.8, 0.2, 0.2)
local errorTextColor = util.color.rgb(1.0, 0.6, 0.6) -- Bright, desaturated red for readable error details
local blackTexture = ui.texture { path = 'black' }

-- Border template with background
local borderTemplate = makeBorder(borderFile, nil, borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = blackTexture,
		relativeSize = v2(1,1),
		alpha = 0.9,
		color = util.color.rgb(0.1, 0.05, 0.05),
	}
}).borders

-- Root
errorDialogue = ui.create({
	type = ui.TYPE.Container,
	layer = 'Modal',
	name = "errorDialogue_" .. math.random(),
	template = borderTemplate,
	props = {
		relativePosition = v2(0.5, 0.5),
		anchor = v2(0.5, 0.5),
	},
	content = ui.content {}
})

-- Top/bottom padding
local outerVerticalFlex = {
	name = 'outerVerticalFlex',
	type = ui.TYPE.Flex,
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Center,
		horizontal = false,
	},
	content = ui.content{}
}
errorDialogue.layout.content:add(outerVerticalFlex)

-- Top padding
outerVerticalFlex.content:add{ props = { size = v2(1, 10) } }

-- Left/right padding
local horizontalFlex = {
	name = 'horizontalFlex',
	type = ui.TYPE.Flex,
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Center,
		horizontal = true,
	},
	content = ui.content{}
}
outerVerticalFlex.content:add(horizontalFlex)

-- Left padding
horizontalFlex.content:add{ props = { size = v2(15, 1) } }

-- Main flex
local mainFlex = {
	name = 'mainFlex',
	type = ui.TYPE.Flex,
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Center,
		horizontal = false,
	},
	content = ui.content{}
}
horizontalFlex.content:add(mainFlex)

-- Right padding
horizontalFlex.content:add{ props = { size = v2(15, 1) } }

-- Bottom padding
outerVerticalFlex.content:add{ props = { size = v2(1, 10) } }

-- Text container for error messages
local textContainer = {
	type = ui.TYPE.Flex,
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Center,
		horizontal = false,
	},
	content = ui.content{}
}
mainFlex.content:add(textContainer)

-- Add error message lines with auto-sizing
for _, text in pairs(errorMessage) do
	textContainer.content:add({
		name = 'messageText',
		type = ui.TYPE.Text,
		props = {
			text = " " .. text .. " ",
			textColor = textColor,
			textShadow = true,
			textShadowColor = util.color.rgb(0, 0, 0),
			textSize = textSize,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = true,
			multiline = true,
		},
	})
end

-- Add spacing before error details if they exist
if errorDetails and errorDetails ~= "" then
	textContainer.content:add{ props = { size = v2(1, 8) } }
	
	-- Approximate TextEdit dimensions
	local errorDetailsStr = tostring(errorDetails)
	local maxWidth = G_hudLayerSize.x -- Limited by Hud size
	local charWidth = textSize * 0.5 -- Approximate character width
	local lineHeight = textSize * 1.4 -- Line height with spacing
	
	-- Estimate width based on longest line
	local estimatedWidth = 0
	local lineCount = 0
	for line in errorDetailsStr:gmatch("[^\r\n]+") do
		lineCount = lineCount + 1
		local lineWidth = #line * charWidth
		if lineWidth > estimatedWidth then
			estimatedWidth = lineWidth
		end
	end
	
	-- If no newlines were found, treat as single line
	if lineCount == 0 then
		lineCount = 1
		estimatedWidth = #errorDetailsStr * charWidth
	end
	
	-- Cap width at maxWidth and account for word wrapping
	if estimatedWidth > maxWidth then
		-- Estimate additional lines from word wrapping
		local wrappedLines = math.ceil(estimatedWidth / maxWidth)
		lineCount = lineCount * wrappedLines
		estimatedWidth = maxWidth
	end
	
	local estimatedHeight = lineCount * lineHeight
	
	-- Add actual error details in reddish color as a read-only TextEdit
	textContainer.content:add({
		name = 'errorDetails',
		type = ui.TYPE.TextEdit,
		template = borderTemplate,
		props = {
			text = errorDetailsStr,
			textColor = errorTextColor,
			textSize = textSize,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			multiline = true,
			wordWrap = true,
			readOnly = false,
			size = v2(estimatedWidth + 20, estimatedHeight + 10), -- Add padding
		},
	})
end

-- Spacer before button
mainFlex.content:add{ props = { size = v2(1, 12) } }

-- OK Button (inline creation without makeButton)
local buttonSize = v2(120, fontSize*2)
local highlightColor = errorColor

-- Create button border template
local buttonBorderTemplate = makeBorder(borderFile, util.color.rgb(0.5,0.5,0.5), borderOffset, {
	type = ui.TYPE.Image,
	props = {
		relativeSize = v2(1,1),
		alpha = 0.5,
	}
}).borders

-- Create button widget
local okButtonBox = ui.create{
	name = "okButton_" .. math.random(),
	type = ui.TYPE.Widget,
	props = {
		size = buttonSize,
	},
	content = ui.content {}
}

-- Button background
local buttonBackground = {
	name = 'background',
	type = ui.TYPE.Image,
	props = {
		relativeSize = v2(1, 1),
		resource = ui.texture { path = 'white' },
		color = util.color.rgb(0,0,0),
		alpha = 0.15,
	},
}
okButtonBox.layout.content:add(buttonBackground)

-- Button border
local buttonBorder = {
	name = 'border',
	template = buttonBorderTemplate,
	props = {
		relativeSize = v2(1, 1),
		alpha = 0.3,
	},
}
okButtonBox.layout.content:add(buttonBorder)

-- Button text
local buttonText = {
	name = 'text',
	type = ui.TYPE.Text,
	props = {
		relativePosition = v2(0.5, 0.5),
		anchor = v2(0.5, 0.5),
		text = "OK",
		textColor = textColor,
		textShadow = true,
		textShadowColor = util.color.rgb(0,0,0),
		textSize = textSize,
		textAlignH = ui.ALIGNMENT.Center,
		textAlignV = ui.ALIGNMENT.Center,
	},
}
okButtonBox.layout.content:add(buttonText)

-- Button clickbox with state management
local clickbox = {
	name = 'clickbox',
	props = {
		relativeSize = v2(1, 1),
	},
	userData = {
		focus = false,
		pressed = false,
	},
}

-- Color application function
local function applyButtonColor(elem)
	elem = elem or clickbox
	if elem.userData.pressed then
		buttonBackground.props.color = darkenColor(highlightColor, 0.8)
		buttonBackground.props.alpha = 0.8
		buttonBorder.props.alpha = 1
	elseif elem.userData.focus then
		buttonBackground.props.color = darkenColor(highlightColor, 0.5)
		buttonBackground.props.alpha = 0.8
		buttonBorder.props.alpha = 1
	else
		buttonBackground.props.color = util.color.rgb(0,0,0)
		buttonBackground.props.alpha = 0.15
		buttonBorder.props.alpha = 0.3
	end
	okButtonBox:update()
end

-- Button events
clickbox.events = {
	mouseRelease = async:callback(function(_, elem)
		elem.userData.pressed = false
		applyButtonColor(elem)
		-- Execute button action directly without G_onFrameJobs
		if elem.userData.focus then
			if errorDialogue then
				errorDialogue:destroy()
				errorDialogue = nil
			end
		end
	end),
	focusGain = async:callback(function(_, elem)
		elem.userData.focus = true
		applyButtonColor(elem)
	end),
	focusLoss = async:callback(function(_, elem)
		elem.userData.focus = false
		elem.userData.pressed = false
		applyButtonColor(elem)
	end),
	mousePress = async:callback(function(_, elem)
		elem.userData.focus = true
		elem.userData.pressed = true
		applyButtonColor(elem)
	end),
}

okButtonBox.layout.content:add(clickbox)

mainFlex.content:add(okButtonBox)