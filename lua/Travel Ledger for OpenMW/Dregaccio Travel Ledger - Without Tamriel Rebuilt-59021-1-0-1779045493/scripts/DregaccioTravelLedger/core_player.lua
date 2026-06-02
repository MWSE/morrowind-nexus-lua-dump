-- Dregaccio Travel Ledger Core player UI helper
local ui = require('openmw.ui')

return {
    eventHandlers = {
        DregaccioTravelLedgerShowMessage = function(data)
            if data and data.text then
                ui.showMessage(data.text, { showInDialogue = false })
            end
        end,
    },
}
