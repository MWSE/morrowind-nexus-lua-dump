if attributeSelectionDialogue then
	attributeSelectionDialogue:destroy()
	attributeSelectionDialogue = nil
end

local makeBorder = require("scripts.Roguelite.ui_makeborder") 
local borderOffset = 1
local borderFile = "thin"

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

local function mixColors(color1, color2)
	return util.color.rgb((color1.r+color2.r)*0.5, (color1.g+color2.g)*0.5, (color1.b+color2.b)*0.5)
end

local fontColor = getColorFromGameSettings("FontColor_color_normal_over")
local darkerFont = util.color.rgb(fontColor.r*0.7,fontColor.g*0.7,fontColor.b*0.7)
local fontSize = 21
local background = ui.texture { path = 'black' }

-- Morrowind-inspirierte Farben
local morrowindGold = getColorFromGameSettings("FontColor_color_normal")
local morrowindBrown = util.color.rgb(0.4, 0.3, 0.2)
local selectedColor = util.color.rgb(0.6, 0.5, 0.2)
local hoverColor = util.color.rgb(0.3, 0.25, 0.15)

local selectedAttribute = nil
local attributeButtonFocus = nil

-- Cache für alle UI-Elemente
local attributeButtons = {}
local confirmButton = nil

-- Attribute mit Icons
local attributes = {}
for _, record in pairs(core.stats.Attribute.records) do
	table.insert(attributes, {id = record.id, name = record.name, icon = record.icon})
end


local function textElement(str, color)
	return { 
		type = ui.TYPE.Text,
		props = {
			textColor = color or fontColor,
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,0.9),
			textAlignV = ui.ALIGNMENT.Center,
			textAlignH = ui.ALIGNMENT.Center,
			text = " "..str.." ",
			textSize = fontSize,
			autoSize = true
		},
	}
end

local function makeAttributeIcon(iconPath)
	local iconSize = fontSize*2
	local iconBorderTemplate = makeBorder(borderFile, nil, 1, {
		type = ui.TYPE.Image,
		props = {
			relativeSize = v2(1,1),
			alpha = 0.5,
		}
	}).borders
	
	local iconBox = {
		type = ui.TYPE.Widget,
		props = {
			size = v2(iconSize, iconSize),
		},
		content = ui.content {}
	}
	
	-- Icon Background
	iconBox.content:add{
		name = 'iconBackground',
		template = iconBorderTemplate,
		type = ui.TYPE.Image,
		props = {
			relativeSize = v2(1, 1),
			resource = ui.texture { path = 'white' },
			color = util.color.rgb(0,0,0),
			alpha = 0.3,
		},
	}
	
	-- Icon
	iconBox.content:add{
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture { path = iconPath },
			relativeSize = v2(1, 1),
			relativePosition = v2(0.5, 0.5),
			anchor = v2(0.5, 0.5),
			alpha = 0.9,
		}
	}
	
	return iconBox
end

local layerId = ui.layers.indexOf("HUD")
local screenSize = ui.layers[layerId].size

local borderTemplate = makeBorder(borderFile, nil, borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = background,
		relativeSize  = v2(1,1),
		alpha = 0.5,
	}
}).borders

--root
attributeSelectionDialogue = ui.create({
	type = ui.TYPE.Container,
	layer = 'Modal',
	name = "attributeSelectionDialogue",
	template = borderTemplate,
	props = {
		relativePosition = v2(0.5,0.5),
		anchor = v2(0.5,0.5),
	},
	content = ui.content {{
			name = 'background',
			type = ui.TYPE.Image,
			props = {
				resource = background,
				tileH = true,
				tileV = true,
				--color = morrowindBrown,
				--alpha = 0.3,
			},
		},
	}
})

local flex = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'mainFlex',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Center,
	},
	content = ui.content {
	}
}
attributeSelectionDialogue.layout.content:add(flex)

flex.content:add{ props = { size = v2(1, 1) * 1 } }
flex.content:add(textElement("Choose an attribute:", fontColor))
flex.content:add{ props = { size = v2(1, 1) * 3 } }

-- Attribute-Buttons Container
local attributeGrid = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'attributeGrid',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
		horizontal = false,
	},
	content = ui.content {
	}
}
flex.content:add(attributeGrid)

