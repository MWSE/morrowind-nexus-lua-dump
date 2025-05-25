-- Zerkish Hotkeys Improved - zhi_ui_main.lua
-- Main window for selecting hotkeys

local async     = require('openmw.async')
local core      = require('openmw.core')
local ui        = require('openmw.ui')
local util      = require('openmw.util')
local MWUI      = require('openmw.interfaces').MWUI
local I         = require('openmw.interfaces')
local storage   = require('openmw.storage')
local types     = require('openmw.types')
local constants = require('scripts.omw.mwui.constants')

local ZHIUI         = require('scripts.ZerkishHotkeysImproved.zhi_ui')
local ZHIUtil       = require('scripts.ZerkishHotkeysImproved.zhi_util')
local ZHITooltip    = require('scripts.ZerkishHotkeysImproved.zhi_tooltip')
local ZHIHotbarData = require('scripts.ZerkishHotkeysImproved.zhi_hotbardata')

local ZHIUI_MAIN_CONSTANTS = {
    WindowWidth = 800,
    WindowHeight = 800,

    --ColumnWidth = 400,
    ColumnPadding = 10,
    --RowHeight = 220,
    RowPadding = 10,

    FooterHeight = 32,

    HotbarGroup = {
        Width = 300,
        Height = 166,

        HeaderHeight = 48,
        InnerHPadding = 2,

        HotkeySize = 48,
        HotkeyPadding = 8,
        KeysPerRow = 5,
        NumRows = 2,
    },

    CategorySelect = {
        Width = 200,
        Height = 180,
        HeaderHeight = 24,
    },

    TooltipMaxHeight = 400,
}

local function createSelectionWindow(callback)
    
    local header = {
        type = ui.TYPE.Flex,
        props = {
            size = util.vector2(ZHIUI_MAIN_CONSTANTS.CategorySelect.Width, ZHIUI_MAIN_CONSTANTS.CategorySelect.HeaderHeight),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content({
            {
                type = ui.TYPE.Text,
                props = {
                    text = 'Item to QuickKey',
                    textSize = 18,
                    textColor = constants.normalColor,
                }
            }
        })
    }

    local menuWindow = ui.create({
        template = I.MWUI.templates.boxSolidThick,
        type = ui.TYPE.Container,
        layer = I.ZHI.getPopupLayer(),
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = I.ZHI.getWindowAnchor(),
        },
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                props = {
                    size = util.vector2(ZHIUI_MAIN_CONSTANTS.CategorySelect.Width, ZHIUI_MAIN_CONSTANTS.CategorySelect.Height),
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content({
                    header,
                    ZHIUI.createTextButton('Inventory Menu Item', ZHIUtil.bindFunction(callback, 'inventory')),
                    {
                        type = ui.TYPE.Widget,
                        props = { size = util.vector2(1, 8) },
                    },
                    ZHIUI.createTextButton('Magic Menu Item', ZHIUtil.bindFunction(callback, 'magic')),
                    {
                        type = ui.TYPE.Widget,
                        props = { size = util.vector2(1, 8) },
                    },
                    ZHIUI.createTextButton('Delete QuickKey Item', ZHIUtil.bindFunction(callback, 'delete')),
                    {
                        type = ui.TYPE.Widget,
                        props = { size = util.vector2(1, 8) },
                    },
                    ZHIUI.createTextButton('Cancel', ZHIUtil.bindFunction(callback, 'cancel')),
                })
            },

        }),
    })

    return menuWindow
end


-- this is used same as I.MWUI.templates, it adds padding on the sides of whatever you stick into it.
local hotbarGroupPaddingTemplate = {
    type = ui.TYPE.Container,
    props = {
        propagateEvents = true,
    },
    content = ui.content {
        {
            props = { size = util.vector2(ZHIUI_MAIN_CONSTANTS.HotbarGroup.InnerHPadding, 1), }
        },
        {
            external = { slot = true },
            props = 
            {
                position = util.vector2(ZHIUI_MAIN_CONSTANTS.HotbarGroup.InnerHPadding, 0),
                relativeSize = util.vector2(1, 1),
            },
        },
        {
            props = {
                position = util.vector2(ZHIUI_MAIN_CONSTANTS.HotbarGroup.InnerHPadding, 1);
                size = util.vector2(ZHIUI_MAIN_CONSTANTS.HotbarGroup.InnerHPadding, 1),
                relativePosition = util.vector2(1, 1),
            }
        },
    }
}

