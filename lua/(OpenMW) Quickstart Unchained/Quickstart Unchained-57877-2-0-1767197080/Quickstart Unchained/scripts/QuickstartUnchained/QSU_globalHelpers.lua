--[[	
	WEAPONS
	getBestWeaponSkill(player)					-> skillId, value
	getMatchingWeapons(skillId, minGold, maxGold) -> {records} (non-enchanted weapons in gold range)
	giveRandomWeapon(player)					  -> nil (weapon for best skill, 30-100g)
	
	ARMOR
	getArmorWeightClass(record)				 -> "lightarmor"|"mediumarmor"|"heavyarmor"|"unarmored" (uses GMSTs)
	getBestArmorSkill(player)				   -> skillId, value (lightarmor/mediumarmor/heavyarmor)
	getMatchingArmor(skillId, minGold, maxGold) -> {records} (non-enchanted armor in gold range)
	giveRandomArmor(player)					 -> bool (armor for best skill, 50-100g)
	
	MAGIC
	getSpellCost(spell)					  -> {cost, schools={school->cost}, calculatedCost, ...} (cached in spellDB)
	getSpellPrimarySchool(spell)			 -> schoolId (school with highest cost contribution)
	getBestMagicSkill(player)				-> skillId, value (alt/conj/dest/ill/myst/rest)
	getMatchingSpellTomes(schoolId, maxCost) -> {{tomeId, spellId, cost}, ...}
	giveRandomSpellTome(player)			  -> bool (tome for best school, cost < 40)
	
	ITEMS (skill-gated)
	giveLockpicks(player)	  -> bool (1-3 apprentice picks; Security >= 15, or 50% chance below)
	giveSoulGem(player)		-> bool (1-2 petty/lesser gems; Mysticism or Enchant >= 20)
	giveApparatus(player)	  -> bool (mortar/retort/alembic/calcinator; Alchemy >= 20)
	giveRepairHammer(player)   -> bool (Armorer >= 20)
	giveAmmo(player)		   -> bool (10-25 iron arrows; Marksman >= 20)
	
	ITEMS (no requirements)
	giveRandomGold(player)	 -> bool (35-139 gold)
	giveRandomAlcohol(player)  -> bool (liquor/brew/brandy/whiskey/moon sugar/skooma)
	giveFood(player)		   -> bool (bread/comberry/crab/hound/kwama/rat/scuttle/saltrice)
	giveJewelry(player)		-> bool (expensive rings/amulets)
	giveLight(player)		  -> bool (torch/candle/lantern)
	giveBook(player)		   -> bool (random non-scroll, non-deprecated book)
	
	ORCHESTRATOR
	getRandomItems(player)	 -> nil (gold + random assortment with varying chances)
]]

local DEBUG = false
local function log(msg)
	if DEBUG then print("[QSU] " .. msg) end
end

local weaponTypeToSkill = {
	[types.Weapon.TYPE.ShortBladeOneHand] = 'shortblade',
	[types.Weapon.TYPE.LongBladeOneHand] = 'longblade',
	[types.Weapon.TYPE.LongBladeTwoHand] = 'longblade',
	[types.Weapon.TYPE.BluntOneHand] = 'bluntweapon',
	[types.Weapon.TYPE.BluntTwoClose] = 'bluntweapon',
	[types.Weapon.TYPE.BluntTwoWide] = 'bluntweapon',
	[types.Weapon.TYPE.SpearTwoWide] = 'spear',
	[types.Weapon.TYPE.AxeOneHand] = 'axe',
	[types.Weapon.TYPE.AxeTwoHand] = 'axe',
	[types.Weapon.TYPE.MarksmanBow] = 'marksman',
	[types.Weapon.TYPE.MarksmanCrossbow] = 'marksman',
	[types.Weapon.TYPE.MarksmanThrown] = 'marksman',
}
local skillToWeaponTypes = {
	shortblade = { types.Weapon.TYPE.ShortBladeOneHand },
	longblade = { types.Weapon.TYPE.LongBladeOneHand, types.Weapon.TYPE.LongBladeTwoHand },
	bluntweapon = { types.Weapon.TYPE.BluntOneHand, types.Weapon.TYPE.BluntTwoClose, types.Weapon.TYPE.BluntTwoWide },
	spear = { types.Weapon.TYPE.SpearTwoWide },
	axe = { types.Weapon.TYPE.AxeOneHand, types.Weapon.TYPE.AxeTwoHand },
	marksman = { types.Weapon.TYPE.MarksmanBow, types.Weapon.TYPE.MarksmanCrossbow, types.Weapon.TYPE.MarksmanThrown },
}
local weaponSkills = { 'shortblade', 'longblade', 'bluntweapon', 'spear', 'axe', 'marksman' }
function getBestWeaponSkill(player)
	local bestSkill = nil
	local bestValue = -1
	for _, skillId in ipairs(weaponSkills) do
		local skillStat = types.NPC.stats.skills[skillId](player)
		local value = skillStat.modified
		if value > bestValue then
			bestValue = value
			bestSkill = skillId
		end
	end
	return bestSkill, bestValue
end
function getMatchingWeapons(skillId, minValue, maxValue)
	local validTypes = skillToWeaponTypes[skillId]
	if not validTypes then
		return {}
	end
	local validTypeSet = {}
	for _, wtype in ipairs(validTypes) do
		validTypeSet[wtype] = true
	end
	local matchingWeapons = {}
	for _, record in pairs(types.Weapon.records) do
		if validTypeSet[record.type] then
			if record.value >= minValue and record.value <= maxValue and not record.enchant then
				table.insert(matchingWeapons, record)
			end
		end
	end
	return matchingWeapons
