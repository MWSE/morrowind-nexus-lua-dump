local core = require('openmw.core')
local MERCHANT_STOCK_DIALOGUE_OPEN_EVENT = 'MerchantStock_DialogueOpen'

local function onUiModeChanged(data)
    if type(data) ~= 'table' then return end
    if data.newMode ~= 'Barter' then return end
    -- Notify the global merchant stock script when barter UI opens for this actor.
    local merchant = data.merchant or data.arg
    core.sendGlobalEvent(MERCHANT_STOCK_DIALOGUE_OPEN_EVENT, { merchant = merchant })
end

return {
    eventHandlers = {
        UiModeChanged = onUiModeChanged,
    },
}
