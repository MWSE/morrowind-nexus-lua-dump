local achievements = require("sb_achievements.achievements")
local utils = require("sb_achievements.utils")
local interop = {}

---@type colour
interop.colours = utils.colours

---@class lockedMessage
interop.lockedMessage = {
    steamDetailsRevealed = "Details for each achievement will be revealed once unlocked.",
    steamKeepPlaying = "Keep playing to discover this achievement.",
    xboxSecret = "This achievement is secret.",
    xboxMoreYouPlay = "This achievement is secret. The more you play, the more likely you are to unlock it!",
    psHidden = "Hidden Achievement"
}

---@type number
interop.priority = 360

---@class category
interop.category = {}

---@type number[]
interop.unlockedAchievements = {}

---@class achievement
---@field id string
---@field category category
---@field condition function
---@field icon string
---@field colour colour
---@field title string
---@field desc string
---@field hideDesc boolean
---@field replaceDesc string

---countTotalAchievements
---@param category category
---@return number
function interop.countTotalAchievements(category)
    local count = 0
    if (category == nil) then
        ---@param index number
        for index, _ in ipairs(interop.category) do
            if (achievements[index] ~= nil) then
                count = count + table.getn(achievements[index])
            end
        end
    else
        if (achievements[category] ~= nil) then
            count = table.getn(achievements[category])
        end
    end
    return count
end

---countUnlockedAchievements
---@param category category
---@return number
function interop.countUnlockedAchievements(category)
    if (category == nil) then
        if (interop.unlockedAchievements[0] ~= nil) then
            return interop.unlockedAchievements[0]
        end
    else
        if (interop.unlockedAchievements[category] ~= nil) then
            return interop.unlockedAchievements[category]
        end
    end
end

---getCategoryByName
---@param category string
---@return number
function interop.getCategoryByName(category)
    for index, cat in ipairs(interop.category) do
        if (cat == category) then
            return index
        end
    end
    return nil
end

---registerAchievement
---@param achievement achievement
function interop.registerAchievement(achievement)
    local cheeve = achievement
    cheeve.colour = cheeve.colour or utils.colours.white
    cheeve.hideDesc = cheeve.hideDesc or false
    cheeve.replaceDesc = cheeve.replaceDesc or ""
    if (achievements[cheeve.category] == nil) then
        achievements[cheeve.category] = {}
    end
    achievements[cheeve.category][interop.countTotalAchievements(cheeve.category) + 1] = cheeve
end

---registerCategory
---@param category string
---@return number
function interop.registerCategory(category)
    local count = 1
    for k, v in pairs(interop.category) do
        count = count + 1
    end
    interop.category[count] = category
    return count
end

return interop