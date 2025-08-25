if chargenDialogue then
	chargenDialogue:destroy()
	chargenDialogue = nil
end


local makeBorder = require("scripts.Roguelite.ui_makeborder") ------------------------
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
local darkerFont = getColorFromGameSettings("FontColor_color_normal")
local hoverColor = util.color.rgb(fontColor.r*0.3,fontColor.g*0.3,fontColor.b*0.3)
local statColor = mixColors(fontColor,darkerFont)
local yesFocus = 0
local noFocus = 0
local finishedChargen = nil
local fontSize = 16
local background = ui.texture { path = 'black' }
----------------------------------------------------------------------------------------------------------


local function makeIcon(enchBackground, icon, innerText, props)
	local iconBox ={
		template = borderTemplate,
		props = props,
		content = ui.content{}
	}
	
	if enchBackground then 
		--ENCHANT ICON
		table.insert(iconBox.content, {
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("textures\\menu_icon_magic_mini.dds"),
				tileH = false,
				tileV = false,
				relativeSize = v2(1,1),
				alpha = 0.7,
			}
		})			
	end
	-- ITEM ICON
	table.insert(iconBox.content, {
		type = ui.TYPE.Image,
		props = {
			resource = getTexture(icon),
			tileH = false,
			tileV = false,
			relativeSize = v2(1,1),
			alpha = 0.7,
		}
	})
	if innerText then
		table.insert(iconBox.content,{
			type = ui.TYPE.Text,
			name = 'inner',
			props = {
				relativePosition = util.vector2(0, 1),
				relativeSize = util.vector2(1, 0.5),
				anchor = util.vector2(0, 1),
				text = ""..innerText,
				textColor = fontColor,--util.color.rgba(1, 1, 1, 1),
				--textAlignH = ui.ALIGNMENT.Center,
				textSize = 19,
			}
		})
	end
	return iconBox
end

local function makeAttributeSkillIcon(iconPath)
    local iconSize = 24
    local iconBorderTemplate = makeBorder(borderFile, nil, 1, {
        type = ui.TYPE.Image,
        props = {
            relativeSize = v2(1,1),
            alpha = 0.9,
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
            color = util.color.rgb(0.2, 0.2, 0.3),
            alpha = 0.8,
        },
    }
    
    -- Attribute/Skill Icon
    iconBox.content:add{
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = iconPath },
            relativeSize = v2(1, 1),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            alpha = 0.9,
            size = v2(-2,-2)
        }
    }
    
    return iconBox
end

local function textElement(str, color)
	return { 
		type = ui.TYPE.Text,
		template = tooltipText,
		props = {
			textColor = color or fontColor,--util.color.rgba(1, 1, 1, 1),
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,0.75),
			textAlignV = ui.ALIGNMENT.Center,
			textAlignH = ui.ALIGNMENT.Center,
			
			text = " "..str.." ",
			textSize = fontSize,
			autoSize = true
		},
	}
end

local function makeAttributeSkillRow(name, currentValue, newValue, iconPath)
    local rowFlex = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(270, fontSize*1.5),
        },
        content = ui.content {}
    }
    
    -- Icon
    local icon = makeAttributeSkillIcon(iconPath)
    icon.props.relativePosition = v2(0, 0.5)
    icon.props.anchor = v2(0, 0.5)
    rowFlex.content:add(icon)
    
    -- Name (fixed position)
    local nameText = textElement(name..":", statColor)
    nameText.props.relativePosition = v2(0, 0.5)
    nameText.props.anchor = v2(0, 0.5)
    nameText.props.position = v2(22, 0)
    nameText.props.size = v2(140, fontSize*1.5)
    nameText.props.textAlignH = ui.ALIGNMENT.Start
    rowFlex.content:add(nameText)
    
    -- Current Value (fixed position)
    local currentText = textElement(tostring(currentValue),  statColor)
    currentText.props.relativePosition = v2(0, 0.5)
    currentText.props.anchor = v2(0, 0.5)
    currentText.props.position = v2(162, 0)
    currentText.props.size = v2(40, fontSize*1.5)
    currentText.props.textAlignH = ui.ALIGNMENT.End
    rowFlex.content:add(currentText)
	
	-- sep
    local currentText = textElement(tostring(">"), statColor)
    currentText.props.relativePosition = v2(0, 0.5)
    currentText.props.anchor = v2(0, 0.5)
    currentText.props.position = v2(184, 0)
    currentText.props.size = v2(40, fontSize*1.5)
    currentText.props.textAlignH = ui.ALIGNMENT.End
    rowFlex.content:add(currentText)
    
    -- New Value (fixed position)
	local tempColor
	if newValue < currentValue then
		tempColor = util.color.rgb(0.8, 0.4, 0.4)
	elseif newValue > currentValue then
		tempColor = util.color.rgb(0.4, 0.8, 0.4)
	end
    local newText = textElement(tostring(newValue), tempColor)
    newText.props.relativePosition = v2(0, 0.5)
    newText.props.anchor = v2(0, 0.5)
    newText.props.position = v2(199, 0)
    newText.props.size = v2(40, fontSize*1.5)
    newText.props.textAlignH = ui.ALIGNMENT.End
    rowFlex.content:add(newText)
    
    return rowFlex
