local framework = require("OperatorJack.MagickaExpanded")

tes3.claimSpellEffectId("summonGoblinGrunt", 223)
tes3.claimSpellEffectId("summonGoblinOfficer", 224)
tes3.claimSpellEffectId("summonHulkingFabricant", 225)
tes3.claimSpellEffectId("summonAscendedSleeper", 226)
tes3.claimSpellEffectId("summonDraugr", 227)
tes3.claimSpellEffectId("summonLich", 228)

tes3.claimSpellEffectId("summonOgrim", 252)
tes3.claimSpellEffectId("summonWarDurzog", 253)
tes3.claimSpellEffectId("summonSpriggan", 254)
tes3.claimSpellEffectId("summonCenturionSteam", 255)
tes3.claimSpellEffectId("summonCenturionProjectile", 256)
tes3.claimSpellEffectId("summonAshGhoul", 257)
tes3.claimSpellEffectId("summonAshZombie", 258)
tes3.claimSpellEffectId("summonAshSlave", 259)
tes3.claimSpellEffectId("summonCenturionSpider", 260)
tes3.claimSpellEffectId("summonImperfect", 261)
tes3.claimSpellEffectId("summonGoblinWarchief", 262)

local function getDescription(creatureName)
    return "Этот эффект призывает ".. creatureName .." из Забвения."..
    " Он появляется в шести футах впереди заклинателя и атакует любое существо, которое нападает на заклинателя, пока"..
    " не закончится действие вызывающего эффекта, или вызванное существо не умрет. После смерти или окончания эффекта, вызванное существо"..
    " исчезает, возвращаясь назад, в Забвение. Если вы прочтете заклинание в городе, стража будет атаковать вас и вызванное вами существо, если увидят это."
end

framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonGoblinGrunt,
    name = "Вызов Гоблина",
    description = getDescription("Гоблина"),
    baseCost = 8,
    creatureId = "goblin_grunt",
    icon = "RFD\\RFD_gbl_common.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonGoblinOfficer,
    name = "Вызов Гоблина-офицера",
    description = getDescription("Гоблина-офицера"),
    baseCost = 50,
    creatureId = "goblin_officer",
    icon = "RFD\\RFD_gbl_officer.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonGoblinWarchief,
    name = "Вызов Гоблина-предводителя",
    description = getDescription("Гоблина-предводителя"),
    baseCost = 65,
    creatureId = "OJ_ME_GoblinWarchief",
    icon = "RFD\\RFD_gbl_warchief.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonHulkingFabricant,
    name = "Вызов Гигантского фабриканта",
    description = getDescription("Гигантского фабриканта"),
    baseCost = 65,
    creatureId = "fabricant_hulking",
    icon = "RFD\\RFD_cc_hulking.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonImperfect,
    name = "Вызов Несовершенства",
    description = getDescription("Несовершенство"),
    baseCost = 400,
    creatureId = "imperfect",
    icon = "RFD\\RFD_cc_imperfect.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonAscendedSleeper,
    name = "Вызов Поднявшегося спящего",
    description = getDescription("Поднявшегося спящего"),
    baseCost = 60,
    creatureId = "ascended_sleeper",
    icon = "RFD\\RFD_6h_ascslp.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonDraugr,
    name = "Вызов Драугра",
    description = getDescription("Драугра"),
    baseCost = 15,
    creatureId = "draugr",
    icon = "RFD\\RFD_un_draugr.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonLich,
    name = "Вызов Лича",
    description = getDescription("Лича"),
    baseCost = 47,
    creatureId = "lich",
    icon = "RFD\\RFD_un_lich.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonOgrim,
    name = "Вызов Огрима",
    description = getDescription("Огрима"),
    baseCost = 20,
    creatureId = "ogrim",
    icon = "RFD\\RFD_sm_ogrim.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonWarDurzog,
    name = "Вызов Боевого дурзога",
    description = getDescription("Боевого дурзога"),
    baseCost = 25,
    creatureId = "durzog_war",
    icon = "RFD\\RFD_gbl_durzog.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonSpriggan,
    name = "Вызов Сприггана",
    description = getDescription("Сприггана"),
    baseCost = 30,
    creatureId = "bm_spriggan",
    icon = "RFD\\RFD_sm_spriggan.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonCenturionSteam,
    name = "Вызов Парового центуриона",
    description = getDescription("Парового центуриона"),
    baseCost = 25,
    creatureId = "centurion_steam",
    icon = "RFD\\RFD_dw_steam.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonCenturionProjectile,
    name = "Вызов Центуриона-лучника",
    description = getDescription("Центуриона-лучника"),
    baseCost = 19,
    creatureId = "centurion_projectile",
    icon = "RFD\\RFD_dw_archer.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonCenturionSpider,
    name = "Вызов Паука-центуриона",
    description = getDescription("Паука-центуриона"),
    baseCost = 6,
    creatureId = "centurion_spider",
    icon = "RFD\\RFD_dw_spider.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonAshGhoul,
    name = "Вызов Пепельного упыря",
    description = getDescription("Пепельного упыря"),
    baseCost = 25,
    creatureId = "ash_ghoul",
    icon = "RFD\\RFD_6h_ghoul.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonAshZombie,
    name = "Вызов Пепельного зомби",
    description = getDescription("Пепельного зомби"),
    baseCost = 10,
    creatureId = "ash_zombie",
    icon = "RFD\\RFD_6h_zombie.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonAshSlave,
    name = "Вызов Раба пепла",
    description = getDescription("Раба пепла"),
    baseCost = 7,
    creatureId = "ash_slave",
    icon = "RFD\\RFD_6h_slave.dds"
})
