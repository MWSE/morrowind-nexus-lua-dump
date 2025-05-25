local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local input = require('openmw.input')
local storage = require('openmw.storage')
local core = require('openmw.core')
local l10n = core.l10n('OmwAchievements')
local interfaces = require('openmw.interfaces')

--- ################################# ---

local playerSettings = storage.playerSection('Settings/OmwAchievements/Options')
local achievements = require('scripts.omw_achievements.achievements.achievements')

local v2 = util.vector2
local showable = nil
local achievementsAmount = #achievements

--- ################################# ---

hiddenIndexes = {}

for i = 1, achievementsAmount do
    if achievements[i].hidden == true then
        table.insert(hiddenIndexes, i)
    end
end

--- ################################# ---

current_MAC_section = "all"

function deepCopy(tbl)
    local newTbl = {}
    for i = 1, #tbl do
        table.insert(newTbl, tbl[i])
    end
    return newTbl
end

local function updateHidden(mode)

    for i = 1, achievementsAmount do
        for j = 1, #hiddenIndexes do
            if i == hiddenIndexes[j] then

                if mode == true then
                    achievements[i].hidden = true
                elseif mode == false then
                    achievements[i].hidden = false
                end

            end
        end
    end

end

function getAchievements()

    if playerSettings:get('show_hidden') == true then
        updateHidden(false)
        return achievements
    elseif playerSettings:get('show_hidden') == false then
        updateHidden(true)
        return achievements
    end

end

function getGMSTcolor(colorType)
    local gmstTextColorNormal = core.getGMST('fontcolor_color_normal')
    local gmstTextColorActive = core.getGMST('fontcolor_color_active')

    if colorType == "normal" then
        gmstString = gmstTextColorNormal
    elseif colorType == "active" then
        gmstString = gmstTextColorActive
    end

    local t = {}
    for num in gmstString:gmatch("[%d%.]+") do
        table.insert(t, tonumber(num))
    end
    local r, g, b = table.unpack(t)
    return util.color.rgb(r / 255, g / 255, b / 255)
end

local function hiddenAchievements(achievementsTable)

    local macData = interfaces.storageUtils.getStorage("achievements")

    local count = 0
    local hiddenIds = {}
    local filteredAchievements = {}

    --- 1. Getting an IDs of hidden locked achievements.
    for i = 1, achievementsAmount do
        if achievementsTable[i].hidden == true and macData:get(achievementsTable[i].id) == false then
            count = count + 1
            table.insert(hiddenIds, achievementsTable[i].id)
        end
    end

    -- 2. Creating of set for fast search.
    local hiddenSet = {}
    if hiddenIds ~= 0 then
        for _, id in ipairs(hiddenIds) do
            hiddenSet[id] = true
        end
    end

    -- 3. Filtering of achievements
    local filteredAchievements = {}
    for _, achievement in ipairs(achievementsTable) do
        if not hiddenSet[achievement.id] then
            table.insert(filteredAchievements, achievement)
        end
    end

    --- 4. Sort achievements in filtered list (adding completed achievements at the beggining)
    local filteredQueuedAchievements = {}
    local achievementsCompleted = {}
    local achievementsLocked = {}

    for i = 1, #filteredAchievements do
        if macData:get(filteredAchievements[i].id) == true then
            table.insert(filteredQueuedAchievements, filteredAchievements[i])
            table.insert(achievementsCompleted, filteredAchievements[i])
        end
    end

    for i = 1, #filteredAchievements do
        if macData:get(filteredAchievements[i].id) == false then
            table.insert(filteredQueuedAchievements, filteredAchievements[i])
            table.insert(achievementsLocked, filteredAchievements[i])
        end
    end

    --- 5. Adding amount of the hidden achievements at the end of list.
    if count ~= 0 then
        local hiddenAchievement = {
            name = l10n('hidden_achievements_count') .. count,
            description = l10n('hidden_achievements_description'),
            icon = "Icons\\MAC\\icn_hidden.dds",
            hidden = false,
            id = "hidden_count_MAC"
        }

        table.insert(filteredQueuedAchievements, hiddenAchievement)
        table.insert(achievementsLocked, hiddenAchievement)
    end
    
    local hidden = {
        count = count,
        achievementsCompleted = achievementsCompleted,
        achievementsLocked = achievementsLocked,
        achievementsFormatted = filteredQueuedAchievements
    }

    return hidden

