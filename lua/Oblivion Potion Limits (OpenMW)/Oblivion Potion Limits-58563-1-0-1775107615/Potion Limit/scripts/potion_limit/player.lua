local ui = require('openmw.ui')

local function onPotionLimitMessage()
    ui.showMessage('Potion Limit Reached')
end

return {
    eventHandlers = {
        PotionLimit_ShowLimitMessage = onPotionLimitMessage,
    },
}
