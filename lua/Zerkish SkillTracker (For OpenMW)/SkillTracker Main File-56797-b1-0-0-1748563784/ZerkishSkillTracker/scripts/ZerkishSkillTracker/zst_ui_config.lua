local Actor = require('openmw.types').Actor
local async = require('openmw.async')
local core = require('openmw.core')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local auxUI = require('openmw_aux.ui')

local constants = require('scripts.omw.mwui.constants')

local ZUtility  = require('scripts.ZModUtils.Utility')
local ZUI       = require('scripts.ZModUtils.UI')

local vector2 = util.vector2

local btnUpTexture = ui.texture({ path = 'textures/omw_menu_scroll_up.dds' })
local btnDownTexture = ui.texture({ path = 'textures/omw_menu_scroll_down.dds' })

local TrackerElementSize = vector2(200, 54)
local HeaderHeight = 48
local FooterHeight = 48
local FG_ALPHA = 1.0
local BG_ALPHA = 0.55

local CONSTANTS = {
    WindowSize = vector2(248, TrackerElementSize.y * 6 + HeaderHeight + FooterHeight),
    TrackerElementSize = TrackerElementSize,
    TrackerElementPadding = 4,

    ArrowButtonSize = vector2(16, 16),

    ButtonsSize = vector2(22, TrackerElementSize.y),

    SkillSelectItemHeight = 20,
    SkillSelectHeaderSize = 42,
    SkillSelectSize = vector2(200, 284),
    SkillSelectPanelSize = vector2(190, 200),
    SkillSelectTextSize = 16,
}

local trackedSkillsCache = nil

local updateTrackerContent = nil

local skillSelectPopup = nil
local configWindow = nil

local function listArrowButtonHandler(dir, index, event, layout)
    assert(trackedSkillsCache)

    local max = #trackedSkillsCache
    local nIndex = index + dir
    nIndex = math.max(1, math.min(max, nIndex))
    if nIndex == index then
        return
    end
    local temp = trackedSkillsCache[nIndex]
    trackedSkillsCache[nIndex] = trackedSkillsCache[index]
    trackedSkillsCache[index] = temp

    -- Trigger an update of the content menu..
    assert(updateTrackerContent)
    updateTrackerContent(layout.userData.content)
end

local function deleteButtonCallback(index, contentLayout, evt, layout)
    assert(trackedSkillsCache)
    assert(updateTrackerContent)
    table.remove(trackedSkillsCache, index)
    updateTrackerContent(contentLayout)
end

local SKILL_NAMES = {
    'None', 'Acrobatics', 'Alchemy', 'Alteration', 'Armorer', 'Athletics', 'Axe',
    'Block', 'Blunt Weapon', 'Conjuration', 'Destruction', 'Enchant', 'Hand to Hand',
    'Heavy Armor', 'Illusion', 'Light Armor', 'Long Blade', 'Marksman', 'Medium Armor',
    'Mercantile', 'Mysticism', 'Restoration', 'Security', 'Short Blade', 'Sneak', 'Spear', 'Speechcraft',
    'Unarmored',
}

local function closeSkillSelectPopup()
    if skillSelectPopup then
        auxUI.deepDestroy(skillSelectPopup)
        skillSelectPopup = nil
    end

    if configWindow then
        configWindow.layout.props.alpha = FG_ALPHA
        configWindow:update()
    end
end

local function skillSelectPress(name, index, contentLayout, evt, layout)
    closeSkillSelectPopup()
    assert(trackedSkillsCache)
    assert(updateTrackerContent)
    trackedSkillsCache[index] = name
    updateTrackerContent(contentLayout)
end