end

local function calculatePages(total_elements, elements_per_page)
    return math.ceil(total_elements / elements_per_page)
end

--- ################################# ---

local function getPageRange(page, itemsPerPage)
    local startIndex = (page - 1) * itemsPerPage + 1
    local endIndex = page * itemsPerPage
    return startIndex, endIndex
end

local function getPageRangeLast(amount, lastAmount)
    local startLastIndex = amount - lastAmount + 1
    local endLastIndex = amount
    return startLastIndex, endLastIndex
end

--- ################################# ---

local function createAchievement(name, description, icon_path, icon_color, icon_bg)

    local screenSize = ui.screenSize()

    local width_ratio = 0.25
    local height_ratio = 0.65

    local scale_factor = playerSettings:get('ui_scaling_factor')

    local widget_width = screenSize.x * width_ratio * scale_factor

    local nameTextSize = screenSize.x * 0.0094 * scale_factor
    local descriptionTextSize = screenSize.y * 0.0160 * scale_factor

    local icon_size = screenSize.y * 0.06 * scale_factor

    local achievementLogo = {
        type = ui.TYPE.Image,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5),
            size = v2(icon_size, icon_size),
            resource = ui.texture { path = icon_path },
            color = util.color.hex(icon_color)
        }
    }

    local achievementLogoBackground = {
        type = ui.TYPE.Image,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5),
            size = v2(icon_size, icon_size),
            resource = ui.texture { path = icon_bg }
        }
    }

    local achievementLogoBox = {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props = {
            size = v2(icon_size, icon_size)
        },
        content = ui.content {
            achievementLogoBackground,
            achievementLogo
        }
    }

    local achievementNameText = {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            text = name,
            textSize = nameTextSize
        }
    }

    local achievementDescriptionText = {
        type = ui.TYPE.Text,
        props = {
            text = description,
            anchor = v2(0, 0),
            autoSize = false,
            relativePosition = v2(0, 0),
            textSize = descriptionTextSize,
            size = v2((widget_width * 0.85)-7-icon_size, descriptionTextSize*3),
            multiline = true,
            wordWrap = true,
            textColor = util.color.hex("cccccc")
        }
    }

    local achievementDescriptionTextBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2((widget_width * 0.85)-7-icon_size, descriptionTextSize*3)
        },
        content = ui.content({achievementDescriptionText})
    }

    local emptyHBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(300, 6)
        }
    }

    local emptyVBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(7, 80)
        }
    }

    local achievementText = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            relativePosition = v2(0, 0),
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Start
        },
        content = ui.content {
            achievementNameText,
            emptyHBox,
            achievementDescriptionTextBox
        }
    }

    local achievement = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            relativePosition = v2(0, 0),
            align = ui.ALIGNMENT.Start,
            arrange = ui.ALIGNMENT.Center
        },
        external = {
            stretch = 1,
            grow = 1
        },
        content = ui.content(
            {achievementLogoBox,
            emptyVBox,
            achievementText}
        )
    }

    return(achievement)

end

