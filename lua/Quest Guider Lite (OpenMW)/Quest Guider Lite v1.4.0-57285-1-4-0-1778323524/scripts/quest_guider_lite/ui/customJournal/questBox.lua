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
local questBase = require("scripts.quest_guider_lite.questBase")
local timeLib = require("scripts.quest_guider_lite.timeLocal")
local common = require('scripts.quest_guider_lite.common')
local tracking = require("scripts.quest_guider_lite.trackingLocal")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local getObject = require("scripts.quest_guider_lite.core.getObject")
local realTimer = require("scripts.quest_guider_lite.realTimer")
local dialogueTime = require("scripts.quest_guider_lite.dialogueTime")

local trackingElementLib = require("scripts.quest_guider_lite.ui.customJournal.objectTrackingElem")

local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")
local interval = require("scripts.quest_guider_lite.ui.interval")
local checkBox = require("scripts.quest_guider_lite.ui.checkBox")
local button = require("scripts.quest_guider_lite.ui.button")
local tooltip = require("scripts.quest_guider_lite.ui.tooltip")

local dialogueIDTooltipLib = require("scripts.quest_guider_lite.ui.dialogueIdTooltip")

local l10n = core.l10n(common.l10nKey)

local playerName = "PCName"
local playerRace = "PCRace"
local playerClass = "PCClass"
pcall(function ()
    local obj = getObject("player")
    playerName = obj.name
    playerRace = obj.race
    playerClass = obj.class
end)


local allowLoadTimeWarning = true


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

function questBoxMeta.getScrollBox(self)
    return self:getLayout()
end

---@return questGuider.ui.scrollBox
function questBoxMeta.getScrollBoxMeta(self)
    return self:getScrollBox().userData.scrollBoxMeta
end

function questBoxMeta.getButtonWidget(self)
    return self:getScrollBoxMeta():getContent()[1].content[3]
end

function questBoxMeta.getButtonFlex(self)
    return self:getButtonWidget().content[2]
end

function questBoxMeta.getHeader(self)
    return self:getScrollBoxMeta():getContent()[1]
end

function questBoxMeta.addTrackButtons(self, showRemoveBtn)
    local function hasTrackedObjects(default)
        local has = default
        for _, info in pairs(self.dialogueInfo) do
            has = has or tracking.isDialogueHasTracked{diaId = info.diaId}
            if has then break end
        end

        return has
    end

    local function updateTrackButton(hasTracked)
        self:getButtonFlex().content = ui.content{}

        if hasTracked then
            self:getButtonFlex().content:add(interval(self.params.fontSize, 0))
            self:getButtonFlex().content:add(button{
                text = l10n("removeTracking"),
                textSize = self.params.fontSize * 0.8,
                visible = tracking.initialized,
                parentScrollBoxUserData = self:getScrollBox().userData,
                event = self.untrackObjectsFunc,
                updateFunc = function ()
                    self.params.updateFunc()
                end
            })
        else
            self:getButtonFlex().content:add(button{
                text = l10n("trackObjects"),
                textSize = self.params.fontSize * 0.8,
                visible = tracking.initialized,
                parentScrollBoxUserData = self:getScrollBox().userData,
                event = self.trackObjectsFunc,
                updateFunc = function ()
                    self.params.updateFunc()
                end
            })
        end
    end

    if tracking.initialized then
        self.trackObjectsFunc = function ()
            self:addTrackButtons(true)

            for _, info in pairs(self.questInfo) do
                tracking.trackQuest(info.diaId, info.diaIndex, {
                        force = self.params.isQuestList,
                        useCurrentIndex = self.params.isQuestList,
                    }
                )
            end
            async:newUnsavableSimulationTimer(0.1, function ()
                tracking.updateTemporaryMarkers()
            end)

            realTimer.newTimer(0.75, function ()
                trackingElementLib.updateObjectTrackingElements(self.content)
                updateTrackButton(hasTrackedObjects(false))
                self:update()
            end)
        end
    else
        self.trackObjectsFunc = nil
    end

    local hasTracked = hasTrackedObjects(showRemoveBtn)

    if hasTracked then
        self.untrackObjectsFunc = function ()
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
            trackingElementLib.updateObjectTrackingElements(self.content)
            playerRef:sendEvent("QGL:updateQuestMenu", {})
        end
    else
        self.untrackObjectsFunc = nil
    end

    self.toggleTrackObjectsFunc = function ()
        local hasTracked = hasTrackedObjects(false)

        if hasTracked then
            if self.untrackObjectsFunc then
                self.untrackObjectsFunc()
            end
        else
            if self.trackObjectsFunc then
                self.trackObjectsFunc()
            end
        end
    end

    updateTrackButton(hasTracked)
