local baseAchievements = require('scripts.omw_achievements.achievements.baseAchievements')
local playerAchievements = require('scripts.omw_achievements.achievements.playerAchievements')

local achievements = {}

for _, v in ipairs(baseAchievements) do
    table.insert(achievements, v)
end

if #playerAchievements ~= 0 then
    for _, v in ipairs(playerAchievements) do
        table.insert(achievements, v)
    end
end

return achievements