local function updateAllAttributeButtons()
	for _, buttonData in pairs(attributeButtons) do
		if buttonData.attribute.id == selectedAttribute then
			buttonData.background.props.color = selectedColor
			buttonData.arrow.props.text = " > "
			buttonData.newValue.props.text = "80"
		else
			buttonData.background.props.color = util.color.rgb(0,0,0)
			buttonData.arrow.props.text = ""
			buttonData.newValue.props.text = ""
		end
	end
	attributeSelectionDialogue:update()
end

-------------------------------------------------------------------------------------- ATTRIBUTE BUTTON --------------------------------------------------------------------------------------
local function makeAttributeButton(attribute)
	local borderTemplate = makeBorder(borderFile, nil, borderOffset, {
		type = ui.TYPE.Image,
		props = {
			relativeSize = v2(1,1),
			alpha = 0.3,
		}
	}).borders
	
	local box = {
		name = attribute.id .. "Button",
		type = ui.TYPE.Widget,
		props = {
			size = v2(fontSize*14.5, fontSize*2),
		},
		content = ui.content {}
	}
	
	local background = {
		name = 'background',
		template = borderTemplate,
		type = ui.TYPE.Image,
		props = {
			relativeSize = util.vector2(1, 1),
			resource = ui.texture { path = 'white' },
			color = util.color.rgb(0,0,0),
			alpha = 0.3,
		},
	}
	box.content:add(background)
	
	-- Content Container (horizontal flex)
	local contentFlex = {
		type = ui.TYPE.Flex,
		props = {
			relativeSize = v2(1, 1),
			arrange = ui.ALIGNMENT.Center,
			horizontal = true,
		},
		content = ui.content {}
	}
	box.content:add(contentFlex)
	
	-- Icon
	contentFlex.content:add{ props = { size = v2(1, 1) * 2 } }

	contentFlex.content:add(makeAttributeIcon(attribute.icon))
	contentFlex.content:add{ props = { size = v2(1, 1) * 5 } }
	
	--local attributeNameBox = {
	--	name = attribute.id .. "Button",
	--	type = ui.TYPE.Widget,
	--	props = {
	--		size = v2(250, fontSize*2.5),
	--	},
	--	content = ui.content {}
	--}
	-- Attribute Name
	contentFlex.content:add{
		type = ui.TYPE.Text,
		props = {
			text = attribute.name,
			textColor = mixColors(fontColor,morrowindGold),
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,1),
			textSize = fontSize,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
			size = v2(fontSize*8.1,0),
			relativeSize = v2(0,1),
		},
	}
	
	contentFlex.content:add{
		type = ui.TYPE.Text,
		props = {
			text = types.NPC.stats.attributes[attribute.id](self).base .."",
			textColor = mixColors(fontColor,morrowindGold),
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,1),
			textSize = fontSize,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
			--autoSize = false,
			--size = v2(20,fontSize*2)
			
		},
	}	
	
	local arrow = {
		name = "arrow",
		type = ui.TYPE.Text,
		props = {
			text = "",
			textColor = mixColors(fontColor,morrowindGold),
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,1),
			textSize = fontSize,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
			
		},
	}
	contentFlex.content:add(arrow)
	
	local newValue = {
		name = "newValue",
		type = ui.TYPE.Text,
		props = {
			text = "",
			textColor = util.color.rgb(0.4, 0.8, 0.4),
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,1),
			textSize = fontSize,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = true,
		},
	}
	contentFlex.content:add(newValue)
	
	contentFlex.content:add{ props = { size = v2(1, 1) * 2 } }
	
	-- Button-Data im Cache speichern
	attributeButtons[attribute.id] = {
		box = box,
		background = background,
		attribute = attribute,
		arrow = arrow,
		newValue = newValue,
	}
	
	local clickbox = {
		name = 'clickbox',
		props = {
			relativeSize = util.vector2(1, 1),
			relativePosition = v2(0,0),
			anchor = v2(0,0),
		},
		userData = {
			attributeId = attribute.id
		},
	}
	
	clickbox.events = {
		mouseRelease = async:callback(function(_, elem)
			if attributeButtonFocus == elem.userData.attributeId then
				selectedAttribute = elem.userData.attributeId
				updateAllAttributeButtons()
			end
		end),
		focusGain = async:callback(function(_, elem)
			attributeButtonFocus = elem.userData.attributeId
			if selectedAttribute ~= elem.userData.attributeId then
				background.props.color = hoverColor
				arrow.props.text = " > "
				newValue.props.text = "80"
				attributeSelectionDialogue:update()
			end
		end),
		focusLoss = async:callback(function(_, elem)
			attributeButtonFocus = nil
			if selectedAttribute ~= elem.userData.attributeId then
				background.props.color = util.color.rgb(0,0,0)
				arrow.props.text = ""
				newValue.props.text = ""
			end
			attributeSelectionDialogue:update()
		end),
	}
	
	box.content:add(clickbox)
	return box
