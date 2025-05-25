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

local ZHIUI_CONSTANTS = {
    ButtonTextHPadding = 8,
    VScrollbarSize = 14,

    MenuClickSound = 'menu click',

    MessageBox = {
        HeaderHeight = 28,
    }
}

local function createTextButton(text, callback)

    local textLayout = {
        type = ui.TYPE.Text,
        name = 'textItem',
        props = {
            propagateEvents = true,
            textSize = 18,
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
        if layout.userData then layout.userData.textLayout.props.textColor = constants.headerColor end
        I.ZHI.updateUI()
        return false
    end

    local focusLostHandler = function(unused, layout)
        if layout.userData then layout.userData.textLayout.props.textColor = constants.normalColor end
        I.ZHI.updateUI()
        return false
    end

    local mousePressHandler = function(mouseEvent, layout)
        if layout.userData then
            layout.userData.textLayout.props.textColor = util.color.rgb(1, 1, 1)
            I.ZHI.updateUI()
        end
        I.ZHI.playSound(ZHIUI_CONSTANTS.MenuClickSound)
        return false
    end

    local mouseReleaseHandler = function(mouseEvent, layout)
        if layout.userData then
            layout.userData.textLayout.props.textColor = constants.headerColor
            I.ZHI.updateUI()
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
    }

    buttonLayout.content = ui.content({
        {
            template = template,
            type = ui.TYPE.Container,
            content = ui.content({ textLayout }),
            userData = {
                parent = buttonLayout,
                textLayout = textLayout
            },
            props = {
                propagateEvents = false,
            },
            events = {
                mousePress = async:callback(mousePressHandler),
                mouseRelease = async:callback(mouseReleaseHandler),
                focusGain = async:callback(focusGainHandler),
                focusLoss = async:callback(focusLostHandler),
            }
        }
    })

    return buttonLayout
end

local function createIconButton(iconPath, size, callback, userData)

    local parent = {
        template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        userData = userData,
        props = {

        },
    }

    local image = {
        type = ui.TYPE.Image,
        props = {
            propagateEvents = true,
            resource = ZHIUtil.getCachedTexture({ --ui.texture({
                 path = iconPath 
            }),
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
                I.ZHI.playSound(ZHIUI_CONSTANTS.MenuClickSound)
            end),
            mouseRelease = async:callback(function(evt, layout)
                -- call with root object to make it easier for users to bind their own userData etc.
                if type(callback) == 'function' then
                    callback(evt, layout.userData.parent)
                    end
                    
            end),
        },
    }

    parent.content = ui.content({inner})

    return parent
end

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
    local imageGroup = ZHIUtil.findLayoutByNameRecursive(hotkeyLayout.content, 'hotkey_image_group')
    local text = ZHIUtil.findLayoutByNameRecursive(hotkeyLayout.content, 'hotkey_text')
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
    local imageGroup = ZHIUtil.findLayoutByNameRecursive(layout.content, 'hotkey_image_group')
    local text = ZHIUtil.findLayoutByNameRecursive(layout.content, 'hotkey_text')

    if icon and imageGroup then
        local hotkeyImage = ZHIUtil.findLayoutByNameRecursive(imageGroup.content, 'hotkey_image')
        local hotkeyBorder = ZHIUtil.findLayoutByNameRecursive(imageGroup.content, 'hotkey_border')

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

-- local function getSpellEffectBigIconPath(fullPath)
--     local pattern = "[%w_]+.dds"
    
--     local b, e = string.find(fullPath, pattern)
--     local fileLocation = string.sub(fullPath, 1, b - 1)
--     local filename = string.sub(fullPath, b, e)

--     return string.format("%sb_%s", fileLocation, filename)
-- end

local function setHotkeyFromData(hotkeyLayout, hotkeyData)
    if not hotkeyLayout then return end

    --local imageGroup = ZHIUtil.findLayoutByNameRecursive(hotkeyLayout.content, 'hotkey_image_group')
    --local text = ZHIUtil.findLayoutByNameRecursive(hotkeyLayout.content, 'hotkey_text')

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
        local bigIconPath = ZHIUtil.getSpellEffectBigIconPath(smallIconPath)
        
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

-- Utility function for moving the scrolled content based on scrollbar position (VERTICAL)
-- Replaces setInnerContentPositionFromScrollbarPosition
local function setContentYPositionFromScrollbarPosition(content, scrollbar)
    assert(content ~= nil and content.userData ~= nil)
    
    -- there is no scrollbar with few items.
    if scrollbar ~= nil then
        local scrollbarData = ZHIScrollbar.getScrollbarHandleData(scrollbar)
        local scrollbarPos = ZHIScrollbar.getScrollbarHandlePosition(scrollbar)
        local maxBarPosition = scrollbarData.height - scrollbarData.barHeight

        local contentY = 0
        if maxBarPosition > 1 then
            local ratio = scrollbarPos / maxBarPosition
            ratio = math.max(0, math.min(ratio, 1))
            --ratio = 1
            contentY = ratio * (content.userData.contentSizeY - content.userData.containerSizeY)
        end
        --content.props.position = util.vector2(0, -contentY)
        content.userData.contentPosY = contentY
    end

    local offset = math.fmod(content.userData.contentPosY, content.userData.itemSize.y)

    -- we need to move need items (rows) in and out of the container 
    local minItem = math.floor(content.userData.contentPosY  / content.userData.itemSize.y) + 1
    local maxItem = math.ceil((content.userData.contentPosY  + content.userData.containerSizeY) / content.userData.itemSize.y)

    maxItem = math.min(maxItem, #content.userData.items)

    for i=1, #content.content do
        local item = content.content[i]
        if item.userData and item.userData.onResetItem then
            item.userData.onResetItem(item)
        end
    end

    content.content = ui.content({})

    for i=minItem, maxItem do
        content.content:add(content.userData.items[i])
    end

    content.props.position = util.vector2(content.props.position.x, -offset)
end

-- numItems can be negative
local function moveScrollbarByItemNum(content, scrollbar, numItems)
    local scrollbarData = ZHIScrollbar.getScrollbarHandleData(scrollbar)
    local maxBarPosition = scrollbarData.height - scrollbarData.barHeight

    local ratio = maxBarPosition / (content.userData.contentSizeY - content.userData.containerSizeY)
    local itemSizeInBar = content.userData.itemSize.y * ratio

    local scrollbarPos = ZHIScrollbar.getScrollbarHandlePosition(scrollbar)

    -- move scrollbar by one item
    local newScrollbarY = math.min(math.max(scrollbarPos + itemSizeInBar * numItems, 0), maxBarPosition)

    ZHIScrollbar.setScrollbarHandlePosition(scrollbar, newScrollbarY)
end

local function onVScrollbarUpButton(mEvent, layout)
    -- -- stored handle to the scrollPaneContent
    local content = layout.userData.content
    local scrollbar = layout.userData.scrollbar
    
    moveScrollbarByItemNum(content, scrollbar, -1)
    setContentYPositionFromScrollbarPosition(content, scrollbar)
    I.ZHI.updateUI()
end

local function onVScrollbarDownButton(mEvent, layout)
    -- -- stored handle to the scrollPaneContent
    local content = layout.userData.content
    local scrollbar = layout.userData.scrollbar

    moveScrollbarByItemNum(content, scrollbar, 1)
    setContentYPositionFromScrollbarPosition(content, scrollbar)
    I.ZHI.updateUI()
end

local function onVScrollPaneScrollbarDrag(mEvent, layout)
    assert(layout ~= nil)
    local sbData = ZHIScrollbar.getScrollbarHandleData(layout)
    assert(layout.userData ~= nil)
    local content = layout.userData

    setContentYPositionFromScrollbarPosition(content, layout)
end

local function createVerticalScrollbarWithButtons(containerSize, contentSizeY, outerContentHandle, callback)
    
    -- the actual height of the scrollbar, removing the two buttons + all the borders and adding outer padding
    local scrollbarHeight = containerSize.y - ZHIUI_CONSTANTS.VScrollbarSize * 2 - constants.border * 6 - constants.thickBorder * 2

    local ratio = scrollbarHeight / contentSizeY -- - containerSize.y
    if ratio >= 1.0 then ratio = 1.0 end

    -- Minimum size in case of very many items
    local barSize = math.max(ratio * scrollbarHeight, ZHIUI_CONSTANTS.VScrollbarSize) 
    local scrollbarLayout = ZHIScrollbar.createScrollbarV(ZHIUI_CONSTANTS.VScrollbarSize, scrollbarHeight, barSize, onVScrollPaneScrollbarDrag)

    if (scrollbarLayout) then
        scrollbarLayout.name = "vpane_scrollbar"
        scrollbarLayout.userData = outerContentHandle
    end
    
    local scrollbarActualSize = ZHIUI_CONSTANTS.VScrollbarSize -- + constants.border * 2

    local userData = {
        content = outerContentHandle,
        scrollbar = scrollbarLayout,
    }

    -- Wrap the scrollbar and buttons 
    return {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            size = util.vector2(scrollbarActualSize, containerSize.y),
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content({
            createIconButton('textures/omw_menu_scroll_up.dds', util.vector2(scrollbarActualSize, scrollbarActualSize), onVScrollbarUpButton, userData),
            scrollbarLayout,
            createIconButton('textures/omw_menu_scroll_down.dds', util.vector2(scrollbarActualSize, scrollbarActualSize), onVScrollbarDownButton, userData),
        })
    }
end

local function adjustScrollPaneSize(items, itemSize, panelSize)
    -- The total inner area 
    local contentSizeY = (#items) * itemSize.y

    local shouldCreateScrollbar = contentSizeY > panelSize.y
    local contentActualSizeX = panelSize.x + constants.thickBorder * 2

    if shouldCreateScrollbar then
        contentActualSizeX = contentActualSizeX + ZHIUI_CONSTANTS.VScrollbarSize + constants.border * 2
    end
    return util.vector2(contentActualSizeX, panelSize.y)
end

local function createVerticalScrollPane(items, itemSize, containerSize)

    local numItems = #items

    -- The total inner area 
    local contentSizeY = numItems * itemSize.y

    local shouldCreateScrollbar = contentSizeY > containerSize.y

    local contentActualSizeX = containerSize.x
    if shouldCreateScrollbar then
        contentActualSizeX = containerSize.x - ZHIUI_CONSTANTS.VScrollbarSize - constants.border * 2 - constants.thickBorder
    end

    local contentPane = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            size = containerSize,
            horizontal = true,
        },

        content = ui.content({
            -- Padding
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    size = util.vector2(constants.thickBorder, 1),
                },
            },
            -- List Area
            {
                type = ui.TYPE.Widget,
                props = {
                    autoSize = false,
                    size = util.vector2(contentActualSizeX, contentSizeY),
                },
                content = ui.content({
                    {
                        --template = I.MWUI.templates.c,
                        type = ui.TYPE.Flex,
                        name = 'outerContent',
                        props = {
                            --autoSize = true,
                            size = util.vector2(containerSize.x - ZHIUI_CONSTANTS.VScrollbarSize, contentSizeY),
                            position = util.vector2(0, 0),
                        },
                        content = ui.content({}),
                        userData = {
                            items = items,
                            itemSize = itemSize,
                            containerSizeY = containerSize.y,
                            contentSizeY = contentSizeY,
                            contentPosY = 0,
                        },
                    }
                }),
            },
        })
    }

    -- Handles to the layouts as they are stored in their content tables.
    local outerContentHandle = ZHIUtil.findLayoutByNameRecursive(contentPane.content, 'outerContent')

    -- add a scrollbar if one is necessary
    if shouldCreateScrollbar then
        contentPane.content:add(createVerticalScrollbarWithButtons(containerSize, contentSizeY, outerContentHandle))
    end

    local container = {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = containerSize,
            --position = util.vector2(0, -32)
        },
        content = ui.content({contentPane})
    }
    setContentYPositionFromScrollbarPosition(outerContentHandle, ZHIUtil.findLayoutByNameRecursive(container.content, 'vpane_scrollbar'))

    return container
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
        buttonsElement.content:add(createTextButton('Ok', cb))
    end
    if hasCancelBtn then
        local cb = (optCallbacks ~= nil) and optCallbacks.cancelButton or nil
        buttonsElement.content:add(createTextButton('Cancel', cb))
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

            -- {
            --     type = ui.TYPE.Flex,
            --     props = { size = util.vector2(16, 16)},
            -- },
            -- centerContent,
            -- {
            --     type = ui.TYPE.Flex,
            --     props = { 
            --         size = util.vector2(16, 16),
            --         position = util.vector2(16, 16),
            --         relativePosition = util.vector2(1.0, 1.0),
            --     },                

            -- },
        }),
    })
end


return {

    ZHIUI_CONSTANTS = ZHIUI_CONSTANTS,

    createTextButton = createTextButton,
    createIconButton = createIconButton,
    
    createHotkeyAssignmentBox = createHotkeyAssignmentBox,
    setHotkeyIcon  = setHotkeyIcon,
    setHotkeyFromData = setHotkeyFromData,
    resetHotkeyUI = resetHotkeyUI,


    adjustScrollPaneSize = adjustScrollPaneSize,
    createVerticalScrollPane = createVerticalScrollPane,
    vScrollPaneMoveScrollbarByItems = moveScrollbarByItemNum,
    vScrollpaneSetContentPositionFromScrollbarPosition = setContentYPositionFromScrollbarPosition,

    createMessageBox = createMessageBox,
}