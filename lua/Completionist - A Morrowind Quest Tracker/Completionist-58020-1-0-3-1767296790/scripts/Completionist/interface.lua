local ui = require('openmw.ui')
local util = require('openmw.util')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local ambient = require("openmw.ambient")
local async = require('openmw.async')
local storage = require('openmw.storage')
local types = require('openmw.types')
local self = require('openmw.self')
local v2 = util.vector2

local Mechanics = require('scripts.Completionist.mechanics')
local UIUtil = require('scripts.Completionist.utils')
local ZUI = require('scripts.ZModUtils.UI') 

-- =============================================================================
-- CONFIG & CONSTANTS
-- =============================================================================
local optionsSection = storage.playerSection('Settings/Completionist/Options')
local appearanceSection = storage.playerSection('Settings/Completionist/Appearance')

local COLORS = {
    gold = util.color.rgb(223/255, 201/255, 159/255),
    white = util.color.rgb(1, 1, 1),
    grey = util.color.rgb(0.5, 0.5, 0.5),    
    done = util.color.rgb(46/255, 74/255, 212/255)
}

-- =============================================================================
-- VIEW STATE
-- =============================================================================
local viewState = {
    menuWidget = nil,
    isOpen = false,
    selectedCategory = nil,
    expandedQuestId = nil,
    activeScrollPanel = nil, 
    savedScrollPos = 0
}

local createMenu 

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

local function estimateTextHeight(text, width, fontSize)
    
    local size = fontSize or 14
    
    local charWidth = size * 0.5
    local charsPerLine = math.floor(width / charWidth)
    if charsPerLine < 1 then charsPerLine = 1 end
    
    local lineCount = math.ceil(#text / charsPerLine)
    
    -- Count explicit newlines
    local _, newlines = text:gsub("\n", "")
    lineCount = lineCount + newlines
    
    local lineHeight = size + 2 
    return (math.max(1, lineCount) * lineHeight) + 4
end

local function saveScrollPosition()
    if viewState.activeScrollPanel and viewState.activeScrollPanel.layout then
        local contentPane = viewState.activeScrollPanel.layout.content[1]
        if contentPane and contentPane.userData and contentPane.userData.scrollbar then
            local sb = contentPane.userData.scrollbar
            if sb.layout and sb.layout.content and sb.layout.content[1] then
                local area = sb.layout.content[1]
                if area.content and area.content[1] then
                    local handle = area.content[1]
                    viewState.savedScrollPos = handle.props.position.y
                    return
                end
            end
        end
    end
    viewState.savedScrollPos = 0
end

local function restoreScrollPosition(scrollPanel)
    if viewState.savedScrollPos and viewState.savedScrollPos > 0 then
         local contentPane = scrollPanel.layout.content[1]
         if contentPane and contentPane.userData and contentPane.userData.scrollbar then
             local sb = contentPane.userData.scrollbar
             if sb.layout and sb.layout.content and sb.layout.content[1] then
                 local area = sb.layout.content[1]
                 if area.content and area.content[1] then
                     local handle = area.content[1]
                     handle.props.position = v2(handle.props.position.x, viewState.savedScrollPos)
                     sb:update() 
                 end
             end
             ZUI.Components.Scrollpanel.updateContent(scrollPanel)
         end
    end
end

-- =============================================================================
-- COMPONENT BUILDERS
-- =============================================================================

local function createProgressContent(leftWidth, fontHeader, fontDesc)
    local completed, total, percent = Mechanics.getGlobalProgress()
    local ratio = (total > 0) and (completed / total) or 0
    local barMaxWidth = leftWidth - 40
    local barHeight = 14
    local fillWidth = math.floor(barMaxWidth * ratio)

    local progressBar = {
        type = ui.TYPE.Container,
        props = { size = v2(barMaxWidth, barHeight) },
        content = ui.content({
            {
                type = ui.TYPE.Image, 
                props = {
                    size = v2(barMaxWidth, barHeight),
                    color = util.color.rgb(0, 0, 0, 0.5),
                    resource = ui.texture({ path = 'textures/menu_bar_gray.dds' }),
                    tileH = true, tileV = true,
                }
            },
            {
                type = ui.TYPE.Image,
                props = {
                    position = v2(0, 0),
                    size = v2(math.max(0, fillWidth), barHeight),
                    resource = ui.texture({ path = 'textures/menu_bar_gray.dds' }), 
                    color = COLORS.done,
                    tileH = true, tileV = true,
                }
            },
            {
               type = ui.TYPE.Widget,
               template = I.MWUI.templates.borders,
               props = { size = v2(barMaxWidth, barHeight) }
            }
        })
    }

    return {
        {
            type = ui.TYPE.Flex,
            props = {
                horizontal = false,
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
                size = v2(leftWidth, 100)
            },
            content = ui.content {
                {
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textHeader,
                    props = { 
                        text = "Progress", 
                        textSize = fontHeader, 
                        textColor = COLORS.gold, 
                        textAlignH = ui.ALIGNMENT.Center 
                    }
                },
                UIUtil.createPadding(0, 8),
                progressBar,
                UIUtil.createPadding(0, 5),
                {
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = { 
                        text = string.format("%d / %d Quests (%d%%)", completed, total, percent), 
                        textSize = fontDesc,
                        textColor = COLORS.white, 
                        textAlignH = ui.ALIGNMENT.Center 
                    }
                }
            }
        }
    }
end

local function createCategoryList(leftWidth, fontHeader, fontItem)
    local items = {}
    local categories = Mechanics.getCategories()
    if not viewState.selectedCategory and #categories > 0 then
        viewState.selectedCategory = categories[1]
    end
    table.insert(items, UIUtil.createPadding(0, 25)) 
    
    table.insert(items, {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                size = v2(leftWidth, 30),
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center
            },
            content = ui.content {
                {
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textHeader,
                    props = {
                        text = "Categories",
                        textSize = fontHeader,
                        textColor = COLORS.gold,
                        textAlignH = ui.ALIGNMENT.Center,
                        autoSize = true
                    }
                }
            }
    })

    table.insert(items, UIUtil.createPadding(0, 5))
    for _, cat in ipairs(categories) do
        local currentCat = cat
        local isSelected = (viewState.selectedCategory == currentCat)
        table.insert(items, {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                size = v2(leftWidth, fontItem + 14), 
                align = ui.ALIGNMENT.Start,
                arrange = ui.ALIGNMENT.Start,
            },
            content = ui.content {
                UIUtil.createPadding(20, 0),
                {
                    template = I.MWUI.templates.textNormal,
                    type = ui.TYPE.Text,
                    props = {
                        text = currentCat,
                        textSize = fontItem, 
                        textColor = isSelected and COLORS.gold or util.color.rgb(0.4, 0.4, 0.4)
                    }
                }
            },
            events = {
                mouseClick = async:callback(function()
                    viewState.savedScrollPos = 0 
                    if viewState.menuWidget then viewState.menuWidget:destroy() end
                    viewState.selectedCategory = currentCat
                    createMenu()
                end)
            }
        })
    end
    return items
