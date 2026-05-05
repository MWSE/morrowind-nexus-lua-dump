local playerRef = require("openmw.self")
local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local vfs = require('openmw.vfs')
local templates = require('openmw.interfaces').MWUI.templates
local customTemplates = require("scripts.quest_guider_lite.ui.templates")

local config = require("scripts.quest_guider_lite.configLib")
local commonData = require("scripts.quest_guider_lite.common")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local tracking = require("scripts.quest_guider_lite.trackingLocal")
local localStorage = require("scripts.quest_guider_lite.storage.localStorage")
local menuHandler = require("scripts.quest_guider_lite.menuHandler")

local timeLib = require("scripts.quest_guider_lite.timeLocal")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local log = require("scripts.quest_guider_lite.utils.log")

local button = require("scripts.quest_guider_lite.ui.button")
local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")
local interval = require("scripts.quest_guider_lite.ui.interval")
local checkBox = require("scripts.quest_guider_lite.ui.checkBox")

local questBox = require("scripts.quest_guider_lite.ui.customJournal.questBox")

local l10n = core.l10n(commonData.l10nKey)

local COLOR_HEADER = util.color.rgb(223 / 255, 201 / 255, 159 / 255)
local COLOR_GOLD = util.color.rgb(0.79, 0.65, 0.38)
local COLOR_GOLD_BRIGHT = util.color.rgb(0.9, 0.78, 0.5)
local COLOR_GOLD_DIM = util.color.rgb(0.55, 0.45, 0.25)
local COLOR_GRAY = util.color.rgb(0.45, 0.45, 0.45)
local COLOR_HIGHLIGHT = util.color.rgb(0.7, 0.55, 0.2)
local COLOR_DIVIDER = util.color.rgb(0.4, 0.33, 0.18)
local COLOR_BG_DARK = util.color.rgb(0.04, 0.03, 0.02)
local COLOR_WHITE = util.color.rgb(1, 1, 1)

local borderTexTop = ui.texture{ path = "textures/menu_thin_border_top.dds" }
local borderTexLeft = ui.texture{ path = "textures/menu_thin_border_left.dds" }
local borderTexThickTop = ui.texture{ path = "textures/menu_thick_border_top.dds" }


---@class questGuider.ui.customJournal
local journalMeta = {}
journalMeta.__index = journalMeta

journalMeta.menu = nil


journalMeta.getQuestList = function (self)
    return self._questListBox
end

journalMeta.getQuestMain = function (self)
    return self._questMain
end

journalMeta.getQuestScrollBox = function (self)
    return self._detailWrapper.content[2]
end

journalMeta.getQuestListCheckBoxFlex = function (self)
    return self._checkBoxFlex
end

journalMeta.getQuestListFinishedCheckBox = function (self)
    return self._finishedCheckBox
end

journalMeta.getQuestListHiddenCheckBox = function (self)
    return self._hiddenCheckBox
end

journalMeta.resetQuestListColors = function (self)
    local questList = self:getQuestList()
    ---@type questGuider.ui.scrollBox
    local sbMeta = questList.userData.scrollBoxMeta

    for _, elem in ipairs(sbMeta:getContent()) do
        if elem.userData and elem.userData.questName then
            if elem.userData.highlightBg then
                elem.userData.highlightBg.props.alpha = 0
            end
            if elem.userData.selectionBar then
                elem.userData.selectionBar.props.alpha = 0
            end
        end
    end
end

journalMeta.updateQuestListTrackedColors = function (self)
    local questList = self:getQuestList()
    ---@type questGuider.ui.scrollBox
    local sbMeta = questList.userData.scrollBoxMeta

    for _, elem in ipairs(sbMeta:getContent()) do
        if elem.userData and elem.userData.playerQuestData and elem.userData.questName then
            self:_updateEntryVisuals(elem)
            if elem.userData.flagsFlex then
                elem.userData.flagsFlex.content = ui.content{}
                self:_addFlags(elem.userData.flagsFlex.content, elem.userData.playerQuestData)
            end
        end
    end
end

journalMeta.setQuestListSelectedFlad = function (self, value)
    self:getQuestList().userData.selected = value
end

journalMeta.getQuestListSelectedFladValue = function (self)
    return self:getQuestList().userData.selected
end

journalMeta.resetQuestListSelection = function (self)
    self:resetQuestListColors()
    self:setQuestListSelectedFlad(nil)
end

journalMeta.clearQuestInfo = function (self)
    local qInfoScrollBox = self:getQuestScrollBox()
    if not qInfoScrollBox then return end
    qInfoScrollBox.name = nil
    ---@type questGuider.ui.scrollBox
    local sBoxMeta = qInfoScrollBox.userData.scrollBoxMeta
    if not sBoxMeta then return end
    sBoxMeta:clearContent()
end


journalMeta._isQuestTracked = function (self, storageData)
    if not storageData then return false end
    local qData = playerQuests.getQuestDataByName(storageData.name)
    if not qData then return false end
    for diaId, _ in pairs(qData.records or {}) do
        if tracking.isDialogueHasTracked{diaId = diaId} then
            return true
        end
    end
    return false
end


