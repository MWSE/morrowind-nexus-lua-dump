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
-- THEME & ASSETS
-- =============================================================================
local optionsSection = storage.playerSection('Settings/Completionist/Options')
local appearanceSection = storage.playerSection('Settings/Completionist/Appearance')

local THEME = {
    colors = {
        gold = util.color.rgb(223/255, 201/255, 159/255),
        white = util.color.rgb(1, 1, 1),
        grey = util.color.rgb(0.5, 0.5, 0.5),    
        done = util.color.rgb(46/255, 74/255, 212/255),
        dim = util.color.rgb(0.6, 0.6, 0.6),
        hover = util.color.rgb(0.3, 0.3, 0.3),
        masterHeader = util.color.rgb(0.8, 0.7, 0.5)
    },
    textures = {
        headerMid   = "Textures/menu_head_block_middle.dds",
        barGray     = "textures/menu_bar_gray.dds"
    },
    sounds = {
        open  = "Sound\\Fx\\item\\bookopen.wav",
        close = "Sound\\Fx\\item\\bookclose.wav",
        click = "Sound\\Fx\\menu\\item.wav" 
    }
}

-- =============================================================================
-- VIEW STATE
-- =============================================================================
local viewState = {
    menuWidget = nil,
    isOpen = false,
    selectedCategory = nil,
    selectedMaster = nil, 
    expandedMaster = nil, 
    expandedQuestId = nil,
    activeScrollPanel = nil,     -- Right Panel
    masterScrollPanel = nil,     -- Left Panel
    savedScrollPos = 0,          
    savedMasterScrollPos = 0   
}

local createMenu 

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

local function estimateTextHeight(text, width, fontSize)
    local size = fontSize or 14
    local charWidthAverage = size * 0.45 
    local charsPerLineEstimate = math.floor(width / charWidthAverage)
    if charsPerLineEstimate < 1 then charsPerLineEstimate = 1 end
    local charCount = #text
    local _, newlineCount = text:gsub("\n", "")
    local estimatedLines = math.ceil(charCount / charsPerLineEstimate) + newlineCount
    local lineHeight = size * 1.2 
    return (math.max(1, estimatedLines) * lineHeight) + 20
end

local function getScrollY(scrollPanel)
    if scrollPanel and scrollPanel.layout then
        local contentPane = scrollPanel.layout.content[1]
        if contentPane and contentPane.userData and contentPane.userData.scrollbar then
            local sb = contentPane.userData.scrollbar
            if sb.layout and sb.layout.content and sb.layout.content[1] then
                local area = sb.layout.content[1]
                if area.content and area.content[1] then
                    local handle = area.content[1]
                    return handle.props.position.y
                end
            end
        end
    end
    return 0
end

local function setScrollY(scrollPanel, yPos)
    if yPos and yPos > 0 and scrollPanel and scrollPanel.layout then
         local contentPane = scrollPanel.layout.content[1]
         if contentPane and contentPane.userData and contentPane.userData.scrollbar then
             local sb = contentPane.userData.scrollbar
             if sb.layout and sb.layout.content and sb.layout.content[1] then
                 local area = sb.layout.content[1]
                 if area.content and area.content[1] then
                     local handle = area.content[1]
                     handle.props.position = v2(handle.props.position.x, yPos)
                     sb:update() 
                 end
             end
             ZUI.Components.Scrollpanel.updateContent(scrollPanel)
         end
    end
end

local function saveScrollPosition()
    viewState.savedScrollPos = getScrollY(viewState.activeScrollPanel)
end

local function restoreScrollPosition(scrollPanel)
    setScrollY(scrollPanel, viewState.savedScrollPos)
end

-- =============================================================================
-- COMPONENT BUILDERS
-- =============================================================================

local function createProgressContent(leftWidth, fontHeader, fontDesc)
    local filter = viewState.expandedMaster or viewState.selectedMaster
    local completed, total, percent = Mechanics.getGlobalProgress(filter)
    
    local ratio = (total > 0) and (completed / total) or 0
    local barMaxWidth = leftWidth - 40 
    local barHeight = 14
    local fillWidth = math.floor(barMaxWidth * ratio)

    local titleText = filter and filter or "Global Progress"

    local progressBar = {
        type = ui.TYPE.Container,
        props = { size = v2(barMaxWidth, barHeight) },
        content = ui.content({
            {
                type = ui.TYPE.Image, 
                props = {
                    size = v2(barMaxWidth, barHeight),
                    color = util.color.rgb(0, 0, 0, 0.5),
                    resource = ui.texture({ path = THEME.textures.barGray }),
                    tileH = true, tileV = true,
                }
            },
            {
                type = ui.TYPE.Image,
                props = {
                    position = v2(0, 0),
                    size = v2(math.max(0, fillWidth), barHeight),
                    resource = ui.texture({ path = THEME.textures.barGray }), 
                    color = THEME.colors.done,
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
                        text = titleText, 
                        textSize = fontHeader, 
                        textColor = THEME.colors.gold, 
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
                        textColor = THEME.colors.white, 
                        textAlignH = ui.ALIGNMENT.Center 
                    }
                }
            }
        }
    }
