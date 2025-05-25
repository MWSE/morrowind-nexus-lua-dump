local core = require("openmw.core")
local ui = require('openmw.ui')
local util = require('openmw.util')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local vfs = require('openmw.vfs')
local async = require('openmw.async')
local ambient = require("openmw.ambient")
local l10n = core.l10n("OpenMWQuestMenu")

local UIComponents = require('scripts.openmw_questmenu.uiComponents')

local v2 = util.vector2

local playerSettings = storage.playerSection('SettingsPlayerOpenMWQuestMenuControls')
local playerCustomizationSettings = storage.playerSection('SettingsPlayerOpenMWQuestMenuCustomization')

local questMenu = nil
local questMode = 'ACTIVE' -- ACTIVE, FINISHED, HIDDEN
local text_size = playerCustomizationSettings:get('TextSize')
local buttonWidth = text_size * 6
local showable = nil

local screenSize = ui.screenSize()
local width_ratio = 0.5
local height_ratio = 0.65
local widget_width = screenSize.x * width_ratio
local widget_height = screenSize.y * height_ratio

local icon_size = screenSize.y * 0.03

if (widget_width > playerCustomizationSettings:get('MaxWidth')) then
    widget_width = playerCustomizationSettings:get('MaxWidth')
end

if (widget_height > playerCustomizationSettings:get('MaxHeight')) then
    widget_height = playerCustomizationSettings:get('MaxHeight')
end

if (icon_size > playerCustomizationSettings:get('MaxIconSize')) then
    icon_size = playerCustomizationSettings:get('MaxIconSize')
end

local vertical_block_size = icon_size + 5
local contentHeight = widget_height - (3 * vertical_block_size)
local menu_block_width = widget_width * 0.30

local createQuestMenu
local selectedQuest = nil

local questsPerPage = math.floor(contentHeight / vertical_block_size)
local detailPage = 1

local emptyVBox = {
    type = ui.TYPE.Widget,
    props = {
        size = v2(widget_width * 0.5, 6)
    }
}

local emptyHBox = {
    type = ui.TYPE.Widget,
    props = {
        size = v2(7, vertical_block_size)
    }
}

local function selectQuest(quest, page)
    selectedQuest = quest
    if questMenu then
        questMenu:destroy()
        questMenu = nil
        detailPage = 1
        createQuestMenu(page, I.OpenMWQuestList.getQuestList())
    end
end

local function createQuest(quest, page)
    local icon = nil
    local questLogo = nil
    if (I.SSQN) then
        icon = I.SSQN.getQIcon(quest.id)

        if not vfs.fileExists(icon) then icon = "Icons\\SSQN\\DEFAULT.dds" end

        questLogo = {
            type = ui.TYPE.Image,
            props = {
                relativePosition = v2(.5, .5),
                anchor = v2(.5, .5),
                size = v2(icon_size, icon_size),
                resource = ui.texture { path = icon },
                color = util.color.rgb(1, 1, 1)
            }
        }
    end

    local function getColor()
        if selectedQuest and selectedQuest.id == quest.id then
            return util.color.rgb(255, 255, 255)
        end

        return nil
    end

    local questNameText = {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            text = quest.name,
            textSize = text_size,
            textColor = getColor()
        }
    }

    local function createContent()
        if (icon ~= nil) then
            return {
                questLogo,
                emptyHBox,
                questNameText
            }
        end

        return { emptyHBox, questNameText }
    end

    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            relativePosition = v2(0, 0),
            align = ui.ALIGNMENT.Start,
            arrange = ui.ALIGNMENT.Center
        },
        external = {
            stretch = 1,
            grow = 1
        },
        content = ui.content(createContent()),
        events = {
            mouseClick = async:callback(function()
                selectQuest(quest, page)
            end)
        },
    }
end

