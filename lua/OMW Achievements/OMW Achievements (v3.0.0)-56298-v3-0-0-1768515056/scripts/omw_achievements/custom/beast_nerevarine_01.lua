local types = require('openmw.types')
local self = require('openmw.self')
local interfaces = require('openmw.interfaces')

local achievements = require('scripts.omw_achievements.achievements.achievements')

local function onQuestUpdate(questId, stage)

    local macData = interfaces.storageUtils.getStorage("counters")

    --- Check for unique achievement "N'wah and Proud Of It"
    for i = 1, #achievements do

        if achievements[i].type == "unique" then
            if achievements[i].id == "beast_nerevarine_01" and questId == "c3_destroydagoth" and stage >= 20 then
                if types.NPC.record(self.object).race == "khajiit" or types.NPC.record(self.object).race == "argonian" then
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
end

return {
    engineHandlers = {
        onQuestUpdate = onQuestUpdate
    }
}