journalMeta._updateEntryVisuals = function (self, elem)
    if not elem or not elem.userData then return end
    local isTracked = self:_isQuestTracked(elem.userData.playerQuestData)
    local isFinished = elem.userData.playerQuestData.finished or elem.userData.playerQuestData.disabled

    if elem.userData.indicatorElem then
        if isTracked then
            elem.userData.indicatorElem.props.text = "◆"
            elem.userData.indicatorElem.props.textColor = COLOR_GOLD_BRIGHT
        elseif isFinished then
            elem.userData.indicatorElem.props.text = "◇"
            elem.userData.indicatorElem.props.textColor = COLOR_GRAY
        else
            elem.userData.indicatorElem.props.text = "◇"
            elem.userData.indicatorElem.props.textColor = COLOR_GOLD_DIM
        end
    end

    if elem.userData.nameElem then
        if isFinished then
            elem.userData.nameElem.props.textColor = COLOR_GRAY
        elseif isTracked then
            elem.userData.nameElem.props.textColor = COLOR_GOLD_BRIGHT
        else
            elem.userData.nameElem.props.textColor = COLOR_GOLD
        end
    end
end


journalMeta.selectQuest = function (self, qName)
    if not self.params.isQuestList then
        localStorage.data.lastSelectedQuest = qName
    end

    if qName == nil then
        self:resetQuestListSelection()
        self:clearQuestInfo()
        return
    end

    ---@type questGuider.ui.scrollBox
    local scrollBoxMeta = self:getQuestList().userData.scrollBoxMeta
    local qListContent = scrollBoxMeta:getContent()

    local qMainLay = self:getQuestMain()

    local succ, selectedLayout = pcall(function() return qListContent[qName] end)
    if not succ or not selectedLayout then
        self:clearQuestInfo()
        self:setQuestListSelectedFlad(nil)
        return
    end

    local function moveScroll()
        local indS, index = pcall(function() return qListContent:indexOf(qName) end)
        if not indS then return end

        local scrollPos = scrollBoxMeta:getScrollPosition()
        local scrollHeight = scrollBoxMeta.params.size.y
        local elemHeight = self._entryHeight
        local height = (index - 1) * elemHeight
        if scrollPos > height then
            scrollBoxMeta:setScrollPosition(math.max(0, height))
        elseif scrollPos + scrollHeight < (height + elemHeight) then
            scrollBoxMeta:setScrollPosition(height - scrollHeight + elemHeight)
        end
    end

    local function applyHighlight()
        if selectedLayout.userData then
            if selectedLayout.userData.highlightBg then
                selectedLayout.userData.highlightBg.props.alpha = 0.18
            end
            if selectedLayout.userData.selectionBar then
                selectedLayout.userData.selectionBar.props.alpha = 1
            end
        end
    end

    local sb = self:getQuestScrollBox()
    if sb and sb.name == qName and self.textFilter == sb.userData.lastFilter then
        applyHighlight()
        return
    end

    self._detailWrapper.content[2] = questBox.create{
        parent = self,
        fontSize = self.params.fontSize or 18,
        playerQuestData = selectedLayout.userData.playerQuestData,
        isQuestList = self.params.isQuestList,
        showReqsForAll = self.params.showReqsForAll,
        hideStageText = self.params.hideStageText,
        showOnlyFirst = self.params.showOnlyFirst,
        questName = selectedLayout.userData.questName,
        size = self.questInfoPanelSize,
        userData = {
            lastFilter = self.textFilter
        },
        updateFunc = function ()
            self:update()
        end,
    }

    self:resetQuestListSelection()
    self:setQuestListSelectedFlad(qName)
    applyHighlight()
    moveScroll()

    self:update()

    ---@type questGuider.ui.questBoxMeta
    local questBoxMeta = self:getQuestScrollBox().userData.questBoxMeta
    core.sendGlobalEvent("QGL:fillQuestBoxQuestInfo", {
        data = questBoxMeta.dialogueInfo,
        menuId = self.params.menuId,
        useCurrentIndex = self.params.isQuestList,
        player = playerRef.object,
    })
end

journalMeta.update = function(self)
    if not self.menu.layout then return end
    self.menu:update()
end


function journalMeta.updateNextStageBlocks(self)
    ---@type questGuider.ui.questBoxMeta
    local qBox = self:getQuestScrollBox().userData.questBoxMeta
    if not qBox then return end
    ---@type questGuider.ui.scrollBox
    local scrlBox = qBox:getScrollBox().userData.scrollBoxMeta

    for _, scrollContentElement in pairs(scrlBox:getContent()) do
        for _, nextStagesBlock in pairs(scrollContentElement.content or {}) do
            if not nextStagesBlock.userData or not nextStagesBlock.userData.meta
                    or nextStagesBlock.userData.meta.type ~= commonData.elementMetatableTypes.nextStages then
                goto continue
            end
            nextStagesBlock.userData.meta:updateObjectElements()
            ::continue::
        end
    end
end


---@param storageData questGuider.playerQuest.storageQuestData
---@param text string
---@return boolean
local function hasText(questData, text)
    text = stringLib.utf8_lower(text)
    if stringLib.utf8_lower(questData.name):find(text, 1, true) then
        return true
    end
    for _, dt in pairs(questData.list) do
        if dt.diaId:find(text, 1, true) then return true end
        local journalText = stringLib.removeSpecialCharactersFromJournalText(playerQuests.getJournalText(dt.diaId, dt.index))
        if journalText and stringLib.utf8_lower(journalText):find(text, 1, true) then
            return true
        end
    end
    return false
