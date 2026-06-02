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
local realTimer = require("scripts.quest_guider_lite.realTimer")
local keysModule = require("scripts.quest_guider_lite.input.keys")

local cacheLib = require("scripts.quest_guider_lite.utils.cache")
local timeLib = require("scripts.quest_guider_lite.timeLocal")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local log = require("scripts.quest_guider_lite.utils.log")

local button = require("scripts.quest_guider_lite.ui.button")
local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")
local interval = require("scripts.quest_guider_lite.ui.interval")
local checkBox = require("scripts.quest_guider_lite.ui.checkBox")
local borders = require("scripts.quest_guider_lite.ui.borders")

local questBox = require("scripts.quest_guider_lite.ui.customJournal.questBox")

local l10n = core.l10n(commonData.l10nKey)


---@class questGuider.ui.customJournal
local journalMeta = {}
journalMeta.__index = journalMeta

journalMeta.menu = nil


journalMeta.getQuestList = function (self)
    return self.menu.layout.content[2].content[1].content[1].content[4]
end

journalMeta.getQuestMain = function (self)
    return self.menu.layout.content[2].content[1]
end

journalMeta.getQuestScrollBox = function (self)
    return self:getQuestMain().content[2]
end

journalMeta.getQuestListCheckBoxFlex = function (self)
    return self.menu.layout.content[2].content[1].content[1].content[2]
end

journalMeta.getQuestListFinishedCheckBox = function (self)
    return self:getQuestListCheckBoxFlex().content[1]
end

journalMeta.getQuestListHiddenCheckBox = function (self)
    return self:getQuestListCheckBoxFlex().content[3]
end

journalMeta.resetQuestListColors = function (self)
    local questList = self:getQuestList()

    ---@type questGuider.ui.scrollBox
    local questBoxMeta = questList.userData.scrollBoxMeta

    for _, elem in ipairs(questBoxMeta:getContent()) do
        if elem.userData then
            -- elem.content[3].props.textShadow = false
            elem.content[1].props.visible = false
        end
    end
end

journalMeta.updateQuestListTrackedColors = function (self)
    local questList = self:getQuestList()

    ---@type questGuider.ui.scrollBox
    local questBoxMeta = questList.userData.scrollBoxMeta

    for _, elem in ipairs(questBoxMeta:getContent()) do
        if elem.userData and elem.userData.playerQuestData then
            elem.content[2].content = ui.content{}
            self:_addFlags(elem.content[2].content, elem.userData.playerQuestData)
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

local createQuestBoxTimer

journalMeta.selectQuest = function (self, qName, force, doDelay)
    if self.params.menuId == commonData.journalMenuId then
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
        local elemHeight = self.questListElementSize.y

        local height = uiUtils.getContentHeightOfIndex(qListContent, index)

        if scrollPos > height then
            scrollBoxMeta:setScrollPosition(math.max(0, height))
        elseif scrollPos + scrollHeight < (height + elemHeight) then
            scrollBoxMeta:setScrollPosition(height - scrollHeight + elemHeight)
        end
    end

    local function applyTextShadow()
        -- selectedLayout.content[3].props.textShadow = true
        -- selectedLayout.content[3].props.textShadowColor = config.data.ui.shadowColor
        selectedLayout.content[1].props.visible = true
    end

    local sb = self:getQuestScrollBox()
    if not force and sb and sb.name == qName and self.textFilter == sb.userData.lastFilter then
        applyTextShadow()
        return
    end

    local playerHasQuest = playerQuests.getQuestStorageData(qName) or false

    local function requestData()
        ---@type questGuider.ui.questBoxMeta
        local questBoxMeta = self:getQuestScrollBox().userData.questBoxMeta
        questBoxMeta.requestId = tostring(math.random())
        core.sendGlobalEvent("QGL:fillQuestBoxQuestInfo", {
            data = questBoxMeta.dialogueInfo,
            menuId = self.params.menuId,
            useCurrentIndex = self.params.isQuestList or self.params.menuId == commonData.journalMenuId and not playerHasQuest,
            player = playerRef.object,
            requestId = questBoxMeta.requestId,
            config = config.getTrackingConfigData()
        })
    end

    local function createQuestBox()
        local hideStageText = self.params.hideStageText and self.firstEntryMode or not playerHasQuest and
            self.params.menuId == commonData.journalMenuId
        qMainLay.content[2] = questBox.create{
            parent = self,
            fontSize = self.params.fontSize or 18,
            playerQuestData = selectedLayout.userData.playerQuestData,
            isQuestList = self.params.isQuestList or not playerHasQuest,
            showReqsForAll = not self.firstEntryMode,
            hideStageText = hideStageText,
            showOnlyMainDia = self.params.showOnlyMainDia and self.firstEntryMode,
            showOnlyFirstDiaEntry = self.firstEntryMode or not playerHasQuest and self.params.menuId == commonData.journalMenuId,
            showReqDiaEntryText = not playerHasQuest or self.params.menuId ~= commonData.journalMenuId,
            showFullReqDiaEntryText = not hideStageText,
            questName = selectedLayout.userData.questName,
            size = self.questInfoPanelSize,
            userData = {
                lastFilter = self.textFilter
            },
            updateFunc = function ()
                self:update()
            end,
        }
        requestData()
    end

    if createQuestBoxTimer then
        createQuestBoxTimer()
        createQuestBoxTimer = nil
    end

    if doDelay then
        createQuestBoxTimer = realTimer.newTimer(0.5, function ()
            if not self.menu.layout then return end
            createQuestBox()
            self:update()
            createQuestBoxTimer = nil
        end)
    else
        createQuestBox()
    end

    self:resetQuestListSelection()
    self:setQuestListSelectedFlad(qName)
    applyTextShadow()
    moveScroll()

    self:update()

    if not doDelay then
        requestData()
    end
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
            if not nextStagesBlock.userData or not nextStagesBlock.userData or not nextStagesBlock.userData.meta
                    or nextStagesBlock.userData.meta.type ~= commonData.elementMetatableTypes.nextStages then
                goto continue
            end

            nextStagesBlock.userData.meta:updateObjectElements()

            ::continue::
        end
    end
