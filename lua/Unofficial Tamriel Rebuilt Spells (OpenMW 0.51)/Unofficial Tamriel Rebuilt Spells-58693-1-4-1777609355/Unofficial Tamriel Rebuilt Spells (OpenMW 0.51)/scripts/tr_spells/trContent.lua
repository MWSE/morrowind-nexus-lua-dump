local content = require('openmw.content')
local trData = require('scripts.tr_spells.trData')
require('scripts.tr_spells.SETTINGS')

if content.magicEffects.records["t_summon_devourer"]
	or content.magicEffects.records["t_bound_greatsword"]
	or content.magicEffects.records["t_mysticism_reflectdmg"]
	or content.magicEffects.records["t_alteration_radshield"]
then
	return
end

-- =====================================================
-- HELPERS
-- =====================================================

local function defineEffect(id, name, template, baseCost, icon, extras)
	content.magicEffects.records[id] = {
		template = content.magicEffects.records[template],
		name = name,
		baseCost = math.floor(baseCost * GLOBAL_EFFECT_COST_MULT),
		icon = icon,
	}
	if extras then
		for a,b in pairs(extras) do
			content.magicEffects.records[id][a] = b
		end
	end
end

local function defineSelfSpell(id, effectId, name, cost, duration, magnitude)
	content.spells.records[id] = {
		name = name,
		type = content.spells.TYPE.Spell,
		cost = cost,
		isAutocalc = false,
		effects = {
			{
				id = effectId,
				range = content.RANGE.Self,
				area = 0,
				duration = duration,
				magnitudeMin = magnitude or 1,
				magnitudeMax = magnitude or 1,
			},
		},
	}
end

local function defineSpell(id, record)
	if record.isAutocalc == nil then record.isAutocalc = false end
	content.spells.records[id] = record
end

-- =====================================================
-- EFFECT DESCRIPTIONS
-- =====================================================

local descriptions = {
	blinkDesc = "This effect teleports the caster in whatever direction they are looking in. The effect's magnitude is the maximum distance that the caster can move.",
	fortifyCastingDesc = "This effect raises the subject's chance of successfully casting a spell.",
	summonDevourerDesc = "This effect summons a devourer from Oblivion. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight.",
	summonDremoraArcherDesc = "This effect summons a dremora archer from Oblivion. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight.",
	summonDremoraCasterDesc = "This effect summons a dremora spellcaster from Oblivion. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight.",
	summonGuardianDesc = "This effect summons a guardian from Oblivion. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight.",
	summonLesserClannfearDesc = "This effect summons a rock biter clannfear from Oblivion. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight.",
	summonOgrimDesc = "This effect summons an ogrim from Oblivion. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight.",
	summonSeducerDesc = "This effect summons a seducer from Oblivion. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight.",
	summonSeducerDarkDesc = "This effect summons a dark seducer from Oblivion. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight.",
	summonVermaiDesc = "This effect summons a vermai from Oblivion. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight.",
	summonStormMonarchDesc = "This effect summons a storm monarch from Oblivion. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight.",
	summonIceWraithDesc = "This effect summons an ice wraith from the Outer Realms. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to the Outer Realms. If summoned in town, the guards will attack you and the summoning on sight.",
	summonDweSpectreDesc = "This effect summons a dwarven spectre from the Outer Realms. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to the Outer Realms. If summoned in town, the guards will attack you and the summoning on sight.",
	summonSteamCentDesc = "This effect summons an steam centurion from the Outer Realms. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to the Outer Realms. If summoned in town, the guards will attack you and the summoning on sight.",
	summonSpiderCentDesc = "This effect summons a centurion spider from the Outer Realms. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to the Outer Realms. If summoned in town, the guards will attack you and the summoning on sight.",
	summonWelkyndSpiritDesc = "This effect summons a welkynd spirit from the Outer Realms. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to the Outer Realms. If summoned in town, the guards will attack you and the summoning on sight.",
	summonAuroranDesc = "This effect summons an auroran from Oblivion. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight.",
	summonHerneDesc = "This effect summons a herne from Oblivion. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight.",
	summonMorphoidDesc = "This effect summons a morphoid daedra from Oblivion. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight.",
	summonDraugrDesc = "This effect summons a draugr from the Underworld. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to the Underworld. If summoned in town, the guards will attack you and the summoning on sight.",
	summonSprigganDesc = "This effect summons a spriggan from the Outer Realms. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to the Outer Realms. If summoned in town, the guards will attack you and the summoning on sight.",
	summonGreaterBonelordDesc = "This effect summons a bonelord warder from the Outer Realms. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to the Outer Realms. If summoned in town, the guards will attack you and the summoning on sight.",
	summonGhostDesc = "This effect summons a ghost from the Outer Realms. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to the Outer Realms. If summoned in town, the guards will attack you and the summoning on sight.",
	summonWraithDesc = "This effect summons a wraith from the Outer Realms. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to the Outer Realms. If summoned in town, the guards will attack you and the summoning on sight.",
	summonBarrowguardDesc = "This effect summons a barrowguard from the Outer Realms. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to the Outer Realms. If summoned in town, the guards will attack you and the summoning on sight.",
	summonMinoBarrowguardDesc = "This effect summons a minotaur barrowguard from the Outer Realms. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to the Outer Realms. If summoned in town, the guards will attack you and the summoning on sight.",
	summonSkeletonChampionDesc = "This effect summons a skeleton champion from the Outer Realms. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to the Outer Realms. If summoned in town, the guards will attack you and the summoning on sight.",
	summonFrostMonarchDesc = "This effect summons a frost monarch from Oblivion. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight.",
	summonSpiderDaedraDesc = "This effect summons a spider daedra from Oblivion. It appears six feet in front of the caster and attacks any entity that attacks the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight.",
	boundGreavesDesc = "The spell effect conjures a lesser Daedra bound in the form of magical, wondrously light Daedric greaves. The greaves appear automatically equipped on the caster, displacing any currently equipped leg armor to inventory. When the effect ends, the greaves disappear, and any previously equipped leg armor is automatically re-equipped.",
	boundWarAxeDesc = "The spell effect conjures a lesser Daedra bound in the form of a magical, wondrously light Daedric war axe. The war axe appears automatically equipped on the caster, displacing any currently equipped weapon to inventory. When the effect ends, the war axe disappears, and any previously equipped weapon is automatically re-equipped.",
	boundWarhammerDesc = "The spell effect conjures a lesser Daedra bound in the form of a magical, wondrously light Daedric warhammer. The warhammer appears automatically equipped on the caster, displacing any currently equipped weapon to inventory. When the effect ends, the warhammer disappears, and any previously equipped weapon is automatically re-equipped.",
	boundPauldronsDesc = "The spell effect conjures a lesser Daedra bound in the form of magical, wondrously light Daedric pauldrons. The pauldrons appear automatically equipped on the caster, displacing any currently equipped shoulder armor to inventory. When the effect ends, the pauldrons disappear, and any previously equipped shoulder armor is automatically re-equipped.",
	boundGreatswordDesc = "The spell effect conjures a lesser Daedra bound in the form of a magical, wondrously light Daedric greatsword. The greatsword appears automatically equipped on the caster, displacing any currently equipped weapon to inventory. When the effect ends, the greatsword disappears, and any previously equipped weapon is automatically re-equipped.",
	interventionKyneDesc = "The subject of this effect is transported instantaneously to the nearest temple or sacred place of the Nordic goddess Kyne.",
	passwallDesc = "In an indoor area, this effect permits the caster to pass through a solid barrier to a vacant space behind it. The effect will fail if the destination beyond the traversed barrier is filled with water, is blocked by a forcefield, sigil gate, or ward, or lies above or below the caster.",
	banishDesc = "Banishes any daedra that the spell is cast upon if the spell's magnitude is greater than or equal to the target's level. If the daedra is wounded, then it will be easier to banish. Banishing a daedra will transfer any of their important belongings to a sigil that is left behind.",
	reflectDamageDesc = "This effect allows the subject to reflect physical damage back at an attacker. The effect's magnitude is the percent damage that will be reflected for each attack. Any unreflected damage is dealt to the defender normally.",
	radiantShieldDesc = "This effect creates a shield of brilliant light around the subject's entire body. The spell adds its magnitude to the subject's Armor Rating, resists harmful magic, and briefly blinds attackers in melee.",
	insightDesc = "This effect lightly twists fate, increasing the chance of discovering valuable items.",
	armorResartusDesc = "This effect mends and recharges enchanted armor that is equipped by the caster. The magnitude is the units of condition and charge restored, which are distributed across all of the caster's enchanted armor.",
	weaponResartusDesc = "This effect mends and recharges an enchanted weapon that is equipped by the caster. The magnitude is the units of condition and charge restored.",
	distractCreatureDesc = "This effect compels a creature to wander away from their current position while attempting to keep their distance from the caster. The effect's magnitude is the maximum distance that the target can travel and the effect cannot be casted again on the target while it is active. Using this effect will fail if the target is aware of the caster's presence. When the effect ends, the target begins to return to their original location and cannot be distracted again until they do.",
	distractHumanoidDesc = "This effect compels a person to wander away from their current position while attempting to keep their distance from the caster. The effect's magnitude is the maximum distance that the target can travel and the effect cannot be casted again on the target while it is active. Using this effect will fail if the target is aware of the caster's presence. When the effect ends, the target begins to return to their original location and cannot be distracted again until they do.",
	gazeOfVelothDesc = "Witness the Face of Veloth!",
	-- detectEnemyDesc = "The caster of this effect can detect any entity animated by a spirit; they appear on the map as symbols. This effect includes all hostile beings. The effect's magnitude is the range in feet from the caster that enemies are detected.",
	-- detectInvisibilityDesc = "The caster of this effect can detect any entity animated by a spirit; they appear on the map as symbols. This effect includes all beings affected by chameleon or invisibility effects. The effect's magnitude is the range in feet from the caster that hidden beings are detected. The chameleon and invisibility effects on detected entities are also weakened.",
	corruptionDesc = "This effect creates a shadowy counterpart of the target that will aid the caster in combat.",
	wabbajackDesc = "Wabbajack!",
	-- detectHumanoidDesc = "The caster of this effect can detect any entity animated by a spirit; they appear on the map as symbols. This effect includes all people. The effect's magnitude is the range in feet from the caster that humanoids are detected.",
	-- boundThrowingKnivesDesc = "The spell effect conjures a lesser Daedra bound in the form of magical, wondrously light Daedric throwing knives. The throwing knives appear automatically equipped on the caster, displacing any currently equipped weapon to inventory. When the effect ends, the throwing knives disappear, and any previously equipped weapon is automatically re-equipped.",
}


