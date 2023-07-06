local ui = require('openmw.ui')

return {
    eventHandlers = {
        momw_af_containers_inform = function (s)
            ui.showMessage(string.format("Your %s been deposited", s))
        end
    }
}