end


---@param questData questGuider.playerQuest.storageQuestData
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

        local dateStr = timeLib.getDateByTime(timeLib.getTimestamp(dt))
        if stringLib.utf8_lower(dateStr):find(text, 1, true) then
            return true
        end
    end

    return false
end


---@param storageData questGuider.playerQuest.storageQuestData
function journalMeta._addFlags(self, content, storageData)
    if not commonData.whiteTexture then return end

    ---@type table<string, string[]>
    local objects = {}
    for diaId, diaRecord in pairs((playerQuests.getQuestDataByName(storageData.name) or {}).records or {}) do
        tableLib.copy(tracking.getDiaTrackedObjects(diaId) or {}, objects)
    end

    if not next(objects) then return end

    if not config.data.journal.trackedColorMarks then
        content:add{
            type = ui.TYPE.Image,
            props = {
                resource = commonData.whiteTexture,
                size = util.vector2(self.params.fontSize / 3, self.params.fontSize - 2),
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
                        size = util.vector2(self.params.fontSize / 4, self.params.fontSize - 2),
                        color = util.color.rgb(objData.color[1], objData.color[2], objData.color[3]),
                    },
                }
            end
        end
    end
end


function journalMeta.fillQuestsContent(self)
    local params = self.params

    local qList = self:getQuestList()
    ---@type questGuider.ui.scrollBox
    local sBoxMeta = qList.userData.scrollBoxMeta
    sBoxMeta:clearContent()

    local content = sBoxMeta:getContent()

    ---@type table<string, questGuider.playerQuest.storageQuestData>
    local questData = {}

    -- for those quests that are tracked but not yet taken by the player
    if self.params.menuId == commonData.journalMenuId then
        questData = playerQuests.generateStorageQuestDataByDiaIdList(tableLib.keys(tracking.trackedObjectsByDiaId))
    end

    tableLib.copy(self.storageTypeQuestData or playerQuests.getStorageData().questData or {}, questData)

    local finishedSubVal = 20000000000
    local disabledSubVal = 10000000000
    local generatedSubVal = 5000000000
    local pinnedAddVal = 20000000000

    local compareVals = {}
    for _, dt in pairs(questData) do
        local val = timeLib.getTimestamp(dt)
        local hasTracked = tracking.hasTrackedObjectsForQuestName(dt.name)

        val = dt.pinned and val + pinnedAddVal or
            dt.generated and val - generatedSubVal or
            (hasTracked and (dt.finished or dt.disabled)) and val - generatedSubVal or
            dt.finished and val - finishedSubVal or
            dt.disabled and val - disabledSubVal or val

        compareVals[dt.name] = val
    end

    local function compareFunc(a, b)
        local aVal = compareVals[a.name or ""] or 0
        local bVal = compareVals[b.name or ""] or 0
        return aVal > bVal
    end

    ---@type questGuider.playerQuest.storageQuestData[]
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

    local inactiveLabelLayout = {
        type = ui.TYPE.Widget,
        props = {
            size = self.inactiveLabelSize,
        },
        name = "QL_InactiveLabel",
        content = ui.content {
            {
                type = ui.TYPE.Text,
                props = {
                    text = l10n("inactiveQuestsLabel"),
                    textSize = (params.fontSize or 18) * 1.25,
                    autoSize = false,
                    size = self.inactiveLabelSize,
                    alpha = 0.75,
                    textColor = config.data.ui.defaultColor,
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center,
                },
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = borders.textures[4],
                    tileH = true,
                    tileV = false,
                    size = util.vector2(0, 2),
                    relativeSize = util.vector2(1, 0),
                    anchor = util.vector2(0, 1),
                    relativePosition = util.vector2(0, 1),
                    alpha = 0.75,
                },
            },
        }
    }

    local showFinished = self:getQuestListFinishedCheckBox().userData.checked
    local showHidden = self:getQuestListHiddenCheckBox().userData.checked

    local disabledColor = config.data.ui.disabledColor
    local finishedColor = config.data.ui.disabledColor

    self.hasInactiveLabel = false
    local addedQuests = 0

    for _, dt in pairs(sortedData) do
        if dt.disabled and not showHidden
                or dt.finished and not showFinished then
            goto continue
        end

        if dt.started and self.params.menuId == commonData.allQuestsMenuId and not showFinished then
            goto continue
        end

        if params.isQuestList and (not dt.name or dt.name == "") then
            goto continue
        end

        if self.textFilter ~= "" and not hasText(dt, self.textFilter) then
            goto continue
        end

        if self.params.menuId ~= commonData.allQuestsMenuId and
                not dt.pinned and (dt.finished or dt.disabled or dt.generated) and not self.hasInactiveLabel then
            content:add(inactiveLabelLayout)
            self.hasInactiveLabel = true
        end

        if addedQuests == 0 and not self.hasInactiveLabel then
            content:add{
                type = ui.TYPE.Image,
                props = {
                    resource = borders.textures[4],
                    size = util.vector2(self.questListElementSize.x, 2),
                },
            }
        end

        local qName = dt.name or ""

        local qNameText = qName == "" and l10n("miscellaneous") or qName or "???"

        if dt.finished or dt.disabled or dt.pinned then
            qNameText = string.format("%s (%s%s%s)",
                qNameText,
                dt.pinned and l10n("pinnedLabel") or "",
                dt.finished and l10n("finishedLabel") or "",
                dt.disabled and l10n("hiddenLabel") or ""
            )
        end

        local flagsContent = ui.content{}
        self:_addFlags(flagsContent, dt)

        local ssqnLayout
        local ssqnWidth = 0
        if (I.SSQN and config.data.journal.ssqnIcons) then
            local diaId = (dt.list[1] or {}).diaId

            if diaId then
                local iconPath = I.SSQN.getQIcon(diaId)

                if not vfs.fileExists(iconPath) then
                    iconPath = "Icons/SSQN/DEFAULT.dds"
                end

                ssqnWidth = math.floor(self.questListElementSize.y * 0.6 + config.data.ui.fontSize * 0.25)
                ssqnLayout = {
                    type = ui.TYPE.Image,
                    props = {
                        size = util.vector2(self.questListElementSize.y * 0.6, self.questListElementSize.y * 0.6),
                        resource = ui.texture{ path = iconPath },
                        anchor = util.vector2(0, 0.5),
                        position = util.vector2(0, self.questListElementSize.y * 0.5)
                    }
                }
            end
        end

        local qListScrollBox = self:getQuestList()
        ---@type questGuider.ui.scrollBox
        local qListScrollBoxMeta = qListScrollBox.userData.scrollBoxMeta

        local textColor = dt.disabled and disabledColor or dt.finished and finishedColor or config.data.ui.defaultColor

        local contentData
        contentData = {
            type = ui.TYPE.Widget,
            props = {
                size = self.questListElementSize,
                propagateEvents = false,
            },
            name = qName,
            userData = {
                height = self.questListElementSize.y,
                questName = qName,
                playerQuestData = dt,
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
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = uiUtils.whiteTexture,
                        color = config.data.ui.defaultColor,
                        alpha = 0.4,
                        size = util.vector2(sBoxMeta.innnerSize.x, self.params.fontSize * 2 + 4),
                        visible = false,
                    },
                },
                {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                        alpha = (dt.finished or dt.disabled) and 0.5 or 1,
                        anchor = util.vector2(1, 1),
                        position = util.vector2(self.questListElementSize.x - 2, self.questListElementSize.y - 3),
                    },
                    content = flagsContent,
                },
                {
                    type = ui.TYPE.Text,
                    props = {
                        text = uiUtils.colorize(qNameText, self.textFilter, "#"..config.data.ui.selectionColor:asHex(), "#"..textColor:asHex()),
                        textSize = params.fontSize or 18,
                        autoSize = false,
                        size = util.vector2(self.questListElementSize.x - ssqnWidth, self.questListElementSize.y - 4),
                        textColor = textColor,
                        position = util.vector2(ssqnWidth, 2),
                        multiline = true,
                        wordWrap = true,
                        textAlignH = ui.ALIGNMENT.Start,
                        textAlignV = ui.ALIGNMENT.Start,
                    },
                },
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = borders.textures[4],
                        tileH = true,
                        tileV = false,
                        size = util.vector2(0, 2),
                        relativeSize = util.vector2(1, 0),
                        anchor = util.vector2(0, 1),
                        relativePosition = util.vector2(0, 1),
                        alpha = (dt.disabled or dt.finished) and not dt.pinned and 0.5 or nil
                    },
                },
            }
        }

        if ssqnLayout then
            contentData.content:add(ssqnLayout)
        end

        content:add(contentData)
        addedQuests = addedQuests + 1

        ::continue::
    end

    local height = 2 + addedQuests * self.questListElementSize.y + (self.hasInactiveLabel and self.inactiveLabelSize.y or 0)
    sBoxMeta:setContentHeight(height)
    sBoxMeta:updateContent()
    local scrollPos = sBoxMeta:getScrollPosition()
    local scrollElemHeight = sBoxMeta.params.size.y
    if scrollPos > height then
        sBoxMeta:setScrollPosition(math.max(0, height - scrollElemHeight))
    end
