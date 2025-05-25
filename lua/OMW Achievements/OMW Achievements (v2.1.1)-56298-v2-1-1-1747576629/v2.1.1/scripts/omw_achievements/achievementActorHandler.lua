local self = require('openmw.self')
local types = require('openmw.types')
local slot = types.Actor.EQUIPMENT_SLOT

local achievements = require('scripts.omw_achievements.achievements.achievements')

local function onActivated(actor)

    for i = 1, #achievements do

        --- Talkto Achievements
        if achievements[i].type == "talkto" then
            if achievements[i].recordId == self.object.recordId then
                if types.Actor.isDead(self.object) ~= true then
                    actor:sendEvent('gettingAchievement', achievements[i])
                end
            end
        end

        --- Unique achievements
        if achievements[i].type == "unique" then

            if achievements[i].id == "killtribunal_01" and self.object.recordId == "vivec_god" then
                if types.Actor.isDead(self.object) == true then
                    actor:sendEvent('vivecIsDead', achievements[i])
                end
            end

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