-- Creates a neat box that just wraps all the hotkeys
local function createHotkeysWidget(hotbarNum, callbacks)
    local width = ZHIUI_MAIN_CONSTANTS.HotbarGroup.KeysPerRow * ZHIUI_MAIN_CONSTANTS.HotbarGroup.HotkeySize + (ZHIUI_MAIN_CONSTANTS.HotbarGroup.KeysPerRow - 1) * ZHIUI_MAIN_CONSTANTS.HotbarGroup.HotkeyPadding + constants.border * 2
    local height = ZHIUI_MAIN_CONSTANTS.HotbarGroup.NumRows * ZHIUI_MAIN_CONSTANTS.HotbarGroup.HotkeySize + (ZHIUI_MAIN_CONSTANTS.HotbarGroup.NumRows - 1) * ZHIUI_MAIN_CONSTANTS.HotbarGroup.HotkeyPadding + constants.border * 2

    local hotkeysContainer = {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(width, height),
            anchor = util.vector2(0.5, 0.0),
            relativePosition = util.vector2(0.5, 0.0),
        },
        content = ui.content({}),
    }

    local offsetX = 0
    local offsetY = 0

    local keysPerRow = 5

    for i=1,2 do
        local keysThisRow = (hotbarNum == 1 or i == 1) and keysPerRow or (keysPerRow-1)

        for j=1,keysThisRow do
            local keyNum = (j + (i - 1) * keysPerRow)

            local userData = { hotbar = hotbarNum, hotkey = keyNum }

            local hotkey = ZHIUI.createHotkeyAssignmentBox(tostring(keyNum % 10), ZHIUI_MAIN_CONSTANTS.HotbarGroup.HotkeySize, ZHIUI_MAIN_CONSTANTS.HotbarGroup.HotkeySize, userData, callbacks)
            hotkey.props.position = util.vector2(offsetX, offsetY)
            hotkey.name = ZHIUtil.getHotkeyIdentifier(hotbarNum, keyNum % 10)
            hotkeysContainer.content:add(hotkey)
            
            offsetX = offsetX + ZHIUI_MAIN_CONSTANTS.HotbarGroup.HotkeyPadding + ZHIUI_MAIN_CONSTANTS.HotbarGroup.HotkeySize
        end
        offsetX = 0
        if hotbarNum ~= 1 then
            offsetX = (ZHIUI_MAIN_CONSTANTS.HotbarGroup.HotkeyPadding + ZHIUI_MAIN_CONSTANTS.HotbarGroup.HotkeySize) / 2
        end
        offsetY = offsetY + ZHIUI_MAIN_CONSTANTS.HotbarGroup.HotkeyPadding + ZHIUI_MAIN_CONSTANTS.HotbarGroup.HotkeySize
    end

    return hotkeysContainer
end