end


---@return boolean changed
function journalMeta:updateTrackedButtonVisibility()
    if not self.trackiingBtnLayout then return false end

    local newVal = tracking.hasTrackedObjects() and self.params.createTrackingMenuFunc and true or false
    if newVal ~= self.trackiingBtnLayout.props.visible then
        self.trackiingBtnLayout.props.visible = newVal
        return true
    end
    return false
end


---@param questList string[]
function journalMeta:loadQuestList(questList)
    self.storageTypeQuestData = playerQuests.generateStorageQuestDataByDiaIdList(questList or {})
    self:fillQuestsContent()
end


---@class questGuider.ui.customJournal.params
---@field menuId string?
---@field size any
---@field sizeProportional any
---@field fontSize integer
---@field relativePosition any?
---@field headerName string?
---@field questList string[]?
---@field isQuestList boolean?
---@field showReqsForAll boolean?
---@field hideStageText boolean?
---@field showOnlyMainDia boolean?
---@field showReqDiaEntryText boolean?
---@field allQuestsMode boolean?
---@field nearbyModeDefault boolean?
---@field allEntriesDefault boolean?
---@field hideJournalBtn boolean?
---@field createTopicMenuFunc function?
---@field createTrackingMenuFunc function?
---@field onClose function?

---@param params questGuider.ui.customJournal.params
local function create(params)

    ---@class questGuider.ui.customJournal
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
        if not menuHandler.getMenu(commonData.journalMenuId) and not menuHandler.getMenu(commonData.allQuestsMenuId) then
            cacheLib.clear("hasPhrase")
        end
    end

    meta.textFilter = ""

    meta.nearbyMode = false
    if params.allQuestsMode then
        if params.nearbyModeDefault ~= nil then
            meta.nearbyMode = params.nearbyModeDefault
        else
            meta.nearbyMode = localStorage.data.nearbyQuestsCheckBox or false
        end
    end

    meta.firstEntryMode = false
    if params.allQuestsMode then
        if params.allEntriesDefault ~= nil then
            meta.firstEntryMode = not params.allEntriesDefault
        else
            meta.firstEntryMode = not localStorage.data.allEntriesCheckBox
        end
    end

    meta.storageTypeQuestData = meta.params.allQuestsMode and meta.nearbyMode and {} or
        (params.questList and playerQuests.generateStorageQuestDataByDiaIdList(params.questList))


    local questInfoSize = util.vector2(params.size.x * (1 - config.data.journal.listRelativeSize * 0.01), params.size.y)
    meta.questInfoPanelSize = questInfoSize
    local questInfo = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = questInfoSize,
        },
        userData = {
            size = questInfoSize,
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = borders.textures[1],
                    size = util.vector2(2, questInfoSize.y),
                },
            }
        }
    }

    local function toggleNearbyMenu()
        if params.menuId == commonData.journalMenuId then
            local dialogues = {}
            for qName, dt in pairs(playerQuests.questData) do
                for diaId, _ in pairs(dt.records) do
                    table.insert(dialogues, diaId)
                end
            end
            local menu = create{
                fontSize = config.data.ui.fontSize,
                sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01, config.data.journal.heightProportional * 0.01),
                relativePosition = util.vector2(config.data.journal.position.x * 0.01, config.data.journal.position.y * 0.01),
                headerName = l10n("nearby"),
                menuId = commonData.allQuestsMenuId,
                questList = dialogues,
                isQuestList = true,
                showReqsForAll = false,
                showReqDiaEntryText = true,
                allQuestsMode = true,
                nearbyModeDefault = true,
                allEntriesDefault = false,
                hideStageText = true,
                showOnlyMainDia = true,
                createTopicMenuFunc = params.createTopicMenuFunc,
                createTrackingMenuFunc = params.createTrackingMenuFunc,
            }
            menuHandler.registerMenu(commonData.allQuestsMenuId, menu)
        else
            local menu = create{
                fontSize = config.data.ui.fontSize,
                sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01, config.data.journal.heightProportional * 0.01),
                relativePosition = util.vector2(config.data.journal.position.x * 0.01, config.data.journal.position.y * 0.01),
                createTopicMenuFunc = params.createTopicMenuFunc,
                createTrackingMenuFunc = params.createTrackingMenuFunc,
            }
            menuHandler.registerMenu(commonData.journalMenuId, menu)
        end

        menuHandler.destroyMenu(meta.params.menuId)
    end

    local mainHeader
    meta.headerDragDistance = 0
    meta.headerPressed = false

    local headerEvents = {
        mousePress = async:callback(function(e, layout)
            mainHeader.userData.lastMousePos = e.position
            meta.headerDragDistance = 0
            meta.headerPressed = true
        end),

        mouseRelease = async:callback(function(_, layout)
            local relativePos = meta.menu.layout.props.relativePosition
            config.setValue("journal.position.x", math.floor(relativePos.x * 10000) / 100)
            config.setValue("journal.position.y", math.floor(relativePos.y * 10000) / 100)
            mainHeader.userData.lastMousePos = nil

            if mainHeader.userData.contentBackup then
                meta:getQuestMain().content[2] = mainHeader.userData.contentBackup
                mainHeader.userData.contentBackup = nil
            end
            meta.headerDragDistance = 0
            meta.headerPressed = false
            meta:update()
        end),

        mouseMove = async:callback(function(e, layout)
            if not mainHeader.userData.lastMousePos then return end

            local screenSize = uiUtils.getScaledScreenSize()
            local props = meta.menu.layout.props

            meta.headerDragDistance = meta.headerDragDistance +
                (e.position - mainHeader.userData.lastMousePos):length()

            if meta.headerDragDistance > 20 then
                if not mainHeader.userData.contentBackup then
                    mainHeader.userData.contentBackup = meta:getQuestScrollBox()
                    meta:getQuestMain().content[2] = questInfo
                end
                props.relativePosition = props.relativePosition - (mainHeader.userData.lastMousePos - e.position):ediv(screenSize)
            end

            mainHeader.userData.lastMousePos = e.position

            meta:update()
        end),
    }

    meta.trackiingBtnLayout = {
        type = ui.TYPE.Text,
        props = {
            text = l10n("tracking"),
            visible = tracking.hasTrackedObjects() and params.createTrackingMenuFunc and true or false,
            textSize = params.fontSize * 1.15,
            autoSize = true,
            textColor = config.data.ui.defaultColor,
            textShadow = true,
            textShadowColor = config.data.ui.shadowColor,
            propagateEvents = false,
        },
        userData = {},
        events = {
            mousePress = async:callback(function(e, layout)
                headerEvents.mousePress(e)
            end),
            mouseRelease = async:callback(function(e, layout)
                if meta.headerDragDistance < 20 and meta.headerPressed then
                    if params.createTrackingMenuFunc then
                        if menuHandler.getMenu(commonData.trackingMenuId) then
                            menuHandler.destroyMenu(commonData.trackingMenuId)
                        else
                            params.createTrackingMenuFunc()
                        end
                    end
                end
                headerEvents.mouseRelease(e)
            end),
            mouseMove = async:callback(function(e, layout)
                headerEvents.mouseMove(e)
            end)
        }
    }

    mainHeader = {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(params.size.x + 6, params.fontSize * 1.5),
        },
        userData = {},
        events = headerEvents,
        content = ui.content{
            {
                type = ui.TYPE.Image,
                props = {
                    resource = uiUtils.whiteTexture,
                    relativeSize = util.vector2(1, 1),
                    color = config.data.ui.backgroundColor,
                    alpha = config.data.ui.headerBackgroundAlpha / 100,
                }
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    arrange = ui.ALIGNMENT.End
                },
                content = ui.content{
                    {
                        type = ui.TYPE.Text,
                        props = {
                            text = params.headerName and params.headerName or l10n("journal"),
                            textSize = params.fontSize * 1.4,
                            autoSize = true,
                            textColor = config.data.ui.defaultColor,
                            textShadow = true,
                            textShadowColor = config.data.ui.shadowColor,
                        },
                    },
                    {
                        type = ui.TYPE.Text,
                        props = {
                            text = l10n("markersDisabled"),
                            textSize = params.fontSize * 0.8,
                            anchor = util.vector2(0, 1),
                            autoSize = true,
                            textColor = config.data.ui.defaultColor,
                        },
                    }
                }
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    anchor = util.vector2(1, 1),
                    relativePosition = util.vector2(1, 1),
                },
                content = ui.content {
                    meta.trackiingBtnLayout,
                    interval(params.fontSize * 2, 0),
                    {
                        type = ui.TYPE.Text,
                        props = {
                            text = params.menuId == commonData.journalMenuId and l10n("nearby") or l10n("journal"),
                            visible = not params.hideJournalBtn and
                                (params.menuId == commonData.allQuestsMenuId or params.menuId == commonData.journalMenuId) or false,
                            textSize = params.fontSize * 1.15,
                            autoSize = true,
                            textColor = config.data.ui.defaultColor,
                            textShadow = true,
                            textShadowColor = config.data.ui.shadowColor,
                            propagateEvents = false,
                        },
                        userData = {},
                        events = {
                            mousePress = async:callback(function(e, layout)
                                headerEvents.mousePress(e)
                            end),
                            mouseRelease = async:callback(function(e, layout)
                                if meta.headerDragDistance < 20 and meta.headerPressed then
                                    toggleNearbyMenu()
                                end
                                headerEvents.mouseRelease(e)
                            end),
                            mouseMove = async:callback(function(e, layout)
                                headerEvents.mouseMove(e)
                            end)
                        }
                    },
                    interval(params.fontSize * 2, 0),
                    {
                        type = ui.TYPE.Text,
                        props = {
                            text = l10n("topics"),
                            visible = core.API_REVISION >= 93 and params.createTopicMenuFunc and true or false,
                            textSize = params.fontSize * 1.15,
                            autoSize = true,
                            textColor = config.data.ui.defaultColor,
                            textShadow = true,
                            textShadowColor = config.data.ui.shadowColor,
                            propagateEvents = false,
                        },
                        userData = {},
                        events = {
                            mousePress = async:callback(function(e, layout)
                                headerEvents.mousePress(e)
                            end),
                            mouseRelease = async:callback(function(e, layout)
                                if meta.headerDragDistance < 20 and meta.headerPressed then
                                    if params.createTopicMenuFunc then
                                        if menuHandler.getMenu(commonData.topicsMenuId) then
                                            menuHandler.destroyMenu(commonData.topicsMenuId)
                                        else
                                            params.createTopicMenuFunc()
                                        end
                                    end
                                end
                                headerEvents.mouseRelease(e)
                            end),
                            mouseMove = async:callback(function(e, layout)
                                headerEvents.mouseMove(e)
                            end)
                        }
                    },
                    interval(params.fontSize * 3, 0),
                    {
                        type = ui.TYPE.Text,
                        props = {
                            text = l10n("close"),
                            textSize = params.fontSize * 1.25,
                            autoSize = true,
                            textColor = config.data.ui.defaultColor,
                            textShadow = true,
                            textShadowColor = config.data.ui.shadowColor,
                            propagateEvents = false,
                        },
                        userData = {},
                        events = {
                            mouseRelease = async:callback(function(_, layout)
                                meta:close()
                            end),
                        }
                    },
                }
            },
        },
    }

    meta.updateMarkersDisabledMessage = function(self)
        mainHeader.content[2].content[2].props.visible = (tracking.storageData ~= nil) and (tracking.storageData.hideAllMarkers == true) or false
        if self.menu and self.menu.layout then
            self:update()
        end
    end

    meta:updateMarkersDisabledMessage()

    local questListSize = util.vector2(params.size.x * config.data.journal.listRelativeSize * 0.01, params.size.y)
    local searchBtnWidth = stringLib.length(l10n("filter")) * config.data.ui.fontSize * config.data.journal.textHeightMulRecord + 16
    local searchBar
    searchBar = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
            anchor = util.vector2(0.5, 0.5),
        },
        content = ui.content {
            {
                template = templates.box,
                props = {
                    anchor = util.vector2(0, 0.5),
                },
                content = ui.content {
                    {
                        template = templates.textEditLine,
                        props = {
                            autoSize = false,
                            textSize = params.fontSize,
                            size = util.vector2(questListSize.x - searchBtnWidth, params.fontSize + 4),
                            textColor = config.data.ui.defaultColor,
                        },
                        events = {
                            textChanged = async:callback(function(text, layout)
                                meta.textFilter = text
                                searchBar.content[1].content[1].props.text = meta.textFilter
                                if params.menuId == commonData.journalMenuId then
                                    localStorage.data.journalSearchText = meta.textFilter
                                end
                            end),
                            keyRelease = async:callback(function(e, layout)
                                if e.code == input.KEY.Enter then
                                    local selectedQuest = meta:getQuestListSelectedFladValue()
                                    meta:fillQuestsContent()
                                    meta:selectQuest(selectedQuest)
                                    searchBar.content[1].content[1].props.text = meta.textFilter

                                    local qBox = meta:getQuestScrollBox()
                                    if qBox then
                                        ---@type questGuider.ui.questBoxMeta
                                        local questBoxMeta = meta:getQuestScrollBox().userData.questBoxMeta
                                        if questBoxMeta then
                                            questBoxMeta:updateColors()
                                        end
                                    end

                                    updateFunc()
                                end
                            end),
                            focusLoss = async:callback(function(layout)
                                searchBar.content[1].content[1].props.text = meta.textFilter
                            end),
                        },
                    },
                }
            },
            button{
                updateFunc = updateFunc,
                text = l10n("filter"),
                textSize = params.fontSize,
                useDefaultBtnTemplate = true,
                anchor = util.vector2(0, 0.5),
                event = function (layout)
                    local selectedQuest = meta:getQuestListSelectedFladValue()
                    meta:fillQuestsContent()
                    meta:selectQuest(selectedQuest)

                    local qBox = meta:getQuestScrollBox()
                    if qBox then
                        ---@type questGuider.ui.questBoxMeta
                        local questBoxMeta = meta:getQuestScrollBox().userData.questBoxMeta
                        if questBoxMeta then
                            questBoxMeta:updateColors()
                        end
                    end
                end
            },
        }
    }

    if params.menuId == commonData.journalMenuId then
        meta.textFilter = localStorage.data.journalSearchText or ""
        searchBar.content[1].content[1].props.text = meta.textFilter
    end

    local finishedStartedCBValue = false
    if params.menuId == commonData.allQuestsMenuId then
        finishedStartedCBValue = localStorage.data.startedCheckBox and true or false
    else
        finishedStartedCBValue = localStorage.data.finishedCheckBox and true or false
    end

    local checkBoxes = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
            anchor = util.vector2(0.5, 0.5),
        },
        content = ui.content {
            checkBox{
                updateFunc = function ()
                    meta:update()
                end,
                checked = finishedStartedCBValue,
                text = params.menuId ~= commonData.allQuestsMenuId and l10n("finished") or l10n("started"),
                anchor = util.vector2(0.5, 0.5),
                textSize = params.fontSize or 18,
                event = function (checked, layout)
                    local selectedQuest = meta:getQuestListSelectedFladValue()
                    meta:fillQuestsContent()
                    meta:selectQuest(selectedQuest)
                    if params.menuId ~= commonData.allQuestsMenuId then
                        localStorage.data.finishedCheckBox = checked
                    else
                        localStorage.data.startedCheckBox = checked
                    end
                end
            },
            interval(params.fontSize / 2, 0),
            checkBox{
                updateFunc = function ()
                    meta:update()
                end,
                checked = localStorage.data.hiddenCheckBox and true or false,
                text = l10n("hidden"),
                anchor = util.vector2(0.5, 0.5),
                textSize = params.fontSize or 18,
                event = function (checked, layout)
                    local selectedQuest = meta:getQuestListSelectedFladValue()
                    meta:fillQuestsContent()
                    meta:selectQuest(selectedQuest)
                    localStorage.data.hiddenCheckBox = checked
                end
            },
        }
    }

    local checkBoxesSecondLine
    if meta.params.allQuestsMode then
        checkBoxesSecondLine = {
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
                align = ui.ALIGNMENT.Center,
                relativeSize = util.vector2(1, 0),
                relativePosition = util.vector2(1, 0),
                anchor = util.vector2(0, 0.5),
            },
            content = ui.content {
                checkBox{
                    updateFunc = function ()
                        meta:update()
                    end,
                    checked = not meta.firstEntryMode,
                    text = l10n("allEntries"),
                    anchor = util.vector2(1, 0.5),
                    textSize = params.fontSize or 18,
                    event = function (checked, layout)
                        localStorage.data.allEntriesCheckBox = checked
                        meta.firstEntryMode = not checked
                        meta:selectQuest(meta:getQuestListSelectedFladValue(), true)
                    end
                },
                interval(params.fontSize, 0),
                checkBox{
                    updateFunc = function ()
                        meta:update()
                    end,
                    checked = meta.nearbyMode,
                    text = l10n("nearby"),
                    anchor = util.vector2(1, 0.5),
                    textSize = params.fontSize or 18,
                    event = function (checked, layout)
                        localStorage.data.nearbyQuestsCheckBox = checked
                        meta.nearbyMode = checked
                        if checked then
                            core.sendGlobalEvent("QGL:getQuestsNearby", { menuId = params.menuId, player = playerRef.object })
                        else
                            meta:loadQuestList(params.questList or {})
                            meta:update()
                        end
                    end
                },
            }
        }
    else
        checkBoxesSecondLine = interval(0, 0)
    end

    local questsContent = ui.content{}

    local questListBoxYOffset = questListSize.y - params.fontSize * 2 - 13 -
        (meta.params.allQuestsMode and params.fontSize or 0)
    local questListBox = scrollBox{
        updateFunc = updateFunc,
        size = util.vector2(questListSize.x - 2, questListBoxYOffset),
        anchor = util.vector2(0, 0.5),
        scrollAmount = params.size.y / 5,
        contentHeight = 0,
        autoOptimize = true,
        content = questsContent
    }
    local sBoxMeta = questListBox.userData.scrollBoxMeta ---@diagnostic disable-line: need-check-nil

    meta.questListElementSize = util.vector2(sBoxMeta.innnerSize.x, meta.params.fontSize * 2 + 4)
    meta.inactiveLabelSize = util.vector2(meta.questListElementSize.x, math.floor(meta.questListElementSize.y * 1.5))
    meta.hasInactiveLabel = false

    local bottomTextLayout = {
        template = {
            type = ui.TYPE.Container,
            content = ui.content{
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = uiUtils.whiteTexture,
                        color = config.data.ui.backgroundColor,
                        relativeSize = util.vector2(1, 1),
                        position = util.vector2(4, 0),
                    },
                },
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = uiUtils.whiteTexture,
                        color = config.data.ui.backgroundColor,
                        size = util.vector2(0, 2),
                        relativeSize = util.vector2(1, 0),
                        position = util.vector2(4, 0),
                        relativePosition = util.vector2(0, 1),
                    },
                },
                {
                    external = { slot = true },
                    props = {
                        position = util.vector2(4, 0),
                        relativeSize = util.vector2(1, 1),
                    }
                }
            },
        },
        type = ui.TYPE.Container,
        props = {
            alpha = 0,
        },
        content = ui.content{
            {
                type = ui.TYPE.TextEdit,
                props = {
                    text = "",
                    textColor = config.data.ui.defaultColor,
                    textSize = config.data.ui.fontSize * 0.8,
                    alpha = 0.7,
                    size = util.vector2(params.size.x, 0),
                    multiline = true,
                    wordWrap = true,
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center,
                    readOnly = true,
                    autoSize = true,
                },
            }
        }
    }

    local questList = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = questListSize,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            searchBar,
            checkBoxes,
            checkBoxesSecondLine,
            questListBox,
        }
    }


    local mainWindow = {
        template = customTemplates.boxSolidThick,
        props = {

        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = true,
                },
                content = ui.content {
                    questList,
                    questInfo
                }
            }
        }
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
        userData = {

        },
        content = ui.content {
            mainHeader,
            mainWindow,
            {},
        }
    }

    meta.menu = ui.create(mainFlex)

    meta:fillQuestsContent()
    meta:update()


    local bottomTextTimer
    local function decreaseBottomTextAlpha(time)
        if not meta.menu or not meta.menu.layout then return end

        local alpha = bottomTextLayout.props.alpha
        bottomTextLayout.props.alpha = math.max(0, alpha - (alpha > 0.98 and 0.0006 / time or 0.02))

        if bottomTextLayout.props.alpha > 0 then
            bottomTextTimer = realTimer.newTimer(0.03, decreaseBottomTextAlpha, time)
        else
            mainFlex.content[3] = {}
            bottomTextTimer = nil
        end
        meta:update()
    end
    local function increaseBottomTextAlpha(time)
        if not meta.menu or not meta.menu.layout then return end

        local alpha = bottomTextLayout.props.alpha
        bottomTextLayout.props.alpha = math.min(1, alpha + 0.02)

        if bottomTextLayout.props.alpha < 1 then
            bottomTextTimer = realTimer.newTimer(0.03, increaseBottomTextAlpha, time)
        elseif time then
            decreaseBottomTextAlpha(time)
        end
        meta:update()
    end

    function meta:showInfoMessage(text, time)
        if not config.data.journal.bottomInfoText.enabled then return end

        if bottomTextTimer then
            bottomTextTimer()
            bottomTextTimer = nil
        end

        bottomTextLayout.content[1].props.text = text
        mainFlex.content[3] = bottomTextLayout
        bottomTextTimer = realTimer.newTimer(0.03, increaseBottomTextAlpha, time)
    end


    local keyInfo = keysModule.getJournalMenuHotkeyInfoStr(params.menuId == commonData.allQuestsMenuId)
    if keyInfo then
        meta:showInfoMessage(keyInfo, not keysModule.isGamepad and math.min(45, stringLib.length(keyInfo) * 0.25) or nil)
    end


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
        local layout = meta.menu.layout
        onMouseWheelCallback(layout.content, vertical)
    end

    meta.selectNextPreviousInList = function (self, step)
        local questList = self:getQuestList()
        local selected = self:getQuestListSelectedFladValue()

        local selectedIndex = nil
        local sBoxMeta = questList.userData.scrollBoxMeta
        local content = questList.userData.scrollBoxMeta:getContent()
        if #content == 0 then return end

        for i, elem in ipairs(content) do
            if elem.name == selected then
                selectedIndex = i
                break
            end
        end

        if not selectedIndex then selectedIndex = 0 end

        local nextIndex = selectedIndex + step
        if nextIndex > #content then return end
        if nextIndex < 1 then return end

        pcall(function()
            local nextSelected = content[nextIndex]
            if nextSelected and nextSelected.name then
                if nextSelected.name == "QL_InactiveLabel" then
                    nextSelected = content[nextIndex + step]
                end
                self:selectQuest(nextSelected.name, nil, true)
            end
        end)
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

        ---@type questGuider.ui.questBoxMeta
        local qBoxMeta = qInfoScrollBox.userData.questBoxMeta
        if not qBoxMeta or not qBoxMeta.trackObjectsFunc then return end

        qBoxMeta.trackObjectsFunc()
        meta:update()
    end

    meta.untrackObjects = function (self)
        local qInfoScrollBox = self:getQuestScrollBox()
        if not qInfoScrollBox then return end

        ---@type questGuider.ui.questBoxMeta
        local qBoxMeta = qInfoScrollBox.userData.questBoxMeta
        if not qBoxMeta or not qBoxMeta.untrackObjectsFunc then return end

        qBoxMeta.untrackObjectsFunc()
        meta:update()
    end

    meta.toggleTrackObjects = function (self)
        local qInfoScrollBox = self:getQuestScrollBox()
        if not qInfoScrollBox then return end

        ---@type questGuider.ui.questBoxMeta
        local qBoxMeta = qInfoScrollBox.userData.questBoxMeta
        if not qBoxMeta or not qBoxMeta.toggleTrackObjectsFunc then return end

        qBoxMeta.toggleTrackObjectsFunc()
        meta:update()
    end

    meta.toggleTopTopics = function (self)
        local qInfoScrollBox = self:getQuestScrollBox()
        if not qInfoScrollBox then return end

        ---@type questGuider.ui.questBoxMeta
        local qBoxMeta = qInfoScrollBox.userData.questBoxMeta
        if not qBoxMeta or not qBoxMeta.toggleTopTopicsFunc then return end

        qBoxMeta.toggleTopTopicsFunc()
        meta:update()
    end

    meta.toggleTopCheckboxes = function (self)
        ---@type questGuider.ui.checkBox
        local cb1Meta = checkBoxes.content[1].userData.meta
        ---@type questGuider.ui.checkBox
        local cb2Meta = checkBoxes.content[3].userData.meta

        local checked = cb1Meta:getChecked() or cb2Meta:getChecked() or false

        cb1Meta:setChecked(not checked)
        cb2Meta:setChecked(not checked)

        meta:update()
    end

    meta.toggleNearbyCheckbox = function (self)
        if checkBoxesSecondLine.type ~= ui.TYPE.Flex then return end
        ---@type questGuider.ui.checkBox
        local cbMeta = checkBoxesSecondLine.content[3].userData.meta
        if not cbMeta then return end

        cbMeta:setChecked(not cbMeta:getChecked())
        meta:update()
    end

    meta.toggleAllEntriesCheckbox = function (self)
        if checkBoxesSecondLine.type ~= ui.TYPE.Flex then return end
        ---@type questGuider.ui.checkBox
        local cbMeta = checkBoxesSecondLine.content[1].userData.meta
        if not cbMeta then return end

        cbMeta:setChecked(not cbMeta:getChecked())
        meta:update()
    end

    meta.toggleQuestObjectsBtn = function (self)
        local qInfoScrollBox = self:getQuestScrollBox()
        if not qInfoScrollBox or not qInfoScrollBox.userData or not qInfoScrollBox.userData.questBoxMeta then return end

        ---@type questGuider.ui.questBoxMeta
        local qb = qInfoScrollBox.userData.questBoxMeta
        qb:toggleQuestObjectsBtn()
        meta:update()
    end

    meta.toggleQuestHiddenCheckbox = function (self)
        local qInfoScrollBox = self:getQuestScrollBox()
        if not qInfoScrollBox or not qInfoScrollBox.userData or not qInfoScrollBox.userData.questBoxMeta then return end

        ---@type questGuider.ui.questBoxMeta
        local qb = qInfoScrollBox.userData.questBoxMeta

        ---@type questGuider.ui.checkBox
        local hiddenCBMeta = qb.hiddenCheckboxLayout.userData.meta

        hiddenCBMeta:setChecked(not hiddenCBMeta:getChecked())
    end

    meta.toggleQuestPinnedCheckbox = function (self)
        local qInfoScrollBox = self:getQuestScrollBox()
        if not qInfoScrollBox or not qInfoScrollBox.userData or not qInfoScrollBox.userData.questBoxMeta then return end

        ---@type questGuider.ui.questBoxMeta
        local qb = qInfoScrollBox.userData.questBoxMeta

        ---@type questGuider.ui.checkBox
        local pinnedCBMeta = qb.pinnedCheckboxLayout.userData.meta

        pinnedCBMeta:setChecked(not pinnedCBMeta:getChecked())
    end


    if params.menuId == commonData.journalMenuId then
        local lastQName = localStorage.data.lastSelectedQuest
        local qDt = playerQuests.getQuestDataByName(lastQName)
        local plQDt = playerQuests.getQuestStorageData(lastQName)
        if lastQName and (qDt and (not qDt.isFinished or plQDt and plQDt.pinned) or meta.textFilter ~= "") then
            meta:selectQuest(lastQName)
        else
            meta:selectNextPreviousInList(1)
        end
        meta:update()
    else
        meta:selectNextPreviousInList(1)
        meta:update()
    end


    if meta.params.allQuestsMode and meta.nearbyMode then
        core.sendGlobalEvent("QGL:getQuestsNearby", { menuId = params.menuId, player = playerRef.object })
    end


    return meta
end


return create