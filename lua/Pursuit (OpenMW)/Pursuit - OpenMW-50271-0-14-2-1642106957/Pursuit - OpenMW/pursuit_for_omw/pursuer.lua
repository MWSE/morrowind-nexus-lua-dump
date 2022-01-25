local self = require("openmw.self")
local time = require("openmw_aux.time")
local query = require("openmw.query")
local core = require("openmw.core")
local oricell
local oripos
local combatTarget

local function savePos_eqnx()
    oricell = oricell or self.cell.name
    oripos = oripos or self.position
end

time.runRepeatedly(
    function()
        if not self:getCombatTarget() then
            combatTarget = nil
            return
        end
        if not self:getCombatTarget():canMove() then
            return
        end

        --getCombatTarget() always return nil when it is inactive (NOTE: player is always 'active')
        combatTarget = self:getCombatTarget()

        if self:getCombatTarget().type ~= "Player" then
            self:getCombatTarget():sendEvent("Pursuit_pursuerData_eqnx", self)
        end
    end,
    0.1 * time.second
)

return {
    engineHandlers = {
        onLoad = function(data)
            if data then
                oricell, oripos = unpack(data)
            end
        end,
        onSave = function()
            return {oricell, oripos}
        end,
        onInactive = function()
            savePos_eqnx()
            core.sendGlobalEvent("Pursuit_returnToCell_eqnx", {self, oricell, nil, oripos})
        end,
        onActive = function()
            savePos_eqnx()
        end
    },
    eventHandlers = {
        Pursuit_savePos_eqnx = savePos_eqnx
    }
}
