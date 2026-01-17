local types = require('openmw.types')
local self = require('openmw.self')

local achievements = require('scripts.omw_achievements.achievements.achievements')

local function isNordSpeechcraft()
    for i = 1, #achievements do
        if achievements[i].id == "nord_speechcraft_01" then
            if types.NPC.record(self.object).race == "nord" and types.NPC.stats.skills.speechcraft(self.object).modified >= 100 then
                self.object:sendEvent('gettingAchievement', {
                    id = achievements[i].id,
                    icon = achievements[i].icon,
                    bgColor = achievements[i].bgColor,
                    name = achievements[i].name,
                    description = achievements[i].description
                })
            end
        end
    end
end

local function onUpdate()
    isNordSpeechcraft()
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}