local function createQuestList(quests, page)
    local questlist = {}

    if (questMode == "ACTIVE") then
        for _, quest in pairs(quests) do
            if (quest.hidden ~= true and quest.finished ~= true) then
                table.insert(questlist, quest)
            end
        end
    elseif (questMode == "HIDDEN") then
        for _, quest in pairs(quests) do
            if (quest.hidden == true) then
                table.insert(questlist, quest)
            end
        end
    elseif (questMode == "FINISHED") then
        for _, quest in pairs(quests) do
            if (quest.finished == true) then
                table.insert(questlist, quest)
            end
        end
    end

    local paginatedList = {}
    for index, quest in pairs(questlist) do
        if ((index - 1) >= ((page - 1) * questsPerPage) and (index - 1) < ((page - 1) * questsPerPage + questsPerPage)) then
            table.insert(paginatedList, createQuest(quest, page))
        end
    end

    return ui.content {
        {
            type = ui.TYPE.Flex,
            content = ui.content(paginatedList),
        }
    }
end

local function createQuestDetail()
    if selectedQuest == nil then
        return ui.content {
            {
                template = I.MWUI.templates.textNormal,
                props = {
                    anchor = v2(.5, .5),
                    relativePosition = v2(.5, .5),
                    text = l10n("error_no_quest"),
                    textColor = util.color.rgb(255, 255, 255),
                    textSize = text_size,
                }
            }
        }
    end

    local stage = selectedQuest.stages[detailPage]
    local text = I.OpenMWQuestList.getQuestText(selectedQuest.id, stage)

    local content = {}
    if playerSettings:get('Debugging') == true then
        table.insert(content, {
            type = ui.TYPE.Text,
            props = {
                text = "id: " .. selectedQuest.id .. " / " .. "stage: " .. stage,
                textColor = util.color.rgb(255, 255, 255),
                textSize = text_size,
                autoSize = false,
                size = v2((widget_width / 2 * 0.85), text_size * 2),
            }
        })
    end

    table.insert(content, {
        template = I.MWUI.templates.textNormal,
        props = {
            text = text,
            size = v2((widget_width / 2 * 0.85), contentHeight),
            multiline = true,
            wordWrap = true,
            autoSize = false,
            textSize = text_size,
        }
    })

    return ui.content {
        {
            type = ui.TYPE.Flex,
            content = ui.content(content)
        }
    }
end

