---@enum ID
local this = {
    conversationHistoryInnerContainer = "ConversationHistory_InnerContainer",
    conversationHistoryListBlock = "ConversationHistory_ScrollPane_Block",
    conversationHistoryDetailsBorder = "ConversationHistory_DetailsBorder",
    conversationHistoryDetailsBlock = "ConversationHistory_Details_ScrollPane_Block",
    conversationHistoryDetailsDialogBlock = "ConversationHistory_Details_DialogBlock",
    conversationHistoryDetailsDialogEntry = function(index)
        return "ConversationHistory_Details_DialogLabel_" .. index
    end,
}

return this
