local makeBorder = require("scripts.timecontrol.tc_makeBorder")

local textSize = 24
local spacer = 5
local borderOffset = 1
local borderFile = "thin"

local textColor = getColorFromGameSettings("fontColor_color_normal_over")
local morrowindGold = getColorFromGameSettings("fontColor_color_normal")

local function makeButton(label, props, func, highlightColor, parent, iconResource, hoverResource, pressedResource, iconTint)
	local borderTemplate = makeBorder(borderFile, THEME_COLOR, borderOffset, {
		type = ui.TYPE.Image,
		props = {
			relativeSize = v2(1,1),
			alpha = 0.6,
			color = THEME_COLOR,
		}
	}).borders
	local creationTime = core.getRealTime()
	local uniqueButtonId = ""..math.random()
	local box = ui.create{
		name = uniqueButtonId,
		type = ui.TYPE.Widget,
		props = props,
		content = ui.content {}
	}
	
	local buttonBackground = {
		name = 'background',
		type = ui.TYPE.Image,
		props = {
			relativeSize = v2(1, 1),
			resource = getTexture('white'),
			color = util.color.rgb(0,0,0),
			alpha = 0.15,
		},
	}
	box.layout.content:add(buttonBackground)
	
	local buttonBorder = {
		name = 'background',
		template = borderTemplate,
		props = {
			relativeSize = v2(1, 1),
			alpha = 0.9,
		},
	}
	box.layout.content:add(buttonBorder)
	
	local iconWithBorder
	local image
	if iconResource then
		iconWithBorder = {
			type = ui.TYPE.Widget,
			props = {
				size = v2(props.size.y or 24, props.size.y or 24),
			},
			content = ui.content {}
		}
		
		image = {
			type = ui.TYPE.Image,
			props = {
				resource = iconResource,
				relativeSize = v2(1, 1),
				relativePosition = v2(0.5, 0.5),
				anchor = v2(0.5, 0.5),
				alpha = 0.9,
				size = v2(-2,-2),
				color = iconTint,
			}
		}
		iconWithBorder.content:add(image)
		box.layout.content:add(iconWithBorder)
	end

	local text
	if label then
		text = {
			name = 'text',
			type = ui.TYPE.Text,
			props = {
				relativePosition = iconResource and v2(0, 0.5) or v2(0.5, 0.5),
				anchor = iconResource and v2(0, 0.5) or v2(0.5, 0.5),
				position = iconResource and v2(34, 0) or v2(0, 0),
				text = tostring(label),
				textColor = textColor,
				textShadow = true,
				textShadowColor = util.color.rgb(0,0,0),
				textSize = textSize,
				textAlignH = iconResource and ui.ALIGNMENT.Start or ui.ALIGNMENT.Center,
				textAlignV = ui.ALIGNMENT.Center,
			},
		}
		box.layout.content:add(text)
	end
	
	local clickbox = {
		name = 'clickbox',
		props = {
			relativeSize = v2(1, 1),
		},
		userData = {
			focus = false,
			pressed = false,
			selected = false,
			highlightAlpha = 0,
		},
	}
	local previousResource
	local function applyColor(elem)
		elem = elem or clickbox
		if elem.userData.pressed then
			buttonBackground.props.color = darkenColor(highlightColor or morrowindGold, 0.8)
			buttonBackground.props.alpha = 0.8
			buttonBorder.props.alpha = 1
			if pressedResource then
				previousResource = image.props.resource
				image.props.resource = pressedResource
			end
		elseif elem.userData.focus then
			buttonBackground.props.color = darkenColor(highlightColor or morrowindGold, 0.5)
			buttonBackground.props.alpha = 0.8
			buttonBorder.props.alpha = 1
			if previousResource then
				image.props.resource = previousResource
				previousResource = nil
			end
		elseif elem.userData.selected then
			buttonBackground.props.color = darkenColor(highlightColor or morrowindGold, 0.4)
			buttonBackground.props.alpha = 0.6
			buttonBorder.props.alpha = 0.9
			if previousResource then
				image.props.resource = previousResource
				previousResource = nil
			end
		else
			if elem.userData.highlightAlpha and elem.userData.highlightAlpha > 0 then
				buttonBackground.props.color = highlightColor or morrowindGold
				buttonBackground.props.alpha = elem.userData.highlightAlpha
				buttonBorder.props.alpha = 0.8 + elem.userData.highlightAlpha * 0.5
			else
				buttonBackground.props.color = util.color.rgb(0,0,0)
				buttonBackground.props.alpha = 0.15
				buttonBorder.props.alpha = 0.8
			end
			if previousResource then
				image.props.resource = previousResource
				previousResource = nil
			end
		end
		box:update()
	end
	clickbox.userData.applyColor = applyColor
	local s = {box = box, clickbox = clickbox, applyColor = applyColor, image = image}
	
	clickbox.events = {
		mouseRelease = async:callback(function(data, elem)
			local button = data.button
			elem.userData.pressed = false
			G_onFrameJobs[uniqueButtonId] = function()
				if elem.userData.focus and core.getRealTime() > creationTime + 0.4 then
					func(button, elem)
				end
				applyColor(elem)
				G_onFrameJobs[uniqueButtonId] = nil
			end
		end),
		focusGain = async:callback(function(_, elem)
			elem.userData.focus = true
			applyColor(elem)
		end),
		focusLoss = async:callback(function(_, elem)
			elem.userData.focus = false
			elem.userData.pressed = false
			applyColor(elem)
		end),
		mousePress = async:callback(function(data, elem)
			elem.userData.focus = true
			elem.userData.pressed = true
			applyColor(elem)
		end),
	}
	box.layout.content:add(clickbox)
	return s
end

return makeButton
