-- Prüfen ob consumeAllButton bereits existiert und zerstören
if consumeAllButton then
    consumeAllButton:destroy()
    consumeAllButton = nil
end

-- Button Setup
local makeBorder = require("scripts.Disenchanting_makeborder") 
local borderOffset = 1
local borderFile = "thin"
local textSize = 18
local textColor = getColorFromGameSettings("fontColor_color_normal_over")
local morrowindGold = getColorFromGameSettings("fontColor_color_normal")
local ui = require('openmw.ui')
local util = require('openmw.util')
local v2 = util.vector2
local async = require('openmw.async')
local core = require('openmw.core')
local self = require('openmw.self')


local borderTemplate = makeBorder(borderFile, util.color.rgb(0.6,0.6,0.6), borderOffset, {
    type = ui.TYPE.Image,
    props = {
        resource = background,
        relativeSize = v2(1,1),
        alpha = 0.8,
    }
}).borders

-- Unique ID für den Button
local uniqueButtonId = "consumeAllButton_" .. math.random()
local buttonFocus = nil
local layerId = ui.layers.indexOf("HUD")
local screenSize = ui.layers[layerId].size
local containerSize = v2(screenSize.x * 0.15, screenSize.y * 0.1)
local position = v2(screenSize.x * 0.5, screenSize.y * 0.45+containerSize.y)

-- Button erstellen
consumeAllButton = ui.create({
    type = ui.TYPE.Widget,
    layer = 'Modal',
    name = "consumeAllButton",
    template = borderTemplate,
    props = {
        position = position,
        anchor = v2(0.5, 0),
        size = v2(150, textSize*1.5),
    },
    content = ui.content {}
})

-- Hintergrund
local background = {
    name = 'background',
    type = ui.TYPE.Image,
    props = {
        relativeSize = v2(1, 1),
        resource = ui.texture { path = 'white' },
        color = util.color.rgb(0,0,0),
        alpha = 0.75,
    },
}
consumeAllButton.layout.content:add(background)

-- Text
consumeAllButton.layout.content:add({
    name = 'text',
    type = ui.TYPE.Text,
    props = {
        relativePosition = v2(0.5, 0.5),
        anchor = v2(0.5, 0.5),
        text = "Consume All",
        textColor = textColor,
        textShadow = true,
        textShadowColor = util.color.rgb(0, 0, 0),
        textSize = textSize,
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
    },
})

-- Funktion für Farbaktualisierung
local function updateButtonColor(elem)
    if consumeAllButton then
        if elem.userData.focus == 2 then
            background.props.color = textColor -- Gedrückt
        elseif elem.userData.focus == 1 then
            background.props.color = morrowindGold -- Hover
        else
            background.props.color = util.color.rgb(0, 0, 0) -- Normal
        end
        consumeAllButton:update()
    end
end

-- Clickbox für Interaktion
consumeAllButton.layout.content:add({
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
            elem.userData.focus = elem.userData.focus - 1
            if buttonFocus == uniqueButtonId then
                onFrameFunctions[uniqueButtonId] = function()
                    if consumeAllButton and buttonFocus == uniqueButtonId then
                       	core.sendGlobalEvent("disenchanting_consumeAll", self)
						consumeAllButton:destroy()
						consumeAllButton = nil
						if dia then
							dia:destroy()
							dia = nil
						end
                    end
                    onFrameFunctions[uniqueButtonId] = nil
                end
            end
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