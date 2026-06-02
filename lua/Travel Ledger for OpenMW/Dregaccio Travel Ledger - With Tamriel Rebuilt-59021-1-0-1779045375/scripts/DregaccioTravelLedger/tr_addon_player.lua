-- Dregaccio Travel Ledger TR Addon player UI helper
local types = require('openmw.types')
local self = require('openmw.self')
local ui = require('openmw.ui')


local topicsAdded = false
local function ensureTravelLedgerTopics()
    if topicsAdded then return end
    topicsAdded = true
    pcall(types.Player.addTopic, self.object, 'mainland travel ledger')
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            ensureTravelLedgerTopics()
        end,
    },

    eventHandlers = {
        DregaccioTravelLedgerShowMessage = function(data)
            if data and data.text then
                ui.showMessage(data.text, { showInDialogue = false })
            end
        end,
    },
}