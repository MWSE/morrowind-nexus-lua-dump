local framework = require("OperatorJack.MagickaExpanded")

tes3.claimSpellEffectId("summonArmorCent", 267)
tes3.claimSpellEffectId("summonArmorCentChamp", 268)
tes3.claimSpellEffectId("summonDraugrHsCrl", 269)
tes3.claimSpellEffectId("summonDraugrLord", 270)
tes3.claimSpellEffectId("summonDridrea", 271)
tes3.claimSpellEffectId("summonDridreaMonarch", 272)
tes3.claimSpellEffectId("summonFrostLich", 273)
tes3.claimSpellEffectId("summonGiant", 274)
tes3.claimSpellEffectId("summonGoblinShaman", 275)
tes3.claimSpellEffectId("summonGreaterLich", 276)
tes3.claimSpellEffectId("summonLamia", 277)
tes3.claimSpellEffectId("summonMammoth", 278)
tes3.claimSpellEffectId("summonMinotaur", 279)
tes3.claimSpellEffectId("summonMudGolem", 280)
tes3.claimSpellEffectId("summonParastylus", 281)
tes3.claimSpellEffectId("summonPlainStrider", 282)
tes3.claimSpellEffectId("summonRaki", 283)
tes3.claimSpellEffectId("callSabreCat", 284)
tes3.claimSpellEffectId("summonSiltStrider", 285)
tes3.claimSpellEffectId("summonSload", 286)
tes3.claimSpellEffectId("summonSwampTroll", 287)
tes3.claimSpellEffectId("summonWelkyndSpirit", 288)
-- Wereboars are no good! 
-- tes3.claimSpellEffectId("callWereboar", 289)
tes3.claimSpellEffectId("summonVelk", 290)
tes3.claimSpellEffectId("summonVermai", 291)
tes3.claimSpellEffectId("summonTrebataur", 292)
tes3.claimSpellEffectId("summonAlfiq", 327)

local function getCallDescription(creatureName)
    return "Этот эффект вызывает " .. creatureName .. " из природы."..
    " Он появляется в шести футах впереди заклинателя и атакует любое существо, которое нападает на заклинателя, пока"..
    " не закончится действие вызывающего эффекта, или вызванное существо не умрет. После смерти или окончания эффекта, вызванное существо"..
    " исчезает, возвращаясь в природу."
end

local function getDescription(creatureName)
    return "Этот эффект призывает ".. creatureName .." из Забвения."..
    " Он появляется в шести футах впереди заклинателя и атакует любое существо, которое нападает на заклинателя, пока"..
    " не закончится действие вызывающего эффекта, или вызванное существо не умрет. После смерти или окончания эффекта, вызванное существо"..
    " исчезает, возвращаясь назад, в Забвение. Если вы прочтете заклинание в городе, стража будет атаковать вас и вызванное вами существо, если увидят это."
end

framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonArmorCent,
    name = "Вызов бронированного центуриона",
    description = getDescription("бронированного центуриона"),
    baseCost = 30,
    creatureId = "T_Dwe_Cre_CentArmor_03",
    icon = "RFD\\RFD_dw_armor.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonArmorCentChamp,
    name = "Вызов бронированного центуриона-чемпиона",
    description = getDescription("бронированного центуриона-чемпиона"),
    baseCost = 50,
    creatureId = "T_Dwe_Cre_CentArmor_06",
    icon = "RFD\\RFD_dw_armorch.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonDraugrHsCrl,
    name = "Вызов Драугра-хускарла",
    description = getDescription("Драугра-хускарла"),
    baseCost = 70,
    creatureId = "T_Sky_Und_DrgrHousc_01",
    icon = "RFD\\RFD_un_draugrhc.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonDraugrLord,
    name = "Вызов Драугра-повелителя",
    description = getDescription("Драугра-повелителя"),
    baseCost = 80,
    creatureId = "T_Sky_Und_DrgrLor_01",
    icon = "RFD\\RFD_un_draugrlrd.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonDridrea,
    name = "Вызов Дридреи",
    description = getDescription("Дридрею"),
    baseCost = 75,
    creatureId = "T_Dae_Cre_Drid_01",
    icon = "RFD\\RFD_tr_drid.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonDridreaMonarch,
    name = "Вызов Дридреи-монарха",
    description = getDescription("Дридрею-монарха"),
    baseCost = 85,
    creatureId = "T_Dae_Cre_DridBs_01",
    icon = "RFD\\RFD_tr_dridmon.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonFrostLich,
    name = "Вызов Морозного лича",
    description = getDescription("Морозного лича"),
    baseCost = 70,
    creatureId = "T_Sky_Und_LichFr_01",
    icon = "RFD\\RFD_un_frlich.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonGiant,
    name = "Вызов Гиганта",
    description = getDescription("Гиганта"),
    baseCost = 60,
    creatureId = "T_Sky_Cre_Giant_01",
    icon = "RFD\\RFD_tr_giant.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonGoblinShaman,
    name = "Вызов Гоблина-шамана",
    description = getDescription("Гоблина-шамана"),
    baseCost = 50,
    creatureId = "T_Mw_Cre_GobShm_01",
    icon = "RFD\\RFD_gbl_shaman.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonGreaterLich,
    name = "Вызов Великого лича",
    description = getDescription("Великого лича"),
    baseCost = 150,
    creatureId = "T_Glb_Und_LichGr_01",
    icon = "RFD\\RFD_un_grlich.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonLamia,
    name = "Вызов Ламии",
    description = getDescription("Ламию"),
    baseCost = 45,
    creatureId = "T_Glb_Cre_Lami_01",
    icon = "RFD\\RFD_tr_lamia.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonMammoth,
    name = "Вызов Мамонта",
    description = getDescription("Мамонта"),
    baseCost = 60,
    creatureId = "T_Sky_Fau_Mamm_01",
    icon = "RFD\\RFD_tr_mammoth.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonMinotaur,
    name = "Вызов Минотавра",
    description = getDescription("Минотавра"),
    baseCost = 90,
    creatureId = "T_Cyr_Cre_Mino_01",
    icon = "RFD\\RFD_tr_minot.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonMudGolem,
    name = "Вызов Грязевого голема",
    description = getDescription("Грязевого голема"),
    baseCost = 26,
    creatureId = "T_Glb_Cre_GolmM_01",
    icon = "RFD\\RFD_tr_mudg.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonParastylus,
    name = "Вызов Парастилуса",
    description = getDescription("Парастилуса"),
    baseCost = 21,
    creatureId = "T_Mw_Fau_Para_01",
    icon = "RFD\\RFD_tr_parast.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonPlainStrider,
    name = "Вызов Плейн страйдера",
    description = getDescription("Плейн страйдера"),
    baseCost = 40,
    creatureId = "T_Mw_Fau_Plstrid_01",
    icon = "RFD\\RFD_tr_plainstr.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonRaki,
    name = "Вызов Раки",
    description = getDescription("Раки"),
    baseCost = 30,
    creatureId = "T_Sky_Fau_Raki_01",
    icon = "RFD\\RFD_tr_raki.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.callSabreCat,
    name = "Вызов Саблезуба",
    description = getCallDescription("Саблезуба"),
    baseCost = 55,
    creatureId = "T_Sky_Fau_SabCat_02",
    icon = "RFD\\RFD_tr_sabr.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonSiltStrider,
    name = "Вызов Силт Страйдера",
    description = getDescription("Силт Страйдера"),
    baseCost = 45,
    creatureId = "T_Mw_Fau_Slstrid_01",
    icon = "RFD\\RFD_tr_siltstr.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonSload,
    name = "Вызов Слоада",
    description = getDescription("Слоада"),
    baseCost = 55,
    creatureId = "T_Glb_Cre_Sloa_01",
    icon = "RFD\\RFD_tr_sload.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonSwampTroll,
    name = "Вызов Болотного Тролля",
    description = getDescription("Болотного Тролля"),
    baseCost = 25,
    creatureId = "T_Mw_Fau_TrllSw_01",
    icon = "RFD\\RFD_tr_swptr.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonWelkyndSpirit,
    name = "Вызов Велкиндского духа",
    description = getDescription("Велкиндского духа"),
    baseCost = 30,
    creatureId = "T_Ayl_Cre_WelkSpr_01",
    icon = "RFD\\RFD_tr_welkynd.dds"
})

framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonVelk,
    name = "Вызов Велька",
    description = getDescription("Велька"),
    baseCost = 15,
    creatureId = "T_Mw_Fau_Velk_01",
    icon = "RFD\\RFD_tr_velk.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonVermai,
    name = "Вызов Вермая",
    description = getDescription("Вермая"),
    baseCost = 25,
    creatureId = "T_Dae_Cre_Verm_01",
    icon = "RFD\\RFD_tr_vermai.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonTrebataur,
    name = "Вызов Требатавра",
    description = getDescription("Требатавра"),
    baseCost = 130,
    creatureId = "T_Cyr_Cre_Mino_02",
    icon = "RFD\\RFD_tr_trebat.dds"
})
framework.effects.conjuration.createBasicSummoningEffect({
    id = tes3.effect.summonAlfiq,
    name = "Вызов Альфика",
    description = getDescription("Альфика"),
    baseCost = 28,
    creatureId = "OJ_ME_SummAlfiqCrea",
    icon = "RFD\\RFD_kj_alfiq.dds"
})
