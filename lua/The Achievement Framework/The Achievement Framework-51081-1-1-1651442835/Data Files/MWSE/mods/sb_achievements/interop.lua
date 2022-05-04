local achievements = require("sb_achievements.achievements")
local utils = require("sb_achievements.utils")
local interop = {}

---@type colour
interop.colours = utils.colours

---@type number
interop.priority = 360

---@class category
interop.category = {}

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

---countAchievements
---@param category category
---@return number
function interop.countAchievements(category)
    local count = 0
    if (category == nil) then
        ---@param category number
        for _, category in pairs(interop.category) do
            if (achievements[category] ~= nil) then
                for k, v in ipairs(achievements[category]) do
                    count = count + 1
                end
            end
        end
    else
        if (achievements[category] ~= nil) then
            for k, v in ipairs(achievements[category]) do
                count = count + 1
            end
        end
    end
    return count
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
    cheeve.replaceDesc = cheeve.replaceDesc or "Earn to unlock."
    if (achievements[cheeve.category] == nil) then
        achievements[cheeve.category] = {}
    end
    achievements[cheeve.category][interop.countAchievements(cheeve.category) + 1] = cheeve
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