local self = require("openmw.self")
local nearby = require("openmw.nearby")
local query = require("openmw.query")
local aux = require("openmw_aux.util")
local core = require("openmw.core")
local functions = require("protective_guards_for_omw.functions")
local timer = 0
local target

local function updateCombat(dt)


    if timer < 2.67 then
        timer = timer + dt
        return
    else
        timer = 0
    end
	target = nil
    if not self:getCombatTarget() then return end
    if (self.cell.isExterior or self.cell ~= self:getCombatTarget().cell) and
        (self:getCombatTarget().position - self.position):length() > 4096
    then
        self:stopCombat()
    end



end


local function attack(data)

    local attacker = unpack(data)

    if not self:canMove() or not attacker:isValid() then
        self:stopCombat()
        return
    end

    if attacker ~= target then
        self:startCombat(attacker)
        target = attacker
    end

end

return {
    engineHandlers = {
        onUpdate = updateCombat,
        onInactive = function() target = nil end
    },
    eventHandlers = {
        ProtectiveGuards_alertGuard_eqnx = attack,
    }
}