local function createSkillSelectPopup(index, windowLayout)
    
    local header = {
        type = ui.TYPE.Flex,
        props = {
            size = vector2(CONSTANTS.SkillSelectSize.x, CONSTANTS.SkillSelectHeaderSize),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content({
            {
                type = ui.TYPE.Text,
                props = {
                    text = 'Select Skill',
                    textSize = 24,
                    textColor = constants.headerColor,
                }
            }
        })
    }

    local contentLayout = {
        type = ui.TYPE.Flex,
        props = {

        },
        content = ui.content({})
    }

    local height = 0

    for i=1,#SKILL_NAMES do
        contentLayout.content:add(ZUI.Components.SelectableText.create({
            size = vector2(CONSTANTS.SkillSelectSize.x, CONSTANTS.SkillSelectItemHeight),
            text = SKILL_NAMES[i],
            textSize = CONSTANTS.SkillSelectTextSize,
            events = {
                mouseRelease = ZUtility.bindFunction(skillSelectPress, SKILL_NAMES[i], index, windowLayout),
            }
        }))
        height = height + CONSTANTS.SkillSelectItemHeight
    end
    contentLayout.props.size = util.vector2(CONSTANTS.SkillSelectSize.x, height)

    local contentElement = ui.create(contentLayout)

    local scrollpanel = ZUI.Components.Scrollpanel.createVertical({
        size = CONSTANTS.SkillSelectPanelSize,
        itemSize = vector2(CONSTANTS.SkillSelectSize.x, CONSTANTS.SkillSelectItemHeight),
        contentElement = contentElement,
    })

    local panelWrapper = {
        template = I.MWUI.templates.box,
        props = {},
        content = ui.content({ scrollpanel })
    }

    local footer = {
        type = ui.TYPE.Flex,
        props = {
            size = vector2(CONSTANTS.SkillSelectSize.x, CONSTANTS.SkillSelectHeaderSize),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.End,
            horizontal = true,
        },
        content = ui.content({
            ZUI.Components.TextButton.create({
                text = 'Cancel',
                textSize = 16,
                callback = function(evt, layout)
                    closeSkillSelectPopup()
                end,
            }),
            {
                type = ui.TYPE.Widget,
                props = { size = vector2(4, 0)}
            }
        })
    }
    
    local inner = {
        type = ui.TYPE.Flex,
        layer = 'Popup',
        props = {
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content({
            header,
            panelWrapper,
            footer,
        })
    }

    local root = {
        template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        layer = 'Popup',
        props = {
            anchor = vector2(0.5, 0.5),
            relativePosition = vector2(0.5, 0.5),
        },
        content = ui.content({
            inner
        }),
        userData = {
            scrollpanel = scrollpanel
        }
    }

    skillSelectPopup = ui.create(root)

    if configWindow then
        configWindow.layout.props.alpha = BG_ALPHA
        configWindow:update()
    end
end

local function createTrackerElement(skillName, index, contentLayout)

    local btnUD = {
        content = contentLayout
    }

    local arrowButtons = {
        type = ui.TYPE.Flex,
        props = {
            size = CONSTANTS.ButtonsSize,
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
            propagateEvents = false,
        },
        content = ui.content({
            ZUI.Components.IconButton.create(btnUpTexture, CONSTANTS.ArrowButtonSize, ZUtility.bindFunction(listArrowButtonHandler, -1, index), btnUD),
            {
                type = ui.TYPE.Widget,
                props = { size = vector2(0, 4) }
            },
            ZUI.Components.IconButton.create(btnDownTexture, CONSTANTS.ArrowButtonSize, ZUtility.bindFunction(listArrowButtonHandler, 1, index), btnUD),
        })
    }

    local text = ZUI.Components.SelectableText.create({
        size = util.vector2(140, 24),--TrackerElementSize - vector2(CONSTANTS.ButtonsSize.x, TrackerElementSize.y / 2),
        text = skillName,
        textSize = 18,
        events = {
            mouseRelease = function(evt, layout)
                createSkillSelectPopup(index, contentLayout)
            end
        },
        userData = {
            content = contentLayout,
        }
    })

    local skillButtons = {
        type = ui.TYPE.Flex,
        props = {
            size = TrackerElementSize - vector2(CONSTANTS.ButtonsSize.x, TrackerElementSize.y / 2),
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.End,
            propagateEvents = false,
        },
        content = ui.content({
            ZUI.Components.TextButton.create({
                text = 'Delete',
                textSize = 16,
                callback = ZUtility.bindFunction(deleteButtonCallback, index, contentLayout)
            })
        })
    }

    local vLayout = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            size = TrackerElementSize - vector2(CONSTANTS.ButtonsSize.x, 0),
            propagateEvents = false,
        },
        content = ui.content({
            text,
            {
                template = I.MWUI.templates.horizontalLine,
                props = {
                    size = vector2(TrackerElementSize.x - CONSTANTS.ButtonsSize.x, 2),
                },
            },
            skillButtons
        })
    }

    local hLayout = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            size = TrackerElementSize,
            propagateEvents = false,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content({
            -- Main Content,
            vLayout,
            {
                template = I.MWUI.templates.verticalLine,
                props = {
                    size = util.vector2(2, TrackerElementSize.y)
                }
            },
            arrowButtons
        })
    }

    local wrapper = {
        template = I.MWUI.templates.box,
        type = ui.TYPE.Container,
        props = {
            propagateEvents = false,
        },
        content = ui.content({hLayout})
    }

    local element = ui.create(wrapper)

    return element