end


---@param data table<string, questGuider.quest.getRequirementPositionData.returnData>
---@param questDiaLinks table<string, table<string, any>> by objectId, by quest dialogue id
function questBoxMeta:addQuestObjectsLayout(data, questDiaLinks)
    if #self.content < 2 or self.params.questName == "" then return end

    local ss, layIndex = pcall(function ()
        return self.content:indexOf("TR_Objects_Flex")
    end)
    if layIndex then
        uiUtils.removeFromContent(self.content, layIndex)
    end

    local objectsFlexContent = ui.content{}
    local objectsContainerLayout = ui.content{}

    local objectsBtn = button{
        text = l10n("questObjectsBtn"),
        textSize = self.params.fontSize * 0.8,
        visible = true,
        anchor = util.vector2(0.5, 0.5),
        parentScrollBoxUserData = self:getScrollBox().userData,
        relativePosition = util.vector2(0.5, 0.5),
        userData = {
            opened = false,
        },
        event = function (layout)
            layout.userData.opened = not layout.userData.opened
            if layout.userData.opened then
                objectsContainerLayout.content[2].content = objectsFlexContent
            else
                objectsContainerLayout.content[2].content = ui.content{}
            end

            self:getScrollBoxMeta():calcContentHeight()
            self:getScrollBoxMeta():updateContent()
        end,
        updateFunc = function ()
            self.params.updateFunc()
        end
    }

    trackingElementLib.addObjectPositionInfo(objectsFlexContent, {
        objPoss = data,
        questDiaLinks = questDiaLinks,
        width = self.params.size.x,
        fontSize = config.data.ui.fontSize,
        questName = self.params.questName,
        addMissingTrackingObjects = true,
        parentContent = self.content,
        parentScrollBoxUserData = self:getScrollBox().userData,
        updateFunc = self.update,
    })


    objectsContainerLayout = {
        type = ui.TYPE.Flex,
        name = "TR_Objects_Flex",
        userData = {
            objectsFlexContent = objectsFlexContent,
        },
        content = ui.content{
            {
                props = {
                    size = util.vector2(self.params.size.x, config.data.ui.fontSize * 2),
                },
                content = ui.content{
                    objectsBtn,
                },
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                },
                content = ui.content{},
            }
        }
    }

    self.content:insert(3, objectsContainerLayout)
end


