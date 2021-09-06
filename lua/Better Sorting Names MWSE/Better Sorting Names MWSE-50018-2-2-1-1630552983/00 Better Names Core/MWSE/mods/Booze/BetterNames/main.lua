-- Better Names v2.1 by Booze (B00ze64)
-- Potion Icons code by Greatness7
-- MCM code by Merlord

local configController = require("Booze.BetterNames.config")
local mcm = require("Booze.BetterNames.mcm")

local function ApplyLabel(potion) -- This comes from MWSE_PoisonCrafting-45729 by Greatness7

	local assets = {icon=".tga"} -- Only do the icon

	local qualities = {"exclusive", "quality", "fresh", "standard", "cheap", "bargain"} -- This is part of the icon filename

	for asset, suffix in pairs(assets) do
		local current = potion[asset]:lower()
		for _, quality in pairs(qualities) do
			if current:find(quality) then
				local effect = potion.effects[1].id
				potion[asset] = "r0\\p\\" .. quality .. "_" .. effect .. suffix
				break
			end
		end
	end
end

local function ChangeItemsProperty(PrettyName,Filename,Property)

	local i = 0
	local j = 0

	local items = require("Booze.BetterNames." .. Filename)

	for _, anItem in ipairs(items) do
	
		i = i + 1
        	local tesObject = tes3.getObject(anItem.ID)
		if tesObject then
			j = j + 1
			tesObject[Property] = anItem[Property]
		else
			if (showDebug) then mwse.log("\tID=%s Not Found for %s=%s", anItem.ID, Property, anItem[Property]) end
		end
	end
	mwse.log("\tLoaded %s %s IDs, changed %s for %s of them.", i, PrettyName, Property, j)
end

