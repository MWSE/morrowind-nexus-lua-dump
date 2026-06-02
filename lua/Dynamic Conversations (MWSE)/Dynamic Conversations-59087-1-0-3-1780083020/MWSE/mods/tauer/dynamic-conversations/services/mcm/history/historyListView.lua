local conversationHistory = require("tauer.dynamic-conversations.services.conversations.conversationHistoryController")
local configurationLoader = require("tauer.dynamic-conversations.services.configurations.configurationLoader")
local guiBuilder = require("tauer.dynamic-conversations.services.gui.guiBuilder")
local historyDetailsView = require("tauer.dynamic-conversations.services.mcm.history.historyDetailsView")

local ID = require("tauer.dynamic-conversations.services.mcm.enums.ID")
local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")

local logger = mwse.Logger.new()

--- Renders a conversation history list in the MCM
---@class historyListView : initializedService
local this = {}

---@private
---@type tes3uiElement
this.root = nil

---@public
---@return boolean
function this.initialize()
    event.register(EVENTS.conversationHistoryDeleted, this.onConversationHistoryDeleted)
    return true
end

--- Builds the conversation history list view
---@public
---@param root tes3uiElement The root UI element of the conversation history MCM page
function this.build(root)
    this.root = root

    this.createListContainer()
    this.createListContents()
end

---@private
function this.createListContainer()
    local inner = this.mustResolveElement(ID.conversationHistoryInnerContainer)
    if not inner then
        return
    end

    local thinBorder = guiBuilder.createThinBorder({
            parent = inner,
        })
        :withBorder({ top = 5, bottom = 5, right = 10 })
        :withMinSize({ width = 0, height = 500 })
        :withProportional({ width = 1.0 })
        :build()

    local scrollPane = guiBuilder.createVerticalScrollPane({
            parent = thinBorder,
        })
        :withAutoSize()
        :build()

    local _ = guiBuilder.createBlock({
            parent = scrollPane,
            id = ID.conversationHistoryListBlock,
        })
        :withFlowDirection(tes3.flowDirection.topToBottom)
        :withProportional({ width = 0.95 })
        :withAutoHeight()
        :build()
end

---@private
function this.createListContents()
    local block = this.mustResolveElement(ID.conversationHistoryListBlock)
    if not block then
        return
    end

    for id, _ in pairs(conversationHistory:getAll()) do
        local configuration = configurationLoader.get(id)
        if configuration then
            local _ = guiBuilder.createTextSelect({
                    parent = block,
                })
                :withText(string.format("%s (%s)", configuration.name, id))
                :withBorder({ all = 5 })
                :withData("configuration", configuration)
                :withUICallback(tes3.uiEvent.mouseClick, this.onHistoryEntryClicked)
                :build()
        end
    end
end

---@private
---@param eventData tes3uiEventData
function this.onHistoryEntryClicked(eventData)
    local configuration = eventData.source:getLuaData("configuration") --[[@as conversationConfiguration|nil]]
    if not configuration then
        return
    end

    this.setAsActive(eventData.source)

    historyDetailsView.build(configuration, this.root)
end

---@private
function this.onConversationHistoryDeleted()
    this.clear()
    this.createListContents()
    this.root:updateLayout()
end

---@private
function this.clear()
    local list = this.tryResolveElement(ID.conversationHistoryListBlock)
    if list then
        list:destroyChildren()
        list:updateLayout()
    end

    local details = this.tryResolveElement(ID.conversationHistoryDetailsBlock)
    if details then
        details:destroyChildren()
        details:updateLayout()
    end
end

---@private
---@param entry tes3uiElement
function this.setAsActive(entry)
    local parent = entry.parent
    for _, child in pairs(parent.children) do
        if child.widget then
            child.widget.state = tes3.uiState.normal
        end
    end

    local widget = entry.widget
    if widget then
        widget.state = tes3.uiState.active
    end
end

---@private
---@param id string
---@return tes3uiElement|nil
function this.tryResolveElement(id)
    return this.root:findChild(id)
end

---@private
---@param id string
---@return tes3uiElement|nil
function this.mustResolveElement(id)
    local element = this.tryResolveElement(id)
    if not element then
        logger:error("UI Element '%s' not found!", id)
    end
    return element
end

return this
