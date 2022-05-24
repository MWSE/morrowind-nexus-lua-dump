local Util = require("CraftingFramework.util.Util")
local config = require("CraftingFramework.config")
local skillsModule = include("OtherSkills.skillModule")
local logger = Util.createLogger("SkillRequirement")

---@class craftingFrameworkSkillRequirement
local SkillRequirement = {
    schema = {
        name = "SkillRequirement",
        fields = {
            skill = { type = "string", required = true },
            requirement = { type = "number", required = true },
            maxProgress = { type = "number", required = false },
        }
    }
}

local MAX_PROGRESS_DEFAULT = 30
local MAX_SKILL_DIFF = 40

--[[
    SkillRequirement Constructor
]]
---@param data craftingFrameworkSkillRequirementData
---@return craftingFrameworkSkillRequirement skillRequirement
function SkillRequirement:new(data)
    local skillRequirement = table.copy(data, {})
    Util.validate(data, SkillRequirement.schema)
    skillRequirement.skill = data.skill
    skillRequirement.requirement = data.requirement
    skillRequirement.maxProgress = data.maxProgress or MAX_PROGRESS_DEFAULT
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
    if skillsModule then
        local skill = skillsModule.getSkill(self.skill)
        if skill then
            return skill.value
        end
    end
    logger:debug("getCurrent() - Could not find skill: %s", self.skill)
    return nil
end

---@return number skillId
function SkillRequirement:getVanillaSkill()
    return tes3.skill[self.skill] and tes3.skill[self.skill] + 1
end

function SkillRequirement:progressSkill()
    logger:debug("Progressing %s skill", self:getSkillName())
    local current = self:getCurrent()
    local required = self.requirement
    local difference = math.clamp(current - required, 0, MAX_SKILL_DIFF)
    --The higher the current skill is above the requirement,
    -- the less the skill progresses.
    local differenceMulti = (MAX_SKILL_DIFF-difference) / MAX_SKILL_DIFF
    local progress = differenceMulti * self.maxProgress
    logger:debug("Progress: %s", progress)
    local vanillaSkill = self:getVanillaSkill()
    if vanillaSkill then
        logger:trace("Vanilla skill")
        tes3.mobilePlayer:exerciseSkill(vanillaSkill, progress)
    end
    if skillsModule then
        local skill = skillsModule.getSkill(self.skill)
        if skill then
            logger:trace("Custom Skill")
            skill:progressSkill(progress)
        end
    end
end

---@return string name
function SkillRequirement:getSkillName()
    local vanillaSkill = self:getVanillaSkill()
    if vanillaSkill then
        local baseGMST = tes3.gmst.sSkillBlock - 1
        local skillNameGMST = tes3.findGMST(baseGMST + vanillaSkill)
        logger:trace("Skill Name: %s", skillNameGMST.value)
        return skillNameGMST.value
    end
    if skillsModule then
        local skill = skillsModule.getSkill(self.skill)
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