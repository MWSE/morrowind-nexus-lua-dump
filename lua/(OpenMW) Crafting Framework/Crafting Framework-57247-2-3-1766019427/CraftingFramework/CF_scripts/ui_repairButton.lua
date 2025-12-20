-- Prüfen ob repairButton bereits existiert und zerstören
if repairButton then
    repairButton:destroy()
    repairButton = nil
end

-- Button Setup
local makeBorder = require("CF_scripts.ui_makeborder") 
local borderOffset = 1
local borderFile = "thin"
local textSize = 21

local borderTemplate = makeBorder(borderFile, nil, borderOffset, {
    type = ui.TYPE.Image,
    props = {
        resource = background,
        relativeSize = v2(1,1),
        alpha = 0.8,
    }
}).borders

-- Unique ID für den Button
local uniqueButtonId = "repairButton_" .. math.random()
local buttonFocus = nil

-- Button erstellen
repairButton = ui.create({
    type = ui.TYPE.Widget,
    layer = 'Modal',
    name = "repairButton",
    template = borderTemplate,
    props = {
        relativePosition = v2(0.5, 0.68),
        anchor = v2(0.5, 0.5),
        size = v2(200, textSize*1.5),
    },
    content = ui.content {}
})

-- Hintergrund
local background = {
    name = 'background',
    type = ui.TYPE.Image,
    props = {
        relativeSize = v2(1, 1),
        resource = getTexture('white'),
        color = util.color.rgb(0,0,0),
        alpha = 0.7,
    },
}
repairButton.layout.content:add(background)

-- Text
repairButton.layout.content:add({
    name = 'text',
    type = ui.TYPE.Text,
    props = {
        relativePosition = v2(0.5, 0.5),
        anchor = v2(0.5, 0.5),
        text = "Crafting UI",
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
    if repairButton then
        if elem.userData.focus == 2 then
            background.props.color = textColor -- Gedrückt
        elseif elem.userData.focus == 1 then
            background.props.color = morrowindGold -- Hover
        else
            background.props.color = util.color.rgb(0, 0, 0) -- Normal
        end
        repairButton:update()
    end
end

-- Clickbox für Interaktion
repairButton.layout.content:add({
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
                    if repairButton and buttonFocus == uniqueButtonId then
                       	tempInventory = nil
						skillChanged = true 
						updateRecipeAvailability(filterRecipes)
						require("CF_scripts.ui_craftingWindow")
						I.UI.setMode('Interface', {windows = {'Map', 'Stats', 'Magic', 'Inventory'}})
                        updateButtonColor(elem)
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