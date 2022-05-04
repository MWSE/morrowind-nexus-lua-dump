local self = require("openmw.self")
local ai = require('openmw.interfaces').AI
local types = require("openmw.types")
local target

return {
    engineHandlers = {
        onInactive = function()
            --cellchanged event is better(not implemented yet)
            if not target or not types.Actor.canMove(target) or not target:isValid() then
                return
            end
            if not (self.cell.isExterior or self.cell == target.cell) then
                return
            end
            if (target.position - self.position):length() > (self.cell.isExterior and 8192 / 5 or 8192) then
                ai.removePackages("Combat")
                target = nil
            end
        end
    },
    eventHandlers = {
        ProtectiveGuards_alertGuard_eqnx = function(attacker)
            if not types.Actor.canMove(self) or not attacker:isValid() then
                return
            end
            ai.startPackage({type='Combat', target=attacker})
            target = ai.getActiveTarget('Combat')
        end
    }
}