local function createAchievementList(page, achievementsTable)

    local screenSize = ui.screenSize()

    local width_ratio = 0.25
    local height_ratio = 0.65

    local scale_factor = playerSettings:get('ui_scaling_factor')

    local widget_width = screenSize.x * width_ratio * scale_factor
    local widget_height = screenSize.y * height_ratio * scale_factor

    local icon_size = screenSize.y * 0.06 * scale_factor

    local macData = interfaces.storageUtils.getStorage("achievements")
    
    local achievementsFormatted = hiddenAchievements(achievementsTable).achievementsFormatted
    local achievementsCompleted = hiddenAchievements(achievementsTable).achievementsCompleted
    local achievementsLocked = hiddenAchievements(achievementsTable).achievementsLocked

    if current_MAC_section == "all" then
        achievementsForList = deepCopy(achievementsFormatted)
    elseif current_MAC_section == "completed" then
        achievementsForList = deepCopy(achievementsCompleted)
    elseif current_MAC_section == "locked" then
        achievementsForList = deepCopy(achievementsLocked)
    end

    pageAmount = calculatePages(#achievementsForList, 6)
    lastPageAmount = #achievementsForList % 6
    startIndex, endIndex = getPageRange(page, 6)
    startLastIndex, endLastIndex = getPageRangeLast(#achievementsForList, lastPageAmount)
    emptyAchievementsAmount = 6 - lastPageAmount

    if pageAmount ~= 0 then
        if page ~= pageAmount or (page == pageAmount and lastPageAmount == 0) then
            contentTable = {}
            for i = startIndex, endIndex do
                
                if achievementsForList[i].id ~= "hidden_count_MAC" and macData:get(achievementsForList[i].id) == false then
                    iconColor = "000000"
                    iconBg = "Icons\\MAC\\icnBackground.tga"
                elseif achievementsForList[i].id ~= "hidden_count_MAC" and macData:get(achievementsForList[i].id) == true then
                    iconColor = "000000"

                    if achievementsForList[i].bgColor ~= nil then
                        if achievementsForList[i].bgColor == "green" then
                            iconBg = "Icons\\MAC\\icnBackgroundGet_Green.tga"
                        elseif achievementsForList[i].bgColor == "red" then
                            iconBg = "Icons\\MAC\\icnBackgroundGet_Red.tga"
                        elseif achievementsForList[i].bgColor == "blue" then
                            iconBg = "Icons\\MAC\\icnBackgroundGet_Blue.tga"
                        elseif achievementsForList[i].bgColor == "purple" then
                            iconBg = "Icons\\MAC\\icnBackgroundGet_Purple.tga"
                        elseif achievementsForList[i].bgColor == "yellow" then
                            iconBg = "Icons\\MAC\\icnBackgroundGet_Yellow.tga"
                        elseif achievementsForList[i].bgColor == "aqua" then
                            iconBg = "Icons\\MAC\\icnBackgroundGet_Aqua.tga"
                        end
                    else
                        iconBg = "Icons\\MAC\\icnBackgroundGet.tga"
                    end

                elseif achievementsForList[i].id == "hidden_count_MAC" then
                    iconColor = "000000"
                    iconBg = "Icons\\MAC\\icnBackground.tga"
                end

                local achievement = createAchievement(
                achievementsForList[i].name,
                achievementsForList[i].description,
                achievementsForList[i].icon,
                iconColor,
                iconBg)

                table.insert(contentTable, achievement)

            end
            list = ui.content(contentTable)
            return list
        end

        if page == pageAmount and lastPageAmount ~= 0 then

            contentTable = {}
            for i = startLastIndex, endLastIndex do
                
                if achievementsForList[i].id ~= "hidden_count_MAC" and macData:get(achievementsForList[i].id) == false then
                    iconColor = "000000"
                    iconBg = "Icons\\MAC\\icnBackground.tga"
                elseif achievementsForList[i].id ~= "hidden_count_MAC" and macData:get(achievementsForList[i].id) == true then
                    iconColor = "000000"
                    
                    if achievementsForList[i].bgColor ~= nil then
                        if achievementsForList[i].bgColor == "green" then
                            iconBg = "Icons\\MAC\\icnBackgroundGet_Green.tga"
                        elseif achievementsForList[i].bgColor == "red" then
                            iconBg = "Icons\\MAC\\icnBackgroundGet_Red.tga"
                        elseif achievementsForList[i].bgColor == "blue" then
                            iconBg = "Icons\\MAC\\icnBackgroundGet_Blue.tga"
                        elseif achievementsForList[i].bgColor == "purple" then
                            iconBg = "Icons\\MAC\\icnBackgroundGet_Purple.tga"
                        elseif achievementsForList[i].bgColor == "yellow" then
                            iconBg = "Icons\\MAC\\icnBackgroundGet_Yellow.tga"
                        elseif achievementsForList[i].bgColor == "aqua" then
                            iconBg = "Icons\\MAC\\icnBackgroundGet_Aqua.tga"
                        end
                    else
                        iconBg = "Icons\\MAC\\icnBackgroundGet.tga"
                    end

                elseif achievementsForList[i].id == "hidden_count_MAC" then
                    iconColor = "000000"
                    iconBg = "Icons\\MAC\\icnBackground.tga"
                end

                local achievement = createAchievement(
                achievementsForList[i].name,
                achievementsForList[i].description,
                achievementsForList[i].icon,
                iconColor,
                iconBg)

                table.insert(contentTable, achievement)

            end

            for i = 1, emptyAchievementsAmount do

                local emptyAchievement = {
                    type = ui.TYPE.Widget,
                    template = I.MWUI.templates.borders,
                    props = {
                        size = v2((widget_width * 0.85), icon_size)
                    }
                }

                local emptyAchievementFlex = {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                        autoSize = false,
                        relativePosition = v2(0, 0),
                        align = ui.ALIGNMENT.Start,
                        arrange = ui.ALIGNMENT.Center
                    },
                    external = {
                        stretch = 1,
                        grow = 1
                    },
                    content = ui.content {
                        {emptyAchievement}
                    }
                }

                table.insert(contentTable, emptyAchievementFlex)

            end

            list = ui.content(contentTable)
            return list
        end
    else

        local thereIsEmptyText = {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text = l10n("thereis_empty_text"),
                anchor = v2(.5, .5),
                relativePosition = v2(.5, .5),
                textSize = (screenSize.x * 0.01),
                size = v2(widget_width * 0.85, 30)
            }
        }
    
        local thereIsEmptyTextBox = {
            type = ui.TYPE.Widget,
            props = {
                size = v2(widget_width * 0.85, icon_size*8),
                anchor = v2(.5, .5),
                realativePosition = v2(.5, .5)
            },
            content = ui.content({thereIsEmptyText})
        }

        list = ui.content({thereIsEmptyTextBox})
        return list
    end

