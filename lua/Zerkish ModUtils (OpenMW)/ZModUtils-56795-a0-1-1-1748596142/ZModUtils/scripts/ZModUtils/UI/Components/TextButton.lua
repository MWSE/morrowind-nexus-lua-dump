local async     = require('openmw.async')
local ambient   = require('openmw.ambient')
local ui        = require('openmw.ui')
local util      = require('openmw.util')
local MWUI      = require('openmw.interfaces').MWUI

local constants = require('scripts.omw.mwui.constants')

local ZHIUI_CONSTANTS = {
    ButtonTextHPadding = 8,
    VScrollbarSize = 14,

    MenuClickSound = 'menu click',

    MessageBox = {
        HeaderHeight = 28,
    }
}

local function createTextButton(params)
    if not params then return end

    local text      = params.text
    local textSize  = params.textSize
    local callback  = params.callback

    local textLayout = {
        type = ui.TYPE.Text,
        name = 'textItem',
        props = {
            propagateEvents = true,
            textSize = textSize and textSize or 18,
            textColor = constants.normalColor,
            text = text,
        },
    }

    local template = {
        type = ui.TYPE.Container,
        props = {
            propagateEvents = true,
        },
        content = ui.content {
            {
                props = {
                    propagateEvents = true,
                    size = util.vector2(ZHIUI_CONSTANTS.ButtonTextHPadding, 1),
                }
            },
            {
                external = { slot = true },
                props = 
                {
                    position = util.vector2(ZHIUI_CONSTANTS.ButtonTextHPadding, 0),
                    relativeSize = util.vector2(1, 1),
                },
            },
            {
                props = {
                    position = util.vector2(ZHIUI_CONSTANTS.ButtonTextHPadding, 1);
                    size = util.vector2(ZHIUI_CONSTANTS.ButtonTextHPadding, 1),
                    relativePosition = util.vector2(1, 1),
                }
            },
        }
    }

    local focusGainHandler = function(unused, layout)
        if layout.userData then
            layout.userData.textLayout.props.textColor = constants.headerColor 
            if layout.userData.element then
                layout.userData.element:update()
            end
        end

        return false
    end

    local focusLostHandler = function(unused, layout)
        if layout.userData then
            layout.userData.textLayout.props.textColor = constants.normalColor end
            if layout.userData.element then
                layout.userData.element:update()
            end
        return false
    end

    local mousePressHandler = function(mouseEvent, layout)
        if layout.userData then
            layout.userData.textLayout.props.textColor = util.color.rgb(1, 1, 1)
            if layout.userData.element then
                layout.userData.element:update()
            end
        end
        ambient.playSound(ZHIUI_CONSTANTS.MenuClickSound)
        return false
    end

    local mouseReleaseHandler = function(mouseEvent, layout)
        if layout.userData then
            layout.userData.textLayout.props.textColor = constants.headerColor
            if layout.userData.element then
                layout.userData.element:update()
            end
        end

        -- call the callback with parent instead, since from the outside perspective
        -- that's the layout you created.
        if type(callback) == 'function' then callback(mouseEvent, layout.userData.parent) end

        return false
    end

    local buttonLayout = {
        template = MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        --userData = textLayout,
        props = {
            propagateEvents = false,
        },
        -- userData = {
        --     textLayout  = textLayout
        -- },        
        -- events = {
        --     mousePress      = async:callback(mousePressHandler),
        --     mouseRelease    = async:callback(mouseReleaseHandler),
        --     focusGain       = async:callback(focusGainHandler),
        --     focusLoss       = async:callback(focusLostHandler),
        -- }
    }

    local button = ui.create(buttonLayout)
    --button.layout.userData.element = button

    buttonLayout.content = ui.content({
        {
            template = template,
            type = ui.TYPE.Container,
            content = ui.content({ textLayout }),
            props = {
                propagateEvents = true,
            },
            userData = {
                textLayout = textLayout,
                element = button,
                parent = buttonLayout,
            },
            events = {
                mousePress      = async:callback(mousePressHandler),
                mouseRelease    = async:callback(mouseReleaseHandler),
                focusGain       = async:callback(focusGainHandler),
                focusLoss       = async:callback(focusLostHandler),
            }
        }
    })

    button:update()
    return button
end

local lib = {
    create = createTextButton,

    getElementFromLayout = function(layoutFromEventHandler)
        if (not layoutFromEventHandler) or (not layoutFromEventHandler.userData) then return end
        
        return layoutFromEventHandler.userData.element
    end,

    setText = function(buttonElement, newText)
        if (not buttonElement) or (not buttonElement.layout) then return end
        if #buttonElement.layout.content < 0 then return end

        local inner = buttonElement.layout.content[1]
        if (not inner) or (not inner.userData) then return end

        if inner.userData.textLayout then
            inner.userData.textLayout.props.text = newText

            if inner.userData.element then
                inner.userData.element:update()
            end
        end
    end,
}

return lib