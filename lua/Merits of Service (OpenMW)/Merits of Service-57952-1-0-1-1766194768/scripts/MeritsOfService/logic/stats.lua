local ambient = require("openmw.ambient")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")

require("scripts.MeritsOfService.utils.consts")
require("scripts.MeritsOfService.utils.string")
require("scripts.MeritsOfService.utils.random")

local sectionGeneral = storage.playerSection("SettingsMeritsOfService_general")
local sectionSkills = storage.playerSection("SettingsMeritsOfService_skills")
local sectionAttrs = storage.playerSection("SettingsMeritsOfService_attributes")

-- +------------+
-- | Increasers |
-- +------------+

local function increaseSkillsInterface(player, stats)
    local src = I.SkillProgression.SKILL_INCREASE_SOURCES.Usage
    for skillId, count in pairs(stats) do
        local skill = SkillNameToHandler[skillId](player)
        local skillXp = skill.progress

        -- increase skill
        for _ = 1, count do
            I.SkillProgression.skillLevelUp(skillId, src)
        end

        -- carry xp if needed
        if sectionSkills:get("carrySkillXp") then
            skill.progress = skillXp
        end
    end
end

local function increaseSkillsBrute(player, stats)
    local msg = ""
    for skillId, count in pairs(stats) do
        local skill = SkillNameToHandler[skillId](player)

        -- increase skill
        for _ = 1, count do
            skill.base = skill.base + 1
        end

        -- reset xp if needed
        if not sectionSkills:get("carrySkillXp") then
            skill.progress = 0
        end

        -- update message
        msg = msg .. "Your " .. Capitalize(skillId) .. " increased to " .. tostring(skill.base) .. ".\n"
    end
    msg = msg:sub(1, -2) -- remove last newline
    player:sendEvent("ShowMessage", { message = msg })
    ambient.playSound("skillraise")
end

local function increaseAttrs(player, stats)
    local msg = ""
    for attrId, count in pairs(stats) do
        local attr = AttrNameToHandler[attrId](player)

        -- luck reward roll - REPLACE
        if sectionAttrs:get("luckRewardType") == LuckRewardTypes.REPLACE
            and math.random() <= sectionAttrs:get("luckRewardChance")
            and AttrNameToHandler.luck(player).base <= sectionAttrs:get("capAttr")
        then
            attrId = "luck"
            attr = AttrNameToHandler.luck(player)
        end

        -- increase attribute
        for _ = 1, count do
            attr.base = attr.base + 1
        end

        -- update message
        msg = msg .. "Your " .. Capitalize(attrId) .. " increased to " .. tostring(attr.base) .. ".\n"
    end

    -- luck reward roll - BONUS
    if sectionAttrs:get("luckRewardType") == LuckRewardTypes.BONUS
        and math.random() <= sectionAttrs:get("luckRewardChance")
        and AttrNameToHandler.luck(player).base <= sectionAttrs:get("capAttr")
    then
        local attr = AttrNameToHandler.luck(player)
        attr.base = attr.base + 1
        msg = msg .. "Your Luck increased to " .. tostring(attr.base) .. ".\n"
    end

    msg = msg:sub(1, -2) -- remove last newline
    player:sendEvent("ShowMessage", { message = msg })
    ambient.playSound("skillraise")
end

local function increaseStat(player, statType, stats)
    if statType == SKILL_REWARD then
        if sectionSkills:get("triggerSkillupHandlers") then
            increaseSkillsInterface(player, stats)
        else
            increaseSkillsBrute(player, stats)
        end
    elseif statType == ATTRIBUTE_REWARD then
        increaseAttrs(player, stats)
    end
end

-- +---------+
-- | Rewards |
-- +---------+

local function pickRewardType(faction)
    if not faction[SKILL_REWARD] then return ATTRIBUTE_REWARD end

    if not faction[ATTRIBUTE_REWARD] then return SKILL_REWARD end

    return WeightedRandom({
        [SKILL_REWARD]     = sectionGeneral:get("skillRewardWeight"),
        [ATTRIBUTE_REWARD] = sectionGeneral:get("attributeRewardWeight")
    })
end

local function pickRewardAmount(rewardType)
    local rewardRange = {
        [SKILL_REWARD] = {
            sectionSkills:get("minSkillReward"),
            sectionSkills:get("maxSkillReward")
        },
        [ATTRIBUTE_REWARD] = {
            sectionAttrs:get("minAttributeReward"),
            sectionAttrs:get("maxAttributeReward")
        }
    }
    return math.random(table.unpack(rewardRange[rewardType]))
end

local function pickRewards(player, faction, rewardType, rewardAmount)
    -- init data for stat picking
    local rewards = {}
    local statList = {}
    for i, name in ipairs(faction[rewardType]) do
        statList[i] = name
    end
    local caps = {
        [SKILL_REWARD]     = sectionSkills:get("capSkills"),
        [ATTRIBUTE_REWARD] = sectionAttrs:get("capAttr"),
    }

    -- pick stats
    for _ = 1, rewardAmount do
        -- prune capped stats
        for _, stat in pairs(statList) do
            local currStat = RewardTypeToHandler[rewardType][stat](player)
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

function GrantStats(player, factions, factionName, completedQuests)
    if completedQuests % sectionGeneral:get("questsPerReward") ~= 0 then return end

    local faction = factions[factionName]
    local rewardType = pickRewardType(faction)
    local rewardAmount = pickRewardAmount(rewardType)

    local rewards = pickRewards(player, faction, rewardType, rewardAmount)

    increaseStat(player, rewardType, rewards)
end