end


function journalMeta._addFlags(self, content, storageData)
    if not commonData.whiteTexture then return end
    local objects = {}
    for diaId, _ in pairs((playerQuests.getQuestDataByName(storageData.name) or {}).records or {}) do
        tableLib.copy(tracking.getDiaTrackedObjects(diaId) or {}, objects)
    end
    if not next(objects) then return end

    if not config.data.journal.trackedColorMarks then
        content:add{
            type = ui.TYPE.Image,
            props = {
                resource = commonData.whiteTexture,
                size = util.vector2(self.params.fontSize / 3, self.params.fontSize),
                color = config.data.ui.defaultColor,
            },
        }
    else
        local maxMarks = config.data.journal.maxColorMarks
        for objectId, _ in pairs(objects) do
            local objData = tracking.getTrackedObjectData(objectId)
            if objData and objData.color then
                if maxMarks > 0 then
                    maxMarks = maxMarks - 1
                else
                    break
                end
                content:add{
                    type = ui.TYPE.Image,
                    props = {
                        resource = commonData.whiteTexture,
                        size = util.vector2(self.params.fontSize / 4, self.params.fontSize),
                        color = util.color.rgb(objData.color[1], objData.color[2], objData.color[3]),
                    },
                }
            end
        end
    end
end


local function _makeSectionHeader(text, fontSize, width, entryHeight)
    local lineWidth = (width - fontSize * #text * 0.6 - 24) / 2
    if lineWidth < 10 then lineWidth = 10 end

    return {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = util.vector2(width, entryHeight),
        },
        userData = { isSectionHeader = true, height = entryHeight },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = borderTexTop,
                    tileH = true,
                    size = util.vector2(lineWidth, 2),
                    position = util.vector2(8, entryHeight * 0.5),
                },
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = borderTexTop,
                    tileH = true,
                    size = util.vector2(lineWidth, 2),
                    position = util.vector2(width - lineWidth - 8, entryHeight * 0.5),
                },
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    size = util.vector2(width, entryHeight),
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        props = {
                            text = text,
                            textSize = fontSize * 0.7,
                            textColor = COLOR_GOLD_DIM,
                            autoSize = true,
                        },
                    },
                },
            },
        },
    }
end


