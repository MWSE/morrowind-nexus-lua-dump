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

local stringLib = require("scripts.quest_guider_lite.utils.string")
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


---@class questGuider.ui.topicMenuMeta
local topicMenuMeta = {}
topicMenuMeta.__index = topicMenuMeta

topicMenuMeta.menu = nil


topicMenuMeta.getTopicList = function (self)
    return self.menu.layout.content[2].content[1].content[1].content[3]
end

topicMenuMeta.getSearchBar = function (self)
    return self.menu.layout.content[2].content[1].content[1].content[1]
end

topicMenuMeta.getTopicMain = function (self)
    return self.menu.layout.content[2].content[1]
end

topicMenuMeta.getTopicScrollBox = function (self)
    return self:getTopicMain().content[2]
end

topicMenuMeta.resetTopicListColors = function (self)
    local topicList = self:getTopicList()

    ---@type questGuider.ui.scrollBox
    local topicBoxMeta = topicList.userData.scrollBoxMeta
    local layout = topicBoxMeta:getMainFlex()

    for _, elem in ipairs(layout.content) do
        elem.content[1].props.textShadow = false
    end
end

topicMenuMeta.setTextFilter = function (self, value)
    local searchBar = self:getSearchBar()
    self.textFilter = value or ""
    searchBar.content[1].content[1].props.text = self.textFilter
end

topicMenuMeta.setTopicListSelectedFlad = function (self, value)
    self:getTopicList().userData.selected = value
end

topicMenuMeta.getQuestListSelectedFladValue = function (self)
    return self:getTopicList().userData.selected
end

topicMenuMeta.resetTopicListSelection = function (self)
    self:resetTopicListColors()
    self:setTopicListSelectedFlad(nil)
end

topicMenuMeta.clearTopicInfo = function (self)
    local topicInfoSB = self:getTopicScrollBox()
    if not topicInfoSB then return end

    topicInfoSB.name = nil

    ---@type questGuider.ui.scrollBox
    local sBoxMeta = topicInfoSB.userData.scrollBoxMeta
    if not sBoxMeta then return end
    sBoxMeta:clearContent()
end


topicMenuMeta.addToHistory = function (self, topicId)
    if self.menuHistory[self.menuHistoryIndex] ~= topicId then
        if self.menuHistoryIndex ~= #self.menuHistory then
            for i = self.menuHistoryIndex + 1, #self.menuHistory do
                self.menuHistory[i] = nil
            end
        end

        table.insert(self.menuHistory, topicId)
        self.menuHistoryIndex = #self.menuHistory
    end
end


topicMenuMeta.jumpInHistory = function (self, value)
    local nextTopicId = self.menuHistory[self.menuHistoryIndex + value]
    if not nextTopicId then return end

    self.menuHistoryIndex = self.menuHistoryIndex + value
    self:setTextFilter()
    self:fillTopicsContent()
    self:selectTopic(nextTopicId)
end


