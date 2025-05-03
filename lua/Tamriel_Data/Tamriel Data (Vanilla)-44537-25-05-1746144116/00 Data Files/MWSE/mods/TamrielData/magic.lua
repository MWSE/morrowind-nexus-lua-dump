local this = {}

local common = require("tamrielData.common")
local config = require("tamrielData.config")

local passwallAlteration = config.passwallAlteration	-- Magic effects are only resolved once when the game begins, but just checking config.passwallAlteration means that the effect's hit sound and VFX will change with the config's value even if the game is not restarted
local passwallIcon = "td\\s\\td_s_passwall.tga"
if passwallAlteration then
	passwallIcon = "td\\s\\td_s_passwall_alt.tga"
end

local northMarkerCos = 0
local northMarkerSin = 0
local mapWidth = 0
local mapHeight = 0
local multiWidth = 0
local multiHeight = 0
local interiorMapOriginX = 0
local interiorMapOriginY = 0
local interiorMultiOriginX = 0
local interiorMultiOriginY = 0
local mapOriginGridX = 0
local mapOriginGridY = 0
local multiOriginGridX = 0
local multiOriginGridY = 0

local corruptionActorID = "T_Glb_Cre_Gremlin_01"	-- A funny default, just in case
local corruptionCasted = false

if config.summoningSpells == true then
	tes3.claimSpellEffectId("T_summon_Devourer", 2090)
	tes3.claimSpellEffectId("T_summon_DremArch", 2091)
	tes3.claimSpellEffectId("T_summon_DremCast", 2092)
	tes3.claimSpellEffectId("T_summon_Guardian", 2093)
	tes3.claimSpellEffectId("T_summon_LesserClfr", 2094)
	tes3.claimSpellEffectId("T_summon_Ogrim", 2095)
	tes3.claimSpellEffectId("T_summon_Seducer", 2096)
	tes3.claimSpellEffectId("T_summon_SeducerDark", 2097)
	tes3.claimSpellEffectId("T_summon_Vermai", 2098)
	tes3.claimSpellEffectId("T_summon_AtroStormMon", 2099)
	tes3.claimSpellEffectId("T_summon_IceWraith", 2100)
	tes3.claimSpellEffectId("T_summon_DweSpectre", 2101)
	tes3.claimSpellEffectId("T_summon_SteamCent", 2102)
	tes3.claimSpellEffectId("T_summon_SpiderCent", 2103)
	tes3.claimSpellEffectId("T_summon_WelkyndSpirit", 2104)
	tes3.claimSpellEffectId("T_summon_Auroran", 2105)
	tes3.claimSpellEffectId("T_summon_Herne", 2107)
	tes3.claimSpellEffectId("T_summon_Morphoid", 2108)
	tes3.claimSpellEffectId("T_summon_Draugr", 2109)
	tes3.claimSpellEffectId("T_summon_Spriggan", 2110)
	tes3.claimSpellEffectId("T_summon_BoneldGr", 2117)
	tes3.claimSpellEffectId("T_summon_Ghost", 2126)
	tes3.claimSpellEffectId("T_summon_Wraith", 2127)
	tes3.claimSpellEffectId("T_summon_Barrowguard", 2128)
	tes3.claimSpellEffectId("T_summon_MinoBarrowguard", 2129)
	tes3.claimSpellEffectId("T_summon_SkeletonChampion", 2130)
	tes3.claimSpellEffectId("T_summon_AtroFrostMon", 2131)
	tes3.claimSpellEffectId("T_summon_SpiderDaedra", 2146)
end

if config.boundSpells == true then
	tes3.claimSpellEffectId("T_bound_Greaves", 2111)
	tes3.claimSpellEffectId("T_bound_Waraxe", 2112)
	tes3.claimSpellEffectId("T_bound_Warhammer", 2113)
	tes3.claimSpellEffectId("T_bound_HammerResdayn", 2114)
	tes3.claimSpellEffectId("T_bound_RazorResdayn", 2115)
	tes3.claimSpellEffectId("T_bound_Pauldrons", 2116)
	--tes3.claimSpellEffectId("T_bound_ThrowingKnives", 2118)
	tes3.claimSpellEffectId("T_bound_Greatsword", 2145)
end

if config.interventionSpells == true then
	tes3.claimSpellEffectId("T_intervention_Kyne", 2122)
end

if config.miscSpells == true then
	tes3.claimSpellEffectId("T_mysticism_Passwall", 2106)
	tes3.claimSpellEffectId("T_mysticism_BanishDae", 2119)
	tes3.claimSpellEffectId("T_mysticism_ReflectDmg", 2120)
	tes3.claimSpellEffectId("T_mysticism_DetHuman", 2121)
	tes3.claimSpellEffectId("T_alteration_RadShield", 2123)
	tes3.claimSpellEffectId("T_alteration_Wabbajack", 2124)
	tes3.claimSpellEffectId("T_mysticism_Insight", 2125)
	tes3.claimSpellEffectId("T_restoration_ArmorResartus", 2132)
	tes3.claimSpellEffectId("T_restoration_WeaponResartus", 2133)
	tes3.claimSpellEffectId("T_conjuration_Corruption", 2134)
	tes3.claimSpellEffectId("T_conjuration_CorruptionSummon", 2135)
	tes3.claimSpellEffectId("T_illusion_DistractCreature", 2136)
	tes3.claimSpellEffectId("T_illusion_DistractHumanoid", 2137)
	tes3.claimSpellEffectId("T_destruction_GazeOfVeloth", 2138)
	tes3.claimSpellEffectId("T_mysticism_DetEnemy", 2139)
	tes3.claimSpellEffectId("T_alteration_WabbajackTrans", 2140)
	tes3.claimSpellEffectId("T_mysticism_DetInvisibility", 2141)
	tes3.claimSpellEffectId("T_mysticism_Blink", 2142)
	tes3.claimSpellEffectId("T_restoration_FortifyCasting", 2143)
	--tes3.claimSpellEffectId("T_illusion_PrismaticLight", 2144)
end

