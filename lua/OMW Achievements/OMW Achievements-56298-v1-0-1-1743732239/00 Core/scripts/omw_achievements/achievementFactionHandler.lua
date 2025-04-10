local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local interfaces = require('openmw.interfaces')

local achievements = require('scripts.omw_achievements.achievements.achievements')
local frameCount = 0

local function gettingAchievementEvent(data)
    self.object:sendEvent('gettingAchievement', data)
end

local function getFaction()

    local macData = interfaces.storageUtils.getStorage()
    local playerFactionsAndRanks = {}
    local playerFactions = types.NPC.getFactions(self.object)

    for i = 1, #playerFactions do
        table.insert(playerFactionsAndRanks, {
            faction = playerFactions[i],
            rank = types.NPC.getFactionRank(self.object, playerFactions[i])
        })
    end

    for i, achievement in ipairs(achievements) do

        --- Check for "join_faction" achievements
        if achievement.type == "join_faction" then
            if macData:get(achievement.id) == false then
                for f = 1, #playerFactions do

                    if type(achievement.factionId) == "string" then
                        if achievement.factionId == playerFactions[f] then
                            gettingAchievementEvent(achievements[i])
                        end
                    elseif type(achievement.factionId) == "table" then
                        for k = 1, #achievement.factionId do
                            if achievement.factionId[k] == playerFactions[f] then
                                gettingAchievementEvent(achievements[i])
                            end
                        end
                    end

                end
            end
        end

        --- Check for "rank_faction" achievements
        if achievement.type == "rank_faction" then
            for f = 1, #playerFactionsAndRanks do
                if achievement.factionId == playerFactionsAndRanks[f].faction and achievement.rank == playerFactionsAndRanks[f].rank then
                    if macData:get(achievement.id) == false then
                        gettingAchievementEvent(achievements[i])
                    end
                end
            end
        end
    
    end

end

local function onFrame()
    frameCount = frameCount + 1
    if frameCount > 10 then 
        getFaction()
    end
end

return {
    engineHandlers = {
        onFrame = onFrame
    }
}