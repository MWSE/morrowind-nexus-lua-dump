local self = require 'openmw.self'
local types = require 'openmw.types'

local getEquipment = function()
    return types.Actor.equipment and types.Actor.equipment(self) or types.Actor.getEquipment(self)
end
local SLOT = types.Actor.EQUIPMENT_SLOT
local setEquipment = types.Actor.setEquipment
local equipment = getEquipment()
local cleft = equipment[SLOT.CarriedLeft]
local cright = equipment[SLOT.CarriedRight]

return {
    engineHandlers = {
        onUpdate = function(dt)

        end,
        onActive = function()
            equipment = getEquipment()
            cleft = equipment[SLOT.CarriedLeft]
            cright = equipment[SLOT.CarriedRight]
        end,
        onInactive = function()
            setEquipment(self, equipment)
        end
    },
    eventHandlers = {
        STRIPPED = function(remove)
            if remove then
                setEquipment(self, { [SLOT.CarriedLeft] = cleft, [SLOT.CarriedRight] = cright })
            else
                setEquipment(self, equipment)
            end
        end
    }
}