local function initialized(e)

	mwse.log("[Better Names] Starting Initialization.")

	local config = configController:get()
	mwse.log(json.encode(config, { indent = true }))
	showDebug = config.showDebug

	if (config.DoArmorNames) then

		ChangeItemsProperty("Armor","armor","name")
	end

	if (config.DoClothingNames) then

		ChangeItemsProperty("Clothing","clothing","name")
	end

	if (config.DoPotionNamesEffect) and not (config.DoPotionNamesPotion) then

		ChangeItemsProperty("Potions","potions-effect","name")

	elseif (config.DoPotionNamesPotion) then

		ChangeItemsProperty("Potions","potions-potion","name")
	end

	if (config.DoSoulgemNames) then

		ChangeItemsProperty("Soulgems","soulgems","name")
	end

	if (config.DoWeaponNames) then

		ChangeItemsProperty("Weapons","weapons","name")
	end

	if (config.DoToolNames) then

		ChangeItemsProperty("Tools","tools","name")
	end

	if (config.DoHighQualityTools) then

		ChangeItemsProperty("Tools","tool-uses","condition")
	end

	if (config.DoTrainingBookNames) then

		ChangeItemsProperty("Training Books","training-books","name")
	end

	if (config.DoPotionIcons) then

		local i = 0

		local BasePotions = {
			"p_almsivi_intervention_s",
			"p_burden_b",
			"p_burden_c",
			"p_burden_e",
			"p_burden_q",
			"p_burden_s",
			"p_chameleon_b",
			"p_chameleon_c",
			"p_chameleon_e",
			"p_chameleon_q",
			"p_chameleon_s",
			"p_cure_blight_s",
			"p_cure_common_s",
			"p_cure_common_unique",
			"p_cure_paralyzation_s",
			"p_cure_poison_s",
			"p_detect_creatures_s",
			"p_detect_enchantment_s",
			"p_detect_key_s",
			"p_disease_resistance_b",
			"p_disease_resistance_c",
			"p_disease_resistance_e",
			"p_disease_resistance_q",
			"p_disease_resistance_s",
			"p_dispel_s",
			"p_drain willpower_q",
			"p_drain_agility_q",
			"p_drain_endurance_q",
			"p_drain_intelligence_q",
			"p_drain_luck_q",
			"p_drain_magicka_q",
			"p_drain_personality_q",
			"p_drain_speed_q",
			"p_drain_strength_q",
			"p_feather_b",
			"p_feather_c",
			"p_feather_e",
			"p_feather_q",
			"p_fire resistance_s",
			"p_fire_resistance_b",
			"p_fire_resistance_c",
			"p_fire_resistance_e",
			"p_fire_resistance_q",
			"p_fire_shield_b",
			"p_fire_shield_c",
			"p_fire_shield_e",
			"p_fire_shield_q",
			"p_fire_shield_s",
			"p_fortify_agility_b",
			"p_fortify_agility_c",
			"p_fortify_agility_e",
			"p_fortify_agility_q",
			"p_fortify_agility_s",
			"p_fortify_attack_e",
			"p_fortify_endurance_b",
			"p_fortify_endurance_c",
			"p_fortify_endurance_e",
			"p_fortify_endurance_q",
			"p_fortify_endurance_s",
			"p_fortify_fatigue_b",
			"p_fortify_fatigue_c",
			"p_fortify_fatigue_e",
			"p_fortify_fatigue_q",
			"p_fortify_fatigue_s",
			"p_fortify_health_b",
			"p_fortify_health_c",
			"p_fortify_health_e",
			"p_fortify_health_q",
			"p_fortify_health_s",
			"p_fortify_intelligence_b",
			"p_fortify_intelligence_c",
			"p_fortify_intelligence_e",
			"p_fortify_intelligence_q",
			"p_fortify_intelligence_s",
			"p_fortify_luck_b",
			"p_fortify_luck_c",
			"p_fortify_luck_e",
			"p_fortify_luck_q",
			"p_fortify_luck_s",
			"p_fortify_magicka_b",
			"p_fortify_magicka_c",
			"p_fortify_magicka_e",
			"p_fortify_magicka_q",
			"p_fortify_magicka_s",
			"p_fortify_personality_b",
			"p_fortify_personality_c",
			"p_fortify_personality_e",
			"p_fortify_personality_q",
			"p_fortify_personality_s",
			"p_fortify_speed_b",
			"p_fortify_speed_c",
			"p_fortify_speed_e",
			"p_fortify_speed_q",
			"p_fortify_speed_s",
			"p_fortify_strength_b",
			"p_fortify_strength_c",
			"p_fortify_strength_e",
			"p_fortify_strength_q",
			"p_fortify_strength_s",
			"p_fortify_willpower_b",
			"p_fortify_willpower_c",
			"p_fortify_willpower_e",
			"p_fortify_willpower_q",
			"p_fortify_willpower_s",
			"p_frost_resistance_b",
			"p_frost_resistance_c",
			"p_frost_resistance_e",
			"p_frost_resistance_q",
			"p_frost_resistance_s",
			"p_frost_shield_b",
			"p_frost_shield_c",
			"p_frost_shield_e",
			"p_frost_shield_q",
			"p_frost_shield_s",
			"p_heroism_s",
			"p_invisibility_b",
			"p_invisibility_c",
			"p_invisibility_e",
			"p_invisibility_q",
			"p_invisibility_s",
			"p_jump_b",
			"p_jump_c",
			"p_jump_e",
			"p_jump_q",
			"p_jump_s",
			"p_levitation_b",
			"p_levitation_c",
			"p_levitation_e",
			"P_Levitation_Q",
			"p_levitation_s",
			"p_light_b",
			"p_light_c",
			"p_light_e",
			"p_light_q",
			"p_light_s",
			"p_lightning shield_b",
			"p_lightning shield_c",
			"p_lightning shield_e",
			"p_lightning shield_q",
			"p_lightning shield_s",
			"p_lovepotion_unique",
			"p_magicka_resistance_b",
			"p_magicka_resistance_c",
			"p_magicka_resistance_e",
			"p_magicka_resistance_q",
			"p_magicka_resistance_s",
			"p_mark_s",
			"p_night-eye_b",
			"p_night-eye_c",
			"p_night-eye_e",
			"p_night-eye_q",
			"p_night-eye_s",
			"p_paralyze_b",
			"p_paralyze_c",
			"p_paralyze_e",
			"p_paralyze_q",
			"p_paralyze_s",
			"p_poison_resistance_b",
			"p_poison_resistance_c",
			"p_poison_resistance_e",
			"p_poison_resistance_q",
			"p_poison_resistance_s",
			"p_quarrablood_UNIQUE",
			"p_recall_s",
			"p_reflection_b",
			"p_reflection_c",
			"p_reflection_e",
			"p_reflection_q",
			"p_reflection_s",
			"p_restore_agility_b",
			"p_restore_agility_c",
			"p_restore_agility_e",
			"p_restore_agility_q",
			"p_restore_agility_s",
			"p_restore_endurance_b",
			"p_restore_endurance_c",
			"p_restore_endurance_e",
			"p_restore_endurance_q",
			"p_restore_endurance_s",
			"p_restore_fatigue_b",
			"p_restore_fatigue_c",
			"p_restore_fatigue_e",
			"p_restore_fatigue_q",
			"p_restore_fatigue_s",
			"p_restore_health_b",
			"p_restore_health_c",
			"p_restore_health_e",
			"p_restore_health_q",
			"p_restore_health_s",
			"p_restore_intelligence_b",
			"p_restore_intelligence_c",
			"p_restore_intelligence_e",
			"p_restore_intelligence_q",
			"p_restore_intelligence_s",
			"p_restore_luck_b",
			"p_restore_luck_c",
			"p_restore_luck_e",
			"p_restore_luck_q",
			"p_restore_luck_s",
			"p_restore_magicka_b",
			"p_restore_magicka_c",
			"p_restore_magicka_e",
			"p_restore_magicka_q",
			"p_restore_magicka_s",
			"p_restore_personality_b",
			"p_restore_personality_c",
			"p_restore_personality_e",
			"p_restore_personality_q",
			"p_restore_personality_s",
			"p_restore_speed_b",
			"p_restore_speed_c",
			"p_restore_speed_e",
			"p_restore_speed_q",
			"p_restore_speed_s",
			"p_restore_strength_b",
			"p_restore_strength_c",
			"p_restore_strength_e",
			"p_restore_strength_q",
			"p_restore_strength_s",
			"p_restore_willpower_b",
			"p_restore_willpower_c",
			"p_restore_willpower_e",
			"p_restore_willpower_q",
			"p_restore_willpower_s",
			"p_shock_resistance_b",
			"p_shock_resistance_c",
			"p_shock_resistance_e",
			"p_shock_resistance_q",
			"p_shock_resistance_s",
			"p_silence_b",
			"p_silence_c",
			"p_silence_e",
			"p_silence_q",
			"p_silence_s",
			"p_sinyaramen_UNIQUE",
			"p_slowfall_s",
			"p_spell_absorption_b",
			"p_spell_absorption_c",
			"p_spell_absorption_e",
			"p_spell_absorption_q",
			"p_spell_absorption_s",
			"p_swift_swim_b",
			"p_swift_swim_c",
			"p_swift_swim_e",
			"p_swift_swim_q",
			"p_telekinesis_s",
			"p_water_breathing_s",
			"p_water_walking_s"
			}

		for _, PotionID in pairs(BasePotions) do
			i = i + 1
			ApplyLabel(tes3.getObject(PotionID))
		end

		mwse.log("\tPotion badges added to %s standard potion icons", i)
	end

	mwse.log("[Better Names] Initialized.")
end

event.register("initialized", initialized)