end

local function createMainWindow(isButtonBackVisible, isButtonForwardVisible, currentPage, achievementsTable)

    local screenSize = ui.screenSize()

    local width_ratio = 0.25
    local height_ratio = 0.65

    local scale_factor = playerSettings:get('ui_scaling_factor')

    local widget_width = screenSize.x * width_ratio * scale_factor
    local widget_height = screenSize.y * height_ratio * scale_factor

    local nameTextSize = screenSize.x * 0.0094 * scale_factor
    local descriptionTextSize = screenSize.y * 0.0160 * scale_factor

    local menu_block_path = "Textures\\menu_head_block_middle.dds"

    local achievementsFormatted = hiddenAchievements(achievementsTable).achievementsFormatted
    local achievementsCompleted = hiddenAchievements(achievementsTable).achievementsCompleted
    local achievementsLocked = hiddenAchievements(achievementsTable).achievementsLocked

    _G.currentPage = currentPage

    local icon_size = screenSize.y * 0.06
    local menu_block_width = widget_width * 0.30
    local header_height = widget_height * 0.05 * scale_factor

    local topButtonHeight = screenSize.y * 0.0213 * scale_factor
    local topButtonWidth = screenSize.y * 0.09 * scale_factor
    local underButtonWidth = screenSize.y * 0.074 * scale_factor

    local text_size = screenSize.y * 0.015 * scale_factor

    if screenSize.y < 901 or tonumber(scale_factor) < 0.8 then
        buttonTemplate = I.MWUI.templates.borders
    else
        buttonTemplate = I.MWUI.templates.bordersThick
    end

    local headerText = l10n('header_text') .. " (" .. tostring(#achievementsCompleted) .. "/" .. tostring(achievementsAmount) .. ")"

    buttonTopColors = {}

    if current_MAC_section == "all" then
        calculatedPageAmount = calculatePages(#achievementsFormatted, 6)
        buttonTopColors = {getGMSTcolor("active"), getGMSTcolor("normal"), getGMSTcolor("normal")}
    elseif current_MAC_section == "completed" then
        calculatedPageAmount = calculatePages(#achievementsCompleted, 6)
        buttonTopColors = {getGMSTcolor("normal"), getGMSTcolor("active"), getGMSTcolor("normal")}
    elseif current_MAC_section == "locked" then
        calculatedPageAmount = calculatePages(#achievementsLocked, 6)
        buttonTopColors = {getGMSTcolor("normal"), getGMSTcolor("normal"), getGMSTcolor("active")}
    end

    if calculatedPageAmount ~= 0 then
        textPage = currentPage .. "/" .. calculatedPageAmount
    else
        textPage = " "
    end

    if calculatedPageAmount == 1 or calculatedPageAmount == 0 then
        isButtonForwardVisible = false
    end

    buttonAllColor = buttonTopColors[1]
    buttonAchievedColor = buttonTopColors[2]
    buttonUnachievedColor = buttonTopColors[3]

    local header = {
        type = ui.TYPE.Flex,
        props = {
            size = v2(widget_width, 20),
            horizontal = true
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    anchor = v2(.5, .5),
                    size = v2(menu_block_width, 20),
                    resource = ui.texture { 
                        path = menu_block_path,
                        size = v2(menu_block_width, 15)
                     }
                }
            },
            {
                type = ui.TYPE.Widget,
                props = {
                    size = v2(widget_width * 0.4, 20),
                    anchor = v2(.5, .5)
                },
                content = ui.content {{
                    template = I.MWUI.templates.textNormal,
                    type = ui.TYPE.Text,
                    props = {
                        anchor = v2(.5, .5),
                        relativePosition = v2(.5, .5),
                        text = headerText,
                        textSize = text_size,
                    }
                }}
            },
            {
                type = ui.TYPE.Image,
                props = {
                    anchor = v2(.5, .5),
                    size = v2(menu_block_width, 20),
                    resource = ui.texture {
                        path = menu_block_path,
                        size = v2(menu_block_width, 15) }
                }
            }
        }
    }

    local emptyHBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(300, 6)
        }
    }

    local achievementsList = {
        type = ui.TYPE.Flex,
        props = {
            size = v2(widget_width * 0.85, icon_size * 8 * scale_factor),
            horizontal = false,
            anchor = v2(0, 0),
            relativePosition = v2(0, 0)
        },
        content = createAchievementList(currentPage, achievements)
    }

    local achievementsBox = {
        type = ui.TYPE.Widget,
        props = {
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            size = v2(widget_width * 0.85, icon_size * 8 * scale_factor)
        },
        content = ui.content({achievementsList})
    }

    local buttonBack = {
        type = ui.TYPE.Widget,
        template = buttonTemplate,
        props = {
            name = "buttonBack",
            anchor = v2(0, .5),
            relativePosition = v2(0, .5),
            size = v2(underButtonWidth, topButtonHeight),
            visible = isButtonBackVisible,
            propagateEvents = false
        },
        content = ui.content {
            {
                template = I.MWUI.templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    anchor = v2(.5, .5),
                    relativePosition = v2(.5, .5),
                    text = l10n("button_back_text"),
                    textSize = text_size + 1,
                }
            }
        },
        events = {
            mousePress = async:callback(function(button)
                if currentPage == 2 then
                    achievementWindow:destroy()
                    createMainWindow(false, true, currentPage-1, getAchievements())
                end
                if currentPage ~= 2 then
                    achievementWindow:destroy()
                    createMainWindow(true, true, currentPage-1, getAchievements())
                end
            end)
        }
    }

    local buttonForward = {
        type = ui.TYPE.Widget,
        template = buttonTemplate,
        props = {
            anchor = v2(1, .5),
            relativePosition = v2(1, .5),
            size = v2(underButtonWidth, topButtonHeight),
            visible = isButtonForwardVisible,
            propagateEvents = false
        },
        content = ui.content {
            {
                template = I.MWUI.templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    anchor = v2(.5, .5),
                    relativePosition = v2(.5, .5),
                    text = l10n("button_forward_text"),
                    textSize = text_size + 1,
                }
            }
        },
        events = {
            mousePress = async:callback(function(button)
                if currentPage < calculatedPageAmount then
                    achievementWindow:destroy()
                    createMainWindow(true, true, currentPage+1, getAchievements())
                end
                if currentPage == calculatedPageAmount-1 then
                    achievementWindow:destroy()
                    createMainWindow(true, false, currentPage+1, getAchievements()) 
                end
            end)
        }
    }

    local pageText = {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            text = textPage,
            textSize = text_size + 4
        }
    }

    local buttonsBox = {
        type = ui.TYPE.Widget,
        props = {
            name = "buttonsBox",
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            size = v2(widget_width * 0.65, topButtonHeight + (topButtonHeight * 0.3))
        },
        content = ui.content(
            {buttonBack, pageText, buttonForward}
        )
    }

    local buttonAll = {
        type = ui.TYPE.Widget,
        template = buttonTemplate,
        props = {
            name = "buttonAll",
            anchor = v2(0, .5),
            -- relativePosition = v2(0, .5),
            size = v2((topButtonWidth / 2), topButtonHeight),
            visible = true
        },
        content = ui.content {
            {
                template = I.MWUI.templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    anchor = v2(.5, .5),
                    relativePosition = v2(.5, .5),
                    text = l10n("button_all_text"),
                    textSize = text_size + 1,
                    textColor = buttonAllColor
                }
            }
        },
        events = {
            mousePress = async:callback(function(button)
                achievementWindow:destroy()
                current_MAC_section = "all"
                createMainWindow(false, true, 1, getAchievements())
            end)
        }
    }

    local buttonAchieved = {
        type = ui.TYPE.Widget,
        template = buttonTemplate,
        props = {
            anchor = v2(0, .5),
            size = v2(topButtonWidth, topButtonHeight),
            visible = true
        },
        content = ui.content {
            {
                template = I.MWUI.templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    anchor = v2(.5, .5),
                    relativePosition = v2(.5, .5),
                    text = l10n("button_unlocked_text"),
                    textSize = text_size + 1,
                    textColor = buttonAchievedColor
                }
            }
        },
        events = {
            mousePress = async:callback(function(button)
                achievementWindow:destroy()
                current_MAC_section = "completed"
                createMainWindow(false, true, 1, getAchievements())
            end)
        }
    }

    local buttonUnachieved = {
        type = ui.TYPE.Widget,
        template = buttonTemplate,
        props = {
            anchor = v2(0, .5),
            -- relativePosition = v2(0, .5),
            size = v2(topButtonWidth * 1.2, topButtonHeight),
            visible = true
        },
        content = ui.content {
            {
                template = I.MWUI.templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    anchor = v2(.5, .5),
                    relativePosition = v2(.5, .5),
                    text = l10n("button_locked_text"),
                    textSize = text_size + 1,
                    textColor = buttonUnachievedColor
                }
            }
        },
        events = {
            mousePress = async:callback(function(button)
                achievementWindow:destroy()
                current_MAC_section = "locked"
                createMainWindow(false, true, 1, getAchievements())
            end)
        }
    }

    local buttonTopEmpty = {
        type = ui.TYPE.Widget,
        props = {
            anchor = v2(0, .5),
            size = v2(10, topButtonHeight)
        }
    }

    local topButtonsFlex = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Start
        },
        content = ui.content({
            buttonAll,
            buttonTopEmpty,
            buttonAchieved,
            buttonTopEmpty,
            buttonUnachieved})
    }

    local topButtonsBox = {
        type = ui.TYPE.Widget,
        props = {
            name = "topButtonsBox",
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            size = v2(widget_width * 0.85, topButtonHeight + (topButtonHeight * 0.3))
        },
        content = ui.content(
            {topButtonsFlex}
        )
    }

    local horizontalLine = {
        type = ui.TYPE.Image,
        template = I.MWUI.templates.horizontalLine,
        props = {
            size = v2(widget_width * 0.85, 2)
        }
    }

    local pluginBox = ui.content {
        {
            type = ui.TYPE.Widget,
            template = I.MWUI.templates.borders,
            props = {
                name = "pluginBox",
                anchor = v2(.5, .5),
                relativePosition = v2(.5, .5),
                size = v2(widget_width * 0.93, (widget_height) * 0.93)
            },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = {
                        anchor = v2(.5, .5),
                        relativePosition = v2(.5, .5),
                        name = "pluginBoxFlex",
                        horizontal = false,
                        align = ui.ALIGNMENT.Start,
                        arrange = ui.ALIGNMENT.Center
                    },
                    external = {
                        stretch = 0.4
                    },
                    content = ui.content {
                        emptyHBox,
                        topButtonsBox,
                        horizontalLine,
                        emptyHBox,
                        achievementsBox,
                        horizontalLine,
                        emptyHBox,
                        buttonsBox
                    }
                }
            }
        }
    }

    local pluginBoxPadding = ui.content {
        {
            type = ui.TYPE.Widget,
            props = {
                name = "pluginBoxPadding",
                anchor = v2(.5, .5),
                relativePosition = v2(.5, .5),
                size = v2(widget_width, (widget_height-10))
            },
            content = pluginBox
        }
    }

    local mainWindow = {
        type = ui.TYPE.Container,
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            name = "mainWindow",
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5),
            propagateEvents = false
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    name = "mainWindowFlex",
                    size = v2(widget_width, widget_height),
                    autoSize = false,
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center
                },
                content = ui.content {
                        header,
                        {
                            name = "mainWindowWidget",
                            type = ui.TYPE.Widget,
                            template = I.MWUI.templates.bordersThick,
                            props = {
                                size = v2(widget_width, widget_height-20)
                            },
                            content = pluginBoxPadding
                        }
                }
            }
        }
    }

    achievementWindow = ui.create(mainWindow)