---@param params questGuider.ui.questBox.params
function questBoxMeta._fillJournal(self, content, params)

    self.dialogueInfo = {}
    ---@type table<string, boolean>
    local addedDiaIds = {}

    local playerQuestDataList, topicTexts
    if self.params.isQuestList then
        playerQuestDataList, topicTexts = playerQuests.getQuestStorageData(params.questName or "")
    else
        playerQuestDataList, topicTexts = playerQuests.getAndUpdateJournalQuestData(params.questName or "")
    end
    playerQuestDataList = playerQuestDataList and playerQuestDataList.list or params.playerQuestData.list

    local topicData = {}
    for _, topic in pairs(playerQuests.getTopicList() or {}) do
        topicData[topic.id or ""] = {
            topic = topic
        }
    end
    local topicList = tableLib.keys(topicData)
    table.sort(topicList, function (a, b)
        local tmA = dialogueTime.getTimestamp(a)
        local tmB = dialogueTime.getTimestamp(b)
        if tmA ~= tmB then
            return tmA > tmB
        end
        return a < b
    end)

    local contentIndex = 2
    local function addElement(i)
        local qInfo = playerQuestDataList[i]
        if not qInfo then goto continue end

        if params.showOnlyFirstDiaEntry and addedDiaIds[qInfo.diaId] then return end

        local text = self.params.hideStageText and "" or nil
        if not text then
            local t, id = playerQuests.getJournalText(qInfo.diaId, qInfo.index)
            if id and topicTexts then
                local tt = topicTexts[id]
                if tt then
                    t = tt
                end
            end
            text = t
        end

        local linkedTexts = {}
        if params.showReqDiaEntryText then
            local primeDiaData = questBase.getQuestDiaPrimeDialogueIds(qInfo.diaId, qInfo.index)
            local checkedInfos = {}
            for _, dt in pairs(primeDiaData or {}) do
                if not checkedInfos[dt.topicId] then
                    local diaInfo = playerQuests.getDialogueInfo(dt.diaId, dt.topicId)
                    if diaInfo then
                        local actorName
                        if dt.actorId then
                            local actor = getObject(dt.actorId)
                            if actor then
                                actorName = actor.name
                            end
                        end
                        actorName = actorName or l10n("dialogueDefaultActorName")

                        local texts = {}
                        if params.showFullReqDiaEntryText then
                            for _, tId in pairs(tableLib.invertIndexes(dt.indexChain or {})) do
                                local dInfo = playerQuests.getDialogueInfo(dt.diaId, tId)
                                if dInfo and diaInfo.text then
                                    table.insert(texts, dInfo.text)
                                end
                            end
                        elseif diaInfo.text then
                            table.insert(texts, diaInfo.text)
                        end

                        if next(texts) then
                            local diaText = table.concat(texts, "\n\n")
                            if not linkedTexts[diaText] then
                                linkedTexts[diaText] = {[actorName] = true}
                            else
                                linkedTexts[diaText][actorName] = true
                            end
                        end
                    end

                    checkedInfos[dt.topicId] = true
                end
            end
        end

        if not text and not next(linkedTexts) then goto continue end

        text = text or ""

        text = stringLib.removeSpecialCharactersFromJournalText(text)
        local actorsStrTags = {}

        local tagCnt = 0
        if next(linkedTexts) then
            local tt = {}
            for t, actors in pairs(linkedTexts) do
                local actorNamesArr = tableLib.keys(actors)
                local tag = string.format("__ACTORNAME%d__", tagCnt)
                tagCnt = tagCnt + 1
                actorsStrTags[tag] = table.concat(actorNamesArr, ", ")
                table.insert(tt, string.format("%s: %s",
                        tag,
                        stringLib.replaceGameTags(
                            stringLib.removeSpecialCharactersFromJournalText(t),
                            {
                                ["PCName"] = playerName,
                                ["PCRace"] = playerRace,
                                ["PCClass"] = playerClass,
                                ["name"] = #actorNamesArr == 1 and actorNamesArr[1] or nil
                            }
                        )
                    )
                )
            end

            text = string.format("%s\n\n\n%s", table.concat(tt, "\n\n"), text or "")
        end

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
            or timeLib.getDateByTime(timeLib.getTimestamp(qInfo))

        local height = uiUtils.getTextHeight(text, params.fontSize, self.scrollBoxContentSize.x, config.data.journal.textHeightMulRecord, 1, true)
        local textElemSize = util.vector2(self.scrollBoxContentSize.x, height)

        local tm = core.getRealTime()
        local topicPoss = config.data.journal.fuzzyTopicMatching and stringLib.findPhrases(text, topicList) or
            stringLib.findPhrasesExact(text, topicList)
        tm = core.getRealTime() - tm

        if tm > 0.2 and config.data.journal.fuzzyTopicMatching and allowLoadTimeWarning then
            self.params.parent:showInfoMessage(l10n("journalTopicLoadingTimeWarning", {setting = l10n("fuzzyTopicMatching")}), 10)
            allowLoadTimeWarning = false
        end

        local linkColor = "#"..config.data.ui.linkColor:asHex()
        local defaultColor = "#"..config.data.ui.defaultColor:asHex()
        text = uiUtils.colorizeFromPhrasePositions(text, topicPoss, linkColor, defaultColor)

        for tag, str in pairs(actorsStrTags) do
            text = text:gsub(tag, string.format("#%s%s#%s",
                config.data.ui.objectColor:asHex(),
                str,
                config.data.ui.defaultColor:asHex()
            ))
        end

        local tooltipContent = dialogueIDTooltipLib.getContentForTooltip{recordInfo = qInfo, fontSize = params.fontSize,
            filter = self.parent.textFilter}

        local element
        local detailsContent = ui.content{}

        local textTopics = {}
        for id, dt in pairs(topicPoss) do
            if topicData[id] then
                local topic = topicData[id].topic
                textTopics[topic.id] = topic
            end
        end

        local topicsText
        local compactTopicText
        local function getTopicsText(count, compact)
            if not compact and topicsText ~= nil then return topicsText end
            if compact and compactTopicText ~= nil then return compactTopicText end

            local t = ""
            local firstLine = true
            for _, topic in pairs(textTopics) do
                local topicText = string.format("%s#%s%s#%s:%s",
                    firstLine and "" or "\n\n",
                    config.data.ui.linkColor:asHex(),
                    topic.name,
                    config.data.ui.defaultColor:asHex(),
                    compact and "" or "\n"
                )
                firstLine = false

                local entryCount = #topic.entries
                local startIndex = math.max(1, entryCount - count + 1)
                local endIndex = entryCount

                if startIndex ~= 1 then
                    topicText = string.format("%s\n%s",
                        topicText,
                        l10n("ellipsis")
                    )
                end

                local first = true
                for j = startIndex, endIndex do
                    local entry = topic.entries[j]
                    local entryText = stringLib.removeSpecialCharactersFromJournalText(entry.text) or ""
                    topicText = string.format("%s%s\t#%s%s#%s: \"%s\"",
                        topicText,
                        first and "\n" or "\n\n",
                        config.data.ui.objectColor:asHex(),
                        entry.actor,
                        config.data.ui.defaultColor:asHex(),
                        entryText
                    )
                    first = false
                end

                t = t..topicText
            end

            if not compact then
                topicsText = t ~= "" and t or false
            else
                compactTopicText = t ~= "" and t or false
            end

            return compact and compactTopicText or topicsText
        end

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
                local t = getTopicsText(config.data.journal.maxTopicEntriesInJournal)
                if t then
                    newText = string.format("%s\n\n\n%s\n", newText, t)
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

        local function toggleTopics()
            changeEntryBlockText(true)
            local sb = self:getScrollBoxMeta()
            sb:calcContentHeight()
            sb:updateContent()
        end

        if not self.toggleTopTopicsFunc then
            self.toggleTopTopicsFunc = function ()
                if not (tracking.initialized and next(topicPoss)
                        and config.data.journal.maxTopicEntriesInJournal > 0) then return end

                toggleTopics()
                self:update()
            end
        end

        local topicsTooltipTimer
        local topicsBtnTooltipContent
        local topicsBtn = button{
            text = l10n("topics"),
            textSize = self.params.fontSize * 0.8,
            visible = tracking.initialized and next(topicPoss)
                and config.data.journal.maxTopicEntriesInJournal > 0 and true or false,
            anchor = util.vector2(0.5, 0.5),
            parentScrollBoxUserData = self:getScrollBox().userData,
            focusLoss = function (layout)
                topicsBtnTooltipContent = nil
                layout.userData.params.tooltipContent = nil
                if topicsTooltipTimer then
                    topicsTooltipTimer()
                    topicsTooltipTimer = nil
                end
            end,
            mouseMove = function (layout)
                if topicsBtnTooltipContent ~= nil then return end

                if not topicsTooltipTimer then
                    topicsTooltipTimer = realTimer.newTimer(config.data.ui.tooltipDelay, function ()
                        local t = getTopicsText(1, true)
                        if not t then topicsBtnTooltipContent = false end

                        local screenSize = uiUtils.getScaledScreenSize()
                        local w = math.floor(screenSize.x * 0.5)
                        local paddingW = math.floor(screenSize.x * 0.025)
                        local paddingH = math.floor(screenSize.y * 0.025)

                        topicsBtnTooltipContent = ui.content{
                            {
                                type = ui.TYPE.Flex,
                                props = {
                                    autoSize = true,
                                    horizontal = false,
                                },
                                content = ui.content{
                                    interval(0, paddingH),
                                    {
                                        type = ui.TYPE.Flex,
                                        props = {
                                            autoSize = true,
                                            horizontal = true,
                                        },
                                        content = ui.content{
                                            interval(paddingW, 0),
                                            {
                                                type = ui.TYPE.TextEdit,
                                                props = {
                                                    text = t,
                                                    textColor = config.data.ui.defaultColor,
                                                    size = util.vector2(w, 0),
                                                    textSize = config.data.ui.fontSize,
                                                    multiline = true,
                                                    wordWrap = true,
                                                    readOnly = true,
                                                    autoSize = true,
                                                    textAlignH = ui.ALIGNMENT.Center,
                                                }
                                            },
                                            interval(paddingW, 0),
                                        }
                                    },
                                    interval(0, paddingH),
                                }
                            },
                        }

                        layout.userData.params.tooltipContent = topicsBtnTooltipContent

                        ---@type questGuider.ui.buttonMeta
                        local btnMeta = layout.userData.meta
                        btnMeta:triggerTooltip()
                    end)
                end
            end,
            event = function (layout)
                toggleTopics()
            end,
            updateFunc = function ()
                self.params.updateFunc()
            end
        }

        local detailsBtn = button{
            text = l10n("stageDetailsBtn"),
            textSize = self.params.fontSize * 0.8,
            visible = false,
            anchor = util.vector2(0.5, 0.5),
            parentScrollBoxUserData = self:getScrollBox().userData,
            event = function (layout)
                local container = element.content["TR_Details_Flex"]
                container.userData.opened = not container.userData.opened
                if container.userData.opened then
                    container.content = detailsContent
                else
                    container.content = ui.content{}
                end

                self:getScrollBoxMeta():calcContentHeight()
                self:getScrollBoxMeta():updateContent()
            end,
            updateFunc = function ()
                self.params.updateFunc()
            end
        }

        element = {
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
                horizontal = false,
            },
            userData = {
                contentIndex = contentIndex,
                info = qInfo,
                topicData = topicPoss,
                detailsContent = detailsContent,
                detailsBtn = detailsBtn,
                isQuestList = params.isQuestList,
            },
            content = ui.content {
                interval(0, params.fontSize),
                {
                    type = ui.TYPE.Widget,
                    props = {
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
                                topicData = topicPoss,
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
                        {
                            type = ui.TYPE.Flex,
                            props = {
                                horizontal = true,
                                anchor = util.vector2(1, 0.5),
                                position = util.vector2(textElemSize.x - config.data.ui.scrollArrowSize - 8, params.fontSize * 1.25 * 0.5),
                                arrange = ui.ALIGNMENT.Center,
                                align = ui.ALIGNMENT.Center,
                            },
                            content = ui.content{
                                detailsBtn,
                                interval(config.data.ui.fontSize, 0),
                                topicsBtn,
                            }
                        },
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
                            type = ui.TYPE.Text,
                            userData = {
                                defaultTextColor = config.data.ui.defaultColor,
                                topicData = topicPoss,
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
                        },
                    }
                },
                {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = false,
                    },
                    userData = {
                        opened = false,
                    },
                    name = "TR_Details_Flex",
                    content = ui.content{}
                },
            }
        }

        content:add(element)

        contentIndex = contentIndex + 1

        ::continue::
    end

    if self.params.isQuestList then
        for i = 1, #playerQuestDataList do
            if params.showOnlyMainDia then
                local qInfo = playerQuestDataList[i]
                if not qInfo then goto continue end

                local mainDias = questBase.getQuestMainDialogueIdsMap(qInfo.diaId)
                if mainDias[qInfo.diaId] then
                    addElement(i)
                end
            else
                addElement(i)
            end

            ::continue::
        end
    else
        for i = #playerQuestDataList, 1, -1 do
            addElement(i)
        end
    end

    -- add missing dialogues if they have tracked objects
    for i, dt in pairs(playerQuestDataList) do
        local id = dt.diaId..tostring(dt.index)
        if not self.dialogueInfo[id] and tracking.isDialogueHasTracked{diaId = dt.diaId, index = dt.index} then
            self.dialogueInfo[id] = {
                diaId = dt.diaId,
                index = dt.index,
                contentIndex = 1000 + i, -- use a nonexistent index to filter these entries later
            }
        end
    end

    local sb = self:getScrollBoxMeta()
    sb:calcContentHeight()
    sb:updateContent()
