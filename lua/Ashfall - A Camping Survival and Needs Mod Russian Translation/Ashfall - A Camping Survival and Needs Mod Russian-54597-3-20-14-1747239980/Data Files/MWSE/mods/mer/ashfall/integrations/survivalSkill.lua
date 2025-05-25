local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Skills")

--INITIALISE SKILLS--
local SkillsModule = include("SkillsModule")
if not SkillsModule then
    common.log:error("Skills Module not found. Ashfall will not work correctly.")
    return
end

local skills = {
    survival = {
        id = "Ashfall:Survival",
        name = "Выживание",
        icon = "Icons/ashfall/survival.dds",
        value = 10,
        attribute = tes3.attribute.endurance,
        description = "Навык Выживание определяет вашу способность справляться с суровыми погодными условиями и выполнять такие действия, как разведение костров и приготовление пищи на них. Более высокий уровень навыка Выживание также снижает вероятность пищевого отравления или дизентерии при употреблении грязной воды.",
        specialization = tes3.specialization.stealth
    },
    bushcrafting = {
        id = "Bushcrafting",
        name = "Ремесленник",
        icon = "Icons/ashfall/bushcrafting.dds",
        value = 10,
        attribute = tes3.attribute.intelligence,
        description = "Навык Ремесленник определяет вашу способность изготавливать предметы из подручных материалов, собранных в дикой местности. На более высоких уровнях навыка Ремесленник становится доступно больше чертежей для изготовления предметов.",
        specialization = tes3.specialization.combat
    }
}
for skill, data in pairs(skills) do
    logger:debug("Registering %s skill", skill)
    SkillsModule.registerSkill(data)
    common.skills[skill] = SkillsModule.getSkill(data.id)
end

--INITIALISE SKILL MODIFIERS--
local classModifiers = {
    ["Acrobat"] = 5,
    ["Barbarian"] = 5,
    ["Pilgrim"] = 5,
    ["Scout"] = 10,
}
for class, amount in pairs(classModifiers) do
        SkillsModule.registerClassModifier{
            class = class,
            skill = "Ashfall:Survival",
            amount = amount
        }
end

logger:info("Ashfall skills registered")
