local I = require('openmw.interfaces')
local types = require('openmw.types')
local self = require('openmw.self')
local Player = require('openmw.types').Player
local core = require('openmw.core')
local self = require('openmw.self')
local ambient = require('openmw.ambient')
local input = require('openmw.input')
local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')
local v2 = util.vector2


local yesFocus = 0
local noFocus = 0
local asyncYes = nil
local asyncNo = nil
local currentBook = nil

local textureCache = {}

local function getTexture(path)
	if not textureCache[path] then
		textureCache[path] = ui.texture{path = path}
	end
	return textureCache[path]
end

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
local fontColor = getColorFromGameSettings("FontColor_color_normal_over")
local darkerFont = util.color.rgb(fontColor.r*0.3,fontColor.g*0.3,fontColor.b*0.3)

---------------------------------------------------------------------------------------------------------------------------------------------- UI ----------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------- UI ----------------------------------------------------------------------------------------------------------------------------------------------

local function applyYesColor()
	if yesFocus > 2 then
		--print("error focus")
	elseif yesFocus == 2 then
		dia.layout.content.yesBox.props.color = util.color.rgb(darkerFont.r*0.9,math.min(1,darkerFont.g+0.2),darkerFont.b*0.9)
	elseif yesFocus == 1 then
		dia.layout.content.yesBox.props.color = darkerFont
	else
		dia.layout.content.yesBox.props.color = util.color.rgb(0, 0, 0)
	end
	dia:update()
end

local function applyNoColor()
	if noFocus > 2 then
		--print("error focus")
	elseif noFocus == 2 then
		dia.layout.content.noBox.props.color = util.color.rgb(math.min(1,darkerFont.r+0.2),darkerFont.g*0.9,darkerFont.b*0.9)
	elseif noFocus == 1 then
		dia.layout.content.noBox.props.color = darkerFont
	else
		dia.layout.content.noBox.props.color = util.color.rgb(0, 0, 0)
	end
	dia:update()
end

local function yes()
if not dia then return end
	asyncYes = true
	yesFocus = 0
	applyYesColor()
end

local function no()
if not dia then return end
	asyncNo = true
	noFocus = 0
	applyNoColor()
end

local function yesPress()
--print("yesPress")
focus = "yes"
yesFocus = yesFocus + 1
applyYesColor()
end
local function noPress()
--print("noPress")
focus = "no"
noFocus = noFocus + 1
applyNoColor()
end

local function yesFocusGain()
--print("yesGain")
focus = "yes"
yesFocus = yesFocus + 1
applyYesColor()
end
local function noFocusGain()
--print("noGain")
focus = "no"
noFocus = noFocus +1
applyNoColor()
end

local function yesFocusLoss()
--print("yesLoss")
focus = nil
yesFocus = 0
applyYesColor()
end
local function noFocusLoss()
--print("noLoss")
focus = nil
noFocus = 0
applyNoColor()
end



---------------------------------------------------------------------------------------------------------------------------------------------- DIALOGUE ----------------------------------------------------------------------------------------------------------------------------------------------