topicMenuMeta.selectTopic = function (self, topicId)
    local params = self.params

    local topic = topicId and playerQuests.getTopicData(topicId)
    if topic == nil then
        self:resetTopicListSelection()
        self:clearTopicInfo()
        return
    end

    ---@type questGuider.ui.scrollBox
    local topicListSBMeta = self:getTopicList().userData.scrollBoxMeta
    local qListLayout = topicListSBMeta:getMainFlex()

    local qMainLay = self:getTopicMain()

    local succ, selectedLayout = pcall(function() return qListLayout.content[topicId] end)
    if not succ or not selectedLayout then
        self:clearTopicInfo()
        self:setTopicListSelectedFlad(nil)
        return
    end

    if (selectedLayout.userData.heightInList or 0) < topicListSBMeta:getScrollPosition()
            or (selectedLayout.userData.heightInList or 0) > (topicListSBMeta:getScrollPosition() + topicListSBMeta:getSize().y) then
        topicListSBMeta:setScrollPosition((selectedLayout.userData.heightInList or 0) - topicListSBMeta:getSize().y / 2)
    end

    local function applyTextShadow()
        selectedLayout.content[1].props.textShadow = true
        selectedLayout.content[1].props.textShadowColor = config.data.ui.shadowColor
    end

    if self:getTopicScrollBox() and self:getTopicScrollBox().name == topicId then
        applyTextShadow()
        return
    end

    local headerSize = util.vector2(self.questInfoPanelSize.x - params.fontSize * 0.5 - 6, (params.fontSize or 18) * 2.5)


    local endIndex = #topic.entries
    local nestedTopics = {}

    local function updateTopicText(topicInfoContent, loadMore)
        ---@type questGuider.ui.scrollBox
        local topicSBMeta = self:getTopicScrollBox().userData.scrollBoxMeta
        local mainFlex = topicSBMeta:getMainFlex()

        if not topicInfoContent then
            topicInfoContent = mainFlex.content
        end

        local success, pcallRes = pcall(function ()
            return topicInfoContent[3]
        end)
        if not success or not pcallRes then return end

        local headerElem = topicInfoContent[1]
        local btnElem = topicInfoContent[3].content[1]
        local textElem = topicInfoContent[4].content[2]
        local buttonFlex = topicInfoContent[2]

        headerElem.props.text = uiUtils.colorize(topic.name, self.textFilter,
            "#"..config.data.ui.selectionColor:asHex(), "#"..config.data.ui.defaultColor:asHex())

        local actorNames = {}

        local textLinks = {}

        local newText = ""

        mainFlex.userData = mainFlex.userData or {}

        if loadMore then
            newText = "\n"

            endIndex = util.clamp(endIndex, 0, #topic.entries)
            local startIndex = math.max(1, endIndex - config.data.journal.maxTopicEntriesInTopicMenu + 1)

            if startIndex == 1 then
                btnElem.props.visible = false
            else
                btnElem.props.visible = true
            end

            for i = startIndex, endIndex do
                local entry = topic.entries[i]
                if not entry then goto continue end

                local topicLinkStrs = stringLib.findTextLinks(entry.text)
                for _, str in pairs(topicLinkStrs) do
                    textLinks[str] = true
                end

                local entryText = stringLib.removeSpecialCharactersFromJournalText(entry.text) or ""
                table.insert(actorNames, entry.actor)
                newText = string.format("%s\t\t____ID_%s____: \"%s\"\n\n",
                    newText,
                    tostring(#actorNames),
                    entryText
                )

                ::continue::
            end

            endIndex = util.clamp(endIndex - config.data.journal.maxTopicEntriesInTopicMenu, 0, #topic.entries)

            if next(textLinks) then
                for str, _ in pairs(textLinks) do
                    for _, tp in pairs(playerQuests.getTopicList()) do

                        if not nestedTopics[tp.id] then
                            for _, name in pairs(actorNames) do
                                if stringLib.fuzzyTopicSearch(tp.id, stringLib.utf8_lower(name)) then
                                    if not nestedTopics[tp.id] then nestedTopics[tp.id] = {topic = tp, nameLen = stringLib.length(tp.id), patterns = {}} end
                                end
                            end
                        end

                        if (not nestedTopics[tp.id] or not nestedTopics[tp.id].patterns[str])
                                and stringLib.fuzzyTopicSearch(str, tp.id) then
                            if not nestedTopics[tp.id] then nestedTopics[tp.id] = {topic = tp, nameLen = stringLib.length(tp.id), patterns = {}} end
                            nestedTopics[tp.id].patterns[str] = true
                        end

                    end
                end
            else
                local textLower = stringLib.utf8_lower(newText)
                for _, tp in pairs(playerQuests.getTopicList()) do

                    if not nestedTopics[tp.id] then
                        for _, name in pairs(actorNames) do
                            if stringLib.fuzzyTopicSearch(tp.id, stringLib.utf8_lower(name)) then
                                if not nestedTopics[tp.id] then nestedTopics[tp.id] = {topic = tp, nameLen = stringLib.length(tp.id), patterns = {}} end
                            end
                        end
                    end

                    if (not nestedTopics[tp.id] or not nestedTopics[tp.id].patterns[tp.name])
                            and stringLib.hasPhrase(textLower, tp.id) then
                        if not nestedTopics[tp.id] then nestedTopics[tp.id] = {topic = tp, nameLen = stringLib.length(tp.id), patterns = {}} end
                        nestedTopics[tp.id].patterns[tp.name] = true
                    end

                end
            end
        end

        local newTextHeight = uiUtils.getTextHeight(newText, params.fontSize, headerSize.x, config.data.journal.textHeightMulRecord, 1, true)
        newTextHeight = math.max(0, newTextHeight - 2 * params.fontSize)

        local oldSize = textElem.props.size
        local newTextElemSize = util.vector2(headerSize.x, oldSize.y + newTextHeight)

        textElem.props.size = newTextElemSize

        local textLen = stringLib.length(newText)

        buttonFlex.content = ui.content{}

        local buttonFlexYPos = 0

        if next(nestedTopics) then

            local nestedTopicsList = tableLib.values(nestedTopics, function (a, b)
                return (a.nameLen > b.nameLen)
            end)

            local patColor = "#"..config.data.ui.linkColor:asHex()
            local patterns = {}
            for _, topicData in ipairs(nestedTopicsList) do
                for pattern, _ in pairs(topicData.patterns) do
                    patterns[pattern] = {pattern = pattern, color = patColor}
                end
            end

            newText = uiUtils.colorizeNestedMulti(newText, tableLib.values(patterns),
                    "#"..config.data.ui.defaultColor:asHex())

            table.sort(nestedTopicsList, function (a, b)
                return a.topic.id < b.topic.id
            end)

            local buttonLineData = {}
            local function placeButtons()
                if not next(buttonLineData) then return end

                local currentStep = params.fontSize * 0.25
                local step = (newTextElemSize.x - currentStep * 2) / #buttonLineData

                for _, topicData in ipairs(buttonLineData) do
                    local topicText = topicData.topic.name

                    buttonFlex.content:add(
                        button{
                            updateFunc = function ()
                                self:update()
                            end,
                            text = topicText,
                            textSize = params.fontSize,
                            anchor = util.vector2(0.5, 0),
                            position = util.vector2(currentStep + step / 2, buttonFlexYPos),
                            parentScrollBoxUserData = self:getTopicScrollBox().userData,
                            userData = {
                                topicId = topicData.topic.id
                            },
                            event = function (layout)
                                self:addToHistory(topicData.topic.id)
                                self:setTextFilter()
                                self:fillTopicsContent()
                                self:selectTopic(layout.userData.topicId)
                            end
                        }
                    )

                    currentStep = currentStep + step
                end

                buttonFlexYPos = buttonFlexYPos + params.fontSize * 1.5
            end

            local maxBtnWidt = 0
            local maxBlockWidth = newTextElemSize.x - params.fontSize * 0.5
            for _, topicData in ipairs(nestedTopicsList) do
                local topicText = topicData.topic.name

                if topicText ~= topic.name then
                    local count = #buttonLineData
                    local textLen = stringLib.length(topicText)
                    local btnWidth = textLen * config.data.journal.textHeightMulRecord * params.fontSize
                    local maxWidth = math.max(maxBtnWidt, btnWidth)

                    if (count * maxWidth) + maxWidth < maxBlockWidth or count == 0 then
                        table.insert(buttonLineData, topicData)
                    else
                        placeButtons()
                        buttonLineData = {}
                        table.insert(buttonLineData, topicData)
                    end

                    maxBtnWidt = maxWidth
                end
            end

            placeButtons()
        end

        local function replace_ids(str, tbl)
            return (str:gsub("____ID_(%d+)____", function(idx)
                idx = tonumber(idx)
                return string.format("#%s%s#%s", config.data.ui.objectColor:asHex(), tbl[idx] or "", config.data.ui.defaultColor:asHex())
            end))
        end

        newText = replace_ids(newText, actorNames)

        buttonFlex.props.size = util.vector2(newTextElemSize.x, buttonFlexYPos)

        if self.textFilter ~= "" then
            newText = uiUtils.colorizeNested(newText, self.textFilter,
                "#"..config.data.ui.selectionColor:asHex(), "#"..config.data.ui.defaultColor:asHex())
        end

        textElem.props.text = newText..textElem.props.text
    end


    local topicContent
    topicContent = ui.content{
        {
            type = ui.TYPE.Text,
            props = {
                text = nil,
                textColor = config.data.ui.defaultColor,
                autoSize = false,
                size = headerSize,
                textSize = (params.fontSize or 18) * 1.25,
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
            },
        },
        {
            type = ui.TYPE.Widget,
            props = {
                autoSize = false,
            },
            content = ui.content{},
        },
        {
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(headerSize.x, params.fontSize * 2 + 8),
            },
            content = ui.content{
                button{
                    updateFunc = function ()
                        self:update()
                    end,
                    text = l10n("ellipsis"),
                    textSize = self.params.fontSize,
                    visible = false,
                    anchor = util.vector2(0.5, 1),
                    position = util.vector2(headerSize.x / 2, params.fontSize * 2 + 8),
                    event = function (layout)
                        updateTopicText(nil, true)
                        qMainLay.content[2].userData.scrollBoxMeta:setContentHeight(uiUtils.getContentHeight(topicContent))
                    end
                },
            },
        },
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
                horizontal = true,
            },
            content = ui.content{
                interval(params.fontSize * 0.25, 0),
                {
                    type = ui.TYPE.Text,
                    props = {
                        text = "",
                        textColor = config.data.ui.defaultColor,
                        autoSize = false,
                        size = util.vector2(headerSize.x, params.fontSize),
                        position = util.vector2(params.fontSize * 0.25, 0),
                        textSize = params.fontSize,
                        multiline = true,
                        wordWrap = true,
                        -- textAlignH = ui.ALIGNMENT.Center,
                    },
                },
            },
        },
    }


    qMainLay.content[2] = scrollBox{
        updateFunc = function ()
            self.menu:update()
        end,
        size = self.questInfoPanelSize,
        scrollAmount = self.params.size.y / 5,
        userData = {
            updateText = updateTopicText,
        },
        content = topicContent,
        contentHeight = 0,
    }

    updateTopicText(topicContent, true)

    qMainLay.content[2].userData.scrollBoxMeta:setContentHeight(uiUtils.getContentHeight(topicContent))

    self:resetTopicListSelection()
    self:setTopicListSelectedFlad(topicId)
    applyTextShadow()

    self:update()
