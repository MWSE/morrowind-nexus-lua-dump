local types = require('openmw.types')
local self = require('openmw.self')
local interfaces = require('openmw.interfaces')
local ui = require('openmw.ui')

local achievements = require('scripts.omw_achievements.achievements.achievements')
local frameCount = 0

local function isWerewolf()

    for i = 1, #achievements do
        if achievements[i].type == "unique" then
            if achievements[i].id == "werewolf_01" then
                if types.NPC.isWerewolf(self.object) then
                    local data = {
                        name = achievements[i].name,
                        icon = achievements[i].icon,
                        description = achievements[i].description,
                        id = achievements[i].id
                    }
                    self.object:sendEvent('gettingAchievement', data)
                end
            end
        end
    end

end

local function onFrame()
    frameCount = frameCount + 1
    if frameCount > 10 then 
        isWerewolf()
    end
end

return {
    engineHandlers = {
        onFrame = onFrame
    }
}