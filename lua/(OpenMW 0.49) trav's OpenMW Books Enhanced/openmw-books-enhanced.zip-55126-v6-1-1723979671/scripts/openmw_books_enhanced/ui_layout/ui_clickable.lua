local ui = require('openmw.ui')
local templates = require("scripts.openmw_books_enhanced.ui_layout.ui_templates")
local async = require('openmw.async')
local content_name = require("scripts.openmw_books_enhanced.window.content_element_names")

local CL = {}

function CL.createFocusableWidget(updateJournalWindow)
    return {
        userData = {
            isFocused = false,
            rightClickCallback = nil,
            callUpdateWindow = updateJournalWindow,
        },
        events = {
            focusGain = async:callback(function(e, thisObject)
                if thisObject.userData.textColorOver ~= nil then
                    thisObject.props.textColor = thisObject.userData.textColorOver
                end
                thisObject.userData.isFocused = true
                if thisObject.userData.callUpdateWindow ~= nil then
                    thisObject.userData.callUpdateWindow()
                end
            end),
            focusLoss = async:callback(function(e, thisObject)
                if thisObject.userData.textColorIdle ~= nil then
                    thisObject.props.textColor = thisObject.userData.textColorIdle
                end
                thisObject.userData.isFocused = false
                if (thisObject.userData.callUpdateWindow ~= nil) and (thisObject.userData.isFocused) and (not thisObject.userData.isPressed) then
                    thisObject.userData.callUpdateWindow()
                end
            end),
        },
        content = ui.content(
            {
                {
                    name = content_name.controlUnderline,
                    template = templates.journalButtonUnderline,
                    props = {
                        visible = false
                    }
                }
            })
    }
end

function CL.createClickableWidget(onClickCallback, updateJournalWindow)
    local result = CL.createFocusableWidget(updateJournalWindow)
    result.userData.isPressed = false
    result.userData.onClicking = onClickCallback
    result.events.mousePress = async:callback(function(e, thisObject)
        thisObject.props.textColor = thisObject.userData.textColorPressed
        thisObject.userData.isPressed = true
        if thisObject.userData.callUpdateWindow ~= nil then
            thisObject.userData.callUpdateWindow()
        end
    end)
    result.events.mouseRelease = async:callback(function(e, thisObject)
        if thisObject.userData.isFocused then
            if thisObject.userData.textColorOver ~= nil then
                thisObject.props.textColor = thisObject.userData.textColorOver
            end
        else
            if thisObject.userData.textColorIdle ~= nil then
                thisObject.props.textColor = thisObject.userData.textColorIdle
            end
        end
        thisObject.userData.isPressed = false
        thisObject.userData.onClicking(thisObject)
        if thisObject.userData.callUpdateWindow ~= nil then
            thisObject.userData.callUpdateWindow()
        end
    end)
    return result
end

return CL
