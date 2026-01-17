local types = require('openmw.types')
local self = require('openmw.self')
local achievements = require('scripts.omw_achievements.achievements.achievements')

local function daysPassed(data)
    for i = 1, #achievements do
        --- Check for unique achievement "What Main Quest?"
        if achievements[i].type == "unique" and achievements[i].id == "dayspassed_01" and data.days >= 60 then
            if types.Player.quests(self.object)["a1_1_findspymaster"].stage < 14 then
                self.object:sendEvent('gettingAchievement', {
                    name = achievements[i].name,
                    description = achievements[i].description,
                    icon = achievements[i].icon,
                    id = achievements[i].id,
                    bgColor = achievements[i].bgColor
                })
            end
        end
    end
end

return {
    eventHandlers = {
        daysPassed = daysPassed
    }
}