end

---------------------------------------------------------------------------------------------------------------------------------------------- DIALOGUE ----------------------------------------------------------------------------------------------------------------------------------------------

local layerId = ui.layers.indexOf("HUD")
local screenSize = ui.layers[layerId].size
local containerSize = v2(screenSize.x * 0.15, screenSize.y * 0.1)

local borderTemplate = makeBorder(borderFile, borderColor or nil, borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = background,
		relativeSize  = v2(1,1),
		alpha = 0.5,
	}
}).borders

--root
chargenDialogue = ui.create({
	type = ui.TYPE.Container,
	layer = 'Modal',
	name = "rogueliteChargenDialogue",
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
chargenDialogue.layout.content:add(flex)
flex.content:add{ props = { size = v2(1, 1) * 1 } }
flex.content:add(textElement("Start roguelite run?"))
local flexTable = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'mainFlex',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
		horizontal = true,
	},
	content = ui.content {
	}
}
flex.content:add(flexTable)

local attributeFlex = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'attributeFlex',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
	},
	content = ui.content {
	}
}
flexTable.content:add(attributeFlex)

for _, attributeRecord in pairs(core.stats.Attribute.records) do
	local iconPath = attributeRecord.icon or "icons\\default_attribute.dds"
	local currentValue = types.NPC.stats.attributes[attributeRecord.id](self).base
	local newValue = math.floor(currentValue * playerSection:get("ATTRIBUTE_MULT")) - math.floor(playerSection:get("ATTRIBUTE_SUBTRACT"))
	
	attributeFlex.content:add(makeAttributeSkillRow(attributeRecord.name, currentValue, newValue, iconPath))
end

local skillFlex = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'skillFlex',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
	},
	content = ui.content {
	}
}
flexTable.content:add(skillFlex)

-- Get class information
local classId = types.NPC.record(self).class
local classRecord = types.NPC.classes.records[classId]
local majorSkills = classRecord.majorSkills
local minorSkills = classRecord.minorSkills

-- Create sets for easier lookup
local majorSkillSet = {}
local minorSkillSet = {}
for _, skillId in ipairs(majorSkills) do
	majorSkillSet[skillId] = true
end
for _, skillId in ipairs(minorSkills) do
	minorSkillSet[skillId] = true
end

for _, skillId in pairs(majorSkills) do
	local skillRecord = core.stats.Skill.records[skillId]
	local iconPath = skillRecord.icon or "icons\\default_skill.dds"
	local currentValue = types.NPC.stats.skills[skillId](self).base
	local newValue = math.floor(currentValue * playerSection:get("SKILL_MULT")) - math.floor(playerSection:get("SKILL_SUBTRACT"))
	
	skillFlex.content:add(makeAttributeSkillRow(skillRecord.name, currentValue, newValue, iconPath))
end

skillFlex.content:add{ props = { size = v2(1, 12) } }

for _, skillId in pairs(minorSkills) do
	local skillRecord = core.stats.Skill.records[skillId]
	local iconPath = skillRecord.icon or "icons\\default_skill.dds"
	local currentValue = types.NPC.stats.skills[skillId](self).base
	local newValue = math.floor(currentValue * playerSection:get("SKILL_MULT")) - math.floor(playerSection:get("SKILL_SUBTRACT"))
	
	skillFlex.content:add(makeAttributeSkillRow(skillRecord.name, currentValue, newValue, iconPath))
end

skillFlex.content:add{ props = { size = v2(1, 12) } }


for _, skillRecord in pairs(core.stats.Skill.records) do
	local skillId = skillRecord.id
	if not majorSkillSet[skillId] and not minorSkillSet[skillId] then
		local iconPath = skillRecord.icon or "icons\\default_skill.dds"
		local currentValue = types.NPC.stats.skills[skillId](self).base
		local newValue = math.floor(currentValue * playerSection:get("SKILL_MULT")) - math.floor(playerSection:get("SKILL_SUBTRACT"))
		
		skillFlex.content:add(makeAttributeSkillRow(skillRecord.name, currentValue, newValue, iconPath))
	end
