local self = require('openmw.self')
local types = require('openmw.types')
local slot = types.Actor.EQUIPMENT_SLOT

local achievements = require('scripts.omw_achievements.achievements.achievements')

local function onActivated(actor)
    for i = 1, #achievements do

        --- Check for unique achievement "Where Did You Get That?"
        if achievements[i].type == "unique" then

            if achievements[i].id == "ordinator_01" and string.find(self.object.recordId, "ordinator") then
                if (types.Actor.getEquipment(actor, slot.Cuirass) ~= nil and types.Actor.getEquipment(actor, slot.Cuirass).recordId == "indoril cuirass") or
                (types.Actor.getEquipment(actor, slot.Helmet) ~= nil and types.Actor.getEquipment(actor, slot.Helmet).recordId == "indoril helmet")
                then
                    actor:sendEvent('gettingAchievement', achievements[i])
                end
            end

        end
    end
end

return {
    engineHandlers = {
        onActivated = onActivated
    }
}