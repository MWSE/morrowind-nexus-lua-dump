local types = require('openmw.types')
local self = require('openmw.self')
local achievements = require('scripts.omw_achievements.achievements.achievements')

local function daysPassed(data)
    for i = 1, #achievements do
        --- Check for unique achievement "Still a Stranger"
        if achievements[i].type == "unique" and achievements[i].id == "dayspassed_02" and data.days >= 365 then
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

return {
    eventHandlers = {
        daysPassed = daysPassed
    }
}