end


function questBoxMeta:updateColors()

    local scrBox = self:getScrollBox()
    if not scrBox then return end

    ---@type questGuider.ui.scrollBox
    local scrollBoxElem = self:getScrollBox().userData.scrollBoxMeta
    local mainFlex = scrollBoxElem:getMainFlex()

    local header = mainFlex.content[1]
    if not header or not header.content or not header.content[1] then return end

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
        local sb = self:getScrollBoxMeta()
        sb:calcContentHeight()
        sb:updateContent()
    end
end


---@param state boolean
function questBoxMeta:setTrackingDisabledState(state)
    local qData = playerQuests.getQuestDataByName(self.params.questName)
    if qData then
        local changed = false
        for diaId, _ in pairs(qData.records or {}) do
            changed = tracking.setDisableMarkerState{questId = diaId, value = state} or changed
        end
        if changed then
            tracking.updateTemporaryMarkers()
            tracking.updateMarkers()
        end
    end
end


---@class questGuider.ui.questBox.params
---@field size any
---@field fontSize integer
---@field questName string,
---@field playerQuestData questGuider.playerQuest.storageQuestData
---@field isQuestList boolean?
---@field hideStageText boolean?
---@field showReqDiaEntryText boolean?
---@field showFullReqDiaEntryText boolean?
---@field showReqsForAll boolean?
---@field showOnlyMainDia boolean?
---@field showOnlyFirstDiaEntry boolean?
---@field updateFunc function
---@field parent questGuider.ui.customJournal
---@field userData table


