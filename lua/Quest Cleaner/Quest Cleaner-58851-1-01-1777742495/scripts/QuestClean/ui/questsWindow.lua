---@diagnostic disable: missing-fields
local ui = require('openmw.ui')
local auxUi = require("openmw_aux.ui")
local util = require('openmw.util')
local v2 = util.vector2
local I = require("openmw.interfaces")
local types = require("openmw.types")
local player = require("openmw.self")
local core = require("openmw.core")

local buttonTemplate = require("scripts.QuestClean.ui.templates.button")
local buttonConsts = require("scripts.QuestClean.ui.templates.button.consts")
local VirtualList = require("scripts.QuestClean.ui.templates.virtual_list.extras").VirtualListExt
local storedRoot = nil
local storedNavigate = function() end
local storedNavigateButton = function() end
local storedPressButton = function() end
-- can be edited
local textSize = 16
local contentWidth = 750
local questListWidthFraction = .50
local questListWidth = contentWidth * questListWidthFraction
local descriptionWidth = contentWidth - questListWidth
local contentHeight = 450
-- don't touch
local topPadding = 8
local contentOuterPadding = 4
local contentCenterPadding = 6
local rootWidth = contentWidth + contentOuterPadding * 2 + contentCenterPadding

local questsWindow = {}

local function padding(x, y)
    return {
        props = {
            size = util.vector2(x, y)
        }
    }
end

local function borderPadding(content, size)
    return {
        name = "wrapper",
        template = I.MWUI.templates.borders,
        props = {
            size = size
        },
        content = ui.content {
            {
                name = "padding",
                template = I.MWUI.templates.padding,
                content = ui.content { content }
            }
        }
    }
end

local function itemListSorter(a, b)
    -- Prioritize objects with id == "nil"
    if a.id == "nil" and b.id ~= "nil" then
        return true
    elseif a.id ~= "nil" and b.id == "nil" then
        return false
    end

    -- Fallback to alphabetical sorting by name (case-insensitive)
    return a.name:lower() < b.name:lower()
end

local function newSectionRow(name)
    return {
        kind = "section",
        id = name,
        questIds = {},
        quests = {},
        type = "section",
        name = name,
        description = "",
        checkDisabled = function() return true end,
    }
end

local function newEmptyRow(name, description)
    return {
        kind = "empty",
        id = name,
        questIds = {},
        quests = {},
        type = "quest",
        name = name,
        description = description,
        checkDisabled = function() return true end,
    }
end

local function getQuestDescription(journal, id)
    for _, entry in pairs(journal.journalTextEntries) do
        if entry.questId == id then
            return entry.text
        end
    end

    return ""
end

local function getQuestName(record, quest)
    local name = quest and quest.name or record and record.questName
    if not name then return nil, nil end

    local displayName = tostring(name)
    local nameKey = displayName:lower():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    return displayName, nameKey
end

