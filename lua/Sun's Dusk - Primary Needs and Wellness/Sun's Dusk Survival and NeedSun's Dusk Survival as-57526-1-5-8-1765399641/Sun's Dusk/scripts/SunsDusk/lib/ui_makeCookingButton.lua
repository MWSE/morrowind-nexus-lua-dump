-- Import required modules
local makeBorder = require("scripts.SunsDusk.ui_makeBorder")

-- Configuration from main window
local textSize = 24
local spacer = 5
local borderOffset = 1
local borderFile = "thin"


-- Color setup
local textColor = getColorFromGameSettings("fontColor_color_normal_over")
local morrowindGold = getColorFromGameSettings("fontColor_color_normal")
local background = ui.texture { path = 'black' }

-- Border templates
local borderTemplate = makeBorder(borderFile, util.color.rgb(0.5,0.5,0.5), borderOffset, {
	type = ui.TYPE.Image,
	props = {
		relativeSize = v2(1,1),
		alpha = 0.6,
	}
}).borders

local tooltipTemplate = makeBorder(borderFile, util.color.rgb(0.5,0.5,0.5), borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = ui.texture{ path = 'black' },
		relativeSize = v2(1,1),
		alpha = 0.93,
	}
}).borders

local function makeMouseTooltip(content) --makeTooltip	
	return ui.create{
		type = ui.TYPE.Container,
		layer = 'Notification',
		name = "aaaa",
		template = tooltipTemplate,
		props = {
		},
		content = ui.content{content}
	}
end

-- makeButton v4.3 (with right-side icon container)
local function makeButton(label, props, func, highlightColor, parent, iconResource, hoverResource, pressedResource, tooltipContent)
	--local mouseTooltip
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
		--template = borderTemplate,
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
			alpha = 0.3,
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
		
		-- Add border template
		local borderTemplate = makeBorder(borderFile, util.color.rgb(0.5,0.5,0.5), 1, {
			type = ui.TYPE.Image,
			props = {
				relativeSize = v2(1,1),
				alpha = 0.5,
			}
		}).borders
		
		if text then
			iconWithBorder.content:add{
				name = 'iconBackground',
				
				type = ui.TYPE.Image,
				props = {
					relativeSize = v2(1, 1),
					resource = getTexture('white'),
					color = darkenColor(morrowindGold, 0.1),
					alpha = 0.8,
				},
			}
		end
		image = {
			type = ui.TYPE.Image,
			template = borderTemplate,
			props = {
				resource = iconResource,
				relativeSize = v2(1, 1),
				relativePosition = v2(0.5, 0.5),
				anchor = v2(0.5, 0.5),
				alpha = 0.9,
				size = v2(-2,-2)
			}
		}
		iconWithBorder.content:add(image)
		box.layout.content:add(iconWithBorder)
	end

	
	--- Text
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
	
	-- Right-side icon container (always created, can be populated later)
	local rightIconContainer = ui.create{
		name = 'rightIconContainer',
		type = ui.TYPE.Widget,
		props = {
			size = v2(props.size.y,props.size.y),
			position = v2(0, 0),
			relativePosition = v2(1, 0.5),
			anchor = v2(1, 0.5),
		},
		content = ui.content{},
	}
	box.layout.content:add(rightIconContainer)
	
	local clickbox = {
		name = 'clickbox',
		props = {
			relativeSize = v2(1, 1),
		},
		userData = {
			focus = false,
			pressed = false,
			selected = false,
			highlightAlpha = 0, -- For dynamic highlighting
		},
	}
	local previousResource
	local function applyColor(elem)
		elem = elem or clickbox
		if elem.userData.pressed then
			buttonBackground.props.color = darkenColor(highlightColor or morrowindGold, 0.95)
			buttonBackground.props.alpha = 0.8
			buttonBorder.props.alpha = 1
			if pressedResource then
				previousResource = image.props.resource
				image.props.resource = pressedResource
			end
		elseif elem.userData.focus then
			buttonBackground.props.color = darkenColor(highlightColor or morrowindGold, 0.8)
			buttonBackground.props.alpha = 0.8
			buttonBorder.props.alpha = 1
			if previousResource then
				image.props.resource = previousResource
				previousResource = nil
			end
		elseif elem.userData.selected then
			buttonBackground.props.color = darkenColor(highlightColor or morrowindGold, 0.7)
			buttonBackground.props.alpha = 0.6
			buttonBorder.props.alpha = 0.8
			if previousResource then
				image.props.resource = previousResource
				previousResource = nil
			end
		else
			-- Normal state - use highlight if available
			if elem.userData.highlightAlpha and elem.userData.highlightAlpha > 0 then
				buttonBackground.props.color = highlightColor or morrowindGold
				buttonBackground.props.alpha = elem.userData.highlightAlpha
				buttonBorder.props.alpha = 0.3 + elem.userData.highlightAlpha * 0.5
			else
				buttonBackground.props.color = util.color.rgb(0,0,0)
				buttonBackground.props.alpha = 0.15
				buttonBorder.props.alpha = 0.3
			end
			if previousResource then
				image.props.resource = previousResource
				previousResource = nil
			end
		end
		box:update()
	end
	clickbox.userData.applyColor = applyColor
	local s = {box = box, clickbox = clickbox, applyColor = applyColor, image = image, rightIconContainer = rightIconContainer}
	
	clickbox.events = {
		mouseRelease = async:callback(function(_, elem)
			elem.userData.pressed = false
			G_onFrameJobs[uniqueButtonId] = function()
				if elem.userData.focus and core.getRealTime() > creationTime + 0.4 then
					func(elem)
				end
				applyColor(elem)
				G_onFrameJobs[uniqueButtonId] = nil
			end
			if not mouseTooltip and tooltipContent then
				mouseTooltip = makeMouseTooltip(tooltipContent)--, elem.userData.recipe.name, calculateQuality(elem.userData.recipe, artisansTouch))
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
			if mouseTooltip then
				mouseTooltip:destroy()
				mouseTooltip = nil
			end
		end),
		mousePress = async:callback(function(_, elem)
			elem.userData.focus = true
			elem.userData.pressed = true
			applyColor(elem)
		end),
		mouseMove = async:callback(function(data, elem)
			if not mouseTooltip and tooltipContent then
				mouseTooltip = makeMouseTooltip(tooltipContent)--, elem.userData.recipe.name, calculateQuality(elem.userData.recipe, artisansTouch))
			end
			if mouseTooltip then
				mouseTooltip.layout.props.position = v2(data.position.x+13,data.position.y+25)
				mouseTooltip:update()
			end
		end),
	}
	box.layout.content:add(clickbox)
	return s
end





return makeButton, refreshButtons