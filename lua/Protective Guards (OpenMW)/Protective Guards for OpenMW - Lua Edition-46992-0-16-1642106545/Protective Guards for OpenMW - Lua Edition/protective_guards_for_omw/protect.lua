local self = require("openmw.self")

local target

return {
    engineHandlers = {
        onInactive = function()
            --cellchanged event is better(not implemented yet)
            if not target or not target:canMove() or not target:isValid() then
                return
            end
            if not (self.cell.isExterior or self.cell == target.cell) then
                return
            end
            if (target.position - self.position):length() > (self.cell.isExterior and 8192 / 5 or 8192) then
                self:stopCombat()
                target = nil
            end
        end
    },
    eventHandlers = {
        ProtectiveGuards_alertGuard_eqnx = function(attacker)
            if not self:canMove() or not attacker:isValid() then
                return
            end
            self:startCombat(attacker)
            target = self:getCombatTarget()
        end
    }
}