end

updateTrackerContent = function(contentLayout)
    assert(trackedSkillsCache)

    if contentLayout.content then
        for i=1,#contentLayout.content do
            auxUI.deepDestroy(contentLayout.content[i])
        end
    end

    contentLayout.content = ui.content({})

    local numSkills = 0
    for i=1,#trackedSkillsCache do
        if trackedSkillsCache[i] then
            if #contentLayout.content > 0 then
                contentLayout.content:add({
                    type = ui.TYPE.Widget,
                    props = { size = vector2(0, CONSTANTS.TrackerElementPadding) }
                })
            end
            contentLayout.content:add(createTrackerElement(trackedSkillsCache[i], i, contentLayout))
            numSkills = numSkills + 1
        end
    end
    local actualElementSizeY = TrackerElementSize.y + CONSTANTS.TrackerElementPadding + constants.border * 2
    contentLayout.props.size = vector2(contentLayout.props.size.x, actualElementSizeY * numSkills)
    -- print('size.y', contentLayout.props.size.y)
    
    contentLayout.userData.element:update()
    ZUI.Components.Scrollpanel.updateContent(contentLayout.userData.scrollpane)
end

local function createTrackerContent()

    local skills = I.ZST.getTrackedSkills()
    trackedSkillsCache = {}

    local numSkills = 0
    for i=1,#skills do
        if skills[i] and skills[i] ~= 'None' then
            table.insert(trackedSkillsCache, skills[i])
            numSkills = numSkills + 1
        end
    end

    local actualElementSizeX = TrackerElementSize.x + constants.border * 4
    local actualElementSizeY = TrackerElementSize.y + CONSTANTS.TrackerElementPadding + constants.border * 2

    local contentLayout = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            size = util.vector2(actualElementSizeX + 8, 0),
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
            -- anchor = vector2(0.5, 0.0),
            -- relativePosition = vector2(0.5, 0.0),
        },
        content = ui.content({}),
        userData = {},
    }

    -- for i=1,#trackedSkillsCache do
    --     if trackedSkillsCache[i] and trackedSkillsCache[i] ~= 'None' then
    --         if #contentLayout.content > 0 then
    --             contentLayout.content:add({
    --                 type = ui.TYPE.Widget,
    --                 props = { size = vector2(0, CONSTANTS.TrackerElementPadding) }
    --             })
    --         end
    --         contentLayout.content:add(createTrackerElement(trackedSkillsCache[i], i, contentLayout))
    --     end
    -- end
    
    local contentElement = ui.create(contentLayout)
    contentLayout.userData.element = contentElement

    local height = 6 * (TrackerElementSize.y + CONSTANTS.TrackerElementPadding + constants.border * 2)

    local panelSize = vector2(TrackerElementSize.x + 18, height)
    panelSize = ZUI.Components.Scrollpanel.adjustPanelSize(contentLayout.props.size, panelSize, true)

    local scrollPane = ZUI.Components.Scrollpanel.createVertical({
        size = panelSize,
        itemSize = vector2(actualElementSizeX, actualElementSizeY),
        contentElement = contentElement,
        forceScrollbar = true,
    })

    contentLayout.userData.scrollpane = scrollPane

    updateTrackerContent(contentLayout)

    local layout = {
        template = I.MWUI.templates.box,
        type = ui.TYPE.Container,
        props = {},
        content = ui.content({ scrollPane }),
        userData = {
            contentElement = contentElement,
            scrollpanel = scrollPane,
        }
    }

    return layout
