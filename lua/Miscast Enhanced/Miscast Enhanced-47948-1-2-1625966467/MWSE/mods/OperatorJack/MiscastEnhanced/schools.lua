local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
local functions = require("OperatorJack.MiscastEnhanced.functions")

local potionIds = {
    alteration = "OJ_MIS_AlterationSchoolSpell",
    conjuration = "OJ_MIS_ConjurationSchoolSpell",
    destruction = "OJ_MIS_DestructionSchoolSpell",
    illusion = "OJ_MIS_IllusionSpell",
    mysticism = "OJ_MIS_MysticismSpell",
    restoration = "OJ_MIS_RestorationSpell"
}
local function registerSpells()
    framework.alchemy.createBasicPotion({
        id = potionIds.alteration,
        name = "Alteration Miscast",
        effect = tes3.effect.burden,
        range = tes3.effectRange.self,
        min = 5,
        max = 25,
        duration = 5,
    })
    framework.alchemy.createBasicPotion({
        id = potionIds.conjuration,
        name = "Conjuration Miscast",
        effect = tes3.effect.damageMagicka,
        range = tes3.effectRange.self,
        min = 5,
        max = 20,
        duration = 5,
    })
    framework.alchemy.createComplexPotion({
        id = potionIds.destruction,
        name = "Destruction Miscast",
        effects = {
            [1] = {
                id = tes3.effect.fireDamage,
                range = tes3.effectRange.self,
                min = 5,
                max = 25,
                radius = 10
            },
            [2] = {
                id = tes3.effect.frostDamage,
                range = tes3.effectRange.self,
                min = 5,
                max = 25,
                radius = 10
            },
            [3] = {
                id = tes3.effect.shockDamage,
                range = tes3.effectRange.self,
                min = 5,
                max = 25,
                radius = 10
            }
        }
    })
    framework.alchemy.createBasicPotion({
        id = potionIds.illusion,
        name = "Illusion Miscast",
        effect = tes3.effect.paralyze,
        range = tes3.effectRange.self,
        duration = 5,
    })
    framework.alchemy.createBasicPotion({
        id = potionIds.mysticism,
        name = "Mysticism Miscast",
        effect = tes3.effect.dispel,
        range = tes3.effectRange.self,
        min = 5,
        max = 25,
        duration = 5,
        radius = 10
    })
    framework.alchemy.createBasicPotion({
        id = potionIds.restoration,
        name = "Restoration Miscast",
        effect = tes3.effect.damageFatigue,
        range = tes3.effectRange.self,
        min = 5,
        max = 25,
        duration = 5
    })
end
event.register("MagickaExpanded:Register", registerSpells)

local schools = {
    [tes3.magicSchool.alteration] = function(e)
        tes3.applyMagicSource({
            reference = e.reference,
            source = potionIds.alteration,
            castChance = 100,
        })
    end,
    [tes3.magicSchool.conjuration] = function(e)
        tes3.applyMagicSource({
            reference = e.reference,
            source = potionIds.conjuration,
            castChance = 100,
        })
    end,
    [tes3.magicSchool.destruction] = function(e)
        tes3.applyMagicSource({
            reference = e.reference,
            source = potionIds.destruction,
            castChance = 100,
        })
    end,
    [tes3.magicSchool.illusion] = function(e)
        tes3.applyMagicSource({
            reference = e.reference,
            source = potionIds.illusion,
            castChance = 100,
        })
    end,
    [tes3.magicSchool.mysticism] = function(e)
        tes3.applyMagicSource({
            reference = e.reference,
            source = potionIds.mysticism,
            castChance = 100,
        })
    end,
    [tes3.magicSchool.restoration] = function(e)
        tes3.applyMagicSource({
            reference = e.reference,
            source = potionIds.restoration,
            castChance = 100,
        })
    end
}
local function onRegister()
    for school, handler in pairs(schools) do
        functions.setSchoolHandler(school, handler)
    end
end
event.register("Miscast:Register", onRegister)