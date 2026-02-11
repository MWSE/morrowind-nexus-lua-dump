local ui = require('openmw.ui')
local util = require('openmw.util')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local ambient = require("openmw.ambient")
local async = require('openmw.async')
local storage = require('openmw.storage')
local v2 = util.vector2

local Mechanics = require('scripts.Perfectionist.mechanics')
local UIUtil = require('scripts.Perfectionist.utils')

-- =============================================================================
-- THEME & CONFIGURATION
-- =============================================================================
local optionsSection = storage.playerSection('Settings/Perfectionist/Options')
local appearanceSection = storage.playerSection('Settings/Perfectionist/Appearance')

local THEME = {
    colors = {
        gold = util.color.rgb(223/255, 201/255, 159/255),
        lightGold = util.color.rgb(240/255, 220/255, 180/255), 
        white = util.color.rgb(0.9, 0.9, 0.9),
        grey = util.color.rgb(0.5, 0.5, 0.5),    
        done = util.color.rgb(46/255, 74/255, 212/255), 
        dim = util.color.rgb(0.6, 0.6, 0.6), 
        mutedGreen = util.color.rgb(0.35, 0.55, 0.35), 
        perfect = util.color.rgb(1.0, 0.8, 0.2)
    },
    textures = {
        headerMid   = "Textures/menu_head_block_middle.dds",
        barGray     = "textures/menu_bar_gray.dds"
    },
    sounds = {
        open  = "Sound\\Fx\\item\\bookopen.wav",
        close = "Sound\\Fx\\item\\bookclose.wav"
    }
}

local viewState = {
    menuWidget = nil,
    isOpen = false,
}

local createMenu 

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

local function estimateTextHeight(text, width, fontSize)
    if not text or text == "" then return 0 end
    local size = fontSize or 14
    local charWidthAverage = size * 0.5 
    local charsPerLineEstimate = math.floor(width / charWidthAverage)
    if charsPerLineEstimate < 1 then charsPerLineEstimate = 1 end

    local charCount = #text
    local _, newlineCount = text:gsub("\n", "")

    local estimatedLines = math.ceil(charCount / charsPerLineEstimate) + newlineCount
    
    local lineHeight = size * 1.3 
    return (math.max(1, estimatedLines) * lineHeight)
end

local function createHorizontalSeparator(width)
    return {
        type = ui.TYPE.Image,
        props = {
            size = v2(width, 1),
            resource = ui.texture({ path = THEME.textures.barGray }),
            color = THEME.colors.grey,
            alpha = 0.5 
        }
    }
end

-- =============================================================================
-- COMPONENTS
-- =============================================================================

local function createLevelProgressBarContent(width, fontSizeHeader, fontDesc)
    local progress = Mechanics.getLevelProgress() 
    local max = 10
    local ratio = math.min(1.0, progress / max)
    
    local barMaxWidth = width - 40 
    local barHeight = 12
    local fillWidth = math.floor(barMaxWidth * ratio)

    local fillColor = THEME.colors.done
    if progress >= 10 then fillColor = THEME.colors.perfect end

    local progressBar = {
        type = ui.TYPE.Container,
        props = { size = v2(barMaxWidth, barHeight) },
        content = ui.content({
            -- Background
            {
                type = ui.TYPE.Image, 
                props = {
                    size = v2(barMaxWidth, barHeight),
                    color = util.color.rgb(0, 0, 0, 0.5),
                    resource = ui.texture({ path = THEME.textures.barGray }),
                    tileH = true, tileV = true,
                }
            },
            -- Fill
            {
                type = ui.TYPE.Image,
                props = {
                    position = v2(0, 0),
                    size = v2(math.max(0, fillWidth), barHeight),
                    resource = ui.texture({ path = THEME.textures.barGray }), 
                    color = fillColor,
                    tileH = true, tileV = true,
                }
            },
            -- Border
            {
               type = ui.TYPE.Widget,
               template = I.MWUI.templates.borders,
               props = { size = v2(barMaxWidth, barHeight) }
            }
        })
    }

    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
            size = v2(width, 70) 
        },
        content = ui.content {
            UIUtil.createPadding(0, 5), 
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textHeader,
                props = { 
                    text = "Level Progress", 
                    textSize = fontSizeHeader, 
                    textColor = THEME.colors.gold, 
                    textAlignH = ui.ALIGNMENT.Center 
                }
            },
            UIUtil.createPadding(0, 5),
            progressBar,
            UIUtil.createPadding(0, 5),
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = { 
                    text = string.format("%d / 10 (Major/Minor)", progress), 
                    textSize = fontDesc,
                    textColor = THEME.colors.dim, 
                    textAlignH = ui.ALIGNMENT.Center 
                }
            }
        }
    }
