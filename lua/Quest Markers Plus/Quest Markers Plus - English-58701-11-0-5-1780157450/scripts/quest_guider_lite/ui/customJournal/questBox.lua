local core = require('openmw.core')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')
local util = require('openmw.util')
local templates = require('openmw.interfaces').MWUI.templates
local playerRef = require('openmw.self')

local log = require("scripts.quest_guider_lite.utils.log")

local config = require("scripts.quest_guider_lite.configLib")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local timeLib = require("scripts.quest_guider_lite.timeLocal")
local common = require('scripts.quest_guider_lite.common')
local tracking = require("scripts.quest_guider_lite.trackingLocal")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local tableLib = require("scripts.quest_guider_lite.utils.table")

local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")
local interval = require("scripts.quest_guider_lite.ui.interval")
local checkBox = require("scripts.quest_guider_lite.ui.checkBox")
local button = require("scripts.quest_guider_lite.ui.button")
local tooltip = require("scripts.quest_guider_lite.ui.tooltip")

local dialogueIDTooltipLib = require("scripts.quest_guider_lite.ui.dialogueIdTooltip")

local l10n = core.l10n(common.l10nKey)

local COLOR_HEADER = util.color.rgb(223 / 255, 201 / 255, 159 / 255)
local COLOR_GOLD = util.color.rgb(0.79, 0.65, 0.38)
local COLOR_GOLD_BRIGHT = util.color.rgb(0.9, 0.78, 0.5)
local COLOR_GOLD_DIM = util.color.rgb(0.55, 0.45, 0.25)
local COLOR_GRAY = util.color.rgb(0.45, 0.45, 0.45)
local COLOR_LINK = util.color.rgb(0.85, 0.72, 0.45)
local COLOR_BG_DARK = util.color.rgb(0.04, 0.03, 0.02)
local COLOR_DIVIDER = util.color.rgb(0.4, 0.33, 0.18)

local borderTexTop = ui.texture{ path = "textures/menu_thin_border_top.dds" }

local HEX_GOLD = COLOR_GOLD:asHex()
local HEX_GOLD_BRIGHT = COLOR_GOLD_BRIGHT:asHex()
local HEX_GOLD_DIM = COLOR_GOLD_DIM:asHex()
local HEX_LINK = COLOR_LINK:asHex()

local this = {}


---@class questGuider.ui.questBoxMeta
local questBoxMeta = {}
questBoxMeta.__index = questBoxMeta

---@type table<string, {diaId : string, index : integer, contentIndex : integer}>
questBoxMeta.dialogueInfo = {}

questBoxMeta.trackObjectsFunc = nil
questBoxMeta.untrackObjectsFunc = nil
questBoxMeta.toggleTrackObjectsFunc = nil
questBoxMeta.toggleTopTopicsFunc = nil

function questBoxMeta:getScrollBox()
    return self:getLayout()
end

---@return questGuider.ui.scrollBox
function questBoxMeta:getScrollBoxMeta()
    return self:getScrollBox().userData.scrollBoxMeta
end

function questBoxMeta:getButtonWidget()
    return self._buttonWidget
end

function questBoxMeta:getButtonFlex()
    return self._buttonFlex
end

function questBoxMeta:getHeader()
    return self._headerNameText
end

function questBoxMeta:addTrackButtons(showRemoveBtn)
    self:getButtonFlex().content = ui.content{}

    if tracking.initialized and not self.params.isQuestList then
        self.trackObjectsFunc = function()
            self:addTrackButtons(true)
            for _, info in pairs(self.questInfo) do
                tracking.trackQuest(info.diaId, info.diaIndex)
                break
            end
            async:newUnsavableSimulationTimer(0.1, function()
                tracking.updateTemporaryMarkers()
            end)
        end
    else
        self.trackObjectsFunc = nil
    end

    local hasTracked = showRemoveBtn
    for _, info in pairs(self.dialogueInfo) do
        hasTracked = hasTracked or tracking.isDialogueHasTracked{diaId = info.diaId}
        if hasTracked then break end
    end

    if hasTracked then
        self.untrackObjectsFunc = function()
            for _, info in pairs(self.questInfo) do
                tracking.removeMarker{
                    questId = info.diaId,
                    removeLinked = true
                }
                tracking.updateMarkers()
                break
            end
            tracking.updateTemporaryMarkers()
            self:addTrackButtons()
            playerRef:sendEvent("QGL:updateQuestMenu", {})
        end
    else
        self.untrackObjectsFunc = nil
    end

    self.toggleTrackObjectsFunc = function()
        local isTracked = false
        for _, info in pairs(self.dialogueInfo) do
            isTracked = isTracked or tracking.isDialogueHasTracked{diaId = info.diaId}
            if isTracked then break end
        end
        if isTracked then
            if self.untrackObjectsFunc then self.untrackObjectsFunc() end
        else
            if self.trackObjectsFunc then self.trackObjectsFunc() end
        end
    end

    if hasTracked then
        self:getButtonFlex().content:add(interval(self.params.fontSize, 0))
        self:getButtonFlex().content:add(button{
            text = l10n("removeTracking"),
            textSize = self.params.fontSize * 0.8,
            visible = tracking.initialized and not self.params.isQuestList,
            parentScrollBoxUserData = self:getScrollBox().userData,
            event = self.untrackObjectsFunc,
            updateFunc = function() self.params.updateFunc() end
        })
    else
        self:getButtonFlex().content:add(button{
            text = l10n("trackObjects"),
            textSize = self.params.fontSize * 0.8,
            visible = tracking.initialized and not self.params.isQuestList,
            parentScrollBoxUserData = self:getScrollBox().userData,
            event = self.trackObjectsFunc,
            updateFunc = function() self.params.updateFunc() end
        })
    end
