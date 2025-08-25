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

local timeLib = require("scripts.quest_guider_lite.timeLocal")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local log = require("scripts.quest_guider_lite.utils.log")

local button = require("scripts.quest_guider_lite.ui.button")
local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")
local interval = require("scripts.quest_guider_lite.ui.interval")
local checkBox = require("scripts.quest_guider_lite.ui.checkBox")

local questBox = require("scripts.quest_guider_lite.ui.customJournal.questBox")

local l10n = core.l10n(commonData.l10nKey)


---@class questGuider.ui.customJournal
local journalMeta = {}
journalMeta.__index = journalMeta

journalMeta.menu = nil


journalMeta.getQuestList = function (self)
    return self.menu.layout.content[2].content[1].content[1].content[3]
end

journalMeta.getQuestMain = function (self)
    return self.menu.layout.content[2].content[1].content[2]
end

journalMeta.getQuestScrollBox = function (self)
    return self:getQuestMain().content[1]
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
    local layout = questBoxMeta:getMainFlex()

    for _, elem in ipairs(layout.content) do
        elem.content[3].props.textShadow = false
    end
end

journalMeta.updateQuestListTrackedColors = function (self)
    local questList = self:getQuestList()

    ---@type questGuider.ui.scrollBox
    local questBoxMeta = questList.userData.scrollBoxMeta
    local layout = questBoxMeta:getMainFlex()

    for _, elem in ipairs(layout.content) do
        if elem.userData and elem.userData.playerQuestData then
            elem.content[1].content = ui.content{}
            self:_addFlags(elem.content[1].content, elem.userData.playerQuestData)
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
    sBoxMeta:clearContent()
end

journalMeta.selectQuest = function (self, qName)
    if qName == nil then
        self:resetQuestListSelection()
        self:clearQuestInfo()
        return
    end

    ---@type questGuider.ui.scrollBox
    local scrollBoxMeta = self:getQuestList().userData.scrollBoxMeta
    local qListLayout = scrollBoxMeta:getMainFlex()

    local qMainLay = self:getQuestMain()

    local succ, selectedLayout = pcall(function() return qListLayout.content[qName] end)
    if not succ or not selectedLayout then
        self:clearQuestInfo()
        self:setQuestListSelectedFlad(nil)
        return
    end

    local function applyTextShadow()
        selectedLayout.content[3].props.textShadow = true
        selectedLayout.content[3].props.textShadowColor = config.data.ui.shadowColor
    end

    if self:getQuestScrollBox() and self:getQuestScrollBox().name == qName then
        applyTextShadow()
        return
    end

    qMainLay.content = ui.content{
        questBox.create{
            parent = self,
            fontSize = self.params.fontSize or 18,
            playerQuestData = selectedLayout.userData.playerQuestData,
            isQuestList = self.params.isQuestList,
            showReqsForAll = self.params.showReqsForAll,
            hideStageText = self.params.hideStageText,
            showOnlyFirst = self.params.showOnlyFirst,
            questName = selectedLayout.userData.questName,
            size = qMainLay.userData.size,
            updateFunc = function ()
                self:update()
            end,
        }
    }

    self:resetQuestListSelection()
    self:setQuestListSelectedFlad(qName)
    applyTextShadow()

    self:update()

    ---@type questGuider.ui.questBoxMeta
    local questBoxMeta = self:getQuestScrollBox().userData.questBoxMeta
    core.sendGlobalEvent("QGL:fillQuestBoxQuestInfo", {
        data = questBoxMeta.dialogueInfo,
        menuId = self.params.menuId,
        useCurrentIndex = self.params.isQuestList,
    })
end

journalMeta.update = function(self)
    self.menu:update()
end


function journalMeta.updateNextStageBlocks(self)
    ---@type questGuider.ui.questBoxMeta
    local qBox = self:getQuestScrollBox().userData.questBoxMeta
    ---@type questGuider.ui.scrollBox
    local scrlBox = qBox:getScrollBox().userData.scrollBoxMeta

    for _, scrollContentElement in pairs(scrlBox:getMainFlex().content) do
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
    text = text:lower()
    if questData.name:lower():find(text, 1, true) then
        return true
    end

    for _, dt in pairs(questData.list) do
        if dt.diaId:find(text, 1, true) then return true end

        local journalText = playerQuests.getJournalText(dt.diaId, dt.index)
        if journalText and journalText:lower():find(text, 1, true) then
            return true
        end

        local dateStr = timeLib.getDateByTime(dt.timestamp or 0)
        if dateStr:lower():find(text, 1, true) then
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
                size = util.vector2(self.params.fontSize / 3, self.params.fontSize),
                color = commonData.defaultColor,
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


