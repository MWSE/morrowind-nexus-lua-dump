local Util = require("CraftingFramework.util.Util")
local config = require("CraftingFramework.config")
local logger = Util.createLogger("SkillRequirement")
-- Keep compatibility with mods using v1 of Skills Module
local SkillsModule = include("OtherSkills.skillModule")

---@class CraftingFramework.SkillRequirement.data
local skilRequirementDataMeta = {
    --- **Required.** The name of the skill of this `skillRequirement`. If vanilla skill, it needs to be a camelCased name of the skill. Supports skills added with the Skills Module.
    ---@type string
    skill = nil,

    --- **Required.** The needed skill value to pass this `skillRequirement`'s skill check.
    ---@type number
    requirement = nil,

    --- The amount of experience the player gets, when crafting an item that has this `skillRequirement`.
    --- Requires v2 of Skills Module.
    ---@type number?
    progress = nil,

    --- *Default*: `30`. The maximal amount of experience the player can get, when crafting an item that has this `skillRequirement`.
    --- Only use if your mod still uses v1 of Skills Module
    ---@deprecated
    ---@type number?
    maxProgress = nil,
}

---@class CraftingFramework.SkillRequirement : CraftingFramework.SkillRequirement.data
local SkillRequirement = {
    schema = {
        name = "SkillRequirement",
        fields = {
            skill = { type = "string", required = true },
            requirement = { type = "number", required = true },
            maxProgress = { type = "number", required = false },
            progress = { type = "number", required = false },
        }
    }
}

local MAX_PROGRESS_DEFAULT = 30
local MAX_SKILL_DIFF = 40

--[[
    SkillRequirement Constructor
]]
---@param data CraftingFramework.SkillRequirement.data
---@return CraftingFramework.SkillRequirement skillRequirement
function SkillRequirement:new(data)
    local skillRequirement = table.copy(data)
    Util.validate(data, SkillRequirement.schema)
    skillRequirement.skill = data.skill
    skillRequirement.requirement = data.requirement
    skillRequirement.progress = data.progress
    skillRequirement.maxProgress = data.maxProgress ---@diagnostic disable-line deprecated
    setmetatable(skillRequirement, self)
    self.__index = self
    return skillRequirement
end

--[[
    Get the player's current skill level
]]
---@return number|nil
function SkillRequirement:getCurrent()
    local vanillaSkill = tes3.skill[self.skill]
    if vanillaSkill then
        return tes3.mobilePlayer.skills[vanillaSkill + 1].current
    end
    if SkillsModule then
        ---@diagnostic disable-next-line: deprecated
        local skill = SkillsModule.getSkill(self.skill)
        if skill then
            return skill.current
        end
    end
    logger:warn("getCurrent() - Could not find skill: %s", self.skill)
    return nil
end

---@return number skillId
function SkillRequirement:getVanillaSkill()
    return tes3.skill[self.skill] and tes3.skill[self.skill] + 1
end

---For V2, we either get the progress provided or
--- calculate it based on the difficulty (requirement).
---@private
---@return number
function SkillRequirement:getV2Progress()
    if self.progress then
        return self.progress
    else
        return MAX_PROGRESS_DEFAULT * (self.requirement / 100)
    end
end

---For V1, we compare the current skill
--- level to the requirement to determine
--- the progress.
---@private
---@return number
function SkillRequirement:getV1Progress()
    local current = self:getCurrent()
    local required = self.requirement
    local difference = math.clamp(current - required, 0, MAX_SKILL_DIFF)
    --The higher the current skill is above the requirement,
    -- the less the skill progresses.
    local differenceMulti = (MAX_SKILL_DIFF-difference) / MAX_SKILL_DIFF
    local maxProgress = table.get(self, "maxProgress", MAX_PROGRESS_DEFAULT)
    local progress = differenceMulti * maxProgress
    return progress
end

---@private
---@param skill SkillsModule.Skill.v1 | SkillsModule.Skill
function SkillRequirement:getCustomSkillProgress(skill)
    if skill.getApiVersion and skill:getApiVersion() > 1 then
        return self:getV2Progress()
    else
        return self:getV1Progress()
    end
end

function SkillRequirement:progressSkill()
    logger:debug("Progressing %s skill", self:getSkillName())

    --Vanilla Skill

    local vanillaSkill = self:getVanillaSkill()
    if vanillaSkill then
        logger:trace("Vanilla skill")
        tes3.mobilePlayer:exerciseSkill(vanillaSkill, self:getV2Progress())
        return
    end

    --Skills Module Skill
    ---@diagnostic disable-next-line: deprecated
    local skill = SkillsModule and SkillsModule.getSkill(self.skill)
    if skill then
        local progress = self:getCustomSkillProgress(skill)
        logger:trace("Skills Module skill")
        skill:progressSkill(progress)
        return
    end
end

---@return string name
function SkillRequirement:getSkillName()
    local vanillaSkill = self:getVanillaSkill()
    if vanillaSkill then
        local baseGMST = tes3.gmst.sSkillBlock - 1
        local skillNameGMST = tes3.findGMST(baseGMST + vanillaSkill)
        logger:trace("Skill Name: %s", skillNameGMST.value)
        return skillNameGMST.value ---@diagnostic disable-line
    end
    if SkillsModule then
        ---@diagnostic disable-next-line: deprecated
        local skill = SkillsModule.getSkill(self.skill)
        if skill then
            return skill.name
        end
    end
    return ""
end

---@return boolean passed
function SkillRequirement:check()
    local current = self:getCurrent()
    if current then
        logger:trace("hasRequirement() - Current: %s, Requirement: %s", current, self.requirement)
        return current >= self.requirement
    else
        logger:trace("hasRequirement() - Could not find skill: %s", self.skill)
        return false
    end
end

return SkillRequirement