end


---@param params questGuider.ui.questBox.params
function questBoxMeta:_fillJournal(content, params)
    self.dialogueInfo = {}
    ---@type table<string, boolean>
    local addedDiaIds = {}

    local contentIndex = 2
    local function addElement(i)
        local qInfo = params.playerQuestData.list[i]
        if not qInfo then goto continue end

        if params.showOnlyFirst and addedDiaIds[qInfo.diaId] then return end

        local text = self.params.hideStageText and "" or playerQuests.getJournalText(qInfo.diaId, qInfo.index)
        if not text then goto continue end

        local topicLinkStrs = stringLib.findTextLinks(text)
        text = stringLib.removeSpecialCharactersFromJournalText(text)

        if self.params.showReqsForAll or not addedDiaIds[qInfo.diaId] then
            addedDiaIds[qInfo.diaId] = true
            local id = qInfo.diaId .. tostring(qInfo.index)
            if not self.dialogueInfo[id] or self.dialogueInfo[id].index < qInfo.index then
                self.dialogueInfo[id] = {
                    diaId = qInfo.diaId,
                    index = qInfo.index,
                    contentIndex = contentIndex,
                }
            end
        end

        local dateStr = self.params.isQuestList
            and string.format(l10n("tooltipIDStringStart"), qInfo.diaId, tostring(qInfo.index))
            or timeLib.getDateByTime(timeLib.getTimestamp(qInfo))

        local height = uiUtils.getTextHeight(text, params.fontSize, self.scrollBoxContentSize.x, config.data.journal.textHeightMulRecord, 1, true)
        local textElemSize = util.vector2(self.scrollBoxContentSize.x, height)

        local topicData = {}
        local linkColor = "#" .. HEX_LINK
        if next(topicLinkStrs) then
            for _, str in pairs(topicLinkStrs) do
                for topicId, topic in pairs(playerQuests.getTopicList()) do
                    if stringLib.fuzzyTopicSearch(str, topic.id) then
                        table.insert(topicData, {topic = topic, pattern = str, color = linkColor, patternLen = stringLib.length(str)})
                    end
                end
            end
        else
            for topicId, topic in pairs(playerQuests.getTopicList()) do
                if stringLib.hasPhrase(stringLib.utf8_lower(text), topic.id) then
                    table.insert(topicData, {topic = topic, pattern = topic.name, color = linkColor, patternLen = stringLib.length(topic.name)})
                end
            end
        end

        table.sort(topicData, function(a, b) return a.patternLen > b.patternLen end)
        text = uiUtils.colorizeNestedMulti(text, topicData, "#" .. HEX_GOLD)

        local tooltipContent = dialogueIDTooltipLib.getContentForTooltip{
            recordInfo = qInfo, fontSize = params.fontSize, filter = self.parent.textFilter
        }

        local element

        local function changeEntryBlockText(toggle)
            local textElem = element.content[3].content[2]
            local withTopics
            if toggle then
                withTopics = not textElem.userData.withTopics
            else
                withTopics = textElem.userData.withTopics
            end

            local newText = uiUtils.colorizeNested(text, self.parent.textFilter,
                "#" .. HEX_GOLD_BRIGHT, "#" .. HEX_GOLD)

            if withTopics then
                local topics = {}
                for _, data in pairs(topicData) do
                    topics[data.topic.id] = data.topic
                end
                newText = newText .. "\n\n\n"
                for _, topic in pairs(topics) do
                    local topicText = string.format("#%s%s#%s:\n\n",
                        config.data.ui.linkColor:asHex(), topic.name, config.data.ui.defaultColor:asHex())
                    local entryCount = #topic.entries
                    local startIndex = math.max(1, entryCount - config.data.journal.maxTopicEntriesInJournal + 1)
                    if startIndex ~= 1 then
                        topicText = string.format("%s%s\n\n", topicText, l10n("ellipsis"))
                    end
                    for j = startIndex, entryCount do
                        local entry = topic.entries[j]
                        local entryText = stringLib.removeSpecialCharactersFromJournalText(entry.text) or ""
                        topicText = string.format("%s\t#%s%s#%s: \"%s\"\n\n",
                            topicText, HEX_GOLD, entry.actor, config.data.ui.defaultColor:asHex(), entryText)
                    end
                    newText = newText .. topicText
                end
            end

            local newTextHeight = uiUtils.getTextHeight(newText, params.fontSize, self.scrollBoxContentSize.x, config.data.journal.textHeightMulRecord, 1, true)
            if withTopics then
                newTextHeight = math.max(0, newTextHeight - 2 * params.fontSize)
            end

            textElem.props.size = util.vector2(self.scrollBoxContentSize.x, newTextHeight)
            textElem.props.text = newText
            textElem.userData.withTopics = withTopics
            return withTopics
        end

        local function toggleTopics()
            changeEntryBlockText(true)
            local sb = self:getScrollBoxMeta()
            sb:calcContentHeight()
            sb:updateContent()
        end

        if not self.toggleTopTopicsFunc then
            self.toggleTopTopicsFunc = function()
                if not (tracking.initialized and not self.params.isQuestList and next(topicData)
                        and config.data.journal.maxTopicEntriesInJournal > 0) then return end
                toggleTopics()
                self:update()
            end
        end

        element = {
            type = ui.TYPE.Flex,
            props = { autoSize = true, horizontal = false },
            userData = {
                contentIndex = contentIndex,
                info = qInfo,
                topicData = topicData,
            },
            content = ui.content{
                interval(0, params.fontSize),
                {
                    type = ui.TYPE.Widget,
                    props = {
                        autoSize = false,
                        size = util.vector2(textElemSize.x, params.fontSize * 1.25),
                    },
                    content = ui.content{
                        {
                            type = ui.TYPE.Text,
                            props = {
                                text = uiUtils.colorize(dateStr, self.parent.textFilter,
                                    "#" .. HEX_GOLD_BRIGHT, "#" .. HEX_GOLD_DIM),
                                autoSize = true,
                                textSize = (params.fontSize or 18) * 1.15,
                                textColor = COLOR_GOLD_DIM,
                            },
                            userData = {
                                defaultTextColor = COLOR_GOLD_DIM,
                                topicData = topicData,
                            },
                            events = {
                                mouseMove = async:callback(function(coord, layout)
                                    local scrollMeta = self.getLayout().userData.scrollBoxMeta
                                    scrollMeta:mouseMove(coord)
                                    tooltip.createOrMove(coord, layout, tooltipContent)
                                end),
                                focusLoss = async:callback(function(e, layout)
                                    local scrollMeta = self.getLayout().userData.scrollBoxMeta
                                    scrollMeta:focusLoss(e)
                                    tooltip.destroy(layout)
                                end),
                            },
                        },
                        button{
                            text = l10n("topics"),
                            textSize = self.params.fontSize * 0.8,
                            visible = tracking.initialized and not self.params.isQuestList and next(topicData)
                                and config.data.journal.maxTopicEntriesInJournal > 0 and true or false,
                            position = util.vector2(textElemSize.x - config.data.ui.scrollArrowSize - 8, params.fontSize * 1.25 * 0.5),
                            anchor = util.vector2(1, 0.5),
                            parentScrollBoxUserData = self:getScrollBox().userData,
                            event = function(layout)
                                toggleTopics()
                            end,
                            updateFunc = function()
                                self.params.updateFunc()
                            end
                        }
                    }
                },
                {
                    type = ui.TYPE.Flex,
                    props = { autoSize = true, horizontal = true },
                    content = ui.content{
                        interval(4, 1),
                        {
                            template = templates.textNormal,
                            type = ui.TYPE.Text,
                            userData = {
                                defaultTextColor = COLOR_GOLD,
                                topicData = topicData,
                                text = text,
                                withTopics = false,
                                changeEntryBlockTextFunc = changeEntryBlockText,
                            },
                            props = {
                                text = uiUtils.colorizeNested(text, self.parent.textFilter,
                                    "#" .. HEX_GOLD_BRIGHT, "#" .. HEX_GOLD),
                                textColor = COLOR_GOLD,
                                autoSize = false,
                                size = textElemSize,
                                textSize = params.fontSize or 18,
                                multiline = true,
                                wordWrap = true,
                                textAlignH = ui.ALIGNMENT.Center,
                            },
                        }
                    }
                },
            }
        }

        content:add(element)
        contentIndex = contentIndex + 1

        ::continue::
    end

    if self.params.isQuestList then
        for i = 1, #params.playerQuestData.list do
            addElement(i)
        end
    else
        for i = #params.playerQuestData.list, 1, -1 do
            addElement(i)
        end
    end

    local sb = self:getScrollBoxMeta()
    sb:calcContentHeight()
    sb:updateContent()