-- =====================================================
-- SUMMON EFFECTS
-- =====================================================

defineEffect("t_summon_devourer",          "Summon Devourer",             "summondremora",           52, "td/s/td_s_summ_dev.dds",      {description = descriptions.summonDevourerDesc})
defineEffect("t_summon_dremarch",          "Summon Dremora Archer",       "summondremora",           33, "td/s/td_s_sum_drm_arch.dds",  {description = descriptions.summonDremoraArcherDesc})
defineEffect("t_summon_dremcast",          "Summon Dremora Caster",       "summondremora",           31, "td/s/td_s_sum_drm_mage.dds",  {description = descriptions.summonDremoraCasterDesc})
defineEffect("t_summon_guardian",          "Summon Guardian",             "summongoldensaint",       69, "td/s/td_s_sum_guard.dds",     {description = descriptions.summonGuardianDesc})
defineEffect("t_summon_lesserclfr",        "Summon Lesser Clannfear",     "summonclannfear",         19, "td/s/td_s_sum_lsr_clan.dds",  {description = descriptions.summonLesserClannfearDesc})
defineEffect("t_summon_ogrim",             "Summon Ogrim",                "summondaedroth",          33, "td/s/td_s_summ_ogrim.dds",    {description = descriptions.summonOgrimDesc})
defineEffect("t_summon_seducer",           "Summon Seducer",              "summongoldensaint",       52, "td/s/td_s_summ_sed.dds",      {description = descriptions.summonSeducerDesc})
defineEffect("t_summon_seducerdark",       "Summon Dark Seducer",         "summongoldensaint",       75, "td/s/td_s_summ_d_sed.dds",    {description = descriptions.summonSeducerDarkDesc})
defineEffect("t_summon_vermai",            "Summon Vermai",               "summonclannfear",         29, "td/s/td_s_summ_vermai.dds",   {description = descriptions.summonVermaiDesc})
defineEffect("t_summon_atrostormmon",      "Summon Storm Monarch",        "summonstormatronach",     60, "td/s/td_s_sum_stm_monch.dds", {description = descriptions.summonStormMonarchDesc})
defineEffect("t_summon_icewraith",         "Summon Ice Wraith",           "summonfrostatronach",     35, "td/s/td_s_sum_ice_wrth.dds",  {description = descriptions.summonIceWraithDesc})
defineEffect("t_summon_dwespectre",        "Summon Dwarven Spectre",      "summonancestralghost",    17, "td/s/td_s_sum_dwe_spctre.dds",{description = descriptions.summonDweSpectreDesc})
defineEffect("t_summon_steamcent",         "Summon Steam Centurion",      "summoncenturionsphere",   29, "td/s/td_s_sum_dwe_cent.dds",  {description = descriptions.summonSteamCentDesc})
defineEffect("t_summon_spidercent",        "Summon Spider Centurion",     "summoncenturionsphere",   15, "td/s/td_s_sum_dwe_spdr.dds",  {description = descriptions.summonSpiderCentDesc})
defineEffect("t_summon_welkyndspirit",     "Summon Welkynd Spirit",       "summonancestralghost",    29, "td/s/td_s_sum_welk_srt.dds",  {description = descriptions.summonWelkyndSpiritDesc})
defineEffect("t_summon_auroran",           "Summon Auroran",              "summongoldensaint",       46, "td/s/td_s_sum_auro.dds",      {description = descriptions.summonAuroranDesc})
defineEffect("t_summon_herne",             "Summon Herne",                "summonscamp",             18, "td/s/td_s_sum_herne.dds",     {description = descriptions.summonHerneDesc})
defineEffect("t_summon_morphoid",          "Summon Morphoid",             "summonscamp",             21, "td/s/td_s_sum_morph.dds",     {description = descriptions.summonMorphoidDesc})
defineEffect("t_summon_draugr",            "Summon Draugr",               "summonskeletalminion",    29, "td/s/td_s_sum_draugr.dds",    {description = descriptions.summonDraugrDesc})
defineEffect("t_summon_spriggan",          "Summon Spriggan",             "summonfabricant",         48, "td/s/td_s_sum_sprig.dds",     {description = descriptions.summonSprigganDesc})
defineEffect("t_summon_boneldgr",          "Summon Greater Bonelord",     "summonbonelord",          71, "td/s/td_s_sum_gtr_bnlrd.dds", {description = descriptions.summonGreaterBonelordDesc})
defineEffect("t_summon_ghost",             "Summon Ghost",                "summonancestralghost",     7, "td/s/td_s_summ_ghost.dds",    {description = descriptions.summonGhostDesc})
defineEffect("t_summon_wraith",            "Summon Wraith",               "summonancestralghost",    49, "td/s/td_s_summ_wraith.dds",   {description = descriptions.summonWraithDesc})
defineEffect("t_summon_barrowguard",       "Summon Barrowguard",          "summongreaterbonewalker", 11, "td/s/td_s_summ_brwgurd.dds",  {description = descriptions.summonBarrowguardDesc})
defineEffect("t_summon_minobarrowguard",   "Summon Minotaur Barrowguard", "summongreaterbonewalker", 57, "td/s/td_s_summ_mintur.dds",   {description = descriptions.summonMinoBarrowguardDesc})
defineEffect("t_summon_skeletonchampion",  "Summon Skeleton Champion",    "summonskeletalminion",    32, "td/s/td_s_sum_skele_c.dds",   {description = descriptions.summonSkeletonChampionDesc})
defineEffect("t_summon_atrofrostmon",      "Summon Frost Monarch",        "summonfrostatronach",     47, "td/s/td_s_sum_fst_monch.dds", {description = descriptions.summonFrostMonarchDesc})
defineEffect("t_summon_spiderdaedra",      "Summon Spider Daedra",        "summondaedroth",          42, "td/s/td_s_sum_spidr_dae.dds", {description = descriptions.summonSpiderDaedraDesc})

