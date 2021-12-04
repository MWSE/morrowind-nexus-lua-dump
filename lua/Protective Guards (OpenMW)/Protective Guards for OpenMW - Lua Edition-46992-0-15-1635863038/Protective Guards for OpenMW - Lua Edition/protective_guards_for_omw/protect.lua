local self = require("openmw.self")
local aux = require("openmw_aux.util")
local target
local timer

local function stop()
    if not target or not target:isValid() or not target:canMove() then
        timer()
        return
    end
    if (self.cell.isExterior or self.cell == target.cell) and (target.position - self.position):length() > 8192 then
        self:stopCombat()
        timer()
    end
end

local function attack(attacker)
    target = attacker
    if not self:canMove() or not attacker:isValid() then
        return
    end

    self:startCombat(attacker)
    timer = aux.runEveryNSeconds(2, stop)
end

return {
    eventHandlers = {
	ProtectiveGuards_alertGuard_eqnx = attack
	}
}
