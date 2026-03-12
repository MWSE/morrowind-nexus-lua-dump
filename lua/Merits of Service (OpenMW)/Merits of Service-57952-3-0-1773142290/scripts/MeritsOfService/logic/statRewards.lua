local ambient = require("openmw.ambient")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local self = require("openmw.self")

require("scripts.MeritsOfService.utils.consts")
require("scripts.MeritsOfService.utils.random")
local sectionSkills = storage.playerSection("SettingsMeritsOfService_skills")
local sectionAttrs = storage.playerSection("SettingsMeritsOfService_attributes")

-- +------------+
-- | Increasers |
-- +------------+

local function increaseSkillsInterface(stats)
    local msg = ""
    local src = I.SkillProgression.SKILL_INCREASE_SOURCES.Usage
    for skillId, count in pairs(stats) do
        local skill = SkillIdToHandler[skillId](self)
        local skillXp = skill.progress

        -- increase skill
        for _ = 1, count do
            I.SkillProgression.skillLevelUp(skillId, src)
        end

        -- carry xp if needed
        if sectionSkills:get("carrySkillXp") then
            skill.progress = skillXp
        end

        -- update message
        msg = msg .. "Your " .. SkillIdToName[skillId] .. " skill increased to " .. tostring(skill.base) .. ".\n"
    end

    msg = msg:sub(1, -2) -- remove last newline
    -- send message only if player is in dialogue
    if I.UI.getMode() == I.UI.MODE.Dialogue then
        self:sendEvent("ShowMessage", { message = msg })
    end
end

local function increaseSkillsBrute(stats)
    local msg = ""
    for skillId, count in pairs(stats) do
        local skill = SkillIdToHandler[skillId](self)

        -- increase skill
        for _ = 1, count do
            skill.base = skill.base + 1
        end

        -- reset xp if needed
        if not sectionSkills:get("carrySkillXp") then
            skill.progress = 0
        end

        -- update message
        msg = msg .. "Your " .. SkillIdToName[skillId] .. " skill increased to " .. tostring(skill.base) .. ".\n"
    end
    msg = msg:sub(1, -2) -- remove last newline
    self:sendEvent("ShowMessage", { message = msg })
    ambient.playSound("skillraise")
end

local function increaseAttrs(stats)
    local msg = ""
    for attrId, count in pairs(stats) do
        local attr = AttrIdToHandler[attrId](self)

        -- luck reward roll - REPLACE
        if sectionAttrs:get("luckRewardType") == LuckRewardTypes.REPLACE
            and math.random() <= sectionAttrs:get("luckRewardChance")
            and AttrIdToHandler.luck(self).base <= sectionAttrs:get("capAttr")
        then
            attrId = "luck"
            attr = AttrIdToHandler.luck(self)
        end

        -- increase attribute
        for _ = 1, count do
            attr.base = attr.base + 1
        end

        -- update message
        msg = msg .. "Your " .. AttrIdToName[attrId] .. " increased to " .. tostring(attr.base) .. ".\n"
    end

    -- luck reward roll - BONUS
    if sectionAttrs:get("luckRewardType") == LuckRewardTypes.BONUS
        and math.random() <= sectionAttrs:get("luckRewardChance")
        and AttrIdToHandler.luck(self).base < sectionAttrs:get("capAttr")
    then
        local attr = AttrIdToHandler.luck(self)
        attr.base = attr.base + 1
        msg = msg .. "Your Luck increased to " .. tostring(attr.base) .. ".\n"
    end

    msg = msg:sub(1, -2) -- remove last newline
    self:sendEvent("ShowMessage", { message = msg })
    ambient.playSound("skillraise")
end

-- +---------+
-- | Rewards |
-- +---------+

local function pickRewards(faction, rewardType, rewardAmount)
    -- init data for stat picking
    local rewards = {}
    local statList = {}
    for _, name in ipairs(faction[rewardType]) do
        statList[name] = name
    end
    local caps = {
        [SKILL_REWARD]     = sectionSkills:get("capSkills"),
        [ATTRIBUTE_REWARD] = sectionAttrs:get("capAttr"),
    }

    -- pick stats
    for _ = 1, rewardAmount do
        -- prune capped stats
        for stat, _ in pairs(statList) do
            local currStat = RewardTypeToHandler[rewardType][stat](self)
            local currReward = rewards[stat] or 0

            if currStat.base + currReward >= caps[rewardType] then
                statList[stat] = nil
            end
        end

        if next(statList) == nil then break end

        local stat = RandomChoice(statList)
        rewards[stat] = (rewards[stat] or 0) + 1
    end

    return rewards
end

local function increaseStat(rewardType, possibleRewards, rewardAmount)
    local rewards = pickRewards(possibleRewards, rewardType, rewardAmount)
    if rewardType == SKILL_REWARD then
        if sectionSkills:get("triggerSkillupHandlers") then
            increaseSkillsInterface(rewards)
        else
            increaseSkillsBrute(rewards)
        end
    elseif rewardType == ATTRIBUTE_REWARD then
        increaseAttrs(rewards)
    end
end

local function statCapChecker(rewardList, cap, stats)
    if not rewardList or not rewardList[1] then
        return true
    end

    for _, statReward in ipairs(rewardList) do
        if stats[statReward](self).base >= cap then
            return false
        end
    end

    return true
end

local function statAmountPicker(section, keyMin, keyMax)
    local min = section:get(keyMin)
    local max = section:get(keyMax)
    return math.random(min, max)
end

-- +-----------+
-- | Endpoints |
-- +-----------+

function AttrAmountPicker()
    return statAmountPicker(
        sectionAttrs,
        "minAttributeReward",
        "maxAttributeReward")
end

function SkillAmountPicker()
    return statAmountPicker(
        sectionAttrs,
        "minAttributeReward",
        "maxAttributeReward")
end

function AttrCapChecker(rewardList)
    return statCapChecker(
        rewardList,
        sectionAttrs:get("capAttr"),
        self.type.stats.attributes)
end

function SkillCapChecker(rewardList)
    return statCapChecker(
        rewardList,
        sectionSkills:get("capSkills"),
        self.type.stats.skills)
end

function GrantAttributes(rewardList, rewardAmount)
    increaseStat(ATTRIBUTE_REWARD, rewardList, rewardAmount)
end

function GrantSkills(rewardList, rewardAmount)
    increaseStat(SKILL_REWARD, rewardList, rewardAmount)
end