-- =====================================================
-- BOUND EFFECTS
-- =====================================================

defineEffect("t_bound_greaves",    "Bound Greaves",    "boundboots",     2, "td/s/td_s_bnd_grves.dds", {description = descriptions.boundGreavesDesc})
defineEffect("t_bound_waraxe",     "Bound War Axe",    "boundbattleaxe", 2, "td/s/td_s_bnd_waxe.dds",  {description = descriptions.boundWarAxeDesc})
defineEffect("t_bound_warhammer",  "Bound Warhammer",  "boundmace",      2, "td/s/td_s_bnd_wham.dds",  {description = descriptions.boundWarhammerDesc})
defineEffect("t_bound_pauldrons",  "Bound Pauldrons",  "boundhelm",      2, "td/s/td_s_bnd_pldrn.dds", {description = descriptions.boundPauldronsDesc})
defineEffect("t_bound_greatsword", "Bound Greatsword", "boundlongsword", 2, "td/s/td_s_bnd_clymr.dds", {description = descriptions.boundGreatswordDesc})
defineEffect("t_bound_hammerresdayn", "Bound Hammer (Resdayn)", "boundmace",      2, "td/s/td_s_bnd_res_ham.dds")
defineEffect("t_bound_razorresdayn",  "Bound Razor (Resdayn)",  "boundlongsword", 2, "td/s/td_s_bnd_red_razor.dds")

-- =====================================================
-- VANILLA BOUND REPLACERS
-- =====================================================

local function defineVanillaScaledBound(id, name, vanillaId)
	local v = content.magicEffects.records[vanillaId]
	if not v then return end
	content.magicEffects.records[id] = {
		template = v,
		name     = name,
		icon     = v.icon,
		baseCost = v.baseCost,
	}
end

defineVanillaScaledBound("t_bound_battleaxe", "Bound Battle Axe", "boundbattleaxe")
defineVanillaScaledBound("t_bound_boots",     "Bound Boots",      "boundboots")
defineVanillaScaledBound("t_bound_cuirass",   "Bound Cuirass",    "boundcuirass")
defineVanillaScaledBound("t_bound_dagger",    "Bound Dagger",     "bounddagger")
defineVanillaScaledBound("t_bound_gloves",    "Bound Gloves",     "boundgloves")
defineVanillaScaledBound("t_bound_helm",      "Bound Helm",       "boundhelm")
defineVanillaScaledBound("t_bound_longbow",   "Bound Longbow",    "boundlongbow")
defineVanillaScaledBound("t_bound_longsword", "Bound Longsword",  "boundlongsword")
defineVanillaScaledBound("t_bound_mace",      "Bound Mace",       "boundmace")
defineVanillaScaledBound("t_bound_shield",    "Bound Shield",     "boundshield")
defineVanillaScaledBound("t_bound_spear",     "Bound Spear",      "boundspear")

-- =====================================================
-- OTHER EFFECTS
-- =====================================================

defineEffect("t_intervention_kyne", "Kyne's Intervention", "divineintervention", 150, "td/s/td_s_int_kyne.tga", {hasDuration = false, hasMagnitude = false, description = descriptions.interventionKyneDesc})

content.statics.records["TRSU_emptyStatic"] = {model = "meshes/tr_spells/none.nif"}

