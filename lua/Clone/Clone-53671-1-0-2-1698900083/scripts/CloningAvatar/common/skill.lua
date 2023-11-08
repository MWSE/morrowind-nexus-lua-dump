local skill     = {}
local skillCore
local SkillsModule
local omw, core = pcall(require, "openmw.core")
if not omw then
    SkillsModule = include("SkillsModule")
    if SkillsModule then
        skillCore = SkillsModule.registerSkill {
            id = "cloning",
            name = "Cloning",
            description = "The cloning skill determines how well you can create and use clones.",
            specialization = tes3.specialization["magic"],
            value = 0,
            maxLevel = -1,
            -- icon = "Icons/HuntingMod/hunting.dds"
        }
    end
end

return skill
