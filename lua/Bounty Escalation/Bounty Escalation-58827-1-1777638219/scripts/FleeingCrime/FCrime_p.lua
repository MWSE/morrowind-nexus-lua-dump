
local ui = require("openmw.ui")
return {
        engineHandlers = {
        },
        eventHandlers = {
            reportCrimeEvent_FC = function(data)
                local crime = data.crime
                if crime == "fleeingCrime" then
                  ui.showMessage("You have evaded arrest. Your bounty has increased.")
                end
            end
        },
}