end

-- =============================================================================
-- LEFT PANEL: MASTER LIST (ACCORDION)
-- =============================================================================
local function createMasterList(panelW, panelH, fontHeader, fontItem)
    local masters = Mechanics.getMasters()
    local contentWidth = panelW - 20 
    
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
    local function addItem(widget, height)
        contentLayout.content:add(widget)
        totalHeight = totalHeight + height
    end

    addItem(UIUtil.createPadding(0, 10), 10)

    for _, masterName in ipairs(masters) do
        local isExpanded = (viewState.expandedMaster == masterName)
        local headerHeight = fontItem + 18

        -- Master Header (No Icons, Left Aligned)
        addItem({
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                size = v2(contentWidth, headerHeight),
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Start,
            },
            content = ui.content {
                UIUtil.createPadding(10, 0),
                {
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = masterName,
                        textSize = fontItem + 2, 
                        textColor = isExpanded and THEME.colors.gold or THEME.colors.masterHeader,
                        textAlignH = ui.ALIGNMENT.Start
                    }
                }
            },
            events = {
                mouseClick = async:callback(function()
                    viewState.savedMasterScrollPos = getScrollY(viewState.masterScrollPanel)
                    
                    viewState.selectedCategory = nil
                    viewState.selectedMaster = nil
                    
                    if viewState.expandedMaster == masterName then
                        viewState.expandedMaster = nil
                    else
                        viewState.expandedMaster = masterName
                    end
                    
                    ambient.playSoundFile(THEME.sounds.click, { volume = 0.6 })
                    if viewState.menuWidget then viewState.menuWidget:destroy() end
                    createMenu()
                end)
            }
        }, headerHeight)

        -- Categories (if expanded)
        if isExpanded then
            local categories = Mechanics.getCategories(masterName)
            local catItemHeight = fontItem + 10
            
            if #categories == 0 then
                 addItem({
                    type = ui.TYPE.Text,
                    props = {
                        text = "   No categories.",
                        textSize = fontItem,
                        textColor = THEME.colors.dim,
                        size = v2(contentWidth, catItemHeight),
                        textAlignH = ui.ALIGNMENT.Start
                    }
                 }, catItemHeight)
            end

            for _, cat in ipairs(categories) do
                local isSelected = (viewState.selectedCategory == cat and viewState.selectedMaster == masterName)
                
                addItem({
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                        size = v2(contentWidth, catItemHeight),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Start, 
                    },
                    content = ui.content {
                        UIUtil.createPadding(20, 0), -- Indentation
                        {
                            type = ui.TYPE.Text,
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = cat,
                                textSize = fontItem,
                                textColor = isSelected and THEME.colors.white or THEME.colors.dim,
                                textAlignH = ui.ALIGNMENT.Start
                            }
                        }
                    },
                    events = {
                        mouseClick = async:callback(function()
                            viewState.savedMasterScrollPos = getScrollY(viewState.masterScrollPanel)
                            viewState.savedScrollPos = 0 
                            
                            viewState.selectedCategory = cat
                            viewState.selectedMaster = masterName 
                            
                            if viewState.menuWidget then viewState.menuWidget:destroy() end
                            createMenu()
                        end)
                    }
                }, catItemHeight)
            end
            addItem(UIUtil.createPadding(0, 5), 5) 
        end
    end

    contentLayout.props.size = v2(contentWidth, totalHeight)
    local contentElement = ui.create(contentLayout)

    local zuiScrollPanel = ZUI.Components.Scrollpanel.createVertical({
        size = v2(panelW, panelH),
        itemSize = v2(contentWidth, 30), 
        contentElement = contentElement,
        forceScrollbar = false, -- Conditional Scrollbar
    })

    viewState.masterScrollPanel = zuiScrollPanel
    
    if viewState.savedMasterScrollPos > 0 then
        setScrollY(zuiScrollPanel, viewState.savedMasterScrollPos)
    end

    return zuiScrollPanel
end