end

local function createAttributeRow(attrKey, width, col1W, col2W, minRowHeight, fontSizeContent)
    local displayName = Mechanics.getAttributeName(attrKey)
    local ups, allSkills = Mechanics.getAttributeProgress(attrKey)
    local multiplier = Mechanics.getMultiplier(ups)
    
    local classContributors = {}
    local miscContributors = {}

    for _, skill in ipairs(allSkills) do
        if skill.diff > 0 then
            local txt = string.format("%s +%d", skill.name, skill.diff)
            if skill.isClassSkill then
                table.insert(classContributors, txt)
            else
                table.insert(miscContributors, txt)
            end
        end
    end
    
    local classText = table.concat(classContributors, ", ")
    local miscText = table.concat(miscContributors, ", ")
    local isEmpty = (classText == "" and miscText == "")

    local multColor = THEME.colors.dim
    local nameColor = THEME.colors.dim

    if multiplier >= 5 then
        multColor = THEME.colors.perfect
        nameColor = THEME.colors.gold
    elseif multiplier > 1 then
        multColor = THEME.colors.mutedGreen 
        nameColor = THEME.colors.white
    end
    
    -- Dynamic Height Calculation
    local skillTextWidth = col2W - 20
    local hClass = estimateTextHeight(classText, skillTextWidth, fontSizeContent)
    local hMisc = estimateTextHeight(miscText, skillTextWidth, fontSizeContent)
    local totalTextHeight = hClass + hMisc
    
    if isEmpty then
        totalTextHeight = estimateTextHeight("-", skillTextWidth, fontSizeContent)
    end

    local dynamicRowHeight = math.max(minRowHeight, totalTextHeight + 10)
    local attrNameWidth = col1W - 65 
    local multWidth = 30

    -- Build Skill Column Content
    local skillContentElements = {}
    
    if isEmpty then
        table.insert(skillContentElements, {
            template = I.MWUI.templates.textNormal,
            type = ui.TYPE.Text,
            props = {
                text = "-",
                textSize = fontSizeContent,
                textColor = THEME.colors.dim,
                autoSize = true,
                textAlignH = ui.ALIGNMENT.Center
            }
        })
    else
        if classText ~= "" then
            table.insert(skillContentElements, {
                template = I.MWUI.templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text = classText,
                    textSize = fontSizeContent,
                    textColor = THEME.colors.lightGold,
                    multiline = true,
                    wordWrap = true,
                    autoSize = false,
                    size = v2(skillTextWidth, hClass),
                    textAlignH = ui.ALIGNMENT.Center
                }
            })
        end
        if miscText ~= "" then
            table.insert(skillContentElements, {
                template = I.MWUI.templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text = miscText,
                    textSize = fontSizeContent,
                    textColor = THEME.colors.white,
                    multiline = true,
                    wordWrap = true,
                    autoSize = false,
                    size = v2(skillTextWidth, hMisc),
                    textAlignH = ui.ALIGNMENT.Center
                }
            })
        end
    end

    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            size = v2(width, dynamicRowHeight),
            align = ui.ALIGNMENT.Center, 
            arrange = ui.ALIGNMENT.Start
        },
        content = ui.content {
            -- Column 1: Attribute & Multiplier
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    size = v2(col1W, dynamicRowHeight),
                    align = ui.ALIGNMENT.Center 
                },
                content = ui.content {
                    UIUtil.createPadding(20, 0), 
                    {
                        template = I.MWUI.templates.textNormal,
                        type = ui.TYPE.Text,
                        props = {
                            text = displayName,
                            textSize = fontSizeContent, 
                            textColor = nameColor,
                            autoSize = false, 
                            size = v2(attrNameWidth, dynamicRowHeight),
                            textAlignV = ui.ALIGNMENT.Center,
                            textAlignH = ui.ALIGNMENT.Start
                        }
                    },
                    { type = ui.TYPE.Flex, props = { resource = { grow = 1 } } }, 
                    {
                        template = I.MWUI.templates.textNormal,
                        type = ui.TYPE.Text,
                        props = {
                            text = string.format("x%d", multiplier),
                            textSize = fontSizeContent,
                            textColor = multColor,
                            autoSize = false,
                            size = v2(multWidth, dynamicRowHeight),
                            textAlignV = ui.ALIGNMENT.Center,
                            textAlignH = ui.ALIGNMENT.End
                        }
                    },
                    UIUtil.createPadding(15, 0),
                }
            },
            
            -- Column 2: Skills
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false, 
                    size = v2(col2W, dynamicRowHeight),
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center 
                },
                content = ui.content(skillContentElements)
            }
        },
        userData = { height = dynamicRowHeight } 
    }