end

-- =============================================================================
-- QUEST LIST PANEL (MODIFIED FOR ZERKISH SCROLLING)
-- =============================================================================
local function createQuestListPanel(panelW, panelH, fontHeader, fontModTitle, fontItem, fontDesc)
    
    fontDesc = fontDesc or 14 
    fontModTitle = fontModTitle or 17
    fontItem = fontItem or 16
    fontHeader = fontHeader or 19

    if not viewState.selectedCategory then 
        return { type = ui.TYPE.Widget, props = { size = v2(panelW, panelH) } } 
    end
    
    local contentWidth = panelW - 20 
    
    -- Definition of contentLayout
    local contentLayout = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            size = v2(contentWidth, 0), 
            align = ui.ALIGNMENT.Start,
            arrange = ui.ALIGNMENT.Start
        },
        content = ui.content({})
    }

    local totalHeight = 0
    local groups = Mechanics.getGroupedQuests(viewState.selectedCategory)
    local questLog = self and types.Player.quests(self) or nil

    local function addItem(widget, height)
        contentLayout.content:add(widget)
        totalHeight = totalHeight + height
    end

    -- Loop Logic
    for _, group in ipairs(groups) do
        local cleanName = group.name:gsub("%s*%(.*%)", "")
        local groupHeaderHeight = fontModTitle + 8 
        
        -- Group Header
        addItem({
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                size = v2(contentWidth, groupHeaderHeight),
                align = ui.ALIGNMENT.Start,
                arrange = ui.ALIGNMENT.Start 
            },
            content = ui.content {
                UIUtil.createPadding(25, 0), 
                {
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textHeader,
                    props = {
                        text = cleanName,
                        textSize = fontModTitle,
                        textColor = COLORS.gold,
                        textAlignH = ui.ALIGNMENT.Start 
                    }
                }
            }
        }, groupHeaderHeight)

        -- Quests Loop
        for _, q in ipairs(group.quests) do
            local currentQuest = q
            local isExpanded = (viewState.expandedQuestId == currentQuest.id)
            local isCompleted = Mechanics.checkQuestStatus(questLog, currentQuest.id)

            local textColor = COLORS.grey
            if isCompleted then
                textColor = COLORS.done
            elseif isExpanded then
                textColor = COLORS.white
            end

            local itemHeight = fontItem + 8
            
            -- Quest Title
            addItem({
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    size = v2(contentWidth, itemHeight),
                    align = ui.ALIGNMENT.Start,
                    arrange = ui.ALIGNMENT.Start
                },
                content = ui.content {
                    UIUtil.createPadding(25, 0),
                    {
                        template = I.MWUI.templates.textNormal,
                        type = ui.TYPE.Text,
                        props = {
                            text = currentQuest.name,
                            textSize = fontItem,
                            textColor = textColor
                        }
                    }
                },
                events = {
                    mouseClick = async:callback(function()
                        saveScrollPosition()
                        if input.isShiftPressed() then
                            Mechanics.toggleManualCompletion(currentQuest.id)
                        else
                            if viewState.expandedQuestId == currentQuest.id then
                                viewState.expandedQuestId = nil
                            else
                                viewState.expandedQuestId = currentQuest.id
                            end
                        end
                        if viewState.menuWidget then viewState.menuWidget:destroy() end
                        createMenu()
                    end)
                }
            }, itemHeight)

            -- Expanded Description
            if isExpanded then
                local textWidth = contentWidth - 120 
                local estHeight = estimateTextHeight(currentQuest.text, textWidth, fontDesc)
                
                addItem({
                    type = ui.TYPE.Flex,
                    props = { 
                        horizontal = true, 
                        size = v2(contentWidth, estHeight),
                        arrange = ui.ALIGNMENT.Start 
                    },
                    content = ui.content {
                        UIUtil.createPadding(25, 0), 
                        {
                            template = I.MWUI.templates.textNormal,
                            type = ui.TYPE.Text,
                            props = {
                                text = currentQuest.text,
                                textSize = fontDesc,
                                textColor = util.color.rgb(0.7, 0.7, 0.6),
                                multiline = true,
                                wordWrap = true,
                                size = v2(textWidth, estHeight),
                            }
                        }
                    }
                }, estHeight)
                
                addItem(UIUtil.createPadding(0, 5), 5) 
            end
        end
        addItem(UIUtil.createPadding(0, 15), 15)
    end

    contentLayout.props.size = v2(contentWidth, totalHeight)
    local contentElement = ui.create(contentLayout)

    -- 1. Create ZUI ScrollPanel
    local zuiScrollPanel = ZUI.Components.Scrollpanel.createVertical({
        size = v2(panelW, panelH),
        itemSize = v2(contentWidth, fontItem + 8),
        contentElement = contentElement,
        forceScrollbar = true,
    })

    viewState.activeScrollPanel = zuiScrollPanel
    restoreScrollPosition(zuiScrollPanel)

    -- 2. Create Wrapper
    local wrapper = {
        type = ui.TYPE.Container,
        props = {
            size = v2(panelW, panelH),
        },
        content = ui.content({ zuiScrollPanel })
    }

    return wrapper