end


topicMenuMeta.update = function(self)
    self.menu:update()
end


---@param topicData questGuider.PlayerJournalTopic
---@param text string
---@return boolean
local function hasText(topicData, text)
    text = stringLib.utf8_lower(text)
    if topicData.id:find(text, 1, true) then
        return true
    end

    for _, dt in pairs(topicData.entries) do
        if stringLib.utf8_lower(dt.text):find(text, 1, true) then return true end
        if stringLib.utf8_lower(dt.actor):find(text, 1, true) then return true end
    end

    return false
end


function topicMenuMeta.fillTopicsContent(self)
    local params = self.params

    local qList = self:getTopicList()
    ---@type questGuider.ui.scrollBox
    local sBoxMeta = qList.userData.scrollBoxMeta
    sBoxMeta:clearContent()

    local content = sBoxMeta:getMainFlex().content

    local topicData = playerQuests.getTopicList()

    ---@type questGuider.PlayerJournalTopic[]
    local sortedData = tableLib.values(topicData, function (a, b)
        return (stringLib.utf8_lower(a.id or "") < stringLib.utf8_lower(b.id or ""))
    end)

    local heightInList = 0
    for _, dt in pairs(sortedData) do

        if self.textFilter ~= "" and not hasText(dt, self.textFilter) then
            goto continue
        end

        local topicName = dt.name or "???"

        local topicListSB = self:getTopicList()
        ---@type questGuider.ui.scrollBox
        local topicListSBMeta = topicListSB.userData.scrollBoxMeta

        local textColor = config.data.ui.defaultColor

        local contentData
        contentData = {
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
                -- size = util.vector2(sBoxMeta.innnerSize.x, self.params.fontSize),
                horizontal = true,
                propagateEvents = false,
            },
            name = dt.id,
            userData = {
                topicName = topicName,
                topicData = dt,
                heightInList = heightInList,
            },
            events = {
                mousePress = async:callback(function(e, layout)
                    topicListSBMeta:mousePress(e)
                end),

                focusLoss = async:callback(function(e, layout)
                    topicListSBMeta:focusLoss(e)
                end),

                mouseMove = async:callback(function(e, layout)
                    topicListSBMeta:mouseMove(e)
                end),

                mouseRelease = async:callback(function(e, layout)
                    if e.button ~= 1 then return end

                    topicListSBMeta:mouseRelease(e)

                    if topicListSBMeta.lastMovedDistance < 30 then
                        self:addToHistory(dt.id)
                        self:fillTopicsContent()
                        self:selectTopic(dt.id)
                    end
                end),
            },
            content = ui.content {
                {
                    template = templates.textNormal,
                    type = ui.TYPE.Text,
                    props = {
                        text = uiUtils.colorize(topicName, self.textFilter, "#"..config.data.ui.selectionColor:asHex(), "#"..textColor:asHex()),
                        textSize = params.fontSize or 18,
                        textColor = textColor,
                        multiline = false,
                        wordWrap = false,
                        textAlignH = ui.ALIGNMENT.Start,
                    },
                }
            }
        }

        content:add(contentData)

        heightInList = heightInList + params.fontSize

        ::continue::
    end

    local height = #content * (params.fontSize or 18)
    sBoxMeta:setContentHeight(height)
    local scrollPos = sBoxMeta:getScrollPosition()
    local scrollElemHeight = sBoxMeta.params.size.y
    if scrollPos > height then
        sBoxMeta:setScrollPosition(math.max(0, height - scrollElemHeight))
    end
