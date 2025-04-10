local self = require('openmw.self')
local types = require('openmw.types')

local achievements = require('scripts.omw_achievements.achievements.achievements')

local function onActivated(actor)

    for i = 1, #achievements do
        if achievements[i].type == "talkto" then
            if achievements[i].recordId == self.object.recordId then
                if types.Actor.isDead(self.object) ~= true then
                    actor:sendEvent('gettingAchievement', achievements[i])
                end
            end
        end

        if achievements[i].type == "unique" then
            if achievements[i].id == "killtribunal_01" and self.object.recordId == "vivec_god" then
                if types.Actor.isDead(self.object) == true then
                    actor:sendEvent('vivecIsDead', achievements[i])
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