defineEffect("t_mysticism_blink", "Blink", "telekinesis", EFFECT_COST_BLINK, "td/s/td_s_blink.tga", { onTouch = true, onTarget = true, hasDuration = false, hasMagnitude = true, school = "mysticism",
    --castStatic= "TRSU_emptyStatic",--"meshes/tr_spells/none.nif",--content.statics.records["VFX_MysticismCast"].model,
    bolt= "VFX_MysticismBolt",
    hitStatic= "TRSU_emptyStatic",--"meshes/tr_spells/none.nif",--content.statics.records["VFX_MysticismHit"].model,
    --areaStatic= "TRSU_emptyStatic",--"meshes/tr_spells/none.nif",--content.statics.records["VFX_MysticismArea"].model,
    description = descriptions.blinkDesc,
})
defineEffect("t_mysticism_passwall", "Passwall", "detectenchantment", EFFECT_COST_PASSWALL, "td/s/td_s_passwall.tga", {hasDuration = false, onTouch = false, onTarget = false, description = descriptions.passwallDesc})
defineEffect("t_mysticism_insight", "Insight", "detectenchantment", EFFECT_COST_INSIGHT, "td/s/td_s_insight.tga", {onTouch = false, onTarget = false, description = descriptions.insightDesc})
defineEffect("t_mysticism_reflectdmg", "Reflect Damage", "reflect", EFFECT_COST_REFLECT, "td/s/td_s_ref_dam.tga", {description = descriptions.reflectDamageDesc})
defineEffect("t_restoration_fortifycasting", "Fortify Casting", "fortifyattack", EFFECT_COST_FORTCAST, "td/s/td_s_ftfy_cast.tga", {description = descriptions.fortifyCastingDesc})
defineEffect("t_alteration_radshield", "Radiant Shield", "shield", EFFECT_COST_RADIANT_SHIELD, "td/s/td_s_radiant_shield.tga", {hitStatic = "T_VFX_RadiantShieldHit", description = descriptions.radiantShieldDesc})
defineEffect("t_restoration_armorresartus",  "Armor Resartus",  "restorehealth", EFFECT_COST_ARMOR_RESARTUS,  "td/s/td_s_restore_ar.tga", {description = descriptions.armorResartusDesc})
defineEffect("t_restoration_weaponresartus", "Weapon Resartus", "restorehealth", EFFECT_COST_WEAPON_RESARTUS, "td/s/td_s_restore_wpn.tga", {description = descriptions.weaponResartusDesc})
defineEffect("t_illusion_distractcreature", "Distract Creature", "chameleon", EFFECT_COST_DISTRACT_CREATURE, "td/s/td_s_dist_cre.tga", {description = descriptions.distractCreatureDesc})
defineEffect("t_illusion_distracthumanoid", "Distract Humanoid", "chameleon", EFFECT_COST_DISTRACT_HUMANOID, "td/s/td_s_dist_hum.tga", {description = descriptions.distractHumanoidDesc})
defineEffect("t_mysticism_banishdae", "Banish Daedra", "dispel", EFFECT_COST_BANISH_DAE, "td/s/td_s_ban_daedra.tga", {school = "mysticism", unreflectable = true, description = descriptions.banishDesc})
--defineEffect("t_destruction_gazeofveloth", "Gaze of Veloth", "damagehealth", 80, "td/s/td_s_gaze_veloth.tga")
--defineEffect("t_conjuration_sanguinerose", "Sanguine Rose", "summondaedroth", 40, "td/s/td_s_sanguine.tga")

-- =====================================================
-- SUMMON SPELLS
-- =====================================================

defineSelfSpell("t_com_cnj_summondevourer",        "t_summon_devourer",         "Summon Devourer",             156, 60)
defineSelfSpell("t_com_cnj_summondremoraarcher",   "t_summon_dremarch",         "Summon Dremora Archer",        98, 60)
defineSelfSpell("t_com_cnj_summondremoracaster",   "t_summon_dremcast",         "Summon Dremora Caster",        93, 60)
defineSelfSpell("t_com_cnj_summonguardian",        "t_summon_guardian",         "Summon Guardian",             155, 45)
defineSelfSpell("t_com_cnj_summonlesserclannfear", "t_summon_lesserclfr",       "Summon Lesser Clannfear",      57, 60)
defineSelfSpell("t_com_cnj_summonogrim",           "t_summon_ogrim",            "Summon Ogrim",                 99, 60)
defineSelfSpell("t_com_cnj_summonseducer",         "t_summon_seducer",          "Summon Seducer",              156, 60)
defineSelfSpell("t_com_cnj_summonseducerdark",     "t_summon_seducerdark",      "Summon Dark Seducer",         169, 45)
defineSelfSpell("t_com_cnj_summonvermai",          "t_summon_vermai",           "Summon Vermai",                88, 60)
defineSelfSpell("t_com_cnj_summonstormmonarch",    "t_summon_atrostormmon",     "Summon Storm Monarch",        180, 60)
defineSelfSpell("t_nor_cnj_summonicewraith",       "t_summon_icewraith",        "Summon Ice Wraith",           105, 60)
defineSelfSpell("t_dwe_cnj_uni_summondwespectre",  "t_summon_dwespectre",       "Summon Dwarven Spectre",       52, 60)
defineSelfSpell("t_dwe_cnj_uni_summonsteamcent",   "t_summon_steamcent",        "Summon Steam Centurion",       88, 60)
defineSelfSpell("t_dwe_cnj_uni_summonspidercent",  "t_summon_spidercent",       "Summon Spider Centurion",      45, 60)
defineSelfSpell("t_ayl_cnj_summonwelkyndspirit",   "t_summon_welkyndspirit",    "Summon Welkynd Spirit",        78, 60)
defineSelfSpell("t_com_cnj_summonauroran",         "t_summon_auroran",          "Summon Auroran",              138, 60)
defineSelfSpell("t_com_cnj_summonherne",           "t_summon_herne",            "Summon Herne",                 54, 60)
defineSelfSpell("t_com_cnj_summonmorphoid",        "t_summon_morphoid",         "Summon Morphoid",              63, 60)
defineSelfSpell("t_nor_cnj_summondraugr",          "t_summon_draugr",           "Summon Draugr",                78, 60)
defineSelfSpell("t_nor_cnj_summonspriggan",        "t_summon_spriggan",         "Summon Spriggan",             144, 60)
defineSelfSpell("t_de_cnj_summongreaterbonelord",  "t_summon_boneldgr",         "Summon Greater Bonelord",     160, 45)
defineSelfSpell("t_cyr_cnj_summonghost",           "t_summon_ghost",            "Summon Ghost",                 21, 60)
defineSelfSpell("t_cyr_cnj_summonwraith",          "t_summon_wraith",           "Summon Wraith",               147, 60)
defineSelfSpell("t_cyr_cnj_summonbarrowguard",     "t_summon_barrowguard",      "Summon Barrowguard",           33, 60)
defineSelfSpell("t_cyr_cnj_summonminobarrowguard", "t_summon_minobarrowguard",  "Summon Minotaur Barrowguard", 171, 60)
defineSelfSpell("t_com_cnj_summonskeletonchamp",   "t_summon_skeletonchampion", "Summon Skeleton Champion",     96, 60)
defineSelfSpell("t_com_cnj_summonfrostmonarch",    "t_summon_atrofrostmon",     "Summon Frost Monarch",        141, 60)
defineSelfSpell("t_com_cnj_summonspiderdaedra",    "t_summon_spiderdaedra",     "Summon Spider Daedra",        126, 60)

-- NPC only
defineSelfSpell("t_cr_cnj_aylsorcksummon1", "t_summon_auroran",       nil, 40, 40)
defineSelfSpell("t_cr_cnj_aylsorcksummon3", "t_summon_welkyndspirit", nil, 25, 40)

-- =====================================================
-- BOUND SPELLS
-- =====================================================

defineSelfSpell("t_com_cnj_boundgreaves",    "t_bound_greaves",    "Bound Greaves",    6, 60)
defineSelfSpell("t_com_cnj_boundwaraxe",     "t_bound_waraxe",     "Bound War Axe",    6, 60)
defineSelfSpell("t_com_cnj_boundwarhammer",  "t_bound_warhammer",  "Bound Warhammer",  6, 60)
defineSelfSpell("t_com_cnj_boundpauldron",   "t_bound_pauldrons",  "Bound Pauldrons",  6, 60)
defineSelfSpell("t_com_cnj_boundgreatsword", "t_bound_greatsword", "Bound Greatsword", 6, 60)

