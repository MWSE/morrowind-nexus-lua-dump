---@alias L10nFunc fun(key: string, context?: table): string

---@class Messages
---@field show fun(player: any, messageKey: string, context?: table)

---Creates a new Messages instance.
---@param l10n L10nFunc
---@return Messages
local function Messages(l10n)

    ---@param messageKey string
    ---@param context? table
    ---@return string
    local function pickRandomMessage(messageKey, context)
        local messageOptions = {}
        local i = 1
        while true do
            local msgKey = ("%s_%d"):format(messageKey, i)
            local msg = l10n(msgKey, context)
            if msgKey ~= msg then
                messageOptions[#messageOptions + 1] = msg
            else
                break
            end
            i = i + 1
        end
        return messageOptions[math.random(#messageOptions)]
    end

    ---@param player GameObject
    ---@param messageKey string
    ---@param context? table
    local function show(player, messageKey, context)
        local msg = pickRandomMessage(messageKey, context)
        player:sendEvent("ShowMessage", { message = msg })
    end

    return { show = show }
end

return Messages