createQuestMenu = function(page, quests)
    local menu_block_path = "Textures\\menu_head_block_middle.dds"
    local topButtonHeight = 23

    local filteredQuests = {}

    if (questMode == "ACTIVE") then
        for _, quest in pairs(quests) do
            if (quest.hidden ~= true and quest.finished ~= true) then
                table.insert(filteredQuests, quest)
            end
        end
    elseif (questMode == "HIDDEN") then
        for _, quest in pairs(quests) do
            if (quest.hidden == true) then
                table.insert(filteredQuests, quest)
            end
        end
    elseif (questMode == "FINISHED") then
        for _, quest in pairs(quests) do
            if (quest.finished == true) then
                table.insert(filteredQuests, quest)
            end
        end
    end

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
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        props = {
                            anchor = v2(.5, .5),
                            relativePosition = v2(.5, .5),
                            text = l10n("menu_title"),
                            textColor = util.color.rgb(255, 255, 255),
                            textSize = text_size,
                        }
                    }
                }
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

    local questList = {
        type = ui.TYPE.Flex,
        props = {
            size = v2(widget_width * 0.85, icon_size * 16),
            horizontal = false,
            anchor = v2(0, 0),
            relativePosition = v2(0, 0)
        },
        content = createQuestList(filteredQuests, page)
    }

    local questBox = {
        type = ui.TYPE.Widget,
        props = {
            anchor = v2(.25, .5),
            relativePosition = v2(.25, .5),
            size = v2(widget_width / 2 * 0.85, contentHeight)
        },
        content = ui.content({ questList })
    }

    local questDetailBox = {
        type = ui.TYPE.Widget,
        props = {
            anchor = v2(1, .5),
            relativePosition = v2(1, .5),
            size = v2(widget_width / 2 * 0.85, contentHeight)
        },
        content = createQuestDetail()
    }

    local function createListNavigation(direction, relativePosition, anchor)
        local text = direction == "+" and l10n("button_next") or l10n("button_back")
        local nextPage = direction == "+" and (page + 1) or (page - 1)

        if ((direction == "-" and nextPage < 1) or (direction == "+" and nextPage > math.ceil(#filteredQuests / questsPerPage))) then
            return {}
        end

        return UIComponents.createButton(text, text_size, buttonWidth - 20, topButtonHeight, relativePosition, anchor,
            function()
                if questMenu then
                    questMenu:destroy()
                    questMenu = nil
                    createQuestMenu(nextPage, filteredQuests)
                end
            end)
    end

    local function createDetailNavigation(direction, relativePosition, anchor)
        if (selectedQuest == nil) then
            return {}
        end

        local text = direction == "+" and l10n("button_next") or l10n("button_back")
        local nextPage = direction == "+" and (detailPage + 1) or (detailPage - 1)

        if ((direction == "-" and nextPage < 1) or (direction == "+" and nextPage > #selectedQuest.stages)) then
            return {}
        end

        return UIComponents.createButton(text, text_size, buttonWidth - 20, topButtonHeight, relativePosition, anchor,
            function()
                if questMenu then
                    questMenu:destroy()
                    questMenu = nil
                    detailPage = nextPage
                    createQuestMenu(page, filteredQuests)
                end
            end)
    end

    local function createPageText()
        return tostring(page) .. " / " .. tostring(math.ceil(#filteredQuests / questsPerPage))
    end

    local pageText = {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            text = createPageText(),
            textSize = text_size
        }
    }

    local function createDetailPageText()
        if (selectedQuest == nil) then
            return tostring(detailPage);
        end

        return tostring(detailPage) .. " / " .. tostring(#selectedQuest.stages)
    end

    local detailPageText = {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            text = createDetailPageText(),
            textSize = text_size
        }
    }

    local buttonsBox = {
        type = ui.TYPE.Widget,
        props = {
            name = "buttonsBox",
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            size = v2(widget_width / 2 * 0.65, 30)
        },
        content = ui.content({
            createListNavigation("-", v2(0, .5), v2(0, .5)),
            pageText,
            createListNavigation("+", v2(1, .5), v2(1, .5))
        })
    }

    local buttonsBoxDetails = {
        type = ui.TYPE.Widget,
        props = {
            name = "buttonsBox",
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            size = v2(widget_width / 2 * 0.65, 30)
        },
        content = ui.content({
            createDetailNavigation("-", v2(0, .5), v2(0, .5)),
            detailPageText,
            createDetailNavigation("+", v2(1, .5), v2(1, .5))
        })
    }

    local buttonHidden = UIComponents.createButton(l10n("button_hidden"), text_size, buttonWidth, topButtonHeight, nil,
        v2(0, .5),
        function()
            if questMenu then
                questMenu:destroy()
                questMenu = nil
                selectedQuest = nil
                questMode = "HIDDEN"
                createQuestMenu(1, I.OpenMWQuestList.getQuestList())
            end
        end, questMode == "HIDDEN")

    local buttonFinished = UIComponents.createButton(l10n("button_finished"), text_size, buttonWidth, topButtonHeight,
        nil, v2(0, .5),
        function()
            if questMenu then
                questMenu:destroy()
                questMenu = nil
                selectedQuest = nil
                questMode = "FINISHED"
                createQuestMenu(1, I.OpenMWQuestList.getQuestList())
            end
        end, questMode == "FINISHED")

    local buttonActive = UIComponents.createButton(l10n("button_active"), text_size, buttonWidth, topButtonHeight, nil,
        v2(0, .5),
        function()
            if questMenu then
                questMenu:destroy()
                questMenu = nil
                selectedQuest = nil
                questMode = "ACTIVE"
                createQuestMenu(1, I.OpenMWQuestList.getQuestList())
            end
        end, questMode == "ACTIVE")

    local function createButtonFollow()
        if (not selectedQuest) then
            return {}
        end

        local text = selectedQuest.followed and l10n("button_unfollow") or l10n("button_follow")

        return UIComponents.createButton(text, text_size, buttonWidth, topButtonHeight, nil, v2(0, .5), function()
            if questMenu and selectedQuest then
                questMenu:destroy()
                questMenu = nil
                createQuestMenu(page, I.OpenMWQuestList.followQuest(selectedQuest.id))
            end
        end)
    end

    local function createButtonHide()
        if (not selectedQuest or questMode == "FINISHED") then
            return {}
        end

        local text = selectedQuest.hidden and l10n("button_show") or l10n("button_hide")

        return UIComponents.createButton(text, text_size, buttonWidth, topButtonHeight, nil, v2(0, .5), function()
            if questMenu and selectedQuest then
                questMenu:destroy()
                questMenu = nil
                I.OpenMWQuestList.toggleQuest(selectedQuest.id)
                selectedQuest = nil
                createQuestMenu(page, I.OpenMWQuestList.getQuestList())
            end
        end)
    end

    local buttonTopGap = {
        type = ui.TYPE.Widget,
        props = {
            anchor = v2(0, .5),
            size = v2(10, 30)
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
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            align = ui.ALIGNMENT.Start,
                            arrange = ui.ALIGNMENT.Center
                        },
                        content = ui.content {
                            UIComponents.createBox(widget_width / 2, widget_height - 20, ui.content {
                                emptyVBox,
                                UIComponents.createButtonGroup(widget_width / 2 * 0.85, ui.content({
                                    buttonActive,
                                    buttonTopGap,
                                    buttonFinished,
                                    buttonTopGap,
                                    buttonHidden
                                })),
                                UIComponents.createHorizontalLine(widget_width / 2 * 0.85),
                                emptyVBox,
                                questBox,
                                UIComponents.createHorizontalLine(widget_width / 2 * 0.85),
                                emptyVBox,
                                buttonsBox
                            }),
                            UIComponents.createBox(widget_width / 2, widget_height - 20, ui.content {
                                emptyVBox,
                                UIComponents.createButtonGroup(widget_width / 2 * 0.85, ui.content({
                                    createButtonHide(),
                                    buttonTopGap,
                                    createButtonFollow()
                                })),
                                UIComponents.createHorizontalLine(widget_width / 2 * 0.85),
                                emptyVBox,
                                questDetailBox,
                                UIComponents.createHorizontalLine(widget_width / 2 * 0.85),
                                emptyVBox,
                                buttonsBoxDetails
                            })
                        }
                    }

                }
            }
        }
    }

    questMenu = ui.create(mainWindow)
end

local function onKeyPress(key)
    if key.symbol == playerSettings:get('OpenMenu') then
        if showable == nil then
            I.UI.setMode('Interface', { windows = {} })
            if playerSettings:get('PlaySound') then
                ambient.playSoundFile("Sound\\Fx\\item\\bookopen.wav", { volume = 0.4 })
            end
            createQuestMenu(1, I.OpenMWQuestList.getQuestList())
            showable = true
        else
            I.UI.removeMode('Interface')
            if (questMenu) then
                if playerSettings:get('PlaySound') then
                    ambient.playSoundFile("Sound\\Fx\\item\\bookclose.wav", { volume = 0.4 })
                end
                questMenu:destroy()
                questMenu = nil;
            end
            showable = nil
        end
    end

    if key.code == input.KEY.Escape and questMenu and showable == true then
        I.UI.removeMode('Interface')
        questMenu:destroy()
        questMenu = nil;
        showable = nil
    end
end

local function onInputAction(id)
    if showable == true then
        if questMenu and id == input.ACTION.Inventory then
            questMenu:destroy()
            questMenu = nil;
            showable = nil
        end

        if questMenu and id == input.ACTION.Journal then
            questMenu:destroy()
            questMenu = nil;
            showable = nil
            I.UI.removeMode('Interface')
        end
    end
end

return {
    engineHandlers = {
        onKeyPress = onKeyPress,
        onInputAction = onInputAction
    }
}