local function createHotbarGroup(identifier, enabled, modifier, callbacks)

    local mainText
    local textSize = 18
    if identifier == 1 then
        mainText = 'Main Hotbar'
        textSize = 24
    else
        mainText = string.format('Hotbar ##%d - ', identifier - 1)
        if enabled then
            mainText = mainText .. 'Modifier : '
        else
            mainText = mainText .. 'Disabled'
        end
    end

    local header = {
        type = ui.TYPE.Flex,
        props = {
            --autoSize = false,
            size = util.vector2(ZHIUI_MAIN_CONSTANTS.HotbarGroup.Width - ZHIUI_MAIN_CONSTANTS.HotbarGroup.InnerHPadding * 2, ZHIUI_MAIN_CONSTANTS.HotbarGroup.HeaderHeight),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            horizontal = true,
        },
        content = ui.content({
            {
                type = ui.TYPE.Text,
                props = {
                    text = mainText,
                    textSize = textSize,
                    textColor = constants.normalColor,
                }
            },
            {
                type = ui.TYPE.Text,
                props = {
                    text = (identifier ~= 1 and enabled) and modifier or '',
                    textSize = 18,
                    textColor = constants.headerColor,
                }
            }
        })
    }

    local hotkeysContainer = createHotkeysWidget(identifier, callbacks)

    local innerPanel = {
        type = ui.TYPE.Container,
        props = {
            autoSize = false,
            size = util.vector2(ZHIUI_MAIN_CONSTANTS.HotbarGroup.Width - ZHIUI_MAIN_CONSTANTS.HotbarGroup.InnerHPadding * 2, ZHIUI_MAIN_CONSTANTS.HotbarGroup.Height),
        },
        content = ui.content({
            
            {
                type = ui.TYPE.Flex,
                props = { },
                content = ui.content({
                    header,
                    {
                        type = ui.TYPE.Widget,
                        props = {
                            size = util.vector2(ZHIUI_MAIN_CONSTANTS.HotbarGroup.Width - ZHIUI_MAIN_CONSTANTS.HotbarGroup.InnerHPadding * 2, ZHIUI_MAIN_CONSTANTS.HotbarGroup.Height - ZHIUI_MAIN_CONSTANTS.HotbarGroup.HeaderHeight),
                        },
                        content = ui.content({
                            hotkeysContainer,
                        })
                    },
                })
            }
        })
    }

    local root = {
        template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        props = {
            anchor = util.vector2(0.5, 0.0),
            relativePosition = util.vector2(0.5, 0.0),
            alpha = enabled and 1.0 or 0.5
        },
        content = ui.content({
            {
                type = ui.TYPE.Widget,
                props = {
                    autoSize = false,
                    size = util.vector2(ZHIUI_MAIN_CONSTANTS.HotbarGroup.Width, ZHIUI_MAIN_CONSTANTS.HotbarGroup.Height),
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content({
                    {
                        template = hotbarGroupPaddingTemplate,
                        type = ui.TYPE.Container,
                        props = {
                                
                        },
                        content = ui.content({
                            innerPanel,
                        })
                    }
                })
            },

            --paddingContainer,
        })
    }

    return root
end

local function createColumn(hotbar1, hotbar2)
    local col = {
        --template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        props = {

        },
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                },
                content = ui.content({
                    {
                        type = ui.TYPE.Widget,
                        props = {
                            size = util.vector2(5, ZHIUI_MAIN_CONSTANTS.RowPadding)
                        },
                    },
                    hotbar1,
                    {
                        type = ui.TYPE.Widget,
                        props = {
                            size = util.vector2(5, ZHIUI_MAIN_CONSTANTS.RowPadding)
                        },
                    },
                    hotbar2,
                    {
                        type = ui.TYPE.Widget,
                        props = {
                            size = util.vector2(5, ZHIUI_MAIN_CONSTANTS.RowPadding)
                        },
                    },
                })
            },
        })
    }

    return col
end

local function createHotbarWithSettings(num, callbacks)
    local section = storage.playerSection(string.format('SettingsZHIHotbar%d', num))
    local enabled = section:get(string.format('hotbar%d_enabled', num))
    local modifier = section:get(string.format('hotbar%d_modifier', num))

    return createHotbarGroup(num, enabled, modifier, callbacks)
end