function journalMeta.fillQuestsContent(self)
    local params = self.params

    local qList = self:getQuestList()
    ---@type questGuider.ui.scrollBox
    local sBoxMeta = qList.userData.scrollBoxMeta
    sBoxMeta:clearContent()

    local content = sBoxMeta:getContent()

    local questData = self.storageTypeQuestData or playerQuests.getStorageData().questData

    local function compareFunc(a, b)
        local finishedSubVal = 200000000000
        local disabledSubVal = 100000000000
        local pinnedAddVal = 200000000000
        local aVal = timeLib.getTimestamp(a)
        aVal = a.pinned and aVal + pinnedAddVal or
            a.finished and aVal - finishedSubVal
            or a.disabled and aVal - disabledSubVal or aVal
        local bVal = timeLib.getTimestamp(b)
        bVal = b.pinned and bVal + pinnedAddVal or
            b.finished and bVal - finishedSubVal
            or b.disabled and bVal - disabledSubVal or bVal
        return aVal > bVal
    end

    local sortedData
    if params.isQuestList then
        sortedData = tableLib.values(questData, function (a, b)
            return (a.name or "") < (b.name or "")
        end)
    else
        sortedData = tableLib.values(questData, function (a, b)
            return compareFunc(a, b)
        end)
    end

    local showFinished = self._finishedCheckBox.userData.checked
    local showHidden = self._hiddenCheckBox.userData.checked

    local trackedQuests = {}
    local activeQuests = {}
    local completedQuests = {}

    for _, dt in pairs(sortedData) do
        if dt.disabled and not showHidden then goto continue end
        if dt.finished and not showFinished then goto continue end
        if params.isQuestList and (not dt.name or dt.name == "") then goto continue end
        if self.textFilter ~= "" and not hasText(dt, self.textFilter) then goto continue end

        if dt.finished or dt.disabled then
            table.insert(completedQuests, dt)
        elseif self:_isQuestTracked(dt) then
            table.insert(trackedQuests, dt)
        else
            table.insert(activeQuests, dt)
        end
        ::continue::
    end

    local listWidth = self._questListSize.x - 2
    local entryH = self._entryHeight
    local fontSize = params.fontSize or 18

    local function addQuestEntry(dt)
        local qName = dt.name or ""
        local qNameText = qName == "" and l10n("miscellaneous") or qName or "???"

        local isTracked = self:_isQuestTracked(dt)
        local isFinished = dt.finished or dt.disabled

        local nameColor = isFinished and COLOR_GRAY or isTracked and COLOR_GOLD_BRIGHT or COLOR_GOLD
        local indicatorText = isTracked and "◆" or "◇"
        local indicatorColor = isTracked and COLOR_GOLD_BRIGHT or isFinished and COLOR_GRAY or COLOR_GOLD_DIM

        local highlightBg = {
            type = ui.TYPE.Image,
            props = {
                resource = uiUtils.whiteTexture,
                relativeSize = util.vector2(1, 1),
                color = COLOR_HIGHLIGHT,
                alpha = 0,
            },
        }

        local selectionBar = {
            type = ui.TYPE.Image,
            props = {
                resource = uiUtils.whiteTexture,
                size = util.vector2(3, entryH - 6),
                position = util.vector2(2, 3),
                color = COLOR_GOLD_BRIGHT,
                alpha = 0,
            },
        }

        local indicatorElem = {
            type = ui.TYPE.Text,
            props = {
                text = indicatorText,
                textSize = fontSize,
                textColor = indicatorColor,
                autoSize = true,
                position = util.vector2(14, (entryH - fontSize) * 0.5),
            },
        }

        local nameText = qNameText
        if self.textFilter ~= "" then
            nameText = uiUtils.colorize(qNameText, self.textFilter,
                "#" .. COLOR_GOLD_BRIGHT:asHex(), "#" .. nameColor:asHex())
        end

        local nameElem = {
            template = templates.textNormal,
            type = ui.TYPE.Text,
            props = {
                text = nameText,
                textSize = fontSize,
                textColor = nameColor,
                autoSize = true,
                position = util.vector2(14 + fontSize * 1.5, (entryH - fontSize) * 0.5),
                multiline = false,
                wordWrap = false,
            },
        }

        local flagsFlex = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                autoSize = true,
                anchor = util.vector2(1, 0.5),
                position = util.vector2(listWidth - 24, entryH * 0.5),
            },
            content = ui.content{}
        }
        self:_addFlags(flagsFlex.content, dt)

        local bottomLine = {
            type = ui.TYPE.Image,
            props = {
                resource = uiUtils.whiteTexture,
                size = util.vector2(listWidth * 0.9, 1),
                position = util.vector2(listWidth * 0.05, entryH - 1),
                color = COLOR_DIVIDER,
                alpha = 0.2,
            },
        }

        local qListScrollBoxMeta = sBoxMeta

        local contentData = {
            type = ui.TYPE.Widget,
            props = {
                autoSize = false,
                size = util.vector2(listWidth, entryH),
                propagateEvents = false,
            },
            name = qName,
            userData = {
                height = entryH,
                questName = qName,
                playerQuestData = dt,
                highlightBg = highlightBg,
                selectionBar = selectionBar,
                indicatorElem = indicatorElem,
                nameElem = nameElem,
                flagsFlex = flagsFlex,
            },
            events = {
                mousePress = async:callback(function(e, layout)
                    qListScrollBoxMeta:mousePress(e)
                end),
                focusLoss = async:callback(function(e, layout)
                    qListScrollBoxMeta:focusLoss(e)
                end),
                mouseMove = async:callback(function(e, layout)
                    qListScrollBoxMeta:mouseMove(e)
                end),
                mouseRelease = async:callback(function(e, layout)
                    if e.button ~= 1 then return end
                    qListScrollBoxMeta:mouseRelease(e)
                    if qListScrollBoxMeta.lastMovedDistance < 30 then
                        self:fillQuestsContent()
                        self:selectQuest(qName)
                        self:update()
                    end
                end),
            },
            content = ui.content {
                highlightBg,
                selectionBar,
                indicatorElem,
                nameElem,
                flagsFlex,
                bottomLine,
            }
        }

        content:add(contentData)
    end

    if #trackedQuests > 0 then
        content:add(_makeSectionHeader("TRACKED", fontSize, listWidth, entryH * 0.7))
        for _, dt in ipairs(trackedQuests) do
            addQuestEntry(dt)
        end
    end

    if #activeQuests > 0 then
        content:add(_makeSectionHeader("ACTIVE", fontSize, listWidth, entryH * 0.7))
        for _, dt in ipairs(activeQuests) do
            addQuestEntry(dt)
        end
    end

    if #completedQuests > 0 then
        content:add(_makeSectionHeader("COMPLETED", fontSize, listWidth, entryH * 0.7))
        for _, dt in ipairs(completedQuests) do
            addQuestEntry(dt)
        end
    end

    local totalEntries = #trackedQuests + #activeQuests + #completedQuests
    local sectionCount = (#trackedQuests > 0 and 1 or 0) + (#activeQuests > 0 and 1 or 0) + (#completedQuests > 0 and 1 or 0)
    local height = totalEntries * entryH + sectionCount * (entryH * 0.7)
    sBoxMeta:setContentHeight(height)
    sBoxMeta:updateContent()
    local scrollPos = sBoxMeta:getScrollPosition()
    local scrollElemHeight = sBoxMeta.params.size.y
    if scrollPos > height then
        sBoxMeta:setScrollPosition(math.max(0, height - scrollElemHeight))
    end
end


function journalMeta:updateTrackedButtonVisibility()
    if not self.trackedButtonLayout then return false end
    local newVal = tracking.hasTrackedObjects() and self.params.createTrackingMenuFunc and true or false
    if newVal ~= self.trackedButtonLayout.props.visible then
        self.trackedButtonLayout.props.visible = newVal
        return true
    end
    return false
end


---@param params questGuider.ui.customJournal.params
local function create(params)

    local meta = setmetatable({}, journalMeta)

    local function updateFunc()
        if not meta.menu then return end
        meta:update()
    end

    if not params.size then
        local scaledScreenSize = uiUtils.getScaledScreenSize()
        params.size = util.vector2(scaledScreenSize.x * params.sizeProportional.x, scaledScreenSize.y * params.sizeProportional.y)
    end

    if not params.menuId then
        params.menuId = params.headerName and params.headerName or commonData.journalMenuId
    end

    meta.params = params

    function meta.close()
        if params.onClose then params.onClose() end
        if not meta.menu or not meta.menu.layout then return end
        meta.menu:destroy()
        menuHandler.unregisterMenu(params.menuId)
    end

    meta.textFilter = ""
    meta.storageTypeQuestData = params.questList and playerQuests.generateStorageQuestDataByDiaIdList(params.questList)

    local fontSize = params.fontSize or 18
    meta._entryHeight = fontSize * 2.4

    local questListWidth = math.floor(params.size.x * 0.35)
    local questInfoWidth = params.size.x - questListWidth
    meta._questListSize = util.vector2(questListWidth, params.size.y)

    local questInfoSize = util.vector2(questInfoWidth, params.size.y)
    meta.questInfoPanelSize = questInfoSize

    local questInfoPanel = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = questInfoSize,
        },
        userData = { size = questInfoSize },
        content = ui.content {}
    }

    meta._finishedCheckBox = { userData = { checked = localStorage.data.finishedCheckBox and true or false } }
    meta._hiddenCheckBox = { userData = { checked = localStorage.data.hiddenCheckBox and true or false } }
    meta._checkBoxFlex = { content = { meta._finishedCheckBox, nil, meta._hiddenCheckBox } }

    meta.trackedButtonLayout = {
        template = templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            text = l10n("tracking"),
            visible = tracking.hasTrackedObjects() and params.createTrackingMenuFunc and true or false,
            textSize = fontSize,
            autoSize = true,
            textColor = COLOR_GOLD_DIM,
            propagateEvents = false,
        },
        userData = {},
        events = {
            mouseRelease = async:callback(function(_, layout)
                if params.createTrackingMenuFunc then
                    params.createTrackingMenuFunc()
                end
            end),
        }
    }

    local headerHeight = fontSize * 2.8

    local mainHeader = {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(params.size.x + 6, headerHeight),
        },
        userData = {},
        events = {
            mousePress = async:callback(function(coord, layout)
                layout.userData.contentBackup = meta:getQuestScrollBox()
                meta._detailWrapper.content[2] = questInfoPanel
                meta:update()
                layout.userData.doDrag = true
                local screenSize = uiUtils.getScaledScreenSize()
                layout.userData.lastMousePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)
            end),
            mouseRelease = async:callback(function(_, layout)
                local relativePos = meta.menu.layout.props.relativePosition
                config.setValue("journal.position.x", math.floor(relativePos.x * 10000) / 100)
                config.setValue("journal.position.y", math.floor(relativePos.y * 10000) / 100)
                layout.userData.lastMousePos = nil
                meta._detailWrapper.content[2] = layout.userData.contentBackup
                layout.userData.contentBackup = nil
                meta:update()
            end),
            mouseMove = async:callback(function(coord, layout)
                if not layout.userData.lastMousePos then return end
                local screenSize = uiUtils.getScaledScreenSize()
                local props = meta.menu.layout.props
                local relativePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)
                props.relativePosition = props.relativePosition - (layout.userData.lastMousePos - relativePos)
                meta:update()
                layout.userData.lastMousePos = relativePos
            end),
        },
        content = ui.content{
            {
                type = ui.TYPE.Image,
                props = {
                    resource = uiUtils.whiteTexture,
                    relativeSize = util.vector2(1, 1),
                    color = COLOR_BG_DARK,
                    alpha = 0.9,
                }
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = borderTexThickTop,
                    tileH = true,
                    size = util.vector2(params.size.x + 6, 4),
                    position = util.vector2(0, headerHeight - 4),
                },
            },
            {
                type = ui.TYPE.Text,
                props = {
                    text = params.headerName or "QUESTS",
                    textSize = fontSize * 1.6,
                    autoSize = true,
                    textColor = COLOR_HEADER,
                    textShadow = true,
                    textShadowColor = util.color.rgb(0, 0, 0),
                    position = util.vector2(16, (headerHeight - fontSize * 1.6) * 0.4),
                },
            },
            {
                type = ui.TYPE.Text,
                props = {
                    text = l10n("markersDisabled"),
                    textSize = fontSize * 0.7,
                    autoSize = true,
                    visible = false,
                    textColor = util.color.rgb(0.7, 0.3, 0.3),
                    position = util.vector2(16, headerHeight * 0.72),
                },
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    anchor = util.vector2(1, 0.5),
                    relativePosition = util.vector2(1, 0.5),
                    position = util.vector2(-16, 0),
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    meta.trackedButtonLayout,
                    interval(fontSize * 1.2, 0),
                    {
                        template = templates.textNormal,
                        type = ui.TYPE.Text,
                        props = {
                            text = l10n("topics"),
                            visible = core.API_REVISION >= 93 and params.createTopicMenuFunc and true or false,
                            textSize = fontSize,
                            autoSize = true,
                            textColor = COLOR_GOLD_DIM,
                            propagateEvents = false,
                        },
                        events = {
                            mouseRelease = async:callback(function()
                                if params.createTopicMenuFunc then params.createTopicMenuFunc() end
                            end),
                        }
                    },
                    interval(fontSize * 1.2, 0),
                    {
                        template = templates.textNormal,
                        type = ui.TYPE.Text,
                        props = {
                            text = l10n("close"),
                            textSize = fontSize,
                            autoSize = true,
                            textColor = COLOR_GOLD_DIM,
                            propagateEvents = false,
                        },
                        events = {
                            mouseRelease = async:callback(function()
                                meta:close()
                            end),
                        }
                    },
                }
            },
        },
    }

    meta.updateMarkersDisabledMessage = function(self)
        mainHeader.content[4].props.visible = (tracking.storageData ~= nil) and (tracking.storageData.hideAllMarkers == true) or false
        if self.menu and self.menu.layout then
            self:update()
        end
    end
    meta:updateMarkersDisabledMessage()

    -- Filter toolbar
    local filterBarHeight = fontSize * 2.2
    local finishedCheckBoxUI = checkBox{
        updateFunc = updateFunc,
        checked = localStorage.data.finishedCheckBox and true or false,
        text = l10n("finished"),
        textSize = fontSize * 0.8,
        event = function(checked, layout)
            meta._finishedCheckBox.userData.checked = checked
            localStorage.data.finishedCheckBox = checked
            meta:fillQuestsContent()
            local sel = meta:getQuestListSelectedFladValue()
            if sel then meta:selectQuest(sel) end
            meta:update()
        end
    }

    local hiddenCheckBoxUI = checkBox{
        updateFunc = updateFunc,
        checked = localStorage.data.hiddenCheckBox and true or false,
        text = l10n("hidden"),
        textSize = fontSize * 0.8,
        event = function(checked, layout)
            meta._hiddenCheckBox.userData.checked = checked
            localStorage.data.hiddenCheckBox = checked
            meta:fillQuestsContent()
            local sel = meta:getQuestListSelectedFladValue()
            if sel then meta:selectQuest(sel) end
            meta:update()
        end
    }

    local searchInput
    searchInput = {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = util.vector2(questListWidth * 0.4, fontSize * 1.2),
            anchor = util.vector2(1, 0.5),
            position = util.vector2(questListWidth - 12, filterBarHeight * 0.5),
        },
        content = ui.content{
            {
                template = templates.box,
                props = {},
                content = ui.content{
                    {
                        template = templates.textEditLine,
                        props = {
                            autoSize = false,
                            textSize = fontSize * 0.8,
                            size = util.vector2(questListWidth * 0.4 - 6, fontSize),
                            textColor = COLOR_GOLD,
                        },
                        events = {
                            textChanged = async:callback(function(text, layout)
                                meta.textFilter = text or ""
                                searchInput.content[1].content[1].props.text = meta.textFilter
                                if not params.isQuestList then
                                    localStorage.data.journalSearchText = meta.textFilter
                                end
                            end),
                            keyRelease = async:callback(function(e, layout)
                                if e.code == input.KEY.Enter then
                                    local selectedQuest = meta:getQuestListSelectedFladValue()
                                    meta:fillQuestsContent()
                                    meta:selectQuest(selectedQuest)
                                    searchInput.content[1].content[1].props.text = meta.textFilter
                                    local qBox = meta:getQuestScrollBox()
                                    if qBox and qBox.userData then
                                        local qbMeta = qBox.userData.questBoxMeta
                                        if qbMeta then qbMeta:updateColors() end
                                    end
                                    updateFunc()
                                end
                            end),
                            focusLoss = async:callback(function(e, layout)
                                searchInput.content[1].content[1].props.text = meta.textFilter
                            end),
                        },
                    },
                },
            },
        },
    }

    if not params.isQuestList then
        meta.textFilter = localStorage.data.journalSearchText or ""
        searchInput.content[1].content[1].props.text = meta.textFilter
    end

    local filterBar = {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = util.vector2(questListWidth, filterBarHeight),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    autoSize = true,
                    position = util.vector2(12, (filterBarHeight - fontSize * 0.8) * 0.5),
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    finishedCheckBoxUI,
                    interval(fontSize * 0.8, 0),
                    hiddenCheckBoxUI,
                }
            },
            searchInput,
            {
                type = ui.TYPE.Image,
                props = {
                    resource = borderTexTop,
                    tileH = true,
                    size = util.vector2(questListWidth - 8, 2),
                    position = util.vector2(4, filterBarHeight - 2),
                },
            },
        }
    }

    -- Quest list
    local listPanelHeight = params.size.y - filterBarHeight
    local questListBox = scrollBox{
        updateFunc = updateFunc,
        size = util.vector2(questListWidth - 4, listPanelHeight - 4),
        scrollAmount = meta._entryHeight * 3,
        contentHeight = 0,
        autoOptimize = true,
        content = ui.content{}
    }
    meta._questListBox = questListBox

    local listFocusBorder = {
        type = ui.TYPE.Image,
        props = {
            resource = uiUtils.whiteTexture,
            relativeSize = util.vector2(1, 1),
            color = COLOR_GOLD_DIM,
            alpha = 0.08,
        },
    }

    local detailFocusBorder = {
        type = ui.TYPE.Image,
        props = {
            resource = uiUtils.whiteTexture,
            relativeSize = util.vector2(1, 1),
            color = COLOR_BG_DARK,
            alpha = 0,
        },
    }

    meta._focusPanel = "list"

    meta.setFocusPanel = function(self, panel)
        self._focusPanel = panel
        if panel == "list" then
            listFocusBorder.props.color = COLOR_GOLD_DIM
            listFocusBorder.props.alpha = 0.08
            detailFocusBorder.props.alpha = 0
        else
            listFocusBorder.props.color = COLOR_BG_DARK
            listFocusBorder.props.alpha = 0.3
            detailFocusBorder.props.color = COLOR_GOLD_DIM
            detailFocusBorder.props.alpha = 0.06
        end
        if meta._controllerHintsText then
            self:_updateControllerHints()
        end
        self:update()
    end

    meta._updateControllerHints = function(self)
        if not meta._controllerHintsText then return end
        if self._focusPanel == "list" then
            meta._controllerHintsText.props.text = "[D-Pad] Navigate     [RB] Details     [A] Track     [X] Toggle     [B] Close"
        else
            meta._controllerHintsText.props.text = "[D-Pad] Objectives     [LB] List     [A] Toggle     [X] Track     [B] Close"
        end
    end

    meta.scrollDetail = function(self, direction)
        local qInfoScrollBox = self:getQuestScrollBox()
        if not qInfoScrollBox then return end
        local sBoxMeta = qInfoScrollBox.userData.scrollBoxMeta
        if not sBoxMeta then return end
        local amount = (self.params.fontSize or 18) * 3
        sBoxMeta:setScrollPosition(sBoxMeta:getScrollPosition() + direction * amount)
        self:update()
    end

    -- Vertical divider between panels
    local panelDivider = {
        type = ui.TYPE.Image,
        props = {
            resource = borderTexLeft,
            tileV = true,
            size = util.vector2(2, params.size.y),
            position = util.vector2(questListWidth - 1, 0),
        },
    }

    local listPanel = {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = util.vector2(questListWidth, params.size.y),
        },
        content = ui.content {
            listFocusBorder,
            filterBar,
            {
                type = ui.TYPE.Widget,
                props = {
                    position = util.vector2(2, filterBarHeight),
                    size = util.vector2(questListWidth - 4, listPanelHeight - 4),
                },
                content = ui.content { questListBox },
            },
            panelDivider,
        }
    }

    local detailWrapper = {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = questInfoSize,
        },
        content = ui.content {
            detailFocusBorder,
            questInfoPanel,
        }
    }

    local questMain = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = true,
        },
        content = ui.content {
            listPanel,
            detailWrapper,
        }
    }
    meta._questMain = questMain
    meta._detailWrapper = detailWrapper

    local mainWindow = {
        template = customTemplates.boxSolidThick,
        props = {},
        content = ui.content { questMain }
    }

    -- Controller hints bar
    local controllerHintsHeight = fontSize * 1.6
    local controllerHintsText = {
        type = ui.TYPE.Text,
        props = {
            text = "[D-Pad] Navigate     [RB] Details     [A] Track     [X] Toggle     [B] Close",
            textSize = fontSize * 0.65,
            textColor = COLOR_GOLD_DIM,
            autoSize = true,
        },
    }
    meta._controllerHintsText = controllerHintsText

    local controllerHintsBar = {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = util.vector2(params.size.x + 6, controllerHintsHeight),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = uiUtils.whiteTexture,
                    relativeSize = util.vector2(1, 1),
                    color = COLOR_BG_DARK,
                    alpha = 0.7,
                },
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = true,
                    anchor = util.vector2(0.5, 0.5),
                    relativePosition = util.vector2(0.5, 0.5),
                },
                content = ui.content {
                    controllerHintsText,
                },
            },
        },
    }

    local mainFlex = {
        type = ui.TYPE.Flex,
        layer = commonData.mainMenuLayer,
        props = {
            autoSize = true,
            horizontal = false,
            align = ui.ALIGNMENT.Center,
            relativePosition = params.relativePosition,
        },
        content = ui.content {
            mainHeader,
            mainWindow,
            controllerHintsBar,
        }
    }

    meta.menu = ui.create(mainFlex)
    meta:fillQuestsContent()
    meta:update()

    local function onMouseWheelCallback(content, value)
        for _, dt in pairs(content) do
            if not type(dt) == "table" then goto continue end
            if dt.userData and dt.userData.onMouseWheel then
                dt.userData.onMouseWheel(value)
            end
            if dt.content then
                onMouseWheelCallback(dt.content, value)
            end
            ::continue::
        end
    end

    meta.onMouseWheel = function (self, vertical)
        onMouseWheelCallback(meta.menu.layout.content, vertical)
    end

    meta.selectNextPreviousInList = function (self, step)
        local questList = self:getQuestList()
        local selected = self:getQuestListSelectedFladValue()

        local sBoxMeta = questList.userData.scrollBoxMeta
        local content = sBoxMeta:getContent()
        if #content == 0 then return end

        local selectedIndex = nil
        for i, elem in ipairs(content) do
            if elem.name == selected then
                selectedIndex = i
                break
            end
        end

        if not selectedIndex then selectedIndex = 0 end

        local nextIndex = selectedIndex + step
        local attempts = 0
        while attempts < #content do
            if nextIndex > #content then nextIndex = #content end
            if nextIndex < 1 then nextIndex = 1 end

            local nextSelected = content[nextIndex]
            if nextSelected and nextSelected.userData and nextSelected.userData.questName then
                self:selectQuest(nextSelected.name)
                return
            end
            nextIndex = nextIndex + step
            if nextIndex > #content or nextIndex < 1 then return end
            attempts = attempts + 1
        end
    end

    meta.scrollInfo = function (self, value)
        local qInfoScrollBox = self:getQuestScrollBox()
        if not qInfoScrollBox then return end
        ---@type questGuider.ui.scrollBox
        local sBoxMeta = qInfoScrollBox.userData.scrollBoxMeta
        if not sBoxMeta then return end
        sBoxMeta:setScrollPosition(sBoxMeta:getScrollPosition() + value * (self.params.fontSize or 18) * 3)
    end

    meta.trackObjects = function (self)
        local qInfoScrollBox = self:getQuestScrollBox()
        if not qInfoScrollBox then return end
        local qBoxMeta = qInfoScrollBox.userData.questBoxMeta
        if not qBoxMeta or not qBoxMeta.trackObjectsFunc then return end
        qBoxMeta.trackObjectsFunc()
    end

    meta.untrackObjects = function (self)
        local qInfoScrollBox = self:getQuestScrollBox()
        if not qInfoScrollBox then return end
        local qBoxMeta = qInfoScrollBox.userData.questBoxMeta
        if not qBoxMeta or not qBoxMeta.untrackObjectsFunc then return end
        qBoxMeta.untrackObjectsFunc()
    end

    meta.toggleTrackObjects = function (self)
        local qInfoScrollBox = self:getQuestScrollBox()
        if not qInfoScrollBox then return end
        local qBoxMeta = qInfoScrollBox.userData.questBoxMeta
        if not qBoxMeta or not qBoxMeta.toggleTrackObjectsFunc then return end
        qBoxMeta.toggleTrackObjectsFunc()
    end

    meta.toggleTopTopics = function (self)
        local qInfoScrollBox = self:getQuestScrollBox()
        if not qInfoScrollBox then return end
        local qBoxMeta = qInfoScrollBox.userData.questBoxMeta
        if not qBoxMeta or not qBoxMeta.toggleTopTopicsFunc then return end
        qBoxMeta.toggleTopTopicsFunc()
    end

    meta._getNextStagesMetas = function(self)
        local qInfoScrollBox = self:getQuestScrollBox()
        if not qInfoScrollBox then return {} end
        local qBoxMeta = qInfoScrollBox.userData.questBoxMeta
        if not qBoxMeta then return {} end
        local scrlBox = qBoxMeta:getScrollBox().userData.scrollBoxMeta
        if not scrlBox then return {} end

        local metas = {}
        for _, scrollContentElement in pairs(scrlBox:getContent()) do
            for _, block in pairs(scrollContentElement.content or {}) do
                if block.userData and block.userData.meta
                        and block.userData.meta.type == commonData.elementMetatableTypes.nextStages then
                    table.insert(metas, block.userData.meta)
                end
            end
        end
        return metas
    end

    meta.navigateDetailObjective = function(self, direction)
        local metas = self:_getNextStagesMetas()
        for _, nsMeta in ipairs(metas) do
            if nsMeta:getObjectCount() > 0 then
                local moved = nsMeta:navigateObjective(direction)
                if moved then self:update() end
                return moved
            end
        end
        return false
    end

    meta.toggleDetailObjective = function(self)
        local metas = self:_getNextStagesMetas()
        for _, nsMeta in ipairs(metas) do
            if nsMeta:getCursorIndex() > 0 then
                nsMeta:toggleSelectedTracking()
                return
            end
        end
    end

    meta.getDetailObjectCount = function(self)
        local metas = self:_getNextStagesMetas()
        for _, nsMeta in ipairs(metas) do
            return nsMeta:getObjectCount()
        end
        return 0
    end

    meta.resetDetailCursor = function(self)
        local metas = self:_getNextStagesMetas()
        for _, nsMeta in ipairs(metas) do
            nsMeta:setCursorIndex(0)
        end
    end

    meta.initDetailCursor = function(self)
        local metas = self:_getNextStagesMetas()
        for _, nsMeta in ipairs(metas) do
            if nsMeta:getObjectCount() > 0 and nsMeta:getCursorIndex() == 0 then
                nsMeta:setCursorIndex(1)
                self:update()
            end
            return
        end
    end

    if not params.isQuestList then
        local lastQName = localStorage.data.lastSelectedQuest
        local qDt = playerQuests.getQuestDataByName(lastQName)
        local plQDt = playerQuests.getQuestStorageData(lastQName)
        if lastQName and (qDt and (not qDt.isFinished or plQDt and plQDt.pinned) or meta.textFilter ~= "") then
            meta:selectQuest(lastQName)
        else
            meta:selectNextPreviousInList(1)
        end
        meta:update()
    end

    return meta
end


return create