end

--- ################################# ---

local function onKeyPress(key)

    if key.code == playerSettings:get('toggle_omwa') then
        if showable == nil then
            I.UI.setMode('Interface', {windows = {}})
            current_MAC_section = "all"
            createMainWindow(false, true, 1, getAchievements())
            showable = true
        else
            achievementWindow:destroy()
            I.UI.removeMode('Interface')
            showable = nil
        end
    end

    if key.code == input.KEY.RightArrow and showable == true then
        if currentPage < calculatedPageAmount then
            if currentPage == calculatedPageAmount-1 then
                achievementWindow:destroy()
                createMainWindow(true, false, currentPage+1, getAchievements()) 
            else
                achievementWindow:destroy()
                createMainWindow(true, true, currentPage+1, getAchievements())
            end 
        end 
    end

    if key.code == input.KEY.LeftArrow and showable == true then
        if currentPage == 2 then
            achievementWindow:destroy()
            createMainWindow(false, true, currentPage-1, getAchievements())
        end
        if currentPage ~= 2 and currentPage > 2 then
            achievementWindow:destroy()
            createMainWindow(true, true, currentPage-1, getAchievements())
        end
    end

    if key.code == input.KEY.Escape and showable == true then
        achievementWindow:destroy()
        I.UI.removeMode('Interface')
        showable = nil
    end

end

local function onMouseWheel(vertical, horizontal)

    if showable == true then
        if vertical == 1 then
            if currentPage < calculatedPageAmount then
                if currentPage == calculatedPageAmount-1 then
                    achievementWindow:destroy()
                    createMainWindow(true, false, currentPage+1, getAchievements()) 
                else
                    achievementWindow:destroy()
                    createMainWindow(true, true, currentPage+1, getAchievements())
                end 
            end 
        end

        if vertical == -1 then
            if currentPage == 2 then
                achievementWindow:destroy()
                createMainWindow(false, true, currentPage-1, getAchievements())
            end
            if currentPage ~= 2 and currentPage > 2 then
                achievementWindow:destroy()
                createMainWindow(true, true, currentPage-1, getAchievements())
            end
        end
    end

end 

local function onInputAction(id)

    if showable == true then
        if id == input.ACTION.Inventory then
            achievementWindow:destroy()
            showable = nil
        end

        if id == input.ACTION.Journal then
            achievementWindow:destroy()
            I.UI.removeMode('Interface')
            showable = nil
        end
    end

end

return {
    engineHandlers = {
        onKeyPress = onKeyPress,
        onInputAction = onInputAction,
        onMouseWheel = onMouseWheel
    }
}