-- NPC only
defineSelfSpell("t_de_cnj_uni_boundhammerresdayn", "t_bound_hammerresdayn", nil, 6, 60)
defineSelfSpell("t_de_cnj_uni_boundrazororesdayn", "t_bound_razorresdayn",  nil, 6, 60)

-- =====================================================
-- OTHER SPELLS
-- =====================================================

defineSelfSpell("t_nor_mys_kynesintervention", "t_intervention_kyne", "Kyne's Intervention",  8, 0)
defineSelfSpell("t_com_mys_blink", "t_mysticism_blink", "Blink", math.floor(EFFECT_COST_BLINK * 2.5), 0, 50) -- 10 * 2.5 = 25
defineSelfSpell("t_com_mys_uni_passwall", "t_mysticism_passwall", "Passwall", math.floor(EFFECT_COST_PASSWALL * 0.128), 1, 25) -- 750 * 0.128 = 96
defineSelfSpell("t_com_mys_insight", "t_mysticism_insight", "Insight", math.floor(EFFECT_COST_INSIGHT*7.6), 10, 15)  -- 10 * 7.6 = 76
defineSpell("t_uni_sainttelynblessing", {
	type = content.spells.TYPE.Ability,
	effects = {
		{
			id = "t_mysticism_insight",
			range = content.RANGE.Self,
			duration = 0,
			magnitudeMin = 10,
			magnitudeMax = 10,
		},
	},
})

-- Radiant shield and variants
defineSelfSpell("t_ayl_alt_radiantshield", "t_alteration_radshield", "Radiant Shield", EFFECT_COST_RADIANT_SHIELD * 15, 30, 10) -- 5 * 15 = 75

defineSpell("t_cr_alt_auroranshield", {
	type = content.spells.TYPE.Ability,
	effects = {
		{
			id = "t_alteration_radshield",
			range = content.RANGE.Self,
			duration = 0,
			magnitudeMin = 20,
			magnitudeMax = 20,
		},
	},
})

-- Ayleid radiant shield + light combo
defineSpell("t_cr_alt_aylsorcklightshield", {
	name = "Radiant Shield",
	type = content.spells.TYPE.Spell,
	cost = EFFECT_COST_RADIANT_SHIELD * 2,
	effects = {
		{
			id = "t_alteration_radshield",
			range = content.RANGE.Self,
			duration = 12,
			magnitudeMin = 10,
			magnitudeMax = 10,
		},
		{
			id = "Light",
			range = content.RANGE.Self,
			duration = 12,
			magnitudeMin = 20,
			magnitudeMax = 20,
		},
	},
})

-- Blind for radiant shield
local blindEffects = {}
for i = 0, 6 do
	local mag = 2 ^ i
	blindEffects[i + 1] = {
		id = "Blind",
		range = content.RANGE.Self,
		area = 0,
		duration = 2,
		magnitudeMin = mag,
		magnitudeMax = mag,
	}
end

defineSpell("t_alteration_radshield_blind", {
	type = content.spells.TYPE.Spell,
	cost = 0,
	effects = blindEffects,
})

-- Reflect Damage
defineSpell("t_com_mys_reflectdamage", {
	name = "Reflect Damage",
	type = content.spells.TYPE.Spell,
	cost = math.floor(EFFECT_COST_REFLECT * 3.8), -- 20 * 3.8 = 76
	effects = {
		{
			id = "t_mysticism_reflectdmg",
			range = content.RANGE.Self,
			duration = 5,
			magnitudeMin = 10,
			magnitudeMax = 20,
		},
	},
})

-- Banish Daedra
defineSpell("t_com_mys_banishdaedra", {
	name = "Banish Daedra",
	type = content.spells.TYPE.Spell,
	cost = math.floor(EFFECT_COST_BANISH_DAE * 0.5), --128 * 0.5 = 64
	effects = {
		{
			id = "t_mysticism_banishdae",
			range = content.RANGE.Touch,
			duration = 1,
			magnitudeMin = 10,
			magnitudeMax = 10,
		},
	},
})

-- Resartus
defineSpell("t_com_res_armorresartus", {
	name = "Armor Resartus",
	type = content.spells.TYPE.Spell,
	cost = math.floor(EFFECT_COST_ARMOR_RESARTUS*1.5), -- 60 * 1.5 = 90
	effects = {
		{
			id = "t_restoration_armorresartus",
			range = content.RANGE.Self,
			duration = 1,
			magnitudeMin = 20,
			magnitudeMax = 40,
		},
	},
})

defineSpell("t_com_res_weaponresartus", {
	name = "Weapon Resartus",
	type = content.spells.TYPE.Spell,
	cost = math.floor(EFFECT_COST_WEAPON_RESARTUS * 0.75), -- 120 * 0.75 = 90
	effects = {
		{
			id = "t_restoration_weaponresartus",
			range = content.RANGE.Self,
			duration = 1,
			magnitudeMin = 10,
			magnitudeMax = 20,
		},
	},
})

-- Distract
defineSpell("t_com_ilu_distractcreature", {
	name = "Distract Creature",
	type = content.spells.TYPE.Spell,
	cost = math.floor(EFFECT_COST_DISTRACT_CREATURE * 22), -- 0.5 * 22 = 11
	effects = {
		{
			id = "t_illusion_distractcreature",
			range = content.RANGE.Target,
			duration = 15,
			magnitudeMin = 20,
			magnitudeMax = 20,
		},
	},
})

defineSpell("t_com_ilu_distracthumanoid", {
	name = "Distract Humanoid",
	type = content.spells.TYPE.Spell,
	cost = EFFECT_COST_DISTRACT_HUMANOID * 22, -- 1 * 22 = 22
	effects = {
		{
			id = "t_illusion_distracthumanoid",
			range = content.RANGE.Target,
			duration = 15,
			magnitudeMin = 20,
			magnitudeMax = 20,
		},
	},
})

-- =====================================================
-- ENCHANTMENT PATCHES
-- =====================================================

-- aliases
local CastOnce       = content.enchantments.TYPE.CastOnce
local ConstantEffect = content.enchantments.TYPE.ConstantEffect
local CastOnUse      = content.enchantments.TYPE.CastOnUse
local Self           = content.RANGE.Self
local Touch          = content.RANGE.Touch
local Target         = content.RANGE.Target

-- helper
local function eff(id, range, area, duration, magMin, magMax, attribute, skill)
	return {
		id = id:lower(),
		range = range,
		area = area,
		duration = duration,
		magnitudeMin = magMin,
		magnitudeMax = magMax,
		affectedAttribute = attribute,
		affectedSkill = skill,
	}
end

-- Vanilla bound -> scaled bound
local boundRemap = {
	boundbattleaxe = "t_bound_battleaxe",
	boundboots     = "t_bound_boots",
	boundcuirass   = "t_bound_cuirass",
	bounddagger    = "t_bound_dagger",
	boundgloves    = "t_bound_gloves",
	boundhelm      = "t_bound_helm",
	boundlongbow   = "t_bound_longbow",
	boundlongsword = "t_bound_longsword",
	boundmace      = "t_bound_mace",
	boundshield    = "t_bound_shield",
	boundspear     = "t_bound_spear",
}