-- The effect costs for most summons were initially calculated by mort using a formula (dependent on a creature's health and soul) that is now lost and were then adjusted as seemed reasonable.
-- Calculations have provided a new formula: Effect Cost = (.16 * Health) + (.035 * Soul); most of the old values are in close agreement with the new formula and have thus been left unchanged.
-- effect id, effect name, creature id, effect mana cost, icon, effect description
local td_summon_effects = {
	{ tes3.effect.T_summon_Devourer, common.i18n("magic.summonDevourer"), "T_Dae_Cre_Devourer_01", 52, "td\\s\\td_s_summ_dev.dds", common.i18n("magic.summonDevourerDesc")},
	{ tes3.effect.T_summon_DremArch, common.i18n("magic.summonDremoraArcher"), "T_Dae_Cre_Drem_Arch_01", 33, "td\\s\\td_s_sum_drm_arch.dds", common.i18n("magic.summonDremoraArcherDesc")},
	{ tes3.effect.T_summon_DremCast, common.i18n("magic.summonDremoraCaster"), "T_Dae_Cre_Drem_Cast_01", 31, "td\\s\\td_s_sum_drm_mage.dds", common.i18n("magic.summonDremoraCasterDesc")},
	{ tes3.effect.T_summon_Guardian, common.i18n("magic.summonGuardian"), "T_Dae_Cre_Guardian_01", 69, "td\\s\\td_s_sum_guard.dds", common.i18n("magic.summonGuardianDesc")},
	{ tes3.effect.T_summon_LesserClfr, common.i18n("magic.summonLesserClannfear"), "T_Dae_Cre_LesserClfr_01", 19, "td\\s\\td_s_sum_lsr_clan.dds", common.i18n("magic.summonLesserClannfearDesc")},
	{ tes3.effect.T_summon_Ogrim, common.i18n("magic.summonOgrim"), "ogrim", 33, "td\\s\\td_s_summ_ogrim.dds", common.i18n("magic.summonOgrimDesc")},
	{ tes3.effect.T_summon_Seducer, common.i18n("magic.summonSeducer"), "T_Dae_Cre_Seduc_01", 52, "td\\s\\td_s_summ_sed.dds", common.i18n("magic.summonSeducerDesc")},
	{ tes3.effect.T_summon_SeducerDark, common.i18n("magic.summonSeducerDark"), "T_Dae_Cre_SeducDark_02", 75, "td\\s\\td_s_summ_d_sed.dds", common.i18n("magic.summonSeducerDarkDesc")},
	{ tes3.effect.T_summon_Vermai, common.i18n("magic.summonVermai"), "T_Dae_Cre_Verm_01", 29, "td\\s\\td_s_summ_vermai.dds", common.i18n("magic.summonVermaiDesc")},
	{ tes3.effect.T_summon_AtroStormMon, common.i18n("magic.summonStormMonarch"), "T_Dae_Cre_MonarchSt_01", 60, "td\\s\\td_s_sum_stm_monch.dds", common.i18n("magic.summonStormMonarchDesc")},
	{ tes3.effect.T_summon_IceWraith, common.i18n("magic.summonIceWraith"), "T_Sky_Cre_IceWr_01", 35, "td\\s\\td_s_sum_ice_wrth.dds", common.i18n("magic.summonIceWraithDesc")},
	{ tes3.effect.T_summon_DweSpectre, common.i18n("magic.summonDweSpectre"), "dwarven ghost", 17, "td\\s\\td_s_sum_dwe_spctre.dds", common.i18n("magic.summonDweSpectreDesc")},
	{ tes3.effect.T_summon_SteamCent, common.i18n("magic.summonSteamCent"), "centurion_steam", 29, "td\\s\\td_s_sum_dwe_cent.dds", common.i18n("magic.summonSteamCentDesc")},
	{ tes3.effect.T_summon_SpiderCent, common.i18n("magic.summonSpiderCent"), "centurion_spider", 15, "td\\s\\td_s_sum_dwe_spdr.dds", common.i18n("magic.summonSpiderCentDesc")},
	{ tes3.effect.T_summon_WelkyndSpirit, common.i18n("magic.summonWelkyndSpirit"), "T_Ayl_Cre_WelkSpr_01", 29, "td\\s\\td_s_sum_welk_srt.dds", common.i18n("magic.summonWelkyndSpiritDesc")},
	{ tes3.effect.T_summon_Auroran, common.i18n("magic.summonAuroran"), "T_Dae_Cre_Auroran_01", 46, "td\\s\\td_s_sum_auro.dds", common.i18n("magic.summonAuroranDesc")},
	{ tes3.effect.T_summon_Herne, common.i18n("magic.summonHerne"), "T_Dae_Cre_Herne_01", 18, "td\\s\\td_s_sum_herne.dds", common.i18n("magic.summonHerneDesc")},
	{ tes3.effect.T_summon_Morphoid, common.i18n("magic.summonMorphoid"), "T_Dae_Cre_Morphoid_01", 21, "td\\s\\td_s_sum_morph.dds", common.i18n("magic.summonMorphoidDesc")},
	{ tes3.effect.T_summon_Draugr, common.i18n("magic.summonDraugr"), "T_Sky_Und_Drgr_01", 29, "td\\s\\td_s_sum_draugr.dds", common.i18n("magic.summonDraugrDesc")},
	{ tes3.effect.T_summon_Spriggan, common.i18n("magic.summonSpriggan"), "T_Sky_Cre_Spriggan_01", 48, "td\\s\\td_s_sum_sprig.dds", common.i18n("magic.summonSprigganDesc")},
	{ tes3.effect.T_summon_BoneldGr, common.i18n("magic.summonGreaterBonelord"), "T_Mw_Und_BoneldGr_01", 71, "td\\s\\td_s_sum_gtr_bnlrd.dds", common.i18n("magic.summonGreaterBonelordDesc")},
	{ tes3.effect.T_summon_Ghost, common.i18n("magic.summonGhost"), "T_Cyr_Und_Ghst_01", 7, "td\\s\\td_s_summ_ghost.dds", common.i18n("magic.summonGhostDesc")},
	{ tes3.effect.T_summon_Wraith, common.i18n("magic.summonWraith"), "T_Cyr_Und_Wrth_01", 49, "td\\s\\td_s_summ_wraith.dds", common.i18n("magic.summonWraithDesc")},
	{ tes3.effect.T_summon_Barrowguard, common.i18n("magic.summonBarrowguard"), "T_Cyr_Und_Mum_01", 11, "td\\s\\td_s_summ_brwgurd.dds", common.i18n("magic.summonBarrowguardDesc")},
	{ tes3.effect.T_summon_MinoBarrowguard, common.i18n("magic.summonMinoBarrowguard"), "T_Cyr_Und_MinoBarrow_01", 57, "td\\s\\td_s_summ_mintur.dds", common.i18n("magic.summonMinoBarrowguardDesc")},
	{ tes3.effect.T_summon_SkeletonChampion, common.i18n("magic.summonSkeletonChampion"), "T_Glb_Und_SkelCmpGls_01", 32, "td\\s\\td_s_sum_skele_c.dds", common.i18n("magic.summonSkeletonChampionDesc")},
	{ tes3.effect.T_summon_AtroFrostMon, common.i18n("magic.summonFrostMonarch"), "T_Dae_Cre_MonarchFr_01", 47, "td\\s\\td_s_sum_fst_monch.dds", common.i18n("magic.summonFrostMonarchDesc")},
	{ tes3.effect.T_summon_SpiderDaedra, common.i18n("magic.summonSpiderDaedra"), "T_Dae_Cre_SpiderDae_01", 42, "td\\s\\td_s_sum_spidr_dae.dds", common.i18n("magic.summonSpiderDaedraDesc")},
}

-- effect id, effect name, item id, 2nd item ID, effect mana cost, icon, effect description
local td_bound_effects = {
	{ tes3.effect.T_bound_Greaves, common.i18n("magic.boundGreaves"), "T_Com_Bound_Greaves_01", "", 2, "td\\s\\td_s_bnd_grves.dds", common.i18n("magic.boundGreavesDesc")},
	{ tes3.effect.T_bound_Waraxe, common.i18n("magic.boundWarAxe"), "T_Com_Bound_WarAxe_01", "", 2, "td\\s\\td_s_bnd_waxe.dds", common.i18n("magic.boundWarAxeDesc")},
	{ tes3.effect.T_bound_Warhammer, common.i18n("magic.boundWarhammer"), "T_Com_Bound_Warhammer_01", "", 2, "td\\s\\td_s_bnd_wham.dds", common.i18n("magic.boundWarhammerDesc")},
	{ tes3.effect.T_bound_HammerResdayn, "", "T_Com_Bound_Warhammer_01", "", 2, "td\\s\\td_s_bnd_res_ham.dds", ""},
	{ tes3.effect.T_bound_RazorResdayn, "", "bound_dagger", "", 2, "td\\s\\td_s_bnd_red_razor.dds", ""},
	{ tes3.effect.T_bound_Pauldrons, common.i18n("magic.boundPauldrons"), "T_Com_Bound_PauldronL_01", "T_Com_Bound_PauldronR_01", 2, "td\\s\\td_s_bnd_pldrn.dds", common.i18n("magic.boundPauldronsDesc")},
	{ tes3.effect.T_bound_Greatsword, common.i18n("magic.boundGreatsword"), "T_Com_Bound_Greatsword_01", "", 2, "td\\s\\td_s_bnd_clymr.dds", common.i18n("magic.boundGreatswordDesc")},
	--{ tes3.effect.T_bound_ThrowingKnives, common.i18n("magic.boundThrowingKnives"), "T_Com_Bound_ThrowingKnife_01", "", 2, "td\\s\\td_s_bnd_knives.dds", common.i18n("magic.boundThrowingKnivesDesc")},
}

-- effect id, effect name, effect mana cost, icon, effect description
local td_intervention_effects = {
	{ tes3.effect.T_intervention_Kyne, common.i18n("magic.interventionKyne"), 150, "td\\s\\td_s_int_kyne.tga", common.i18n("magic.interventionKyneDesc")},
}

-- effect id, effect name, effect mana cost, icon, effect description
local td_misc_effects = {
	{ tes3.effect.T_mysticism_Passwall, common.i18n("magic.miscPasswall"), 750, passwallIcon, common.i18n("magic.miscPasswallDesc")},
	{ tes3.effect.T_mysticism_BanishDae, common.i18n("magic.miscBanish"), 128, "td\\s\\td_s_ban_daedra.tga", common.i18n("magic.miscBanishDesc")},
	{ tes3.effect.T_mysticism_ReflectDmg, common.i18n("magic.miscReflectDamage"), 20, "td\\s\\td_s_ref_dam.tga", common.i18n("magic.miscReflectDamageDesc")},
	{ tes3.effect.T_mysticism_DetHuman, common.i18n("magic.miscDetectHumanoid"), 1.5, "td\\s\\td_s_det_hum.tga", common.i18n("magic.miscDetectHumanoidDesc")},
	{ tes3.effect.T_alteration_RadShield, common.i18n("magic.miscRadiantShield"), 5, "td\\s\\td_s_radiant_shield.tga", common.i18n("magic.miscRadiantShieldDesc")},
	{ tes3.effect.T_alteration_Wabbajack, common.i18n("magic.miscWabbajack"), 22, "td\\s\\td_s_wabbajack.tga", common.i18n("magic.miscWabbajackDesc")},
	{ tes3.effect.T_mysticism_Insight, common.i18n("magic.miscInsight"), 10, "td\\s\\td_s_insight.tga", common.i18n("magic.miscInsightDesc")},
	{ tes3.effect.T_restoration_ArmorResartus, common.i18n("magic.miscArmorResartus"), 60, "td\\s\\td_s_restore_ar.tga", common.i18n("magic.miscArmorResartusDesc")},
	{ tes3.effect.T_restoration_WeaponResartus, common.i18n("magic.miscWeaponResartus"), 120, "td\\s\\td_s_restore_wpn.tga", common.i18n("magic.miscWeaponResartusDesc")},
	{ tes3.effect.T_conjuration_Corruption, common.i18n("magic.miscCorruption"), 40, "td\\s\\td_s_skull_corr.tga", common.i18n("magic.miscCorruptionDesc")},
	{ tes3.effect.T_conjuration_CorruptionSummon, common.i18n("magic.miscCorruption"), 0, "td\\s\\td_s_skull_corr.tga", common.i18n("magic.miscCorruptionDesc")},
	{ tes3.effect.T_illusion_DistractCreature, common.i18n("magic.miscDistractCreature"), 0.5, "td\\s\\td_s_dist_cre.tga", common.i18n("magic.miscDistractCreatureDesc")},
	{ tes3.effect.T_illusion_DistractHumanoid, common.i18n("magic.miscDistractHumanoid"), 1, "td\\s\\td_s_dist_hum.tga", common.i18n("magic.miscDistractHumanoidDesc")},
	{ tes3.effect.T_destruction_GazeOfVeloth, common.i18n("magic.miscGazeOfVeloth"), 80, "td\\s\\td_s_gaze_veloth.tga", common.i18n("magic.miscGazeOfVelothDesc")},
	{ tes3.effect.T_mysticism_DetEnemy, common.i18n("magic.miscDetectEnemy"), 2.25, "td\\s\\td_s_det_enemy.tga", common.i18n("magic.miscDetectEnemyDesc")},
	{ tes3.effect.T_alteration_WabbajackTrans, common.i18n("magic.miscWabbajack"), 0, "td\\s\\td_s_wabbajack.tga", common.i18n("magic.miscWabbajackDesc")},
	{ tes3.effect.T_mysticism_DetInvisibility, common.i18n("magic.miscDetectInvisibility"), 3, "td\\s\\td_s_det_invisibility.tga", common.i18n("magic.miscDetectInvisibilityDesc")},		-- Not sure about the cost on this one. 3 just seems like a lot for such a niche effect, even though it nicely fits the pattern set by the other detect effects.
	{ tes3.effect.T_mysticism_Blink, common.i18n("magic.miscBlink"), 10, "td\\s\\td_s_blink.tga", common.i18n("magic.miscBlinkDesc")},
	{ tes3.effect.T_restoration_FortifyCasting, common.i18n("magic.miscFortifyCasting"), 1, "td\\s\\td_s_ftfy_cast.tga", common.i18n("magic.miscFortifyCastingDesc")},
	--{ tes3.effect.T_illusion_PrismaticLight, common.i18n("magic.miscPrismaticLight"), 0.4, "td\\s\\td_s_p_light.tga", common.i18n("magic.miscPrismaticLightDesc")},
}

-- spell id, cast type, spell name, spell mana cost, 1st effect id, 1st range type, 1st area, 1st duration, 1st minimum magnitude, 1st maximum magnitude, ...
local td_summon_spells = {
	{ "T_Com_Cnj_SummonDevourer", tes3.spellType.spell, common.i18n("magic.summonDevourer"), 156, { tes3.effect.T_summon_Devourer }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_SummonDremoraArcher", tes3.spellType.spell, common.i18n("magic.summonDremoraArcher"), 98, { tes3.effect.T_summon_DremArch }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_SummonDremoraCaster", tes3.spellType.spell, common.i18n("magic.summonDremoraCaster"), 93, { tes3.effect.T_summon_DremCast }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_SummonGuardian", tes3.spellType.spell, common.i18n("magic.summonGuardian"), 155, { tes3.effect.T_summon_Guardian }, tes3.effectRange.self, 0, 45, 1, 1 },
	{ "T_Com_Cnj_SummonLesserClannfear", tes3.spellType.spell, common.i18n("magic.summonLesserClannfear"), 57, { tes3.effect.T_summon_LesserClfr }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_SummonOgrim", tes3.spellType.spell, common.i18n("magic.summonOgrim"), 99, { tes3.effect.T_summon_Ogrim }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_SummonSeducer", tes3.spellType.spell, common.i18n("magic.summonSeducer"), 156, { tes3.effect.T_summon_Seducer }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_SummonSeducerDark", tes3.spellType.spell, common.i18n("magic.summonSeducerDark"), 169, { tes3.effect.T_summon_SeducerDark }, tes3.effectRange.self, 0, 45, 1, 1 },
	{ "T_Com_Cnj_SummonVermai", tes3.spellType.spell, common.i18n("magic.summonVermai"), 88, { tes3.effect.T_summon_Vermai }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_SummonStormMonarch", tes3.spellType.spell, common.i18n("magic.summonStormMonarch"), 180, { tes3.effect.T_summon_AtroStormMon }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Nor_Cnj_SummonIceWraith", tes3.spellType.spell, common.i18n("magic.summonIceWraith"), 105, { tes3.effect.T_summon_IceWraith }, tes3.effectRange.self, 60, 1, 1 },
	{ "T_Dwe_Cnj_Uni_SummonDweSpectre", tes3.spellType.spell, common.i18n("magic.summonDweSpectre"), 52, { tes3.effect.T_summon_DweSpectre }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Dwe_Cnj_Uni_SummonSteamCent", tes3.spellType.spell, common.i18n("magic.summonSteamCent"), 88, { tes3.effect.T_summon_SteamCent }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Dwe_Cnj_Uni_SummonSpiderCent", tes3.spellType.spell, common.i18n("magic.summonSpiderCent"), 45, { tes3.effect.T_summon_SpiderCent }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Ayl_Cnj_SummonWelkyndSpirit", tes3.spellType.spell, common.i18n("magic.summonWelkyndSpirit"), 78, { tes3.effect.T_summon_WelkyndSpirit }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_SummonAuroran", tes3.spellType.spell, common.i18n("magic.summonAuroran"), 138, { tes3.effect.T_summon_Auroran }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_SummonHerne", tes3.spellType.spell, common.i18n("magic.summonHerne"), 54, { tes3.effect.T_summon_Herne }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_SummonMorphoid", tes3.spellType.spell, common.i18n("magic.summonMorphoid"), 63, { tes3.effect.T_summon_Morphoid }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Nor_Cnj_SummonDraugr", tes3.spellType.spell, common.i18n("magic.summonDraugr"), 78, { tes3.effect.T_summon_Draugr }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Nor_Cnj_SummonSpriggan", tes3.spellType.spell, common.i18n("magic.summonSpriggan"), 144, { tes3.effect.T_summon_Spriggan }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_De_Cnj_SummonGreaterBonelord", tes3.spellType.spell, common.i18n("magic.summonGreaterBonelord"), 160, { tes3.effect.T_summon_BoneldGr }, tes3.effectRange.self, 0, 45, 1, 1 },
	{ "T_Cr_Cnj_AylSorcKSummon1", tes3.spellType.spell, nil, 40, { tes3.effect.T_summon_Auroran }, tes3.effectRange.self, 0, 40, 1, 1 },
	{ "T_Cr_Cnj_AylSorcKSummon3", tes3.spellType.spell, nil, 25, { tes3.effect.T_summon_WelkyndSpirit }, tes3.effectRange.self, 0, 40, 1, 1 },
	{ "T_Cyr_Cnj_SummonGhost", tes3.spellType.spell, common.i18n("magic.summonGhost"), 21, { tes3.effect.T_summon_Ghost }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Cyr_Cnj_SummonWraith", tes3.spellType.spell, common.i18n("magic.summonWraith"), 147, { tes3.effect.T_summon_Wraith }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Cyr_Cnj_SummonBarrowguard", tes3.spellType.spell, common.i18n("magic.summonBarrowguard"), 33, { tes3.effect.T_summon_Barrowguard }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Cyr_Cnj_SummonMinoBarrowguard", tes3.spellType.spell, common.i18n("magic.summonMinoBarrowguard"), 171, { tes3.effect.T_summon_MinoBarrowguard }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_SummonSkeletonChamp", tes3.spellType.spell, common.i18n("magic.summonSkeletonChampion"), 96, { tes3.effect.T_summon_SkeletonChampion }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_SummonFrostMonarch", tes3.spellType.spell, common.i18n("magic.summonFrostMonarch"), 141, { tes3.effect.T_summon_AtroFrostMon }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_SummonSpiderDaedra", tes3.spellType.spell, common.i18n("magic.summonSpiderDaedra"), 126, { tes3.effect.T_summon_SpiderDaedra }, tes3.effectRange.self, 0, 60, 1, 1 },
}

-- spell id, cast type, spell name, spell mana cost, 1st effect id, 1st range type, 1st area, 1st duration, 1st minimum magnitude, 1st maximum magnitude, ...
local td_bound_spells = {
	{ "T_Com_Cnj_BoundGreaves", tes3.spellType.spell, common.i18n("magic.boundGreaves"), 6, { tes3.effect.T_bound_Greaves }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_BoundWarAxe", tes3.spellType.spell, common.i18n("magic.boundWarAxe"), 6, { tes3.effect.T_bound_Waraxe }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_BoundWarhammer", tes3.spellType.spell, common.i18n("magic.boundWarhammer"), 6, { tes3.effect.T_bound_Warhammer }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_De_Cnj_Uni_BoundHammerResdayn", tes3.spellType.spell, nil, 6, { tes3.effect.T_bound_HammerResdayn }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_De_Cnj_Uni_BoundRazorOResdayn", tes3.spellType.spell, nil, 6, { tes3.effect.T_bound_RazorResdayn }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_BoundPauldron", tes3.spellType.spell, common.i18n("magic.boundPauldrons"), 6, { tes3.effect.T_bound_Pauldrons }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Com_Cnj_BoundGreatsword", tes3.spellType.spell, common.i18n("magic.boundGreatsword"), 6, { tes3.effect.T_bound_Greatsword }, tes3.effectRange.self, 0, 60, 1, 1 },
	--{ "T_Com_Cnj_BoundThrowingKnives", tes3.spellType.spell, common.i18n("magic.boundThrowingKnives"), 6, { tes3.effect.T_bound_ThrowingKnives }, tes3.effectRange.self, 0, 60, 1, 1 },
}

-- spell id, cast type, spell name, spell mana cost, 1st effect id, 1st range type, 1st area, 1st duration, 1st minimum magnitude, 1st maximum magnitude, ...
local td_intervention_spells = {
	{ "T_Nor_Mys_KynesIntervention", tes3.spellType.spell, common.i18n("magic.interventionKyne"), 8, { tes3.effect.T_intervention_Kyne }, tes3.effectRange.self, 0, 0, 1, 1 },
}

-- spell id, cast type, spell name, spell mana cost, (1st effect id, attribute id, skill id), 1st range type, 1st area, 1st duration, 1st minimum magnitude, 1st maximum magnitude, ...
local td_misc_spells = {
	{ "T_Com_Mys_UNI_Passwall", tes3.spellType.spell, common.i18n("magic.miscPasswall"), 96, { tes3.effect.T_mysticism_Passwall }, tes3.effectRange.touch, 25, 0, 0, 0 },
	{ "T_Com_Mys_BanishDaedra", tes3.spellType.spell, common.i18n("magic.miscBanish"), 64, { tes3.effect.T_mysticism_BanishDae }, tes3.effectRange.touch, 0, 0, 10, 10 },
	{ "T_Com_Mys_ReflectDamage", tes3.spellType.spell, common.i18n("magic.miscReflectDamage"), 76, { tes3.effect.T_mysticism_ReflectDmg }, tes3.effectRange.self, 0, 5, 10, 20 },
	{ "T_Com_Mys_DetectHumanoid", tes3.spellType.spell, common.i18n("magic.miscDetectHumanoid"), 38, { tes3.effect.T_mysticism_DetHuman }, tes3.effectRange.self, 0, 5, 50, 150 },
	{ "T_Ayl_Alt_RadiantShield", tes3.spellType.spell, common.i18n("magic.miscRadiantShield"), 75, { tes3.effect.T_alteration_RadShield }, tes3.effectRange.self, 0, 30, 10, 10 },
	{ "T_Cr_Alt_AuroranShield", tes3.spellType.ability, nil, nil, { tes3.effect.T_alteration_RadShield }, tes3.effectRange.self, 0, 0, 20, 20 },
	{ "T_Cr_Alt_AylSorcKLightShield", tes3.spellType.spell, common.i18n("magic.miscRadiantShield"), 10, { tes3.effect.T_alteration_RadShield }, tes3.effectRange.self, 0, 12, 10, 10, { tes3.effect.light }, tes3.effectRange.self, 0, 12, 20, 20 },
	{ "T_Com_Mys_Insight", tes3.spellType.spell, common.i18n("magic.miscInsight"), 76, { tes3.effect.T_mysticism_Insight }, tes3.effectRange.self, 0, 10, 15, 15 },
	{ "T_Com_Res_ArmorResartus", tes3.spellType.spell, common.i18n("magic.miscArmorResartus"), 90, { tes3.effect.T_restoration_ArmorResartus }, tes3.effectRange.self, 0, 0, 20, 40 },
	{ "T_Com_Res_WeaponResartus", tes3.spellType.spell, common.i18n("magic.miscWeaponResartus"), 90, { tes3.effect.T_restoration_WeaponResartus }, tes3.effectRange.self, 0, 0, 10, 20 },
	{ "T_Dae_Cnj_UNI_CorruptionSummon", tes3.spellType.spell, common.i18n("magic.miscCorruption"), 0, { tes3.effect.T_conjuration_CorruptionSummon }, tes3.effectRange.self, 0, 30, 1, 1 },
	{ "T_Com_Ilu_DistractCreature", tes3.spellType.spell, common.i18n("magic.miscDistractCreature"), 11, { tes3.effect.T_illusion_DistractCreature }, tes3.effectRange.target, 0, 15, 20, 20 },
	{ "T_Com_Ilu_DistractHumanoid", tes3.spellType.spell, common.i18n("magic.miscDistractHumanoid"), 22, { tes3.effect.T_illusion_DistractHumanoid }, tes3.effectRange.target, 0, 15, 20, 20 },
	{ "T_Com_Mys_DetectEnemy", tes3.spellType.spell, common.i18n("magic.miscDetectEnemy"), 57, { tes3.effect.T_mysticism_DetEnemy }, tes3.effectRange.self, 0, 5, 50, 150 },
	{ "T_Dae_Alt_UNI_WabbajackTrans", tes3.spellType.spell, common.i18n("magic.miscWabbajack"), 0, { tes3.effect.T_alteration_WabbajackTrans }, tes3.effectRange.touch, 0, 16, 1, 1 },
	{ "T_Com_Mys_DetectInvisibility", tes3.spellType.spell, common.i18n("magic.miscDetectInvisibility"), 76, { tes3.effect.T_mysticism_DetInvisibility }, tes3.effectRange.self, 0, 5, 50, 150 },
	{ "T_Com_Mys_Blink", tes3.spellType.spell, common.i18n("magic.miscBlink"), 25, { tes3.effect.T_mysticism_Blink }, tes3.effectRange.self, 0, 0, 50, 50 },
	--{ "T_Cr_Ab_AuroranLight", tes3.spellType.ability, nil, nil, { tes3.effect.T_illusion_PrismaticLight }, tes3.effectRange.self, 0, 0, 20, 20 },	-- There should be a separate, higher magnitude ability for the radiant Aurorans that will be affected instead
	{ "T_UNI_SaintTelynBlessing", tes3.spellType.ability, nil, nil, { tes3.effect.T_mysticism_Insight }, tes3.effectRange.self, 0, 0, 10, 10 },
}

-- enchantment id, (1st effect id, attribute id, skill id), 1st range type, 1st area, 1st duration, 1st minimum magnitude, 1st maximum magnitude, ...
local td_enchantments = {
	{ "T_Once_SummonDremoraArcher60", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_DremArch }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_SummonDremoraCaster60", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_DremCast }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_SummonGuardian60", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_Guardian }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_SummonLesserClannfear60", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_LesserClfr }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_SummonOgrim60", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_Ogrim }, tes3.effectRange.self, 0, 60, 1, 1, nil },
	{ "T_Once_SummonOgrim120", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_Ogrim }, tes3.effectRange.self, 0, 120, 1, 1, nil },
	{ "T_Once_SummonSeducer60", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_Seducer }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_SummonSeducerDark60", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_SeducerDark }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_SummonVermai60", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_Vermai }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_SummonVermai120", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_Vermai }, tes3.effectRange.self, 0, 120, 1, 1 },
	{ "T_Once_SummonSkeletonChamp120", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_SkeletonChampion }, tes3.effectRange.self, 0, 120, 1, 1 },
	{ "T_Once_SummonFrostMonarch120", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_AtroFrostMon }, tes3.effectRange.self, 0, 120, 1, 1 },
	{ "T_Once_SummonStormMonarch60", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_AtroStormMon }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_SummonWelkyndSpirit60", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_WelkyndSpirit }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_SummonAuroran60", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_Auroran }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_SummonHerne60", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_Herne }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_SummonMorphoid60", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_Morphoid }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_SummonBonelordGr60", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_BoneldGr }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_AylDaedricHerald1", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_WelkyndSpirit }, tes3.effectRange.self, 0, 30, 1, 1 },
	{ "T_Once_AylDaedricHerald2", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_Auroran }, tes3.effectRange.self, 0, 30, 1, 1 },
	{ "T_Once_AylLoreArmor1", tes3.enchantmentType.castOnce, { tes3.effect.T_alteration_RadShield }, tes3.effectRange.self, 0, 30, 20, 20 },
	--{ "T_Once_AylCavernsTruth", tes3.enchantmentType.castOnce, { tes3.effect.T_illusion_PrismaticLight }, tes3.effectRange.self, 0, 90, 15, 15 },
	{ "T_Once_KynesIntervention", tes3.enchantmentType.castOnce, { tes3.effect.T_intervention_Kyne }, tes3.effectRange.self, 0, 1, 1, 1 },
	{ "T_Once_QuelledGeas", tes3.enchantmentType.castOnce, { tes3.effect.T_mysticism_BanishDae }, tes3.effectRange.touch, 0, 1, 10, 15 },
	{ "T_Once_LordMhasFortress", tes3.enchantmentType.castOnce, { tes3.effect.boundBoots }, tes3.effectRange.self, 0, 90, 1, 1, { tes3.effect.T_bound_Greaves }, tes3.effectRange.self, 0, 90, 1, 1, { tes3.effect.boundCuirass }, tes3.effectRange.self, 0, 90, 1, 1, { tes3.effect.T_bound_Pauldrons }, tes3.effectRange.self, 0, 90, 1, 1,
								{ tes3.effect.boundGloves }, tes3.effectRange.self, 0, 90, 1, 1, { tes3.effect.boundHelm }, tes3.effectRange.self, 0, 90, 1, 1, { tes3.effect.boundShield }, tes3.effectRange.self, 0, 90, 1, 1, { tes3.effect.T_bound_Warhammer }, tes3.effectRange.self, 0, 90, 1, 1 },
	{ "T_Once_SummonDremoraAll60", tes3.enchantmentType.castOnce, { tes3.effect.summonDremora }, tes3.effectRange.self, 0, 60, 1, 1, { tes3.effect.T_summon_DremArch }, tes3.effectRange.self, 0, 60, 1, 1, { tes3.effect.T_summon_DremCast }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_DaedraBane", tes3.enchantmentType.castOnce, { tes3.effect.T_mysticism_BanishDae }, tes3.effectRange.touch, 0, 1, 10, 15 },
	{ "T_Once_BlackSpirits", tes3.enchantmentType.castOnce, { tes3.effect.T_mysticism_BanishDae }, tes3.effectRange.target, 25, 1, 10, 40 },
	{ "T_Once_Diversion", tes3.enchantmentType.castOnce, { tes3.effect.T_illusion_DistractHumanoid }, tes3.effectRange.target, 0, 30, 10, 30 },
	{ "T_Once_Scent", tes3.enchantmentType.castOnce, { tes3.effect.T_illusion_DistractCreature }, tes3.effectRange.target, 0, 30, 10, 30 },
	{ "T_Once_DarothrilDisorder", tes3.enchantmentType.castOnce, { tes3.effect.T_illusion_DistractCreature }, tes3.effectRange.target, 20, 20, 50, 50, { tes3.effect.T_illusion_DistractHumanoid }, tes3.effectRange.target, 20, 20, 50, 50 },
	{ "T_Once_Revealing", tes3.enchantmentType.castOnce, { tes3.effect.T_mysticism_DetInvisibility }, tes3.effectRange.self, 0, 10, 40, 80, nil },
	{ "T_Once_GramaryeMirror", tes3.enchantmentType.castOnce, { tes3.effect.T_mysticism_ReflectDmg }, tes3.effectRange.self, 0, 30, 20, 20, { tes3.effect.reflect }, tes3.effectRange.self, 0, 30, 20, 20 },
	{ "T_Once_DeificChrisom", tes3.enchantmentType.castOnce, { tes3.effect.T_mysticism_ReflectDmg }, tes3.effectRange.self, 0, 60, 10, 30, { tes3.effect.spellAbsorption }, tes3.effectRange.self, 0, 60, 10, 30, { tes3.effect.sanctuary }, tes3.effectRange.self, 0, 60, 10, 30 },
	{ "T_Once_Dashing", tes3.enchantmentType.castOnce, { tes3.effect.T_mysticism_Blink }, tes3.effectRange.self, 0, 0, 40, 40 },
	{ "T_Once_AssassinRush", tes3.enchantmentType.castOnce, { tes3.effect.T_mysticism_Blink }, tes3.effectRange.self, 0, 0, 30, 30, { tes3.effect.fortifyAttack }, tes3.effectRange.self, 0, 60, 10, 20, { tes3.effect.fortifySkill, nil, tes3.skill.shortBlade }, tes3.effectRange.self, 0, 60, 10, 20 },
	{ "T_Once_QorwynnMending", tes3.enchantmentType.castOnce, { tes3.effect.T_restoration_ArmorResartus }, tes3.effectRange.self, 0, 0, 30, 30, { tes3.effect.T_restoration_WeaponResartus }, tes3.effectRange.self, 0, 0, 30, 30 },
	{ "T_Once_MoathAuthority", tes3.enchantmentType.castOnce, { tes3.effect.boundBoots }, tes3.effectRange.self, 0, 90, 1, 1, { tes3.effect.T_bound_Greaves }, tes3.effectRange.self, 0, 90, 1, 1, { tes3.effect.boundGloves }, tes3.effectRange.self, 0, 90, 1, 1, { tes3.effect.T_bound_Greatsword }, tes3.effectRange.self, 0, 90, 1, 1 },
	{ "T_Once_AllSeeing", tes3.enchantmentType.castOnce, { tes3.effect.detectAnimal }, tes3.effectRange.self, 0, 300, 200, 200, { tes3.effect.T_mysticism_DetHuman }, tes3.effectRange.self, 0, 300, 200, 200, { tes3.effect.T_mysticism_DetEnemy }, tes3.effectRange.self, 0, 300, 200, 200,
						{ tes3.effect.T_mysticism_DetInvisibility }, tes3.effectRange.self, 0, 300, 200, 200, { tes3.effect.detectEnchantment }, tes3.effectRange.self, 0, 300, 200, 200, { tes3.effect.detectKey }, tes3.effectRange.self, 0, 300, 200, 200 },
	{ "T_Once_Firmament", tes3.enchantmentType.castOnce, { tes3.effect.fortifyAttack }, tes3.effectRange.self, 0, 120, 40, 40, { tes3.effect.T_restoration_FortifyCasting }, tes3.effectRange.self, 0, 120, 40, 40, { tes3.effect.fortifySkill, nil, tes3.skill.sneak }, tes3.effectRange.self, 0, 120, 40, 40 },
	{ "T_Once_BoethiahService", tes3.enchantmentType.castOnce, { tes3.effect.summonHunger }, tes3.effectRange.self, 0, 120, 1, 1, { tes3.effect.T_summon_Devourer }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_FourArmsGoingUp", tes3.enchantmentType.castOnce, { tes3.effect.summonScamp }, tes3.effectRange.self, 0, 120, 1, 1, { tes3.effect.summonDremora }, tes3.effectRange.self, 0, 120, 1, 1, { tes3.effect.T_summon_Morphoid }, tes3.effectRange.self, 0, 120, 1, 1, { tes3.effect.T_summon_Herne }, tes3.effectRange.self, 0, 120, 1, 1 },
	{ "T_Once_Anticipations", tes3.enchantmentType.castOnce, { tes3.effect.summonWingedTwilight }, tes3.effectRange.self, 0, 60, 1, 1, { tes3.effect.T_summon_SpiderDaedra }, tes3.effectRange.self, 0, 60, 1, 1, { tes3.effect.summonHunger }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Once_FourCorners", tes3.enchantmentType.castOnce, { tes3.effect.summonGoldenSaint }, tes3.effectRange.self, 0, 60, 1, 1, { tes3.effect.summonDremora }, tes3.effectRange.self, 0, 60, 1, 1, { tes3.effect.T_summon_Ogrim }, tes3.effectRange.self, 0, 60, 1, 1, { tes3.effect.summonDaedroth }, tes3.effectRange.self, 0, 60, 1, 1 },

	{ "T_Const_Ring_Namira", tes3.enchantmentType.constant, { tes3.effect.T_mysticism_ReflectDmg }, tes3.effectRange.self, 0, 1, 30, 30, { tes3.effect.reflect }, tes3.effectRange.self, 0, 1, 30, 30 },
	{ "T_Const_FindersCharm", tes3.enchantmentType.constant, { tes3.effect.T_mysticism_Insight }, tes3.effectRange.self, 0, 1, 10, 10, { tes3.effect.detectEnchantment }, tes3.effectRange.self, 0, 1, 120, 120, { tes3.effect.detectKey }, tes3.effectRange.self, 0, 1, 120, 120 },
	{ "T_Const_Robe_Reprisal", tes3.enchantmentType.constant, { tes3.effect.frostShield }, tes3.effectRange.self, 0, 1, 50, 50, { tes3.effect.T_mysticism_ReflectDmg }, tes3.effectRange.self, 0, 1, 10, 10 },
	{ "T_Const_Onimaru_en", tes3.enchantmentType.constant, { tes3.effect.fortifyAttack }, tes3.effectRange.self, 0, 1, 10, 10, { tes3.effect.resistMagicka }, tes3.effectRange.self, 0, 1, 20, 20, { tes3.effect.resistNormalWeapons }, tes3.effectRange.self, 0, 1, 20, 20, { tes3.effect.T_mysticism_ReflectDmg }, tes3.effectRange.self, 0, 1, 20, 20, { tes3.effect.summonDremora }, tes3.effectRange.self, 0, 1, 1, 1 },
	{ "T_Const_NadiaInsight", tes3.enchantmentType.constant, { tes3.effect.T_mysticism_Insight }, tes3.effectRange.self, 0, 1, 30, 30 },
	{ "T_Use_GuardianRIng", tes3.enchantmentType.onUse, { tes3.effect.boundBoots }, tes3.effectRange.self, 0, 60, 1, 1, { tes3.effect.T_bound_Greaves }, tes3.effectRange.self, 0, 60, 1, 1, { tes3.effect.boundCuirass }, tes3.effectRange.self, 0, 60, 1, 1, { tes3.effect.T_bound_Pauldrons }, tes3.effectRange.self, 0, 60, 1, 1,
							{ tes3.effect.boundGloves }, tes3.effectRange.self, 0, 60, 1, 1, { tes3.effect.boundHelm }, tes3.effectRange.self, 0, 60, 1, 1, },
	{ "T_Use_WabbajackUni", tes3.enchantmentType.onUse, { tes3.effect.T_alteration_Wabbajack }, tes3.effectRange.target, 0, 1, 1, 1 },
	{ "T_Use_SkullOfCorruption", tes3.enchantmentType.onUse, { tes3.effect.T_conjuration_Corruption }, tes3.effectRange.target, 0, 0, 1, 1 },	-- Why oh why is this ID not Uni?
	{ "T_Use_SummonGuardian60", tes3.enchantmentType.castOnce, { tes3.effect.T_summon_Guardian }, tes3.effectRange.self, 0, 60, 1, 1 },
	{ "T_Const_VelothsPauld_R", tes3.enchantmentType.constant, { tes3.effect.T_mysticism_ReflectDmg }, tes3.effectRange.self, 0, 1, 30, 30 },
	{ "T_Strike_StaffVeloth", tes3.enchantmentType.onUse, { tes3.effect.T_destruction_GazeOfVeloth }, tes3.effectRange.target, 0, 1, 1, 1 },
	{ "T_Const_Spell_Bifurcation", tes3.enchantmentType.constant, { tes3.effect.T_restoration_FortifyCasting }, tes3.effectRange.self, 0, 1, 20, 20 },
}

-- ingredient id, 1st effect id, 1st effect attribute id, 1st effect skill id, 2nd effect id, ...
local td_ingredients = {
	{ "T_IngFlor_PBloomBulb_01", tes3.effect.poison, -1, -1,
								 tes3.effect.T_mysticism_ReflectDmg, -1, -1,
								 tes3.effect.damageFatigue, -1, -1,
								 tes3.effect.light, -1, -1 },
	{ "T_IngCrea_Eyestar_01", tes3.effect.nightEye, -1, -1,
							  tes3.effect.T_mysticism_Insight, -1, -1,
							  tes3.effect.weaknesstoMagicka, -1, -1,
							  tes3.effect.waterBreathing, -1, -1 },
	{ "T_IngCrea_EyestarDae_01", tes3.effect.nightEye, -1, -1,
								 tes3.effect.T_mysticism_Insight, -1, -1,
								 tes3.effect.weaknesstoMagicka, -1, -1,
								 tes3.effect.waterBreathing, -1, -1 },
	{ "T_IngCrea_BeetleShell_01", tes3.effect.fortifyAttribute, tes3.attribute.endurance, 0,
								  tes3.effect.T_mysticism_Insight, -1, -1 },
	{ "T_IngCrea_BeetleShell_04", tes3.effect.fortifyAttribute, tes3.attribute.endurance, 0,
								  tes3.effect.T_mysticism_ReflectDmg, -1, -1 },
	{ "T_IngMine_PearlBlue_01", tes3.effect.damageAttribute, tes3.attribute.intelligence, 0,
								tes3.effect.restoreMagicka, -1, -1,
								tes3.effect.T_mysticism_Insight, -1, -1,
								tes3.effect.fortifyMaximumMagicka, -1, -1 },
	{ "T_IngMine_PearlBlueDae_01", tes3.effect.damageAttribute, tes3.attribute.intelligence, 0,
								   tes3.effect.restoreMagicka, -1, -1,
								   tes3.effect.T_mysticism_Insight, -1, -1,
								   tes3.effect.fortifyMaximumMagicka, -1, -1 },
	{ "T_IngMine_PearlKardesh_01", tes3.effect.silence, -1, -1,
								   tes3.effect.waterBreathing, -1, -1,
								   tes3.effect.damageAttribute, tes3.attribute.luck, 0,
								   tes3.effect.T_restoration_FortifyCasting, -1, -1 },
	{ "T_IngMine_DiamondRed_01", tes3.effect.drainAttribute, tes3.attribute.endurance, 0,
								 tes3.effect.invisibility, -1, -1,
								 tes3.effect.T_mysticism_ReflectDmg, -1, -1,
								 tes3.effect.resistFire, -1, -1 },
	{ "T_IngCrea_PrismaticDust_01", tes3.effect.light, -1, -1,	-- Change to Prismatic Light once MWSE has been fixed as needed
									tes3.effect.T_alteration_RadShield, -1, -1,
									tes3.effect.blind, -1, -1,
									tes3.effect.restoreMagicka, -1, -1 },
	{ "T_IngCrea_MothWingMw_02", tes3.effect.resistFire, -1, -1,
								 tes3.effect.drainAttribute, tes3.attribute.speed, 0,
								 tes3.effect.resistMagicka, -1, -1,
								 tes3.effect.T_mysticism_Insight, -1, -1 },
	{ "T_IngMine_Amethyst_01", tes3.effect.T_mysticism_DetInvisibility, -1, -1,
							   tes3.effect.drainFatigue, -1, -1,
							   tes3.effect.CureCommonDisease, -1, -1,
							   tes3.effect.restoreAttribute, tes3.attribute.willpower, 0 },
	{ "T_IngMine_AmethystDae_01", tes3.effect.T_mysticism_DetInvisibility, -1, -1,
								  tes3.effect.drainFatigue, -1, -1,
								  tes3.effect.CureCommonDisease, -1, -1,
								  tes3.effect.restoreAttribute, tes3.attribute.willpower, 0 },
	{ "T_IngFood_TGuarHide", tes3.effect.drainMagicka, -1, -1,
							 tes3.effect.fortifyAttribute, tes3.attribute.strength, 0,
							 tes3.effect.restoreAttribute, tes3.attribute.speed, 0,
							 tes3.effect.T_mysticism_DetInvisibility, -1, -1 },
	{ "T_IngCrea_ThresherClaw_01", tes3.effect.fortifyAttribute, tes3.attribute.strength, 0,
								   tes3.effect.resistFire, -1, -1,
								   tes3.effect.weaknesstoFrost, -1, -1,
								   tes3.effect.T_mysticism_DetEnemy, -1, -1 },
	{ "T_IngFlor_TempleDome_01", tes3.effect.blind, -1, -1,
								 tes3.effect.burden, -1, -1,
								 tes3.effect.T_mysticism_DetInvisibility, -1, -1,
								 tes3.effect.shield, -1, -1 },
	{ "T_IngCrea_ArmunHide_01", tes3.effect.resistNormalWeapons, -1, -1,
								tes3.effect.T_mysticism_DetHuman, -1, -1,
								tes3.effect.resistFire, -1, -1,
								tes3.effect.weaknesstoFrost, -1, -1 },
	{ "T_IngCrea_RakiTeeth_01", tes3.effect.drainHealth, -1, -1,
								tes3.effect.weaknesstoShock, -1, -1,
								tes3.effect.T_mysticism_DetHuman, -1, -1,
								tes3.effect.jump, -1, -1 },
	{ "T_IngCrea_Dragonscales_01", tes3.effect.damageHealth, -1, -1,
								   tes3.effect.T_mysticism_DetEnemy, -1, -1,
								   tes3.effect.fireShield, -1, -1,
								   tes3.effect.silence, -1, -1 },
	{ "T_IngCrea_DridreaSilk_01", tes3.effect.burden, -1, -1,
								  tes3.effect.nightEye, -1, -1,
								  tes3.effect.T_mysticism_DetEnemy, -1, -1,
								  tes3.effect.damageAttribute, tes3.attribute.endurance, 0 },
	{ "T_IngCrea_MothWingCyr_02", tes3.effect.drainAttribute, tes3.attribute.willpower, 0,
								  tes3.effect.T_mysticism_DetHuman, -1, -1,
								  tes3.effect.fortifyMagicka, -1, -1,
								  tes3.effect.resistMagicka, -1, -1 },
	{ "T_IngCrea_MothWingSky_03", tes3.effect.fortifyAttribute, tes3.attribute.agility, 0,
								 tes3.effect.drainAttribute, tes3.attribute.strength, 0,
								 tes3.effect.T_mysticism_Blink, -1, -1 },
	{ "T_IngFood_MeatDolphin_01", tes3.effect.jump, -1, -1,
								  tes3.effect.swiftSwim, -1, -1,
								  tes3.effect.sanctuary, -1, -1,
								  tes3.effect.T_mysticism_DetInvisibility, -1, -1 },
	{ "T_IngFlor_Indulcet_01", tes3.effect.fortifyAttribute, tes3.attribute.personality, -1,
							   tes3.effect.T_mysticism_DetInvisibility, -1, -1,
							   tes3.effect.sanctuary, -1, -1,
							   tes3.effect.damageAttribute, tes3.attribute.agility, 0 },
	{ "T_IngFlor_FlaxFlower_01", tes3.effect.fortifyFatigue, -1, -1,
								 tes3.effect.T_mysticism_DetInvisibility, -1, -1,
								 tes3.effect.weaknesstoFire, -1, -1,
								 tes3.effect.frostShield, -1, -1 },
	{ "T_IngFlor_FlaxFlower_02", tes3.effect.fortifyFatigue, -1, -1,
								 tes3.effect.T_mysticism_DetEnemy, -1, -1,
								 tes3.effect.weaknesstoFire, -1, -1,
								 tes3.effect.fireShield, -1, -1 },
	{ "T_IngFlor_FlaxFlower_03", tes3.effect.fortifyFatigue, -1, -1,
								 tes3.effect.T_mysticism_DetHuman, -1, -1,
								 tes3.effect.weaknesstoFire, -1, -1,
								 tes3.effect.dispel, -1, -1 },
	{ "T_IngFlor_ArrowrootFlower_01", tes3.effect.restoreAttribute, tes3.attribute.agility, 0,
									  tes3.effect.damageAttribute, tes3.attribute.luck, 0,
								 	  tes3.effect.T_mysticism_DetEnemy, -1, -1,
								 	  tes3.effect.nightEye, -1, -1 },
	{ "T_IngFlor_Spiddal_01", tes3.effect.damageHealth, -1, -1,
							  tes3.effect.damageMagicka, -1, -1,
							  tes3.effect.fireDamage, -1, -1,
							  tes3.effect.T_mysticism_DetEnemy, -1, -1 },
	{ "T_IngFlor_Peony_01", tes3.effect.restoreAttribute, tes3.attribute.strength, -1,
							tes3.effect.damageHealth, -1, -1,
							tes3.effect.damageAttribute, tes3.attribute.speed, -1,
							tes3.effect.T_mysticism_DetHuman, -1, -1 },
	{ "T_IngSpice_Curcuma_01", tes3.effect.T_mysticism_ReflectDmg, -1, -1,
							   tes3.effect.weaknesstoFire, -1, -1,
							   tes3.effect.damageAttribute, tes3.attribute.strength, -1,
							   tes3.effect.resistParalysis, -1, -1 },
	{ "T_IngCrea_CetaceanMelon", tes3.effect.detectAnimal, -1, -1,
							   	 tes3.effect.sound, -1, -1,
							   	 tes3.effect.damageAttribute, tes3.attribute.personality, -1,
							   	 tes3.effect.T_mysticism_ReflectDmg, -1, -1 },
	{ "T_IngFlor_Siyat_01", tes3.effect.T_mysticism_Insight, -1, -1,
							tes3.effect.resistParalysis, -1, -1,
							tes3.effect.damageMagicka, -1, -1,
							tes3.effect.dispel, -1, -1 },
	{ "T_IngCrea_HagravenFeathers_01", tes3.effect.damageMagicka, -1, -1,
									   tes3.effect.fortifyAttack, -1, -1,
									   tes3.effect.weaknesstoShock, -1, -1,
									   tes3.effect.T_restoration_FortifyCasting, -1, -1 },
	{ "T_IngSpice_Cinnamon_01", tes3.effect.fireDamage, -1, -1,
								tes3.effect.T_restoration_FortifyCasting, -1, -1,
								tes3.effect.damageFatigue, -1, -1 },
	{ "T_IngMine_Spellstone_01", tes3.effect.T_restoration_FortifyCasting, -1, -1,
								 tes3.effect.spellAbsorption, -1, -1,
								 tes3.effect.restoreMagicka, -1, -1,
								 tes3.effect.telekinesis, -1, -1 },
	{ "T_IngSpice_Pepper_01", tes3.effect.drainAttribute, tes3.attribute.personality, -1,
							  tes3.effect.resistMagicka, -1, -1,
							  tes3.effect.fireDamage, -1, -1,
							  tes3.effect.T_mysticism_Insight, -1, -1 },
	{ "T_IngFlor_MonksTons_01", tes3.effect.T_mysticism_Insight, -1, -1,
								tes3.effect.blind, -1, -1,
								tes3.effect.fortifyAttribute, tes3.attribute.willpower, 0,
								tes3.effect.drainAttribute, tes3.attribute.personality, 0 },
	--{ "T_IngMine_Agate_01", tes3.effect.reflect, -1, -1,
	--						  tes3.effect.levitate, -1, -1,
	--						  tes3.effect.T_illusion_PrismaticLight, -1, -1,
	--						  tes3.effect.silence, -1, -1 },
}

-- item id, item name, 1st effect id, 1st duration, 1st magnitude, ...
local td_potions = {
	{ "T_Com_Potion_ReflectDamage_B", common.i18n("magic.itemPotionReflectDamageB"), tes3.effect.T_mysticism_ReflectDmg, 8, 5 },
	{ "T_Com_Potion_ReflectDamage_C", common.i18n("magic.itemPotionReflectDamageC"), tes3.effect.T_mysticism_ReflectDmg, 15, 8  },
	{ "T_Com_Potion_ReflectDamage_S", common.i18n("magic.itemPotionReflectDamageS"), tes3.effect.T_mysticism_ReflectDmg, 30, 10 },
	{ "T_Com_Potion_ReflectDamage_Q", common.i18n("magic.itemPotionReflectDamageQ"), tes3.effect.T_mysticism_ReflectDmg, 45, 15 },
	{ "T_Com_Potion_ReflectDamage_E", common.i18n("magic.itemPotionReflectDamageE"), tes3.effect.T_mysticism_ReflectDmg, 60, 20 },
	{ "T_Com_Potion_Insight_B", common.i18n("magic.itemPotionInsightB"), tes3.effect.T_mysticism_Insight, 8, 5 },
	{ "T_Com_Potion_Insight_C", common.i18n("magic.itemPotionInsightC"), tes3.effect.T_mysticism_Insight, 15, 8  },
	{ "T_Com_Potion_Insight_S", common.i18n("magic.itemPotionInsightS"), tes3.effect.T_mysticism_Insight, 30, 10 },
	{ "T_Com_Potion_Insight_Q", common.i18n("magic.itemPotionInsightQ"), tes3.effect.T_mysticism_Insight, 45, 15 },
	{ "T_Com_Potion_Insight_E", common.i18n("magic.itemPotionInsightE"), tes3.effect.T_mysticism_Insight, 60, 20 },
	{ "T_Com_Potion_Detect_Humanoid_S", common.i18n("magic.itemPotionDetectHumanoid"), tes3.effect.T_mysticism_DetHuman, 15, 10 },
	{ "T_Com_Potion_Detect_Enemy_S", common.i18n("magic.itemPotionDetectEnemy"), tes3.effect.T_mysticism_DetEnemy, 15, 10 },
	{ "T_Com_Potion_Detect_Invisib_S", common.i18n("magic.itemPotionDetectInvisibility"), tes3.effect.T_mysticism_DetInvisibility, 15, 10 },
	{ "T_Com_Potion_Eyes", nil, tes3.effect.detectAnimal, 60, 50, tes3.effect.T_mysticism_DetHuman, 60, 50, tes3.effect.detectEnchantment, 60, 50, tes3.effect.detectKey, 60, 50, tes3.effect.nightEye, 60, 50 },
	{ "T_Com_Potion_FortifyCasting_B", nil, tes3.effect.T_restoration_FortifyCasting, 8, 5 },
	{ "T_Com_Potion_FortifyCasting_C", nil, tes3.effect.T_restoration_FortifyCasting, 15, 8 },
	{ "T_Com_Potion_FortifyCasting_S", nil, tes3.effect.T_restoration_FortifyCasting, 30, 10 },
	{ "T_Com_Potion_FortifyCasting_Q", nil, tes3.effect.T_restoration_FortifyCasting, 45, 15 },
	{ "T_Com_Potion_FortifyCasting_E", nil, tes3.effect.T_restoration_FortifyCasting, 60, 20 },
}

-- item id, item name, value
local td_enchanted_items = {
	{ "T_EnSc_Com_SummonDremoraArcher", common.i18n("magic.itemScSummonDremoraArcher"), 295 },
	{ "T_EnSc_Com_SummonDremoraCaster", common.i18n("magic.itemScSummonDremoraCaster"), 314 },
	{ "T_EnSc_Nor_KynesIntervention", common.i18n("magic.itemScKynesIntervention"), nil }
}

-- race name, female, distraction voice files, distraction end voice lines
local distractedVoiceLines = {
	{ "Argonian", false, { "vo\\a\\m\\Idl_AM001.mp3", "vo\\a\\m\\Hlo_AM056.mp3" }, { "vo\\a\\m\\Idl_AM008.mp3" } },
	{ "Argonian", true, { "vo\\a\\f\\Idl_AF007.mp3", "vo\\a\\f\\Idl_AF004.mp3" }, { "vo\\a\\f\\Idl_AF002.mp3" } },
	{ "Breton", false, { }, { } },
	{ "Breton", true, { "vo\\b\\f\\Idl_BF001.mp3", "vo\\b\\f\\Idl_BF005.mp3" }, { "vo\\b\\f\\Idl_BF003.mp3" } },
	{ "Dark Elf", false, { "vo\\d\\m\\Idl_DM006.mp3", "vo\\d\\m\\Idl_DM007.mp3" }, { "vo\\d\\m\\Idl_DM008.mp3" } },
	{ "Dark Elf", true, { "vo\\d\\f\\Idl_DF006.mp3" }, { "vo\\d\\f\\Idl_DF003.mp3" } },
	{ "High Elf", false, { "vo\\h\\m\\Hlo_HM056.mp3" }, { "vo\\i\\m\\Idl_HF007.mp3" } },
	{ "High Elf", true, { "vo\\h\\f\\Hlo_HF056.mp3" }, { "vo\\i\\f\\Idl_HF007.mp3" } },
	{ "Imperial", false, { "vo\\i\\m\\Idl_IM008.mp3", "vo\\i\\m\\Idl_IM003.mp3" }, { "vo\\i\\m\\Idl_IM005.mp3" } },
	{ "Imperial", true, { "vo\\i\\f\\Idl_IF001.mp3" }, { "vo\\i\\f\\Idl_IF009.mp3" } },
	{ "Khajiit", false, { "vo\\k\\m\\Idl_KM005.mp3", "vo\\k\\m\\Idl_KM006.mp3", "vo\\k\\m\\Idl_KM007.mp3" }, { "vo\\k\\m\\Idl_KM002.mp3", "vo\\k\\m\\Idl_KM003.mp3" } },	-- The main reason for using race names instead of IDs is to make the Khajiit easier, but that should change when/if certain forms get their own voicelines
	{ "Khajiit", true, { "vo\\k\\f\\Idl_KF005.mp3", "vo\\k\\f\\Idl_KF006.mp3", "vo\\k\\f\\Idl_KF007.mp3" }, { "vo\\k\\f\\Idl_KF002.mp3", "vo\\k\\f\\Idl_KF003.mp3" } },
	{ "Nord", false, { "vo\\n\\m\\Idl_NM001.mp3" }, { "vo\\n\\m\\Idl_NM009.mp3" } },
	{ "Nord", true, { "vo\\n\\f\\Idl_NF002.mp3", "vo\\n\\f\\Idl_NF004.mp3" }, { "vo\\n\\f\\Idl_NM008.mp3" } },
	{ "Orc", false, { "vo\\o\\m\\Idl_OM001.mp3", "vo\\o\\m\\Idl_OM002.mp3" }, { "vo\\o\\m\\Idl_OM004.mp3", "vo\\o\\m\\Idl_OM009.mp3" } },
	{ "Orc", true, { "vo\\o\\f\\Idl_OF009.mp3" }, { } },
	{ "Redguard", false, { }, { } },
	{ "Redguard", true, { "vo\\r\\f\\Idl_RF002.mp3", "vo\\r\\f\\Idl_RF008.mp3" }, { "vo\\r\\f\\Idl_RF003.mp3", "vo\\r\\f\\Idl_RF007.mp3" } },
	{ "Wood Elf", false, { "vo\\w\\m\\Idl_WM009.mp3" }, { "vo\\w\\m\\Idl_WM006.mp3", "vo\\w\\m\\Idl_WM007.mp3" } },
	{ "Wood Elf", true, { "vo\\w\\f\\Idl_WF006.mp3", "vo\\w\\f\\Idl_WF009.mp3" }, { "vo\\w\\f\\Idl_WF003.mp3", "vo\\w\\f\\Idl_WF007.mp3" } },
}

local prismaticReferences = {}

local distractedReferences = {}	-- Should probably decide on a consistent naming scheme for tables

local invisibleReferences = {}

-- race id, skeleton base body part id, skeleton "clothing" body part id
local raceSkeletonBodyParts = {
	{ "Argonian", "T_B_GazeVeloth_SkeletonArg_01", "T_C_GazeVeloth_SkeletonArg_01" },	-- Use the other Argonian skeletons too depending on the hair mesh of the target?
	{ "Breton", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },
	{ "Dark Elf", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },
	{ "High Elf", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },
	{ "Imperial", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },
	{ "Khajiit", "T_B_GazeVeloth_SkeletonKha_01", "T_C_GazeVeloth_SkeletonKha_01" },
	{ "Nord", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },
	{ "Orc", "T_B_GazeVeloth_SkeletonOrc_01", "T_C_GazeVeloth_SkeletonOrc_01" },
	{ "Redguard", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },
	{ "Wood Elf", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },
	{ "T_Cnq_ChimeriQuey", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },
	{ "T_Cnq_Keptu", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },
	{ "T_Els_Cathay", "T_B_GazeVeloth_SkeletonKha_02", "T_C_GazeVeloth_SkeletonKha_02" },
	{ "T_Els_Cathay-raht", "T_B_GazeVeloth_SkeletonKha_01", "T_C_GazeVeloth_SkeletonKha_01" },
	{ "T_Els_Dagi-raht", "T_B_GazeVeloth_SkeletonKha_01", "T_C_GazeVeloth_SkeletonKha_01" },
	{ "T_Els_Ohmes", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },
	{ "T_Els_Ohmes-raht", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },
	{ "T_Els_Suthay", "T_B_GazeVeloth_SkeletonKha_02", "T_C_GazeVeloth_SkeletonKha_02" },
	{ "T_Hr_Riverfolk", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },
	{ "T_Mw_Malahk_Orc", "T_B_GazeVeloth_SkeletonOrc_01", "T_C_GazeVeloth_SkeletonOrc_01" },
	{ "T_Pya_SeaElf", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },
	{ "T_Sky_Hill_Giant", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },		-- Giants should eventually get their own skeleton mesh though
	{ "T_Sky_Reachman", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },
	{ "T_Yne_Ynesai", "T_B_GazeVeloth_Skeleton_01", "T_C_GazeVeloth_Skeleton_01" },		-- Imga, and Tsaesci skeletons will take more effort
}

local wabbajackCreatures = { 
	"T_Mw_UNI_GrahlWabbajack",	-- This version of the Grahl does not have fireregenScript attached to it; I saw a crash occur while it was being executed, but I am not sure why.
	"scamp",
	"T_Glb_Cre_LandDreu_01",
	"T_Glb_Cre_TrollCave_03",
	"mudcrab",
	"T_Ham_Fau_Goat_01",
	"Rat",
	"golden saint"
}

-- actor id
local gazeOfVelothImmuneActors = {
	"vivec_god",
	"almalexia",
	"Almalexia_warrior",
	"divayth fyr",
	"wulf",
	"Sky_qRe_KWMG6_Azra"
}

---@param table table
function this.replaceSpells(table)
	for _,v in pairs(table) do
		local overridden_spell = tes3.getObject(v[1])
		if overridden_spell then
			overridden_spell.castType = v[2]
			if v[3] then overridden_spell.name = v[3] end
			if v[4] then overridden_spell.magickaCost = v[4] end
			for i = 1, 8, 1 do
				if not v[5 + (i - 1) * 6] then
					break	-- This condition exists so that the tables don't have to have dozens of fields if they have less than 8 effects
				end

				local effect = overridden_spell.effects[i]
				effect.id = v[5 + (i - 1) * 6][1]
				effect.attribute = v[5 + (i - 1) * 6][2]
				effect.skill = v[5 + (i - 1) * 6][3]
				effect.rangeType = v[6 + (i - 1) * 6]
				effect.radius = v[7 + (i - 1) * 6]
				effect.duration = v[8 + (i - 1) * 6]
				effect.min = v[9 + (i - 1) * 6]
				effect.max = v[10 + (i - 1) * 6]
			end
		end
	end
end

---@param table table
function this.replaceEnchantments(table)
	for _,v in pairs(table) do
		local overridden_enchantment = tes3.getObject(v[1])
		---@cast overridden_enchantment tes3enchantment
		if overridden_enchantment then
			overridden_enchantment.castType = v[2]
			for i = 1, 8, 1 do
				if not v[3 + (i - 1) * 6] then
					for j = i, 8, 1 do
						local effect = overridden_enchantment.effects[i]
						effect.id = -1
						effect.attribute = -1
						effect.skill = -1
					end

					break
				end

				local effect = overridden_enchantment.effects[i]
				effect.id = v[3 + (i - 1) * 6][1]
				effect.attribute = v[3 + (i - 1) * 6][2]
				effect.skill = v[3 + (i - 1) * 6][3]
				effect.rangeType = v[4 + (i - 1) * 6]
				effect.radius = v[5 + (i - 1) * 6]
				effect.duration = v[6 + (i - 1) * 6]
				effect.min = v[7 + (i - 1) * 6]
				effect.max = v[8 + (i - 1) * 6]
			end
		end
	end
end

---@param table table
function this.replaceIngredientEffects(table)
	for _,v in pairs(table) do
		local ingredient = tes3.getObject(v[1])
		if ingredient then
			for i = 1, 4, 1 do
				if not v[2 + (i - 1) * 3] then
					break
				end

				ingredient.effects[i] = v[2 + (i - 1) * 3]
				ingredient.effectAttributeIds[i] = v[3 + (i - 1) * 3]
				ingredient.effectSkillIds[i] = v[4 + (i - 1) * 3]
			end
		end
	end
end

---@param table table
function this.replacePotions(table)
	for _,v in pairs(table) do
		local potion = tes3.getObject(v[1])
		if potion then
			if v[2] then potion.name = v[2] end
			for i = 1, 8, 1 do
				local effect = potion.effects[i]
				if v[3 + (i - 1) * 3] then
					effect.id = v[3 + (i - 1) * 3]
					effect.duration = v[4 + (i - 1) * 3]
					effect.min = v[5 + (i - 1) * 3]
					effect.max = v[5 + (i - 1) * 3]
				else
					effect.id = -1
					effect.duration = -1
					effect.min = -1
					effect.max = -1
				end
			end
		end
	end
end

---@param table table
function this.editItems(table)
	for _,v in pairs(table) do
		local overridden_item = tes3.getObject(v[1])
		if overridden_item then
			if v[2] then overridden_item.name = v[2] end
			if v[3] then overridden_item.value = v[3] end
		end
	end
end

---@param actor tes3mobileNPC
---@param table table< table< string, tes3.spellType, string|nil, number, tes3.effect, tes3.effectRange, number, number, number, number > >
---@return table< table< string, tes3.effect > >
local function checkActorSpells(actor, table)
	local customSpells = { }
	local customSpellIndex = 1
	for _,v in pairs(table) do
		if actor.object.spells:contains(v[1]) and actor.magicka.current > v[4] then
			customSpells[customSpellIndex] = { v[1], v[5] }
			customSpellIndex = customSpellIndex + 1
		end
	end

	return customSpells
end

---@param session tes3combatSession
---@param spells table< table< string, tes3.effect > >
local function equipActorSpell(session, spells)
	for _,v in pairs(spells) do
		if #session.mobile:getActiveMagicEffects({ effect = v[2] }) == 0 then
			session.selectedAction = 6
			local spell = tes3.getObject(v[1])
			session.selectedSpell = spell
			session.mobile:equipMagic({ source = spell })
			return
		end
	end
end

---@param e determinedActionEventData
function this.useCustomSpell(e)
	local customSpells
	--if (e.session.selectedAction > 3 and e.session.selectedAction < 7) or e.session.selectedAction == 8 then	-- These conditions require that the actor is already casting a spell, which can't happen if they are unable to cast a non-MWSE spell
		if config.summoningSpells then
			customSpells = checkActorSpells(e.session.mobile, td_summon_spells)
	
			if customSpells then
				equipActorSpell(e.session, customSpells)
			end
		end

		--[[
		if not customSpells and config.boundSpells then
			customSpells = checkActorSpells(e.session.mobile, td_bound_spells)
	
			if customSpells then
				equipActorSpell(e.session, customSpells)
			end
		end
		]]
	--end
end

function this.prismaticLightTick()
	for ref in pairs(prismaticReferences) do
		---@cast ref tes3reference
		local lightNode = ref:getAttachedDynamicLight()
		lightNode.light.diffuse = common.hsvToRGB(ref.data.tamrielData.prismaticLightHue, .3, 1)

		ref.data.tamrielData.prismaticLightHue = ref.data.tamrielData.prismaticLightHue + 1
		if ref.data.tamrielData.prismaticLightHue > 359 then ref.data.tamrielData.prismaticLightHue = 0 end
	end
end

---@param e referenceActivatedEventData
function this.onPrismaticLightReferenceActivated(e)
	if e.reference.mobile then
		local prismaticLightEffects = e.reference.mobile:getActiveMagicEffects({ effect = tes3.effect.T_illusion_PrismaticLight })

		if #prismaticLightEffects > 0 then	-- Just replace this with a check for prismaticLightHue?
			prismaticReferences[e.reference] = true
		end
	end
end

---@param e referenceActivatedEventData
function this.onPrismaticLightReferenceDeactivated(e)
	prismaticReferences[e.reference] = nil
end

---@param e magicEffectRemovedEventData
function this.prismaticLightRemovedEffect(e)
	if e.effect.id == tes3.effect.T_illusion_PrismaticLight then
		local target = e.effectInstance.target
		prismaticReferences[target] = nil

		local lightNode = target:getOrCreateAttachedDynamicLight()

		if lightNode.light.name == "prismaticLightAttachment" then	-- If this is not true, then some other MWSE addon has replaced the light and it should not be touched
			local prismaticLightEffects = e.mobile:getActiveMagicEffects({ effect = tes3.effect.T_illusion_PrismaticLight })

			if #prismaticLightEffects > 1 then	-- 1 is checked rather than 0 because the (final) effect being removed will still be counted here
				local totalMagnitude = 0
				
				for _,v in pairs(prismaticLightEffects) do
					totalMagnitude = totalMagnitude + v.effectInstance.effectiveMagnitude
				end

				totalMagnitude = totalMagnitude - e.effectInstance.effectiveMagnitude	-- The radius is rounded to the nearest whole number, so doing these calculations ensures that it will be correct afterwards

				lightNode.light:setRadius(totalMagnitude * 22.1)
			else
				target.data.tamrielData.prismaticLightHue = nil
				target:deleteDynamicLightAttachment(true)
			end
		end
	end
end

---@param e tes3magicEffectTickEventData
local function prismaticLightEffect(e)
	if (not e:trigger()) then
		return
	end
	
	local target = e.effectInstance.target
	prismaticReferences[target] = true

	local lightNode = target:getOrCreateAttachedDynamicLight()

	if lightNode.light.name == "prismaticLightAttachment" then
		local prismaticLightEffects = target.mobile:getActiveMagicEffects({ effect = tes3.effect.T_illusion_PrismaticLight })
		local totalMagnitude = 0
				
		for _,v in pairs(prismaticLightEffects) do
			totalMagnitude = totalMagnitude + v.effectInstance.effectiveMagnitude
		end

		lightNode.light:setRadius(totalMagnitude * 22.1)
	else
		lightNode.light.name = "prismaticLightAttachment"
		target.data.tamrielData = target.data.tamrielData or {}
		target.data.tamrielData.prismaticLightHue = 60
		lightNode.light.diffuse = common.hsvToRGB(target.data.tamrielData.prismaticLightHue, .3, 1)
		lightNode.light:setRadius(e.effectInstance.effectiveMagnitude * 22.1)
		lightNode.light.translation = lightNode.light.translation + tes3vector3.new(0, 0, 0.5 * tes3.mobilePlayer.height)
	end
end

---@param e uiPreEventEventData
local function fortifyCastingMultiFillbar(e)
	local multiMenu = e.source
	if not multiMenu then
		return
	end

	local fortifyCastingEffects = tes3.mobilePlayer:getActiveMagicEffects({ effect = tes3.effect.T_restoration_FortifyCasting })	-- This limits findChild calls, but is that actually more efficient?
	if #fortifyCastingEffects > 0 then
		local magicLayout = multiMenu:findChild("MenuMulti_bottom_row_left"):findChild("MenuMulti_icons"):findChild("MenuMulti_magic_layout")
		if not magicLayout then
			return
		end

		local colorBar = magicLayout:findChild("PartFillbar_colorbar_ptr")
		local magicIcon = magicLayout:findChild("MenuMulti_magic_icon")
		if not colorBar or not magicIcon then
			return
		end

		local magnitude = 0
		for _,v in pairs(fortifyCastingEffects) do
			magnitude = magnitude + v.magnitude
		end

		local spell = magicIcon:getPropertyObject("MagicMenu_Spell")
		if not spell then return end
		---@cast spell tes3spell
		local castChance

		if spell.magickaCost > tes3.mobilePlayer.magicka.current then
			castChance = 0
		else
			castChance = spell:calculateCastChance({ caster = tes3.player, checkMagicka = false })
			castChance = castChance + magnitude
		end

		local width = math.clamp(castChance / 100, .001, 1)
		colorBar.widthProportional = width
	end
end

---@param e uiActivatedEventData
function this.onMenuMultiActivated(e)
	e.element:registerAfter(tes3.uiEvent.preUpdate, fortifyCastingMultiFillbar)
end

---@param e uiPreEventEventData
local function fortifyCastingSpellmakingMenuChance(e)
	local spellmakingMenu = e.source
	if not spellmakingMenu then return end

	local fortifyCastingEffects = tes3.mobilePlayer:getActiveMagicEffects({ effect = tes3.effect.T_restoration_FortifyCasting })
	if #fortifyCastingEffects > 0 then
		local magnitude = 0
		for _,v in pairs(fortifyCastingEffects) do
			magnitude = magnitude + v.magnitude
		end

		local spellChance = spellmakingMenu:findChild("MenuSpellmaking_SpellChance")
		if not spellChance then return end
		if not spellChance.text then return end

		local effectProperty = spellChance:getPropertyFloat("MenuSpellmaking_Effect")

		if effectProperty == 0 or effectProperty == 99999 then return end -- This is true if no effects have been added or if all of the previously selected effects have been removed, both of which should give a spellChance of 0

		if effectProperty > 0 then		-- effectProperty appears to have 0.7 added to it when positive and 0.3 subtracted from it when negative, hence the condition and calculations here
			spellChance.text = math.round(effectProperty - 0.7) + magnitude
		else
			spellChance.text = math.round(effectProperty + 0.3) + magnitude
		end
	end
end

---@param e uiActivatedEventData
function this.onMenuSpellmakingActivated(e)
	e.element:registerAfter(tes3.uiEvent.preUpdate, fortifyCastingSpellmakingMenuChance)
end

---@param e uiPreEventEventData
local function fortifyCastingMenuPercents(e)
	local magicMenu = e.source
	if not magicMenu then return end

	local spellLayout = magicMenu:findChild("MagicMenu_spell_layout")
	if not spellLayout then return end

	local spellPercents = spellLayout:findChild("MagicMenu_spell_percents")
	if not spellPercents then return end

	local fortifyCastingEffects = tes3.mobilePlayer:getActiveMagicEffects({ effect = tes3.effect.T_restoration_FortifyCasting })
	if #fortifyCastingEffects > 0 then
		local magnitude = 0
		for _,v in pairs(fortifyCastingEffects) do
			magnitude = magnitude + v.magnitude
		end

		for i,percent in ipairs(spellPercents.children) do
			if percent.text ~= "/100" then
				local spell = percent:getPropertyObject("MagicMenu_Spell")
				---@cast spell tes3spell
				local castChance
				
				if spell.magickaCost > tes3.mobilePlayer.magicka.current then
					castChance = 0
				else
					castChance = spell:calculateCastChance({ caster = tes3.player, checkMagicka = false })
					castChance = castChance + magnitude
				end

				if castChance > 0.5 then
					castChance = math.round(castChance)

					if castChance >= 100 then
						percent.text = "/100"
						percent.autoWidth = true
						--percent.width = 28
					else
						percent.text = "/" .. castChance
						percent.autoWidth = true
					end
				end
			end
		end
	end
end

---@param e uiActivatedEventData
function this.onMenuMagicActivated(e)
	e.element:registerAfter(tes3.uiEvent.preUpdate, fortifyCastingMenuPercents)
end

---@param e spellCastEventData
function this.fortifyCastingOnSpellCast(e)
	local fortifyCastingEffects = e.caster.mobile:getActiveMagicEffects({ effect = tes3.effect.T_restoration_FortifyCasting })
	if #fortifyCastingEffects > 0 then
		local magnitude = 0
		for _,v in pairs(fortifyCastingEffects) do
			magnitude = magnitude + v.magnitude
		end

		e.castChance = e.castChance + magnitude
	end
end

---@param e tes3magicEffectTickEventData
local function blinkEffect(e)
	if (not e:trigger()) then
		return
	end

	if tes3.worldController.flagLevitationDisabled then
		tes3ui.showNotifyMenu(common.i18n("magic.blinkLevitationDisabled"))
		e.effectInstance.state = tes3.spellState.retired
		return
	end

	local range = e.effectInstance.magnitude * 22.1

	local wardCheck = tes3.rayTest{
		position = tes3.getPlayerEyePosition(),
		direction = tes3.getPlayerEyeVector(),
		maxDistance = range,
		findAll = true,
		ignore = { tes3.player },
		observeAppCullFlag  = false,
		useBackTriangles = true
	}			
	
	if wardCheck then
		for _,detection in ipairs(wardCheck) do
			if detection.reference then
				if detection.reference.baseObject.id:find("T_Dae_Ward_") or detection.reference.baseObject.id:find("T_Aid_PasswallWard_") then
					range = detection.distance - 16
					break
				end
			end
		end
	end

	if range > 0 then
		local obstacles = tes3.rayTest{
			position = tes3.getPlayerEyePosition(),
			direction = tes3.getPlayerEyeVector(),
			maxDistance = range,
			findAll = true,
			ignore = { tes3.player }
		}
	
		if obstacles then		-- I would much rather just test the collision, but that doesn't seem to be possible
			for _,obstacle in ipairs(obstacles) do
				local validObstacle = true
				if obstacle.reference then
					local mesh = tes3.loadMesh(obstacle.reference.baseObject.mesh)
					if mesh.extraData then
						repeat
							if mesh.extraData.string and (mesh.extraData.string:lower() == "nco" or mesh.extraData.string:lower() == "nc") then validObstacle = false end
						until not mesh.extraData.next
					end
				elseif obstacle.object.name and obstacle.object.name:startswith("Water ") then
					validObstacle = false
				end
		
				if validObstacle then
					range = obstacle.distance - (tes3.mobilePlayer.boundSize2D.y / 2) - 16		-- The 16 is there to put a bit more space between the player and the target; there is probably a better way to do this by taking the angle of the camera into account
					break
				end
			end
		end
	
		if range > 0 then
			local destination = tes3.mobilePlayer.position + tes3.getPlayerEyeVector() * range
	
			tes3.mobilePlayer.isSwimming = false	-- If the player is swimming, then they need to stop swimming in order to leave the water; a condition for this shouldn't be needed since they were either not swimming to begin with or will immediately begin swimming again if still underwater
	
			local heightCheck = tes3.rayTest{
				position = destination + tes3vector3.new(0, 0, tes3.mobilePlayer.height),
				direction = tes3vector3.new(0, 0, -1),
				maxDistance = tes3.mobilePlayer.height,
				ignore = { tes3.player },
			}
	
			if heightCheck and heightCheck.distance then
				destination = destination + tes3vector3.new(0, 0, tes3.mobilePlayer.height - heightCheck.distance)	-- This should prevent the player from clipping through objects below them
			end
	
			tes3.mobilePlayer.position = destination
		end
	end

	e.effectInstance.state = tes3.spellState.retired
end

---@param e addTempSoundEventData
function this.gazeOfVelothBlockActorSound(e)
	if e.reference and e.reference.data and e.reference.data.tamrielData and e.reference.data.tamrielData.gazeOfVeloth then
		if e.isVoiceover then return false end
	end
end

---@param e bodyPartAssignedEventData
function this.gazeOfVelothBodyPartAssigned(e)
	if e.reference.data.tamrielData and e.reference.data.tamrielData.gazeOfVelothSkeleton then
		if e.index == tes3.partIndex.chest then
			for _,v in pairs(raceSkeletonBodyParts) do
				if e.reference.baseObject.race.id == v[1] then
					if e.bodyPart.partType == tes3.activeBodyPartLayer.base then
						e.bodyPart = tes3.getObject(v[2])
					else
						e.bodyPart = tes3.getObject(v[3])
					end
				end
			end
		else
			e.bodyPart = nil
		end
	end
end

---@param e tes3magicEffectTickEventData
local function gazeOfVelothEffect(e)
	if (not e:trigger()) then
		return
	end

	local target = e.effectInstance.target

	if not target or target.mobile.isDead or (target.data.tamrielData and target.data.tamrielData.wabbajack) then
		e.effectInstance.state = tes3.spellState.retired
		return
	end

	local id = target.baseObject.id:lower()
	local name = target.object.name

	if table.contains(gazeOfVelothImmuneActors, id) then
		tes3ui.showNotifyMenu(common.i18n("magic.gazeOfVelothImmune", { name }))
		e.effectInstance.state = tes3.spellState.retired
		return
	end

	if target.mobile.actorType ~= tes3.actorType.npc then
		if id:find("dagoth_ur") then
			tes3ui.showNotifyMenu(common.i18n("magic.gazeOfVelothDagoth"))
			e.effectInstance.state = tes3.spellState.retired
			return
		end

		if target.baseObject.type == tes3.creatureType.humanoid then
			if id:find("ash_") or id:find("dagoth_") or id:find("corprus_") or id == "ascended_sleeper" then
				tes3ui.showNotifyMenu(common.i18n("magic.gazeOfVelothAsh", { name }))
				e.effectInstance.state = tes3.spellState.retired
				return
			end
		end
		
		if target.baseObject.type == tes3.creatureType.daedra then
			tes3ui.showNotifyMenu(common.i18n("magic.gazeOfVelothDaedra", { name }))
			e.effectInstance.state = tes3.spellState.retired
			return
		end

		if target.baseObject.type == tes3.creatureType.normal or target.baseObject.type == tes3.creatureType.undead then
			tes3ui.showNotifyMenu(common.i18n("magic.gazeOfVelothCreature", { name }))
			e.effectInstance.state = tes3.spellState.retired
			return
		end

		tes3ui.showNotifyMenu(common.i18n("magic.gazeOfVelothOther", { name }))
		e.effectInstance.state = tes3.spellState.retired
		return
	end


	target.data.tamrielData = target.data.tamrielData or {}
	target.data.tamrielData.gazeOfVeloth = true
	tes3.removeSound({ sound = nil, reference = target })	-- Stop long-winded voice lines from playing when the target is stripped of their flesh
	tes3.playSound({ sound = tes3.getMagicEffect(tes3.effect.damageHealth).hitSoundEffect, reference = target })	-- The hit sound is stopped by the line above though, so this plays it again
	target.mobile:kill()
	tes3.incrementKillCount({ actor = target.baseObject })

	if target.baseObject.faction then tes3.triggerCrime({ type = tes3.crimeType.killing, victim = target.baseObject.faction }) end	-- Ensures that the player will be expelled for killing a faction member
	tes3.triggerCrime({ type = tes3.crimeType.killing, victim = target.baseObject })

	if target.baseObject.race then
		for _,v in pairs(raceSkeletonBodyParts) do
			if target.baseObject.race.id == v[1] then
				target.data.tamrielData.gazeOfVelothSkeleton = true
				target:updateEquipment()

				e.effectInstance.state = tes3.spellState.retired
				return
			end
		end
	end

	local container = tes3.createReference({ object = "T_Glb_GazeVeloth_Empty", position = target.position , orientation = target.orientation, cell = target.cell })	-- If this runs, then the target does not belong to a compatible race listed in raceSkeletonBodyParts
	tes3.transferInventory({ from = target, to = container, limitCapacity = false })
	tes3.positionCell({ reference = target, position = { 0, 0, -53.187 }, cell = "T_GazeOfVeloth" })	-- All sorts of problems can arise from disabling a target within the effect event
	
	e.effectInstance.state = tes3.spellState.retired
end

function this.distractedReturnTick()
	for ref in pairs(distractedReferences) do
		---@cast ref tes3reference
		if ref.data.tamrielData and ref.data.tamrielData.distract then
			if (ref.mobile.actorType == tes3.actorType.npc and #ref.mobile:getActiveMagicEffects({ effect = tes3.effect.T_illusion_DistractHumanoid }) == 0) or (ref.mobile.actorType == tes3.actorType.creature and #ref.mobile:getActiveMagicEffects({ effect = tes3.effect.T_illusion_DistractCreature }) == 0) then
				if not ref.mobile.isMovingForward then
					tes3.setAIWander({ reference = ref, range = ref.data.tamrielData.distract.distance, duration = ref.data.tamrielData.distract.duration, time = ref.data.tamrielData.distract.hour, idles = ref.data.tamrielData.distract.idles })
					
					if ref.data.tamrielData.distract.distance == 0 then
						ref.orientation = ref.data.tamrielData.distract.orientation -- If they are supposed to actually wander around, then not resetting the orientation feels more natural, hence it being under this condition
						ref.data.tamrielData.distractOldPosition = ref.data.tamrielData.distract.position	-- They don't quite return to their original positions, so this is used with onDistractedReferenceActivated to do so
					end

					ref.mobile.hello = ref.data.tamrielData.distract.hello

					ref.data.tamrielData.distract = nil
					distractedReferences[ref] = nil
				end
			end
		end
	end
end

---@param e referenceActivatedEventData
function this.onDistractedReferenceActivated(e)
	if e.reference.data and e.reference.data.tamrielData then
		if e.reference.data.tamrielData.distract then
			distractedReferences[e.reference] = true
		elseif e.reference.data.tamrielData.distractOldPosition then
			e.reference.position = e.reference.data.tamrielData.distractOldPosition
			e.reference.data.tamrielData.distractOldPosition = nil
		end
	end
end

-- Most of this function's code was originally in a function trigged by cellChanged, but that could lead to NPCs visibly teleporting around when moving between exterior cells
---@param e referenceDeactivatedEventData
function this.onDistractedReferenceDeactivated(e)
	local ref = e.reference

	if ref.data and distractedReferences[ref] and ref.data.tamrielData and ref.data.tamrielData.distract then
		tes3.setAIWander({ reference = ref, range = ref.data.tamrielData.distract.distance, duration = ref.data.tamrielData.distract.duration, time = ref.data.tamrielData.distract.hour, idles = ref.data.tamrielData.distract.idles })
		ref.position = ref.data.tamrielData.distract.position

		if ref.data.tamrielData.distract.distance == 0 then ref.orientation = ref.data.tamrielData.distract.orientation end

		ref.mobile.hello = ref.data.tamrielData.distract.hello

		ref.data.tamrielData.distract = nil

		distractedReferences[ref] = nil
	end
end

---@param ref tes3reference
---@param isEnd boolean
local function playDistractedVoiceLine(ref, isEnd)
	if ref.mobile.actorType == tes3.actorType.npc then
		for _,v in pairs(distractedVoiceLines) do
			local raceName, isFemale, voicesStart, voicesEnd = unpack(v)
			if ref.baseObject.race.name == raceName and ref.baseObject.female == isFemale then
				local voices
				if not isEnd then voices = voicesStart
				else voices = voicesEnd end
	
				if voices then
					local path = voices[math.random(#voices)]
					if path then tes3.say({ reference = ref, soundPath = path }) end
				end
	
				return
			end
		end
	elseif ref.mobile.actorType == tes3.actorType.creature then
		local creature = ref.baseObject

		while (creature.soundCreature) do
			creature = creature.soundCreature	-- Get the base sound creature
		end
		
		local soundGen = tes3.getSoundGenerator(creature.id, tes3.soundGenType.moan)
	
		if soundGen then tes3.playSound({ reference = ref, sound = soundGen.sound }) end
	end
end

---@param e magicEffectRemovedEventData
function this.distractRemovedEffect(e)
	if e.effect.id == tes3.effect.T_illusion_DistractCreature or e.effect.id == tes3.effect.T_illusion_DistractHumanoid then
		if e.reference and e.reference.data.tamrielData and e.reference.data.tamrielData.distract then
			if math.random() < 0.45 then playDistractedVoiceLine(e.reference, true) end
			tes3.setAITravel({ reference = e.reference, destination = e.reference.data.tamrielData.distract.position })
		end
	end
end

---@param ref tes3reference
---@param package tes3aiPackageWander
local function distractSavePackage(ref, package)
	ref.data.tamrielData = ref.data.tamrielData or {}

	if not package then
		ref.data.tamrielData.distract = {
			position = {
				ref.position.x,
				ref.position.y,
				ref.position.z
			},
			orientation = {
				ref.orientation.x,
				ref.orientation.y,
				ref.orientation.z
			},
			cell = ref.cell.id,
			distance = 0,
			duration = 0,
			hour = 0,
			idles = { 60, 20, 10, 0, 0, 0, 0, 0 },
			hello = ref.mobile.hello
		}
	elseif package.type == 0 then	-- Have condition for preexisting travel package too?
		local packageIdles = {}
		for k,v in pairs(package.idles) do
			packageIdles[k] = v.chance
		end

		ref.data.tamrielData.distract = {
			position = {
				ref.position.x,
				ref.position.y,
				ref.position.z
			},
			orientation = {
				ref.orientation.x,
				ref.orientation.y,
				ref.orientation.z
			},
			cell = ref.cell.id,
			distance = package.distance,
			duration = package.duration,
			hour = package.hourOfDay,
			idles = packageIdles,
			hello = ref.mobile.hello
		}
	end
end

---@param e tes3magicEffectTickEventData
local function distractEffect(e)
	local target = e.effectInstance.target
	local range = e.effectInstance.magnitude * 22.1
	
	local activePackage = target.mobile.aiPlanner:getActivePackage()
	if not activePackage or activePackage.type < 1 then
		local targetDistance
		local finalPlayerDistance

		local bestDestination
		
		if target.cell.isInterior or (target.cell.pathGrid and #target.cell.pathGrid.nodes > 9 and target.position:distance(common.getClosestNode(target).position) <= 512) then	-- The path grid approach is used in interiors and in exterior cells where there are many nodes with one nearby, such as in cities. These conditions should prevent actors outside of a city's walls yet still in the cell from moving inside.
			local nodeArr = target.cell.pathGrid.nodes
			local bestScore = 0
			
			local threeClosestNodes = common.getClosestNodes(target, 512)

			for _,node in pairs(nodeArr) do
				if math.abs(node.position.z - target.position.z) < 384 then		-- This is meant to stop actors from walking up/down several flights of stairs, which I think would feel unrealistic
					targetDistance = target.position:distance(node.position)
					if targetDistance <= range then
						local pathExists = common.pathGridBFS(threeClosestNodes[1], node)	-- pathGridBFS is used here to check whether a path actually exists because it is quicker than pathGridDijkstra
						if pathExists then
							finalPlayerDistance = tes3.player.position:distance(node.position)
							if math.abs(tes3.player.position.z - node.position.z) > 160 then finalPlayerDistance = finalPlayerDistance * 4 end	-- 4 was chosen as a constant arbitrarily and the distract effects may benefit from tweaking it

							local shortestPathDistance = math.huge
							local shortestPath
							for _,v in ipairs(threeClosestNodes) do
								if node ~= threeClosestNodes[1] and node ~= threeClosestNodes[2] and node ~= threeClosestNodes[3] then
									---@cast v tes3pathGridNode
									local path = common.pathGridDijkstra(v, node)
									local pathDistance = 0
									local previousPathNode

									for _,pathNode in ipairs(path) do
										---@cast pathNode tes3pathGridNode
										if previousPathNode then pathDistance = pathDistance + pathNode.position:distance(previousPathNode.position) end
										previousPathNode = pathNode
									end

									if pathDistance < shortestPathDistance then
										shortestPath = path
										shortestPathDistance = pathDistance
									end
								end
							end

							local nodePlayerDistance
							local shortestPlayerDistance = math.huge

							if shortestPath then
								for _,pathNode in pairs(shortestPath) do	-- Optimize this loop by stopping once the actor begins moving away from the player?
									nodePlayerDistance = tes3.player.position:distance(pathNode.position)
									if math.abs(tes3.player.position.z - pathNode.position.z) > 160 then nodePlayerDistance = nodePlayerDistance * 4 end
									if nodePlayerDistance < shortestPlayerDistance then shortestPlayerDistance = nodePlayerDistance end
								end
	
								local score = targetDistance / 2 + finalPlayerDistance / 4 + shortestPlayerDistance		-- These constants were also chosen arbitrarily and finetuning them might yield better results
	
								if score > bestScore then
									bestScore = score
									bestDestination = node.position
								end
							end
						end
					end
				end
			end
		else
			local bestDistance = 0
			local bestPlayerFinalDistance = 0
			local destination


			for rotation = 0, 342, 18 do
				local pathCollision = tes3.rayTest{	-- This is not a very rigorous check, but anything that works better would also be much more complicated, so this is it for now
					position = target.position + tes3vector3.new(0, 0, 0.25 * target.mobile.height),
					direction = target.orientation + tes3vector3.new(0, 0, rotation),
					maxDistance = range + target.mobile.boundSize2D.y / 2,
					root = { tes3.game.worldObjectRoot },
					ignore = { target },
				}

				if pathCollision and pathCollision.distance then targetDistance = pathCollision.distance - target.mobile.boundSize2D.y / 2
				else targetDistance = range end

				if targetDistance >= bestDistance then
					destination = target.position + tes3vector3.new(math.sin(math.rad(rotation)) * range, math.cos(math.rad(rotation)) * range, 0)
					finalPlayerDistance = tes3.player.position:distance(destination)

					if finalPlayerDistance > bestPlayerFinalDistance then
						bestDistance = targetDistance
						bestPlayerFinalDistance = finalPlayerDistance
						bestDestination = destination
					end
				end
			end
		end

		if bestDestination then
			distractSavePackage(target, activePackage)
			if math.random() < 0.45 then playDistractedVoiceLine(target, false) end
			tes3.setAITravel({ reference = target, destination = bestDestination })
			target.mobile.hello = 0
			distractedReferences[target] = true
		else  
			target.data.tamrielData.distract = nil
		end
	end
end

---@param e tes3magicEffectTickEventData
local function distractHumanoidEffect(e)
	if (not e:trigger()) then
		return
	end

	local target = e.effectInstance.target	-- Level restriction? Tied to magnitude?

	if not target or target.mobile.actorType ~= tes3.actorType.npc or target.mobile.isDead or target.mobile.inCombat or target.mobile.isPlayerDetected or (target.data.tamrielData and target.data.tamrielData.distract) then
		e.effectInstance.state = tes3.spellState.retired	-- This condition seems to be hit when the effect expires
		return
	end
	
	--	if target.mobile.isPlayerDetected then
	--		tes3.triggerCrime({ type = tes3.crimeType.trespass })
	--		e.effectInstance.state = tes3.spellState.retired
	--		return
	--	end
	
	distractEffect(e)
end

---@param e tes3magicEffectTickEventData
local function distractCreatureEffect(e)
	if (not e:trigger()) then
		return
	end

	local target = e.effectInstance.target	-- Level restriction? Tied to magnitude?

	if not target or target.mobile.actorType ~= tes3.actorType.creature or target.mobile.isDead or target.mobile.inCombat or target.mobile.isPlayerDetected or (target.data.tamrielData and target.data.tamrielData.distract) then	-- Require player to sneak?
		e.effectInstance.state = tes3.spellState.retired
		return
	end

	distractEffect(e)
end

-- Stop the player from talking to the summon and the summon from talking to the player (just in case)
---@param e activateEventData
function this.corruptionBlockActivation(e)
	if e.target.id == tes3.player.data.tamrielData.corruptionReferenceID or (e.activator.id == tes3.player.data.tamrielData.corruptionReferenceID and e.target == tes3.player) then return false end
end

---@param e mobileActivatedEventData
function this.corruptionSummoned(e)
	if corruptionCasted and e.reference.baseObject.id == corruptionActorID then	-- Apply VFX to summon here as well?
		corruptionCasted = false
		tes3.player.data.tamrielData.corruptionReferenceID = e.reference.id
		e.mobile.alarm = 0
		e.mobile.fight = 100
		e.mobile.flee = 0
		e.mobile.hello = 0
	end
end

---@param e tes3magicEffectTickEventData
local function weaponResartusEffect(e)
	if (not e:trigger()) then
		return
	end
	
	local weapon = tes3.getEquippedItem({ actor = e.sourceInstance.caster, enchanted = true, objectType = tes3.objectType.weapon})

	if weapon then
		weapon.itemData.condition = weapon.itemData.condition + e.effectInstance.magnitude
		if weapon.itemData.condition > weapon.object.maxCondition then
			weapon.itemData.condition = weapon.object.maxCondition
		end
		
		weapon.itemData.charge = weapon.itemData.charge + e.effectInstance.magnitude
		if weapon.itemData.charge > weapon.object.enchantment.maxCharge then
			weapon.itemData.charge = weapon.object.enchantment.maxCharge
		end
	end

	e.effectInstance.state = tes3.spellState.retired
end

---@param e tes3magicEffectTickEventData
local function armorResartusEffect(e)
	if (not e:trigger()) then
		return
	end
	
	local armor = {
		tes3.getEquippedItem({ actor = e.sourceInstance.caster, enchanted = true, objectType = tes3.objectType.armor, slot = tes3.armorSlot.cuirass }),
		tes3.getEquippedItem({ actor = e.sourceInstance.caster, enchanted = true, objectType = tes3.objectType.armor, slot = tes3.armorSlot.greaves }),
		tes3.getEquippedItem({ actor = e.sourceInstance.caster, enchanted = true, objectType = tes3.objectType.armor, slot = tes3.armorSlot.helmet }),
		tes3.getEquippedItem({ actor = e.sourceInstance.caster, enchanted = true, objectType = tes3.objectType.armor, slot = tes3.armorSlot.boots }),
		tes3.getEquippedItem({ actor = e.sourceInstance.caster, enchanted = true, objectType = tes3.objectType.armor, slot = tes3.armorSlot.shield }),
		tes3.getEquippedItem({ actor = e.sourceInstance.caster, enchanted = true, objectType = tes3.objectType.armor, slot = tes3.armorSlot.leftPauldron }),
		tes3.getEquippedItem({ actor = e.sourceInstance.caster, enchanted = true, objectType = tes3.objectType.armor, slot = tes3.armorSlot.rightPauldron }),
		tes3.getEquippedItem({ actor = e.sourceInstance.caster, enchanted = true, objectType = tes3.objectType.armor, slot = tes3.armorSlot.leftGauntlet }),
		tes3.getEquippedItem({ actor = e.sourceInstance.caster, enchanted = true, objectType = tes3.objectType.armor, slot = tes3.armorSlot.rightGauntlet }),
		tes3.getEquippedItem({ actor = e.sourceInstance.caster, enchanted = true, objectType = tes3.objectType.armor, slot = tes3.armorSlot.leftBracer }),
		tes3.getEquippedItem({ actor = e.sourceInstance.caster, enchanted = true, objectType = tes3.objectType.armor, slot = tes3.armorSlot.rightBracer })
	}

	local conditionMagnitude = e.effectInstance.magnitude
	local chargeMagnitude = e.effectInstance.magnitude
	local hasChanged = false

	while conditionMagnitude > 0 or chargeMagnitude > 0 do
		for _,item in pairs(armor) do
			if item then
				if conditionMagnitude > 0 and item.itemData.condition < item.object.maxCondition then
					item.itemData.condition = item.itemData.condition + 1
					conditionMagnitude = conditionMagnitude - 1
					hasChanged = true
				end
				
				if chargeMagnitude > 0 and item.itemData.charge < item.object.enchantment.maxCharge then
					item.itemData.charge = item.itemData.charge + 1
					chargeMagnitude = chargeMagnitude - 1
					hasChanged = true
				end
			end
		end

		if not hasChanged then break end

		hasChanged = false
	end

	e.effectInstance.state = tes3.spellState.retired
end

-- Diject's mapMarkerLib was an invaluable reference for the calculations required to make these map markers work
---@param mapPane tes3uiElement
---@param multiPane tes3uiElement
local function calculateMapValues(mapPane, multiPane)
	local mapCell = mapPane:findChild("MenuMap_map_cell")
	local multiCell = multiPane:findChild("MenuMap_map_cell")

	mapWidth = mapCell.width
	mapHeight = mapCell.height
	multiWidth = multiCell.width
	multiHeight = multiCell.height

	if tes3.player.cell.isInterior then
		local mapPlayerMarker = mapPane:findChild("MenuMap_local_player")
		local multiPlayerMarker = multiPane.parent.parent:findChild("MenuMap_local_player")

		local northMarkerAngle = 0
		for ref in tes3.player.cell:iterateReferences(tes3.objectType.static) do
			if ref.baseObject.id == "NorthMarker" then
				northMarkerAngle = ref.orientation.z
				break
			end
		end

		northMarkerCos = math.cos(northMarkerAngle)
		northMarkerSin = math.sin(northMarkerAngle)

		local xShift = -tes3.player.position.x
		local yShift = tes3.player.position.y
		local xNorm = xShift * northMarkerCos + yShift * northMarkerSin
		local yNorm = yShift * northMarkerCos - xShift * northMarkerSin
	
		local newInteriorMapOriginX = mapPlayerMarker.positionX + xNorm / (8192 / mapWidth)
		local newInteriorMapOriginY = mapPlayerMarker.positionY - yNorm / (8192 / mapHeight)
		local newInteriorMultiOriginX = -multiPane.parent.positionX + multiPlayerMarker.positionX + xNorm / (8192 / multiWidth)
		local newInteriorMultiOriginY = -multiPane.parent.positionY + multiPlayerMarker.positionY - yNorm / (8192 / multiHeight)

		if not (math.isclose(interiorMapOriginX, newInteriorMapOriginX, 2) and (math.isclose(interiorMapOriginY, newInteriorMapOriginY, 2))) then
			interiorMapOriginX = newInteriorMapOriginX
			interiorMapOriginY = newInteriorMapOriginY
		end

		if not (math.isclose(interiorMultiOriginX, newInteriorMapOriginX, 2) and (math.isclose(interiorMultiOriginY, newInteriorMapOriginY, 2))) then
			interiorMultiOriginX = newInteriorMultiOriginX
			interiorMultiOriginY = newInteriorMultiOriginY
		end
	else
		-- It seems as though this is not being updated exactly when it should be; exterior markers will briefly move across cells as the player moves around.
		local mapLayout = mapPane:findChild("MenuMap_map_layout")
		local mapCellProperty = mapCell:getPropertyObject("MenuMap_cell")
		local multiCellProperty = multiCell:getPropertyObject("MenuMap_cell")
		local multiLayout = multiPane:findChild("MenuMap_map_layout")

		if mapCellProperty and multiCellProperty then
			mapOriginGridX = mapCellProperty.gridX - math.floor(mapCell.positionX / mapCell.width)	-- Should each set of lines really have different types of values in the numerators?
			mapOriginGridY = mapCellProperty.gridY - math.floor(mapLayout.positionY / mapCell.height)
			multiOriginGridX = multiCellProperty.gridX - math.floor(multiCell.positionX / multiCell.width)
			multiOriginGridY = multiCellProperty.gridY - math.floor(multiLayout.positionY / multiCell.height)
		end
	end
end

---@param position tes3vector3
---@return number, number, number, number
local function calcInteriorPos(position)
	local xNorm = position.x * northMarkerCos - position.y * northMarkerSin
	local yNorm = -position.y * northMarkerCos - position.x * northMarkerSin

	local mapX = interiorMapOriginX + xNorm / (8192 / mapWidth)
	local mapY = interiorMapOriginY - yNorm / (8192 / mapHeight)
	local multiX = interiorMultiOriginX + xNorm / (8192 / multiWidth)
	local multiY = interiorMultiOriginY - yNorm / (8192 / multiHeight)

	return mapX, mapY, multiX, multiY
end

---@param position tes3vector3
---@return number, number, number, number
local function calcExteriorPos(position)
	local mapX = (position.x / 8192 - mapOriginGridX) * mapWidth
	local mapY = (position.y / 8192 - mapOriginGridY - 1) * mapHeight
	local multiX = (position.x / 8192 - multiOriginGridX) * multiWidth
	local multiY = (position.y / 8192 - multiOriginGridY - 1) * multiHeight

	return mapX, mapY, multiX, multiY
end

---@param ref tes3reference
---@return boolean
local function detectInvisibilityValid(ref)
	if ref == tes3.player then return false end

	local obj = ref.baseObject

	if obj.mesh:lower():find("ghost") or obj.mesh:lower():find("spirit") or obj.mesh:lower():find("wraith") or obj.mesh:lower():find("spectre") or obj.mesh:lower():find("specter")	-- These conditions should catch most actors that are incorporeal and shouldn't be affected by Detect Invisibility
		or obj.id:lower():find("ghost") or obj.id:lower():find("spirit") or obj.id:lower():find("wraith") or obj.id:lower():find("spectre") or obj.id:lower():find("specter") then
		return false
	end
	
	if not tes3.canCastSpells({ target = ref }) then return false end
	local actorSpells = tes3.getSpells({ target = ref, spellType = tes3.spellType.ability, getActorSpells = true, getRaceSpells = false, getBirthsignSpells = false })

	if actorSpells then
		local ghostAbilities = { tes3.getObject("ghost ability"), tes3.getObject("Ulfgar_Ghost_sp") , tes3.getObject("TR_m4_EmmurbalpituGhost_EN"), tes3.getObject("TR_m3_OE_GhostGlow"), tes3.getObject("TR_m4_RR_StorigGlow") }	-- It would be nice to just have a single TD ghost effect where possible

		for _,spell in pairs(actorSpells) do
			for _,ability in pairs(ghostAbilities) do
				if ability and spell == ability then return false end
			end
		end
	end

	for _,effect in pairs(ref.mobile.activeMagicEffectList)do
		if effect.effectId == tes3.effect.chameleon or effect.effectId == tes3.effect.invisibility then return true end
	end

	return false
end

---@param e mobileActivatedEventData
function this.onInvisibleMobileActivated(e)
	if detectInvisibilityValid(e.reference) then	-- This kind of approach should be reliable until someone makes an addon that allows for the AI to use chameleon and invisibility effects.
		local chameleonEffects = e.mobile:getActiveMagicEffects({ effect = tes3.effect.chameleon })		-- Might as well get these values here
		local chameleonMagnitude = 0
		local detectedChameleonMagnitude = 0
		if #chameleonEffects > 0 then
			for _,v in pairs(chameleonEffects) do
				chameleonMagnitude = chameleonMagnitude + v.magnitude
			end

			if chameleonMagnitude > 100 then chameleonMagnitude = 100 end
			
			chameleonMagnitude = chameleonMagnitude / 100

			detectedChameleonMagnitude = chameleonMagnitude - .5
			if detectedChameleonMagnitude < 0 then detectedChameleonMagnitude = 0 end
		end

		local invisibilityMagnitude = 0
		if #e.mobile:getActiveMagicEffects({ effect = tes3.effect.invisibility }) > 0 then
			invisibilityMagnitude = 1
		end

		invisibleReferences[e.reference] = { chameleon = chameleonMagnitude, detectedChameleon = detectedChameleonMagnitude, invisibility = invisibilityMagnitude }
	end
end

---@param e mobileDeactivatedEventData
function this.onInvisibleMobileDeactivated(e)
	invisibleReferences[e.reference] = nil
end

---@param e spellTickEventData
function this.invisibilityAppliedEffect(e)
	if e.target and e.target ~= tes3.player and (e.effect.id == tes3.effect.chameleon or e.effect.id == tes3.effect.invisibility) and not invisibleReferences[e.target] then	-- Could this miss another effect being applied to an actor that is already "invisible"? Yes, but I don't really care at the moment.
		this.onInvisibleMobileActivated({ claim = false, mobile = e.target.mobile, reference = e.target })
	end
end

---@param e magicEffectRemovedEventData
function this.invisibilityRemovedEffect(e)
	if e.target and e.target ~= tes3.player and e.effect.id == tes3.effect.chameleon or e.effect.id == tes3.effect.invisibility then
		if detectInvisibilityValid(e.reference) then															-- The actor might (but probably won't) still have other acceptable effects
			local chameleonEffects = e.mobile:getActiveMagicEffects({ effect = tes3.effect.chameleon })
			local chameleonMagnitude = 0
			local detectedChameleonMagnitude = 0
			if #chameleonEffects > 0 then
				for _,v in pairs(chameleonEffects) do
					chameleonMagnitude = chameleonMagnitude + v.magnitude
				end

				if chameleonMagnitude > 100 then chameleonMagnitude = 100 end

				chameleonMagnitude = chameleonMagnitude / 100

				detectedChameleonMagnitude = chameleonMagnitude - .5
				if detectedChameleonMagnitude < 0 then detectedChameleonMagnitude = 0 end
			end

			local invisibilityMagnitude = 0
			if #e.mobile:getActiveMagicEffects({ effect = tes3.effect.invisibility }) > 0 then
				invisibilityMagnitude = 1
			end

			invisibleReferences[e.reference] = { chameleon = chameleonMagnitude, detectedChameleon = detectedChameleonMagnitude, invisibility = invisibilityMagnitude }
		else
			invisibleReferences[e.reference] = nil
		end
	end
end

--- @param e simulateEventData
function this.detectInvisibilityOpacity(e)
	for actor,magnitudes in pairs(invisibleReferences) do		-- Should the other parts of Detect Invisibility rely on invisibleReferences too?
		local detectInvisibilityEffects = tes3.mobilePlayer:getActiveMagicEffects({ effect = tes3.effect.T_mysticism_DetInvisibility })
		local undetectable = false
		if #detectInvisibilityEffects > 0 then
			local detectMagnitude = 0
			for _,v in pairs(detectInvisibilityEffects) do
				if v.magnitude > detectMagnitude then detectMagnitude = detectMagnitude + v.magnitude end
			end

			if tes3.player.position:distance(actor.position) <= detectMagnitude * 22.1 then
				local opacity = (1 - .75 * magnitudes.detectedChameleon) * (1 - magnitudes.invisibility / 2)
				if opacity < .5 then opacity = .5 end
			
				actor.mobile.animationController.opacity = opacity
				actor.data.tamrielData = actor.data.tamrielData or {}
				actor.data.tamrielData.invisibilityDetected = true
			else
				undetectable = true
			end
		else
			undetectable = true
		end

		
		if undetectable and actor.data.tamrielData and actor.data.tamrielData.invisibilityDetected then
			local opacity = (1 - .75 * magnitudes.chameleon) * (1 - magnitudes.invisibility)
			if opacity < 0 then opacity = 0
			elseif opacity >= 1 then opacity = 0.99999		-- A value of 1 is naturally not supported by the engine, so it is set to 0.99999 until MWSE's developers fix that bug
			end

			actor.mobile.animationController.opacity = opacity
			actor.data.tamrielData.invisibilityDetected = false
		end
	end
end

--- @param e calcHitChanceEventData
function this.detectInvisibilityHitChance(e)
	local fCombatInvisoMult = tes3.findGMST(tes3.gmst.fCombatInvisoMult).value

	local detectInvisibilityEffects = e.attackerMobile:getActiveMagicEffects({ effect = tes3.effect.T_mysticism_DetInvisibility })
	if #detectInvisibilityEffects > 0 then
		local detectMagnitude = 0
		for _,v in pairs(detectInvisibilityEffects) do
			if v.magnitude > detectMagnitude then detectMagnitude = detectMagnitude + v.magnitude end
		end

		if e.target and e.targetMobile and e.attacker.position:distance(e.target.position) <= detectMagnitude * 22.1 and not table.contains(tes3.player.mobile.friendlyActors, e.targetMobile) then
			if detectInvisibilityValid(e.target) then
				local chameleonEffects = e.targetMobile:getActiveMagicEffects({ effect = tes3.effect.chameleon })
				local chameleonMagnitude = 0
				local reducedChameleonMagnitude = 0
				if #chameleonEffects > 0 then
					for _,v in pairs(chameleonEffects) do
						chameleonMagnitude = chameleonMagnitude + v.magnitude
					end
	
					if chameleonMagnitude > 100 then chameleonMagnitude = 100 end
	
					reducedChameleonMagnitude = chameleonMagnitude - 50
					if reducedChameleonMagnitude < 0 then reducedChameleonMagnitude = 0 end
				end
	
				local invisibilityEffects = e.targetMobile:getActiveMagicEffects({ effect = tes3.effect.invisibility })
				local invisibilityMagnitude = 0
				if #invisibilityEffects > 0 then
					invisibilityMagnitude = 1		-- It doesn't look as though invisibility has much effect on hitchance as per https://wiki.openmw.org/index.php?title=Research:Combat and my own testing. In the calculation, invisibility's magnitude will be evaluated as 1 and multiplied by fCombatInvisoMult (.2).
				end
	
				e.hitChance = e.hitChance + fCombatInvisoMult * (chameleonMagnitude - reducedChameleonMagnitude)
				e.hitChance = e.hitChance + fCombatInvisoMult * invisibilityMagnitude / 2
			end
		end
	end
end

---@param pane tes3uiElement
local function deleteInvisibilityDetections(pane)
	for _,child in pairs (pane.children) do
		if child.name == "T_detInv" then child:destroy() end
	end
end

---@param pane tes3uiElement
---@param x number
---@param y number
local function createInvisibilityDetections(pane, x, y)
	local detection = pane:createImage({ id = "T_detInv", path = "textures\\td\\td_detect_invisibility_icon.dds" })
	detection.positionX = x
	detection.positionY = y
	detection.absolutePosAlignX = -32668
	detection.absolutePosAlignY = -32668
	detection.width = 3
	detection.height = 3
end

--- @param e magicEffectRemovedEventData
function this.detectInvisibilityTick(e)
	if e.reference and e.reference ~= tes3.player then return end	-- I would just use a filter, but that triggers a warning for some reason

	local mapMenu = tes3ui.findMenu("MenuMap")
	local multiMenu = tes3ui.findMenu("MenuMulti")
	local mapPane, multiPane

	if mapMenu then mapPane = mapMenu:findChild("MenuMap_pane") end
	if multiMenu then multiPane = multiMenu:findChild("MenuMap_pane") end

	if mapPane then deleteInvisibilityDetections(mapPane) end
	if multiPane then deleteInvisibilityDetections(multiPane) end

	if mapMenu and multiMenu then
		local detectInvisibilityEffects = tes3.mobilePlayer:getActiveMagicEffects({ effect = tes3.effect.T_mysticism_DetInvisibility })
		if #detectInvisibilityEffects > 0 then
			calculateMapValues(mapPane, multiPane)

			local totalMagnitude = 0
			for _,v in pairs(detectInvisibilityEffects) do
				totalMagnitude = totalMagnitude + v.magnitude
			end

			for _,actor in pairs(tes3.findActorsInProximity({ reference = tes3.player, range = totalMagnitude * 22.1 })) do	-- This should probably be changed to a refrence manager like the dreugh and lamia get in behavior.lua 
				if detectInvisibilityValid(actor.reference) then
					local mapX, mapY, multiX, multiY
					if tes3.player.cell.isInterior then mapX, mapY, multiX, multiY = calcInteriorPos(actor.position)
					else mapX, mapY, multiX, multiY = calcExteriorPos(actor.position) end

					createInvisibilityDetections(mapPane, mapX, mapY)
					createInvisibilityDetections(multiPane, multiX, multiY)
				end
			end
		end
	end
end

---@param pane tes3uiElement
local function deleteEnemyDetections(pane)
	for _,child in pairs (pane.children) do
		if child.name == "T_detEnm" then child:destroy() end
	end
end

---@param pane tes3uiElement
---@param x number
---@param y number
local function createEnemyDetections(pane, x, y)
	local detection = pane:createImage({ id = "T_detEnm", path = "textures\\td\\td_detect_enemy_icon.dds" })
	detection.positionX = x
	detection.positionY = y
	detection.absolutePosAlignX = -32668
	detection.absolutePosAlignY = -32668
	detection.width = 3
	detection.height = 3
end

--- @param e magicEffectRemovedEventData
function this.detectEnemyTick(e)
	if e.reference and e.reference ~= tes3.player then return end	-- I would just use a filter, but that triggers a warning for some reason

	local mapMenu = tes3ui.findMenu("MenuMap")
	local multiMenu = tes3ui.findMenu("MenuMulti")
	local mapPane, multiPane

	if mapMenu then mapPane = mapMenu:findChild("MenuMap_pane") end
	if multiMenu then multiPane = multiMenu:findChild("MenuMap_pane") end

	if mapPane then deleteEnemyDetections(mapPane) end
	if multiPane then deleteEnemyDetections(multiPane) end

	if mapMenu and multiMenu then
		local detectEnemyEffects = tes3.mobilePlayer:getActiveMagicEffects({ effect = tes3.effect.T_mysticism_DetEnemy })
		if #detectEnemyEffects > 0 then
			calculateMapValues(mapPane, multiPane)

			local totalMagnitude = 0
			for _,v in pairs(detectEnemyEffects) do
				totalMagnitude = totalMagnitude + v.magnitude
			end

			for _,actor in pairs(tes3.findActorsInProximity({ reference = tes3.player, range = totalMagnitude * 22.1 })) do	-- This should probably be changed to a refrence manager like the dreugh and lamia get in behavior.lua 

				local isHostile = false
				for _,hostileActor in pairs(actor.hostileActors) do
					if hostileActor == tes3.mobilePlayer then
						isHostile = true
					end
				end

				local disposition = 0
				if not isHostile and actor.actorType == tes3.actorType.npc then
					disposition = actor.reference.object.disposition
				end

				if (isHostile or (actor.fight > 70 and disposition < (actor.fight - 70) * 5)) and not table.contains(actor.friendlyActors, tes3.mobilePlayer) then	-- Checking the friendly actors is needed for the player's summons to not be detected (unless the player attacks them)
					local mapX, mapY, multiX, multiY
					if tes3.player.cell.isInterior then mapX, mapY, multiX, multiY = calcInteriorPos(actor.position)
					else mapX, mapY, multiX, multiY = calcExteriorPos(actor.position) end

					createEnemyDetections(mapPane, mapX, mapY)
					createEnemyDetections(multiPane, multiX, multiY)
				end
			end
		end
	end
end

---@param pane tes3uiElement
local function deleteHumanoidDetections(pane)
	for _,child in pairs (pane.children) do
		if child.name == "T_detHum" then child:destroy() end
	end
end

---@param pane tes3uiElement
---@param x number
---@param y number
local function createHumanoidDetections(pane, x, y)
	local detection = pane:createImage({ id = "T_detHum", path = "textures\\td\\td_detect_humanoid_icon.dds" })
	detection.positionX = x
	detection.positionY = y
	detection.absolutePosAlignX = -32668
	detection.absolutePosAlignY = -32668
	detection.width = 3
	detection.height = 3
end

--- @param e magicEffectRemovedEventData
function this.detectHumanoidTick(e)
	if e.reference and e.reference ~= tes3.player then return end	-- I would just use a filter, but that triggers a warning for some reason

	local mapMenu = tes3ui.findMenu("MenuMap")
	local multiMenu = tes3ui.findMenu("MenuMulti")
	local mapPane, multiPane

	if mapMenu then mapPane = mapMenu:findChild("MenuMap_pane") end
	if multiMenu then multiPane = multiMenu:findChild("MenuMap_pane") end

	if mapPane then deleteHumanoidDetections(mapPane) end
	if multiPane then deleteHumanoidDetections(multiPane) end

	if mapPane and multiPane then
		local detectHumanoidEffects = tes3.mobilePlayer:getActiveMagicEffects({ effect = tes3.effect.T_mysticism_DetHuman })
		if #detectHumanoidEffects > 0 then
			calculateMapValues(mapPane, multiPane)	-- Move this into a separate tick function so that it only runs once, rather than for each detection effect?

			local totalMagnitude = 0
			for _,v in pairs(detectHumanoidEffects) do
				totalMagnitude = totalMagnitude + v.magnitude
			end

			for _,actor in pairs(tes3.findActorsInProximity({ reference = tes3.player, range = totalMagnitude * 22.1 })) do	-- This should probably be changed to a refrence manager like the dreugh and lamia get in behavior.lua 
				if actor.actorType == tes3.actorType.npc then
					local mapX, mapY, multiX, multiY
					if tes3.player.cell.isInterior then mapX, mapY, multiX, multiY = calcInteriorPos(actor.position)
					else mapX, mapY, multiX, multiY = calcExteriorPos(actor.position) end

					createHumanoidDetections(mapPane, mapX, mapY)
					createHumanoidDetections(multiPane, multiX, multiY)
				end
			end
		end
	end
end

---@param e leveledItemPickedEventData
function this.insightEffect(e)
	local insightEffects = tes3.mobilePlayer:getActiveMagicEffects({ effect = tes3.effect.T_mysticism_Insight })
	if #insightEffects > 0 and e.list.count > 0 then
		local totalMagnitude = 0
		for _,v in pairs(insightEffects) do
			totalMagnitude = totalMagnitude + v.magnitude
		end

		local effectiveMagnitude = totalMagnitude / 100
		if effectiveMagnitude > 1 then effectiveMagnitude = 1 end		-- If the total magnitude ends up being higher than 100, this ensures that the probabilities won't get messed up
		
		if effectiveMagnitude > 0 then
			if e.list.chanceForNothing > 0 then
				local nothingFactor = 1 - (effectiveMagnitude * .9)	-- 0% chance of getting nothing seems OP and too obvious, so the probability of getting nothing is reduced by 90% at most
				local nothingChance = e.list.chanceForNothing * nothingFactor
				if math.random() * 100 < nothingChance then
					e.pick = nil
					return
				elseif e.list.count == 1 then
					e.pick = e.list.list[1].object
					return
				end
			end

			if e.list.count > 1 then
				local maxLevel = 0
				for _,v in pairs(e.list.list) do
					if v.levelRequired > maxLevel and v.levelRequired <= tes3.player.object.level  then
						maxLevel = v.levelRequired
					end
				end

				local leveledItemTable = { }
				local maxValue = 0
				local minValue = math.huge
				local valueTemp = 0
				local tableIndex = 1

				for _,v in pairs(e.list.list) do
					if v.levelRequired == maxLevel or (v.levelRequired < tes3.player.object.level and e.list.calculateFromAllLevels) then

						if v.object.value then
							valueTemp = v.object.value
						else
							valueTemp = 0	-- Avoids failures when encountering an item without a value
						end

						leveledItemTable[tableIndex] = { item = v.object, value = valueTemp, probability = nil }
						tableIndex = tableIndex + 1
						
						if valueTemp > maxValue then
							maxValue = valueTemp
						end

						if valueTemp < minValue then
							minValue = valueTemp
						end
					end
				end

				local itemCount = #leveledItemTable
				if maxValue ~= minValue then				-- If all items in the list have the same value, then math.remap would have problems and the probabilities should have the vanilla distribution anyways
					local effectFactor = 2					-- Increases or decreases the strength of the effect

					local evenChance = 1 / itemCount
					local probabilitySum = 0
					local numerator = effectFactor * evenChance * effectiveMagnitude
					local offset = evenChance * (1 - effectiveMagnitude / 2)
					for _,v in ipairs(leveledItemTable) do
						v.value = math.remap(v.value, minValue, maxValue, 0, 1)
						v.probability = (numerator / (1 + math.pow(2.7182818284, (-8 * v.value) + 4))) + offset	-- Sigmoid function that yields vanilla's unweighted probability distribution when effectiveMagnitude = 0;
						probabilitySum = probabilitySum + v.probability
					end

					local selection = math.random() * probabilitySum	-- Effectively normalizes the sum of the weighted probabilities
					for _,v in ipairs(leveledItemTable) do
						selection = selection - v.probability
						if selection < 0 then
							e.pick = v.item
							return
						end
					end
				else
					e.pick = leveledItemTable[math.random(itemCount)].item	-- Vanilla selection; it still needs to be done in this function if maxValue == minValue to account for the different chanceForNothing
				end
			end
		end
	end
end

---@param e magicEffectRemovedEventData
function this.wabbajackTransRemovedEffect(e)
	if e.effect.id == tes3.effect.T_alteration_WabbajackTrans then
		local target = e.target
		for ref in tes3.getCell({ id = "T_Wabbajack" }):iterateReferences({ tes3.objectType.npc, tes3.objectType.creature }) do		-- It appears as though this can cause a crash when the effect is removed from multiple actors at once, as references are being removed from the cell while being iterated through. A crash also occurs with tes3.getReference though.
			if target.data.tamrielData.wabbajack.targetID == ref.id then
				local transformedHealth = target.mobile.health.normalized
				local transformedFatigue = target.mobile.fatigue.normalized
				local transformedMagicka = target.mobile.magicka.normalized

				local vfx = tes3.createVisualEffect({ object = "T_VFX_Wabbajack", lifespan = 1.5, reference = ref })
				tes3.playSound{ sound = "alteration hit", reference = ref }

				tes3.positionCell({ reference = ref, position = target.position, orientation = target.orientation, cell = target.cell })
				
				if target.mobile.isDead or target.mobile.health.current <= 1 then
					tes3.decrementKillCount({ actor = target.baseObject })
					ref.mobile:kill()
					if target.baseObject.faction then tes3.triggerCrime({ type = tes3.crimeType.killing, victim = ref.baseObject.faction }) end	-- Ensures that the player will be expelled for killing a faction member
					tes3.triggerCrime({ type = tes3.crimeType.killing, victim = ref.baseObject })
					tes3.incrementKillCount({ actor = ref.baseObject })
				else
					ref.mobile.health.current = ref.mobile.health.base * transformedHealth
					ref.mobile.fatigue.current = ref.mobile.fatigue.base * transformedFatigue
					ref.mobile.magicka.current = ref.mobile.magicka.base * transformedMagicka
				end

				ref.data.tamrielData.wabbajacked = false
				target:disable()	-- I would move the target to another cell, but that causes Morrowind to lock up, but disabling them after the rest of the function runs seems to work fine though

				return
			end
		end
	end
end

---@param e tes3magicEffectTickEventData
local function wabbajackTransEffect(e)
	if (not e:trigger()) then
		return
	end

	e.sourceInstance.sourceEffects[e.effectIndex + 1].duration = e.effectInstance.target.data.tamrielData.wabbajack.duration
end

---@param e tes3magicEffectTickEventData
local function wabbajackEffect(e)
	if (not e:trigger()) then
		return
	end

	local target = e.effectInstance.target
	if target.isDead or (target.data.tamrielData and target.data.tamrielData.wabbajacked) or (target.mobile.actorType == tes3.actorType.creature and not target.baseObject.walks and not target.baseObject.biped) then
		e.effectInstance.state = tes3.spellState.retired
		return
	end
	
	if target.object.level < 30 then
		if not target.data.tamrielData or not target.data.tamrielData.wabbajack then
			target.data.tamrielData = target.data.tamrielData or {}
			target.data.tamrielData.wabbajacked = true	-- Prevents this from running twice with the retirement condition above

			local maxDuration = 16
			local minDuration = 4
	
			local effectiveLevel = 0
			if target.object.level > 5 then
				effectiveLevel = target.object.level - 5	-- The effect lasts for maxDuration for creatures of level 5 and below
			end
			
			local duration = maxDuration - ((maxDuration - minDuration) * (effectiveLevel / 24))
	
			local targetHealth = target.mobile.health.normalized
			local targetFatigue = target.mobile.fatigue.normalized
			local targetMagicka = target.mobile.magicka.normalized
			
			local transformCreature = tes3.getObject(wabbajackCreatures[math.random(#wabbajackCreatures)])
	
			local transformedTarget = tes3.createReference({ object = transformCreature, position = target.position, orientation = target.orientation, cell = target.cell })	-- Could this setup and the WabbajackTrans effect actually be done through a summon like the Corruption effect does?
			transformedTarget.data.tamrielData = transformedTarget.data.tamrielData or {}
			transformedTarget.data.tamrielData.wabbajack = {}
			transformedTarget.data.tamrielData.wabbajack.duration = duration
			transformedTarget.data.tamrielData.wabbajack.targetID = target.id
			transformedTarget.data.tamrielData.wabbajack.targetName = target.object.name
			transformedTarget.mobile.fight = 0	-- Without this guards will fight transformed NPCs
	
			local vfx = tes3.createVisualEffect({ object = "T_VFX_Wabbajack", lifespan = 1.5, reference = transformedTarget })
			tes3.playSound{ sound = "alteration hit", reference = transformedTarget }
	
			tes3.cast({ reference = e.sourceInstance.caster, spell = "T_Dae_Alt_UNI_WabbajackTrans", alwaysSucceeds = true, bypassResistances = true, instant = true, target = transformedTarget })
			tes3.positionCell({ reference = target, position = { 0, 0, -53.187 }, cell = "T_Wabbajack" })	-- All sorts of problems can arise from disabling a target within the effect event
	
			local transformedHealth = transformedTarget.mobile.health.base * targetHealth
			if transformedHealth <= 1 then transformedHealth = 2 end 	-- Ensures that an actor with low base health won't die if the target had a high base health and was badly wounded
			transformedTarget.mobile.health.current = transformedHealth
			transformedTarget.mobile.fatigue.current = transformedTarget.mobile.fatigue.base * targetFatigue
			transformedTarget.mobile.magicka.current = transformedTarget.mobile.magicka.base * targetMagicka
	
			transformedTarget.mobile:startCombat(e.sourceInstance.caster.mobile)
			e.sourceInstance.caster.mobile:startCombat(transformedTarget.mobile)	-- Is this actually needed?
		else
			tes3.playSound{ sound = "Spell Failure Alteration", reference = target }
			if target.data.tamrielData and target.data.tamrielData.wabbajack and target.data.tamrielData.wabbajack.targetName then tes3ui.showNotifyMenu(common.i18n("magic.wabbajackAlready", { target.data.tamrielData.wabbajack.targetName })) end
		end
	else
		tes3.playSound{ sound = "Spell Failure Alteration", reference = target }
		tes3ui.showNotifyMenu(common.i18n("magic.wabbajackFailure", { target.object.name }))
	end

	e.effectInstance.state = tes3.spellState.retired
end

---@param e spellResistEventData
function this.radiantShieldSpellResistEffect(e)
	local radiantShieldEffects
	if e.target.mobile then radiantShieldEffects = e.target.mobile:getActiveMagicEffects({ effect = tes3.effect.T_alteration_RadShield }) end	-- Sometimes e.target.mobile just doesn't exist
		
	-- Only resist hostile effects; 'not e.effect' is checked because the documentation says that e.effect "may not always be available" and I'd rather resist the odd positive effects than not resist harmful ones
	if radiantShieldEffects and #radiantShieldEffects > 0 and (not e.effect or e.effect.object.isHarmful) then
		for _,v in pairs(radiantShieldEffects) do
			e.resistedPercent = e.resistedPercent + v.magnitude
		end
		
		if e.resistedPercent > 100 then
			e.resistedPercent = 100		-- Prevents anomalous behavior from occuring when above 100%
		end
	end
end

---@param e damagedEventData
function this.radiantShieldDamagedEffect(e)
	if e.attacker and e.source == tes3.damageSource.attack and not e.projectile then
		local radiantShieldEffects = e.mobile:getActiveMagicEffects({ effect = tes3.effect.T_alteration_RadShield })
		if #radiantShieldEffects > 0 then
			local totalMagnitude = 0
			for _,v in pairs(radiantShieldEffects) do
				totalMagnitude = totalMagnitude + v.magnitude
			end
			
			tes3.applyMagicSource({ reference = e.attacker, name = "Radiant Shield", effects = {{ id = tes3.effect.blind, duration = 1.5, min = totalMagnitude, max = totalMagnitude }} })
		end
	end
end

---@param e magicEffectRemovedEventData
function this.radiantShieldRemovedEffect(e)
	if e.effect.id == tes3.effect.T_alteration_RadShield then
		e.mobile.shield = e.mobile.shield - e.effectInstance.magnitude
		e.effectInstance.cumulativeMagnitude = 0	-- The event *might* trigger when it shouldn't, so this ensures that the effect can be reapplied if that actually happens
	end
end

---@param e spellTickEventData
function this.radiantShieldAppliedEffect(e)
	if e.effectId == tes3.effect.T_alteration_RadShield then
		if e.effectInstance.cumulativeMagnitude ~= -1 and e.effectInstance.magnitude > 0 then	-- Just checking whether no time has passed since the effect began doesn't work, since the magnitude isn't actually calculated until after the first tick
			e.target.mobile.shield = e.target.mobile.shield + e.effectInstance.magnitude
			e.effectInstance.cumulativeMagnitude = -1	-- cumulativeMagnitude doesn't (shouldn't) do anything for custom effects, so here it is used to track whether the effect has been applied to the target's shield value
		end
	end
end

---@param cellTable table
---@param markerID string
function this.replaceInterventionMarkers(cellTable, markerID)
	for _,v in pairs(cellTable) do
		local xCoord, yCoord = unpack(v)
		local cell = tes3.getCell({ x = xCoord, y = yCoord })

		local vanillaMarker = nil
		for ref in cell:iterateReferences(tes3.objectType.static) do
			if ref.id == markerID then
				break
			elseif ref.id == "DivineMarker" then
				vanillaMarker = ref
			end
		end

		if vanillaMarker then
			tes3.createReference({ object = markerID, position = vanillaMarker.position, orientation = vanillaMarker.orientation })
			vanillaMarker:delete()
		end
	end
end

---@param e tes3magicEffectTickEventData
local function kynesInterventionEffect(e)
	if (not e:trigger()) then
		return
	end

	if not tes3.worldController.flagTeleportingDisabled then
		local caster = e.sourceInstance.caster
		local marker = tes3.findClosestExteriorReferenceOfObject({ object = "T_Aid_KyneInterventionMarker" })
		if marker then
			tes3.positionCell({ reference = caster, position = marker.position, orientation = marker.orientation, teleportCompanions = false })
		end
	else
		tes3ui.showNotifyMenu(tes3.findGMST(tes3.gmst.sTeleportDisabled).value)
	end

	e.effectInstance.state = tes3.spellState.retired
end

---@param e damagedEventData
function this.reflectDamageStun(e)
	if e.source == tes3.damageSource.attack and e.attacker then
		local reflectDamageEffects = e.mobile:getActiveMagicEffects({ effect = tes3.effect.T_mysticism_ReflectDmg })
		if #reflectDamageEffects > 0 then
			local magnitude = 1
			for _,v in pairs(reflectDamageEffects) do
				magnitude = magnitude * (1 - (v.magnitude / 100))
			end
			magnitude = 1 - magnitude
			local defenderStunned = e.mobile.isHitStunned or e.mobile.isKnockedDown

			if math.random() < magnitude then		-- Chance of preventing a hit stun or knockdown increases with the strength of the reflect damage effect(s)
				e.mobile:hitStun{ cancel = true }
				if defenderStunned then
					e.attacker:hitStun()
				end
			end
		end
	end
end

---@param reflectDamageEffects tes3activeMagicEffect[]
---@param damage number
---@return number, number
local function reflectDamageCalculate(reflectDamageEffects, damage)
	local percentMagnitude
	local reflectedDamage = 0
	for _,v in pairs(reflectDamageEffects) do -- This effect is multiplicative like Morrowind's reflect rather than additive like Oblivion's reflect damage
		percentMagnitude = v.magnitude / 100
		reflectedDamage = reflectedDamage + (damage * percentMagnitude)
		damage = damage * (1 - percentMagnitude)
	end

	if damage < 0 then
		damage = 0		-- Make sure that the effect can't heal the defender
	end

	return damage, reflectedDamage
end

---@param e damageEventData
function this.reflectDamageEffect(e)
	if e.attacker and e.source == tes3.damageSource.attack and e.damage > 0 then
		local reflectDamageEffects = e.mobile:getActiveMagicEffects({ effect = tes3.effect.T_mysticism_ReflectDmg })
		if #reflectDamageEffects > 0 then
			local damage, reflectedDamage = reflectDamageCalculate(reflectDamageEffects, e.damage)
			e.attacker:applyDamage({ damage = reflectedDamage, playerAttack = true })
			e.damage = damage
		end
	end
end

---@param e damageHandToHandEventData
function this.reflectDamageHHEffect(e)
	if e.attacker and e.source == tes3.damageSource.attack and e.fatigueDamage > 0 then
		local reflectDamageEffects = e.mobile:getActiveMagicEffects({ effect = tes3.effect.T_mysticism_ReflectDmg })
		if #reflectDamageEffects > 0 then
			local damage, reflectedDamage = reflectDamageCalculate(reflectDamageEffects, e.fatigueDamage)
			e.attacker:applyFatigueDamage(reflectedDamage, 0, false)
			e.fatigueDamage = damage
		end
	end
end

---@param e cellChangedEventData
function this.banishDaedraCleanup(e)
	if e.previousCell then
		local banished = false
		for ref in tes3.getCell({ id = "T_BanishTemp" }):iterateReferences(tes3.objectType.creature) do
			banished = true
			tes3.positionCell({ reference = ref, position = { 0, 0, 0 }, cell = "T_Banish" })	-- Move to another cell so that only recent banishments have to be iterated over every time that the cell is changed
			ref:disable()
		end

		if banished then	-- Only iterate through the statics if a daedra was actually banished
			for ref in e.previousCell:iterateReferences(tes3.objectType.static) do
				if ref.baseObject.id == "T_VFX_Empty" then ref:delete() end	-- Remove every trace of the effect
			end
		end
	end
end

---@param e containerClosedEventData
function this.deleteBanishDaedraContainer(e)
	if e.reference.baseObject.id == "T_Glb_BanishDae_Empty" and #e.reference.object.inventory == 0 then	-- isEmpty does not work here
		for light in e.reference.cell:iterateReferences(tes3.objectType.light) do
			if light.position.x == e.reference.position.x and light.position.y == e.reference.position.y and light.position.z == e.reference.position.z and light.baseObject.id == "T_Glb_BanishDae_Light" then
				light:delete()
				break
			end
		end

		e.reference:delete()
	end
end

---@param e tes3magicEffectTickEventData
local function banishDaedraEffect(e)
	if (not e:trigger()) then
		return
	end
	
	local target = e.effectInstance.target

	if target.object.type ~= tes3.creatureType.daedra or target.isDead or table.contains(target.mobile.friendlyActors, e.sourceInstance.caster.mobile) or (target.data.tamrielData and target.data.tamrielData.wabbajack) then
		e.effectInstance.state = tes3.spellState.retired
		return
	end

	local magnitude = e.effectInstance.effectiveMagnitude
	local targetLevel = target.object.level
	local caster = e.sourceInstance.caster
	local uniqueItems = {}
	
	if magnitude >= (targetLevel / 2) + ((targetLevel / 2) * target.mobile.health.normalized) then
		for _,v in pairs(target.baseObject.inventory.items) do
			if v.object.objectType ~= tes3.objectType.leveledItem then
				if v.object.id ~= "ingred_daedras_heart_01" and v.object.id ~= "ingred_daedra_skin_01" and v.object.id ~= "ingred_scamp_skin_01" and v.object.id ~= "T_IngCrea_DridreaSilk_01" and v.object.id ~= "T_IngCrea_PrismaticDust_01" then	-- Sometimes ingredients are added without being part of a list, so here they are
					table.insert(uniqueItems, v.object)
				end
			end
		end

		--target.mobile:startCombat(caster.mobile)
		--target.mobile:kill()
		target:setActionFlag(tes3.actionFlag.onDeath)
		tes3.incrementKillCount({ actor = target.object })
		local soundSource = tes3.createReference({ object = "T_VFX_Empty", position = target.position + tes3vector3.new(0, 0, target.mobile.height/2) , orientation = target.orientation, cell = target.cell })
		tes3.playSound{ sound = "mysticism hit", reference = soundSource }
		local vfx = tes3.createVisualEffect({ object = "T_VFX_Banish", lifespan = 1.5, position = target.position })
		
		local targetHandle = tes3.makeSafeObjectHandle(target)
		timer.delayOneFrame(function()
			timer.delayOneFrame(function()		-- Give MWScripts using onDeath time to run
				if not targetHandle or not targetHandle:valid() then
					return
				end

				local target = targetHandle:getObject()

				if #uniqueItems > 0 then	-- Don't bother if there is definitely not going to be loot
					local container = tes3.createReference({ object = "T_Glb_BanishDae_Empty", position = target.position + tes3vector3.new(0, 0, target.mobile.height) , orientation = target.orientation, cell = target.cell })
					for _,v in pairs(target.mobile.inventory) do
						if table.contains(uniqueItems, v.object) then
							tes3.transferItem({ from = target, to = container, item = v.object, count = 999, limitCapacity = false })	-- This setup can account for how Dregas Volar's items are given to the player, so that they don't end up with two of both
						end
					end

					if #container.object.inventory == 0 then	-- Just in case
						container:delete()
					else
						tes3.createReference({ object = "T_Glb_BanishDae_Light", position = target.position + tes3vector3.new(0, 0, target.mobile.height) , orientation = target.orientation, cell = target.cell })
					end
				end

				tes3.positionCell({ reference = target, position = { 0, 0, 0 }, cell = "T_BanishTemp" })	-- This has to be put after the item transfers for them to work, rather than before the delays where it really belongs
			end)
		end)
	else
		target.mobile:startCombat(caster.mobile)
		tes3ui.showNotifyMenu(common.i18n("magic.banishFailure", { target.object.name }))
	end

	e.effectInstance.state = tes3.spellState.retired
end

---@param door tes3reference
---@return boolean
local function passWallDoorCrime(door)
	local owner, requirement = tes3.getOwner({ reference = door })

	if owner then
		if owner.objectType == tes3.objectType.npc then
			if requirement and requirement.value ~= 0 then return false end
		elseif owner.objectType == tes3.objectType.faction then
			if owner.playerRank >= requirement then	return false end -- I guess that the game doesn't check whether the player is expelledend
		end

		return true
	end

	return false
end

---@param wallPosition tes3vector3
---@param forward tes3vector3
---@param right tes3vector3
---@param up tes3vector3
---@param range number
---@return tes3vector3, number
local function passwallCalculate(wallPosition, forward, right, up, range)
	local nodeArr = tes3.mobilePlayer.cell.pathGrid.nodes
	local playerPosition = tes3.mobilePlayer.position

	local minDistance = 108
	local forwardOffset = 0
	local rayTestOffset = 19

	local rightCoord = (right * 200)
	local upCoord = (up * 105)			-- Should this account for player height, which affects castPosition and wallPosition?

	local startPosition = wallPosition + (forward * forwardOffset)
	local endPosition = wallPosition + (forward * (range + forwardOffset))

	local point1 = startPosition - rightCoord - upCoord
	local point2 = endPosition + rightCoord + upCoord

	local bestDistance = range
	local bestPosition = nil

	for _,node in pairs(nodeArr) do
		if (point1.x <= node.position.x and node.position.x <= point2.x) or (point1.x >= node.position.x and node.position.x >= point2.x) then
			if (point1.y <= node.position.y and node.position.y <= point2.y) or (point1.y >= node.position.y and node.position.y >= point2.y) then
				if (point1.z <= node.position.z and node.position.z <= point2.z) or (point1.z >= node.position.z and node.position.z >= point2.z) then
					local distance = startPosition:distance(node.position)
					if distance <= bestDistance and playerPosition:distance(node.position) >= minDistance then
						local targetY = tes3.rayTest{
							position = node.position - (forward * rayTestOffset) + tes3vector3.new(0, 0, 0.5 * tes3.mobilePlayer.height),
							direction = forward,
							maxDistance = rayTestOffset * 2,
							--root = {tes3.game.sceneGraphCollideString},
							useBackTriangles = true,
						}
						local targetX = tes3.rayTest{
							position = node.position - (right * rayTestOffset) + tes3vector3.new(0, 0, 0.5 * tes3.mobilePlayer.height),
							direction = right,
							maxDistance = rayTestOffset * 2,
							--root = {tes3.game.sceneGraphCollideString},
							useBackTriangles = true,
						}
						
						if not targetY and not targetX then
							bestDistance = distance
							bestPosition = node.position
						end
					end
				end
			end
		end
	end

	local checkedNodeTable = { }
	for _,node in pairs(nodeArr) do
		for _,connectedNode in pairs(node.connectedNodes) do
			if not table.contains(checkedNodeTable, node) and not table.contains(checkedNodeTable, connectedNode) then			-- Only check each connection once
				if (startPosition:distance(node.position) <= 1024 and startPosition:distance(connectedNode.position) <= 1024) or (endPosition:distance(node.position) <= 1024 and endPosition:distance(connectedNode.position) <= 1024) then	-- Reasonable limit on how far nodes can be
					local increment = (connectedNode.position - node.position) / 15
					local connectionLength = connectedNode.position:distance(node.position)
					local incrementLength = connectionLength / 15

					local prevStartDistance = nil
					local prevEndDistance = nil

					local prevInVolume = false		-- Given that raytests are used to check for collision near the tested positions, the closest acceptable position might actually be further away, so positions should keep being checked until they are outside of the volume entirely
					
					for i=1,14,1 do
						local incrementPosition = node.position + (increment * i)
						local startDistance = incrementPosition:distance(startPosition)
						local endDistance = incrementPosition:distance(endPosition)

						if prevStartDistance and prevEndDistance and not prevInVolume and (startDistance > prevStartDistance and endDistance > prevEndDistance) or ((connectionLength - (incrementLength * i)) < startDistance and (connectionLength - (incrementLength * i)) < endDistance) then
							break		-- If incrementPosition is moving away or too far from the volume that the player can teleport within and was not inside of it then the loop will be broken out of for the sake of performance
						end

						prevInVolume = false

						if startDistance <= bestDistance and playerPosition:distance(incrementPosition) >= minDistance then
							if (point1.x <= incrementPosition.x and incrementPosition.x <= point2.x) or (point1.x >= incrementPosition.x and incrementPosition.x >= point2.x) then
								if (point1.y <= incrementPosition.y and incrementPosition.y <= point2.y) or (point1.y >= incrementPosition.y and incrementPosition.y >= point2.y) then
									if (point1.z <= incrementPosition.z and incrementPosition.z <= point2.z) or (point1.z >= incrementPosition.z and incrementPosition.z >= point2.z) then
										prevInVolume = true
										
										local targetY = tes3.rayTest{
											position = incrementPosition - (forward * rayTestOffset) + tes3vector3.new(0, 0, 0.5 * tes3.mobilePlayer.height),
											direction = forward,
											maxDistance = rayTestOffset * 2,
											--root = {tes3.game.sceneGraphCollideString},	-- Does not actually have collision meshes; replace with object and pick roots?
											useBackTriangles = true,
										}
										local targetX = tes3.rayTest{
											position = node.position - (right * rayTestOffset) + tes3vector3.new(0, 0, 0.5 * tes3.mobilePlayer.height),
											direction = right,
											maxDistance = rayTestOffset * 2,
											--root = {tes3.game.sceneGraphCollideString},
											useBackTriangles = true,
										}
										
										if not targetY and not targetX then
											bestDistance = startDistance
											bestPosition = incrementPosition
										end
									end
								end
							end
						end
						
						prevStartDistance = startDistance
						prevEndDistance = endDistance
					end
				end
			end
		end

		table.insert(checkedNodeTable, node)
	end

	return bestPosition, bestDistance
end

---@param e magicCastedEventData
function this.passwallEffect(e)
	for _,v in pairs(e.source.effects) do
		if v.id == tes3.effect.T_mysticism_Passwall then

			if tes3.mobilePlayer.cell.isOrBehavesAsExterior or not tes3.mobilePlayer.cell.pathGrid then
				tes3ui.showNotifyMenu(common.i18n("magic.passwallExterior"))
				return
			end

			if tes3.mobilePlayer.underwater then
				tes3ui.showNotifyMenu(common.i18n("magic.passwallUnderwater"))
				return
			end

			if tes3.worldController.flagTeleportingDisabled or tes3.worldController.flagLevitationDisabled then
				tes3ui.showNotifyMenu(common.i18n("magic.passwallDisabled"))
				return
			end

			local alphaDistance = math.huge
			local wardDistance = math.huge

			local castPosition = tes3.mobilePlayer.position + tes3vector3.new(0, 0, 0.7 * tes3.mobilePlayer.height)	-- Position of where spells are casted
			local forward = (tes3.worldController.armCamera.cameraData.camera.worldDirection * tes3vector3.new(1, 1, 0)):normalized()
			local right = tes3.worldController.armCamera.cameraData.camera.worldRight:normalized()
			local up = tes3vector3.new(0, 0, 1)

			local range = v.radius * 22.1

			local hitSound = "mysticism hit"
			local hitVFX = "VFX_MysticismHit"
			if passwallAlteration then
				hitSound = "alteration hit"
				hitVFX = "VFX_AlterationHit"
			end

			local checkMeshes = tes3.rayTest{
				position = castPosition,
				direction = forward,
				findAll = true,
				maxDistance = 196 + range,
				ignore = { tes3.player },
				observeAppCullFlag  = false,
			}

			if checkMeshes then		-- This block of code looks through all of the objects that the effect can hit and finds the closest one that is a ward or has some transparency
				for _,detection in ipairs(checkMeshes) do
					if detection.reference then
						if detection.reference.baseObject.id:find("T_Aid_PasswallWard_") then	-- I considered changing reducing the distance if such an object is found, but just saving the object's distance allows for determining whether or not it is responsible for the effect failing
							wardDistance = detection.distance
							break
						else
							local type = detection.reference.baseObject.objectType
							if type == tes3.objectType.activator and common.hasAlpha(tes3.loadMesh(detection.reference.baseObject.mesh), false, true) then	-- This mesh is passed rather than the rayTest's object because the latter is part of 
								alphaDistance = detection.distance
								break
							end
						end
					end
				end
			end

			if alphaDistance <= 160 then	-- These conditions should handle casting the effect on or near an unacceptable object
				tes3ui.showNotifyMenu(common.i18n("magic.passwallAlpha"))
				return
			elseif wardDistance <= 160 then
				tes3ui.showNotifyMenu(common.i18n("magic.passwallWard"))
				return
			end

			local target = tes3.rayTest{
				position = castPosition,
				direction = forward,
				maxDistance = 196,		-- The normal activation range
				ignore = { tes3.player },
			}

			local hitReference, wallPosition = target and target.reference, target and target.intersection

			if hitReference then
				if hitReference.baseObject.objectType == tes3.objectType.static or hitReference.baseObject.objectType == tes3.objectType.activator then
					if hitReference.baseObject.boundingBox.max:heightDifference(hitReference.baseObject.boundingBox.min) >= 172 then		-- Check how tall the targeted object is; this is Passwall, not Passtable
						local bestPosition, bestDistance = passwallCalculate(wallPosition + (forward * 16) - (up * 48), forward, right, up, range)		-- (forward * 16) is used to hopefully prevent teleporting inside the target; (up * 64) is used to make the effect work better with stairways down that are right behind doors and to limit the player's ability to teleport up stairs

						if bestPosition then
							if bestDistance >= alphaDistance then	-- These conditions will notify the player if the closest node was through or inside an unacceptable mesh
								tes3ui.showNotifyMenu(common.i18n("magic.passwallAlpha"))
								return
							elseif bestDistance >= wardDistance then
								tes3ui.showNotifyMenu(common.i18n("magic.passwallWard"))
								return
							end

							tes3.playSound{ sound = hitSound, reference = tes3.mobilePlayer }		-- Since there isn't a target in the normal sense, the sound won't play without this
							local vfx = tes3.createVisualEffect({ object = hitVFX, lifespan = 2, avObject = tes3.player.sceneNode })
							tes3.mobilePlayer.position = bestPosition
						end
					end
				elseif hitReference.baseObject.objectType == tes3.objectType.door and (hitReference.baseObject.name:lower():find("door") or hitReference.baseObject.name:lower():find("wooden gate") or hitReference.baseObject.name:lower():find("palace gates") or
						hitReference.baseObject.name:lower():find("stone gate") or hitReference.baseObject.name:lower():find("old iron gate")) and
						not (hitReference.baseObject.name:lower():find("trap") or hitReference.baseObject.name:lower():find("cell") or hitReference.baseObject.name:lower():find("tent")) then
					if not hitReference.destination then
						local bestPosition, bestDistance = passwallCalculate(wallPosition + (forward * 16) - (up * 48), forward, right, up, range)
						if bestPosition then
							if bestDistance >= alphaDistance then
								tes3ui.showNotifyMenu(common.i18n("magic.passwallAlpha"))
								return
							elseif bestDistance >= wardDistance then
								tes3ui.showNotifyMenu(common.i18n("magic.passwallWard"))
								return
							end

							if passWallDoorCrime(hitReference) then tes3.triggerCrime({ type = tes3.crimeType.trespass }) end
							tes3.playSound{ sound = hitSound, reference = tes3.mobilePlayer }
							local vfx = tes3.createVisualEffect({ object = hitVFX, lifespan = 2, avObject = tes3.player.sceneNode })
							tes3.mobilePlayer.position = bestPosition
						end
					elseif hitReference.destination and hitReference.destination.cell.isInterior then
						if hitReference.baseObject.script then
							tes3ui.showNotifyMenu(common.i18n("magic.passwallAlpha"))
							return
						end

						if passWallDoorCrime(hitReference) then tes3.triggerCrime({ type = tes3.crimeType.trespass }) end
						tes3.playSound{ sound = hitSound, reference = tes3.mobilePlayer }
						local vfx = tes3.createVisualEffect({ object = hitVFX, lifespan = 2, avObject = tes3.player.sceneNode })
						tes3.positionCell({ cell = hitReference.destination.cell, position = hitReference.destination.marker.position, orientation = hitReference.destination.marker.orientation, teleportCompanions = false })
					else
						tes3ui.showNotifyMenu(common.i18n("magic.passwallDoorExterior"))
					end
				end
			end
		end
	end
end

-- Adds new magic effects based on the tables above
event.register(tes3.event.magicEffectsResolved, function()
	if config.summoningSpells == true then
		local summonHungerEffect = tes3.getMagicEffect(tes3.effect.summonHunger)

		for _,v in pairs(td_summon_effects) do
			local effectID, effectName, creatureID, effectCost, iconPath, effectDescription = unpack(v)
			tes3.addMagicEffect{
				id = effectID,
				name = effectName,
				description = effectDescription,
				school = tes3.magicSchool.conjuration,
				baseCost = effectCost,
				speed = summonHungerEffect.speed,
				allowEnchanting = true,
				allowSpellmaking = true,
				appliesOnce = summonHungerEffect.appliesOnce,
				canCastSelf = true,
				canCastTarget = false,
				canCastTouch = false,
				casterLinked = summonHungerEffect.casterLinked,
				hasContinuousVFX = summonHungerEffect.hasContinuousVFX,
				hasNoDuration = summonHungerEffect.hasNoDuration,
				hasNoMagnitude = summonHungerEffect.hasNoMagnitude,
				illegalDaedra = summonHungerEffect.illegalDaedra,
				isHarmful = summonHungerEffect.isHarmful,
				nonRecastable = summonHungerEffect.nonRecastable,
				targetsAttributes = summonHungerEffect.targetsAttributes,
				targetsSkills = summonHungerEffect.targetsSkills,
				unreflectable = summonHungerEffect.unreflectable,
				usesNegativeLighting = summonHungerEffect.usesNegativeLighting,
				icon = iconPath,
				particleTexture = summonHungerEffect.particleTexture,
				castSound = summonHungerEffect.castSoundEffect.id,
				castVFX = summonHungerEffect.castVisualEffect.id,
				boltSound = summonHungerEffect.boltSoundEffect.id,
				boltVFX = summonHungerEffect.boltVisualEffect.id,
				hitSound = summonHungerEffect.hitSoundEffect.id,
				hitVFX = summonHungerEffect.hitVisualEffect.id,
				areaSound = summonHungerEffect.areaSoundEffect.id,
				areaVFX = summonHungerEffect.areaVisualEffect.id,
				lighting = {x = summonHungerEffect.lightingRed / 255, y = summonHungerEffect.lightingGreen / 255, z = summonHungerEffect.lightingBlue / 255},
				size = summonHungerEffect.size,
				sizeCap = summonHungerEffect.sizeCap,
				onTick = function(eventData)
					eventData:triggerSummon(creatureID)
				end,
				onCollision = nil
			}
		end
	end
	
	if config.boundSpells == true then
		local boundCuirassEffect = tes3.getMagicEffect(tes3.effect.boundBoots)

		for _,v in pairs(td_bound_effects) do
			local effectID, effectName, itemID, itemID_02, effectCost, iconPath, effectDescription = unpack(v)
			tes3.addMagicEffect{
				id = effectID,
				name = effectName,
				description = effectDescription,
				school = tes3.magicSchool.conjuration,
				baseCost = effectCost,
				speed = boundCuirassEffect.speed,
				allowEnchanting = true,
				allowSpellmaking = true,
				appliesOnce = boundCuirassEffect.appliesOnce,
				canCastSelf = true,
				canCastTarget = false,
				canCastTouch = false,
				casterLinked = boundCuirassEffect.casterLinked,
				hasContinuousVFX = boundCuirassEffect.hasContinuousVFX,
				hasNoDuration = boundCuirassEffect.hasNoDuration,
				hasNoMagnitude = boundCuirassEffect.hasNoMagnitude,
				illegalDaedra = boundCuirassEffect.illegalDaedra,
				isHarmful = boundCuirassEffect.isHarmful,
				nonRecastable = boundCuirassEffect.nonRecastable,
				targetsAttributes = boundCuirassEffect.targetsAttributes,
				targetsSkills = boundCuirassEffect.targetsSkills,
				unreflectable = boundCuirassEffect.unreflectable,
				usesNegativeLighting = boundCuirassEffect.usesNegativeLighting,
				icon = iconPath,
				particleTexture = boundCuirassEffect.particleTexture,
				castSound = boundCuirassEffect.castSoundEffect.id,
				castVFX = boundCuirassEffect.castVisualEffect.id,
				boltSound = boundCuirassEffect.boltSoundEffect.id,
				boltVFX = boundCuirassEffect.boltVisualEffect.id,
				hitSound = boundCuirassEffect.hitSoundEffect.id,
				hitVFX = boundCuirassEffect.hitVisualEffect.id,
				areaSound = boundCuirassEffect.areaSoundEffect.id,
				areaVFX = boundCuirassEffect.areaVisualEffect.id,
				lighting = {x = boundCuirassEffect.lightingRed / 255, y = boundCuirassEffect.lightingGreen / 255, z = boundCuirassEffect.lightingBlue / 255},
				size = boundCuirassEffect.size,
				sizeCap = boundCuirassEffect.sizeCap,
				onTick = function(eventData)
					if tes3.getObject(itemID).objectType == tes3.objectType.armor then
						if itemID_02 == "" then
							eventData:triggerBoundArmor(itemID)
						else
							eventData:triggerBoundArmor(itemID, itemID_02)
						end
					elseif tes3.getObject(itemID).objectType == tes3.objectType.weapon then
						eventData:triggerBoundWeapon(itemID)
					end
				end,
				onCollision = nil
			}
		end
	end
	
	if config.interventionSpells == true then
		local divineInterventionEffect = tes3.getMagicEffect(tes3.effect.divineIntervention)

		local effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_intervention_effects[1])	-- Kyne's Intervention
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			school = tes3.magicSchool.mysticism,
			baseCost = effectCost,
			speed = divineInterventionEffect.speed,
			allowEnchanting = divineInterventionEffect.allowEnchanting,
			allowSpellmaking = divineInterventionEffect.allowSpellmaking,
			appliesOnce = divineInterventionEffect.appliesOnce,
			canCastSelf = divineInterventionEffect.canCastSelf,
			canCastTarget = divineInterventionEffect.canCastTarget,
			canCastTouch = divineInterventionEffect.canCastTouch,
			casterLinked = divineInterventionEffect.casterLinked,
			hasContinuousVFX = divineInterventionEffect.hasContinuousVFX,
			hasNoDuration = divineInterventionEffect.hasNoDuration,
			hasNoMagnitude = divineInterventionEffect.hasNoMagnitude,
			illegalDaedra = divineInterventionEffect.illegalDaedra,
			isHarmful = divineInterventionEffect.isHarmful,
			nonRecastable = divineInterventionEffect.nonRecastable,
			targetsAttributes = divineInterventionEffect.targetsAttributes,
			targetsSkills = divineInterventionEffect.targetsSkills,
			unreflectable = divineInterventionEffect.unreflectable,
			usesNegativeLighting = divineInterventionEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = divineInterventionEffect.particleTexture,
			castSound = divineInterventionEffect.castSoundEffect.id,
			castVFX = divineInterventionEffect.castVisualEffect.id,
			boltSound = divineInterventionEffect.boltSoundEffect.id,
			boltVFX = divineInterventionEffect.boltVisualEffect.id,
			hitSound = divineInterventionEffect.hitSoundEffect.id,
			hitVFX = divineInterventionEffect.hitVisualEffect.id,
			areaSound = divineInterventionEffect.areaSoundEffect.id,
			areaVFX = divineInterventionEffect.areaVisualEffect.id,
			lighting = {x = divineInterventionEffect.lightingRed / 255, y = divineInterventionEffect.lightingGreen / 255, z = divineInterventionEffect.lightingBlue / 255},
			size = divineInterventionEffect.size,
			sizeCap = divineInterventionEffect.sizeCap,
			onTick = kynesInterventionEffect,
			onCollision = nil
		}
	end
	
	if config.miscSpells == true then
		local passwallBaseEffect = tes3.getMagicEffect(tes3.effect.detectAnimal)
		local passwallSchool = tes3.magicSchool.mysticism

		if passwallAlteration then
			passwallBaseEffect = tes3.getMagicEffect(tes3.effect.levitate)
			passwallSchool = tes3.magicSchool.alteration
		end

		local soultrapEffect = tes3.getMagicEffect(tes3.effect.soultrap)
		local reflectEffect = tes3.getMagicEffect(tes3.effect.reflect)
		local detectEffect = tes3.getMagicEffect(tes3.effect.detectAnimal)
		local shieldEffect = tes3.getMagicEffect(tes3.effect.shield)
		local burdenEffect = tes3.getMagicEffect(tes3.effect.burden)
		local restoreEffect = tes3.getMagicEffect(tes3.effect.fortifyHealth)	-- The fortify VFX feels more appropriate for the resartus effects, but perhaps it should still be restoration?
		local summonDremoraEffect = tes3.getMagicEffect(tes3.effect.summonDremora)
		local blindEffect = tes3.getMagicEffect(tes3.effect.blind)
		local damageHealthEffect = tes3.getMagicEffect(tes3.effect.damageHealth)
		local fortifyAttackEffect = tes3.getMagicEffect(tes3.effect.fortifyAttack)
		local lightEffect = tes3.getMagicEffect(tes3.effect.light)

		local effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[1])	-- Passwall
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			school = passwallSchool,
			baseCost = effectCost,
			speed = passwallBaseEffect.speed,
			allowEnchanting = true,
			allowSpellmaking = true,
			appliesOnce = true,
			canCastSelf = false,
			canCastTarget = false,
			canCastTouch = true,
			casterLinked = passwallBaseEffect.casterLinked,
			hasContinuousVFX = false,
			hasNoDuration = true,
			hasNoMagnitude = true,
			illegalDaedra = false,
			isHarmful = false,
			nonRecastable = true,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = true,
			usesNegativeLighting = passwallBaseEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = passwallBaseEffect.particleTexture,
			castSound = passwallBaseEffect.castSoundEffect.id,
			castVFX = passwallBaseEffect.castVisualEffect.id,
			boltSound = "T_SndObj_Silence",
			boltVFX = "T_VFX_Empty",
			hitSound = "T_SndObj_Silence",
			hitVFX = "T_VFX_Empty",							-- Currently has to use VFX because otherwise Morrowind crashes when casting the effect on some actors despite this parameter being "optional"
			areaSound = "T_SndObj_Silence",
			areaVFX = "T_VFX_Empty",							-- Problems can apparently still arise from missing boltVFX and areaVFX for some people
			lighting = {x = passwallBaseEffect.lightingRed / 255, y = passwallBaseEffect.lightingGreen / 255, z = passwallBaseEffect.lightingBlue / 255},
			size = passwallBaseEffect.size,
			sizeCap = passwallBaseEffect.sizeCap,
			onTick = function(eventData) eventData:trigger() end,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[2])		-- Banish Daedra
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			school = tes3.magicSchool.mysticism,
			baseCost = effectCost,
			speed = soultrapEffect.speed,
			allowEnchanting = true,
			allowSpellmaking = true,
			appliesOnce = true,
			canCastSelf = false,
			canCastTarget = true,
			canCastTouch = true,
			casterLinked = soultrapEffect.casterLinked,
			hasContinuousVFX = soultrapEffect.hasContinuousVFX,
			hasNoDuration = true,
			hasNoMagnitude = false,
			illegalDaedra = soultrapEffect.illegalDaedra,
			isHarmful = false,
			nonRecastable = true,
			targetsAttributes = soultrapEffect.targetsAttributes,
			targetsSkills = soultrapEffect.targetsSkills,
			unreflectable = true,
			usesNegativeLighting = soultrapEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = soultrapEffect.particleTexture,
			castSound = soultrapEffect.castSoundEffect.id,
			castVFX = soultrapEffect.castVisualEffect.id,
			boltSound = soultrapEffect.boltSoundEffect.id,
			boltVFX = soultrapEffect.boltVisualEffect.id,
			hitSound = "T_SndObj_Silence",
			hitVFX = "T_VFX_Empty",
			areaSound = "T_SndObj_Silence",
			areaVFX = "T_VFX_Empty",
			lighting = {x = soultrapEffect.lightingRed / 255, y = soultrapEffect.lightingGreen / 255, z = soultrapEffect.lightingBlue / 255},
			size = soultrapEffect.size,
			sizeCap = soultrapEffect.sizeCap,
			onTick = banishDaedraEffect,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[3])		-- Reflect Damage
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			magnitudeType = tes3.findGMST(tes3.gmst.spercent).value,
			magnitudeTypePlural = tes3.findGMST(tes3.gmst.spercent).value,
			school = tes3.magicSchool.mysticism,
			baseCost = effectCost,
			speed = reflectEffect.speed,
			allowEnchanting = reflectEffect.allowEnchanting,
			allowSpellmaking = reflectEffect.allowSpellmaking,
			appliesOnce = reflectEffect.appliesOnce,
			canCastSelf = reflectEffect.canCastSelf,
			canCastTarget = reflectEffect.canCastTarget,
			canCastTouch = reflectEffect.canCastTouch,
			casterLinked = reflectEffect.casterLinked,
			hasContinuousVFX = reflectEffect.hasContinuousVFX,
			hasNoDuration = reflectEffect.hasNoDuration,
			hasNoMagnitude = reflectEffect.hasNoMagnitude,
			illegalDaedra = reflectEffect.illegalDaedra,
			isHarmful = reflectEffect.isHarmful,
			nonRecastable = reflectEffect.nonRecastable,
			targetsAttributes = reflectEffect.targetsAttributes,
			targetsSkills = reflectEffect.targetsSkills,
			unreflectable = reflectEffect.unreflectable,
			usesNegativeLighting = reflectEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = reflectEffect.particleTexture,
			castSound = reflectEffect.castSoundEffect.id,
			castVFX = reflectEffect.castVisualEffect.id,
			boltSound = reflectEffect.boltSoundEffect.id,
			boltVFX = reflectEffect.boltVisualEffect.id,
			hitSound = reflectEffect.hitSoundEffect.id,
			hitVFX = reflectEffect.hitVisualEffect.id,
			areaSound = reflectEffect.areaSoundEffect.id,
			areaVFX = reflectEffect.areaVisualEffect.id,
			lighting = {x = reflectEffect.lightingRed / 255, y = reflectEffect.lightingGreen / 255, z = reflectEffect.lightingBlue / 255},
			size = reflectEffect.size,
			sizeCap = reflectEffect.sizeCap,
			onTick = nil,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[4])		-- Detect Humanoid
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			magnitudeType = " " .. tes3.findGMST(tes3.gmst.sfeet).value,
			magnitudeTypePlural = " " .. tes3.findGMST(tes3.gmst.sfeet).value,
			school = tes3.magicSchool.mysticism,
			baseCost = effectCost,
			speed = detectEffect.speed,
			allowEnchanting = true,
			allowSpellmaking = true,
			appliesOnce = true,
			canCastSelf = true,
			canCastTarget = false,
			canCastTouch = false,
			casterLinked = detectEffect.casterLinked,
			hasContinuousVFX = detectEffect.hasContinuousVFX,
			hasNoDuration = false,
			hasNoMagnitude = false,
			illegalDaedra = detectEffect.illegalDaedra,
			isHarmful = false,
			nonRecastable = false,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = false,
			usesNegativeLighting = detectEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = detectEffect.particleTexture,
			castSound = detectEffect.castSoundEffect.id,
			castVFX = detectEffect.castVisualEffect.id,
			boltSound = detectEffect.boltSoundEffect.id,
			boltVFX = detectEffect.boltVisualEffect.id,
			hitSound = detectEffect.hitSoundEffect.id,
			hitVFX = detectEffect.hitVisualEffect.id,
			areaSound = detectEffect.areaSoundEffect.id,
			areaVFX = detectEffect.areaVisualEffect.id,
			lighting = {x = detectEffect.lightingRed / 255, y = detectEffect.lightingGreen / 255, z = detectEffect.lightingBlue / 255},
			size = detectEffect.size,
			sizeCap = detectEffect.sizeCap,
			onTick = nil,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[5])		-- Radiant Shield
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			school = tes3.magicSchool.alteration,
			baseCost = effectCost,
			speed = shieldEffect.speed,
			allowEnchanting = shieldEffect.allowEnchanting,
			allowSpellmaking = shieldEffect.allowSpellmaking,
			appliesOnce = shieldEffect.appliesOnce,
			canCastSelf = shieldEffect.canCastSelf,
			canCastTarget = shieldEffect.canCastTarget,
			canCastTouch = shieldEffect.canCastTouch,
			casterLinked = shieldEffect.casterLinked,
			hasContinuousVFX = shieldEffect.hasContinuousVFX,
			hasNoDuration = shieldEffect.hasNoDuration,
			hasNoMagnitude = shieldEffect.hasNoMagnitude,
			illegalDaedra = shieldEffect.illegalDaedra,
			isHarmful = shieldEffect.isHarmful,
			nonRecastable = shieldEffect.nonRecastable,
			targetsAttributes = shieldEffect.targetsAttributes,
			targetsSkills = shieldEffect.targetsSkills,
			unreflectable = shieldEffect.unreflectable,
			usesNegativeLighting = shieldEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = shieldEffect.particleTexture,
			castSound = shieldEffect.castSoundEffect.id,
			castVFX = shieldEffect.castVisualEffect.id,
			boltSound = shieldEffect.boltSoundEffect.id,
			boltVFX = shieldEffect.boltVisualEffect.id,
			hitSound = shieldEffect.hitSoundEffect.id,
			hitVFX = "T_VFX_RadiantShieldHit",
			areaSound = shieldEffect.areaSoundEffect.id,
			areaVFX = shieldEffect.areaVisualEffect.id,
			lighting = {x = 128, y = 128, z = 128},
			size = shieldEffect.size,
			sizeCap = shieldEffect.sizeCap,
			onTick = nil,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[6])		-- Wabbajack
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			school = tes3.magicSchool.alteration,
			baseCost = effectCost,
			speed = burdenEffect.speed,
			allowEnchanting = false,
			allowSpellmaking = false,
			appliesOnce = true,
			canCastSelf = false,
			canCastTarget = true,
			canCastTouch = false,
			casterLinked = burdenEffect.casterLinked,
			hasContinuousVFX = burdenEffect.hasContinuousVFX,
			hasNoDuration = true,
			hasNoMagnitude = true,
			illegalDaedra = burdenEffect.illegalDaedra,
			isHarmful = true,
			nonRecastable = true,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = true,
			usesNegativeLighting = burdenEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = burdenEffect.particleTexture,
			castSound = burdenEffect.castSoundEffect.id,
			castVFX = burdenEffect.castVisualEffect.id,
			boltSound = burdenEffect.boltSoundEffect.id,
			boltVFX = burdenEffect.boltVisualEffect.id,
			hitSound = "T_SndObj_Silence",
			hitVFX = "T_VFX_Empty",
			areaSound = "T_SndObj_Silence",
			areaVFX = "T_VFX_Empty",
			lighting = {x = burdenEffect.lightingRed / 255, y = burdenEffect.lightingGreen / 255, z = burdenEffect.lightingBlue / 255},
			size = burdenEffect.size,
			sizeCap = burdenEffect.sizeCap,
			onTick = wabbajackEffect,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[7])		-- Insight
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			school = tes3.magicSchool.mysticism,
			baseCost = effectCost,
			speed = reflectEffect.speed,
			allowEnchanting = true,
			allowSpellmaking = true,
			appliesOnce = true,
			canCastSelf = true,
			canCastTarget = false,
			canCastTouch = false,
			casterLinked = reflectEffect.casterLinked,
			hasContinuousVFX = reflectEffect.hasContinuousVFX,
			hasNoDuration = false,
			hasNoMagnitude = false,
			illegalDaedra = reflectEffect.illegalDaedra,
			isHarmful = false,
			nonRecastable = false,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = false,
			usesNegativeLighting = reflectEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = reflectEffect.particleTexture,
			castSound = reflectEffect.castSoundEffect.id,
			castVFX = reflectEffect.castVisualEffect.id,
			boltSound = reflectEffect.boltSoundEffect.id,
			boltVFX = reflectEffect.boltVisualEffect.id,
			hitSound = reflectEffect.hitSoundEffect.id,
			hitVFX = reflectEffect.hitVisualEffect.id,
			areaSound = reflectEffect.areaSoundEffect.id,
			areaVFX = reflectEffect.areaVisualEffect.id,
			lighting = {x = reflectEffect.lightingRed / 255, y = reflectEffect.lightingGreen / 255, z = reflectEffect.lightingBlue / 255},
			size = reflectEffect.size,
			sizeCap = reflectEffect.sizeCap,
			onTick = nil,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[8])		-- Armor Resartus
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			school = tes3.magicSchool.restoration,
			baseCost = effectCost,
			speed = restoreEffect.speed,
			allowEnchanting = true,
			allowSpellmaking = true,
			appliesOnce = true,
			canCastSelf = true,
			canCastTarget = false,
			canCastTouch = false,
			casterLinked = restoreEffect.casterLinked,
			hasContinuousVFX = restoreEffect.hasContinuousVFX,
			hasNoDuration = true,
			hasNoMagnitude = false,
			illegalDaedra = restoreEffect.illegalDaedra,
			isHarmful = false,
			nonRecastable = false,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = false,
			usesNegativeLighting = restoreEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = restoreEffect.particleTexture,
			castSound = restoreEffect.castSoundEffect.id,
			castVFX = restoreEffect.castVisualEffect.id,
			boltSound = restoreEffect.boltSoundEffect.id,
			boltVFX = restoreEffect.boltVisualEffect.id,
			hitSound = restoreEffect.hitSoundEffect.id,
			hitVFX = restoreEffect.hitVisualEffect.id,
			areaSound = restoreEffect.areaSoundEffect.id,
			areaVFX = restoreEffect.areaVisualEffect.id,
			lighting = {x = restoreEffect.lightingRed / 255, y = restoreEffect.lightingGreen / 255, z = restoreEffect.lightingBlue / 255},
			size = restoreEffect.size,
			sizeCap = restoreEffect.sizeCap,
			onTick = armorResartusEffect,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[9])		-- Weapon Resartus
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			school = tes3.magicSchool.restoration,
			baseCost = effectCost,
			speed = restoreEffect.speed,
			allowEnchanting = true,
			allowSpellmaking = true,
			appliesOnce = true,
			canCastSelf = true,
			canCastTarget = false,
			canCastTouch = false,
			casterLinked = restoreEffect.casterLinked,
			hasContinuousVFX = restoreEffect.hasContinuousVFX,
			hasNoDuration = true,
			hasNoMagnitude = false,
			illegalDaedra = restoreEffect.illegalDaedra,
			isHarmful = false,
			nonRecastable = false,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = false,
			usesNegativeLighting = restoreEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = restoreEffect.particleTexture,
			castSound = restoreEffect.castSoundEffect.id,
			castVFX = restoreEffect.castVisualEffect.id,
			boltSound = restoreEffect.boltSoundEffect.id,
			boltVFX = restoreEffect.boltVisualEffect.id,
			hitSound = restoreEffect.hitSoundEffect.id,
			hitVFX = restoreEffect.hitVisualEffect.id,
			areaSound = restoreEffect.areaSoundEffect.id,
			areaVFX = restoreEffect.areaVisualEffect.id,
			lighting = {x = restoreEffect.lightingRed / 255, y = restoreEffect.lightingGreen / 255, z = restoreEffect.lightingBlue / 255},
			size = restoreEffect.size,
			sizeCap = restoreEffect.sizeCap,
			onTick = weaponResartusEffect,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[10])		-- Corruption
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			school = tes3.magicSchool.conjuration,
			baseCost = effectCost,
			speed = summonDremoraEffect.speed,
			allowEnchanting = false,
			allowSpellmaking = false,
			appliesOnce = true,
			canCastSelf = false,
			canCastTarget = true,
			canCastTouch = false,
			casterLinked = summonDremoraEffect.casterLinked,
			hasContinuousVFX = summonDremoraEffect.hasContinuousVFX,
			hasNoDuration = false,
			hasNoMagnitude = true,
			illegalDaedra = summonDremoraEffect.illegalDaedra,
			isHarmful = true,
			nonRecastable = false,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = true,
			usesNegativeLighting = summonDremoraEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = summonDremoraEffect.particleTexture,
			castSound = summonDremoraEffect.castSoundEffect.id,
			castVFX = summonDremoraEffect.castVisualEffect.id,
			boltSound = summonDremoraEffect.boltSoundEffect.id,
			boltVFX = summonDremoraEffect.boltVisualEffect.id,
			hitSound = summonDremoraEffect.hitSoundEffect.id,
			hitVFX = summonDremoraEffect.hitVisualEffect.id,
			areaSound = summonDremoraEffect.areaSoundEffect.id,
			areaVFX = summonDremoraEffect.areaVisualEffect.id,
			lighting = {x = summonDremoraEffect.lightingRed / 255, y = summonDremoraEffect.lightingGreen / 255, z = summonDremoraEffect.lightingBlue / 255},
			size = summonDremoraEffect.size,
			sizeCap = summonDremoraEffect.sizeCap,
			onTick = function(eventData)
				if (not eventData:trigger()) then
					return
				end
				
				if eventData.effectInstance.target.id ~= tes3.player.data.tamrielData.corruptionReferenceID then	-- Memory errors can be reported if the effect is applied to the summon and doing so is weird anyways
					corruptionActorID = eventData.effectInstance.target.baseObject.id
					corruptionCasted = true
					tes3.cast({ reference = eventData.sourceInstance.caster, spell = "T_Dae_Cnj_UNI_CorruptionSummon", alwaysSucceeds = true, bypassResistances = true, instant = true, target = eventData.sourceInstance.caster })
				end

				eventData.effectInstance.state = tes3.spellState.retired
			end,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[11])		-- Corruption Summon
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			school = tes3.magicSchool.conjuration,
			baseCost = effectCost,
			speed = summonDremoraEffect.speed,
			allowEnchanting = false,
			allowSpellmaking = false,
			appliesOnce = true,
			canCastSelf = true,
			canCastTarget = false,
			canCastTouch = false,
			casterLinked = summonDremoraEffect.casterLinked,
			hasContinuousVFX = summonDremoraEffect.hasContinuousVFX,
			hasNoDuration = false,
			hasNoMagnitude = true,
			illegalDaedra = summonDremoraEffect.illegalDaedra,
			isHarmful = false,
			nonRecastable = false,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = summonDremoraEffect.unreflectable,
			usesNegativeLighting = summonDremoraEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = summonDremoraEffect.particleTexture,
			castSound = summonDremoraEffect.castSoundEffect.id,
			castVFX = summonDremoraEffect.castVisualEffect.id,
			boltSound = summonDremoraEffect.boltSoundEffect.id,
			boltVFX = summonDremoraEffect.boltVisualEffect.id,
			hitSound = summonDremoraEffect.hitSoundEffect.id,
			hitVFX = summonDremoraEffect.hitVisualEffect.id,
			areaSound = summonDremoraEffect.areaSoundEffect.id,
			areaVFX = summonDremoraEffect.areaVisualEffect.id,
			lighting = {x = summonDremoraEffect.lightingRed / 255, y = summonDremoraEffect.lightingGreen / 255, z = summonDremoraEffect.lightingBlue / 255},
			size = summonDremoraEffect.size,
			sizeCap = summonDremoraEffect.sizeCap,
			onTick = function(eventData)
				eventData:triggerSummon(corruptionActorID)
			end,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[12])		-- Distract Creature
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			school = tes3.magicSchool.illusion,
			baseCost = effectCost,
			speed = blindEffect.speed,
			allowEnchanting = true,
			allowSpellmaking = true,
			appliesOnce = true,
			canCastSelf = false,
			canCastTarget = true,	-- The GUI for making custom magic effects doesn't like just having an effect only work at target range, so the distract spells also work at touch range for now
			canCastTouch = true,
			casterLinked = blindEffect.casterLinked,
			hasContinuousVFX = blindEffect.hasContinuousVFX,
			hasNoDuration = false,
			hasNoMagnitude = false,
			illegalDaedra = blindEffect.illegalDaedra,
			isHarmful = false,
			nonRecastable = false,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = true,
			usesNegativeLighting = blindEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = blindEffect.particleTexture,
			castSound = blindEffect.castSoundEffect.id,
			castVFX = blindEffect.castVisualEffect.id,
			boltSound = blindEffect.boltSoundEffect.id,
			boltVFX = blindEffect.boltVisualEffect.id,
			hitSound = blindEffect.hitSoundEffect.id,
			hitVFX = blindEffect.hitVisualEffect.id,
			areaSound = blindEffect.areaSoundEffect.id,
			areaVFX = blindEffect.areaVisualEffect.id,
			lighting = {x = blindEffect.lightingRed / 255, y = blindEffect.lightingGreen / 255, z = blindEffect.lightingBlue / 255},
			size = blindEffect.size,
			sizeCap = blindEffect.sizeCap,
			onTick = distractCreatureEffect,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[13])		-- Distract Humanoid
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			school = tes3.magicSchool.illusion,
			baseCost = effectCost,
			speed = blindEffect.speed,
			allowEnchanting = true,
			allowSpellmaking = true,
			appliesOnce = true,
			canCastSelf = false,
			canCastTarget = true,
			canCastTouch = true,
			casterLinked = blindEffect.casterLinked,
			hasContinuousVFX = blindEffect.hasContinuousVFX,
			hasNoDuration = false,
			hasNoMagnitude = false,
			illegalDaedra = blindEffect.illegalDaedra,
			isHarmful = false,
			nonRecastable = false,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = true,
			usesNegativeLighting = blindEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = blindEffect.particleTexture,
			castSound = blindEffect.castSoundEffect.id,
			castVFX = blindEffect.castVisualEffect.id,
			boltSound = blindEffect.boltSoundEffect.id,
			boltVFX = blindEffect.boltVisualEffect.id,
			hitSound = blindEffect.hitSoundEffect.id,
			hitVFX = blindEffect.hitVisualEffect.id,
			areaSound = blindEffect.areaSoundEffect.id,
			areaVFX = blindEffect.areaVisualEffect.id,
			lighting = {x = blindEffect.lightingRed / 255, y = blindEffect.lightingGreen / 255, z = blindEffect.lightingBlue / 255},
			size = blindEffect.size,
			sizeCap = blindEffect.sizeCap,
			onTick = distractHumanoidEffect,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[14])		-- Gaze of Veloth
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			school = tes3.magicSchool.destruction,
			baseCost = effectCost,
			speed = damageHealthEffect.speed,
			allowEnchanting = false,
			allowSpellmaking = false,
			appliesOnce = true,
			canCastSelf = false,
			canCastTarget = true,
			canCastTouch = true,
			casterLinked = damageHealthEffect.casterLinked,
			hasContinuousVFX = damageHealthEffect.hasContinuousVFX,
			hasNoDuration = true,
			hasNoMagnitude = true,
			illegalDaedra = damageHealthEffect.illegalDaedra,
			isHarmful = true,
			nonRecastable = false,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = true,
			usesNegativeLighting = damageHealthEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = damageHealthEffect.particleTexture,
			castSound = damageHealthEffect.castSoundEffect.id,
			castVFX = damageHealthEffect.castVisualEffect.id,
			boltSound = damageHealthEffect.boltSoundEffect.id,
			boltVFX = damageHealthEffect.boltVisualEffect.id,
			hitSound = damageHealthEffect.hitSoundEffect.id,
			hitVFX = damageHealthEffect.hitVisualEffect.id,
			areaSound = damageHealthEffect.areaSoundEffect.id,
			areaVFX = damageHealthEffect.areaVisualEffect.id,
			lighting = {x = damageHealthEffect.lightingRed / 255, y = damageHealthEffect.lightingGreen / 255, z = damageHealthEffect.lightingBlue / 255},
			size = damageHealthEffect.size,
			sizeCap = damageHealthEffect.sizeCap,
			onTick = gazeOfVelothEffect,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[15])		-- Detect Enemy
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			magnitudeType = " " .. tes3.findGMST(tes3.gmst.sfeet).value,
			magnitudeTypePlural = " " .. tes3.findGMST(tes3.gmst.sfeet).value,
			school = tes3.magicSchool.mysticism,
			baseCost = effectCost,
			speed = detectEffect.speed,
			allowEnchanting = true,
			allowSpellmaking = true,
			appliesOnce = true,
			canCastSelf = true,
			canCastTarget = false,
			canCastTouch = false,
			casterLinked = detectEffect.casterLinked,
			hasContinuousVFX = detectEffect.hasContinuousVFX,
			hasNoDuration = false,
			hasNoMagnitude = false,
			illegalDaedra = detectEffect.illegalDaedra,
			isHarmful = false,
			nonRecastable = false,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = false,
			usesNegativeLighting = detectEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = detectEffect.particleTexture,
			castSound = detectEffect.castSoundEffect.id,
			castVFX = detectEffect.castVisualEffect.id,
			boltSound = detectEffect.boltSoundEffect.id,
			boltVFX = detectEffect.boltVisualEffect.id,
			hitSound = detectEffect.hitSoundEffect.id,
			hitVFX = detectEffect.hitVisualEffect.id,
			areaSound = detectEffect.areaSoundEffect.id,
			areaVFX = detectEffect.areaVisualEffect.id,
			lighting = {x = detectEffect.lightingRed / 255, y = detectEffect.lightingGreen / 255, z = detectEffect.lightingBlue / 255},
			size = detectEffect.size,
			sizeCap = detectEffect.sizeCap,
			onTick = nil,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[16])		-- Wabbajack Trans
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			school = tes3.magicSchool.alteration,
			baseCost = effectCost,
			speed = burdenEffect.speed,
			allowEnchanting = false,
			allowSpellmaking = false,
			appliesOnce = true,
			canCastSelf = false,
			canCastTarget = true,
			canCastTouch = true,
			casterLinked = burdenEffect.casterLinked,
			hasContinuousVFX = burdenEffect.hasContinuousVFX,
			hasNoDuration = false,
			hasNoMagnitude = true,
			illegalDaedra = burdenEffect.illegalDaedra,
			isHarmful = false,
			nonRecastable = false,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = true,
			usesNegativeLighting = burdenEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = burdenEffect.particleTexture,
			castSound = "T_SndObj_Silence",
			castVFX = "T_VFX_Empty",
			boltSound = "T_SndObj_Silence",
			boltVFX = "T_VFX_Empty",
			hitSound = "T_SndObj_Silence",
			hitVFX = "T_VFX_Empty",
			areaSound = "T_SndObj_Silence",
			areaVFX = "T_VFX_Empty",
			lighting = {x = burdenEffect.lightingRed / 255, y = burdenEffect.lightingGreen / 255, z = burdenEffect.lightingBlue / 255},
			size = burdenEffect.size,
			sizeCap = burdenEffect.sizeCap,
			onTick = wabbajackTransEffect,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[17])		-- Detect Invisibility
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			magnitudeType = " " .. tes3.findGMST(tes3.gmst.sfeet).value,
			magnitudeTypePlural = " " .. tes3.findGMST(tes3.gmst.sfeet).value,
			school = tes3.magicSchool.mysticism,
			baseCost = effectCost,
			speed = detectEffect.speed,
			allowEnchanting = true,
			allowSpellmaking = true,
			appliesOnce = true,
			canCastSelf = true,
			canCastTarget = false,
			canCastTouch = false,
			casterLinked = detectEffect.casterLinked,
			hasContinuousVFX = detectEffect.hasContinuousVFX,
			hasNoDuration = false,
			hasNoMagnitude = false,
			illegalDaedra = detectEffect.illegalDaedra,
			isHarmful = false,
			nonRecastable = false,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = false,
			usesNegativeLighting = detectEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = detectEffect.particleTexture,
			castSound = detectEffect.castSoundEffect.id,
			castVFX = detectEffect.castVisualEffect.id,
			boltSound = detectEffect.boltSoundEffect.id,
			boltVFX = detectEffect.boltVisualEffect.id,
			hitSound = detectEffect.hitSoundEffect.id,
			hitVFX = detectEffect.hitVisualEffect.id,
			areaSound = detectEffect.areaSoundEffect.id,
			areaVFX = detectEffect.areaVisualEffect.id,
			lighting = {x = detectEffect.lightingRed / 255, y = detectEffect.lightingGreen / 255, z = detectEffect.lightingBlue / 255},
			size = detectEffect.size,
			sizeCap = detectEffect.sizeCap,
			onTick = nil,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[18])		-- Blink
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			magnitudeType = " " .. tes3.findGMST(tes3.gmst.sfeet).value,
			magnitudeTypePlural = " " .. tes3.findGMST(tes3.gmst.sfeet).value,
			school = tes3.magicSchool.mysticism,
			baseCost = effectCost,
			speed = detectEffect.speed,
			allowEnchanting = true,
			allowSpellmaking = true,
			appliesOnce = true,
			canCastSelf = true,
			canCastTarget = false,
			canCastTouch = false,
			casterLinked = detectEffect.casterLinked,
			hasContinuousVFX = detectEffect.hasContinuousVFX,
			hasNoDuration = true,
			hasNoMagnitude = false,
			illegalDaedra = detectEffect.illegalDaedra,
			isHarmful = false,
			nonRecastable = false,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = false,
			usesNegativeLighting = detectEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = detectEffect.particleTexture,
			castSound = detectEffect.castSoundEffect.id,
			castVFX = detectEffect.castVisualEffect.id,
			boltSound = detectEffect.boltSoundEffect.id,
			boltVFX = detectEffect.boltVisualEffect.id,
			hitSound = "T_SndObj_BlinkHit",
			hitVFX = "T_VFX_Empty",
			areaSound = detectEffect.areaSoundEffect.id,
			areaVFX = detectEffect.areaVisualEffect.id,
			lighting = {x = detectEffect.lightingRed / 255, y = detectEffect.lightingGreen / 255, z = detectEffect.lightingBlue / 255},
			size = detectEffect.size,
			sizeCap = detectEffect.sizeCap,
			onTick = blinkEffect,
			onCollision = nil
		}

		effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[19])		-- Fortify Casting
		tes3.addMagicEffect{
			id = effectID,
			name = effectName,
			description = effectDescription,
			school = tes3.magicSchool.restoration,
			baseCost = effectCost,
			speed = fortifyAttackEffect.speed,
			allowEnchanting = true,
			allowSpellmaking = true,
			appliesOnce = true,
			canCastSelf = true,
			canCastTarget = false,
			canCastTouch = false,
			casterLinked = fortifyAttackEffect.casterLinked,
			hasContinuousVFX = fortifyAttackEffect.hasContinuousVFX,
			hasNoDuration = false,
			hasNoMagnitude = false,
			illegalDaedra = fortifyAttackEffect.illegalDaedra,
			isHarmful = false,
			nonRecastable = false,
			targetsAttributes = false,
			targetsSkills = false,
			unreflectable = false,
			usesNegativeLighting = fortifyAttackEffect.usesNegativeLighting,
			icon = iconPath,
			particleTexture = fortifyAttackEffect.particleTexture,
			castSound = fortifyAttackEffect.castSoundEffect.id,
			castVFX = fortifyAttackEffect.castVisualEffect.id,
			boltSound = fortifyAttackEffect.boltSoundEffect.id,
			boltVFX = fortifyAttackEffect.boltVisualEffect.id,
			hitSound = fortifyAttackEffect.hitSoundEffect.id,
			hitVFX = fortifyAttackEffect.hitVisualEffect.id,
			areaSound = fortifyAttackEffect.areaSoundEffect.id,
			areaVFX = fortifyAttackEffect.areaVisualEffect.id,
			lighting = {x = fortifyAttackEffect.lightingRed / 255, y = fortifyAttackEffect.lightingGreen / 255, z = fortifyAttackEffect.lightingBlue / 255},
			size = fortifyAttackEffect.size,
			sizeCap = fortifyAttackEffect.sizeCap,
			onTick = nil,
			onCollision = nil
		}

		--effectID, effectName, effectCost, iconPath, effectDescription = unpack(td_misc_effects[20])		-- Prismatic Light
		--tes3.addMagicEffect{
		--	id = effectID,
		--	name = effectName,
		--	description = effectDescription,
		--	school = tes3.magicSchool.illusion,
		--	baseCost = effectCost,
		--	speed = lightEffect.speed,
		--	allowEnchanting = lightEffect.allowEnchanting,
		--	allowSpellmaking = lightEffect.allowSpellmaking,
		--	appliesOnce = lightEffect.appliesOnce,
		--	canCastSelf = lightEffect.canCastSelf,
		--	canCastTarget = lightEffect.canCastTarget,
		--	canCastTouch = lightEffect.canCastTouch,
		--	casterLinked = lightEffect.casterLinked,
		--	hasContinuousVFX = lightEffect.hasContinuousVFX,
		--	hasNoDuration = lightEffect.hasNoDuration,
		--	hasNoMagnitude = lightEffect.hasNoMagnitude,
		--	illegalDaedra = lightEffect.illegalDaedra,
		--	isHarmful = lightEffect.isHarmful,
		--	nonRecastable = lightEffect.nonRecastable,
		--	targetsAttributes = lightEffect.targetsAttributes,
		--	targetsSkills = lightEffect.targetsSkills,
		--	unreflectable = lightEffect.unreflectable,
		--	usesNegativeLighting = lightEffect.usesNegativeLighting,
		--	icon = iconPath,
		--	particleTexture = lightEffect.particleTexture,
		--	castSound = lightEffect.castSoundEffect.id,
		--	castVFX = lightEffect.castVisualEffect.id,
		--	boltSound = lightEffect.boltSoundEffect.id,
		--	boltVFX = lightEffect.boltVisualEffect.id,
		--	hitSound = lightEffect.hitSoundEffect.id,
		--	hitVFX = lightEffect.hitVisualEffect.id,
		--	areaSound = lightEffect.areaSoundEffect.id,
		--	areaVFX = lightEffect.areaVisualEffect.id,
		--	lighting = {x = lightEffect.lightingRed / 255, y = lightEffect.lightingGreen / 255, z = lightEffect.lightingBlue / 255},
		--	size = lightEffect.size,
		--	sizeCap = lightEffect.sizeCap,
		--	onTick = prismaticLightEffect,
		--	onCollision = nil
		--}
	end