end


function questBoxMeta:updateColors()
    local scrBox = self:getScrollBox()
    if not scrBox then return end

    local scrollBoxElem = self:getScrollBoxMeta()
    local content = scrollBoxElem:getContent()

    if self._headerNameText then
        self._headerNameText.props.text = uiUtils.removeColorMarkers(self._headerNameText.props.text)
        if self.parent.textFilter ~= "" then
            self._headerNameText.props.text = uiUtils.colorize(self._headerNameText.props.text,
                self.parent.textFilter, "#" .. HEX_GOLD_BRIGHT,
                "#" .. (self._headerNameText.userData.defaultTextColor or COLOR_GOLD):asHex())
        end
    end

    for i = 2, #content do
        local entry = content[i]
        if not entry or not entry.content then goto continue end

        local dateWidget = entry.content[2]
        if dateWidget and dateWidget.content then
            local dateElem = dateWidget.content[1]
            if dateElem and dateElem.props then
                dateElem.props.text = uiUtils.removeColorMarkers(dateElem.props.text)
                if self.parent.textFilter ~= "" then
                    dateElem.props.text = uiUtils.colorize(dateElem.props.text, self.parent.textFilter,
                        "#" .. HEX_GOLD_BRIGHT, "#" .. (dateElem.userData.defaultTextColor or COLOR_GOLD_DIM):asHex())
                end
            end
        end

        local textFlex = entry.content[3]
        if textFlex and textFlex.content then
            local stageTextElem = textFlex.content[2]
            if stageTextElem and stageTextElem.userData and stageTextElem.userData.changeEntryBlockTextFunc then
                stageTextElem.props.text = uiUtils.removeColorMarkers(stageTextElem.props.text)
                stageTextElem.userData.changeEntryBlockTextFunc()
            end
        end

        ::continue::
    end

    scrollBoxElem:calcContentHeight()
    scrollBoxElem:updateContent()
