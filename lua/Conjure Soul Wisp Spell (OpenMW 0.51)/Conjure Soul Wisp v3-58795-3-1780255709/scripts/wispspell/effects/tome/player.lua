local ui = require('openmw.ui')

return {
    eventHandlers = {
        RT_SoulWispTomeMessage = function(data)
            ui.showMessage((data and data.text) or 'You learn Conjure Soul Wisp.')
        end,
    },
}
