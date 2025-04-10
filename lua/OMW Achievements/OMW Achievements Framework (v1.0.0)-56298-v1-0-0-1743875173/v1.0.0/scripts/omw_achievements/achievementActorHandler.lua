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
    end

end

return {
    engineHandlers = {
        onActivated = onActivated
    }
}