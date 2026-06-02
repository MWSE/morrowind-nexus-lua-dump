local translations = require("tauer.dynamic-conversations.services.translations.translations")
local guiBuilder = require("tauer.dynamic-conversations.services.gui.guiBuilder")
local historyListView = require("tauer.dynamic-conversations.services.mcm.history.historyListView")
local conversationHistory = require("tauer.dynamic-conversations.services.conversations.conversationHistoryController")

local TRANSLATION_KEY = require("tauer.dynamic-conversations.services.translations.enums.TRANSLATION_KEY")
local ID = require("tauer.dynamic-conversations.services.mcm.enums.ID")
local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")

---@class conversationHistoryPage : mcmPage
local this = {}

---@public
---@param template mwseMCMTemplate
function this.initialize(template)
    local page = template:createPage({
        label = translations.get(TRANSLATION_KEY.conversationHistoryTitleLabel),
        inGameOnly = true,
    })

    page.createInnerContainer = this.buildPage
end

---@private
---@param self mwseMCMPage
---@param parentBlock tes3uiElement
function this.buildPage(self, parentBlock)
    local root = this.createRoot(parentBlock)

    historyListView.build(root)

    this.createClearSection(root)

    self.elements.innerContainer = root
end

---@private
---@param parentBlock tes3uiElement
function this.createRoot(parentBlock)
    local root = guiBuilder.createBlock({
            parent = parentBlock,
        })
        :withFlowDirection(tes3.flowDirection.topToBottom)
        :withAutoHeight()
        :withPadding({ all = 5 })
        :withProportional({ width = 1.0 })
        :build()

    local _ = guiBuilder.createLabel({
            parent = root,
        })
        :withText(translations.get(TRANSLATION_KEY.conversationHistoryDescription))
        :withBorder({ top = 5, bottom = 5 })
        :build()

    local _ = guiBuilder.createBlock({
            parent = root,
            id = ID.conversationHistoryInnerContainer,
        })
        :withFlowDirection(tes3.flowDirection.leftToRight)
        :withAutoHeight()
        :withChildAlignment({ x = 0.5 })
        :withProportional({ width = 0.99 })
        :build()

    return root
end

---@private
---@param root tes3uiElement
function this.createClearSection(root)
    local _ = guiBuilder.createLabel({
            parent = root,
        })
        :withText(translations.get(TRANSLATION_KEY.clearConversationHistoryLabel))
        :withBorder({ top = 5, bottom = 5 })
        :build()

    local _ = guiBuilder.createButton({
            parent = root,
        })
        :withText(translations.get(TRANSLATION_KEY.clearConversationHistoryButton))
        :withUICallback(tes3.uiEvent.mouseClick, this.onClearHistoryClicked)
        :withBorder({ top = 5, bottom = 5 })
        :withWidgetColors({
            idle = tes3ui.getPalette(tes3.palette.healthColor),
        })
        :build()
end

---@private
function this.onClearHistoryClicked()
    tes3ui.showMessageMenu {
        message = translations.get(TRANSLATION_KEY.clearConversationHistoryConfirmation),
        buttons = {
            { text = translations.get(TRANSLATION_KEY.yesButton), callback = this.onClearHistoryConfirmed },
            { text = translations.get(TRANSLATION_KEY.noButton) }
        }
    }
end

---@private
function this.onClearHistoryConfirmed()
    conversationHistory:clear()
    event.trigger(EVENTS.conversationHistoryDeleted)
end

return this