local function makeDialogue()
	local book = currentBook
	local itemName = book.type.record(book).name
	local layerId = ui.layers.indexOf("HUD")
	local screenSize = ui.layers[layerId].size
	local containerSize = v2(screenSize.x * 0.15, screenSize.y * 0.1)
	dia = ui.create {
		template = I.MWUI.templates.borders,
		layer = 'Modal',
		props = {
			size = containerSize,
			anchor = util.vector2(0.5, 0),
			position =v2(screenSize.x * 0.5, screenSize.y * 0.45),
		},
		
		userData = {isPressed = false},
		
		content = ui.content {
			{
				name = 'background',
				type = ui.TYPE.Image,
				props = {
					relativeSize = util.vector2(1, 1),
					resource = ui.texture { path = 'white' },
					color = util.color.rgb(0, 0, 0),
					alpha = 0.8,
				},
			},
			{
				name = 'questionText',
				type = ui.TYPE.Text,
				props = {
					relativePosition = util.vector2(0.5, 0.1),
					anchor = util.vector2(.5, .5),
					text = "Continue Reading?",
					textColor = fontColor,
					textSize = 18,
				}
			},
			{
				name = 'yesBox',
				template = borderTemplate,
				type = ui.TYPE.Image,
				props = {
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.25,0.85),
					anchor = v2(0.5,0.5),
					resource = ui.texture { path = 'white' },
					color = util.color.rgb(0, 0, 0),
					alpha = .75,
				},
			},
			{
				name = 'yesText',
				type = ui.TYPE.Text,
				props = {
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.25,0.85),
					anchor = v2(0.5,0.5),
					text =core.getGMST("sYes"),
					textColor = fontColor,
					textSize = 18,
					textAlignH = ui.ALIGNMENT.Center,
					textAlignV = ui.ALIGNMENT.Center,
				},
			},
			{
				name = 'noBox',
				template = borderTemplate,
				type = ui.TYPE.Image,
				props = {
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.75,0.85),
					anchor = v2(0.5,0.5),
					resource = ui.texture { path = 'white' },
					color = util.color.rgb(0, 0, 0),
					alpha = .75,
				},
			},
			{
				name = 'noText',
				type = ui.TYPE.Text,
				props = {
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.75,0.85),
					anchor = v2(0.5,0.5),
					text = core.getGMST("sNo"),
					textColor = fontColor,
					textSize = 18,
					textAlignH = ui.ALIGNMENT.Center,
					textAlignV = ui.ALIGNMENT.Center,
				},
			},
			{ -- yes clickbox
				props = 
				{ 
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.75,0.85),
					anchor = v2(0.5,0.5),
				},
				events = {
					mouseRelease = async:callback(no),
					focusGain = async:callback(noFocusGain),
					focusLoss = async:callback(noFocusLoss),
					mousePress = async:callback(noPress),
				},
			},
			{ -- no clickbox
				props = 
				{ 
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.25,0.85),
					anchor = v2(0.5,0.5),
				},
				events = {
					mouseRelease = async:callback(yes),
					focusGain = async:callback(yesFocusGain),
					focusLoss = async:callback(yesFocusLoss),
					mousePress = async:callback(yesPress),
				},
			}
		},
	}
	local function makeIcon(enchBackground, icon, innerText, props)

		local iconBox ={
			template = I.MWUI.templates.borders,
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
	local bookRecord = book.type.record(book)
	local icon = bookRecord.icon
	dia.layout.content:add(makeIcon(nil, icon, nil, {
			position = v2(containerSize.x * 0.5,containerSize.y * 0.5),
			size = v2(containerSize.y * 0.4,containerSize.y * 0.4),
			anchor = v2(0.5,0.5)
		}))


end


---------------------------------------------------------------------------------------------------------------------------------------------- LOGIC ----------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------- LOGIC ----------------------------------------------------------------------------------------------------------------------------------------------

local function onFrame(dt)
	if dia then
		if asyncYes and focus == "yes" then
			print("yesss")
			dia:destroy()
			dia = nil
			currentBook = nil
		elseif asyncNo and focus == "no" then
			print("nooo")
			dia:destroy()
			dia = nil
			currentBook = nil
			I.UI.setMode()
		end
		asyncYes = nil
		asyncNo = nil
	end
end



local function UiModeChanged(data)
	if (data.newMode == "Book" or data.newMode == "Scroll") and data.arg then
		currentBook = data.arg
		makeDialogue()
	elseif (data.oldMode == "Book" or data.oldMode == "Scroll") and currentBook then
		currentBook = nil
		if dia then 
			dia:destroy()
			dia = nil
		end
	end
end



return {
	engineHandlers = { 
		onFrame = onFrame,
	},
	eventHandlers = { 
		UiModeChanged = UiModeChanged,
	}
}