-- =====================================================
-- ENCHANTMENTS
-- =====================================================
-- enchantment id, (1st effect id, attribute id, skill id), 1st range type, 1st area, 1st duration, 1st minimum magnitude, 1st maximum magnitude, 
-- scrolls
local enchantmentPatches = {
	-- scrolls
	["t_once_lordmhasfortress"] = { type = CastOnce, effects = { -- Lord Mha's Fortress: full bound armor set + warhammer
			eff("BoundBoots",        Self, 0, 90, 1, 1),
			eff("t_bound_greaves",   Self, 0, 90, 1, 1),
			eff("BoundCuirass",      Self, 0, 90, 1, 1),
			eff("t_bound_pauldrons", Self, 0, 90, 1, 1),
			eff("BoundGloves",       Self, 0, 90, 1, 1),
			eff("BoundHelm",         Self, 0, 90, 1, 1),
			eff("BoundShield",       Self, 0, 90, 1, 1),
			eff("t_bound_warhammer", Self, 0, 90, 1, 1),
		},
	},
	["t_once_moathauthority"] = { -- Moath's Authority
		type = CastOnce,
		effects = {
			eff("BoundBoots",         Self, 0, 90, 1, 1),
			eff("t_bound_greaves",    Self, 0, 90, 1, 1),
			eff("BoundGloves",        Self, 0, 90, 1, 1),
			eff("t_bound_greatsword", Self, 0, 90, 1, 1),
		},
	},
	-- 60s summons	
	["t_once_summondremoraarcher60"] = { type = CastOnce, effects = { eff("t_summon_dremarch", Self, 0, 60, 1, 1) }, }, -- Scroll of Dagon's Door
	["t_once_summondremoracaster60"] = { type = CastOnce, effects = { eff("t_summon_dremcast", Self, 0, 60, 1, 1) }, }, -- Scroll of Dagon's Door
	["t_once_summonguardian60"] = { type = CastOnce, effects = { eff("t_summon_guardian", Self, 0, 60, 1, 1) } }, -- Morningstar Scroll
	["t_once_summonlesserclannfear60"] = { type = CastOnce, effects = { eff("t_summon_lesserclfr", Self, 0, 60, 1, 1) } }, -- Hewer Scroll
	["t_once_summonogrim60"] = { type = CastOnce, effects = { eff("t_summon_ogrim", Self, 0, 60, 1, 1) } }, 
	["t_once_summonseducer60"] = { type = CastOnce, effects = { eff("t_summon_seducer", Self, 0, 60, 1, 1) } }, -- Voidguard Scroll
	["t_once_summonseducerdark60"] = { type = CastOnce, effects = { eff("t_summon_seducerdark", Self, 0, 60, 1, 1) } }, -- Bodyguard Scroll
	["t_once_summonvermai60"] = { type = CastOnce, effects = { eff("t_summon_vermai", Self, 0, 60, 1, 1) } },
	["t_once_summonstormmonarch60"] = { type = CastOnce, effects = { eff("t_summon_atrostormmon", Self, 0, 60, 1, 1) } }, -- Stormbound Scroll
	["t_once_summonwelkyndspirit60"] = { type = CastOnce, effects = { eff("t_summon_welkyndspirit", Self, 0, 60, 1, 1) } },
	["t_once_summonauroran60"] = { type = CastOnce, effects = { eff("t_summon_auroran", Self, 0, 60, 1, 1) } }, -- Sentry Scroll
	["t_once_summonherne60"] = { type = CastOnce, effects = { eff("t_summon_herne", Self, 0, 60, 1, 1) } }, -- Trapper Scroll
	["t_once_summonmorphoid60"] = { type = CastOnce, effects = { eff("t_summon_morphoid", Self, 0, 60, 1, 1) } },  -- Firebrand Scroll
	["t_once_summonbonelordgr60"] = { type = CastOnce, effects = { eff("t_summon_boneldgr", Self, 0, 60, 1, 1) }, }, -- Warder Scroll
	["t_once_summondremoraall60"] = { type = CastOnce, effects = { eff("summondremora", Self, 0, 60, 1, 1), eff("t_summon_dremarch", Self, 0, 60, 1, 1), eff("t_summon_dremcast", Self, 0, 60, 1, 1) }, }, -- Scroll of Dagon's Peerage
	["t_use_summonguardian60"] = { type = CastOnce, effects = { eff("t_summon_guardian", Self, 0, 60, 1, 1) }, },
	-- 120s summons
	["t_once_summonogrim120"] = { type = CastOnce, effects = { eff("t_summon_ogrim", Self, 0, 120, 1, 1) } }, -- Clanfather Scroll
	["t_once_summonvermai120"] = { type = CastOnce, effects = { eff("t_summon_vermai", Self, 0, 120, 1, 1) } }, -- Zenaida Nacarra's Scroll
	["t_once_summonskeletonchamp120"] = { type = CastOnce, effects = { eff("t_summon_skeletonchampion", Self, 0, 120, 1, 1) } }, -- Llaalam Tharen's Scroll
	["t_once_summonfrostmonarch120"] = { type = CastOnce, effects = { eff("t_summon_atrofrostmon", Self, 0, 120, 1, 1) } }, -- Almion Celmo's Scroll
	-- other summons
	["t_once_ayldaedricherald1"] = { type = CastOnce, effects = { eff("t_summon_welkyndspirit", Self, 0, 30, 1, 1) } }, -- Scroll of Spurred Incomers
	["t_once_ayldaedricherald2"] = { type = CastOnce, effects = { eff("t_summon_auroran", Self, 0, 30, 1, 1) } }, -- Scroll of Strange Incomers
	["t_once_ayllorearmor1"] = { type = CastOnce, effects = { eff("t_alteration_radshield", Self, 0, 30, 1, 1) } }, -- Scroll of Doctrine Panoply
	["t_once_boethiahservice"] = { type = CastOnce, effects = { eff("summonhunger", Self, 0, 120, 1, 1), eff("t_summon_devourer", Self, 0, 60, 1, 1) } }, -- Scroll of Boethiah's Service
	["t_once_fourarmsgoingup"] = { -- Scroll of Four Arms Going Up
		type = CastOnce, 
		effects = { 
			eff("summonscamp", Self, 0, 120, 1, 1),
			eff("summondremora", Self, 0, 120, 1, 1),
			eff("t_summon_morphoid", Self, 0, 120, 1, 1),
			eff("t_summon_herne", Self, 0, 120, 1, 1) 
		},
	},
	["t_once_anticipations"] = { -- Scroll of The Anticipations
	type = CastOnce,
	effects = {
		eff("summonwingedtwilight", Self, 0, 60, 1, 1),
		eff("t_summon_spiderdaedra", Self, 0, 60, 1, 1),
		eff("summonhunger", Self, 0, 60, 1, 1),
		eff("t_summon_herne", Self, 0, 120, 1, 1)
		},
	},
	["t_once_fourcorners"] = { -- Scroll of The Four Corners
		type = CastOnce, effects = {
			eff("summongoldensaint", Self, 0, 60, 1, 1),
			eff("summondremora", Self, 0, 60, 1, 1),
			eff("t_summon_ogrim", Self, 0, 60, 1, 1),
			eff("summondaedroth", Self, 0, 60, 1, 1) 
		},
	},
	-- mysticism
	["t_once_kynesintervention"] = { type = CastOnce, effects = { eff("t_intervention_kyne", Self, 0, 1, 1, 1) }, },
	["t_once_quelledgeas"] = { type = CastOnce, effects = { eff("t_mysticism_banishdae", Touch, 0, 1, 10, 15) }, }, -- Scroll of The Quelled Geas
	["t_once_daedrabane"] = { type = CastOnce, effects = { eff("t_mysticism_banishdae", Touch, 0, 1, 10, 15) }, },
	["t_once_blackspirits"] = { type = CastOnce, effects = { eff("t_mysticism_banishdae", Target, 25, 1, 10, 40) }, },
	["t_once_gramaryemirror"] = { type = CastOnce, effects = { eff("t_mysticism_reflectdmg", Self, 0, 30, 20, 20), eff("reflect", Self, 0, 30, 20, 20) }, },
	["t_once_dashing"] = { type = CastOnce, effects = { eff("t_mysticism_blink", Self, 0, 0, 40, 40) } },	
	["t_once_deificchrisom"] = { type = CastOnce, effects = { eff("t_mysticism_reflectdmg", Self, 0, 60, 10, 30), eff("spellAbsorption", Self, 0, 60, 10, 30), eff("sanctuary", Self, 0, 60, 10, 30) }, },
	["t_once_assassinrush"] = { type = CastOnce, effects = { eff("t_mysticism_blink", Self, 0, 0, 30, 30), eff("fortifyattack", Self, 0, 60, 10, 20), eff("fortifyskill", Self, 0, 120, 40, 40, nil, "shortblade")} },
	-- restoration
	["t_once_qorwynnmending"] = { type = CastOnce, effects = { eff("t_restoration_armorresartus", Self, 0, 0, 30, 30), eff("t_restoration_weaponresartus", Self, 0, 0, 30, 30) }, },
	["t_once_firmament"] = { type = CastOnce, effects = { eff("fortifyattack", Self, 0, 120, 40, 40), eff("t_restoration_fortifycasting", Self, 0, 120, 40, 40), eff("fortifyskill", Self, 0, 120, 40, 40, nil, "sneak")}, },
	-- illusion
	["t_once_diversion"] = { type = CastOnce, effects = { eff("t_illusion_distracthumanoid", Target, 0, 30, 10, 30) } },
	["t_once_scent"] = { type = CastOnce, effects = { eff("t_illusion_distractcreature", Target, 0, 30, 10, 30) } },
	["t_once_darothrildisorder"] = { type = CastOnce, effects = { eff("t_illusion_distractcreature", Target, 20, 20, 50, 50), eff("t_illusion_distracthumanoid", Target, 20, 20, 50, 50) } },	
	-- constant enchantments
	-- Finder's Charm - t_com_uni_finderscharm
	["t_const_finderscharm"] = { 
		type = ConstantEffect,
		charge = 0,
		cost = 0,
		effects = {
			eff("t_mysticism_insight", Self, 0, 1, 10, 10), -- increase duration
			eff("detectenchantment", Self, 0, 1, 120, 120),
			eff("detectkey", Self, 0, 1, 120, 120),
		},
	},
	-- Robe of Reprisal - t_de_uni_robe_reprisal
	["t_const_robe_reprisal"] = { 
		type = ConstantEffect,
		charge = 0,
		cost = 0,
		effects = {
			eff("frostshield", Self, 0, 1, 50, 50),
			eff("t_mysticism_reflectdmg", Self, 0, 1, 10, 10),		
		},
	},
	-- Onimaru - t_dae_uni_onimaru
	["t_const_onimaru_en"] = { 
		type = ConstantEffect,
		charge = 0,
		cost = 0,
		effects = {
			eff("fortifyattack", Self,0, 1, 10, 10),
			eff("resistmagicka", Self, 0, 1, 20, 20),
			eff("resistnormalweapons", Self, 0, 1, 20, 20),
			eff("t_mysticism_reflectdmg", Self, 0, 1, 20, 20),
			eff("summonDremora", Self, 0, 1, 1, 1),
		},
	},
	-- Amulet of Peerless Insight - pc_m1_amuletinsight (Project Cyrodiil)
	["t_const_nadiainsight"] = { 
		type = ConstantEffect,
		charge = 0,
		cost = 0,
		effects = {
			eff("t_mysticism_insight", Self, 0, 1, 30, 30),
		},
	},
	-- Guardian Ring - t_imp_uni_guardianring
	["t_use_guardianring"] = { 
		type = CastOnUse,
		charge = 0,
		cost = 0,
		effects = {
			eff("boundboots", Self, 0, 60, 1, 1),
			eff("t_bound_greaves", Self, 0, 60, 1, 1),
			eff("boundcuirass", Self, 0, 60, 1, 1),
			eff("t_bound_pauldrons", Self, 0, 60, 1, 1),
			eff("boundgloves", Self, 0, 60, 1, 1),
			eff("boundhelm", Self, 0, 60, 1, 1),
		},
	},
	-- artifacts --
	-- veloth's r pauldron: constant reflect damage 30pt on self
	["t_const_velothspauld_r"] = {
		type = ConstantEffect,
		charge = 0,
		cost = 0,
		effects = {
			eff("t_mysticism_reflectdmg", Self, 0, 1, 30, 30),
		},
	},
	-- right bracer of bifurcation, item id: t_imp_uni_bracerr_bifurication
	["t_const_spell_bifurcation"] = {
		type = ConstantEffect,
		charge = 0,
		cost = 0,
		effects = {
			eff("t_restoration_fortifycasting", Self, 0, 1, 20, 20),
		},
	},
	-- ring of namira, t_dae_uni_ring_namira_01
	["t_const_ring_namira"] = {
		type = ConstantEffect,
		charge = 0,
		cost = 0,
		effects = {
			{
				id = "t_mysticism_reflectdmg",
				range = Self,
				area = 0,
				duration = 1,
				magnitudeMin = 30,
				magnitudeMax = 30,
			},
			{
				id = "reflect",
				range = Self,
				area = 0,
				duration = 1,
				magnitudeMin = 30,
				magnitudeMax = 30,		
			},
		},
	},
--[[	-- veloth's staff
	["t_strike_staffveloth"] = {
		type = CastOnUse,
	--	charge = 900,
	--	cost = 300,
		effects = {
			{
				id = "t_destruction_gazeofveloth",
				range = Target,
				area = 0,
				duration = 1,
				magnitudeMin = 1,
				magnitudeMax = 1,
			},
		},
	},
	-- sanguine rose
	["tr_m1_sanguinesrose_en"] = {
		type = CastOnUse,
	--	charge = 480,
	--	cost = 96,
		effects = {
			{
				id = "t_use_sanguinerose",
				range = Self,
				area = 0,
				duration = 120,
				magnitudeMin = 1,
				magnitudeMax = 1,
			},
		},
	},
-- skull of corruption
	["t_use_skullofcorruption"] = {
		type = CastOnUse,
	--	charge = 900,
	--	cost = 300,
		effects = {
			{
				id = "t_conjuration_corruption",
				range = Target,
				area = 0,
				duration = 0,
				magnitudeMin = 1,
				magnitudeMax = 1,
			},
		},
	},
	-- wabbajack
	["t_use_wabbajackuni"] = {
		type = CastOnUse,
	--	charge = 900,
	--	cost = 300,
		effects = {
			{
				id = "t_alteration_wabbajack",
				range = Target,
				area = 0,
				duration = 1,
				magnitudeMin = 1,
				magnitudeMax = 1,
			},
		},
	},]]
}