end

local function destroyTracker(window)
    auxUI.deepDestroy(window)
    if skillSelectPopup then
        auxUI.deepDestroy(skillSelectPopup)
        skillSelectPopup = nil
    end
end

local function createConfigWindow()

    local header = {
        type = ui.TYPE.Widget,
        props = {
            size = vector2(CONSTANTS.WindowSize.x, HeaderHeight)
        },
        content = ui.content({
            {
                type = ui.TYPE.Text,
                props = {
                    text = "SkillTracker Config",
                    textSize = 20,
                    textColor = constants.headerColor,
                    textShadowColor = util.color.rgb(0.0, 0.0, 0.0),

                    relativePosition = vector2(0.5, 0.5),
                    anchor = vector2(0.5, 0.5),
                },
            }
        })
    }

    local headerWrapper = {
        template = I.MWUI.templates.box,
        props = {},
        content = ui.content({header})
    }

    local listContent = createTrackerContent()

    local footer = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            size = vector2(CONSTANTS.WindowSize.x, FooterHeight),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.End,
        },
        content = ui.content({
            ZUI.Components.TextButton.create({
                text = "Add",
                textSize = 16,
                callback = function(evt, layout)
                    assert(trackedSkillsCache)
                    table.insert(trackedSkillsCache, 'None')
                    updateTrackerContent(listContent.userData.contentElement.layout)
                end,
            }),
            {
                type = ui.TYPE.Widget,
                props = { size = vector2(4, 0) }
            },            
            ZUI.Components.TextButton.create({
                text = "OK",
                textSize = 16,
                callback = function(evt, layout)
                    I.ZST.onTrackerConfigResult(trackedSkillsCache)
                end,
            }),
            {
                type = ui.TYPE.Widget,
                props = { size = vector2(4, 0) }
            },
        })
    }

    local footerWrapper = {
        template = I.MWUI.templates.box,
        props = {},
        content = ui.content({footer})
    }

    local window = {
        type = ui.TYPE.Flex,
        props = {
            propagateEvents = false,
            size = CONSTANTS.WindowSize,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content({
        }),
        userData = {
            scrollpanel = listContent.userData.scrollpanel
        }
    }



    window.content:add(header)
    window.content:add(listContent)
    window.content:add(footer)

    local wrapper = {
        template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        layer = 'Windows',
        userData = {
            window = window,
        },
        props = {
            propagateEvents = false,
            relativePosition = vector2(0.5, 0.5),
            anchor = vector2(0.5, 0.5),
        },
        content = ui.content({window})
    }

    local element = ui.create(wrapper)
    configWindow = element

    return element
end

return {
    create = createConfigWindow,
    destroy = destroyTracker,

    onMouseWheel = function(wheel)
        if not configWindow then
            return
        end

        local dir = wheel / math.abs(wheel)
        if skillSelectPopup then
            assert(skillSelectPopup.layout.userData and skillSelectPopup.layout.userData.scrollpanel)
            local scrollpanel = skillSelectPopup.layout.userData.scrollpanel
            ZUI.Components.Scrollpanel.moveScrollbarByItems(scrollpanel, -dir)
            ZUI.Components.Scrollpanel.updateContent(scrollpanel)
        else
            assert(configWindow.layout.userData and configWindow.layout.userData.window)
            local window = configWindow.layout.userData.window
            assert(window.userData.scrollpanel)
            local scrollpanel = window.userData.scrollpanel
            ZUI.Components.Scrollpanel.moveScrollbarByItems(scrollpanel, -dir)
            ZUI.Components.Scrollpanel.updateContent(scrollpanel)
        end
    end
}