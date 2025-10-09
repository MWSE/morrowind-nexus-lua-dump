-- Prüfen ob deletedDialogue bereits existiert und zerstören
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local v2 = util.vector2
local I = require('openmw.interfaces')
local async = require('openmw.async')

deletedText = deletedText or {"Character perished"}
local maxTextLength = 1
for _, text in pairs(deletedText) do
	maxTextLength = math.max(maxTextLength, #text)
end

-- Button Setup
--local makeBorder = require("CF_scripts.ui_makeborder") 
local borderOffset = 1
local borderFile = "thin"
local textSize = 21

--local borderTemplate = makeBorder(borderFile, nil, borderOffset, {
--    type = ui.TYPE.Image,
--    props = {
--        resource = background,
--        relativeSize = v2(1,1),
--        alpha = 0.8,
--    }
--}).borders

-- Unique ID für den Button
local uniqueButtonId = "deletedDialogue_" .. math.random()
local buttonFocus = nil


-- Color utility functions
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



local textColor = getColorFromGameSettings("fontColor_color_normal_over")
local lightText = util.color.rgb(textColor.r^0.5,textColor.g^0.5,textColor.b^0.5)
local morrowindGold = getColorFromGameSettings("fontColor_color_normal")

-- Button erstellen
local deletedDialogue = ui.create({
    type = ui.TYPE.Widget,
    layer = 'Modal',
    name = uniqueButtonId,
    template =  I.MWUI.templates.borders,
    props = {
        relativePosition = v2(0.5, 0.68),
        anchor = v2(0.5, 0.5),
        size = v2(textSize*maxTextLength*0.6, textSize*1.25*#deletedText+2),
    },
    content = ui.content {}
})

-- Hintergrund
local background = {
    name = 'background',
    type = ui.TYPE.Image,
    props = {
        relativeSize = v2(1, 1),
        resource = ui.texture { path = "white" },
        color = util.color.rgb(0,0,0),
        alpha = 0.7,
    },
}
deletedDialogue.layout.content:add(background)
local flex ={		 
			name = 'flex',
			type = ui.TYPE.Flex,
			props = {
				--position = v2(cornerMargin + horizontalOffset, -cornerMargin + verticalOffset),
				--anchor = v2(0, 1),
				--relativePosition = v2(0, 1),
				arrange = ui.ALIGNMENT.Start,
				horizontal = false,
				visible = true,
			},
			content = ui.content{}
}
deletedDialogue.layout.content:add(flex)

-- Text
for _, text in pairs(deletedText) do

	flex.content:add({
		name = 'text',
		type = ui.TYPE.Text,
		props = {
			--relativePosition = v2(0.5, 0.5),
		-- anchor = v2(0.5, 0.5),
			text =text,
			textColor = textColor,
			textShadow = true,
			textShadowColor = util.color.rgb(0, 0, 0),
			textSize = textSize,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
			size = v2(textSize*maxTextLength*0.6, textSize*1.25),
		},
	})
end
-- Funktion für Farbaktualisierung
local function updateButtonColor(elem)
    if deletedDialogue then
        if elem.userData.focus == 2 then
            background.props.color = textColor -- Gedrückt
        elseif elem.userData.focus == 1 then
            background.props.color = morrowindGold -- Hover
        else
            background.props.color = util.color.rgb(0, 0, 0) -- Normal
        end
        deletedDialogue:update()
    end
end

-- Clickbox für Interaktion
deletedDialogue.layout.content:add({
    name = 'clickbox',
    props = {
        relativeSize = v2(1, 1),
        relativePosition = v2(0, 0),
        anchor = v2(0, 0),
    },
    userData = {
        focus = 0
    },
    events = {
        mouseRelease = async:callback(function(_, elem)
            --elem.userData.focus = elem.userData.focus - 1
            --if buttonFocus == uniqueButtonId then
            --    onFrameFunctions[uniqueButtonId] = function()
            --        if deletedDialogue and buttonFocus == uniqueButtonId then
            --           	tempInventory = nil
			--			updateRecipeAvailability()
			--			require("CF_scripts.ui_craftingWindow")
			--			I.UI.setMode('Interface', {windows = {'Map', 'Stats', 'Magic', 'Inventory'}})
            --            updateButtonColor(elem)
            --        end
            --        onFrameFunctions[uniqueButtonId] = nil
            --    end
            --end
			deletedDialogue:destroy()
        end),
        mousePress = async:callback(function(_, elem)
            elem.userData.focus = elem.userData.focus + 1
            updateButtonColor(elem)
        end),
        focusGain = async:callback(function(_, elem)
            buttonFocus = uniqueButtonId
            elem.userData.focus = elem.userData.focus + 1
            updateButtonColor(elem)
        end),
        focusLoss = async:callback(function(_, elem)
            buttonFocus = nil
            elem.userData.focus = 0
            updateButtonColor(elem)
        end),
    }
})