end


---@class questGuider.ui.questBox.params
---@field size any
---@field fontSize integer
---@field questName string,
---@field playerQuestData questGuider.playerQuest.storageQuestData
---@field isQuestList boolean?
---@field hideStageText boolean?
---@field showReqsForAll boolean?
---@field showOnlyFirst boolean?
---@field updateFunc function
---@field parent questGuider.ui.customJournal
---@field userData table


---@param params questGuider.ui.questBox.params
function this.create(params)

    ---@class questGuider.ui.questBoxMeta
    local meta = setmetatable({}, questBoxMeta)

    meta.params = params

    meta.update = function(self)
        params.updateFunc()
    end

    meta.parent = params.parent

    meta.scrollBoxContentSize = util.vector2(params.size.x - 26, params.size.y - 2)

    local journalContent = ui.content{}

    local userData = { questBoxMeta = meta }
    if params.userData then
        tableLib.copy(params.userData, userData)
    end

    local journalEntries = scrollBox{
        name = params.questName,
        updateFunc = params.updateFunc,
        size = util.vector2(params.size.x, params.size.y - 2),
        leftOffset = 8,
        scrollAmount = params.size.y / 5,
        content = journalContent,
        contentHeight = 0,
        autoOptimize = true,
        userData = userData,
    }

    local tooltipContent = dialogueIDTooltipLib.getContentForTooltip{meta = meta, filter = meta.parent.textFilter}

    local checkBoxBlockSize = util.vector2(meta.scrollBoxContentSize.x, params.fontSize * 2)

    -- Header: quest name + checkboxes + track buttons + divider
    -- The divider is INSIDE the header to keep contentIndex aligned with journal entries
    local headerHeight = params.fontSize * 1.2 + params.fontSize / 3 + checkBoxBlockSize.y + params.fontSize * 0.5 + 2

    local headerNameText = {
        template = templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            text = uiUtils.colorize(params.questName, meta.parent.textFilter,
                "#" .. HEX_GOLD_BRIGHT, "#" .. COLOR_HEADER:asHex()),
            textColor = COLOR_HEADER,
            autoSize = false,
            size = util.vector2(meta.scrollBoxContentSize.x, (params.fontSize or 18) * 1.2),
            textSize = (params.fontSize or 18) * 1.2,
            multiline = false,
            wordWrap = false,
            textAlignH = ui.ALIGNMENT.Center,
        },
        userData = { defaultTextColor = COLOR_GOLD },
        events = {
            mouseMove = async:callback(function(coord, layout)
                local scrollMeta = meta.getLayout().userData.scrollBoxMeta
                scrollMeta:mouseMove(coord)
                tooltip.createOrMove(coord, layout, tooltipContent)
            end),
            focusLoss = async:callback(function(e, layout)
                local scrollMeta = meta.getLayout().userData.scrollBoxMeta
                scrollMeta:focusLoss(e)
                tooltip.destroy(layout)
            end),
        },
    }

    local buttonFlex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = true,
            anchor = util.vector2(1, 0.5),
            position = util.vector2(meta.scrollBoxContentSize.x - params.fontSize * 3, checkBoxBlockSize.y / 2),
        },
        content = ui.content{}
    }

    local buttonWidget = {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = checkBoxBlockSize,
            horizontal = true,
        },
        content = ui.content{
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = true,
                    anchor = util.vector2(0, 0.5),
                    position = util.vector2(0, checkBoxBlockSize.y / 2),
                },
                content = ui.content{
                    checkBox{
                        updateFunc = function() params.updateFunc() end,
                        checked = params.playerQuestData.pinned,
                        text = l10n("pinned"),
                        textSize = params.fontSize or 18,
                        visible = not params.isQuestList,
                        getScrollBoxMeta = function() return meta:getScrollBoxMeta() end,
                        event = function(checked, layout)
                            params.playerQuestData.pinned = checked
                            local selectedQuest = meta.parent:getQuestListSelectedFladValue()
                            meta.parent:fillQuestsContent()
                            meta.parent:selectQuest(selectedQuest)
                        end
                    },
                    interval(config.data.ui.fontSize, 0),
                    checkBox{
                        updateFunc = function() params.updateFunc() end,
                        checked = params.playerQuestData.finished,
                        text = l10n("finished"),
                        textSize = params.fontSize or 18,
                        visible = not params.isQuestList,
                        getScrollBoxMeta = function() return meta:getScrollBoxMeta() end,
                        event = function(checked, layout)
                            params.playerQuestData.finished = checked
                            local selectedQuest = meta.parent:getQuestListSelectedFladValue()
                            meta.parent:fillQuestsContent()
                            meta.parent:selectQuest(selectedQuest)
                        end
                    },
                    interval(config.data.ui.fontSize, 0),
                    checkBox{
                        updateFunc = function() params.updateFunc() end,
                        checked = params.playerQuestData.disabled,
                        text = l10n("hidden"),
                        textSize = params.fontSize or 18,
                        visible = not params.isQuestList,
                        getScrollBoxMeta = function() return meta:getScrollBoxMeta() end,
                        event = function(checked, layout)
                            params.playerQuestData.disabled = checked
                            local qData = playerQuests.getQuestDataByName(params.questName)
                            if qData then
                                local changed = false
                                for diaId, _ in pairs(qData.records or {}) do
                                    changed = tracking.setDisableMarkerState{questId = diaId, value = checked} or changed
                                end
                                if changed then tracking.updateMarkers() end
                            end
                            local selectedQuest = meta.parent:getQuestListSelectedFladValue()
                            meta.parent:fillQuestsContent()
                            meta.parent:selectQuest(selectedQuest)
                        end
                    },
                }
            },
            buttonFlex,
        }
    }

    meta._headerNameText = headerNameText
    meta._buttonWidget = buttonWidget
    meta._buttonFlex = buttonFlex

    local header = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = util.vector2(meta.scrollBoxContentSize.x, headerHeight),
        },
        content = ui.content{
            headerNameText,
            interval(0, params.fontSize / 3),
            buttonWidget,
            interval(0, params.fontSize * 0.5),
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content{
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = borderTexTop,
                            tileH = true,
                            size = util.vector2(meta.scrollBoxContentSize.x * 0.85, 2),
                        },
                    },
                },
            },
        }
    }

    journalContent:add(header)

    meta.getLayout = function(self)
        return journalEntries
    end

    meta:_fillJournal(journalContent, params)

    return journalEntries
end


return this