local function createMainLayout(callbacks)

    local columns = {
        type = ui.TYPE.Flex,
        props = {
            --autoSize = true,
            horizontal = true,
        },
        content = ui.content({
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(ZHIUI_MAIN_CONSTANTS.ColumnPadding, 1),
                },
            },
            createColumn(createHotbarWithSettings(2, callbacks), createHotbarWithSettings(4, callbacks)),
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(ZHIUI_MAIN_CONSTANTS.ColumnPadding, 1),
                },
            },
            createColumn(createHotbarWithSettings(1, callbacks), createHotbarWithSettings(5, callbacks)),
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(ZHIUI_MAIN_CONSTANTS.ColumnPadding, 1),
                },
            },
            createColumn(createHotbarWithSettings(3, callbacks), createHotbarWithSettings(6, callbacks)),
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(ZHIUI_MAIN_CONSTANTS.ColumnPadding, 1),
                },
            },
        }),
    }

    local footerButtons = {
        type = ui.TYPE.Flex,
        props = {
            horizontal  = true,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content({
            ZHIUI.createTextButton("Clear All", callbacks.onClearAllPressed),
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(ZHIUI_MAIN_CONSTANTS.WindowWidth - 30, ZHIUI_MAIN_CONSTANTS.FooterHeight),
                },
                content = ui.content({
                    {
                        type = ui.TYPE.Text,
                        props = {
                            anchor = util.vector2(0.5, 0.5),
                            relativePosition = util.vector2(0.48, 0.5),
                            text = "Hotkeys Improved for OpenMW",
                            textSize = 16,
                            textColor = constants.normalColor
                        },
                    }
                })
            },
            {
                type = ui.TYPE.Container,
                props = {
                    relativePosition = util.vector2(0.75, 0.5),
                },
                content = ui.content({
                    ZHIUI.createTextButton("Ok", callbacks.onOkPressed),
                })
            },
        })
    }


    local footerContent =  {
        type = ui.TYPE.Flex,
        props = {
            --autoSize = false,
            horizontal = true,
            size = util.vector2(ZHIUI_MAIN_CONSTANTS.WindowWidth, ZHIUI_MAIN_CONSTANTS.FooterHeight),
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    size = util.vector2(ZHIUI_MAIN_CONSTANTS.ColumnPadding, 1),
                    --size = util.vector2(200, 80),
                },
            },
            footerButtons,
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(ZHIUI_MAIN_CONSTANTS.ColumnPadding, 1),
                },
            },
        })
    }

    local footer = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = true,
            size = util.vector2(ZHIUI_MAIN_CONSTANTS.WindowWidth, ZHIUI_MAIN_CONSTANTS.FooterHeight)
        },
        content = ui.content({
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(ZHIUI_MAIN_CONSTANTS.ColumnPadding, 1),
                },
            },
            {
                template = I.MWUI.templates.boxSolid,
                type = ui.TYPE.Container,
                content = ui.content ({
                    footerContent,
                }),
            },
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(ZHIUI_MAIN_CONSTANTS.ColumnPadding, 1),
                },
            },
        }),
    }


    local root = {
        type = ui.TYPE.Flex,
        props = {
            --autoSize = true,
            --size = util.vector2(ZHIUI_MAIN_CONSTANTS.WindowWidth, ZHIUI_MAIN_CONSTANTS.WindowHeight),
            --size = util.vector2(200, 200),
        },
        content = ui.content({
            columns,
            footer,
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(ZHIUI_MAIN_CONSTANTS.ColumnPadding, ZHIUI_MAIN_CONSTANTS.RowPadding),
                },
            }
        })
    }

    return root
end

local function hideTooltipForHotkey(mainWindow, layout)
    ZHITooltip.updateTooltip(nil, nil)
end

return {
    createHotkeySelectionWindow = createSelectionWindow,

    createMainWindow = function(callbacks)

        local window = {
            template = I.MWUI.templates.boxSolidThick,
            layer = 'Windows',
            type = ui.TYPE.Container,
            props = {
                anchor = util.vector2(0.5, 0.5),
                relativePosition = I.ZHI.getWindowAnchor(),
                --autoSize = false,
            },
            content = ui.content({
                createMainLayout(callbacks),
            }),
        }

        return ui.create(window)
    end,

    showTooltipForHotkey = function(hotkeyLayout, position)
        if not hotkeyLayout or not hotkeyLayout.userData then
            ZHITooltip.updateTooltip(nil, nil)
            return
        end

        -- local tooltipPane = mainWindow.layout.userData.tooltipPane
        local hotbar = hotkeyLayout.userData.hotbar
        local hotkey = hotkeyLayout.userData.hotkey

        local hkData = ZHIHotbarData.getHotkeyData(hotbar, hotkey)
        if not hkData then return end

        local data = {}

        if hkData.data.spell then
            data.spell = core.magic.spells.records[hkData.data.spell.spellId]
        elseif hkData.data.item then
            data.item = {
                itemId = hkData.data.id,
                recordId = hkData.data.item.recordId,
                itemType = types[hkData.data.item.typeStr]
            }
        end

        if data.spell or data.item then
            ZHITooltip.updateTooltip(position, data)
        else
            ZHITooltip.updateTooltip(nil, nil)
        end
    end,

    hideTooltipForHotkey = hideTooltipForHotkey,
}