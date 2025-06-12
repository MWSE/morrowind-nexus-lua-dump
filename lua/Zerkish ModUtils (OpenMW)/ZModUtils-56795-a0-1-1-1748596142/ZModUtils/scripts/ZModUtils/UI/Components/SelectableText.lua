local ambient = require('openmw.ambient')
local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')

local constants = require('scripts.omw.mwui.constants')

local ZConstants = require('scripts.ZModUtils.UI.Constants')

local function createSelectableLine(params)
    assert(params)

    local size = params.size
    local lineText = params.text and params.text or ""
    local textSize = params.textSize and params.textSize or 16
    local textColor = params.textColor and params.textColor or constants.normalColor
    local textHoverColor = params.textHoverColor and params.textHoverColor or constants.headerColor
    local textPressColor = params.textPressColor and params.textPressColor or util.color.rgb(0.95, 0.95, 0.95)
    local events = params.events and params.events or {}
    local userData = params.userData

    local textLayout = {
        type = ui.TYPE.Text,
        props = {
            propagateEvents = true,
            --propagateEvents = true,
            text = lineText,
            textSize = textSize,
            textColor = textColor,
        },
    }

    local lineLayout = {
        type = ui.TYPE.Flex,
        props = {
            propagateEvents = false,
            autoSize = false,
            size = size,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content({
            -- Text
            textLayout
        }),
    }

    local textHandle = textLayout
    local hasFocus = false

    local function onMouseMove(evt, layout)
        if events and events.mouseMove then
            events.mouseMove(evt, lineLayout)
        end
    end

    local function onMousePress(evt, layout)
        if textHandle and hasFocus then
            textHandle.props.textColor = textPressColor
            layout.userData.element:update()
        end
        ambient.playSound(ZConstants.ButtonClickSound)
        return false
    end

    local function onMouseRelease(evt, layout)
        if textHandle then
            if hasFocus then
                textHandle.props.textColor = textHoverColor
            else
                textHandle.props.textColor = textColor
            end

            -- Check that we're in bounds after releasing the button.
            if (evt.offset.x >= 0 and evt.offset.x <= size.x) and
                (evt.offset.y >= 0 and evt.offset.y <= size.y) then                
                if events and events.mouseRelease then events.mouseRelease(evt, lineLayout.userData.parent) end
            end

            layout.userData.element:update()
        end
        return false
    end

    local function onFocusGain(_, layout)
        hasFocus = true
        if textHandle then
            textHandle.props.textColor = textHoverColor
            if events and events.focusGain then events.focusGain(_, lineLayout) end
            layout.userData.element:update()
        end
        return false
    end

    local function onFocusLoss(_, layout)
        hasFocus = false
        if textHandle then
            textHandle.props.textColor = textColor
            if events and events.focusLoss then events.focusLoss(_, lineLayout) end
            layout.userData.element:update()
        end
        return false
    end

    lineLayout.events = {
        mousePress = async:callback(onMousePress),
        mouseRelease = async:callback(onMouseRelease),
        focusGain = async:callback(onFocusGain),
        focusLoss = async:callback(onFocusLoss),
        mouseMove = async:callback(onMouseMove),
    }

    local wrapper = {
        type = ui.TYPE.Container,
        props = {
            propagateEvents = false,
        },
        userData = userData,
        content = ui.content({lineLayout})
    }

    local element = ui.create(wrapper)

    lineLayout.userData = {
        element = element,
        parent = wrapper,
    }

    return element
end

local lib = {
    create = createSelectableLine,
}

return lib