---@param params questGuider.ui.questBox.params
function this.create(params)

    ---@class questGuider.ui.questBoxMeta
    local meta = setmetatable({}, questBoxMeta)

    meta.requestId = nil
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
        autoOptimize = true,
        userData = userData
    }

    local tooltipContent = dialogueIDTooltipLib.getContentForTooltip{meta = meta, filter = meta.parent.textFilter}

    local headerSize = util.vector2(meta.scrollBoxContentSize.x, params.fontSize * 4)
    local checkBoxBlockSize = util.vector2(meta.scrollBoxContentSize.x, params.fontSize * 2)
    local header

    local pinnedCB = checkBox{
        updateFunc = function ()
            params.updateFunc()
        end,
        checked = params.playerQuestData.pinned,
        text = l10n("pinned"),
        textSize = params.fontSize or 18,
        visible = not params.isQuestList,
        getScrollBoxMeta = function ()
            return meta:getScrollBoxMeta()
        end,
        event = function (checked, layout)
            params.playerQuestData.pinned = checked
            local selectedQuest = meta.parent:getQuestListSelectedFladValue()
            meta.parent:fillQuestsContent()
            meta.parent:selectQuest(selectedQuest)
        end
    }

    local finishedCB = checkBox{
        updateFunc = function ()
            params.updateFunc()
        end,
        checked = params.playerQuestData.finished,
        text = l10n("finished"),
        textSize = params.fontSize or 18,
        visible = not params.isQuestList,
        getScrollBoxMeta = function ()
            return meta:getScrollBoxMeta()
        end,
        event = function (checked, layout)
            params.playerQuestData.finished = checked
            meta:setTrackingDisabledState(checked)
            local selectedQuest = meta.parent:getQuestListSelectedFladValue()
            meta.parent:fillQuestsContent()
            meta.parent:selectQuest(selectedQuest)
        end
    }

    local hiddenCB = checkBox{
        updateFunc = function ()
            params.updateFunc()
        end,
        checked = params.playerQuestData.disabled,
        text = l10n("hidden"),
        textSize = params.fontSize or 18,
        visible = true,
        getScrollBoxMeta = function ()
            return meta:getScrollBoxMeta()
        end,
        event = function (checked, layout)
            params.playerQuestData.disabled = checked
            meta:setTrackingDisabledState(checked)
            local selectedQuest = meta.parent:getQuestListSelectedFladValue()
            meta.parent:fillQuestsContent()
            meta.parent:selectQuest(selectedQuest)
        end
    }

    meta.finishedCheckboxLayot = finishedCB
    meta.hiddenCheckboxLayout = hiddenCB
    meta.pinnedCheckboxLayout = pinnedCB

    header = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = headerSize
        },
        content = ui.content {
            {
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
                    size = checkBoxBlockSize,
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = true,
                            horizontal = true,
                            anchor = util.vector2(0, 0.5),
                            position = util.vector2(0, checkBoxBlockSize.y / 2),
                        },
                        content = ui.content{
                            pinnedCB,
                            interval(config.data.ui.fontSize, 0),
                            finishedCB,
                            interval(config.data.ui.fontSize, 0),
                            hiddenCB,
                        }
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

    meta.content = journalContent

    meta:_fillJournal(meta.content, params)


    meta.toggleQuestObjectsBtn = function (self)
        local ss, btnLayout = pcall(function ()
            return meta.content["TR_Objects_Flex"].content[1].content[1]
        end)
        if not ss or not btnLayout then return end

        ---@type questGuider.ui.buttonMeta
        local btnMeta = btnLayout.userData.meta
        if btnMeta.params.event then
            btnMeta.params.event(btnLayout)
        end
    end

    return journalEntries
end


return this