end

local buttonsFlex ={
	type = ui.TYPE.Flex,
	name = "buttonsFlex",
	props = {
		--position = v2(0, 0),
		--size = v2(0,20),
		--anchor = v2(0.5,0),
		--relativePosition = v2(0.5, 0),
		horizontal = true,
	},
	content = ui.content({})
}
flex.content:add(buttonsFlex)


local function makeButton(data)
			--elemId = "yesButton",
			--caption = core.getGMST("sYes"),
			--hoverColor = util.color.rgb(0.5,1,0.5),
			--func = function()
	local borderTemplate = makeBorder(borderFile, nil, borderOffset, {
		type = ui.TYPE.Image,
		props = {
			relativeSize  = v2(1,1),
			alpha = 0.1,
		}
	}).borders
	local box = 
	{
		name = data.elemId,
		type = ui.TYPE.Widget,
		props = {
			size = v2(100, fontSize*1.5),
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
			color = util.color.rgb(0, 0, 0),
			alpha = .75,
		},
	}
	box.content:add(background)
	
	box.content:add{
		name = 'text',
		type = ui.TYPE.Text,
		props = {
			--relativeSize = util.vector2(1, 1),
			relativePosition = v2(0.5,0.5),
			anchor = v2(0.5,0.5),
			text = data.caption,
			textColor = fontColor,
			textSize = fontSize,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
		},
	}
	local function applyColor(elem)
		if elem.userData.focus == 2 then
			background.props.color = data.hoverColor
		elseif elem.userData.focus == 1 then
			background.props.color = hoverColor
		else
			background.props.color = util.color.rgb(0, 0, 0)
		end
		chargenDialogue:update()
	end
	local clickbox = { -- no clickbox
		name = 'clickbox',
		props = 
		{ 
			relativeSize = util.vector2(1, 1),
			relativePosition = v2(0,0),
			anchor = v2(0,0),
		},
		userData = {
			focus = 0
		},
	}
	clickbox.events = {
			mouseRelease = async:callback(function(_,elem)
				elem.userData.focus = elem.userData.focus -1
				applyColor(elem)
				onFrameFunctions[data.elemId] = data.func
			end),
			focusGain = async:callback(function(_,elem)
				buttonFocus = data.elemId
				elem.userData.focus = elem.userData.focus +1
				applyColor(elem)
			end),
			focusLoss = async:callback(function(_,elem)
				buttonFocus = nil
				elem.userData.focus = 0
				applyColor(elem)
			end),
			
			mousePress = async:callback(function(_,elem)
				elem.userData.focus = elem.userData.focus +1
				applyColor(elem)
			end),
		},
	box.content:add(clickbox)
	return box
end

buttonsFlex.content:add{ props = { size = v2(1, 1) * 4 } }
local buttonId = "yesButton"
buttonsFlex.content:add(makeButton{
			elemId = buttonId,
			caption = "Yes",
			hoverColor = util.color.rgb(0.15,0.7,0.15),
			func = function(clickbox)
				if chargenDialogue and buttonFocus == buttonId then
					chargenDialogue:destroy()
					chargenDialogue = nil
					chargenDialogueReturn(buttonId)
				end
				onFrameFunctions[buttonId] = nil
			end
		})
buttonsFlex.content:add{ props = { size = v2(1, 1) * 4 } }
local buttonId = "noButton"
buttonsFlex.content:add(makeButton{
			elemId = buttonId,
			caption = "Not yet",
			hoverColor = util.color.rgb(0.7,0.5,0.5),
			func = function(clickbox)
				if chargenDialogue and buttonFocus == buttonId then
					chargenDialogue:destroy()
					chargenDialogue = nil
					chargenDialogueReturn(buttonId)
				end
				onFrameFunctions[buttonId] = nil
			end
		})

buttonsFlex.content:add{ props = { size = v2(1, 1) * 4 } }
local buttonId = "neverButton"
buttonsFlex.content:add(makeButton{
			elemId = buttonId,
			caption = "No",
			hoverColor = util.color.rgb(0.7,0.15,0.15),
			func = function(clickbox)
				if chargenDialogue and buttonFocus == buttonId then
					chargenDialogue:destroy()
					chargenDialogue = nil
					chargenDialogueReturn(buttonId)
				end
				onFrameFunctions[buttonId] = nil
			end
		})

buttonsFlex.content:add{ props = { size = v2(1, 1) * 5 } }
flex.content:add{ props = { size = v2(1, 1) * 5 } }