end)

-- Replaces spell names, effects, etc. using the spell tables above
event.register(tes3.event.load, function()
	if config.summoningSpells == true then
		this.replaceSpells(td_summon_spells)
	end

	if config.boundSpells == true then
		this.replaceSpells(td_bound_spells)
	end
	
	if config.interventionSpells == true then
		this.replaceSpells(td_intervention_spells)
	end

	if config.miscSpells == true then
		this.replaceSpells(td_misc_spells)

		event.unregister(tes3.event.uiActivated, this.onMenuMagicActivated, { filter = "MenuMagic" })	-- unregisterOnLoad isn't an option here of course
		event.register(tes3.event.uiActivated, this.onMenuMagicActivated, { filter = "MenuMagic" })	-- This needs to be done before the loaded event is triggered

		event.unregister(tes3.event.uiActivated, this.onMenuSpellmakingActivated, { filter = "MenuSpellmaking" })
		event.register(tes3.event.uiActivated, this.onMenuSpellmakingActivated, { filter = "MenuSpellmaking" })

		event.unregister(tes3.event.uiActivated, this.onMenuMultiActivated, { filter = "MenuMulti" })
		event.register(tes3.event.uiActivated, this.onMenuMultiActivated, { filter = "MenuMulti" })
	end

	if config.summoningSpells == true and config.boundSpells == true and config.interventionSpells == true and config.miscSpells == true then
		this.replaceEnchantments(td_enchantments)
		this.replaceIngredientEffects(td_ingredients)
		this.replacePotions(td_potions)
		this.editItems(td_enchanted_items)

		tes3.getObject("T_Dae_UNI_Wabbajack").enchantment = tes3.getObject("T_Use_WabbajackUni")	-- Crashes game when registered to the loaded event with the wabbajack enchantment equipped, so it is here instead
	end
end)

return this