end

-- Attribute-Buttons erstellen
for _, attribute in ipairs(attributes) do
	attributeGrid.content:add(makeAttributeButton(attribute))
	attributeGrid.content:add{ props = { size = v2(1, 1) * 1 } }
end

flex.content:add{ props = { size = v2(1, 1) * 3 } }

-- Confirm Button
local function makeConfirmButton()
	local borderTemplate = makeBorder(borderFile, nil, borderOffset, {
		type = ui.TYPE.Image,
		props = {
			relativeSize = v2(1,1),
			alpha = 0.3,
		}
	}).borders
	
	local box = {
		name = "confirmButton",
		type = ui.TYPE.Widget,
		props = {
			size = v2(200, fontSize*2),
		},
		content = ui.content {}
	}
	
	local background = {
		name = 'background',
		template = borderTemplate,
		type = ui.TYPE.Image,
		props = {
			relativeSize = util.vector2(1, 1),
			resource = ui.texture { path = 'white' },
			color = util.color.rgb(0,0,0),
			alpha = 0.3,
		},
	}
	box.content:add(background)
	
	box.content:add{
		name = 'text',
		type = ui.TYPE.Text,
		props = {
			relativePosition = v2(0.5,0.5),
			anchor = v2(0.5,0.5),
			text = "Confirm Selection",
			textColor = fontColor,
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,1),
			textSize = fontSize,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
		},
	}
	
	-- Confirm Button im Cache speichern
	confirmButton = {
		box = box,
		background = background
	}
	
	local clickbox = {
		name = 'clickbox',
		props = {
			relativeSize = util.vector2(1, 1),
			relativePosition = v2(0,0),
			anchor = v2(0,0),
		},
		userData = {
			focus = 0
		},
	}
	
	local function applyColor(elem)
		if not selectedAttribute then
			background.props.color = util.color.rgb(0,0,0)
			return
		end
		
		if elem.userData.focus == 2 then
			background.props.color = fontColor
		elseif elem.userData.focus == 1 then
			background.props.color = morrowindGold
		else
			background.props.color = util.color.rgb(0,0,0)
		end
		attributeSelectionDialogue:update()
	end
	
	clickbox.events = {
		mouseRelease = async:callback(function(_, elem)
			elem.userData.focus = elem.userData.focus - 1
			if attributeButtonFocus == "confirmButton" and selectedAttribute then
				onFrameFunctions["confirmAttributeButton"] = function()
					applyColor(elem)
					if attributeSelectionDialogue and attributeButtonFocus == "confirmButton" then
						attributeSelectionDialogue:destroy()
						attributeSelectionDialogue = nil
						attributeSelectionReturn(selectedAttribute) -- Callback mit dem ausgewählten Attribut
					end
					onFrameFunctions["confirmAttributeButton"] = nil
				end
			end
		end),
		focusGain = async:callback(function(_, elem)
			attributeButtonFocus = "confirmButton"
			elem.userData.focus = elem.userData.focus + 1
			applyColor(elem)
		end),
		focusLoss = async:callback(function(_, elem)
			attributeButtonFocus = nil
			elem.userData.focus = 0
			applyColor(elem)
		end),
		mousePress = async:callback(function(_, elem)
			elem.userData.focus = elem.userData.focus + 1
			applyColor(elem)
		end),
	}
	
	box.content:add(clickbox)

	
	return box
end

flex.content:add(makeConfirmButton())
flex.content:add{ props = { size = v2(1, 1) * 2 } }