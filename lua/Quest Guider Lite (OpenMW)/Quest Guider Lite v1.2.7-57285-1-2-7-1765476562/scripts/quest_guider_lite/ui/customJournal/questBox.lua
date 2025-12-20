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


local this = {}


---@class questGuider.ui.questBoxMeta
local questBoxMeta = {}
questBoxMeta.__index = questBoxMeta

---@type table<string, {diaId : string, index : integer, contentIndex : integer}>
questBoxMeta.dialogueInfo = {}

function questBoxMeta.getScrollBox(self)
    return self:getLayout()
end

---@return questGuider.ui.scrollBox
function questBoxMeta.getScrollBoxMeta(self)
    return self:getScrollBox().userData.scrollBoxMeta
end

function questBoxMeta.getButtonWidget(self)
    return self:getScrollBoxMeta():getMainFlex().content[1].content[3]
end

function questBoxMeta.getButtonFlex(self)
    return self:getButtonWidget().content[3]
end

function questBoxMeta.getHeader(self)
    return self:getScrollBoxMeta():getMainFlex().content[1]
end

function questBoxMeta.addTrackButtons(self, showRemoveBtn)
    self:getButtonFlex().content = ui.content{}
    self:getButtonFlex().content:add(button{
        text = l10n("trackObjects"),
        textSize = self.params.fontSize * 0.8,
        visible = tracking.initialized and not self.params.isQuestList,
        parentScrollBoxUserData = self:getScrollBox().userData,
        event = function (layout)
            self:addTrackButtons(true)

            for _, info in pairs(self.questInfo) do
                tracking.trackQuest(info.diaId, info.diaIndex)
                break
            end
            async:newUnsavableSimulationTimer(0.1, function ()
                tracking.updateTemporaryMarkers()
            end)
        end,
        updateFunc = function ()
            self.params.updateFunc()
        end
    })

    local hasTracked = showRemoveBtn
    for _, info in pairs(self.dialogueInfo) do
        hasTracked = hasTracked or tracking.isDialogueHasTracked{diaId = info.diaId}
        if hasTracked then break end
    end

    if hasTracked then
        self:getButtonFlex().content:add(interval(self.params.fontSize, 0))
        self:getButtonFlex().content:add(button{
            text = l10n("removeTracking"),
            textSize = self.params.fontSize * 0.8,
            visible = tracking.initialized and not self.params.isQuestList,
            parentScrollBoxUserData = self:getScrollBox().userData,
            event = function (layout)
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
            end,
            updateFunc = function ()
                self.params.updateFunc()
            end
        })
    end
end


