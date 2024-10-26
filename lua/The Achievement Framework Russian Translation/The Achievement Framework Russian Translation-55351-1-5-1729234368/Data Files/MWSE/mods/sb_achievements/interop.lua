local achievements = require("sb_achievements.achievements")
local utils = require("sb_achievements.utils")
local interop = {}

---@type colour
interop.colours = utils.colours

---@class lockedMessage
interop.lockedMessage = {
    steamDetailsRevealed = "Информация о каждом достижении будет доступна после его получения.",
    steamKeepPlaying = "Продолжайте играть, чтобы открыть это достижение.",
    xboxSecret = "Это достижение является скрытым.",
    xboxMoreYouPlay = "Это достижение является скрытым. Чем больше вы играете, тем больше вероятность того, что вы его откроете!",
    psHidden = "Скрытые достижения"
}

---@type number
interop.priority = 360

---@class category
interop.category = {}

---@type number[]
interop.unlockedAchievements = {}

---@enum configDesc
interop.configDesc = {
    -- authorsChoice = 0,
    hideDesc = 1,
    showDesc = 2,
    groupHidden = 3
}

---@class achievement
---@field id string
---@field category category
---@field condition function
---@field icon string
---@field fullIcon string
---@field colour colour | nil
---@field title string
---@field desc string
---@field hideDesc boolean | nil use configDesc
---@field configDesc configDesc | nil
---@field lockedDesc string | nil

---countTotalAchievements
---@param category category | nil
---@return number
function interop.countTotalAchievements(category)
    local count = 0
    if (category == nil) then
        ---@param index number
        for index, _ in ipairs(interop.category) do
            if (achievements[index] ~= nil) then
                count = count + #(achievements[index])
            end
        end
    else
        if (achievements[category] ~= nil) then
            count = #(achievements[category])
        end
    end
    return count
end

---countUnlockedAchievements
---@param category category | nil
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
    return 0
end

---countHiddenAchievements
---@param category category | nil
---@param config integer
---@return number
function interop.countHiddenAchievements(category, config)
    local hiddenCount = 0

    ---@type boolean
    local choice = config == 0
    ---@type boolean
    local grouped = config == 3

    if (category == nil) then
        if (achievements[0] ~= nil) then
            ---@param achievement achievement
            for _, achievement in ipairs(achievements[0]) do
                ---@type boolean
                local unlocked = tes3.player.data["achievements"][achievement.id]
                ---@type boolean
                local hide = achievement.configDesc == interop.configDesc.hideDesc
                ---@type boolean
                local group = achievement.configDesc == interop.configDesc.groupHidden

                hiddenCount = hiddenCount +
                    ((unlocked == false and ((choice and group) or (grouped and (hide or group)))) and 1 or 0)
            end
        end
    else
        if (achievements[category] ~= nil) then
            ---@param achievement achievement
            for _, achievement in ipairs(achievements[category]) do
                ---@type boolean
                local unlocked = tes3.player.data["achievements"][achievement.id]
                ---@type boolean
                local hide = achievement.configDesc == interop.configDesc.hideDesc
                ---@type boolean
                local group = achievement.configDesc == interop.configDesc.groupHidden

                hiddenCount = hiddenCount +
                    ((unlocked == false and ((choice and group) or (grouped and (hide or group)))) and 1 or 0)
            end
        end
    end
    return hiddenCount
end

---getCategoryByName
---@param category string
---@return number | nil
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
    cheeve.configDesc = (cheeve.hideDesc and interop.configDesc.hideDesc) or cheeve.configDesc or
        interop.configDesc.showDesc
    cheeve.lockedDesc = cheeve.lockedDesc or ""
    if (interop.category[cheeve.category] == nil) then
        mwse.log(
            "[The Achievement Framework]: Failed to register achievement \"%s\" - \"%s\", category \"%s\" does not exist.",
            achievement.id, achievement.title, cheeve.category)
    else
        if (achievements[cheeve.category] == nil) then
            achievements[cheeve.category] = {}
        end
        achievements[cheeve.category][interop.countTotalAchievements(cheeve.category) + 1] = cheeve
        mwse.log("[The Achievement Framework]: Registered achievement \"%s\" - \"%s\" under category \"%s\".",
            achievement.id, achievement.title, interop.category[cheeve.category])
    end
end

---registerCategory
---@param category string
---@return number
function interop.registerCategory(category)
    local categoryID = interop.getCategoryByName(category);
    if (categoryID) then
        return categoryID
    else
        categoryID = 1
        for k, v in pairs(interop.category) do
            categoryID = categoryID + 1
        end
        interop.category[categoryID] = category
        mwse.log("[The Achievement Framework]: Registered category \"%s\".", category)
        return categoryID
    end
end

return interop