-- apply enchantment patches
for id, patch in pairs(enchantmentPatches) do
	local orig = content.enchantments.records[id:lower()]
	if orig then
		local effects = patch.effects
		
		content.enchantments.records[id:lower()] = {
			type = patch.type,
			charge = orig.charge,
			cost = orig.cost,
			effects = effects,
		}
	end
end

-- =====================================================
-- SPELL TOMES
-- =====================================================

local tomeAssets = {
	alt = {
		icon = "icons/tr_spells/st_alteration.dds",
		mesh = "meshes/tr_spells/alteration_1.nif",
	},
	conj = {
		icon = "icons/tr_spells/st_conjuration.dds",
		mesh = "meshes/tr_spells/conjuration_1.nif",
	},
	ilu = {
		icon = "icons/tr_spells/st_illusion.dds",
		mesh = "meshes/tr_spells/illusion_1.nif",
	},
	rest = {
		icon = "icons/tr_spells/st_restoration.dds",
		mesh = "meshes/tr_spells/restoration_1.nif",
	},
	myst = {
		icon = "icons/tr_spells/st_mysticism.dds",
		mesh = "meshes/tr_spells/mysticism_1.nif",
	},
}

local function buildTomeText(tomeId)
	for _, tomeDef in ipairs(trData.TOME_DEFS) do
		if tomeDef.tomeId == tomeId then
			local lines = { "<p>This tome contains records of the following spells:<br><p>" }
			for _, spellId in ipairs(tomeDef.spells) do
				local spell = content.spells.records[spellId]
				if spell and spell.name then
					lines[#lines + 1] = "- " .. spell.name .. "<br>"
				end
			end
			return table.concat(lines, "")
		end
	end
	return ""
end

local function defineTome(id, name, school)
	local assets = tomeAssets[school]
	if not assets then return end
	content.books.records[id] = {
		name = name,
		model = assets.mesh,
		icon = assets.icon,
		weight = 0.2,
		value = 75,
		isScroll = false,
		text = buildTomeText(id),
	}
end

defineTome("spelltome_tr_conj_bound",  "Spell Tome: Bound",       "conj")
defineTome("spelltome_tr_conj_summon", "Spell Tome: Summon",      "conj")
defineTome("spelltome_tr_myst",        "Spell Tome: Mysticism",   "myst")
defineTome("spelltome_tr_rest",        "Spell Tome: Restoration", "rest")
defineTome("spelltome_tr_alt",         "Spell Tome: Alteration",  "alt")
defineTome("spelltome_tr_ilu",         "Spell Tome: Illusion",    "ilu")

-- =====================================================
-- BOUND ITEMS PATCH
-- =====================================================

if BOUND_VANILLA_PATCH then
	-- vanilla effect id -> scaled effect id
	local vanillaToScaled = {
		boundbattleaxe = "t_bound_battleaxe",
		boundboots     = "t_bound_boots",
		boundcuirass   = "t_bound_cuirass",
		bounddagger    = "t_bound_dagger",
		boundgloves    = "t_bound_gloves",
		boundhelm      = "t_bound_helm",
		boundlongbow   = "t_bound_longbow",
		boundlongsword = "t_bound_longsword",
		boundmace      = "t_bound_mace",
		boundshield    = "t_bound_shield",
		boundspear     = "t_bound_spear",
	}

	local function patchEffects(effects)
		if not effects then return nil end
		local changed = false
		local out = {}
		local i = 1
		while true do
			local e = effects[i]
			if e == nil then break end
			local mapped = e.id and vanillaToScaled[e.id:lower()]
			if mapped then changed = true end
			out[i] = {
				id                = mapped or e.id,
				range             = e.range,
				area              = e.area,
				duration          = e.duration,
				magnitudeMin      = e.magnitudeMin,
				magnitudeMax      = e.magnitudeMax,
				affectedAttribute = e.affectedAttribute,
				affectedSkill     = e.affectedSkill,
			}
			i = i + 1
		end
		if changed then return out end
		return nil
	end
	
	-- spells
	for id, rec in pairs(content.spells.records) do
		local patched = patchEffects(rec.effects)
		if patched then
			content.spells.records[id].effects = patched
		end
	end
	
	-- enchantments
	for id, rec in pairs(content.enchantments.records) do
		local patched = patchEffects(rec.effects)
		if patched then
			content.enchantments.records[id].effects = patched
		end
	end
	
	-- potions
	for id, rec in pairs(content.potions.records) do
		local patched = patchEffects(rec.effects)
		if patched then
			content.potions.records[id].effects  = patched
		end
	end
	
	-- ingredients
	for id, rec in pairs(content.ingredients.records) do
		local patched = patchEffects(rec.effects)
		if patched then
			content.ingredients.records[id].effects = patched
		end
	end
end

-- =====================================================
-- TESTING
-- =====================================================

defineSpell("t_test_boundarmor", {
	name = "Test: Bound Armor",
	type = content.spells.TYPE.Spell,
	cost = 0,
	effects = {
		{ id = BOUND_VANILLA_PATCH and "t_bound_boots" or "boundboots",     range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = BOUND_VANILLA_PATCH and "t_bound_cuirass" or "boundcuirass", range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = BOUND_VANILLA_PATCH and "t_bound_gloves" or "boundgloves",   range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = BOUND_VANILLA_PATCH and "t_bound_helm" or "boundhelm",       range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = BOUND_VANILLA_PATCH and "t_bound_shield" or "boundshield",   range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_bound_greaves",   range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_bound_pauldrons", range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
	},
})

defineSpell("t_test_summonall", {
	name = "Test: Summon All",
	type = content.spells.TYPE.Spell,
	cost = 0,
	effects = {
		{ id = "t_summon_devourer",         range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_dremarch",         range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_dremcast",         range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_guardian",         range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_lesserclfr",       range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_ogrim",            range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_seducer",          range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_seducerdark",      range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_vermai",           range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_atrostormmon",     range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_icewraith",        range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_dwespectre",       range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_steamcent",        range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		--{ id = "t_summon_spidercent",       range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_welkyndspirit",    range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_auroran",          range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_herne",            range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_morphoid",         range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_draugr",           range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_spriggan",         range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_boneldgr",         range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_ghost",            range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_wraith",           range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_barrowguard",      range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_minobarrowguard",  range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_skeletonchampion", range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_atrofrostmon",     range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
		{ id = "t_summon_spiderdaedra",     range = content.RANGE.Self, duration = 60, magnitudeMin = 1, magnitudeMax = 1 },
	},
})