end

-- =============================================================================
-- MAIN RENDER LOGIC
-- =============================================================================

createMenu = function()
    -- Force a logic update to ensure data is fresh when opening the menu
    Mechanics.onUpdate(100) -- Force check with a large dt

    -- Font Settings
    local fontModTitle = appearanceSection:get("FontModTitle") or 17 
    local fontHeader = appearanceSection:get("FontHeader") or 19
    local fontItem = appearanceSection:get("FontItem") or 16
    local fontDesc = 14

    local sizeLevelHeader = fontHeader - 3 
    local sizeTableHeader = fontItem 
    local sizeRowContent = fontItem - 2 

    -- Window Dimensions
    local screenSize = ui.screenSize()
    local totalWidth = math.min(screenSize.x * 0.5, 600) 
    local contentWidth = totalWidth - 20 
    
    local col1Width = contentWidth * 0.40
    local col2Width = contentWidth * 0.60
    
    local headerHeight = fontModTitle + 4 
    
    -- Dimensions: Box 1 (Progress)
    local progressContentHeight = 70
    local progressBoxHeight = progressContentHeight + 10 

    -- Dimensions: Box 2 (Table)
    local tableHeaderHeight = 30     
    local minRowHeight = sizeRowContent + 14 
    local tableTopMargin = 10 
    
    local listContent = {}
    local currentTableContentHeight = 0
    
    local attributes = Mechanics.getAttributes()
    for i, attr in ipairs(attributes) do
        local rowWidget = createAttributeRow(attr, contentWidth, col1Width, col2Width, minRowHeight, sizeRowContent)
        table.insert(listContent, rowWidget)
        
        currentTableContentHeight = currentTableContentHeight + rowWidget.userData.height
        
        if i < #attributes then
             table.insert(listContent, createHorizontalSeparator(contentWidth))
             currentTableContentHeight = currentTableContentHeight + 1 
        end
    end

    local tableTotalContentHeight = tableTopMargin + tableHeaderHeight + currentTableContentHeight + 5 
    local tableBoxHeight = tableTotalContentHeight + 10

    local totalWindowHeight = headerHeight + progressBoxHeight + tableBoxHeight + 15

    -- Build Header
    local header = {
        type = ui.TYPE.Flex,
        props = { horizontal = true, size = v2(totalWidth, headerHeight), arrange = ui.ALIGNMENT.Center },
        content = ui.content {
            { 
                type = ui.TYPE.Image, external = { grow = 1 }, 
                props = { size = v2(0, headerHeight), resource = ui.texture { path = THEME.textures.headerMid }, tileH = true, tileV = false } 
            },
            UIUtil.createPadding(10, 0),
            { 
                type = ui.TYPE.Text, 
                props = { 
                    text = "Perfectionist - A Morrowind Skill Tracker", 
                    textSize = fontModTitle, 
                    textColor = THEME.colors.gold, 
                    autoSize = true, 
                    size = v2(0, headerHeight),
                    textAlignV = ui.ALIGNMENT.Center
                } 
            },
            UIUtil.createPadding(10, 0),
            { 
                type = ui.TYPE.Image, external = { grow = 1 }, 
                props = { size = v2(0, headerHeight), resource = ui.texture { path = THEME.textures.headerMid }, tileH = true, tileV = false } 
            }
        }
    }

    -- Build Box 1 (Progress)
    local progressBoxContent = createLevelProgressBarContent(totalWidth, sizeLevelHeader, fontDesc)
    local progressBox = UIUtil.createBox(totalWidth, progressBoxHeight, ui.content({
        UIUtil.createPadding(0, 0), 
        {
            type = ui.TYPE.Flex,
            props = { horizontal = false, align = ui.ALIGNMENT.Center, size = v2(contentWidth, progressContentHeight) },
            content = ui.content({ progressBoxContent })
        }
    }))

    -- Build Box 2 (Table)
    local tableLayout = {
        type = ui.TYPE.Flex,
        props = { horizontal = false, align = ui.ALIGNMENT.Start, size = v2(contentWidth, tableTotalContentHeight) },
        content = ui.content({})
    }

    -- Table Header
    tableLayout.content:add(UIUtil.createPadding(0, tableTopMargin))
    tableLayout.content:add({
        type = ui.TYPE.Flex,
        props = { horizontal = true, size = v2(contentWidth, tableHeaderHeight), align = ui.ALIGNMENT.Center }, 
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = { size = v2(col1Width, tableHeaderHeight), horizontal = true, align = ui.ALIGNMENT.Center },
                content = ui.content {
                    UIUtil.createPadding(20, 0), 
                    {
                        type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
                        props = { text = "Attribute / Mult.", textSize = sizeTableHeader, textColor = THEME.colors.gold }
                    }
                }
            },
            {
                type = ui.TYPE.Flex,
                props = { size = v2(col2Width, tableHeaderHeight), horizontal = true, align = ui.ALIGNMENT.Center },
                content = ui.content {
                    UIUtil.createPadding(5, 0),
                    {
                        type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
                        props = { text = "Contributing Skills", textSize = sizeTableHeader, textColor = THEME.colors.gold }
                    }
                }
            }
        }
    })
    tableLayout.content:add(createHorizontalSeparator(contentWidth))

    -- Rows
    for _, item in ipairs(listContent) do
        tableLayout.content:add(item)
    end
    tableLayout.content:add(UIUtil.createPadding(0, 2))

    local tableBox = UIUtil.createBox(totalWidth, tableBoxHeight, ui.content({
        UIUtil.createPadding(0, 0),
        {
            type = ui.TYPE.Flex,
            props = { horizontal = false, align = ui.ALIGNMENT.Center, size = v2(contentWidth, tableTotalContentHeight) },
            content = ui.content({ tableLayout })
        }
    }))

    -- Window Composition
    local windowProps = {
        relativePosition = v2(0.98, 0.03), 
        anchor = v2(1, 0), 
        position = v2(0, 0), 
        size = v2(totalWidth, totalWindowHeight)
    }

    local window = {
        type = ui.TYPE.Container,
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = windowProps,
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = { horizontal = false, align = ui.ALIGNMENT.Center },
                content = ui.content {
                    header,
                    progressBox,
                    tableBox
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
    return -- Scroll disabled
end

return {
    toggleMenu = toggleMenu,
    isVisible = isVisible,
    onMouseWheel = onMouseWheel
}