local function addQuestToGroup(groupedQuests, kind, id, name, nameKey, description)
    local existingQuest = groupedQuests[nameKey]

    if existingQuest then
        existingQuest.questIds[#existingQuest.questIds + 1] = id
        existingQuest.quests[#existingQuest.quests + 1] = {
            id = id,
            name = name,
        }
        if description ~= "" then
            existingQuest.description = existingQuest.description .. "\n\n" .. description
        end
        return
    end

    groupedQuests[nameKey] = {
        kind = kind,
        id = id,
        nameKey = nameKey,
        questIds = { id },
        quests = {
            {
                id = id,
                name = name,
            },
        },
        type = "quest",
        name = name,
        description = description,
        checkDisabled = function() return false end,
    }
end

local function appendSectionRows(questList, sectionName, emptyName, emptyDescription, rows)
    questList[#questList + 1] = newSectionRow(sectionName)
    table.sort(rows, itemListSorter)

    if #rows == 0 then
        questList[#questList + 1] = newEmptyRow(emptyName, emptyDescription)
        return
    end

    for idx = 1, #rows do
        local row = rows[idx]
        questList[#questList + 1] = row
    end
end

local function getListText(row)
    if row.kind == "section" then
        return row.name
    elseif row.kind == "empty" then
        return "  " .. row.name
    end

    return "  " .. row.name
end

local function isQuestRow(row)
    return row.kind == "unfinished" or row.kind == "cleaned"
end


questsWindow.new = function(cleanedQuests)
    local root
    cleanedQuests = cleanedQuests or {}

    -- the thing works with indexes, so yeah
    local questList = {}
    local unfinishedQuestsByName = {}
    local cleanedQuestsByName = {}
    local quests = types.Player.quests(player)
    local journal = types.Player.journal(player)

    local finishedQuestNames = {}
    local cleanedQuestNames = {}
    for id, q in pairs(quests) do
        local record = core.dialogue.journal.records[id]
        local name, nameKey = getQuestName(record, q)
        if nameKey and cleanedQuests[id] then
            cleanedQuestNames[nameKey] = true
        elseif nameKey and q.finished then
            finishedQuestNames[nameKey] = true
        end
    end

    for id, q in pairs(quests) do
        local record = core.dialogue.journal.records[id]
        local name, nameKey = getQuestName(record, q)
        local desc = getQuestDescription(journal, id)

        if name and cleanedQuests[id] then
            addQuestToGroup(cleanedQuestsByName, "cleaned", id, name, nameKey, desc)
        elseif name and q.finished == false and not finishedQuestNames[nameKey] and not cleanedQuestNames[nameKey] then
            addQuestToGroup(unfinishedQuestsByName, "unfinished", id, name, nameKey, desc)
        end
    end

    local function rebuildQuestList()
        questList = {}

        local unfinishedRows = {}
        for _, quest in pairs(unfinishedQuestsByName) do
            unfinishedRows[#unfinishedRows + 1] = quest
        end

        local cleanedRows = {}
        for _, quest in pairs(cleanedQuestsByName) do
            cleanedRows[#cleanedRows + 1] = quest
        end

        appendSectionRows(
            questList,
            "Active Quests",
            "No unfinished quests",
            "There are no unfinished quests that have not already been cleaned by this mod.",
            unfinishedRows
        )
        appendSectionRows(
            questList,
            "Cleaned Quests",
            "No cleaned quests",
            "There are no quests currently stored by this mod.",
            cleanedRows
        )
    end

    rebuildQuestList()
    local function getInitialIndex()
        for idx = 1, #questList do
            local row = questList[idx]
            if row.kind == "unfinished" then
                return idx
            end
        end

        for idx = 1, #questList do
            local row = questList[idx]
            if row.kind == "cleaned" then
                return idx
            end
        end

        return 2
    end

    local descWrapper = borderPadding({
            name = "descFlex",
            type = ui.TYPE.Flex,
            props = {
                horizontal = false,
                autoSize = false,
                size = v2(descriptionWidth, contentHeight),
            },
            content = ui.content {
                ui.create {
                    name = "header",
                    template = I.MWUI.templates.textHeader,
                    props = {
                        text = questList[1].name,
                        textSize = textSize,
                    }
                },
                padding(0, 5),
                ui.create {
                    name = "description",
                    template = I.MWUI.templates.textParagraph,
                    props = {
                        text = questList[1].description,
                        textSize = textSize,
                    },
                    external = {
                        stretch = .975,
                        grow = 1,
                    }
                },
            }
        },
        v2(descriptionWidth, contentHeight)
    )

    local descFlex = descWrapper.content["padding"].content["descFlex"]
    local descHeader = descFlex.content[1]
    local descBody = descFlex.content[3]

    local function onQuestSelect(list, idx)
        local quest = questList[idx]

        descHeader.layout.props.text = quest.name
        descBody.layout.props.text = quest.description
        descHeader:update()
        descBody:update()

        list:changeSelection(idx)
    end

    local function findSourceSelectionIndex(kind, selectedIndex)
        for idx = math.min(selectedIndex - 1, #questList), 1, -1 do
            if questList[idx].kind == kind then
                return idx
            end
        end

        for idx = selectedIndex, #questList do
            if questList[idx].kind == kind then
                return idx
            end
        end

        return getInitialIndex()
    end

    local function refreshList(list, selectedIndex, sourceKind)
        local anchorIndex = list:getFirstVisibleIndex()
        local anchorOffset = list:getItemViewportOffset(anchorIndex)

        rebuildQuestList()
        list:rebuild(#questList)
        list:scrollToIndex(math.min(anchorIndex, #questList), anchorOffset)
        onQuestSelect(list, findSourceSelectionIndex(sourceKind, selectedIndex))
    end

    local function cleanSelectedQuest(list)
        local selectedIndex = list:getSelectedIndex()
        local selectedQuest = questList[selectedIndex]

        if not selectedQuest or selectedQuest.kind ~= "unfinished" then
            ui.showMessage("Select an unfinished quest to clean.")
            return
        end

        player:sendEvent(
            "QuestClean_questCleaned",
            { quests = selectedQuest.quests }
        )

        unfinishedQuestsByName[selectedQuest.nameKey] = nil
        cleanedQuestNames[selectedQuest.nameKey] = true
        selectedQuest.kind = "cleaned"
        cleanedQuestsByName[selectedQuest.nameKey] = selectedQuest
        refreshList(list, selectedIndex, "unfinished")
    end

    local function restoreSelectedQuest(list)
        local selectedIndex = list:getSelectedIndex()
        local selectedQuest = questList[selectedIndex]

        if not selectedQuest or selectedQuest.kind ~= "cleaned" then
            ui.showMessage("Select a cleaned quest to restore.")
            return
        end

        player:sendEvent(
            "QuestClean_questReenabled",
            { questIds = selectedQuest.questIds }
        )

        cleanedQuestsByName[selectedQuest.nameKey] = nil
        cleanedQuestNames[selectedQuest.nameKey] = nil
        if not finishedQuestNames[selectedQuest.nameKey] then
            selectedQuest.kind = "unfinished"
            unfinishedQuestsByName[selectedQuest.nameKey] = selectedQuest
        end
        refreshList(list, selectedIndex, "cleaned")
    end



    local virtualQuestList
    virtualQuestList = VirtualList.create {
        viewportSize = v2(questListWidth - 3, contentHeight - 3),
        itemSize = v2(questListWidth, textSize + 2),
        itemCount = #questList,
        itemLayout = function(idx, list)
            local itemLayout = list:createItemLayout {
                index = idx,
                props = {
                    text = getListText(questList[idx]),
                    textSize = textSize,
                },
                onMousePress = function()
                    onQuestSelect(list, idx)
                end,
            }

            return itemLayout
        end,
    }

    virtualQuestList:setKeyPressHandler({
        setSelectedIndex = function(idx)
            onQuestSelect(virtualQuestList, idx)
        end,
    })

    storedNavigate = function(direction)
        local selectedIndex = virtualQuestList:getSelectedIndex() or getInitialIndex()
        local nextIndex = nil

        for idx = selectedIndex + direction, direction > 0 and #questList or 1, direction do
            if isQuestRow(questList[idx]) then
                nextIndex = idx
                break
            end
        end

        if not nextIndex then return end

        onQuestSelect(virtualQuestList, nextIndex)
        if direction > 0 then
            virtualQuestList:scrollToIndex(nextIndex, "bottom")
        else
            virtualQuestList:scrollToIndex(nextIndex, "top")
        end
    end

    local content = {
        name = "content",
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            padding(contentOuterPadding, 0),
            borderPadding(virtualQuestList:getElement(), v2(questListWidth, contentHeight)),
            padding(contentCenterPadding, 0),
            descWrapper,
            padding(contentOuterPadding, 0),
        }
    }

    local header = {
        name = "header",
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = "Quest Clean",
            textSize = textSize,
        }
    }

    local buttonFocusIndex = 1
    local footerButtons = {}

    local function updateButtonFocus()
        for idx, button in pairs(footerButtons) do
            local btnText = button.layout.content[1].content[2]
            btnText.props.textColor = idx == buttonFocusIndex
                and buttonConsts.Colors.DEFAULT_LIGHT
                or buttonConsts.Colors.DEFAULT
            button:update()
        end
    end

    local function makeFooterButton(text, action, name)
        local button = buttonTemplate.button(text, textSize, action, name, 1)
        footerButtons[#footerButtons + 1] = button
        return button
    end

    local cleanButton = makeFooterButton(
        "Clean",
        function()
            cleanSelectedQuest(virtualQuestList)
        end,
        "buttonClean"
    )
    local restoreButton = makeFooterButton(
        "Restore",
        function()
            restoreSelectedQuest(virtualQuestList)
        end,
        "buttonRestore"
    )
    local closeButton = makeFooterButton(
        "Close",
        function()
            player:sendEvent("QuestClean_closeMenu")
        end,
        "buttonClose"
    )

    storedNavigateButton = function(direction)
        buttonFocusIndex = util.clamp(buttonFocusIndex + direction, 1, #footerButtons)
        updateButtonFocus()
    end

    storedPressButton = function()
        local button = footerButtons[buttonFocusIndex]
        if button and button.layout.events.mouseRelease then
            button.layout.events.mouseRelease()
        end
    end

    local footer = ui.create {
        name = "footer",
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            size = v2(rootWidth, 0),
            align = ui.ALIGNMENT.Start
        },
        content = ui.content {
            cleanButton,
            padding(contentCenterPadding, 0),
            restoreButton,
            padding(contentCenterPadding, 0),
            closeButton,
            padding(contentCenterPadding, 0),
        }
    }

    root = ui.create {
        name = "root",
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = ui.content { {
            name = "rootPadding",
            template = I.MWUI.templates.padding,
            content = ui.content { {
                name = "flex_V1",
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    padding(0, topPadding),
                    header,
                    padding(0, contentOuterPadding),
                    content,
                    padding(0, contentOuterPadding),
                    footer,
                    padding(0, topPadding),
                }
            } }
        } }
    }
    storedRoot = root

    onQuestSelect(virtualQuestList, getInitialIndex())
    updateButtonFocus()
    root:update()

    return root
end

questsWindow.getMouseWheelHandler = VirtualList.getMouseWheelHandler
questsWindow.navigate = function(direction)
    storedNavigate(direction)
end
questsWindow.navigateButton = function(direction)
    storedNavigateButton(direction)
end
questsWindow.pressButton = function()
    storedPressButton()
end
questsWindow.close = function ()
    if storedRoot then
        auxUi.deepDestroy(storedRoot)
        storedRoot = nil
    end
    storedNavigate = function() end
    storedNavigateButton = function() end
    storedPressButton = function() end
end
return questsWindow