function journalMeta.fillQuestsContent(self)
    local params = self.params

    local qList = self:getQuestList()
    ---@type questGuider.ui.scrollBox
    local sBoxMeta = qList.userData.scrollBoxMeta
    sBoxMeta:clearContent()

    local content = sBoxMeta:getMainFlex().content

    ---@type table<string, questGuider.playerQuest.storageQuestData>
    local questData = self.storageTypeQuestData or playerQuests.getStorageData().questData

    local finishedSubVal = 200000000000
    local disabledSubVal = 100000000000
    local function compareFunc(a, b)
        local aVal = a.timestamp or 0
        aVal = a.finished and aVal - finishedSubVal
            or a.disabled and aVal - disabledSubVal or aVal
        local bVal = b.timestamp or 0
        bVal = b.finished and bVal - finishedSubVal
            or b.disabled and bVal - disabledSubVal or bVal
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

    local showFinished = self:getQuestListFinishedCheckBox().userData.checked
    local showHidden = self:getQuestListHiddenCheckBox().userData.checked

    local disabledColor = config.data.ui.disabledColor
    local finishedColor = config.data.ui.disabledColor

    for _, dt in pairs(sortedData) do
        if dt.disabled and not showHidden
                or dt.finished and not showFinished then
            goto continue
        end

        if params.isQuestList and (not dt.name or dt.name == "") then
            goto continue
        end

        if self.textFilter ~= "" and not hasText(dt, self.textFilter) then
            goto continue
        end

        local qName = dt.name or ""

        local qNameText = qName == "" and l10n("miscellaneous") or qName or "???"

        if dt.finished or dt.disabled then
            qNameText = string.format("(%s%s) %s",
                dt.finished and l10n("finishedLabel") or "",
                dt.disabled and l10n("hiddenLabel") or "",
                qNameText
            )
        end

        local flagsContent = ui.content{}
        self:_addFlags(flagsContent, dt)

        if (I.SSQN and config.data.journal.ssqnIcons) then
            local diaId = (dt.list[1] or {}).diaId

            if diaId then
                local iconPath = I.SSQN.getQIcon(diaId)

                if not vfs.fileExists(iconPath) then
                    iconPath = "Icons/SSQN/DEFAULT.dds"
                end

                flagsContent:add(interval(self.params.fontSize / 4, 1))
                flagsContent:add{
                    type = ui.TYPE.Image,
                    props = {
                        size = util.vector2(self.params.fontSize - 2, self.params.fontSize - 2),
                        resource = ui.texture{ path = iconPath },
                    }
                }
            end
        end

        local qListScrollBox = self:getQuestList()
        ---@type questGuider.ui.scrollBox
        local qListScrollBoxMeta = qListScrollBox.userData.scrollBoxMeta

        local textColor = dt.disabled and disabledColor or dt.finished and finishedColor or config.data.ui.defaultColor

        content:add{
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
                -- size = util.vector2(sBoxMeta.innnerSize.x, self.params.fontSize),
                horizontal = true,
                propagateEvents = false,
            },
            name = qName,
            userData = {
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
                    end
                end),
            },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = {
                        autoSize = true,
                        horizontal = true,
                        alpha = (dt.finished or dt.disabled) and 0.5 or 1,
                    },
                    content = flagsContent,
                },
                interval(params.fontSize / 4, 1),
                {
                    template = templates.textNormal,
                    type = ui.TYPE.Text,
                    props = {
                        text = uiUtils.colorize(qNameText, self.textFilter, "#"..config.data.ui.selectionColor:asHex(), "#"..textColor:asHex()),
                        textSize = params.fontSize or 18,
                        textColor = textColor,
                        multiline = false,
                        wordWrap = false,
                        textAlignH = ui.ALIGNMENT.Start,
                    },
                }
            }
        }

        ::continue::
    end

    local height = #content * (params.fontSize or 18)
    local scrollPos = sBoxMeta:getScrollPosition()
    local scrollElemHeight = sBoxMeta.params.size.y
    if scrollPos > height then
        sBoxMeta:setScrollPositiom(math.max(0, height - scrollElemHeight))
    end
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
---@field showOnlyFirst boolean?
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

    meta.textFilter = ""

    meta.storageTypeQuestData = params.questList and playerQuests.generateStorageQuestDataByDiaIdList(params.questList)

    local mainHeader = {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(params.size.x, params.fontSize * 1.5),
        },
        userData = {},
        content = ui.content{
            {
                template = templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text = params.headerName and params.headerName or l10n("journal"),
                    textSize = params.fontSize * 1.5,
                    autoSize = true,
                    textColor = config.data.ui.defaultColor,
                    textShadow = true,
                    textShadowColor = config.data.ui.shadowColor,
                },
                userData = {},
                events = {
                    mousePress = async:callback(function(coord, layout)
                        layout.userData.contentBackup = meta:getQuestMain().content
                        meta:getQuestMain().content = ui.content{}

                        layout.userData.doDrag = true
                        local screenSize = uiUtils.getScaledScreenSize()
                        layout.userData.lastMousePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)
                    end),

                    mouseRelease = async:callback(function(_, layout)
                        local relativePos = meta.menu.layout.props.relativePosition
                        config.setValue("journal.position.x", relativePos.x * 100)
                        config.setValue("journal.position.y", relativePos.y * 100)
                        layout.userData.lastMousePos = nil

                        meta:getQuestMain().content = layout.userData.contentBackup
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
                }
            },
            {
                template = templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text = l10n("close"),
                    textSize = params.fontSize * 1.25,
                    autoSize = true,
                    anchor = util.vector2(1, 1),
                    relativePosition = util.vector2(1, 1),
                    textColor = config.data.ui.defaultColor,
                    textShadow = true,
                    textShadowColor = config.data.ui.shadowColor,
                },
                userData = {},
                events = {
                    mouseRelease = async:callback(function(_, layout)
                        if params.onClose then params.onClose() end
                        meta.menu:destroy()
                    end),
                }
            },
        },
    }

    local questListSize = util.vector2(params.size.x * config.data.journal.listRelativeSize * 0.01, params.size.y)
    local searchBar
    searchBar = {
        type = ui.TYPE.Container,
        props = {
            autoSize = false,
            size = util.vector2(questListSize.x, params.fontSize)
        },
        content = ui.content {
            {
                template = templates.box,
                props = {
                    position = util.vector2(2, 2),
                    anchor = util.vector2(0, 0),
                },
                content = ui.content {
                    {
                        template = templates.textEditLine,
                        props = {
                            autoSize = false,
                            textSize = params.fontSize,
                            size = util.vector2(params.size.x * 0.2, params.fontSize + 5),
                            textColor = config.data.ui.defaultColor,
                        },
                        events = {
                            textChanged = async:callback(function(text, layout)
                                meta.textFilter = text
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
                                        questBoxMeta:updateColors()
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
                position = util.vector2(questListSize.x - 2, 3),
                anchor = util.vector2(1, 0),
                event = function (layout)
                    local selectedQuest = meta:getQuestListSelectedFladValue()
                    meta:fillQuestsContent()
                    meta:selectQuest(selectedQuest)

                    local qBox = meta:getQuestScrollBox()
                    if qBox then
                        ---@type questGuider.ui.questBoxMeta
                        local questBoxMeta = meta:getQuestScrollBox().userData.questBoxMeta
                        questBoxMeta:updateColors()
                    end
                end
            },
        }
    }

    local checkBoxes = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = true,
        },
        content = ui.content {
            checkBox{
                updateFunc = function ()
                    meta:update()
                end,
                checked = localStorage.data.finishedCheckBox and true or false,
                text = l10n("finished"),
                textSize = params.fontSize or 18,
                event = function (checked, layout)
                    local selectedQuest = meta:getQuestListSelectedFladValue()
                    meta:fillQuestsContent()
                    meta:selectQuest(selectedQuest)
                    localStorage.data.finishedCheckBox = checked
                end
            },
            interval(params.fontSize / 2, 0),
            checkBox{
                updateFunc = function ()
                    meta:update()
                end,
                checked = localStorage.data.hiddenCheckBox and true or false,
                text = l10n("hidden"),
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

    local questsContent = ui.content{}

    local questListBox = scrollBox{
        updateFunc = updateFunc,
        size = util.vector2(questListSize.x - 2, questListSize.y - params.fontSize * 2 - 13),
        scrollAmount = params.size.y / 5,
        content = questsContent
    }

    local questList = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = questListSize
        },
        content = ui.content {
            searchBar,
            checkBoxes,
            questListBox,
        }
    }


    local questInfoSize = util.vector2(params.size.x * (1 - config.data.journal.listRelativeSize * 0.01), params.size.y)
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
        layer = "Windows",
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
        }
    }

    meta.menu = ui.create(mainFlex)

    meta:fillQuestsContent()

    return meta
end


return create