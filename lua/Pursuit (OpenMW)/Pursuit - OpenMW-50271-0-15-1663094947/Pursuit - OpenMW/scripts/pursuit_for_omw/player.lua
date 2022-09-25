local core = require('openmw.core')
local ui = require('openmw.ui')
require('scripts/pursuit_for_omw.settings')

if core.API_REVISION < 29 then
	error('Pursuit mod requires a newer version of OpenMW, please update.')
end

return {
    engineHandlers = {
    },
    eventHandlers = {
        Pursuit_Debug_Pursuer_Details_eqnx = function(e)
            ui.showMessage(string.format("%s chases %s from %s to %s", e.actor, e.target, e.actor.cell.name, e.target.cell.name))
        end
    }
}
