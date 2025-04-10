local playerAchievements = require('scripts.omw_achievements.achievements.playerAchievements')

local achievements = {}

if #playerAchievements ~= 0 then
    for _, v in ipairs(playerAchievements) do
        table.insert(achievements, v)
    end
end

return achievements