end

-- =============================================================================
-- MAIN RENDER FUNCTION
-- =============================================================================

createMenu = function()
    local maxWidth = appearanceSection:get("MaxWidth") or 950
    local maxHeight = appearanceSection:get("MaxHeight") or 1000
    local fontModTitle = appearanceSection:get("FontModTitle") or 17
    local fontHeader = appearanceSection:get("FontHeader") or 19
    local fontItem = appearanceSection:get("FontItem") or 16
    local fontDesc = appearanceSection:get("FontDesc") or 14
    
    local headerHeight = fontModTitle + 10
    local screenSize = ui.screenSize()
    
    local width = math.min(screenSize.x * 0.8, maxWidth)
    local height = math.min(screenSize.y * 0.75, maxHeight)
    local leftWidth = width * 0.30
    local rightWidth = width * 0.70
    
    local header = {
        type = ui.TYPE.Flex,
        props = { horizontal = true, size = v2(width, headerHeight), arrange = ui.ALIGNMENT.Center },
        content = ui.content {
            { type = ui.TYPE.Image, external = { grow = 1 }, props = { size = v2(0, headerHeight), resource = ui.texture { path = "Textures/menu_head_block_middle.dds" } } },
            UIUtil.createPadding(50, 0),
            { type = ui.TYPE.Text, props = { text = "Completionist - Morrowind Quests Completion Tracker", textSize = fontModTitle, textColor = COLORS.gold, textAlignH = ui.ALIGNMENT.Center, textAlignV = ui.ALIGNMENT.Center, autoSize = true, size = v2(0, headerHeight) } },
            UIUtil.createPadding(50, 0),
            { type = ui.TYPE.Image, external = { grow = 1 }, props = { size = v2(0, headerHeight), resource = ui.texture { path = "Textures/menu_head_block_middle.dds" } } }
        }
    }

    local progressBoxHeight = 100
    local categoryBoxHeight = math.max(100, (height - 50) - progressBoxHeight)
    local rightPanelContentHeight = height - 50 - 20

    local window = {
        type = ui.TYPE.Container,
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = { relativePosition = v2(0.5, 0.5), anchor = v2(0.5, 0.5), size = v2(width, height) },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = { horizontal = false, align = ui.ALIGNMENT.Center },
                content = ui.content {
                    header,
                    {
                        type = ui.TYPE.Flex,
                        props = { horizontal = true },
                        content = ui.content {
                            {
                                type = ui.TYPE.Flex,
                                props = { horizontal = false },
                                content = ui.content {
                                    UIUtil.createBox(leftWidth, progressBoxHeight, ui.content(createProgressContent(leftWidth, fontHeader, fontDesc))),
                                    UIUtil.createBox(leftWidth, categoryBoxHeight, ui.content {
                                        UIUtil.createPadding(0, 0),
                                        { type = ui.TYPE.Flex, content = ui.content(createCategoryList(leftWidth, fontHeader, fontItem)) }
                                    })
                                }
                            },
                            UIUtil.createBox(rightWidth, height - 50, ui.content {
                                UIUtil.createPadding(15, 10),
                                { 
                                    type = ui.TYPE.Flex, 
                                    content = ui.content({ 
                                        createQuestListPanel(rightWidth - 30, rightPanelContentHeight, fontHeader, fontModTitle, fontItem, fontDesc) 
                                    }) 
                                }
                            })
                        }
                    }
                }
            }
        }
    }
    viewState.menuWidget = ui.create(window)