end


---@class questGuider.ui.topicMenu.params
---@field menuId string?
---@field size any
---@field sizeProportional any
---@field fontSize integer?
---@field relativePosition any?
---@field headerName string?
---@field onClose function?

---@param params questGuider.ui.topicMenu.params
local function create(params)

    params.fontSize = params.fontSize or 18

    ---@class questGuider.ui.topicMenuMeta
    local meta = setmetatable({}, topicMenuMeta)

    local function updateFunc()
        if not meta.menu then return end
        meta:update()
    end

    if not params.size then
        local scaledScreenSize = uiUtils.getScaledScreenSize()
        params.size = util.vector2(scaledScreenSize.x * params.sizeProportional.x, scaledScreenSize.y * params.sizeProportional.y)
    end

    if not params.menuId then
        params.menuId = params.headerName and params.headerName or commonData.topicsMenuId
    end

    meta.params = params

    meta.textFilter = ""

    meta.menuHistory = {}
    meta.menuHistoryIndex = 0


    local topicInfoSize = util.vector2(params.size.x * (1 - config.data.journal.listRelativeSize * 0.01), params.size.y)
    meta.questInfoPanelSize = topicInfoSize
    local topicInfo = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = topicInfoSize,
        },
        userData = {
            size = topicInfoSize,
        },
        content = ui.content {

        }
    }

    local mainHeader = {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(params.size.x + 6, params.fontSize * 1.5),
        },
        userData = {},
        events = {
            mousePress = async:callback(function(coord, layout)
                layout.userData.contentBackup = meta:getTopicScrollBox()
                meta:getTopicMain().content[2] = topicInfo

                layout.userData.doDrag = true
                local screenSize = uiUtils.getScaledScreenSize()
                layout.userData.lastMousePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)
            end),

            mouseRelease = async:callback(function(_, layout)
                local relativePos = meta.menu.layout.props.relativePosition
                config.setValue("journal.topic.position.x", relativePos.x * 100)
                config.setValue("journal.topic.position.y", relativePos.y * 100)
                layout.userData.lastMousePos = nil

                meta:getTopicMain().content[2] = layout.userData.contentBackup
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
                    color = config.data.ui.backgroundColor,
                    alpha = config.data.ui.headerBackgroundAlpha / 100,
                }
            },
            {
                template = templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text = params.headerName and params.headerName or l10n("topics"),
                    textSize = params.fontSize * 1.5,
                    autoSize = true,
                    textColor = config.data.ui.defaultColor,
                    textShadow = true,
                    textShadowColor = config.data.ui.shadowColor,
                },
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
                    propagateEvents = false,
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

    local topictListSize = util.vector2(params.size.x * config.data.journal.listRelativeSize * 0.01, params.size.y)
    local searchBar
    searchBar = {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = util.vector2(topictListSize.x, params.fontSize + 10)
        },
        content = ui.content {
            {
                template = templates.box,
                props = {
                    position = util.vector2(2, (params.fontSize + 10) / 2),
                    anchor = util.vector2(0, 0.5),
                },
                content = ui.content {
                    {
                        template = templates.textEditLine,
                        props = {
                            autoSize = false,
                            textSize = params.fontSize,
                            size = util.vector2(params.size.x * 0.2, params.fontSize + 4),
                            textColor = config.data.ui.defaultColor,
                        },
                        events = {
                            textChanged = async:callback(function(text, layout)
                                meta.textFilter = text
                            end),
                            keyRelease = async:callback(function(e, layout)
                                if e.code == input.KEY.Enter then
                                    local selectedTopic = meta:getQuestListSelectedFladValue()
                                    meta:fillTopicsContent()
                                    meta:selectTopic(selectedTopic)
                                    searchBar.content[1].content[1].props.text = meta.textFilter

                                    -- local qBox = meta:getTopicScrollBox()
                                    -- if qBox and qBox.userData and qBox.userData.updateText then
                                    --     qBox.userData.updateText()
                                    -- end

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
                position = util.vector2(topictListSize.x - 2, (params.fontSize + 10) / 2),
                anchor = util.vector2(1, 0.5),
                event = function (layout)
                    local selectedTopic = meta:getQuestListSelectedFladValue()
                    meta:fillTopicsContent()
                    meta:selectTopic(selectedTopic)

                    -- local qBox = meta:getTopicScrollBox()
                    -- if qBox and qBox.userData and qBox.userData.updateText then
                    --     qBox.userData.updateText()
                    -- end
                end
            },
        }
    }

    local nextPrevBlock = {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = util.vector2(topictListSize.x, params.fontSize + 6 + params.fontSize * 0.5)
        },
        content = ui.content {
            button{
                updateFunc = function ()
                    meta:update()
                end,
                text = l10n("previous"),
                textSize = params.fontSize,
                anchor = util.vector2(0.5, 0),
                position = util.vector2(topictListSize.x * 0.25, params.fontSize * 0.25),
                event = function (layout)
                    meta:jumpInHistory(-1)
                end
            },
            button{
                updateFunc = function ()
                    meta:update()
                end,
                text = l10n("next"),
                textSize = params.fontSize,
                anchor = util.vector2(0.5, 0),
                position = util.vector2(topictListSize.x * 0.75, params.fontSize * 0.25),
                event = function (layout)
                    meta:jumpInHistory(1)
                end
            }
        }
    }

    local topicsContent = ui.content{}

    local topicListBox = scrollBox{
        updateFunc = updateFunc,
        size = util.vector2(topictListSize.x - 2, topictListSize.y - params.fontSize * 2.5 - 16),
        scrollAmount = params.size.y / 5,
        content = topicsContent,
        contentHeight = 0,
    }

    local topicList = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = topictListSize
        },
        content = ui.content {
            searchBar,
            nextPrevBlock,
            topicListBox,
        }
    }


    local mainWindow = {
        template = customTemplates.boxSolidThick,
        props = {

        },
        events = {
            focusLoss = async:callback(function(e, layout)
                meta.inFocus = false
            end),

            mouseMove = async:callback(function(e, layout)
                meta.inFocus = true
            end),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = true,
                },
                content = ui.content {
                    topicList,
                    topicInfo
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

    meta:fillTopicsContent()

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

    meta.onMouseClick = function (self, buttonId)
        ---@diagnostic disable-next-line: need-check-nil
        if not meta.inFocus and not topicListBox.userData.inFocus
                and (topicInfo.content[1] and not topicInfo.content[1].userData.inFocus) then
            return
        end
        if buttonId == 4 then
            self:jumpInHistory(-1)
        elseif buttonId == 5 then
            self:jumpInHistory(1)
        end
    end

    return meta
end


return create