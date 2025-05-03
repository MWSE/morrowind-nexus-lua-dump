local vfs = require('openmw.vfs')

local achievements = {}

local function convertPath(path)
    path = path:gsub("%.lua$", "")
    path = path:gsub("/", ".")
    return path
end

for fileName in vfs.pathsWithPrefix("scripts\\omw_achievements\\achievements\\") do
    if fileName ~= "scripts/omw_achievements/achievements/achievements.lua" and fileName:sub(-4) == ".lua" then
        
        local customAchievements = require(convertPath(fileName))
        if #customAchievements ~= 0 then
            for _, v in ipairs(customAchievements) do
                table.insert(achievements, v)
            end
        end

    end
end

return achievements