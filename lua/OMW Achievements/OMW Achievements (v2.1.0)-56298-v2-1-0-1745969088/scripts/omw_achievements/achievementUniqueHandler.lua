local types = require('openmw.types')
local self = require('openmw.self')

local achievements = require('scripts.omw_achievements.achievements.achievements')

local function isOrcIntelligence()
    for i = 1, #achievements do
        if achievements[i].id == "orc_intelligence_01" then
            if types.NPC.record(self.object).race == "orc" and types.Actor.stats.attributes.intelligence(self.object).modified >= 100 then
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
    isOrcIntelligence()
    isNordSpeechcraft()
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}