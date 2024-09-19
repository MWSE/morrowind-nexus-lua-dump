--[[
    THIS CLASS IS DEPRECATED
    Use `local SkillsModule = require("OtherSkills")` instead.
]]



---@class SkillsModule.Skill.v1
---@field id string
---@field name string
---@field value number
---@field base number
---@field current number
---@field progress number
---@field lvlCap number
---@field icon string
---@field description string
---@field specialization tes3.specialization
---@field active string "active" | "inactive"
---@field levelUpSkill fun(SkillsModule.Skill.v1, value: number)
---@field progressSkill fun(SkillsModule.Skill.v1, value: number)
---@field updateSkill fun(SkillsModule.Skill.v1, skillVals: table)

--Require the new module to ensure any events are triggered
require("OtherSkills")
local common = include("OtherSkills.common")
local config = include("OtherSkills.config")
local Skill = include("OtherSkills.components.Skill")
local util = include("OtherSkills.util")
local logger = util.createLogger("SkillsModule_v1")
local this = {}

this.version = 1.4

---@deprecated Modify skill values directly instead
function this.updateSkill(id, skillVals)
    local skill = Skill.get(id)
    if skill then
        ---@diagnostic disable-next-line: deprecated
        skill:updateSkill(skillVals)
    else
        logger:error("Skill %s does not exist", id)
    end
end

---@deprecated use `Skill:levelUp` instead
function this.incrementSkill(id, skillVals)
    skillVals = skillVals or { progress = 10 }
    local skill = Skill.get(id)
    if not skill then
        logger:error("Skill %s does not exist", id)
        return
    end
    if not skill:isActive() then
        logger:debug("Skill %s is not active", id)
        return
    end
    if skillVals.value then
        logger:info("Incrementing by %s", skillVals.value)
        skill:levelUp(skillVals.value)
        logger:info("New value = %s", skill.current)
    end
    if skillVals.progress then
        skill:exercise(skillVals.progress)
    end
end

---@deprecated use the `getSkill(id)` method from `require("SkillsModule")` instead
---@param id string
---@param owner? tes3reference
function this.getSkill(id, owner)
    return Skill.get(id) --[[@as SkillsModule.Skill.v1]]
end

---@deprecated use the `registerSkill` method from `require("SkillsModule")` instead
---@param id string
---@param skillData SkillsModule.Skill.data
function this.registerSkill(id, skillData)
    if not config.playerData then
        logger:info("[Skills Module: ERROR] Skills table not loaded - trigger register using event 'OtherSkills:Ready'")
        return
    end
    --exists: set active flag
    local existingSkill = Skill.get(id)
    if existingSkill then
        logger:debug("Skill already exists, setting to active: %s", id)
        existingSkill:setActive(true)
        return existingSkill
    else
        skillData = table.copy(skillData)
        skillData.id = id
        skillData.maxLevel = skillData.lvlCap
        skillData.apiVersion = 1
        local newSkill = Skill:new(skillData)
        logger:debug("Registering skill via legacy API: %s", newSkill)
        return Skill:new(skillData)
    end
end

return this
