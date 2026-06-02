---@meta

--- Provides a structure for defining callbacks executed upon conversation completion
---@class conversationCallback
---@field public execute fun(data:conversationCallbackData)

--- Data passed to conversation callbacks upon execution
---@class conversationCallbackData
---@field public conversation conversation The conversation that has completed
