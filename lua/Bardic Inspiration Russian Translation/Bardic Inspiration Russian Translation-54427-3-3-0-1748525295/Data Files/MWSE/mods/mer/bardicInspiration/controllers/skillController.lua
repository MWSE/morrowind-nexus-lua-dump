--[[
    Skills
]]
local messages = require("mer.bardicInspiration.messages.messages")
local common = require("mer.bardicInspiration.common")
local SkillsModule = include("SkillsModule")
if not SkillsModule then return end

event.register("loaded", function()
    common.skills.performance = SkillsModule.getSkill("BardicInspiration:Performance")
end)

SkillsModule.registerSkill{
    id = "BardicInspiration:Performance",
    name = messages.skills_performance_name,
    icon = "Icons/mer_bard/performSkill.dds",
    value = 5,
    attribute = tes3.attribute.personality,
    description = messages.skills_performance_description,
    specialization = tes3.specialization.stealth
}
