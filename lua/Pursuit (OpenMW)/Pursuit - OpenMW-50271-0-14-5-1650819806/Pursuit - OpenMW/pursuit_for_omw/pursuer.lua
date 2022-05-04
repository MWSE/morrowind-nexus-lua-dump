local self = require("openmw.self")
local time = require("openmw_aux.time")
local nearby = require("openmw.nearby")
local core = require("openmw.core")
local ai = require('openmw.interfaces').AI
local types = require('openmw.types')
local oricell
local oripos
local combatTarget

local function savePos_eqnx()
    oricell = oricell or self.cell.name
    oripos = oripos or self.position
end

time.runRepeatedly(
    function()
        if not ai.getActiveTarget('Combat') then
            combatTarget = nil
            return
        end
        if not types.Actor.canMove(ai.getActiveTarget('Combat')) then
            return
        end

        combatTarget = ai.getActiveTarget('Combat')

        if ai.getActiveTarget('Combat').type ~= types.Player then
            ai.getActiveTarget('Combat'):sendEvent("Pursuit_pursuerData_eqnx", self)
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
			local back = false
			ai.forEachPackage(
			function(package)
				if (package.type == "Follow" or package.type == "Escort") then
					back = true
					return
				end
			end
			)
			if back then return end
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
