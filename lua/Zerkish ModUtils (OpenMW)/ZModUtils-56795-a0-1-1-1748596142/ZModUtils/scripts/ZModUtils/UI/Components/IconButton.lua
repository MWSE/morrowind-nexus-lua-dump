-- ZModUtils - ZModUtils/UI/Components/IconButton.lua
-- Author: Zerkish (2025)

local ambient = require('openmw.ambient')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')

local constants = require('scripts.omw.mwui.constants')

local ZUIConstants = require('scripts.ZModUtils.UI.Constants')

local function createIconButton(iconTexture, size, callback, userData)

    local parent = {
        template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        userData = userData,
        props = {
            propagateEvents = false,
        },
    }

    local image = {
        type = ui.TYPE.Image,
        props = {
            propagateEvents = true,
            resource = iconTexture,
            size = size - util.vector2(2, 2),
            --relativePosition = util.vector2(1.0, 1.0),
            autoSize = false,
        }
    }

    local inner = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            size = size - util.vector2(constants.border * 2, constants.border * 2),
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
            propagateEvents = false,
        },
        content = ui.content({
            image
        }),
        userData = {
            parent = parent,
            image = image,
        },
        events = {
            mousePress = async:callback(function(evt) 
                ambient.playSound(ZUIConstants.ButtonClickSound)
                return false
            end),
            mouseRelease = async:callback(function(evt, layout)
                -- call with root object to make it easier for users to bind their own userData etc.
                if type(callback) == 'function' then
                    callback(evt, layout.userData.parent)
                end
                return false
            end),
        },
    }

    parent.content = ui.content({inner})
    local button = ui.create(parent)
    inner.userData._element = button

    return button
end

local lib = {
    create = createIconButton,

    -- setIcon = function(iconButton, iconTexture)

    -- end,
}

return lib