end
function giveRandomWeapon(player)
	if not player then
		log("[RandomWeaponGift] Error: Player not found")
		return
	end
	local bestSkill, skillValue = getBestWeaponSkill(player)
	if not bestSkill then
		log("[RandomWeaponGift] Error: Could not determine best weapon skill")
		return
	end
	log("[RandomWeaponGift] Best weapon skill: " .. bestSkill .. " (" .. skillValue .. ")")
	local weapons = getMatchingWeapons(bestSkill, 30, 100)
	if #weapons == 0 then
		log("[RandomWeaponGift] No weapons found matching criteria")
		return
	end
	log("[RandomWeaponGift] Found " .. #weapons .. " matching weapons")
	local randomIndex = math.random(1, #weapons)
	local chosenWeapon = weapons[randomIndex]
	local item = world.createObject(chosenWeapon.id, 1)
	item:moveInto(types.Actor.inventory(player))
	local message = "Received: " .. chosenWeapon.name .. " (" .. chosenWeapon.value .. "g)"
	log("[RandomWeaponGift] " .. message)
end

local armorSkills = { 'lightarmor', 'mediumarmor', 'heavyarmor' }
function getArmorWeightClass(record)
	local recordType = record.type
	local referenceWeight = 0
	if recordType == types.Armor.TYPE.Boots then
		referenceWeight = core.getGMST("iBootsWeight")
	elseif recordType == types.Armor.TYPE.Cuirass then
		referenceWeight = core.getGMST("iCuirassWeight")
	elseif recordType == types.Armor.TYPE.Greaves then
		referenceWeight = core.getGMST("iGreavesWeight")
	elseif recordType == types.Armor.TYPE.Helmet then
		referenceWeight = core.getGMST("iHelmWeight")
	elseif recordType == types.Armor.TYPE.LBracer or recordType == types.Armor.TYPE.RBracer then
		referenceWeight = core.getGMST("iGauntletWeight")
	elseif recordType == types.Armor.TYPE.LPauldron or recordType == types.Armor.TYPE.RPauldron then
		referenceWeight = core.getGMST("iPauldronWeight")
	elseif recordType == types.Armor.TYPE.LGauntlet or recordType == types.Armor.TYPE.RGauntlet then
		referenceWeight = core.getGMST("iGauntletWeight")
	elseif recordType == types.Armor.TYPE.Shield then
		referenceWeight = core.getGMST("iShieldWeight")
	end
	local epsilon = 5e-4
	if record.weight == 0 then
		return "unarmored"
	elseif record.weight <= referenceWeight * core.getGMST("fLightMaxMod") + epsilon then
		return "lightarmor"
	elseif record.weight <= referenceWeight * core.getGMST("fMedMaxMod") + epsilon then
		return "mediumarmor"
	else
		return "heavyarmor"
	end
end
function getBestArmorSkill(player)
	local bestSkill = nil
	local bestValue = -1
	for _, skillId in ipairs(armorSkills) do
		local skillStat = types.NPC.stats.skills[skillId](player)
		local value = skillStat.modified
		if value > bestValue then
			bestValue = value
			bestSkill = skillId
		end
	end
	return bestSkill, bestValue
end
function getMatchingArmor(skillId, minValue, maxValue)
	local matchingArmor = {}
	for _, record in pairs(types.Armor.records) do
		local weightClass = getArmorWeightClass(record)
		if weightClass == skillId then
			if record.value >= minValue and record.value <= maxValue and not record.enchant then
				table.insert(matchingArmor, record)
			end
		end
	end
	return matchingArmor
end
function giveRandomArmor(player)
	if not player then
		log("[RandomArmor] Error: Player not found")
		return false
	end
	local bestSkill, skillValue = getBestArmorSkill(player)
	if not bestSkill then
		log("[RandomArmor] Error: Could not determine best armor skill")
		return false
	end
	log("[RandomArmor] Best armor skill: " .. bestSkill .. " (" .. skillValue .. ")")
	local armor = getMatchingArmor(bestSkill, 50, 100)
	if #armor == 0 then
		log("[RandomArmor] No armor found matching criteria")
		return false
	end
	log("[RandomArmor] Found " .. #armor .. " matching armor pieces")
	local chosen = armor[math.random(1, #armor)]
	local item = world.createObject(chosen.id, 1)
	item:moveInto(types.Actor.inventory(player))
	log("[RandomArmor] Gave: " .. chosen.name .. " (" .. chosen.value .. "g)")
	return true
end



local spellTomes = {
	["spelltome_alt_lev_g1"] = "great levitate",
	["spelltome_alt_lev_s"] = "Strong Levitate",
	["spelltome_alt_lev_w"] = "Wild Levitate",
	["spelltome_alt_shield_fi_f"] = "fierce fire shield",
	["spelltome_alt_shield_fr_f"] = "fierce frost shield",
	["spelltome_alteration_burden_1"] = "Burden",
	["spelltome_alteration_burden_c1"] = "Crushing Burden",
	["spelltome_alteration_burden_cs1"] = "Crushing Burden of Sin",
	["spelltome_alteration_burden_ct1"] = "Crushing Burden Touch",
	["spelltome_alteration_burden_h1"] = "Heavy Burden",
	["spelltome_alteration_burden_ht1"] = "Heavy Burden Touch",
	["spelltome_alteration_feather_1"] = "Feather",
	["spelltome_alteration_feather_g1"] = "Great Feather",
	["spelltome_alteration_feather_uj"] = "Ulms Juicedaw's Feather",
	["spelltome_alteration_jump_th1"] = "Tinur's Hoptoad",
	["spelltome_alteration_levitate_1"] = "Levitate",
	["spelltome_alteration_lock_fd1"] = "Fenrick's Doorjam",
	["spelltome_alteration_open_1"] = "Open",
	["spelltome_alteration_open_g1"] = "great open",
	["spelltome_alteration_open_ood1"] = "Ondusi's Open Door",
	["spelltome_alteration_open_w1"] = "Wild Open",
	["spelltome_alteration_sf_1"] = "Slowfall",
	["spelltome_alteration_shield"] = "Shield",
	["spelltome_alteration_shield_1"] = "First Barrier",
	["spelltome_alteration_shield_2"] = "Second Barrier",
	["spelltome_alteration_shield_3"] = "Third Barrier",
	["spelltome_alteration_shield_4"] = "Fourth Barrier",
	["spelltome_alteration_shield_5"] = "Fifth Barrier",
	["spelltome_alteration_shield_6"] = "Sixth Barrier",
	["spelltome_alteration_shield_fi1"] = "Fire Barrier",
	["spelltome_alteration_shield_fi2"] = "Fire Shield",
	["spelltome_alteration_shield_fi3"] = "Strong Fire Shield",
	["spelltome_alteration_shield_fr1"] = "Frost Barrier",
	["spelltome_alteration_shield_fr2"] = "frost_shield",
	["spelltome_alteration_shield_fr3"] = "Strong Frost Shield",
	["spelltome_alteration_shield_sh1"] = "Shock Barrier",
	["spelltome_alteration_shield_sh2"] = "Lightning Shield",
	["spelltome_alteration_shield_sh3"] = "Strong Shock Shield",
	["spelltome_alteration_shield_shf"] = "fierce shock shield",
	["spelltome_alteration_ss_1"] = "Buoyancy",
	["spelltome_alteration_ss_sb"] = "Swimmer's_Blessing",
	["spelltome_alteration_wb_1"] = "Water Breathing",
	["spelltome_alteration_wb_vk"] = "Vivec's Kiss",
	["spelltome_alteration_weary_1"] = "weary",
	["spelltome_alteration_weary_d1"] = "dire weary",
	["spelltome_alteration_ww_1"] = "water walking",
	["spelltome_conj_ba_bb"] = "bound boots",
	["spelltome_conj_ba_bc"] = "bound cuirass",
	["spelltome_conj_ba_bg"] = "bound gauntlets",
	["spelltome_conj_ba_bh"] = "bound helm",
	["spelltome_conj_ba_bs"] = "bound shield",
	["spelltome_conj_bw_ba"] = "bound battle-axe",
	["spelltome_conj_bw_bd"] = "bound dagger",
	["spelltome_conj_bw_blb"] = "bound longbow",
	["spelltome_conj_bw_bls"] = "bound longsword",
	["spelltome_conj_bw_bm"] = "bound mace",
	["spelltome_conj_bw_bsp"] = "bound spear",
	["spelltome_conj_ccr_1"] = "command creature",
	["spelltome_conj_ch_1"] = "command humanoid",
	["spelltome_conj_ch_t1"] = "commanding touch",
	["spelltome_conj_summon_ag_1"] = "summon ancestral ghost",
	["spelltome_conj_summon_bl_1"] = "summon bonelord",
	["spelltome_conj_summon_cb_1"] = "BM_summonbear",
	["spelltome_conj_summon_cf_1"] = "summon clanfear",
	["spelltome_conj_summon_cs_1"] = "summon_centurion_unique",
	["spelltome_conj_summon_cw_1"] = "BM_summonwolf",
	["spelltome_conj_summon_dd_1"] = "summon daedroth",
	["spelltome_conj_summon_dm_1"] = "summon dremora",
	["spelltome_conj_summon_fla_1"] = "summon flame atronach",
	["spelltome_conj_summon_fra_1"] = "summon frost atronach",
	["spelltome_conj_summon_gbw_1"] = "summon greater bonewalker",
	["spelltome_conj_summon_gs_1"] = "summon golden saint",
	["spelltome_conj_summon_h_1"] = "summon hunger",
	["spelltome_conj_summon_lbw_1"] = "summon least bonewalker",
	["spelltome_conj_summon_s_1"] = "summon scamp",
	["spelltome_conj_summon_sm_1"] = "summon skeletal minion",
	["spelltome_conj_summon_sta_1"] = "summon storm atronach",
	["spelltome_conj_summon_wt_1"] = "summon winged twilight",
	["spelltome_conj_tu_1"] = "holy word",
	["spelltome_conj_tu_2"] = "saintly word",
	["spelltome_conj_tu_t1"] = "turn undead",
	["spelltome_conj_tu_t2"] = "holy touch",
	["spelltome_conj_tu_t3"] = "saintly touch",
	["spelltome_conj_tu_t4"] = "blessed touch",
	["spelltome_dest_dis_a"] = "Armor Eater",
	["spelltome_dest_dis_w"] = "weapon eater",
	["spelltome_dest_dmg_a_L"] = "hex",
	["spelltome_dest_dmg_a_a"] = "stumble",
	["spelltome_dest_dmg_a_e"] = "emasculate",
	["spelltome_dest_dmg_a_i"] = "fuddle",
	["spelltome_dest_dmg_a_p"] = "evil eye",
	["spelltome_dest_dmg_a_s"] = "clench",
	["spelltome_dest_dmg_a_w"] = "woe",
	["spelltome_dest_dmg_f_1"] = "fleabite",
	["spelltome_dest_dmg_f_2"] = "doze",
	["spelltome_dest_dmg_f_3"] = "hornhand",
	["spelltome_dest_dmg_f_bc"] = "blood curse: fatigue",
	["spelltome_dest_dmg_h_bh"] = "black hand",
	["spelltome_dest_dmg_h_sh"] = "stormhand",
	["spelltome_dest_dmg_h_t1"] = "spirit knife",
	["spelltome_dest_dmg_h_t2"] = "heartbite",
	["spelltome_dest_dmg_h_t3"] = "daedric bite",
	["spelltome_dest_dmg_m"] = "soulpinch",
	["spelltome_dest_dra_a_t1"] = "clumsy touch",
	["spelltome_dest_dra_e"] = "enervate",
	["spelltome_dest_dra_f1"] = "sleep",
	["spelltome_dest_dra_f2"] = "wild exhaustion",
	["spelltome_dest_dra_f_t1"] = "wearying touch",
	["spelltome_dest_dra_f_t2"] = "ordeal of st. olms",
	["spelltome_dest_dra_h_db"] = "drain blood",
	["spelltome_dest_dra_i1"] = "distraction",
	["spelltome_dest_dra_i2"] = "wild distraction",
	["spelltome_dest_dra_i_t1"] = "distracting touch",
	["spelltome_dest_dra_m1"] = "wild flay spirit",
	["spelltome_dest_dra_m2"] = "gash spirit [ranged]",
	["spelltome_dest_dra_m_t1"] = "gash spirit",
	["spelltome_dest_dra_m_t2"] = "magicka leech",
	["spelltome_dest_dra_m_t3"] = "flay spirit",
	["spelltome_dest_dra_p"] = "spite",
	["spelltome_dest_dra_skill_a"] = "drain athletics",
	["spelltome_dest_dra_skill_alch"] = "drain alchemy",
	["spelltome_dest_dra_skill_alt"] = "drain alteration",
	["spelltome_dest_dra_skill_b"] = "drain block",
	["spelltome_dest_dra_skill_conj"] = "drain conjuration",
	["spelltome_dest_dra_skill_d"] = "drain destruction",
	["spelltome_dest_dra_skill_ill"] = "drain illusion",
	["spelltome_dest_dra_skill_myst"] = "drain athletics",
	["spelltome_dest_dra_skill_rest"] = "drain restoration",
	["spelltome_dest_dra_skill_sb"] = "scourge blade",
	["spelltome_dest_dra_skill_ua"] = "drain unarmored",
	["spelltome_dest_dra_sp"] = "torpor",
	["spelltome_dest_dra_str_t1"] = "strength leech",
	["spelltome_dest_dra_w1"] = "temptation",
	["spelltome_dest_dra_w2"] = "blood despair",
	["spelltome_dest_fire1"] = "fireball",
	["spelltome_dest_fire2"] = "cruel firebloom",
	["spelltome_dest_fire3"] = "Fireball_large",
	["spelltome_dest_fire4"] = "fire storm",
	["spelltome_dest_fire5"] = "god's fire",
	["spelltome_dest_fire_t1"] = "fire bite",
	["spelltome_dest_frost1"] = "Frostball_large",
	["spelltome_dest_frost2"] = "frost storm",
	["spelltome_dest_frost3"] = "god's frost",
	["spelltome_dest_frost_t1"] = "Frostbite",
	["spelltome_dest_poison1"] = "poison",
	["spelltome_dest_poison2"] = "poisonbloom",
	["spelltome_dest_poison3"] = "viperbolt",
	["spelltome_dest_poison4"] = "poison_powerful",
	["spelltome_dest_poison_t1"] = "poisonous touch",
	["spelltome_dest_poison_t2"] = "deadly poison",
	["spelltome_dest_poison_t3"] = "potent poison",
	["spelltome_dest_shock1"] = "spark",
	["spelltome_dest_shock2"] = "shockball",
	["spelltome_dest_shock3"] = "lightning bolt",
	["spelltome_dest_shock4"] = "lightning storm",
	["spelltome_dest_shock5"] = "shockbloom",
	["spelltome_dest_shock_ds"] = "shockball_large",
	["spelltome_dest_shock_t1"] = "shock",
	["spelltome_dest_weak_cd"] = "weakness to common disease",
	["spelltome_dest_weak_fire1"] = "weakness to fire",
	["spelltome_dest_weak_fire2"] = "dire weakness to fire",
	["spelltome_dest_weak_frost"] = "dire weakness to frost",
	["spelltome_dest_weak_mag"] = "dire weakness to magicka",
	["spelltome_dest_weak_pois"] = "dire weakness to poison",
	["spelltome_dest_weak_shock"] = "dire weakness to shock",
	["spelltome_ill_blind1"] = "crying eye",
	["spelltome_ill_blind_t1"] = "erelvam's wild sty",
	["spelltome_ill_blind_t2"] = "alad's caliginy",
	["spelltome_ill_calm_cr"] = "calm creature",
	["spelltome_ill_calm_hum"] = "calm humanoid",
	["spelltome_ill_calm_hum_t1"] = "calming touch",
	["spelltome_ill_cham1"] = "chameleon",
	["spelltome_ill_cham2"] = "golanar's eye-maze",
	["spelltome_ill_cham3"] = "shadow form",
	["spelltome_ill_cham4"] = "shadowmask",
	["spelltome_ill_cham_mephala"] = "SkillMephala_SP",
	["spelltome_ill_cham_sw"] = "shadow weave",
	["spelltome_ill_charm"] = "charm mortal",
	["spelltome_ill_charm_t1"] = "charming touch",
	["spelltome_ill_dem_cr"] = "demoralize creature",
	["spelltome_ill_dem_hum"] = "demoralize humanoid",
	["spelltome_ill_dem_hum_t1"] = "demoralizing touch",
	["spelltome_ill_frenzy_cr"] = "frenzy creature",
	["spelltome_ill_frenzy_cr_t1"] = "frenzy beast",
	["spelltome_ill_frenzy_h_t1"] = "frenzying touch",
	["spelltome_ill_invis1"] = "brevusa's averted eyes",
	["spelltome_ill_invis2"] = "invisibility",
	["spelltome_ill_invis3"] = "concealment",
	["spelltome_ill_light"] = "light",
	["spelltome_ill_nighteye"] = "night-eye",
	["spelltome_ill_paralysis1"] = "paralysis",
	["spelltome_ill_paralysis2"] = "medusa's gaze",
	["spelltome_ill_paralysis_wr"] = "wizard rend",
	["spelltome_ill_rally_cr"] = "rally creature",
	["spelltome_ill_rally_hum"] = "rally humanoid",
	["spelltome_ill_rally_hum_t1"] = "rallying touch",
	["spelltome_ill_sanc1"] = "sanctuary",
	["spelltome_ill_sanc2"] = "sotha's grace",
	["spelltome_ill_sanc3"] = "father's hand",
	["spelltome_ill_sil1"] = "silence",
	["spelltome_ill_sil2"] = "far silence",
	["spelltome_ill_sound1"] = "earwig",
	["spelltome_ill_sound2"] = "dire earwig",
	["spelltome_ill_sound3"] = "wild earwig",
	["spelltome_ill_sound4"] = "dire noise",
	["spelltome_ill_sound_t1"] = "cruel noise",
	["spelltome_myst_aa_L"] = "absorb luck",
	["spelltome_myst_aa_ag"] = "absorb agility",
	["spelltome_myst_aa_e"] = "absorb endurance",
	["spelltome_myst_aa_i"] = "absorb intelligence",
	["spelltome_myst_aa_p"] = "absorb personality",
	["spelltome_myst_aa_sp"] = "absorb speed [ranged]",
	["spelltome_myst_aa_sp_t1"] = "absorb speed",
	["spelltome_myst_aa_str"] = "absorb strength",
	["spelltome_myst_aa_w"] = "crimson despair",
	["spelltome_myst_aa_w_t1"] = "absorb willpower",
	["spelltome_myst_af"] = "absorb fatigue [ranged]",
	["spelltome_myst_af_t1"] = "absorb fatigue",
	["spelltome_myst_af_t2"] = "energy leech",
	["spelltome_myst_ah_t1"] = "righteousness",
	["spelltome_myst_ah_t2"] = "absorb health",
	["spelltome_myst_ah_v"] = "Vampire Touch",
	["spelltome_myst_almsint"] = "almsivi intervention",
	["spelltome_myst_detect_creature"] = "detect_creature",
	["spelltome_myst_detect_enchant"] = "detect enchantment",
	["spelltome_myst_detect_key1"] = "tevral's hawkshaw",
	["spelltome_myst_detect_key2"] = "detect_key",
	["spelltome_myst_disp_1"] = "purge magic",
	["spelltome_myst_disp_s1"] = "almalexia's grace",
	["spelltome_myst_disp_s2"] = "dispel",
	["spelltome_myst_divint"] = "divine intervention",
	["spelltome_myst_mark"] = "mark",
	["spelltome_myst_recall"] = "recall",
	["spelltome_myst_reflect1"] = "sotha's mirror",
	["spelltome_myst_reflect2"] = "reflect",
	["spelltome_myst_reflect3"] = "strong reflect",
	["spelltome_myst_reflect4"] = "shalidor's mirror",
	["spelltome_myst_reflect5"] = "wild reflect",
	["spelltome_myst_reflect6"] = "llivam's reversal",
	["spelltome_myst_sa1"] = "spell absorption",
	["spelltome_myst_sa2"] = "vivec's feast",
	["spelltome_myst_sa3"] = "weak spelldrinker",
	["spelltome_myst_sa4"] = "wild spelldrinker",
	["spelltome_myst_sa5"] = "strong spelldrinker",
	["spelltome_myst_sa6"] = "tranasa's spelltrap",
	["spelltome_myst_st"] = "soul trap",
	["spelltome_myst_tks"] = "telekinesis",
	["spelltome_rest_cure_bd_aryon"] = "cure_blight_target",
	["spelltome_rest_cure_bd_p"] = "panacea",
	["spelltome_rest_cure_bd_rg"] = "rilm's gift",
	["spelltome_rest_cure_bd_s1"] = "Cure Blight Disease",
	["spelltome_rest_cure_bd_s2"] = "vivec's tears",
	["spelltome_rest_cure_bd_vt"] = "HealingTouch_SP_uniq",
	["spelltome_rest_cure_cd"] = "cure common disease victim",
	["spelltome_rest_cure_cd_s1"] = "cure common disease",
	["spelltome_rest_cure_cd_s2"] = "rilm's cure",
	["spelltome_rest_cure_cd_t1"] = "cure common disease other",
	["spelltome_rest_cure_p_s1"] = "Balyna's Antidote",
	["spelltome_rest_cure_p_s2"] = "cure poison",
	["spelltome_rest_cure_p_t1"] = "seryn's gift",
	["spelltome_rest_cure_para_s"] = "free action",
	["spelltome_rest_fort_a_L_s1"] = "turn of the wheel",
	["spelltome_rest_fort_a_L_s2"] = "jack of trades",
	["spelltome_rest_fort_a_a_s1"] = "nimbleness",
	["spelltome_rest_fort_a_da"] = "divine aid",
	["spelltome_rest_fort_a_e_s1"] = "fortitude",
	["spelltome_rest_fort_a_i_s1"] = "wisdom",
	["spelltome_rest_fort_a_p_s1"] = "charisma",
	["spelltome_rest_fort_a_p_s2"] = "Zenithar_gospel",
	["spelltome_rest_fort_a_sp_s1"] = "Quicksilver",
	["spelltome_rest_fort_a_sp_s2"] = "feet of notorgo",
	["spelltome_rest_fort_a_str_s1"] = "Troll Strength",
	["spelltome_rest_fort_a_str_s2"] = "orc's strength",
	["spelltome_rest_fort_a_w_s1"] = "iron will",
	["spelltome_rest_fort_a_w_s2"] = "daedric willpower",
	["spelltome_rest_fort_f_s1"] = "enrichment",
	["spelltome_rest_fort_f_s2"] = "daedric fatigue",
	["spelltome_rest_fort_h_s1"] = "vitality",
	["spelltome_rest_fort_h_s2"] = "blood gift",
	["spelltome_rest_fort_h_s3"] = "daedric health",
	["spelltome_rest_fort_m_s1"] = "powerwell",
	["spelltome_rest_fort_skill_alch"] = "masterful sublime wisdom",
	["spelltome_rest_fort_skill_alt"] = "masterful golden wisdom",
	["spelltome_rest_fort_skill_conj"] = "Masterful Transcendant Wisdom",
	["spelltome_rest_fort_skill_dest"] = "Masterful Red Wisdom",
	["spelltome_rest_fort_skill_ill"] = "masterful silver wisdom",
	["spelltome_rest_fort_skill_myst"] = "masterful unseen wisdom",
	["spelltome_rest_fort_skill_rest"] = "masterful green wisdom",
	["spelltome_rest_fort_skill_ua"] = "masterful fluid evasion",
	["spelltome_rest_resist_bd_s1"] = "poet's whim",
	["spelltome_rest_resist_bd_s2"] = "vivec's mercy",
	["spelltome_rest_resist_bd_s3"] = "shield of the armiger",
	["spelltome_rest_resist_cd_s1"] = "resist common disease",
	["spelltome_rest_resist_cd_s2"] = "variable resist common disease",
	["spelltome_rest_resist_cd_s3"] = "seryn's blessing",
	["spelltome_rest_resist_cd_s4"] = "great resist common disease",
	["spelltome_rest_resist_corp_s1"] = "variable resist corpus disease",
	["spelltome_rest_resist_corp_s2"] = "strong resist corprus disease",
	["spelltome_rest_resist_corp_s3"] = "great resist corprus disease",
	["spelltome_rest_resist_fi_s1"] = "resist fire",
	["spelltome_rest_resist_fi_s2"] = "variable resist fire",
	["spelltome_rest_resist_fi_s3"] = "strong resist fire",
	["spelltome_rest_resist_fi_s4"] = "great resist fire",
	["spelltome_rest_resist_fi_s5"] = "flameguard",
	["spelltome_rest_resist_fr_s1"] = "resist frost",
	["spelltome_rest_resist_fr_s2"] = "variable resist frost",
	["spelltome_rest_resist_fr_s3"] = "strong resist frost",
	["spelltome_rest_resist_fr_s4"] = "great resist frost",
	["spelltome_rest_resist_fr_s5"] = "frostguard",
	["spelltome_rest_resist_mag_s1"] = "resist magicka",
	["spelltome_rest_resist_mag_s2"] = "variable resist magicka",
	["spelltome_rest_resist_mag_s3"] = "strong resist magicka",
	["spelltome_rest_resist_mag_s4"] = "great resist magicka",
	["spelltome_rest_resist_mag_s5"] = "magickguard",
	["spelltome_rest_resist_para"] = "resist paralysis",
	["spelltome_rest_resist_pois_s1"] = "resist poison",
	["spelltome_rest_resist_pois_s2"] = "variable resist poison",
	["spelltome_rest_resist_pois_s3"] = "strong resist poison",
	["spelltome_rest_resist_pois_s4"] = "greater resist poison",
	["spelltome_rest_resist_pois_s5"] = "poisonguard",
	["spelltome_rest_resist_sh_s1"] = "resist shock",
	["spelltome_rest_resist_sh_s2"] = "variable resist shock",
	["spelltome_rest_resist_sh_s3"] = "strong resist shock",
	["spelltome_rest_resist_sh_s4"] = "shockguard",
	["spelltome_rest_restore_a_L"] = "restore luck",
	["spelltome_rest_restore_a_a"] = "restore agility",
	["spelltome_rest_restore_a_e"] = "restore endurance",
	["spelltome_rest_restore_a_i"] = "restore intelligence",
	["spelltome_rest_restore_a_p"] = "restore personality",
	["spelltome_rest_restore_a_sp"] = "restore speed",
	["spelltome_rest_restore_a_str"] = "restore strength",
	["spelltome_rest_restore_a_w"] = "restore willpower",
	["spelltome_rest_restore_f_s1"] = "rest of st. merris",
	["spelltome_rest_restore_f_s2"] = "stamina",
	["spelltome_rest_restore_h_s"] = "hearth heal",
	["spelltome_rest_restore_h_s1"] = "balyna's soothing balm",
	["spelltome_rest_restore_h_s2"] = "balyna's efficacious balm",
	["spelltome_rest_restore_h_s3"] = "veloth's benison",
	["spelltome_rest_restore_h_s4"] = "balyna's perfect balm",
	["spelltome_rest_restore_h_s5"] = "mother's kiss",
	["spelltome_rest_restore_h_s6"] = "veloth's grace",
	["spelltome_rest_restore_h_s7"] = "regenerate",
	["spelltome_rest_restore_h_s8"] = "rapid regenerate",
	["spelltome_rest_restore_h_t1"] = "heal companion",
}
local magicSkills = { 'alteration', 'conjuration', 'destruction', 'illusion', 'mysticism', 'restoration' }
local spellDB = {}
function getSpellCost(spell)
	local spellId = spell.id
	if not spellDB[spellId] then
		spellDB[spellId] = {}
		local s = spellDB[spellId]
		s.schools = {}
		s.calculatedCost = 0
		s.autoCalculated = spell.autocalcFlag
		s.isSpell = spell.type == core.magic.SPELL_TYPE.Spell
		local playerSpell = spellId:sub(1,9) == "Generated"
		for _,effect in pairs(spell.effects) do
			local school = effect.effect.school
			local hasMagnitude = effect.effect.hasMagnitude
			local hasDuration = effect.effect.hasDuration
			local appliedOnce = effect.effect.isAppliedOnce
			local minMagn = hasMagnitude and effect.magnitudeMin or 1
			local maxMagn = hasMagnitude and effect.magnitudeMax or 1
			minMagn = math.max(1, minMagn)
			maxMagn = math.max(1, maxMagn)
			local duration = hasDuration and effect.duration or 1
			if not appliedOnce then
				duration = math.max(1, duration)
			end
			local fEffectCostMult = core.getGMST("fEffectCostMult")
			local durationOffset = 0
			local minArea = 0
			if playerSpell then
				durationOffset = 1
				minArea = 1
			end
			local x = 0.5 * (minMagn + maxMagn)
			x = x * (0.1 * effect.effect.baseCost)
			x = x * (durationOffset + duration)
			x = x + (0.05 * math.max(minArea, effect.area) * effect.effect.baseCost)
			x = x * fEffectCostMult
			if effect.range == core.magic.RANGE.Target then
				x = x * 1.5
			end
			x = math.max(0, x)
			s.schools[school] = (s.schools[school] or 0) + x
			s.calculatedCost = s.calculatedCost + x
		end
		if spell.autocalcFlag then
			s.cost = math.floor(s.calculatedCost + 0.5)
		else
			s.cost = math.floor(spell.cost + 0.5)
		end
	end
	return spellDB[spellId]
end
function getSpellPrimarySchool(spell)
	local spellInfo = getSpellCost(spell)
	local bestSchool = nil
	local bestCost = -1
	for school, cost in pairs(spellInfo.schools) do
		if cost > bestCost then
			bestCost = cost
			bestSchool = school
		end
	end
	return bestSchool
end
function getBestMagicSkill(player)
	local bestSkill = nil
	local bestValue = -1
	for _, skillId in ipairs(magicSkills) do
		local skillStat = types.NPC.stats.skills[skillId](player)
		local value = skillStat.modified
		if value > bestValue then
			bestValue = value
			bestSkill = skillId
		end
	end
	return bestSkill, bestValue
end

function getMatchingSpellTomes(schoolId, maxCost)
	local matchingTomes = {}
	for tomeId, spellId in pairs(spellTomes) do
		local tomeRecord = types.Book.records[tomeId]
		if tomeRecord then
			local spell = core.magic.spells.records[spellId]
			if spell then
				local spellInfo = getSpellCost(spell)
				local primarySchool = getSpellPrimarySchool(spell)
				if primarySchool == schoolId and spellInfo.cost < maxCost then
					table.insert(matchingTomes, { tomeId = tomeId, spellId = spellId, cost = spellInfo.cost })
				end
			end
		end
	end
	return matchingTomes
end

function giveRandomSpellTome(player)
	if not player then
		return false
	end
	local hasSpellTomes = false
	for tomeId, _ in pairs(spellTomes) do
		if types.Book.records[tomeId] then
			hasSpellTomes = true
			break
		end
	end
	if not hasSpellTomes then
		return false
	end
	local bestSkill, skillValue = getBestMagicSkill(player)
	if not bestSkill then
		return false
	end
	local tomes = getMatchingSpellTomes(bestSkill, 40)
	if #tomes == 0 then
		return false
	end
	local chosen = tomes[math.random(1, #tomes)]
	local item = world.createObject(chosen.tomeId, 1)
	item:moveInto(types.Actor.inventory(player))
	local spell = core.magic.spells.records[chosen.spellId]
	return true
end


function giveRandomGold(player)
	if not player then
		log("[RandomGold] Error: Player not found")
		return false
	end
	local amount = math.random(35, 139)
	local gold = world.createObject("gold_001", amount)
	gold:moveInto(types.Actor.inventory(player))
	log("[RandomGold] Gave: " .. amount .. " gold")
	return true
end


local alcoholAndDrugs = {
	"potion_local_liquor_01",
	"potion_local_brew_01",
	"potion_comberry_brandy_01",
	"potion_cyro_whiskey_01",
	"potion_cyro_brandy_01",
	"ingred_moon_sugar_01",
	"potion_skooma_01",
}
function giveRandomAlcohol(player)
	if not player then
		log("Alcohol: Error - Player not found")
		return false
	end
	local idx = math.ceil(math.random() * (#alcoholAndDrugs - 0.9))
	local chosen = alcoholAndDrugs[idx]
	local item = world.createObject(chosen, 1)
	item:moveInto(types.Actor.inventory(player))
	log("Alcohol: Gave " .. chosen)
	return true
end

function giveLockpicks(player)
	if not player then
		log("[Lockpicks] Error: Player not found")
		return false
	end
	local securitySkill = types.NPC.stats.skills.security(player).modified
	if securitySkill < 15 and math.random() < 0.5 then
		log("[Lockpicks] Security too low (" .. securitySkill .. "), no lockpicks")
		return false
	end
	local count = 1
	if securitySkill >= 15 then count = 2 end
	if securitySkill >= 25 then count = 3 end
	local lockpick = world.createObject("pick_apprentice_01", count)
	lockpick:moveInto(types.Actor.inventory(player))
	log("[Lockpicks] Gave: " .. count .. " lockpick(s) (Security: " .. securitySkill .. ")")
	return true
end

function giveSoulGem(player)
	local mysticism = types.NPC.stats.skills.mysticism(player).modified
	local enchant = types.NPC.stats.skills.enchant(player).modified
	if math.max(mysticism, enchant) < 20 then
		return false
	end
	local gem = math.random(1, 2) == 1 and "misc_soulgem_petty" or "misc_soulgem_lesser"
	local count = math.random(1, 2)
	local item = world.createObject(gem, count)
	item:moveInto(types.Actor.inventory(player))
	log("SoulGem: Gave " .. count .. "x " .. gem)
	return true
end

local apparatus = {
	"apparatus_a_mortar_01",
	"apparatus_a_retort_01",
	"apparatus_a_alembic_01",
	"apparatus_a_calcinator_01",
}
function giveApparatus(player)
	local alchemy = types.NPC.stats.skills.alchemy(player).modified
	if alchemy < 20 then
		return false
	end
	local chosen = apparatus[math.random(1, #apparatus)]
	local item = world.createObject(chosen, 1)
	item:moveInto(types.Actor.inventory(player))
	log("Apparatus: Gave " .. chosen)
	return true
end

function giveRepairHammer(player)
	local armorer = types.NPC.stats.skills.armorer(player).modified
	if armorer < 20 then
		return false
	end
	local item = world.createObject("hammer_repair", 1)
	item:moveInto(types.Actor.inventory(player))
	log("Repair: Gave repair hammer")
	return true
end

function giveAmmo(player)
	local marksman = types.NPC.stats.skills.marksman(player).modified
	if marksman < 20 then
		return false
	end
	local count = math.random(10, 25)
	local item = world.createObject("iron arrow", count)
	item:moveInto(types.Actor.inventory(player))
	log("Ammo: Gave " .. count .. "x " .. "iron arrow")
	return true
end

local foods = {
	"ingred_bread_01",
	"ingred_comberry_01",
	"ingred_crab_meat_01",
	"ingred_hound_meat_01",
	"ingred_kwama_cuttle_01",
	"ingred_rat_meat_01",
	"ingred_scuttle_01",
	"ingred_saltrice_01",
}

function giveFood(player)
	local chosen = foods[math.random(1, #foods)]
	local item = world.createObject(chosen, 1)
	item:moveInto(types.Actor.inventory(player))
	log("Food: Gave " .. chosen)
	return true
end

local jewelry = {
	"expensive_ring_01",
	"expensive_ring_02",
	"expensive_ring_03",
	"expensive_amulet_01",
	"expensive_amulet_02",
	"expensive_amulet_03",
}
function giveJewelry(player)
	local chosen = jewelry[math.random(1, #jewelry)]
	local item = world.createObject(chosen, 1)
	item:moveInto(types.Actor.inventory(player))
	log("Jewelry: Gave " .. chosen)
	return true
end

local lights = {
	"light_com_torch_01",
	"light_com_torch_02",
	"light_com_candle_05",
	"light_com_lantern_01",
}
function giveLight(player)
	local chosen = lights[math.random(1, #lights)]
	local item = world.createObject(chosen, 1)
	item:moveInto(types.Actor.inventory(player))
	log("Light: Gave " .. chosen)
	return true
end

function giveBook(player)
	local books = {}
	for _, record in pairs(types.Book.records) do
		if not record.isScroll and not record.mwscript and record.value > 1 and record.name and not record.name:lower():find("deprecated") and record.icon ~= "icons\\" then
			table.insert(books, record.id)
		end
	end
	if #books == 0 then
		return false
	end
	local chosen = books[math.random(1, #books)]
	local item = world.createObject(chosen, 1)
	item:moveInto(types.Actor.inventory(player))
	log("Book: Gave " .. chosen)
	return true
end

function getRandomItems(player)
	giveRandomGold(player)
	
	if math.random() < 0.3 then giveRandomGold(player)		end
	if math.random() < 1.0 then giveRandomWeapon(player)	  end
	if math.random() < 1.0 then giveRandomSpellTome(player)   end
	--if math.random() < 0.5 then giveRandomArmor(player)	 end
	if math.random() < 0.5 then giveFood(player)			  end
	if math.random() < 0.3 then giveRandomAlcohol(player)	 end
	if math.random() < 0.4 then giveBook(player)			  end
	if math.random() < 0.5 then giveLight(player)			 end
	if math.random() < 0.3 then giveJewelry(player)		   end
	if math.random() < 0.8 then giveLockpicks(player)		 end
	if math.random() < 0.7 then giveAmmo(player)			  end
	if math.random() < 0.7 then giveRepairHammer(player)	  end
	if math.random() < 0.7 then giveApparatus(player)		 end
	if math.random() < 0.7 then giveSoulGem(player)		   end
end