end

-- =============================================================================
-- PUBLIC INTERFACE
-- =============================================================================

local function toggleMenu()
    local playSound = optionsSection:get("PlaySound")
    if viewState.isOpen then
        if viewState.menuWidget then viewState.menuWidget:destroy() end
        viewState.menuWidget = nil
        viewState.isOpen = false
        I.UI.removeMode('Interface')
        if playSound then ambient.playSoundFile("Sound\\Fx\\item\\bookclose.wav", { volume = 0.4 }) end
    else
        createMenu()
        viewState.isOpen = true
        I.UI.setMode('Interface', { windows = {} })
        if playSound then ambient.playSoundFile("Sound\\Fx\\item\\bookopen.wav", { volume = 0.4 }) end
    end
end

local function isVisible()
    return viewState.isOpen
end

--s croll handler implementation
local function onMouseWheel(wheel)
    if not isVisible() or not viewState.activeScrollPanel then
        return
    end

    -- Normalize direction (1 or -1)
    local dir = wheel / math.abs(wheel)

    -- Use ZUI helper to move scrollbar
    ZUI.Components.Scrollpanel.moveScrollbarByItems(viewState.activeScrollPanel, -dir) --
    ZUI.Components.Scrollpanel.updateContent(viewState.activeScrollPanel) --
    
    -- Save position for consistency if user clicks/expands items later
    saveScrollPosition()
end

return {
    toggleMenu = toggleMenu,
    isVisible = isVisible,
    onMouseWheel = onMouseWheel
}