-- =============================================================================
-- RIGHT PANEL: QUEST LIST
-- =============================================================================
local function createQuestListPanel(panelW, panelH, fontHeader, fontModTitle, fontItem, fontDesc)
    
    fontDesc = fontDesc or 14 
    fontModTitle = fontModTitle or 17
    fontItem = fontItem or 16
    fontHeader = fontHeader or 19

    -- Empty State
    if not viewState.selectedCategory then 
        return { 
            type = ui.TYPE.Flex, 
            props = { 
                size = v2(panelW, panelH),
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center
            },
            content = ui.content {
                {
                     type = ui.TYPE.Text,
                     props = {
                         text = "Select a category from the left.",
                         textSize = fontItem,
                         textColor = THEME.colors.dim,
                         textAlignH = ui.ALIGNMENT.Center
                     }
                }
            }
        } 
    end
    
    local contentWidth = panelW - 20 
    
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
    local groups = Mechanics.getGroupedQuests(viewState.selectedCategory, viewState.selectedMaster)
    local questLog = self and types.Player.quests(self) or nil

    local function addItem(widget, height)
        contentLayout.content:add(widget)
        totalHeight = totalHeight + height
    end

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
                        textColor = THEME.colors.gold,
                        textAlignH = ui.ALIGNMENT.Start 
                    }
                }
            }
        }, groupHeaderHeight)

        -- Quests
        for _, q in ipairs(group.quests) do
            local currentQuest = q
            local isExpanded = (viewState.expandedQuestId == currentQuest.id)
            local isCompleted = Mechanics.checkQuestStatus(questLog, currentQuest)

            local textColor = THEME.colors.grey
            if isCompleted then
                textColor = THEME.colors.done
            elseif isExpanded then
                textColor = THEME.colors.white
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
                            textColor = textColor,
                            textAlignH = ui.ALIGNMENT.Start
                        }
                    }
                },
                events = {
                    mouseClick = async:callback(function()
                        saveScrollPosition() 
                        viewState.savedMasterScrollPos = getScrollY(viewState.masterScrollPanel)
                        
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
                local textWidth = contentWidth - 50 
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
                                autoSize = false, 
                                size = v2(textWidth, estHeight),
                                textAlignH = ui.ALIGNMENT.Start
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

    local zuiScrollPanel = ZUI.Components.Scrollpanel.createVertical({
        size = v2(panelW, panelH),
        itemSize = v2(contentWidth, fontItem + 8),
        contentElement = contentElement,
        forceScrollbar = true,
    })

    viewState.activeScrollPanel = zuiScrollPanel
    restoreScrollPosition(zuiScrollPanel)

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
    
    local headerHeight = fontModTitle + 4 
    local screenSize = ui.screenSize()
    
    local width = math.min(screenSize.x * 0.8, maxWidth)
    local height = math.min(screenSize.y * 0.75, maxHeight)

    local leftWidth = width * 0.35
    local rightWidth = width * 0.65
    
    local header = {
        type = ui.TYPE.Flex,
        props = { horizontal = true, size = v2(width, headerHeight), arrange = ui.ALIGNMENT.Center },
        content = ui.content {
            { 
                type = ui.TYPE.Image, 
                external = { grow = 1 }, 
                props = { 
                    size = v2(0, headerHeight), 
                    resource = ui.texture { path = THEME.textures.headerMid },
                    tileH = true,
                    tileV = false 
                } 
            },
            UIUtil.createPadding(10, 0),
            { 
                type = ui.TYPE.Text, 
                props = { 
                    text = "Completionist - A Morrowind Quest Tracker", 
                    textSize = fontModTitle, 
                    textColor = THEME.colors.gold, 
                    textAlignH = ui.ALIGNMENT.Center, 
                    textAlignV = ui.ALIGNMENT.Center, 
                    autoSize = true, 
                    size = v2(0, headerHeight) 
                } 
            },
            UIUtil.createPadding(10, 0),
            { 
                type = ui.TYPE.Image, 
                external = { grow = 1 }, 
                props = { 
                    size = v2(0, headerHeight), 
                    resource = ui.texture { path = THEME.textures.headerMid },
                    tileH = true, 
                    tileV = false 
                } 
            }
        }
    }

    local progressBoxHeight = 100
    local masterListHeight = math.max(100, (height - 50) - progressBoxHeight)
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
                            -- Left Panel
                            {
                                type = ui.TYPE.Flex,
                                props = { horizontal = false },
                                content = ui.content {
                                    UIUtil.createBox(leftWidth, progressBoxHeight, ui.content(createProgressContent(leftWidth, fontHeader, fontDesc))),
                                    
                                    UIUtil.createBox(leftWidth, masterListHeight, ui.content {
                                        UIUtil.createPadding(0, 0),
                                        { type = ui.TYPE.Flex, content = ui.content({ createMasterList(leftWidth - 10, masterListHeight - 20, fontHeader, fontItem) }) }
                                    })
                                }
                            },
                            -- Right Panel
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
        if playSound then ambient.playSoundFile(THEME.sounds.close, { volume = 0.4 }) end
    else
        createMenu()
        viewState.isOpen = true
        I.UI.setMode('Interface', { windows = {} })
        if playSound then ambient.playSoundFile(THEME.sounds.open, { volume = 0.4 }) end
    end
end

local function isVisible()
    return viewState.isOpen
end

local function onMouseWheel(wheel)
    if not isVisible() then return end
    local dir = wheel / math.abs(wheel)
    
    if viewState.activeScrollPanel then
        ZUI.Components.Scrollpanel.moveScrollbarByItems(viewState.activeScrollPanel, -dir)
        ZUI.Components.Scrollpanel.updateContent(viewState.activeScrollPanel)
        saveScrollPosition()
    end
end

return {
    toggleMenu = toggleMenu,
    isVisible = isVisible,
    onMouseWheel = onMouseWheel
}