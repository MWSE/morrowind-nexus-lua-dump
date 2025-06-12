-- Zerksih Hotkeys Improved - zhi_ui
-- UI Functionality for ZHI.

local Actor     = require('openmw.types').Actor
local async     = require('openmw.async')
local core      = require('openmw.core')
local types     = require('openmw.types')
local ui        = require('openmw.ui')
local util      = require('openmw.util')
local MWUI      = require('openmw.interfaces').MWUI
local I         = require('openmw.interfaces')

local constants = require('scripts.omw.mwui.constants')

local ZHIUtil = require('scripts.ZerkishHotkeysImproved.zhi_util')
local ZHIScrollbar = require('scripts.ZerkishHotkeysImproved.zhi_scrollbar')

local ZMUI = require('scripts.ZModUtils.UI')
local ZMUtility = require('scripts.ZModUtils.Utility')

local ZHIUI_CONSTANTS = {
    ButtonTextHPadding = 8,
    VScrollbarSize = 14,

    MenuClickSound = 'menu click',

    MessageBox = {
        HeaderHeight = 28,
    }
}

local function createHotkeyAssignmentBox(keyText, sizeX, sizeY, userData, callbacks, borderX, borderY, iconX, iconY)

    local textElement = {
        type = ui.TYPE.Text,
        name = 'hotkey_text',
        props = {
            propagateEvents = true,
            textSize = 18,
            textColor = constants.normalColor,
            text = keyText,
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
        },
    }

    local bx = borderX and borderX or 44
    local by = borderY and borderY or 44
    local ix = iconX and iconX or 32
    local iy = iconY and iconY or 32

    local hotkeyBorder = {
        type = ui.TYPE.Image,
        name = 'hotkey_border',
        props = {
            propagateEvents = true,
            size = util.vector2(bx, by),
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            resource = ZHIUtil.getCachedTexture({ --ui.texture({
                path = 'textures/menu_icon_magic_mini.dds'
            })
        },
    }

    local imageBorder = {
        --template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        name = 'hotkey_image_group',
        props = {
            visible = false,
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            autoSize = true,
            propagateEvents = true,
        },
        content = ui.content({
            {
                type = ui.TYPE.Widget,
                props = {
                    propagateEvents = true,
                    visible = true,
                    size = util.vector2(sizeX, sizeY),
                },
                
                content = ui.content({
                    hotkeyBorder,
                    {
                        type = ui.TYPE.Image,
                        name = 'hotkey_image',
                        props = {
                            propagateEvents = true,
                            visible = true,
                            size = util.vector2(ix, iy),
                            anchor = util.vector2(0.5, 0.5),
                            relativePosition = util.vector2(0.5, 0.5),
                            resource = ZHIUtil.getCachedTexture({ --ui.texture({
                                path = 'textures/omw_menu_scroll_up.dds'
                            }),
                            --resource = ui.texture( { path = 'textures/menu_icon_magic.dds'} )
                        }
                    },
                })
            }
        }),
    }

    local innerContainer = {
        type = ui.TYPE.Widget,
        layer = 'Windows',
        name = 'hotkey_inner',
        props = {
            autoSize = false,
            size = util.vector2(sizeX, sizeY),
            propagateEvents = true,
            -- align = ui.ALIGNMENT.Center,
            -- arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content({textElement, imageBorder}),
    }

    -- local events = {
    --     mouseRelease = async:callback(callback)
    -- }

    local events = { }
    if callbacks and callbacks.onHotkeyPressed then
        events.mouseRelease = async:callback(callbacks.onHotkeyPressed)
    end
    if callbacks and callbacks.onHotkeyFocusGain then
        events.focusGain = async:callback(callbacks.onHotkeyFocusGain)
    end
    if callbacks and callbacks.onHotkeyFocusLoss then
        events.focusLoss = async:callback(callbacks.onHotkeyFocusLoss)
    end
    if callbacks and callbacks.onHotkeyMouseMove then
        events.mouseMove = async:callback(callbacks.onHotkeyMouseMove)
    end

    return {
        template = MWUI.templates.boxTransparent,
        type = ui.TYPE.Container,
        layer = 'Windows',
        userData = userData,
        props = {

        },
        content = ui.content({innerContainer}),
        events = events,
    }
end

local function resetHotkeyUI(hotkeyLayout)
    local imageGroup = ZMUtility.findLayoutByNameRecursive(hotkeyLayout.content, 'hotkey_image_group')
    local text = ZMUtility.findLayoutByNameRecursive(hotkeyLayout.content, 'hotkey_text')
    if imageGroup then
        imageGroup.props.visible = false
    end
    if text then
        text.props.visible = true
    end
end

local function getIconPathFromSpell (spell)
    if spell == nil then return end

    if #spell.effects == 0 then return end

    return spell.effects[1].effect.icon
end

local function setHotkeyIcon(layout, icon, border)
    local imageGroup = ZMUtility.findLayoutByNameRecursive(layout.content, 'hotkey_image_group')
    local text = ZMUtility.findLayoutByNameRecursive(layout.content, 'hotkey_text')

    if icon and imageGroup then
        local hotkeyImage = ZMUtility.findLayoutByNameRecursive(imageGroup.content, 'hotkey_image')
        local hotkeyBorder = ZMUtility.findLayoutByNameRecursive(imageGroup.content, 'hotkey_border')

        if hotkeyImage then
            hotkeyImage.props.resource = icon
        end
        if hotkeyBorder then
            hotkeyBorder.props.resource = border
        end
        
        imageGroup.props.visible = true

        if text then
            text.props.visible = false
        end
    elseif imageGroup or text then
        if imageGroup then
            imageGroup.props.visible = false
        end
        if text then
            text.props.visible = true
        end
    end
end

local function setHotkeyFromData(hotkeyLayout, hotkeyData)
    if not hotkeyLayout then return end

    if not hotkeyData or not hotkeyData.data then return end

    local item = hotkeyData.data.item
    local spell = hotkeyData.data.spell

    local icon, borderPath
    local borderOffset = util.vector2(0, 0)

    if item then
        --print('setHotkeyFromData, item', item.typeStr, item.recordId)
        local itemRecord = types[item.typeStr].records[item.recordId]
        icon = ZHIUtil.getCachedTexture({ --ui.texture({
             path = itemRecord.icon 
        })

        local isBoundToEquip = item.enchantment ~= nil
        
        if isBoundToEquip then
            borderPath = 'textures/menu_icon_select_magic_magic.dds'
        else
            if itemRecord.enchant then
                borderPath = 'textures/menu_icon_magic_barter.dds'
            else
                borderPath = 'textures/menu_icon_barter.dds'
                borderOffset = util.vector2(2, 2)
            end
        end

    elseif spell then
        local smallIconPath = getIconPathFromSpell(core.magic.spells.records[spell.spellId])
        local bigIconPath = ZMUtility.Magic.getSpellEffectBigIconPath(smallIconPath)
        
        -- Try to convert the spell effect icon to the larger icons
        if bigIconPath then
            icon = ZHIUtil.getCachedTexture({ --ui.texture({
                path = bigIconPath 
            })
        end

        -- Fallback to original 
        if not icon then
            icon = ZHIUtil.getCachedTexture({ -- ui.texture({
                 path = smallIconPath 
            })
        end

        borderPath = 'textures/menu_icon_select_magic.dds'
    end

    local borderIcon
    if borderPath then 
        borderIcon = ZHIUtil.getCachedTexture({ --ui.texture({ 
            path = borderPath,
            size = util.vector2(44, 44),
            offset = borderOffset,
        })
    end

    setHotkeyIcon(hotkeyLayout, icon, borderIcon)
end

----------------------
-- Popup
----------------------
local function createMessageBox(title, message, hasOKBtn, hasCancelBtn, optCallbacks)

    local header = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            --size = util.vector2(ZHIUI_CONSTANTS.HotbarGroup.Width - ZHIUI_MAIN_CONSTANTS.HotbarGroup.InnerHPadding * 2, ZHIUI_MAIN_CONSTANTS.HotbarGroup.HeaderHeight),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content({
            {
                type = ui.TYPE.Text,
                props = {
                    text = title,
                    textSize = 18,
                    textColor = constants.headerColor,
                }
            }
        })
    }

    local messageElement = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = true,
            -- arrange = ui.ALIGNMENT.End,
            -- align = ui.ALIGNMENT.End,
        },
        content = ui.content({
            {
                type = ui.TYPE.Text,
                props = {
                    text = message,
                    textSize = 16,
                    textColor = constants.normalColor,
                    multiline = true,
                    wordWrap = true,
                }
            }
        })
    }

    local buttonsElement = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            align = ui.ALIGNMENT.End,
            arrange = ui.ALIGNMENT.End,
        },
        content = ui.content({})
    }

    -- local callbackWrapper = function(result) 
    --     if type(optCallback) == 'function' then
    --         optCallback(result)
    --     end
    -- end

    -- nil is ok
    if hasOKBtn ~= false then
        local cb = (optCallbacks ~= nil) and optCallbacks.okButton or nil
        --buttonsElement.content:add(ZMUIcreateTextButton('Ok', cb))
        buttonsElement.content:add(ZMUI.Components.TextButton.create({
            text = ZHIL10n('in_game_button_ok'),
            callback = cb,
        }))
    end
    if hasCancelBtn then
        local cb = (optCallbacks ~= nil) and optCallbacks.cancelButton or nil
        --buttonsElement.content:add(createTextButton('Cancel', cb))
        buttonsElement.content:add(ZMUI.Components.TextButton.create({
            text = ZHIL10n('in_game_button_cancel'),
            callback = cb,
        }))
    end

    -- if (hasOKBtn == nil) or (hasOKBtn) then
    --     buttonsElement.content:add(createTextButton('Ok', ZHIUtil.bindFunction(callbackWrapper, true)))
    -- end
    -- if hasCancelBtn then
    --     buttonsElement.content:add(createTextButton('Cancel', ZHIUtil.bindFunction(callbackWrapper, false)))
    -- end

    local centerContent = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            --size = util.vector2(200, 200),
            align = ui.ALIGNMENT.End,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content({
            header,
            -- Padding
            {
                type = ui.TYPE.Flex,
                props = { autoSize = false, size = util.vector2(0, 8)}
            },
            messageElement,
            -- Padding
            {
                type = ui.TYPE.Flex,
                props = { autoSize = false, size = util.vector2(0, 8)}
            },
            buttonsElement,
        })
    }

    local padTemplate = {
        type = ui.TYPE.Container,
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                props = { size = util.vector2(16, 0)},
            },
            {
                external = { slot = true },
                props = {
                    position = util.vector2(16, 0),
                    relativeSize = util.vector2(1, 1)
                }
            },
            {
                type = ui.TYPE.Flex,
                props = { 
                    size = util.vector2(16, 16),
                    position = util.vector2(16, 0),
                    relativePosition = util.vector2(1.0, 1.0),
                },                
            },
        })
    }

    return ui.create({
        template = I.MWUI.templates.boxSolidThick,
        type = ui.TYPE.Container,
        layer = I.ZHI.getPopupLayer(),
        props = {
            --autoSize = true,
            horizontal = true,
            anchor = util.vector2(0.5, 0.25),
            relativePosition = util.vector2(0.5, 0.5)
        },
        content = ui.content({
            {
                template = padTemplate,
                props = {
                    
                },
                content = ui.content({
                    centerContent
                })
            },
        }),
    })
end


return {

    ZHIUI_CONSTANTS = ZHIUI_CONSTANTS,
    
    createHotkeyAssignmentBox = createHotkeyAssignmentBox,
    setHotkeyIcon  = setHotkeyIcon,
    setHotkeyFromData = setHotkeyFromData,
    resetHotkeyUI = resetHotkeyUI,

    createMessageBox = createMessageBox,
}