---@param params questGuider.ui.questBox.params
function questBoxMeta._fillJournal(self, content, params)

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
            local id = qInfo.diaId..tostring(qInfo.index)
            if not self.dialogueInfo[id] or self.dialogueInfo[id].index < qInfo.index then
                self.dialogueInfo[id] = {
                    diaId = qInfo.diaId,
                    index = qInfo.index,
                    contentIndex = contentIndex,
                }
            end
        end

        local dateStr = self.params.isQuestList and string.format(l10n("tooltipIDStringStart"), qInfo.diaId, tostring(qInfo.index))
            or timeLib.getDateByTime(qInfo.timestamp or 0)

        local height = uiUtils.getTextHeight(text, params.fontSize, self.scrollBoxContentSize.x, config.data.journal.textHeightMulRecord, 1, true)
        local textElemSize = util.vector2(self.scrollBoxContentSize.x, height)

        local topicData = {}
        local linkColor = "#"..config.data.ui.linkColor:asHex()
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

        table.sort(topicData, function (a, b)
            return a.patternLen > b.patternLen
        end)
        text = uiUtils.colorizeNestedMulti(text, topicData, "#"..config.data.ui.defaultColor:asHex())

        local tooltipContent = dialogueIDTooltipLib.getContentForTooltip{recordInfo = qInfo, fontSize = params.fontSize,
            filter = self.parent.textFilter}

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
                "#"..config.data.ui.selectionColor:asHex(), "#"..config.data.ui.defaultColor:asHex())

            if withTopics then
                local topics = {}
                for _, data in pairs(topicData) do
                    topics[data.topic.id] = data.topic
                end

                newText = newText.."\n\n\n"
                for _, topic in pairs(topics) do
                    local topicText = string.format("#%s%s#%s:\n\n", config.data.ui.linkColor:asHex(),
                        topic.name, config.data.ui.defaultColor:asHex())

                    local entryCount = #topic.entries
                    local startIndex = math.max(1, entryCount - config.data.journal.maxTopicEntriesInJournal + 1)
                    local endIndex = entryCount

                    if startIndex ~= 1 then
                        topicText = string.format("%s%s\n\n", topicText, l10n("ellipsis"))
                    end

                    for j = startIndex, endIndex do
                        local entry = topic.entries[j]
                        local entryText = stringLib.removeSpecialCharactersFromJournalText(entry.text) or ""
                        topicText = string.format("%s\t#%s%s#%s: \"%s\"\n\n",
                            topicText,
                            config.data.ui.objectColor:asHex(),
                            entry.actor,
                            config.data.ui.defaultColor:asHex(),
                            entryText
                        )
                    end

                    newText = newText..topicText
                end
            end

            local newTextHeight = uiUtils.getTextHeight(newText, params.fontSize, self.scrollBoxContentSize.x, config.data.journal.textHeightMulRecord, 1, true)
            if withTopics then
                newTextHeight = math.max(0, newTextHeight - 2 * params.fontSize)
            end
            local newTextElemSize = util.vector2(self.scrollBoxContentSize.x, newTextHeight)

            textElem.props.size = newTextElemSize

            textElem.props.text = newText

            textElem.userData.withTopics = withTopics
            return withTopics
        end


        element = {
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
                horizontal = false,
            },
            userData = {
                contentIndex = contentIndex,
                info = qInfo,
                topicData = topicData,
            },
            content = ui.content {
                interval(0, params.fontSize),
                {
                    type = ui.TYPE.Widget,
                    props = {
                        autoSize = false,
                        size = util.vector2(textElemSize.x, params.fontSize * 1.25),
                    },
                    content = ui.content {
                        {
                            type = ui.TYPE.Text,
                            props = {
                                text = uiUtils.colorize(dateStr, self.parent.textFilter,
                                    "#"..config.data.ui.selectionColor:asHex(), "#"..config.data.ui.dateColor:asHex()),
                                autoSize = true,
                                textSize = (params.fontSize or 18) * 1.15,
                                textColor = config.data.ui.dateColor,
                            },
                            userData = {
                                defaultTextColor = config.data.ui.dateColor,
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
                            event = function (layout)
                                changeEntryBlockText(true)
                                self:getScrollBoxMeta():setContentHeight(uiUtils.getContentHeight(content))
                            end,
                            updateFunc = function ()
                                self.params.updateFunc()
                            end
                        }
                    }
                },
                {
                    type = ui.TYPE.Flex,
                    props = {
                        autoSize = true,
                        horizontal = true,
                    },
                    content = ui.content {
                        interval(4, 1),
                        {
                            template = templates.textNormal,
                            type = ui.TYPE.Text,
                            userData = {
                                defaultTextColor = config.data.ui.defaultColor,
                                topicData = topicData,
                                text = text,
                                withTopics = false,
                                changeEntryBlockTextFunc = changeEntryBlockText,
                            },
                            props = {
                                text = uiUtils.colorizeNested(text, self.parent.textFilter,
                                    "#"..config.data.ui.selectionColor:asHex(), "#"..config.data.ui.defaultColor:asHex()),
                                textColor = config.data.ui.defaultColor,
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

    self:getScrollBoxMeta():setContentHeight(uiUtils.getContentHeight(content))
end


function questBoxMeta:updateColors()

    local scrBox = self:getScrollBox()
    if not scrBox then return end

    ---@type questGuider.ui.scrollBox
    local scrollBoxElem = self:getScrollBox().userData.scrollBoxMeta
    local mainFlex = scrollBoxElem:getMainFlex()

    local header = mainFlex.content[1]
    if not header then return end

    header.content[1].props.text = uiUtils.removeColorMarkers(header.content[1].props.text)
    if self.parent.textFilter ~= "" then
        header.content[1].props.text = uiUtils.colorize(header.content[1].props.text, self.parent.textFilter,
            "#"..config.data.ui.selectionColor:asHex(), "#"..header.content[1].userData.defaultTextColor:asHex())
    end

    for i = 2, #mainFlex.content do
        local dateElem = mainFlex.content[i].content[2].content[1]

        dateElem.props.text = uiUtils.removeColorMarkers(dateElem.props.text)
        if self.parent.textFilter ~= "" then
            dateElem.props.text = uiUtils.colorize(dateElem.props.text, self.parent.textFilter,
                "#"..config.data.ui.selectionColor:asHex(), "#"..dateElem.userData.defaultTextColor:asHex())
        end

        local stageTextElem = mainFlex.content[i].content[3].content[2]

        stageTextElem.props.text = uiUtils.removeColorMarkers(stageTextElem.props.text)

        stageTextElem.userData.changeEntryBlockTextFunc()
        self:getScrollBoxMeta():setContentHeight(uiUtils.getContentHeight(self:getScrollBoxMeta():getMainFlex().content))
    end
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

    meta.update = function (self)
        params.updateFunc()
    end

    meta.parent = params.parent

    meta.scrollBoxContentSize = util.vector2(params.size.x - 26, params.size.y - 2)

    local journalContent = ui.content{}

    local userData = {
        questBoxMeta = meta,
    }
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
        userData = userData
    }

    local tooltipContent = dialogueIDTooltipLib.getContentForTooltip{meta = meta, filter = meta.parent.textFilter}

    local headerSize = util.vector2(meta.scrollBoxContentSize.x, params.fontSize * 4)
    local checkBoxBlockSize = util.vector2(meta.scrollBoxContentSize.x, params.fontSize * 2)
    local header
    header = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = headerSize
        },
        content = ui.content {
            {
                template = templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text = uiUtils.colorize(params.questName, meta.parent.textFilter,
                        "#"..config.data.ui.selectionColor:asHex(), "#"..config.data.ui.defaultColor:asHex()),
                    textColor = config.data.ui.defaultColor,
                    autoSize = false,
                    size = util.vector2(meta.scrollBoxContentSize.x, (params.fontSize or 18) * 1.2),
                    textSize = (params.fontSize or 18) * 1.2,
                    multiline = false,
                    wordWrap = false,
                    textAlignH = ui.ALIGNMENT.Center,
                },
                userData = {
                    defaultTextColor = config.data.ui.defaultColor,
                },
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
            },
            interval(0, params.fontSize / 3),
            {
                type = ui.TYPE.Widget,
                props = {
                    autoSize = false,
                    size = checkBoxBlockSize,
                    horizontal = true,
                },
                content = ui.content {
                    checkBox{
                        updateFunc = function ()
                            params.updateFunc()
                        end,
                        checked = params.playerQuestData.finished,
                        text = l10n("finished"),
                        textSize = params.fontSize or 18,
                        visible = not params.isQuestList,
                        relativePosition = util.vector2(0.01, 0.5),
                        anchor = util.vector2(0, 0.5),
                        event = function (checked, layout)
                            params.playerQuestData.finished = checked
                        end
                    },
                    checkBox{
                        updateFunc = function ()
                            params.updateFunc()
                        end,
                        checked = params.playerQuestData.disabled,
                        text = l10n("hidden"),
                        relativePosition = util.vector2(0.25, 0.5),
                        anchor = util.vector2(0, 0.5),
                        textSize = params.fontSize or 18,
                        visible = not params.isQuestList,
                        event = function (checked, layout)
                            params.playerQuestData.disabled = checked
                            local qData = playerQuests.getQuestDataByName(params.questName)
                            if qData then
                                local changed = false
                                for diaId, _ in pairs(qData.records or {}) do
                                    changed = tracking.setDisableMarkerState{questId = diaId, value = checked} or changed
                                end
                                if changed then
                                    tracking.updateMarkers()
                                end
                            end
                        end
                    },
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = true,
                            horizontal = true,
                            anchor = util.vector2(1, 0.5),
                            position = util.vector2(meta.scrollBoxContentSize.x - params.fontSize * 3, checkBoxBlockSize.y / 2),
                        },
                        content = ui.content{}
                    },
                }
            },
        }
    }

    journalContent:add(header)

    meta.getLayout = function (self)
        return journalEntries
    end

    meta:_fillJournal(journalContent, params)

    return journalEntries
end


return this