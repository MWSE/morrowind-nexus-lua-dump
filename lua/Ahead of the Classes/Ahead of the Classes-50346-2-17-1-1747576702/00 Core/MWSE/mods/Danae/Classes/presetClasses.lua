---@class AheadOfTheClasse.PresetStarters
local this = {}
local goldamount = 20
local arrowamount = 20
local throwingstaramount = 30
--[[
    functions for each class return
    gear list of item objects
]]
this.pickStarters = {
    ["acrobat"] = function()
-- acrobat' is a polite euphemism for agile burglars and second-story men. these thieves avoid detection by stealth, and rely on mobility and cunning to avoid capture.
        return {
            gearList = {
                { item = "p_jump_q" },
                { item = "p_restore_fatigue_q" },
                { item = "chitin throwing star", count = arrowamount },
                { item = "watcher's belt" },
                { item = "netch_leather_helm" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "chitin spear" },
                { item = "aa_thw_net", count = 6 },
            },
            spellList = {
                "aa_cl_acrob_power",
                "jump",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 5 },
                { skillId = "BardicInspiration:Performance", value = 5 },
                { skillId = "climbing", value = 15 },
            }
        }
    end,

    ["agent"] = function()
-- agents are operatives skilled in deception and avoidance, but trained in self-defense and the use of deadly force. self-reliant and independent, agents devote themselves to personal goals, or to various patrons or causes.
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "p_chameleon_s" },
                { item = "p_jump_s" },
                { item = "netch_leather_helm" },
                { item = "netch_leather_cuirass" },
                { item = "chitin shortsword" },
                { item = "ab_misc_pursecoin" },
                { item = "watcher's belt" },
                { item = "netch_leather_shield" },
            },
            spellList = {
                "aa_cl_agent_power",
                "aa_cl_bank_power",
            },
        }
    end,

    ["alchemist"] = function()
--alchemists know the processes of refining and preserving the magical properties hidden in natural and supernatural ingredients. they buy and sell potions, the various kinds of apparatus needed to make potions, and ingredients.
        return {
            gearList = {
                { item = "apparatus_a_mortar_01" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "watcher's belt" },
                { item = "aa_cl_speech_pot" },
                { item = "netch_leather_shield" },
                { item = "wooden staff" },
                { item = "a_trapitem1" },
                { item = "jjs_plant_blklichen" },
                { item = "jjs_plant_cork" },
            },
            spellList = {
                "summon scamp",
                "aa_cl_alc_power",
                "frost barrier",
            },
            customSkillList = {
                { skillId = "mc_Crafting", value = 5 },
                { skillId = "mc_Metalworking", value = 5 },
                { skillId = "mc_Cooking", value = 10 },
            }
        }
    end,

    ["antipaladin"] = function()
        return {
            gearList = {
                { item = "iron saber" },
                { item = "iron_shield" },
                { item = "t_nor_wood_shield_01" },
                { item = "war_imperial_srct_robe01" },
                { item = "iron battle axe" },
                { item = "iron_greaves" },
                { item = "iron boots" },
                { item = "t_com_iron_cuirass_01" },
                { item = "hammer_repair", count = 2 },
                { item = "bk_arkaytheenemy" }
            },
            spellList = {
                "aa_cl_antipal_spell",
                "absorb fatigue",
                "burden",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 15 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["apothecary"] = function()
--apothecaries brew and sell potions to heal wounds, restore bodily and mental attributes, and cure diseases.
        return {
            gearList = {
                { item = "apparatus_a_mortar_01" },
                { item = "aa_cl_speech_pot" },
                { item = "ab_misc_pursecoin" },
                { item = "wooden staff" },
                { item = "ab_c_commonhood01" },
                { item = "netch_leather_shield" },
                { item = "gold_001", count = 70 },
                { item = "jjs_plant_marsh" },
                { item = "jjs_plant_swtbardsrt" },
            },
            spellList = {
                "aa_cl_apth_destr",
                "cure poison",
            },
            customSkillList = {
                { skillId = "mc_Cooking", value = 10 },
            }
        }
    end,

    ["aarcher"] = function()
--the arcane archer is a master masrksman whose study of magic has made him all the more deadlier. they use magic to enchant bows and arrows, conjure weapons and hide themselves.
        return {
            gearList = {
                { item = "ab_c_commonhood01" },
                { item = "mer_fletch_kit" },
                { item = "mc_Fletching_kit" },
                { item = "long bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_rea_wormmouth_bracerl_01" },
            },
            spellList = {
                "aa_cl_aarcher_power01",
                "aa_cl_aarcher_power02",
                "sanctuary",
                "mother's kiss",
                "bound longbow",
            },
            customSkillList = {
                { skillId = "fletching", value = 5 },
                { skillId = "mc_Fletching", value = 5 },
            }
        }
    end,

    ["arcanist"] = function()
--arcanists are wizards who combine prodigious affinity to metaphysical magicks with more practical training with staff. arcanists are ingenious and they use mystical rituals to turn the threads of fate ever slightly towards their favour.        return {
        return {
            gearList = {
                { item = "ingred_rune_a_01" },
                { item = "ingred_rune_a_10" },
                { item = "wooden staff" },
                { item = "oj_w_woodtwigswand_en_cshb" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "ab_app_grinder" },
            },
            spellList = {
                "disintegrate armor",
                "aa_cl_arcan_power",
                "spell absorption",
                "shield",
                "silence",
            },
            customSkillList = {
                { skillId = "MSS:Staff", value = 15 },
                { skillId = "painting", value = 5 },
                { skillId = "daedricSkillId", value = 20 },
                { skillId = "common.inscriptionSkillId", value = 10 },
            }
        }
    end,

    ["aatl_cla_researcher"] = function()
--pika aatl
        return {
            gearList = {
                { item = "ingred_rune_a_02" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "aa_cl_speech_pot" },
                { item = "wooden staff" },
                { item = "oj_w_woodtwigswand_en_cshb" },
                { item = "apparatus_a_mortar_01" },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_rea_wormmouth_bracerl_01" },
            },
            spellList = {
                "aa_cl_arcan_power",
                "spell absorption",
                "shield",
            },
            customSkillList = {
                { skillId = "MSS:Staff", value = 15 },
                { skillId = "daedricSkillId", value = 30 },
                { skillId = "common.inscriptionSkillId", value = 10 },
            }
        }
    end,

    ["aatl_cla_imperial_archivist"] = function()
--pika aatl
        return {
            gearList = {
                { item = "t_bk_imperialheraldrymwtr" },
                { item = "ab_bk_codexarcana1_sk" },
                { item = "wooden staff" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "ab_app_grinder" },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_rea_wormmouth_bracerl_01" },
            },
            spellList = {
                "hearth heal",
                "aa_cl_arcan_power",
                "spell absorption",
                "shield",
            },
            customSkillList = {
                { skillId = "MSS:Staff", value = 15 },
                { skillId = "daedricSkillId", value = 30 },
                { skillId = "common.inscriptionSkillId", value = 20 },
            }
        }
    end,


    ["archeologist"] = function()
--archeologists quietly explore ruins, hoping to uncover precious artifacts. they have knowledge of magical objects and how to restore them.            gearList = {
        return {
            gearList = {
                { item = "mu_chalkc" },
                { item = "ashfall_woodaxe" },
                { item = "p_chameleon_s" },
                { item = "p_restore_fatigue_s" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "hammer_repair", count = 2 },
                { item = "light_com_lantern_01" },
                { item = "chitin shortsword" },
                { item = "ab_app_grinder" },
            },
            spellList = {
                "aa_cl_archeo_power",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 25 },
                { skillId = "mc_Masonry", value = 5 },
                { skillId = "climbing", value = 5 },
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["archer"] = function()
--archers are fighters specializing in long-range combat and rapid movement. opponents are kept at distance by ranged weapons and swift maneuver, and engaged in melee with sword and shield after the enemy is wounded and weary.
        return {
            gearList = {
                { item = "mer_fletch_kit" },
                { item = "mc_Fletching_kit" },
                { item = "long bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "iron saber" },
                { item = "netch_leather_shield" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "t_rea_wormmouth_helm_01" },
                { item = "p_chameleon_s" },
                { item = "chitin spear" },
            },
            spellList = {
                "aa_cl_archer_power",
            },
            customSkillList = {
                { skillId = "fletching", value = 15 },
                { skillId = "mc_Fletching", value = 15 },
            }
        }
    end,

    ["artificer"] = function()
--artificers are detail oriented crafters, capable of creating fine works of art or mechanical marvels. in addition to smithing and enchanting jewelry and embellishing armor, artificers may craft alchemical equipment, study dwemer mechanisms, smith locks, and if necessary, conduct cruder repairs to weapons and armor.
        return {
            gearList = {
                { item = "oj_w_woodtwigswand_en_cshb" },
                { item = "hammer_repair", count = 2 },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "misc_soulgem_lesser" },
                { item = "chitin club" },
                { item = "t_com_iron_pauldronr_01" },
                { item = "t_com_iron_pauldronl_01" },
                { item = "iron_shield" },
                { item = "ab_w_woodcrossbow" },
                { item = "mc_jewelry_kit" },
                { item = "t_com_wood_bolt_01", count = arrowamount },
            },
            spellList = {
            },
            customSkillList = {
                { skillId = "mc_Crafting", value = 10 },
                { skillId = "common.inscriptionSkillId", value = 5 },
                { skillId = "mc_Smithing", value = 5 },
                { skillId = "mc_Metalworking", value = 10 },
                { skillId = "mc_Crafting", value = 10 },
                { skillId = "mc_Masonry", value = 5 },
                { skillId = "mc_Woodworking", value = 5 },
            }
        }
    end,

    ["artisan"] = function()
--artisan are talented people who love to make new items and repair them. they are handy and skilled with a hammer. they can even create more refined items, some magical. they are shrewed salesmen.        return {
        return {
            gearList = {
                { item = "mc_pottery_wheel" },
                { item = "mc_jewelry_kit" },
                { item = "mg_agate1" },
                { item = "war_blacksmith_apron01" },
                { item = "hammer_repair", count = 2 },
                { item = "watcher's belt" },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "ab_app_grinder" },
                { item = "ab_a_wickerhelm" },
                { item = "t_com_paint_palette_01" },
            },
            spellList = {
                "open",
            },
            customSkillList = {
                { skillId = "fletching", value = 5 },
                { skillId = "mc_Fletching", value = 5 },
                { skillId = "mc_Smithing", value = 5 },
                { skillId = "mc_Sewing", value = 5 },
                { skillId = "mc_Crafting", value = 15 },
                { skillId = "mc_Metalworking", value = 10 },
                { skillId = "mc_Masonry", value = 15 },
                { skillId = "mc_Woodworking", value = 15 },
                { skillId = "painting", value = 5 },
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["aa_glb_artist"] = function()
--Artists are talented creatives often found in the retinues of high lords, in service to religious orders, or working in guild workshops. Skilled with paintbrush, chisel, or the pen, artists search for meaning in the mediums of the physical world.
-- alch, blunt, sb, speech, secu //alt, illu, merc, h2h, unrm
-- not playable by default.- enabled by this mod.
        return {
            gearList = {
                { item = "gold_001", count = 50 },
                { item = "apparatus_a_mortar_01" },
                { item = "ingred_gold_kanet_01" },
                { item = "ingred_heather_01" },
                { item = "ingred_stoneflower_petals_01" },
                { item = "silver dagger" },
                { item = "T_Imp_ColFur_HelmEx_01"},
                { item = "aa_cl_speech_pot" },
                { item = "t_com_paintbrush_01" },
                { item = "jop_brush_01" },
                { item = "jop_easel_misc" },
                { item = "jop_water_palette_01" },
                { item = "jop_parchment_01", count = 5 },
                { item = "jop_coal_sticks_01", count = 2 },
            },
            spellList = {
                "calm creature",
                "chameleon",
                "paralysis",
                "shield",
            },
            customSkillList = {
                { skillId = "painting", value = 15 },
            }
        }
    end,

    ["t_glb_astrologer"] = function()
--Astrologers are mystics, scholars, and sages who study the patterns of celestial objects as they move across the firmament. Though often derided as charlatans, experienced astrologers are prized by high nobles and poor farmers alike for their skills in divination.
-- myst, merc, speech, conj, illu // rest, unarm, ench, sneak, alt
-- not playble by default.
        return {
            gearList = {
                { item = "_rv_goggles4" },
                { item = "ab_c_expensivehood02a" },
                { item = "expensive_robe_02_a" },
                { item = "t_com_iron_staff_01" },
                { item = "ab_misc_pursecoin" },
                { item = "bk_firmament" },
                { item = "ma_modernadventurer_01" },
            },
            spellList = {
                "aa_cl_astro_spell01",
                "aa_cl_astro_spell02",
                "aa_cl_bound mace",
                "levitate",
                "mother's kiss",
            },
            customSkillList = {
                { skillId = "MSS:Staff", value = 5 },
                { skillId = "daedricSkillId", value = 10 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["aa_astrologer"] = function()
--the astrologer reads their fate in the stars, be it a blessing or a curse. they carry a staff and are proficient at magic.
        return {
            gearList = {
                { item = "_rv_goggles4" },
                { item = "ab_c_expensivehood02a" },
                { item = "expensive_robe_02_a" },
                { item = "t_com_iron_staff_01" },
                { item = "ab_misc_pursecoin" },
                { item = "bk_firmament" },
                { item = "ma_modernadventurer_01" },
            },
            spellList = {
                "aa_cl_astro_spell01",
                "aa_cl_astro_spell02",
                "aa_cl_bound mace",
                "levitate",
                "mother's kiss",
            },
            customSkillList = {
                { skillId = "MSS:Staff", value = 5 },
                { skillId = "daedricSkillId", value = 10 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["assassin"] = function()
--assassins are killers who rely on stealth and mobility to approach victims undetected. execution is with ranged weapons or with short blades for close work. assassins include ruthless murderers and principled agents of noble causes.
        return {
            gearList = {
                { item = "dwcalling card", count = 10 },
                { item = "p_chameleon_s" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "netch_leather_cuirass" },
                { item = "cruel viperblade" },
                { item = "p_jump_s" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "p_restore_fatigue_s" },
                { item = "ab_app_grinder" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
            },
            spellList = {
            },
            customSkillList = {
                { skillId = "climbing", value = 5 },
            }
        }
    end,

    ["t_glb_baker"] = function()
--bakers run or work in bakehouses, where they bake and sell bread, pastries, and cakes.
        return {
            gearList = {
                { item = "nom_yeast", count = 10 },
                { item = "nom_sugar", count = 5 },
                { item = "war_blacksmith_apron01", },
                { item = "t_ingfood_breadcolovian_01", count = 2 },
                { item = "t_ingfood_breadflat_01", count = 2 },
                { item = "t_ingfood_bread_01", count = 2 },
                { item = "t_ingfood_breaddeshaan_01", count = 2 },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "ab_ingfood_saltricebread" },
                { item = "ab_ingfood_sweetroll" },
                { item = "nom_food_pie_appl" },
                { item = "ab_w_cookknifebread" },
                { item = "t_nor_wood_shield_01" },
                { item = "hammer_repair", count = 2 },
                { item = "ab_app_grinder" },
                { item = "watcher's belt" },
                { item = "chitin club" },
                { item = "ab_a_wickerhelm" },
                { item = "aa_cl_speech_pot" },
                { item = "t_com_breadpaddle_01a" },
                { item = "nom_shovel" },
            },
            spellList = {
                "mother's kiss",
            },
            customSkillList = {
                { skillId = "mc_Cooking", value = 20 },
            }
        }
    end,

    ["t_glb_banker"] = function()
--bankers take care of deposits, withdrawals, money flow, payments, and loans at bank branches. bankers also invest in the local economy or deal with immovable property for the benefit of their customers.            gearList = {
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "gold_001", count = 100 },
                { item = "pick_journeyman_01" },
                { item = "watcher's belt" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "t_imp_chain_boots_01" },
                { item = "expensive_pants_02" },
                { item = "expensive_shirt_02" },
                { item = "ab_misc_pursecoin" },
                { item = "firebite dagger" },
            },
            spellList = {
                "aa_cl_bank_power",
            },
        }
    end,

    ["barbarian"] = function()
--barbarians are the proud, savage warrior elite of the plains nomads, mountain tribes, and sea reavers. they tend to be brutal and direct, lacking civilized graces, but they glory in heroic feats, and excel in fierce, frenzied single combat.
        return {
            gearList = {
                { item = "iron war axe" },
                { item = "ashfall_woodaxe" },
                { item = "t_nor_ringmail_cuirass_01" },
                { item = "steel club" },
                { item = "p_restore_fatigue_s" },
                { item = "nordic_leather_shield" },
                { item = "p_jump_s", count= 2 },
                { item = "fur_pauldron_left" },
                { item = "fur_pauldron_right" },
                { item = "repair_prongs", count= 2 },
                { item = "0s_throwax_chit_01", count = 15 },
                { item = "bk_abcs" },
            },
            spellList = {
                "aa_cl_barbar_power",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 5 },
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["bard"] = function()
--bards are loremasters and storytellers. they crave adventure for the wisdom and insight to be gained, and must depend on sword, shield, spell, and enchantment to preserve them from the perils of their educational experiences.
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "ab_app_grinder" },
                { item = "iron saber" },
                { item = "t_nor_wood_shield_01" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "aa_bk_songbook_bard", },
                { item = "misc_de_lute_01", },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_rea_wormmouth_bracerl_01" },
            },
            spellList = {
                "aa_cl_bard_power",
                "aa_cl_bard_spell",
            },
            customSkillList = {
                { skillId = "common.inscriptionSkillId", value = 5 },
                { skillId = "BardicInspiration:Performance", value = 20 },
                { skillId = "mc_Crafting", value = 5 },
            }
        }
    end,

    ["balchemist"] = function()
-- the battle alchemist has turned alchemy into  a deadly art. they will coat their weapon with poison, or, more often, create bombs than can be thrown from a safe distance.
        return {
            gearList = {
                { item = "ab_c_commonhood01" },
                { item = "netch_leather_cuirass" },
                { item = "aa_cl_poison_deadly" },
                { item = "aa_cl_poison_potent", count= 2 },
                { item = "aa_cl_posin_cheap", count= 2 },
                { item = "mc_poison01" },
                { item = "mc_grenade_case", count= 5 },
                { item = "aa_blind_30" },
                { item = "aa_calm_30" },
                { item = "aa_fire_30" },
                { item = "apparatus_a_mortar_01" },
                { item = "ab_ingflor_glmuscaria_01", count= 2 },
                { item = "t_ingflor_chokeberry_01", count= 2 },
            },
            spellList = {
                "cure poison",
                "burden touch",
            },
            customSkillList = {
                { skillId = "mc_Crafting", value = 5 },
                { skillId = "mc_Cooking", value = 5 },
            }
        }
    end,

    ["battlemage"] = function()
--battlemages are wizard-warriors, trained in both lethal spellcasting and heavily armored combat. they sacrifice mobility and versatility for the ability to supplement melee and ranged attacks with elemental damage and summoned creatures.
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "iron_cuirass" },
                { item = "iron boots" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "ab_app_grinder" },
                { item = "iron saber" },
            },
            spellList = {
                "shield",
                "bound battle-axe",
                "aa_cl_battle_spell",
                "absorb agility",
            },
            customSkillList = {
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["beastmaster"] = function()
--beastmasters use their understanding of animals and creatures to their advantage, either calming or even commanding creatures. they prefer medium armor and are adept with clubs though they will wrestle animals often to tame them as well. they are incredibly fit and can run with a pack of nix-hounds.
        return {
            gearList = {
                { item = "chitin club" },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_rea_wormmouth_bracerl_01" },
                { item = "p_restore_fatigue_s" },
                { item = "t_nor_wood_shield_01" },
                { item = "p_jump_s" },
                { item = "ab_c_commonhood01" },
                { item = "ab_app_grinder" },
                { item = "ashfall_waterskin" },
                { item = "ashfall_woodaxe" },
            },
            spellList = {
                "aa_cl_beastm_power01",
                "aa_cl_beastm_power02",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 5 },
                { skillId = "fishing", value = 5 },
                { skillId = "fishingSkillId", value = 5 },
                { skillId = "PoleFishing", value = 5 },
                { skillId = "climbing", value = 5 },
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["bookseller"] = function()
--booksellers buy and sell books, and are sometimes involved in the printing process. they are also immersed in book lore and most are happy to share a little advice.
        return {
            gearList = {
                { item = "gold_001", count = 60 },
                { item = "ab_misc_pursecoin" },
                { item = "aa_cl_speech_pot" },
                { item = "watcher's belt" },
                { item = "netch_leather_shield" },
                { item = "chitin club" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "t_bk_pocketguide1pc" },
                { item = "bk_onmorrowind" },
                { item = "bk_specialfloraoftamriel" },
                { item = "bk_shorthistorymorrowind" },
                { item = "t_com_bookendpoor_01", count = 2 },
            },
            spellList = {
                "detect enchantment",
                "almsivi intervention",
            },
            customSkillList = {
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["bounty hunter"] = function()
--bounty hunters apply their skills to tracking down and either capturing or killing criminals that escape justice at the hands of local law ement.
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "ab_w_woodcrossbow" },
                { item = "t_com_wood_bolt_01", count = arrowamount },
                { item = "t_nor_ringmail_cuirass_01" },
                { item = "lbonemold brace of horny fist" },
                { item = "rbonemold bracer of horny fist" },
                { item = "t_nor_wood_shield_01" },
                { item = "aa_thw_net", count = 3 },
            },
            spellList = {
                "absorb fatigue",
                "aa_cl_catcatch_power",
                "aa_cl_bounty_power",
                "calm humanoid",
            },
        }
    end,

    ["buoyant armiger"] = function()
--buoyant armigers are members of a small military order of the tribunal temple, exclusively dedicated to and answering to vivec. they pattern themselves on vivec's heroic spirit of exploration and adventure, and emulate his mastery of the varied arts of personal combat, chivalric courtesy, and subtle verse. they serve the tribunal temple as champions and knights-errant, and are friendly rivals of the more solemn ordinators.
        return {
            gearList = {
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "chitin cuirass" },
                { item = "chitin shortsword" },
                { item = "p_chameleon_s" },
                { item = "netch_leather_shield" },
            },
            spellList = {
                "strength leech",
                "veloth's benison",
            },
        }
    end,

    ["caretaker"] = function()
-- caretakers keep buildings clean and running smoothly. they care for a stock of supplies and keep an eye out for trouble.
        return {
            gearList = {
                { item = "war_blacksmith_apron01" },
                { item = "p_restore_fatigue_s" },
                { item = "pick_journeyman_01" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "p_chameleon_s" },
                { item = "mc_Crafting_kit" },
            },
            spellList = {
                "recall",
                "stamina",
                "light",
            },
            customSkillList = {
                { skillId = "mc_Sewing", value = 5 },
                { skillId = "mc_Crafting", value = 5 },
                { skillId = "mc_Woodworking", value = 5 },
                { skillId = "mc_Cooking", value = 10 },
            }
        }
    end,

    ["t_mw_catcatcher"] = function()
-- cat-catchers are ruthless and cunning slave-hunters. they employ various means of negotiation to secure leads and rewards for their work, use agility and stealth to track their prey, and are skilled in non-lethal combat to overpower any resistance they face.
        return {
            gearList = {
                { item = "chitin club" },
                { item = "left gauntlet of the horny fist" },
                { item = "right gauntlet of horny fist" },
                { item = "p_restore_fatigue_s" },
                { item = "p_chameleon_s" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "p_jump_s" },
                { item = "netch_leather_cuirass" },
                { item = "ashfall_waterskin" },
                { item = "chitin throwing star", count = arrowamount },
            },
            spellList = {
                "aa_cl_catcatch_power",
                "aa_cl_bounty_power",
                "restore strength",
            },
            customSkillList = {
                { skillId = "climbing", value = 5 },
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["champion"] = function()
-- champions have the duty of protecting the honor of their ashlander tribe in peace and war. they give counsel to the ashkhan in tribal affairs, and represent the tribe to guests and intruders.
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "netch_leather_shield" },
                { item = "bonemold_bracer_left" },
                { item = "bonemold_bracer_right" },
                { item = "netch_leather_helm" },
                { item = "netch_leather_cuirass" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "p_restore_fatigue_s" },
            },
            spellList = {
                "aa_cl_champ_power",
                "variable resist magicka",
            },
        }
    end,

    ["t_sky_clever-man"] = function()
--clever-men are practioners of the ancient nordic magical tradition. they act as counsellors to kings and jarls in the affairs of magic and the forces of the otherworld. in olden times, they were widely respected and fought alongside the legendary kings and warriors of skyrim's past. as mages, they are specialized in the various magic schools. in battle, they adorn heavy armor and supply their magical prowess with axe and shield when needed.
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "bm_wool01_robe" },
                { item = "t_nor_wood_shield_01" },
                { item = "t_com_iron_pauldronr_01" },
                { item = "t_com_iron_pauldronl_01" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
            },
            spellList = {
                "frost barrier",
                "flameguard",
                "frostball",
                "bound battle-axe",
                "purge magic",
                "cruel noise",
            },
            customSkillList = {
                { skillId = "common.inscriptionSkillId", value = 10 },
            }
        }
    end,

    ["clothier"] = function()
--clothiers make clothes and sell them. they also buy clothes in good condition; with a little work they can make them good as new and resell them.
        return {
            gearList = {
                { item = "misc_shears_01" },
                { item = "misc_spool_0", count= 3 },
                { item = "misc_de_cloth10", count= 2 },
                { item = "misc_de_cloth11", count= 2 },
                { item = "mc_Sewing_kit" },
                { item = "aa_cl_speech_pot", count= 2 },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "watcher's belt" },
                { item = "chitin club" },
                { item = "cloth bracer left" },
                { item = "cloth bracer right" },
                { item = "gold_001", count = goldamount },
                { item = "expensive_pants_01_z" },
                { item = "expensive_robe_03" },
                { item = "common_robe_04" },
                { item = "common_shirt_05" },
            },
            spellList = {
            },
            customSkillList = {
                { skillId = "mc_Sewing", value = 20 },
                { skillId = "mc_Crafting", value = 5 },
            }
        }
    end,

    ["commoner"] = function()
--commoners do whatever needs doing -- cooking, cleaning, building, baking, making, breaking, and sharing a little local lore.
        return {
            gearList = {
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "watcher's belt" },
                { item = "p_restore_fatigue_s" },
                { item = "aa_cl_speech_pot" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "chitin shortsword" },
                { item = "p_chameleon_s" },
                { item = "ashfall_waterskin" },
            },
            spellList = {
                "aa_cl_pauper_power",
            },
            customSkillList = {
                { skillId = "fishing", value = 5 },
                { skillId = "fishingSkillId", value = 5 },
                { skillId = "PoleFishing", value = 5 },
                { skillId = "mc_Sewing", value = 5 },
                { skillId = "mc_Crafting", value = 5 },
                { skillId = "mc_Mining", value = 5 },
                { skillId = "mc_Woodworking", value = 5 },
                { skillId = "mc_Cooking", value = 10 },
            }
        }
    end,

    ["t_glb_courtesan"] = function()
--courtesans were originally professional courtiers living in the royal courts of daggerfall as confidants of rulers and nobles until that practice fell out of favour. nowadays, a courtesan is little more than a prostitute with a wealthy or noble clientele.
        return {
            gearList = {
                { item = "extravagant_amulet_01" },
                { item = "extravagant_skirt_02" },
                { item = "gold_001", count = goldamount},
                { item = "ab_misc_pursecoin" },
                { item = "potion_t_bug_musk_01" },
                { item = "p_restore_fatigue_s" },
                { item = "watcher's belt" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "chitin shortsword" },
            },
            spellList = {
                "stamina",
                "aa_cl_bank_power",
            },
            customSkillList = {
                { skillId = "BardicInspiration:Performance", value = 5 },
                { skillId = "painting", value = 5 },
                { skillId = "mc_Sewing", value = 5 },
            }
        }
    end,

    ["crusader"] = function()
--any heavily armored warrior with spellcasting powers and a good cause may call himself a crusader. crusaders do well by doing good. they hunt monsters and villains, making themselves rich by plunder as they rid the world of evil.
        return {
            gearList = {
                { item = "iron mace" },
                { item = "iron saber" },
                { item = "iron_greaves" },
                { item = "iron boots" },
                { item = "t_nor_wood_shield_01" },
                { item = "ab_app_grinder" },
                { item = "p_restore_fatigue_s" },
                { item = "t_rea_wormmouth_bracerl_01" },
                { item = "hammer_repair" },
            },
            spellList = {
                "aa_cl_crusad_spell",
                "clench",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 10 }
            }
        }
    end,

    ["dervish"] = function()
        return {
            gearList = {
                { item = "iron saber" },
                { item = "p_jump_s" },
                { item = "mc_toxinflask" },
                { item = "ab_app_grinder" },
                { item = "t_com_iron_throwingknife_01", count = arrowamount },
                { item = "p_restore_fatigue_s" },
                { item = "_ws_defensive_fan" },
                { item = "ingred_coprinus_01" },
                { item = "ingred_russula_01" },
            },
            spellList = {
                "aa_cl_dervish_spell01",
                "aa_cl_dervish_spell02",
            },
            customSkillList = {
                { skillId = "climbing", value = 10 },
            }
        }
    end,

    ["diplomat"] = function()
-- a diplomat is unmatched when it comes to charming and calming poeple. the very best can even talk angry people out of fighting. the only wear armor for ceremonies but always wear a blade.
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "iron saber" },
                { item = "extravagant_glove_left_01" },
                { item = "extravagant_glove_right_01" },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "expensive_robe_02_a" },
            },
            spellList = {
                "aa_cl_diplo_power",
                "aa_diplo_spell",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 15 },
            }
        }
    end,

    ["aatl_cla_baron"] = function()
-- pika aatl
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "iron saber" },
                { item = "silver dagger" },
                { item = "steel_cuirass" },
                { item = "ab_app_grinder" },
                { item = "extravagant_glove_left_01" },
                { item = "extravagant_glove_right_01" },
                { item = "steel_shield" },
                { item = "ab_misc_pursecoin" },
                { item = "expensive_robe_02_a" },
            },
            spellList = {
                "aa_cl_diplo_power",
                "aa_diplo_spell",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 15 },
            }
        }
    end,

    ["diresinger"] = function()
--the diresinger is a bard that specialises in crippling and controlling his enemies. when he fights alone, he'll weaken his enemies with a songs and finish them with daggers or bows, though he will prefer to send companions or even minions. like all bards, speechcraft and alchemy are part of his arsenal.
        return {
            gearList = {
                { item = "chitin shortsword" },
                { item = "ab_c_commonhood01" },
                { item = "netch_leather_cuirass" },
                { item = "misc_de_lute_01" },
                { item = "p_restore_fatigue_s" },
                { item = "aa_bk_songbook_dire" },
                { item = "ab_app_grinder" },
                { item = "chitin throwing star", count = arrowamount },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_rea_wormmouth_bracerl_01" },
            },
            spellList = {
                "summon scamp",
                "aa_cl_bard_power",
                "aa_cl_dire_spell",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 10 },
                { skillId = "BardicInspiration:Performance", value = 10 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["t_glb_dockworker"] = function()
--a dock worker is a waterfront unskilled laborer who load and unload vessels in port. rarely, a larger military vessel will carry its own contingent of trusted dock workers.
        return {
            gearList = {
                { item = "p_feather_c", count= 3 },
                { item = "p_restore_fatigue_s" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "chitin club" },
                { item = "belt of orc's strength" },
                { item = "ab_a_wickerhelm" },
                { item = "p_jump_s" },
                { item = "ashfall_waterskin" },
            },
            spellList = {
                "aa_cl_dock_power",
            },
            customSkillList = {
                { skillId = "fishing", value = 5 },
                { skillId = "fishingSkillId", value = 5 },
                { skillId = "PoleFishing", value = 5 },
            }
        }
    end,

    ["dreamers"] = function()
--dreamers are newly come to dagoth ur, and have not yet been infused with his power, although they are already deep in the heart of his mysteries. eventually, dreamers will progress towards transformation into an ash creature.
        return {
            gearList = {
                { item = "chitin throwing star", count = arrowamount },
                { item = "chitin club" },
                { item = "chitin shortsword" },
                { item = "p_chameleon_s" },
                { item = "netch_leather_shield" },
                { item = "left gauntlet of the horny fist" },
                { item = "right gauntlet of horny fist" },
                { item = "ingred_corprus_weepings_01", count= 3 },
            },
            spellList = {
            },
        }
    end,

    ["drillmaster"] = function()
--drillmasters train and condition the local militia, teaching the citziens the basics of block, spear, and long blade with a special consideration of athletics and acrobatics.
        return {
            gearList = {
                { item = "netch_leather_shield" },
                { item = "p_jump_s" },
                { item = "watcher's belt" },
                { item = "p_restore_fatigue_s" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "iron saber" },
                { item = "chitin shortsword" },
                { item = "chitin club" },
                { item = "chitin war axe" },
                { item = "chitin spear" },
            },
            spellList = {
            },
            customSkillList = {
                { skillId = "climbing", value = 5 },
            }
        }
    end,

    ["druid"] = function()
--druids have a great understanding of plants and creatures: they can make potent brews and calm animals. while they do use weapons and armor, they ignore anything made of metal, prefering natural material such a wood, leather or chitin. druids can also wield mystical energies.
        return {
            gearList = {
                { item = "wooden staff of peace" },
                { item = "ab_w_toolhandscythe00" },
                { item = "ab_app_grinder" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "netch_leather_cuirass" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "common_hood_01" },
                { item = "jjs_plant_firefern" },
                { item = "jjs_plant_wickwheat" },
                { item = "ashfall_waterskin" },
                { item = "ashfall_woodaxe" },
                { item = "aa_wood_boot_gnd" },
            },
            spellList = {
                "sanctuary",
                "calm creature",
                "shield",
                "aa_cl_garden_spell",
                "spell absorption",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 5 },
                { skillId = "MSS:Staff", value = 5 },
                { skillId = "mc_Woodworking", value = 5 },
                { skillId = "mc_Cooking", value = 5 },
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["vvs_druidclass"] = function()
--Druids, or "vinebeards", are children of the land whose kind have their origins in ancient High Rock. They are practitioners of Y'ffre's True Way, in which one is to lead a life connecting with, valuing, and stewarding the growth of the natural world, referred to as The Green.
        return {
            gearList = {
                { item = "wooden staff of peace" },
                { item = "ab_w_toolhandscythe00" },
                { item = "ab_app_grinder" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "netch_leather_cuirass" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "common_hood_01" },
                { item = "jjs_plant_firefern" },
                { item = "jjs_plant_wickwheat" },
                { item = "ashfall_waterskin" },
                { item = "ashfall_woodaxe" },
                { item = "aa_wood_boot_gnd" },
            },
            spellList = {
                "sanctuary",
                "calm creature",
                "shield",
                "aa_cl_garden_spell",
                "spell absorption",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 5 },
                { skillId = "MSS:Staff", value = 5 },
                { skillId = "mc_Woodworking", value = 5 },
                { skillId = "mc_Cooking", value = 5 },
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["duelist"] = function()
--duelists are combatants who in fight rely on finesse, perfect form and quickness over brute force. uncommon among fighters, the duelists do not wear any armor at all preferring maximum speed and not being hit at all. duelists are known to possess a silver tongue and are exceptionally nimble and quick.
        return {
            gearList = {
                { item = "chk_rap_iron" },
                { item = "iron saber" },
                { item = "watcher's belt" },
                { item = "aa_cl_speech_pot" },
                { item = "p_restore_fatigue_s" },
                { item = "p_jump_s" },
                { item = "chitin shortsword" },
                { item = "hammer_repair", },
                { item = "p_chameleon_s" },
            },
            spellList = {
                "aa_cl_duel_spell",
            },
        }
    end,

    ["enchanter"] = function()
--enchanters trade with enchanted items, weapons, armor, and clothes. they also enchant items such as scrolls and sell them, or offer their lab for others to use - against a fee, of course.
        return {
            gearList = {
                { item = "sx2_quillsword" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "misc_soulgem_lesser" },
                { item = "misc_soulgem_common" },
                { item = "misc_soulgem_greater" },
                { item = "wooden staff" },
                { item = "ab_app_grinder" },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "ab_sc_blank", count= 3 },
                { item = "common_robe_02_t"},
                { item = "sc_paper plain", count= 3 },
            },
            spellList = {
                "aa_cl_enchat_spell",
                "soul trap",
                "bound mace",
                "slowfall",
                "dire earwig",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 20 },
                { skillId = "common.inscriptionSkillId", value = 15 },
            }
        }
    end,

    ["enforcer"] = function()
--enforcers serve crimebosses as thugs. their boss makes the rules and they enforce them by physical or magical force.
        return {
            gearList = {
                { item = "chitin shortsword" },
                { item = "netch_leather_helm" },
                { item = "netch_leather_cuirass" },
                { item = "chitin throwing star", count = arrowamount },
                { item = "p_chameleon_s" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "p_restore_fatigue_s" },
                { item = "netch_leather_shield" },
                { item = "aa_thw_net", count = 3 },
            },
            spellList = {
                "five fingers of pain",
                "burden",
            },
        }
    end,

    ["farmer"] = function()
--farmers grow crops, and raise animals for food, and gather animal products and vegetable products from the land for their own use or for sale at the markets.
        return {
            gearList = {
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "ab_a_wickerhelm" },
                { item = "p_restore_fatigue_s" },
                { item = "t_com_farm_pitchfork_01" },
                { item = "t_com_farm_shovel_01" },
                { item = "ingred_ash_yam_01", count = 3 },
                { item = "ashfall_waterskin" },
            },
            spellList = {
                "aa_cl_garden_spell",
            },
            customSkillList = {
                { skillId = "mc_Crafting", value = 5 },
                { skillId = "mc_Metalworking", value = 5 },
                { skillId = "mc_Woodworking", value = 5 },
                { skillId = "mc_Cooking", value = 5 },
            }
        }
    end,

    ["t_glb_fisherman"] = function()
--fishermen work on boats to catch fishes on oceans, rivers, and causeways with lines, nets, or spears. some also work as salt-makers, sailors, or collect and sell reed.
        return {
            gearList = {
                { item = "chitin spear" },
                { item = "mer_fishing_net" },
                { item = "misc_de_fishing_pole" },
                { item = "ashfall_crabpot_02_m" },
                { item = "nom_food_fish", count= 2 },
                { item = "mer_bug_spinner" },
                { item = "nom_food_fish_fat_02", count= 2 },
                { item = "p_restore_fatigue_s" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "ab_a_wickerhelm" },
                { item = "netch_leather_shield" },
                { item = "ashfall_waterskin" },
            },
            spellList = {
            },
            customSkillList = {
                { skillId = "fishing", value = 20 },
                { skillId = "fishingSkillId", value = 20 },
                { skillId = "PoleFishing", value = 20 },
                { skillId = "mc_Crafting", value = 5 },
            }
        }
    end,

    ["gambler"] = function()
--gamblers primarily rely on luck. they will take leaps of faith, confident that the stars will guide them to safety. gamblers wear no armor, betting on speed or their opponent's clumsiness. the gambler is quite charming in their candor that things will turn out all right, with just a bit of luck.
        return {
            gearList = {
                { item = "aa_coin41" },
                { item = "t_com_dice_01" },
                { item = "t_de_cardhortempty" },
                { item = "t_com_iron_throwingknife_01", count = arrowamount },
                { item = "watcher's belt" },
                { item = "aa_cl_speech_pot" },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "chitin shortsword" },
            },
            spellList = {
                "aa_cl_gambl_power",
                "absorb luck",
                "aa_cl_gambl_spell",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 5 },
                { skillId = "BardicInspiration:Performance", value = 5 },
                { skillId = "common.inscriptionSkillId", value = 5 },
                { skillId = "mc_Crafting", value = 5 },
                { skillId = "climbing", value = 5 },
            }
        }
    end,

    ["gardener"] = function()
--gardeners tend the plants and trees, and keep them looking pretty. they are often employed by nobility or the temple to keep their parks and gardens watered when it's dry and dusty.
        return {
            gearList = {
                { item = "jjs_plant_timsa" },
                { item = "jjs_plant_gldkan" },
                { item = "jjs_plant_gldkan" },
                { item = "jjs_plant_gldkan" },
                { item = "t_com_farm_hoe_01" },
                { item = "t_com_farm_trovel_01" },
                { item = "ab_app_grinder" },
                { item = "watcher's belt" },
                { item = "gold_001", count = 20 },
                { item = "ab_misc_pursecoin" },
                { item = "p_restore_fatigue_s" },
                { item = "ingred_stoneflower_petals_01", count = 3 },
                { item = "ingred_gold_kanet_01", count = 3 },
                { item = "ingred_timsa-come-by_01", count = 3 },
                { item = "ashfall_waterskin" },
            },
            spellList = {
                "mother's kiss",
                "aa_cl_garden_spell",
                "absorb fatigue",
                "feather",
            },
            customSkillList = {
                { skillId = "mc_Crafting", value = 5 },
            }
        }
    end,

    ["gladiator"] = function()
--gladiators fight in arenas across tamriel for the entertainment of others. in morrowind, slaves are sometimes trained as gladiators, but others fight for fame and fortune.
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "chitin spear" },
                { item = "netch_leather_shield" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "p_restore_fatigue_s" },
                { item = "iron saber" },
                { item = "t_rea_wormmouth_pauldronl_01" },
                { item = "aa_glad_cuirass_glad" },
                { item = "aa_glad_boots_glad(e)" },
                { item = "p_jump_s" },
            },
            spellList = {
                "aa_cl_barbar_power",
            },
        }
    end,

    ["guard"] = function()
--guards keep the peace, collect fines and compensation, and chase down criminals to drag them off to prison. each local authority employs its own guards, and there is always work for them.
        return {
            gearList = {
                { item = "iron saber" },
                { item = "t_com_wood_mace_01" },
                { item = "t_nor_wood_shield_01" },
                { item = "imperial_chain_coif_helm" },
                { item = "imperial_chain_pauldron_left" },
                { item = "imperial_chain_pauldron_right" },
                { item = "imperial boots" },
                { item = "p_jump_s" },
            },
            spellList = {
                "aa_cl_guard_power",
            },
        }
    end,

    ["healer"] = function()
--healers are spellcasters who swear solemn oaths to heal the afflicted and cure the diseased. when threatened, they defend themselves with reason and disabling attacks and magic, relying on deadly force only in extremity.
        return {
            gearList = {
                { item = "ab_alc_healbandage01", count = 2 },
                { item = "ab_c_commonhood05b"},
                { item = "ab_app_grinder" },
                { item = "common_robe_05_b"},
                { item = "wooden staff" },
            },
            spellList = {
                "restore attributes",
                "cure common disease other",
                "mother's kiss",
                "absorb health",
                "calming touch",
            },
        }
    end,

    ["herder"] = function()
--herders watch over their herds of guars, shalk, or netches. they are responsible for defending them against predators, bandits, and illnesses. they also butcher them and preparing the meat, skin, and other ingredients for use by craftsmen, cooks, or alchemists.
        return {
            gearList = {
                { item = "mer_tgw_flute" },
                { item = "mc_organic_kit" },
                { item = "ab_dri_guarmilk", count= 2 },
                { item = "ab_a_wickerhelm" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "ab_w_toolpitchfork" },
                { item = "p_restore_fatigue_s" },
                { item = "chitin war axe" },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_rea_wormmouth_bracerl_01" },
                { item = "ingred_guar_hide_01", count= 2 },
                { item = "ashfall_woodaxe" },
                { item = "ashfall_waterskin" },
                { item = "aa_thw_net", count = 3 },
            },
            spellList = {
                "aa_cl_garden_spell",
            },
            customSkillList = {
                { skillId = "mc_Crafting", value = 5 },
            }
        }
    end,

    ["hermit"] = function()
--whether for religious reasons or merely personal preference, hermits choose to live solitary lives. it takes someone of versatile skill and knowledge to be entirely self-sufficient. hermits develop advanced expertise of local flora and fauna.
        return {
            gearList = {
                { item = "mc_organic_kit" },
                { item = "ab_app_grinder" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "hammer_repair", count = 2 },
                { item = "p_chameleon_s" },
                { item = "ab_c_commonhood01" },
                { item = "wooden staff" },
                { item = "misc_com_iron_ladle" },
                { item = "nom_food_cabbage", count = 2 },
                { item = "common_robe_01"},
                { item = "ashfall_woodaxe" },
                { item = "ashfall_grill" },
                { item = "ashfall_kettle_06" },
                { item = "ashfall_waterskin" },
                { item = "ashfall_strawbed" },
                { item = "ashfall_firewood", count = 4 },
            },
            spellList = {
                "fire shield",
                "hearth heal",
                "five fingers of pain",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 15 },
                { skillId = "fishing", value = 15 },
                { skillId = "fishingSkillId", value = 15 },
                { skillId = "PoleFishing", value = 5 },
                { skillId = "fletching", value = 5 },
                { skillId = "mc_Fletching", value = 5 },
                { skillId = "mc_Sewing", value = 5 },
                { skillId = "mc_Crafting", value = 10 },
                { skillId = "mc_Woodworking", value = 10 },
                { skillId = "Bushcrafting", value = 10 },
                { skillId = "mc_Cooking", value = 10 },
            }
        }
    end,

    ["hood"] = function()
--hoods are the common clay of the criminal underworld. thugs and gangsters, hoods favor fighting in close quarters using daggers, short clubs, and fists.
        return {
            gearList = {
                { item = "lbonemold brace of horny fist" },
                { item = "rbonemold bracer of horny fist" },
                { item = "chitin shortsword" },
                { item = "t_com_wood_mace_01" },
                { item = "t_rea_wormmouth_helm_01" },
                { item = "p_chameleon_s" },
                { item = "chitin war axe" },
                { item = "t_nor_wood_shield_01" },
                { item = "p_restore_fatigue_s" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "aa_scarf_grey" },
            },
            spellList = {
            },
        }
    end,

    ["hunter"] = function()
--hunters range across the lands, hunting for meat and hides. they know the native creatures, and know how to best avoid the diseased creatures.
        return {
            gearList = {
                { item = "mc_organic_kit" }, --75
                { item = "ashfall_woodaxe" },
                { item = "ashfall_waterskin" },
                { item = "mer_fletch_kit" },
                { item = "mc_Fletching_kit" },
                { item = "t_rea_wormmouth_helm_01" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "chitin shortsword" },
                { item = "p_chameleon_s" },
                { item = "p_restore_fatigue_s" },
                { item = "aa_thw_net", count = 3 },
            },
            spellList = {
                "stamina",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 5 },
                { skillId = "fishing", value = 5 },
                { skillId = "fishingSkillId", value = 5 },
                { skillId = "PoleFishing", value = 5 },
                { skillId = "fletching", value = 10 },
                { skillId = "mc_Fletching", value = 10 },
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["t_sky_jarl"] = function()
-- jarls are the second highest ranking title in the hierarchy of nordic kingdoms, answering only to their king. the jarl acts as a vassal to the king, but essentially rules a jarldom of his or her own. most jarl titles are heriditary, and as with most nord nobility, future jarls are trained from young age in the skills of combat, war and diplomacy.
        return {
            gearList = {
                { item = "nordic broadsword" },
                { item = "nordic_ringmail_cuirass" },
                { item = "nordic_iron_helm" },
                { item = "bm bear shield"},
                { item = "nordic battle axe"},
                { item = "aa_cl_speech_pot" },
                { item = "hammer_repair", count = 2 },
                { item = "iron mace" },
                { item = "iron halberd" },
                { item = "p_restore_fatigue_s" },
            },
            spellList = {
            },
        }
    end,

    ["jester"] = function()
--the jester is often underestimated. jester are physical entertainers, performing feats of skill and wits at court. it is a frequent mistake to conflate a jester’s intelligence with that of the bumbling character they often play. the jester relies on tricks and deception and is the most proficient spellcaster of all the bards.
        return {
            gearList = {
                { item = "jokesofdaggerfall" },
                { item = "aa_cl_jester_hat" },
                { item = "p_chameleon_s" },
                { item = "p_jump_s" },
                { item = "potion_t_bug_musk_01" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "aa_bk_songbook_bard" },
                { item = "ab_app_grinder" },
                { item = "bk_yellowbookofriddles" },
            },
            spellList = {
                "five fingers of pain",
                "crying eye",
                "aa_cl_bank_power",
                "stamina",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 5 },
                { skillId = "BardicInspiration:Performance", value = 5 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["journalist"] = function()
--journalists gather the news and print them.
        return {
            gearList = {
                { item = "sc_paper plain", count= 3 },
                { item = "misc_inkwell" },
                { item = "misc_quill" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "ab_sc_blank" },
                { item = "watcher's belt" },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "aa_cl_speech_pot" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "ab_app_grinder" },
            },
            spellList = {
                "mark",
                "mother's kiss",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 5 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["juggler"] = function()
--jugglers use the magic arts to entertain and amaze, causing fireballs and knives to dance through the air in feats of artistic and technical skill that defy the laws of nature.
        return {
            gearList = {
                { item = "food_kwama_egg_01", count= 5 },
                { item = "t_com_iron_throwingknife_01", count = arrowamount },
                { item = "chitin shortsword" },
                { item = "p_jump_s" },
                { item = "p_chameleon_s" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
            },
            spellList = {
                "fireball",
                "calming touch",
                "lock",
                "absorb agility",
            },
            customSkillList = {
                { skillId = "BardicInspiration:Performance", value = 5 },
                { skillId = "fletching", value = 5 },
                { skillId = "mc_Fletching", value = 5 },
                { skillId = "climbing", value = 5 },
            }
        }
    end,

    ["king"] = function()
--kings are at the top of the local nobility. only the emperor himself is above them, and it is him who they report to.
        return {
            gearList = {
                { item = "potion_t_bug_musk_01" },
                { item = "silver longsword" },
                { item = "silver_cuirass" },
                { item = "exquisite_pants_01" },
                { item = "gold_001", count = goldamount },
                { item = "gold_001", count = goldamount },
                { item = "exquisite_shirt_01" },
                { item = "exquisite_shoes_01" },
            },
            spellList = {
                "aa_cl_king_power",
            },
        }
    end,

    ["knight"] = function()
--of noble birth, or distinguished in battle or tourney, knights are civilized warriors, schooled in letters and courtesy, governed by the codes of chivalry. in addition to the arts of war, knights study the lore of healing and enchantment.
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "hammer_repair", count = 2 },
                { item = "ab_misc_pursecoin" },
                { item = "t_imp_chain_boots_01" },
                { item = "steel_shield" },
                { item = "steel longsword" },
                { item = "steel_cuirass" },
            },
            spellList = {
                "fortify block skill",
            },
        }
    end,

    ["mabrigash"] = function()
--a mabrigash is an outcast ashlander witch-warrior, women who defy the ashlanders' rules of behavior for women, mastering weapons of war and powerful sorcery.
        return {
            gearList = {
                { item = "ashfall_kettle_04" },
                { item = "ashfall_woodaxe" },
                { item = "chitin war axe" },
                { item = "netch_leather_shield" },
                { item = "watcher's belt" },
                { item = "aa_cl_speech_pot" },
                { item = "p_restore_fatigue_s" },
                { item = "war_mlsnd_boot_01" },
                { item = "expensive_robe_01"},
            },
            spellList = {
                "aa_cl_mabrig_spell",
                "turn of the wheel",
                "absorb health",
                "burden",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 10 },
                { skillId = "fishing", value = 5 },
                { skillId = "fishingSkillId", value = 5 },
                { skillId = "PoleFishing", value = 5 },
                { skillId = "mc_Crafting", value = 15 },
                { skillId = "mc_Cooking", value = 5 },
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["mage"] = function()
--most mages claim to study magic for its intellectual rewards, but they also often profit from its practical applications. varying widely in temperament and motivation, mages share but one thing in common: an avid love of spellcasting.
        return {
            gearList = {
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "ab_app_grinder" },
                { item = "chitin shortsword" },
                { item = "common_robe_03_b" },
            },
            spellList = {
                "bound dagger",
                "aa_cl_mage_abil",
                "absorb health",
                "poison",
                "weakness to poison",
                "levitate",
                "invisibility",
                "hearth heal",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 10 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["aatl_cla_college_initiate"] = function()
-- pika aatl
        return {
            gearList = {
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "aa_nordic silver dagger" },
                { item = "bm_wool01_robe" },
                { item = "oj_w_woodtwigswand_en_cshb" },
            },
            spellList = {
                "aa_cl_mage_abil",
                "absorb health",
                "poison",
                "weakness to poison",
                "levitate",
                "invisibility",
                "hearth heal",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 5 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["marauder"] = function()
--marauders are powerful warriors, favoring massive two-handed weapons. marauders subscribe to the philosophy that a good offense is the best defense, forgoing shields and relying only on their armor to protect them.
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "t_com_wood_mace_01" },
                { item = "t_rea_wormmouth_pauldronl_01" },
                { item = "t_rea_wormmouth_pauldronr_01" },
                { item = "t_com_iron_cuirass_01" },
                { item = "iron saber" },
                { item = "chitin spear" },
                { item = "lbonemold brace of horny fist" },
                { item = "rbonemold bracer of horny fist" },
                { item = "hammer_repair", count = 2 },
                { item = "aa_scarf_grey" },
            },
            spellList = {
            },
            customSkillList = {
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["master-at-arms"] = function()
--masters-at-arms are dedicated weapon trainers, having mastered all the basic hand weapon types: long blades, short blades, axes, blunt weapons, and spears.
        return {
            gearList = {
                { item = "chitin spear" },
                { item = "chitin shortsword" },
                { item = "iron saber" },
                { item = "chitin war axe" },
                { item = "t_com_wood_mace_01" },
                { item = "netch_leather_shield" },
                { item = "netch_leather_cuirass" },
                { item = "t_rea_wormmouth_helm_01" },
                { item = "t_com_iron_pauldronr_01" },
                { item = "t_com_iron_pauldronl_01" },
            },
            spellList = {
            },
            customSkillList = {
                { skillId = "mc_Smithing", value = 5 },
                { skillId = "mc_Metalworking", value = 5 },
            }
        }
    end,

    ["mercenary"] = function()
--mercenaries are rugged fighters who employ their reputable martial prowess in service of whoever pays them the most. mercenaries are strong and physically conditioned.
        return {
            gearList = {
                { item = "t_com_iron_cuirass_01" },
                { item = "t_com_iron_pauldronr_01" },
                { item = "t_com_iron_pauldronl_01" },
                { item = "chitin war axe" },
                { item = "iron saber" },
                { item = "ab_misc_pursecoin" },
                { item = "p_restore_fatigue_s" },
                { item = "hammer_repair", count = 2 },
                { item = "t_com_wood_mace_01" },
                { item = "ab_w_woodcrossbow" },
                { item = "t_com_wood_bolt_01", count = arrowamount },
                { item = "iron_shield" },
            },
            spellList = {
            },
        }
    end,

    ["merchant"] = function()
--merchants look for goods that are well-made, and can be sold at a profit. there are many different kinds of materials a merchant can buy and sell -- animal products, vegetable products, mineral products, even exotic products. crafts and manufactured goods they deal in include weapons, armor, clothing, books, potions, enchanted items, and various housewares.
        return {
            gearList = {
                { item = "gold_001", count = goldamount },
                { item = "gold_001", count = goldamount },
                { item = "potion_t_bug_musk_01" },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "hammer_repair", count = 2 },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_rea_wormmouth_bracerl_01" },
                { item = "watcher's belt" },
                { item = "ab_c_commonhood01" },
                { item = "t_imp_cm_bootscol_01" },
                { item = "t_com_wood_mace_01" },
                { item = "iron saber" },
            },
            spellList = {
                "charisma",
                "aa_cl_pawn_power",
            },
        }
    end,

    ["ab_eggminer"] = function()
--OAAB not playable by default
        return {
            gearList = {
                { item = "netch_leather_shield" },
                { item = "t_com_wood_mace_01" },
                { item = "miner's pick" },
                { item = "ab_a_wickerhelm" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "iron boots" },
                { item = "hammer_repair"},
                { item = "chitin spear" },
                { item = "food_kwama_egg_02", count= 2 },
                { item = "food_kwama_egg_01", count= 3 },
            },
            spellList = {
                "stamina",
            },
            customSkillList = {
                { skillId = "mc_Crafting", value = 5 },
                { skillId = "mc_Mining", value = 15 },
                { skillId = "mc_Cooking", value = 5 },
            }
        }
    end,

    ["miner"] = function()
--in morrowind, being a miner usually means being a kwama miner. kwama miners extrace kwama eggs from egg mines, feeding the population.
        return {
            gearList = {
                { item = "netch_leather_shield" },
                { item = "t_com_wood_mace_01" },
                { item = "miner's pick" },
                { item = "ab_a_wickerhelm" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "iron boots" },
                { item = "hammer_repair"},
                { item = "chitin spear" },
                { item = "food_kwama_egg_02", count= 2 },
                { item = "food_kwama_egg_01", count= 3 },
            },
            spellList = {
                "stamina",
            },
            customSkillList = {
                { skillId = "mc_Crafting", value = 5 },
                { skillId = "mc_Mining", value = 15 },
                { skillId = "mc_Cooking", value = 5 },
            }
        }
    end,

    ["monk"] = function()
--monks are students of the ancient martial arts of hand-to-hand combat and unarmored self-defense. monks avoid detection by stealth, mobility, and agility, and are skilled with a variety of ranged and close-combat weapons.
        return {
            gearList = {
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "aa_nin3_shirt3" },
                { item = "_ws_right_tonfa" },
                { item = "watcher's belt" },
                { item = "p_restore_fatigue_s" },
                { item = "p_jump_s" },
                { item = "p_chameleon_s" },
                { item = "netch_leather_shield" },
                { item = "chitin throwing star", count = arrowamount },
                { item = "ab_a_wickerhelm" },
                { item = "war_khajiit_wrstwrp01_r" },
                { item = "war_khajiit_wrstwrp01_l" },
            },
            spellList = {
                "fortify hand to hand skill",
            },
            customSkillList = {
                { skillId = "MSS:Staff", value = 10 },
                { skillId = "climbing", value = 5 },
            }
        }
    end,

    ["necromancer"] = function()
--necromancers are mages who summon the spirits of the dead or raise them bodily. in the empire, necromancy is a legitimate discipline, though body and spirit are protected property, and may not be used without permission of the owner. in morrowind, the dunmer loathe philosophical necromancers, and put them to death. however, using sacred necromancy, the dunmer summon their own dead to guard tombs and defend the family.
        return {
            gearList = {
                { item = "aa_necro_night_scroll" },
                { item = "bk_corpsepreperation1_c" },
                { item = "t_com_embalming_hook_01" },
                { item = "liche_robe1_c" },
                { item = "ab_misc_soulgemblack" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "wooden staff" },
                { item = "common_robe_02_h"},
                { item = "misc_skull10"},
            },
            spellList = {
                "summon skeletal minion",
                "aa_cl_necro_spell",
                "aa_cl_necro_spell02",
                "aa_cl_necro_spell03",
                "soul trap",
                "shield",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 10 },
                { skillId = "NC:CorpsePreparation", value = 20 },
            }
        }
    end,

    ["nightblade"] = function()
--nightblades are spellcasters who use their magics to enhance mobility, concealment, and stealthy close combat. they have a sinister reputation, since many nightblades are thieves, enforcers, assassins, or covert agents.
        return {
            gearList = {
                { item = "p_chameleon_s" },
                { item = "chitin shortsword" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "ab_c_commonhood01" },
                { item = "t_imp_cm_bootscol_01" },
            },
            spellList = {
                "righteousness",
                "invisibility",
                "feather",
                "five fingers of pain",
            },
        }
    end,

    ["ninja"] = function()
--ninjas have trained very hard to become the ultimate assassin; they can sneak into the enemy's base and retrieve documents or kill the leader. they favor throwing items and may use secret techniques akin to magic.
        return {
            gearList = {
                { item = "left gauntlet of the horny fist" },
                { item = "_ws_right_tonfa" },
                { item = "aa_nin3_shirt3" },
                { item = "right gauntlet of horny fist" },
                { item = "chitin throwing star", count = arrowamount },
                { item = "p_chameleon_s" },
                { item = "p_jump_s" },
                { item = "ab_c_commonhood01" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "p_restore_fatigue_s" },
                { item = "netch_leather_pauldron_right" },
                { item = "netch_leather_pauldron_left" },
                { item = "war_khajiit_wrstwrp01_r" },
                { item = "war_khajiit_wrstwrp01_l" },
            },
            spellList = {
                "sanctuary",
                "recall",
            },
            customSkillList = {
                { skillId = "climbing", value = 10 },
            }
        }
    end,

    ["noble"] = function()
--nobles are elevated by birth and distinction to the highest ranks of imperial society. they do not a have trades per se, but dabble in various affairs, collecting rare treasures of beauty and refinement. in return, they serve at the command of the emperor and the councils, giving counsel and support, and, when duty calls, taking spell and sword to protect the smallfolk of the empire.
        return {
            gearList = {
                { item = "gold_001", count = goldamount },
                { item = "gold_001", count = goldamount },
                { item = "gold_001", count = 50 },
                { item = "extravagant_robe_01" },
                { item = "extravagant_shoes_01" },
                { item = "potion_t_bug_musk_01" },
                { item = "firebite dagger" },
                { item = "ab_c_extravaganthood01" },
                { item = "netch_leather_shield" },
                { item = "ab_misc_pursecoin" },
            },
            spellList = {
                "aa_cl_noble_ability",
                "turn of the wheel",
            },
            customSkillList = {
                { skillId = "painting", value = 5 },
            }
        }
    end,

    ["ordinator"] = function()
--ordinators are the priest-soldiers of the tribunal temple. they have the duty of keeping worshippers from restoring the old daedric sites scattered throughout the wastelands and along the rocky coasts and islands of morrowind. they also fight witchcraft, necromancy, and vampirism.
        return {
            gearList = {
                { item = "t_com_wood_mace_01" },
                { item = "iron saber" },
                { item = "t_com_iron_pauldronr_01" },
                { item = "t_com_iron_pauldronl_01" },
                { item = "t_imp_chain_gauntletl_01t" },
                { item = "t_imp_chain_gauntletr_02" },
                { item = "iron_shield" },
                { item = "ab_app_grinder" },
                { item = "p_jump_s" },
                { item = "t_rea_wormmouth_helm_01" },
                { item = "t_bk_sermonofthesaintstr" },
            },
            spellList = {
                "five fingers of pain",
                "cure common disease",
            },
        }
    end,

    ["t_mw_oreminer"] = function()
--ore miners extract rare minerals, such as glass, diamonds or ebony from the earth.
        return {
            gearList = {
                { item = "miner's pick" },
                { item = "t_ingmine_oreiron_01" },
                { item = "t_ingmine_coal_01" },
                { item = "hammer_repair", count = 2 },
                { item = "t_com_wood_mace_01" },
                { item = "iron_shield" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "iron saber" },
            },
            spellList = {
                "aa_cl_dock_power",
            },
            customSkillList = {
                { skillId = "mc_Crafting", value = 5 },
                { skillId = "mc_Metalworking", value = 5 },
                { skillId = "mc_Masonry", value = 5 },
                { skillId = "mc_Mining", value = 15 },
            }
        }
    end,

    ["paladin"] = function()
--paladins are knights in service to the aedra or good daedra. in return they benefit from more magical capability than secular knights.
        return {
            gearList = {
                { item = "iron saber" },
                { item = "iron_shield" },
                { item = "iron_greaves" },
                { item = "iron boots" },
                { item = "t_com_iron_cuirass_01" },
                { item = "aa_cl_speech_pot" },
                { item = "chitin spear" },
                { item = "hammer_repair", count = 2 },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "ab_app_grinder" },
                { item = "bk_formygodsandemperor" }
            },
            spellList = {
                "aa_cl_pally_power",
                "divine intervention",
                "aa_cl_pally_spell",
                "aa_cl_pally_power02",
            },
        }
    end,

    ["pauper"] = function()
--pauper are the humblest smallfolk. they make their way in the world as best they can, providing unskilled labor in the fields, kitchens, and factories of lords and merchants.
        return {
            gearList = {
                { item = "p_restore_fatigue_s" },
                { item = "t_com_var_bottleweapon_01" },
                { item = "nordic_leather_shield" },
                { item = "p_chameleon_s" },
                { item = "ab_misc_pursecoin" },
                { item = "t_com_wood_mace_01" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
            },
            spellList = {
                "aa_cl_pauper_power",
            },
            customSkillList = {
                { skillId = "fishing", value = 5 },
                { skillId = "fishingSkillId", value = 5 },
                { skillId = "PoleFishing", value = 5 },
                { skillId = "mc_Sewing", value = 5 },
                { skillId = "mc_Crafting", value = 5 },
                { skillId = "mc_Cooking", value = 5 },
            }
        }
    end,

    ["pawnbroker"] = function()
--pawnbrokers offer secured loans by using goods as collateral. they also sell pawned things, sometimes used and worn, sometimes almost new, and all for a fraction of what they'd cost if purchased elsewhere.
        return {
            gearList = {
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "p_restore_fatigue_s" },
                { item = "aa_cl_speech_pot" },
                { item = "watcher's belt" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "netch_leather_shield" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "t_com_wood_mace_01" },
                { item = "misc_de_bowl_bugdesign_01" },
                { item = "misc_de_bowl_glass_peach_01" },
                { item = "misc_com_redware_platter" },
            },
            spellList = {
                "aa_cl_pawn_power",
            },
            customSkillList = {
                { skillId = "mc_Crafting", value = 5 },
            }
        }
    end,

    ["pearl diver"] = function()
--pear divers make a living finding pearl in the waters of morrowind
        return {
            gearList = {
                { item = "ashfall_crabpot_02_m" },
                { item = "_mm_pearl_blue" },
                { item = "ingred_pearl_01" },
                { item = "chitin shortsword" },
                { item = "chitin spear" },
                { item = "p_restore_fatigue_s" },
                { item = "ab_app_grinder" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
            },
            spellList = {
                "vigor",
                "aa_cl_pearl",
            },
            customSkillList = {
                { skillId = "fishing", value = 15 },
                { skillId = "fishingSkillId", value = 15 },
                { skillId = "PoleFishing", value = 15 },
                { skillId = "mc_Crafting", value = 5 },
            }
        }
    end,

    ["pilgrim"] = function()
--pilgrims are travelers, seekers of truth and enlightenment. they fortify themselves for road and wilderness with arms, armor, and magic, and through wide experience of the world, they become shrewd in commerce and persuasion.
        return {
            gearList = {
                { item = "ashfall_waterskin" },
                { item = "war_mlsnd_boot_01" },
                { item = "aa_cl_speech_pot" },
                { item = "ab_misc_pursecoin" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "t_rea_wormmouth_pauldronl_01" },
                { item = "t_rea_wormmouth_pauldronr_01" },
                { item = "ab_app_grinder" },
                { item = "t_nor_wood_shield_01" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "chitin shortsword" },
                { item = "ashfall_woodaxe" },
            },
            spellList = {
                "veloth's grace",
                "light",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 5 },
                { skillId = "daedricSkillId", value = 5 },
            }
        }
    end,

    ["pirate"] = function()
--pirates roam the seas plundering coastal towns and good-laden ships. they are skilled with both ranged and melee weapons. even when stuck without a ship, a pirate still embodies their defining trait, a love of freedom.
        return {
            gearList = {
                { item = "gold_001", count = goldamount },
                { item = "ingred_emerald_01" },
                { item = "tm_treasure_map" },
                { item = "iron saber" },
                { item = "netch_leather_shield" },
                { item = "t_com_iron_throwingknife_01", count = arrowamount },
                { item = "gold_001", count = 70 },
                { item = "ab_misc_pursecoin" },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_rea_wormmouth_bracerl_01" },
                { item = "p_chameleon_s" },
                { item = "ssa_blackpiratehat" },
                { item = "aa_deck_green" },
                { item = "aa_deck_green" },
            },
            spellList = {
                "chameleon",
                "aa_cl_pirate_power",
            },
            customSkillList = {
                { skillId = "fishing", value = 5 },
                { skillId = "fishingSkillId", value = 5 },
                { skillId = "PoleFishing", value = 5 },
            }
        }
    end,

    ["aatl_cla_abecean_pirate"] = function()
-- -- pika aatl
        return {
            gearList = {
                { item = "gold_001", count = goldamount },
                { item = "ingred_emerald_01" },
                { item = "tm_treasure_map" },
                { item = "iron saber" },
                { item = "t_com_iron_throwingknife_01", count = arrowamount },
                { item = "gold_001", count = 60 },
                { item = "ab_misc_pursecoin" },
                { item = "netch_leather_boiled_cuirass" },
                { item = "p_chameleon_s" },
                { item = "ssa_blackpiratehat" },
                { item = "aa_deck_green" },
                { item = "aa_deck_green" },
            },
            spellList = {
                "chameleon",
                "aa_cl_pirate_power",
            },
            customSkillList = {
                { skillId = "fishing", value = 5 },
                { skillId = "fishingSkillId", value = 5 },
                { skillId = "PoleFishing", value = 5 },
            }
        }
    end,


    ["poacher"] = function()
--poachers are hunters for whom the advantages of hunting on private or protected lands outweigh the risks of being caught. poachers make use of illusion magic to avoid detection and help them talk their way out of problems, and wear medium armor as a compromise between speed and extra protection.
        return {
            gearList = {
                { item = "chitin spear" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_rea_wormmouth_bracerl_01" },
                { item = "p_chameleon_s" },
                { item = "p_restore_fatigue_s" },
                { item = "p_jump_s" },
                { item = "ab_app_grinder" },
                { item = "ab_misc_pursecoin" },
                { item = "aa_cl_speech_pot" },
                { item = "ingred_hound_meat_01", count = 4 },
                { item = "aa_thw_net", count = 3 },
            },
            spellList = {
                "chameleon",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 5 },
                { skillId = "fishing", value = 10 },
                { skillId = "fishingSkillId", value = 10 },
                { skillId = "PoleFishing", value = 5 },
                { skillId = "fletching", value = 5 },
                { skillId = "mc_Fletching", value = 5 },
                { skillId = "mc_Crafting", value = 5 },
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["poet"] = function()
--poets are people who sing tales about great battles and write them in books so that they can be memorised for generations. their silver tongues cannot be matched.
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "chitin shortsword" },
                { item = "watcher's belt" },
                { item = "misc_de_lute_01", },
                { item = "aa_bk_songbook_bard", },
                { item = "ashfall_waterskin" },
                { item = "ab_app_grinder" },
                { item = "p_restore_fatigue_s" },
                { item = "iron saber" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "sc_paper plain", count= 3 },
                { item = "misc_inkwell" },
                { item = "misc_quill" },
            },
            spellList = {
                "shock barrier",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 10 },
                { skillId = "BardicInspiration:Performance", value = 5 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["priest"] = function()
--priests act as intercessors between the gods and their worshippers. as caretakers of the temples and shrines, and councilor and educator for the faithful and laymen, they hold onto the myths and lore of old.
        return {
            gearList = {
                { item = "wooden staff" },
                { item = "common_robe_05_a"},
                { item = "watcher's belt" },
                { item = "aa_cl_speech_pot" },
                { item = "ab_c_commonhood05a" },
                { item = "ab_app_grinder" },
            },
            spellList = {
                "cure common disease other",
                "restore attributes",
                "levitate",
                "turn undead",
                "soul trap",
                "spirit knife",
                "aa_cl_pally_spell",
            },
        }
    end,

    ["publican"] = function()
--publicans maintain inns and pubs. they offer food and drinks to buy, and beds for lodgers. they know the neighborhood, and can share local lore and small rumors.
        return {
            gearList = {
                { item = "dhb_mug_coffee" },
                { item = "lfl_br_vvardenfell" },
                { item = "nom_food_crab_slice" },
                { item = "t_ingfood_cookie_01" },
                { item = "t_de_drink_liquorllotham_01" },
                { item = "gold_001", count = goldamount },
                { item = "ingred_bread_01" },
                { item = "potion_local_brew_01" },
                { item = "aa_cl_speech_pot" },
                { item = "ab_misc_pursecoin" },
                { item = "left gauntlet of the horny fist" },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "probe_journeyman_01" },
                { item = "netch_leather_shield" },
                { item = "t_com_wood_mace_01" },
                { item = "chitin spear" },
            },
            spellList = {
                "aa_cl_pawn_power",
            },
            customSkillList = {
                { skillId = "mc_Cooking", value = 15 },
            }
        }
    end,

    ["pugilist"] = function()
--pugilists are dedicated fistfighters and paragons of physical fitness. they prefer to fight unencumbered by armor. if they run into a dangerous situation, rather than turning to weapons pugilists will use magic to even the odds, silencing mages or blinding warriors.
        return {
            gearList = {
                { item = "left gauntlet of the horny fist" },
                { item = "right gauntlet of horny fist" },
                { item = "p_restore_fatigue_s" },
                { item = "p_jump_s" },
            },
            spellList = {
                "silence",
                "blind",
                "sanctuary",
                "mother's kiss",
                "stamina",
                "bound gauntlets",
                "shield",
            },
        }
    end,

    ["pyromancer"] = function()
--pyromancers excel at destruction and favour fire spells above all others. they often wield staves and are competent in other schools of magic. they prefer treated leather armour to resist the flames but may forego armor altogether.
        return {
            gearList = {
                { item = "ingred_fire_salts_01" },
                { item = "netch_leather_cuirass" },
                { item = "wooden staff" },
                { item = "ab_app_grinder" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
            },
            spellList = {
                "fire shield",
                "fireball",
                "noise",
                "mother's kiss",
                "resist fire",
                "aa_cl_pyro_power",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 10 },
            }
        }
    end,

    ["queen"] = function()
--queens are at the top of the local nobility. only the emperor himself is above them, and it is him who they report to.
        return {
            gearList = {
                { item = "potion_t_bug_musk_01" },
                { item = "silver longsword" },
                { item = "war_barenziah_robe01" },
                { item = "silver_cuirass" },
                { item = "gold_001", count = goldamount },
                { item = "gold_001", count = goldamount },
                { item = "exquisite_shirt_01" },
                { item = "exquisite_shirt_01" },
                { item = "exquisite_shoes_01" },
            },
            spellList = {
                "aa_cl_king_power",
            },
        }
    end,

    ["t_glb_ratcatcher"] = function()
--Ratcatchers are skilled exterminators who prowl through sewers, cellars, and ships' holds to seek out and destroy infestations of vermin. Though they are despised by many, talented Ratcatchers are honored by the common folk whose homes, vessels, and health they protect.
-- spear, light, alch, sneak, block // short, secu, unarm, acrob, h2h
        return {
            gearList = {
                { item = "iron spear" },
                { item = "netch_leather_pauldron_right" },
                { item = "netch_leather_pauldron_left" },
                { item = "ab_app_grinder" },
                { item = "aa_thw_net", count = 3 },
                { item = "p_chameleon_s" },
                { item = "netch_leather_shield" },
                { item = "netch_leather_pauldron_left" },
                { item = "chitin shortsword" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "p_jump_s" },
                { item = "p_restore_fatigue_s" },
            },
            spellList = {
            },
            customSkillList = {
                { skillId = "climbing", value = 10 },
            }
        }
    end,


    ["ranger"] = function()
--rangers are skilled and knowledgeable fighters who have the skills necessary to be at home in the wilderness for long stretches at a time. rangers are expert trackers and can help guide others through difficult terrain.
        return {
            gearList = {
                { item = "ashfall_woodaxe" },
                { item = "ashfall_grill" },
                { item = "ashfall_waterskin" },
                { item = "ashfall_tent_base_m" },
                { item = "iron saber" },
                { item = "netch_leather_shield" },
                { item = "netch_leather_pauldron_right" },
                { item = "netch_leather_pauldron_left" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "ab_app_grinder" },
                { item = "p_chameleon_s" },
                { item = "p_jump_s" },
                { item = "p_restore_fatigue_s" },
            },
            spellList = {
                "aa_cl_ranger_spell",
                "chameleon",
                "aa_cl_ranger_power",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 10 },
                { skillId = "fletching", value = 10 },
                { skillId = "mc_Fletching", value = 10 },
                { skillId = "mc_Woodworking", value = 5 },
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["reaver"] = function()
--the reaver is a barbarian who surrendered to darker magicks in exchange for incredible power.
        return {
            gearList = {
                { item = "iron battle axe" },
                { item = "p_restore_fatigue_s" },
                { item = "0s_throwax_chit_01", count = 15 },
                { item = "ab_app_grinder" },
                { item = "hammer_repair" },
                { item = "aa_cl_silver_armor" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowamount },
            },
            spellList = {
                "absorb fatigue",
                "absorb health",
                "aa_cl_barbar_power",
                "aa_cl_reaver_power",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 5 },
                { skillId = "Ashfall:Survival", value = 5 },
            }
        }
    end,

    ["rogue"] = function()
--rogues are adventurers and opportunists with a gift for getting into and out of trouble. relying variously on charm and dash, blades and business sense, they thrive on conflict and misfortune, trusting to their luck and cunning to survive.
        return {
            gearList = {
                { item = "common_hood_01" },
                { item = "chitin shortsword" },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "chitin war axe" },
                { item = "left gauntlet of the horny fist" },
                { item = "right gauntlet of horny fist" },
                { item = "t_nor_wood_shield_01" },
                { item = "iron saber" },
                { item = "p_restore_fatigue_s" },
                { item = "aa_cl_speech_pot" },
                { item = "aa_scarf_grey" },
            },
            spellList = {
                "aa_cl_rogue_power",
            },
        }
    end,

    ["sage"] = function()
--sages are among the most intelligent people on tamriel, who even other mages go to for advice or instruction. sages are masters of alchemy, conjuration, enchanting, illusion, and speechcraft.
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "aa_nin3_shirt3" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "ab_app_grinder" },
                { item = "wooden staff" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "common_robe_05"},
                { item = "war_khajiit_wrstwrp01_r" },
                { item = "war_khajiit_wrstwrp01_l" },
            },
            spellList = {
                "light",
                "bound dagger",
                "spell absorption",
                "restore intelligence",
            },
            customSkillList = {
                { skillId = "MSS:Staff", value = 15 },
                { skillId = "daedricSkillId", value = 25 },
                { skillId = "common.inscriptionSkillId", value = 10 },
            }
        }
    end,

    ["ab_sailor"] = function()
--OAAB class, not playable by default
        return {
            gearList = {
                { item = "common_shirt_gondolier" },
                { item = "gondolier_helm" },
                { item = "p_restore_fatigue_s" },
                { item = "left gauntlet of the horny fist" },
                { item = "right gauntlet of horny fist" },
                { item = "iron saber" },
                { item = "p_jump_s" },
                { item = "chitin war axe" },
                { item = "ab_misc_pursecoin" },
                { item = "aa_cl_speech_pot" },
                { item = "chitin shortsword" },
            },
            spellList = {
                "aa_cl_sailor_spell",
            },
            customSkillList = {
                { skillId = "fishing", value = 10 },
                { skillId = "fishingSkillId", value = 10 },
                { skillId = "PoleFishing", value = 10 },
                { skillId = "mc_Crafting", value = 5 },
            }
        }
    end,

    ["t_glb_sailor"] = function()
--enlisted seafarers, sailors are skilled in operating and maintaining naval vessels, as well as navigation and the occasional joust. when wor on a military vessel, a group of sailors are often under the command of noble officers.
        return {
            gearList = {
                { item = "common_shirt_gondolier" },
                { item = "gondolier_helm" },
                { item = "p_restore_fatigue_s" },
                { item = "left gauntlet of the horny fist" },
                { item = "right gauntlet of horny fist" },
                { item = "iron saber" },
                { item = "p_jump_s" },
                { item = "chitin war axe" },
                { item = "ab_misc_pursecoin" },
                { item = "aa_cl_speech_pot" },
                { item = "chitin shortsword" },
            },
            spellList = {
                "aa_cl_sailor_spell",
            },
            customSkillList = {
                { skillId = "fishing", value = 10 },
                { skillId = "fishingSkillId", value = 10 },
                { skillId = "PoleFishing", value = 10 },
                { skillId = "mc_Crafting", value = 5 },
            }
        }
    end,

    ["sand-runner"] = function()
--sand-runners excel at running long distances even under the harsh conditions of the desert. they prefer to outrun their enemes, or take them out at a distance. while not spellcaster by profession, they have an affinity with fire and are adept at healing themselves.        return {
        return {
            gearList = {
                { item = "chitin shortsword" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "ab_a_leatherhatd" },
                { item = "netch_leather_boots" },
                { item = "flameguard robe" },
                { item = "p_restore_fatigue_s" },
                { item = "ab_misc_pursecoin" },
                { item = "flamebolt ring" },
            },
            spellList = {
                "resist fire",
                "mother's kiss",
                "fire barrier",
                "invisibility",
                "feather",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 10 },
                { skillId = "fletching", value = 5 },
                { skillId = "mc_Fletching", value = 5 },
                { skillId = "climbing", value = 5 },
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["savant"] = function()
--savants are people of wide learning and cosmopolitan tastes, well-traveled, educated, refined in manner, able to converse on various topics with authority, and ever ready to defend their honor, and the honor of their companions.
        return {
            gearList = {
                { item = "sc_paper plain", count= 3 },
                { item = "misc_inkwell" },
                { item = "misc_quill" },
                { item = "aa_cl_speech_pot" },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "ab_app_grinder" },
                { item = "watcher's belt" },
                { item = "probe_journeyman_01" },
                { item = "netch_leather_shield" },
                { item = "bk_great_houses", },
                { item = "bk_guide_to_vvardenfell" },
                { item = "t_bk_historyofdaggerfalltr" },
                { item = "sc_daydenespanacea", },
                { item = "sc_galmsesseal" },
                { item = "sc_firstbarrier" },
            },
            spellList = {
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 25},
                { skillId = "painting", value = 5 },
                { skillId = "common.inscriptionSkillId", value = 5 },
                { skillId = "mc_Crafting", value = 5 },
            }
        }
    end,

    ["scavenger"] = function()
--scavengers are people who find items that look like junk but turns out that they are valuable treasures. usually, they can even sell junk for a higher price, and their stealth and mobility makes them excellent for raiding caverns and bandit lairs.
        return {
            gearList = {
                { item = "aa_fact_bag01_light" },
                { item = "ingred_scrap_metal_01" },
                { item = "hammer_repair", count = 2 },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "chitin war axe" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_rea_wormmouth_bracerl_01" },
                { item = "iron boots" },
                { item = "netch_leather_pauldron_right" },
                { item = "netch_leather_pauldron_left" },
                { item = "p_chameleon_s" },
            },
            spellList = {
                "mark",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 5 },
                { skillId = "mc_Smithing", value = 5 },
                { skillId = "mc_Sewing", value = 5 },
                { skillId = "mc_Crafting", value = 10 },
                { skillId = "mc_Metalworking", value = 10 },
                { skillId = "mc_Masonry", value = 5 },
                { skillId = "mc_Mining", value = 5 },
                { skillId = "mc_Woodworking", value = 10 },
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["scout"] = function()
--scouts rely on stealth to survey routes and opponents, using ranged weapons and skirmish tactics when forced to fight. by contrast with barbarians, in combat scouts tend to be cautious and methodical, rather than impulsive.
        return {
            gearList = {
                { item = "ab_a_clothhelm1" },
                { item = "ashfall_waterskin" },
                { item = "ashfall_woodaxe" },
                { item = "ashfall_grill" },
                { item = "ashfall_kettle_06" },
                { item = "ashfall_waterskin" },
                { item = "p_chameleon_s" },
                { item = "iron saber" },
                { item = "t_nor_wood_shield_01" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_rea_wormmouth_bracerl_01" },
                { item = "ab_app_grinder" },
                { item = "war_mlsnd_boot_01" },
            },
            spellList = {
                "feather",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 10 },
                { skillId = "climbing", value = 5 },
                { skillId = "Bushcrafting", value = 10 },
            }
        }
    end,

    ["t_glb_scribe"] = function()
--scribes serve as public clerks for the masses, as well as professional copyists of hand-written texts in noble courts. in western provinces, scribes often oversee the operation and maintainance of printing presses.
        return {
            gearList = {
                { item = "sc_paper plain", count= 2 },
                { item = "misc_inkwell" },
                { item = "misc_quill" },
                { item = "aa_cl_speech_pot" },
                { item = "ab_app_grinder" },
                { item = "ab_misc_pursecoin" },
                { item = "probe_journeyman_01" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "chitin war axe" },
                { item = "chitin spear" },
                { item = "sc_tevilspeace" },
                { item = "sc_restoration" },
            },
            spellList = {
                "stamina",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 10 },
                { skillId = "painting", value = 5 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["seraph"] = function()
--seraphs belong to an holy order of knights in service to the aedra or good daedra. they are granted powers to purify the wicked.
        return {
            gearList = {
                { item = "mg_m (1)" },
                { item = "iron spear" },
                { item = "steel_gauntlet_right" },
                { item = "steel_pauldron_right" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "ab_app_grinder" },
                { item = "bk_formygodsandemperor" }
            },
            spellList = {
                "aa_cl_pally_power",
                "divine intervention",
                "aa_cl_seraph_spell",
                "aa_cl_seraph_power",
                "fire bite",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 15 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["shadow"] = function()
--shadows are mages who turn their magical abilities to thievery. the best way to protect your goods from a shadow is to have nothing valuable or interesting enough that they would bother to steal it.
        return {
            gearList = {
                { item = "p_chameleon_s" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "p_jump_s" },
                { item = "p_restore_fatigue_s" },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "common_robe_05"},
            },
            spellList = {
                "chameleon",
                "sanctuary",
                "feather",
                "telekinesis",
                "five fingers of pain",
                "fortify sneak skill",
            },
            customSkillList = {
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["shadowdancer"] = function()
--the shadowdancer is the bard most suited for solo adventures. he relies on potions and magic items for support. travelling often alone, he is a proficient armourer and dabbles in mysticism.
        return {
            gearList = {
                { item = "chitin shortsword" },
                { item = "netch_leather_pauldron_right" },
                { item = "netch_leather_pauldron_left" },
                { item = "p_jump_s" },
                { item = "p_restore_fatigue_s" },
                { item = "ab_app_grinder" },
                { item = "iron saber" },
                { item = "hammer_repair", count = 2 },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "aa_cl_speech_pot" },
                { item = "misc_de_lute_01", },
                { item = "aa_bk_songbook_shadow" },
            },
            spellList = {
                "absorb speed",
                "aa_cl_shadowd_power",
            },
            customSkillList = {
                { skillId = "BardicInspiration:Performance", value = 10 },
                { skillId = "climbing", value = 5 },
            }
        }
    end,

    ["shaman"] = function()
--shamans rely on their mystical powers drawn from their worship of nature and animal spirits. they are known to be able to summon living creatures to fight by their sides, and are proficient with various weapons.
        return {
            gearList = {
                { item = "t_nor_ringmail_cuirass_01" },
                { item = "t_com_wood_mace_01" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "common_robe_05_a"},
                { item = "aa_asent_boots"},
            },
            spellList = {
                "summon scamp",
                "absorb fatigue",
                "aa_cl_mage_abil",
                "calm creature",
                "five fingers of pain",
                "aa_cl_shaman_spell",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 10 },
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["sharpshooter"] = function()
--sharpshooter are expert marksmen, often making their living as mercenaries, working on short contracts as caravan guards or expedition escorts, or for long term contracts to nobles or .
        return {
            gearList = {
                { item = "mer_fletch_kit" },
                { item = "mc_Fletching_kit" },
                { item = "ab_w_woodcrossbow" },
                { item = "t_com_wood_bolt_01", count = arrowamount },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_rea_wormmouth_bracerl_01" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "p_chameleon_s" },
                { item = "p_restore_fatigue_s" },
            },
            spellList = {
                "aa_cl_sharp_spell",
            },
            customSkillList = {
                { skillId = "fletching", value = 15 },
                { skillId = "mc_Fletching", value = 15 },
            }
        }
    end,

    ["silver hand"] = function()
--the silver hands dedicate their lives to the eradication of werewolves. they fight armed with silver weapons and wear the fur of their kills.
        return {
            gearList = {
                { item = "silver war axe" },
                { item = "ab_c_commonhood01" },
                { item = "aa_cl_silver_armor" },
                { item = "ab_app_grinder" },
                { item = "bm wolf boots" },
                { item = "ab_w_woodcrossbow" },
                { item = "p_cure_common_s", count = 2 },
                { item = "silver bolt", count = 5 },
                { item = "hammer_repair", count = 2 },
            },
            spellList = {
                "shield",
            },
        }
    end,

    ["skald"] = function()
--the skald is a bard that goes to battle to support his companions. he is hardy and wears heavier armour than most bards. when forced into combat, he prefers the spear. like all bards, he is a fine speaker and relies on potions and to some extent, enchanted items.
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "t_nor_ringmail_cuirass_01" },
                { item = "ab_app_grinder" },
                { item = "fur_pauldron_left" },
                { item = "fur_pauldron_right" },
                { item = "chitin spear" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "ab_misc_pursecoin" },
                { item = "misc_de_lute_01", },
                { item = "aa_bk_songbook_skald" },
            },
            spellList = {
                "aa_cl_skald_spell",
                "heal companion",
            },
            customSkillList = {
                { skillId = "BardicInspiration:Performance", value = 10 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["slave"] = function()
--slaves serve their owner and master as commanded. they clean, prepare food, fetch and carry, do the shopping and marketing, and do other tasks too tiresome or menial for their master.
        return {
            gearList = {
                { item = "slave_bracer_left" },
                { item = "slave_bracer_right" },
            },
            spellList = {
                "aa_cl_slave_ability",
                "aa_cl_slave_power",
            },
            customSkillList = {
                { skillId = "mc_Sewing", value = 5 },
                { skillId = "mc_Crafting", value = 5 },
                { skillId = "mc_Mining", value = 10 },
                { skillId = "mc_Woodworking", value = 5 },
                { skillId = "mc_Cooking", value = 5 },
            }
        }
    end,

    ["smith"] = function()
--smiths make, sell, and repair weapons and armor. they can also teach how to take care of worn weapons and worn armor, and sell the necessary armorer tools. they also repair weapons and armor, for a fee.
        return {
            gearList = {
                { item = "hammer_repair", count = 5 },
                { item = "mc_Metalworking_kit" },
                { item = "mc_crucible" },
                { item = "ab_w_toolsmithhammer" },
                { item = "war_blacksmith_apron01" },
                { item = "iron_shield" },
                { item = "left gauntlet of the horny fist" },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_com_iron_warpick_01" },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
            },
            spellList = {
            },
            customSkillList = {
                { skillId = "mc_Smithing", value = 15 },
                { skillId = "mc_Crafting", value = 10 },
                { skillId = "mc_Metalworking", value = 15 },
                { skillId = "mc_Mining", value = 5 },
            }
        }
    end,

    ["aatl_cla_orsimer_tribesman"] = function()
--pika aatl
        return {
            gearList = {
                { item = "hammer_repair", count = 5 },
                { item = "mc_Metalworking_kit" },
                { item = "ab_w_toolsmithhammer" },
                { item = "war_blacksmith_apron01" },
                { item = "iron_shield" },
                { item = "left gauntlet of the horny fist" },
                { item = "iron_bracer_right" },
                { item = "t_com_iron_warpick_01" },
                { item = "aa_orcish_helm" },
            },
            spellList = {
            },
            customSkillList = {
                { skillId = "mc_Smithing", value = 15 },
                { skillId = "mc_Crafting", value = 10 },
                { skillId = "mc_Metalworking", value = 15 },
            }
        }
    end,

    ["smuggler"] = function()
--smugglers transport goods the empire has prohibited, such as skooma, moon sugar, ebony, dwemer artifacts, exotic dunmer weapons and armor, and slaves. smugglers also smuggle greef, shein, and sujamma to avoid imperial tax.
        return {
            gearList = {
                { item = "t_com_wood_mace_01" },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "p_chameleon_s" },
                { item = "aa_cl_speech_pot" },
                { item = "chitin shortsword" },
                { item = "p_restore_fatigue_s" },
                { item = "chitin war axe" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "chitin spear" },
                { item = "potion_comberry_brandy_01" },
                { item = "misc_dwrv_mug00" },
                { item = "misc_dwrv_goblet00" },
                { item = "ingred_moon_sugar_01" },
            },
            spellList = {
                "aa_cl_dock_power",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 5 },
            }
        }
    end,

    ["sorcerer"] = function()
--though spellcasters by vocation, sorcerers rely most on summonings and enchantments. they are greedy for magic scrolls, rings, armor, and weapons, and commanding undead and daedric servants gratifies their egos.
        return {
            gearList = {
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "misc_soulgem_lesser" },
                { item = "chitin shortsword" },
                { item = "viperstar", count = arrowamount },
                { item = "t_rea_wormmouth_bracerl_01" },
                { item = "t_com_iron_pauldronr_01" },
                { item = "common_robe_02_rr"},
            },
            spellList = {
                "summon scamp",
                "summon clanfear",
                "soul trap",
                "soulpinch",
                "fire shield",
                "command creature",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 10 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["spearman"] = function()
--spearmen form the front lines in a pitched battle, requiring strength and bravery. mysticism is a useful skill for those spearmen who can learn it as it allows them to protect themselves from ranged magical attacks. all spearmen also carry short blades for those who manage to get past their spears.
        return {
            gearList = {
                { item = "steel spear" },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_rea_wormmouth_bracerl_01" },
                { item = "p_restore_fatigue_s" },
                { item = "t_com_iron_pauldronr_01" },
                { item = "t_com_iron_pauldronl_01" },
                { item = "chitin shortsword" },
                { item = "hammer_repair", count = 2 },
                { item = "ab_app_grinder" },
            },
            spellList = {
                "aa_cl_spear_spell",
                "dispel",
            },
            customSkillList = {
                { skillId = "fishing", value = 5 },
                { skillId = "fishingSkillId", value = 5 },
                { skillId = "PoleFishing", value = 5 },
            }
        }
    end,

    ["spellsword"] = function()
--spellswords are spellcasting specialists trained to support imperial troops in skirmish and battle. veteran spellswords are prized as mercenaries, and well-suited for careers as adventurers and soldiers-of-fortune.
        return {
            gearList = {
                { item = "t_nor_wood_shield_01" },
                { item = "iron saber" },
                { item = "t_com_wood_mace_01" },
                { item = "t_nor_ringmail_cuirass_01" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "ab_app_grinder" },
            },
            spellList = {
                "mother's kiss",
                "five fingers of pain",
                "shield",

            },
        }
    end,

    ["stormcaller"] = function()
--stormcallers are the shamanistic spellbinders and spiritual guides. these hedge mages combine the ability to call upon lightning and ice, amongst other magicks, with a lifetime of training with the spear. stormcallers are trained to withstand both physical and mental hardships.
        return {
            gearList = {
                { item = "ingred_frost_salts_01" },
                { item = "chitin spear" },
                { item = "ab_c_commonhood01" },
                { item = "bm_nordic01_robe" },
                { item = "ab_app_grinder" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "aa_cl_speech_pot" },
                { item = "bm wolf boots" },
            },
            spellList = {
                "frost bolt",
                "shock",
                "frost barrier",
                "spell absorption",
                "aa_cl_storm_power",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 10 },
            }
        }
    end,

    ["summoner"] = function()
--summoners are people who influence the outer world by summoning creatures or objects of interest. they are talented spellcasters who understand most schools of magic but heavily favour conjuration.
        return {
            gearList = {
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "misc_soulgem_lesser" },
                { item = "chitin shortsword" },
                { item = "aa_cl_speech_pot" },
                { item = "netch_leather_cuirass" },
                { item = "common_robe_03"},
                { item = "ab_c_commonhood03"},
                { item = "ingred_rune_a_02" },
            },
            spellList = {
                "summon scamp",
                "summon clanfear",
                "dispel",
                "heal companion",
                "five fingers of pain",
                "levitate",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 10 },
            }
        }
    end,

    ["thaumaturge"] = function()
--thaumaturges concentrate on exposing or manipulating known forces and objects within their natural laws. thaumaturgical spells can temporarily change the appearance or structure of a force or object. examples include levitation, magic resistance, reflect, calm, invisibility, and water walking.
        return {
            gearList = {
                { item = "wooden staff" },
                { item = "chitin throwing star", count = arrowamount },
                { item = "p_chameleon_s" },
                { item = "ab_c_commonhood02tt"},
                { item = "common_robe_02_tt"},
            },
            spellList = {
                "levitate",
                "reflect",
                "invisibility",
                "aa_cl_arcan_power",
                "water walking",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 10 },
                { skillId = "common.inscriptionSkillId", value = 5 },
                { skillId = "mc_Metalworking", value = 5 },
                { skillId = "mc_Masonry", value = 5 },
            }
        }
    end,

    ["thief"] = function()
--thieves are pickpockets and pilferers. unlike robbers, who kill and loot, thieves typically choose stealth and subterfuge over violence, and often entertain romantic notions of their charm and cleverness in their acquisitive activities.
        return {
            gearList = {
                { item = "common_hood_01" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "p_chameleon_s" },
                { item = "p_jump_s" },
                { item = "chitin shortsword" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "p_restore_fatigue_s" },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "aa_cl_speech_pot" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
            },
            spellList = {
                "aa_cl_thief_power",
            },
            customSkillList = {
                { skillId = "climbing", value = 15 },
            }
        }
    end,

    ["trader"] = function()
--traders are travelling general merchants. they look for opportunities to make a profit on their travels, often with exotic goods or services.
        return {
            gearList = {
                { item = "gold_001", count = goldamount },
                { item = "gold_001", count = goldamount },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "aa_cl_speech_pot" },
                { item = "probe_journeyman_01" },
                { item = "watcher's belt" },
                { item = "netch_leather_shield" },
                { item = "t_com_wood_mace_01" },
                { item = "left gauntlet of the horny fist" },
                { item = "right gauntlet of horny fist" },
                { item = "war_mlsnd_boot_01" },
            },
            spellList = {
                "aa_cl_bank_power",
                "aa_cl_pawn_power",
                "aa_cl_dock_power",
                "recall",
            },
        }
    end,

    ["aatl_cla_caravan_trader"] = function()
--pika aatl
        return {
            gearList = {
                { item = "gold_001", count = goldamount },
                { item = "gold_001", count = goldamount },
                { item = "gold_001", count = 50 },
                { item = "ab_misc_pursecoin" },
                { item = "chitin war axe" },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "t_rea_wormmouth_bracerl_01" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowamount },
                { item = "aa_cl_speech_pot" },
                { item = "repair_prongs" },
                { item = "war_mlsnd_boot_01" },
            },
            spellList = {
                "aa_cl_bank_power",
                "aa_cl_pawn_power",
                "aa_cl_dock_power",
                "recall",
            },
        }
    end,

    ["vampire hunter"] = function()
--vampire hunters make a living by destroying vampires and cultists of molag bal. they might be tribunal temple fanatics, or they might serve either meridia, the daedric princess associated with the energies of living things, or hircine, the daedric prince of werevolves.
        return {
            gearList = {
                { item = "firebite sword" },
                { item = "ab_w_woodstake" },
                { item = "ab_w_woodcrossbow" },
                { item = "ab_a_netchboilpldleft" },
                { item = "ab_a_netchboilpldright" },
                { item = "p_chameleon_s" },
                { item = "t_com_wood_bolt_01", count = arrowamount },
                { item = "p_restore_fatigue_s" },
                { item = "netch_leather_shield" },
                { item = "tau_stake1" },
                { item = "p_cure_common_s", count = 4 },
            },
            spellList = {
                "aa_cl_vamp_power",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 10 },
            }
        }
    end,

    ["aatl_cla_vampire_hunter"] = function()
--pika aatl
        return {
            gearList = {
                { item = "ab_w_woodcrossbow" },
                { item = "t_com_wood_bolt_01", count = arrowamount },
                { item = "iron flameskewer" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "misc_soulgem_lesser" },
                { item = "t_rea_wormmouth_greaves_01" },
                { item = "ab_w_woodstake" },
                { item = "tau_stake1" },
                { item = "p_cure_common_s", count = 4 },
                { item = "t_com_iron_helm_01" },
            },
            spellList = {
                "aa_cl_vamp_power",
                "shield",
                "fire bite",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 10 },
            }
        }
    end,

    ["vestal"] = function()
        return {
            gearList = {
                { item = "ab_alc_healbandage01", count = 2 },
                { item = "aa_cl_speech_pot" },
                { item = "common_robe_01"},
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "hammer_repair" },
                { item = "mg_p (3)" },
            },
            spellList = {
                "mother's kiss",
                "cure poison",
                "cure common disease",
                "reflect",
                "invisibility",
                "shield",
                "heal companion",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 10 },
            }
        }
    end,

    ["veteran"] = function()
--veterans are soldiers who have seen enough fighting not to desire more. they would rather sit by a campfire exchanging war stories than create new ones. however, it would still be unwise to pick a fight with someone who has survived as much combat as they have.
        return {
            gearList = {
                { item = "iron saber" },
                { item = "chitin spear" },
                { item = "t_nor_wood_shield_01" },
                { item = "aa_cl_speech_pot" },
                { item = "ab_w_woodcrossbow" },
                { item = "t_com_wood_bolt_01", count = arrowamount },
                { item = "lbonemold brace of horny fist" },
                { item = "rbonemold bracer of horny fist" },
                { item = "ab_app_grinder" },
                { item = "iron_greaves" },
                { item = "iron boots" },
                { item = "t_com_iron_cuirass_01" },
            },
            spellList = {
                "aa_cl_veteran_spell",
            },
            customSkillList = {
                { skillId = "mc_Smithing", value = 5 },
            }
        }
    end,

    ["warlock"] = function()
--warlocks are male mages who bind themselves by oath and deed to the service of a daedra lord, and in return receive gifts of knowledge and power. in morrowind, warlocks often serve the house of troubles.

        return {
            gearList = {
                { item = "ingred_rune_a_03" },
                { item = "ingred_rune_a_06" },
                { item = "chitin shortsword" },
                { item = "p_restore_fatigue_s" },
                { item = "aa_cl_speech_pot" },
                { item = "ab_c_commonhood03" },
                { item = "common_robe_03"},
            },
            spellList = {
                "silence",
                "fire shield",
                "mother's kiss",
                "fire bite",
                "shock",
                "frost bolt",
                "poison",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 10 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["warlord"] = function()
--warlords are powerful fighters who command their own hordes. they make use of speechcraft and magic to rally and buff their troops in battle.
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "iron_greaves" },
                { item = "iron boots" },
                { item = "steel_cuirass" },
                { item = "aa_cl_speech_pot" },
                { item = "iron saber" },
                { item = "t_com_wood_mace_01" },
                { item = "iron_shield" },
                { item = "ab_w_woodcrossbow" },
                { item = "t_com_wood_bolt_01", count = arrowamount },
            },
            spellList = {
                "aa_cl_skald_spell",
                "rally humanoid",
            },
        }
    end,

    ["warrior"] = function()
--warriors are the professional men-at-arms, soldiers, mercenaries, and adventurers of the empire, trained with various weapon and armor styles, conditioned by long marches, and hardened by ambush, skirmish, and battle.
        return {
            gearList = {
                { item = "iron saber" },
                { item = "t_rea_wormmouth_pauldronl_01" },
                { item = "t_rea_wormmouth_pauldronr_01" },
                { item = "iron boots" },
                { item = "t_com_iron_cuirass_01" },
                { item = "p_restore_fatigue_s" },
                { item = "t_nor_wood_shield_01" },
                { item = "hammer_repair", count = 2 },
                { item = "t_com_wood_mace_01" },
                { item = "chitin war axe" },
                { item = "ab_w_woodcrossbow" },
                { item = "t_com_wood_bolt_01", count = arrowamount },
                { item = "chitin spear" },
            },
            spellList = {
                "aa_cl_barbar_power",
            },
        }
    end,

    ["wise woman"] = function()
--the wise women of the ashlanders are councilors to their tribe, guardian of secret knowledge, spirit guide and seer into the world unseen. if accepted by the tribe, they can teach outlanders about the ancestors, and about ashlander customs.
        return {
            gearList = {
                { item = "left gauntlet of the horny fist" },
                { item = "right gauntlet of horny fist" },
                { item = "aa_cl_speech_pot" },
                { item = "wooden staff" },
                { item = "netch_leather_pauldron_right" },
                { item = "netch_leather_pauldron_left" },
                { item = "ab_app_grinder" },
                { item = "war_mlsnd_boot_01" },
                { item = "expensive_robe_01"},
                { item = "ashfall_woodaxe" },
            },
            spellList = {
                "poet's whim",
                "cure common disease",
                "dispel",
                "water walking",
                "sanctuary",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 10 },
                { skillId = "common.inscriptionSkillId", value = 10 },
                { skillId = "mc_Crafting", value = 5 },
                { skillId = "mc_Cooking", value = 5 },
            }
        }
    end,

    ["witch"] = function()
--witches are female mages who bind themselves by oath and deed to the service of a daedra lord, and in return receive gifts of knowledge and power. in morrowind, witches often serve the house of troubles.
        return {
            gearList = {
                { item = "mc_toxinflask" },
                { item = "ingred_rune_a_04" },
                { item = "chitin shortsword" },
                { item = "ab_c_commonhood05c" },
                { item = "aa_cl_speech_pot" },
                { item = "p_chameleon_s" },
                { item = "ab_app_grinder" },
                { item = "common_robe_05_c"},
            },
            spellList = {
                "absorb fatigue",
                "summon scamp",
                "summon clanfear",
                "burden",
                "erelvam's wild sty",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 15 },
                { skillId = "common.inscriptionSkillId", value = 5 },
                { skillId = "mc_Cooking", value = 5 },
            }
        }
    end,

    ["witchhunter"] = function()
--witchhunters are dedicated to rooting out and destroying the perverted practices of dark cults and profane sorcery. they train for martial, magical, and stealthy war against vampires, witches, warlocks, and necromancers.
        return {
            gearList = {
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "ab_app_grinder" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "netch_leather_helm" },
                { item = "ab_w_woodcrossbow" },
                { item = "t_com_wood_bolt_01", count = arrowamount },
                { item = "watcher's belt" },
                { item = "p_chameleon_s" },
                { item = "t_com_wood_mace_01" },
                { item = "netch_leather_shield" },
            },
            spellList = {
                "turn undead",
                "dispel",
                "aa_cl_whunter_power",
            },
        }
    end,

    ["vagaband"] = function()
-- the vagabond survives in cities and wilderness by stealth, versatility, and wits.
        return {
            gearList = {
                { item = "ashfall_fab_cloak" },
                { item = "ab_w_bottlebroken" },
                { item = "ab_c_commonhood01" },
                { item = "ashfall_waterskin" },
                { item = "ashfall_knife_flint" },
                { item = "ashfall_woodaxe_flint" },
                { item = "aa_cl_vagabon_boots" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "ab_alc_healbandage01" },
                { item = "aa_cl_restorative_brew", count = 2 },
            },
            spellList = {
                "light",
                "mother's kiss",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 5 },
                { skillId = "Bushcrafting", value = 5 },
            }
        }
    end,

    ["aatl_cla_grunt"] = function()
-- pika aatl
        return {
            gearList = {
                { item = "p_chameleon_s" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "firebite dagger" },
                { item = "netch_leather_pauldron_right" },
                { item = "netch_leather_pauldron_left" },
                { item = "chitin throwing star", count = arrowamount },
                { item = "ab_app_grinder" },
            },
            spellList = {
                "burden",
                "invisibility",
            },
        }
    end,

    ["aatl_cla_redguard_mercenary"] = function()
-- pika aatl
        return {
            gearList = {
                { item = "t_rga_alik_broadsword_01" },
                { item = "t_rga_lamellar_cuirass" },
                { item = "t_rga_lamellar_helm" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "ab_misc_pursecoin" },
                { item = "t_rga_verk_cutlass_01" },
                { item = "ab_app_grinder" },
            },
            spellList = {
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 10 },
                { skillId = "climbing", value = 5 },
            }
        }
    end,

    ["aatl_cla_shadowscale"] = function()
--pika aatl
        return {
            gearList = {
                { item = "cruel viperblade" },
                { item = "p_chameleon_s" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "ab_app_grinder" },
                { item = "aa_hist_cuirass_01" },
                { item = "p_jump_q" },
                { item = "p_restore_fatigue_q" },
                { item = "t_com_iron_throwingknife_01", count = arrowamount },
            },
            spellList = {
                "chameleon",
                "poison",
            },
            customSkillList = {
                { skillId = "climbing", value = 10 },
            }
        }
    end,

    ["aatl_cla_vampire_matriarch"] = function()
--pika aatl
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "aa_cl_ench_ring" },
                { item = "misc_soulgem_petty" },
                { item = "ab_app_grinder" },
                { item = "aa_cl_speech_pot" },
                { item = "p_chameleon_s" },
                { item = "p_restore_fatigue_q" },
            },
            spellList = {
                "aa_vamp_memsmer",
                "summon ancestral ghost",
                "aa_vamp_drain",
                "burden",
                "vampire blood aundae",

            },
            customSkillList = {
                { skillId = "climbing", value = 10 },
            }
        }
    end,

    ["aatl_cla_vampire_patriarch"] = function()
--pika aatl
        return {
            gearList = {
                { item = "chitin club" },
                { item = "chitin spear" },
                { item = "chitin war axe" },
                { item = "t_rea_wormmouth_bracerr_01" },
                { item = "left gauntlet of the horny fist" },
                { item = "p_restore_fatigue_q" },
            },
            spellList = {
                "shock",
                "summon ancestral ghost",
                "absorb health [ranged]",
                "vampire blood quarra",
            },
            customSkillList = {
                { skillId = "climbing", value = 10 },
            }
        }
    end,

    ["aatl_cla_vampire_nightstalker"] = function()
-- pika aatl
        return {
            gearList = {
                { item = "aa_cl_h2h_glove_left" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "p_chameleon_s" },
                { item = "watcher's belt" },
                { item = "p_jump_q" },
                { item = "p_restore_fatigue_q" },
                { item = "chitin club" },
                { item = "t_de_chitin_longsword_01 club" },
                { item = "chitin throwing star", count = arrowamount },
            },
            spellList = {
                "feather",
                "aa_vamp_memsmer",
                "vampire blood berne",
            },
            customSkillList = {
                { skillId = "climbing", value = 10 },
            }
        }
    end,

    ["aa_arc_knight"] = function()
-- the arcane knight has long studied arcana while following the more conventional training of a knight in melee combat and etiquette.
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "hammer_repair", count = 2 },
                { item = "iron_shield" },
                { item = "ab_w_ironrapierfla" },
                { item = "iron_cuirass" },
            },
            spellList = {
                "aa_cl_crusad_spell",
                "shield",
                "soul trap",
                "aa_cl_arc_knight",
            },
            customSkillList = {
                { skillId = "mc_Smithing", value = 5 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["aa_cl_plague"] = function()
-- the plagueherald has an incredible physique that lets them resist diseases and an intellect to understand and manipulate them. once an enemy is weakened and plague-ridden, the plagueherald will finish them off with their axe.
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "aa_cl_poison_potent" },
                { item = "aa_cl_posin_cheap" },
                { item = "aa_cl_bk_diseasecommon"},
                { item = "t_nor_wood_shield_01" },
                { item = "t_rea_wormmouth_pauldronr_01" },
                { item = "t_rea_wormmouth_pauldronl_01" },
                { item = "liche_robe1_c" },
            },
            spellList = {
                "aa_cl_plague01",
                "aa_cl_plague03",
                "aa_cl_plague04",
            },
            customSkillList = {
                { skillId = "NC:CorpsePreparation", value = 10 },
            }
        }
    end,

    ["t_glb_barrister"] = function()
-- barristers are experts in debate and argument well-versed in the intricacies of imperial law.
        return {
            gearList = {
                { item = "potion_t_bug_musk_01" },
                { item = "gold_001", count = 70 },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "extravagant_pants_01" },
                { item = "extravagant_shirt_01" },
                { item = "extravagant_shoes_01" },
                { item = "aa_cl_speech_pot" },
            },
            spellList = {
                "aa_cl_bank_power",
                "aa_cl_diplo_power",
                "aa_diplo_spell",
            },
            customSkillList = {
                { skillId = "common.inscriptionSkillId", value = 20 },
            }
        }
    end,

    ["t_glb_cook"] = function()
-- cooks can be found everywhere from the most exclusive court kitchens to the meanest ships' galleys. they are skilled with the chef's knife and the tenderizing hammer, quick under pressure, and often adept at mundane alchemy.
        return {
            gearList = {
                { item = "t_com_frypan_01" },
                { item = "t_com_ironpot_01" },
                { item = "misc_rollingpin_01" },
                { item = "nom_food_guar_rib_succ" },
                { item = "nom_food_fruit_salad" },
                { item = "nom_food_omelette_crab" },
                { item = "t_ingfood_cheesecolovian_01" },
                { item = "t_ingfood_breadcolovian_02" },
                { item = "mc_cutting_board" },
                { item = "mc_wheatflour" },
                { item = "mc_kanet_butter" },
                { item = "mc_hackle-lo_powder" },
                { item = "apparatus_a_mortar_01" },
                { item = "t_com_var_knife_01" },
                { item = "aa_cl_speech_pot" },
                { item = "mc_cutting_board" },
                { item = "mc_wheatflour" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "t_com_wood_mace_01" },
            },
            spellList = {
                "mother's kiss",
            },
            customSkillList = {
                { skillId = "mc_Cooking", value = 20 },
            }
        }
    end,

    ["aa_cl_succubus"] = function()
--the succubus is a female of great beauty and powerful magics. she seduces, charm or drugs her victims. the luckiest are charmed for intimate reasons, most die in combat, defending the succubus before reaping their carnal reward.
        return {
            gearList = {
                { item = "2pl_obdress_1" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "aa_cl_speech_pot" },
                { item = "apparatus_a_mortar_01" },
                { item = "ab_c_commonhood05c" },
                { item = "aa_cl_jink_tanto" },
                { item = "common_robe_05_c"},
            },
            spellList = {
                "absorb fatigue",
                "absorb health",
                "command humanoid",
                "charming touch",
                "aa_cl_succubus_power",
                "sanctuary",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 15 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["aa_cl_incubus"] = function()
--the incubus is a male of great beauty and powerful magics. he seduces, charm or drugs her victims. the luckiest are charmed for intimate reasons, most die in combat, defending the incubus before reaping their carnal rewards.
        return {
            gearList = {
                { item = "2pl_obdress_1" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "aa_cl_speech_pot" },
                { item = "apparatus_a_mortar_01" },
                { item = "ab_c_commonhood05c" },
                { item = "aa_cl_jink_tanto" },
                { item = "common_robe_05_c"},
            },
            spellList = {
                "absorb fatigue",
                "absorb health",
                "command humanoid",
                "charming touch",
                "aa_cl_succubus_power",
                "sanctuary",
            },
            customSkillList = {
                { skillId = "daedricSkillId", value = 15 },
                { skillId = "common.inscriptionSkillId", value = 5 },
            }
        }
    end,

    ["aa_cl_artist"] = function()
--artists seek out beautiful sights to capture on canvas, honing their athletics and alteration in search of new vistas. through the mixing of paints and dyes, they often acquire alchemical knowledge. mostly untrained in the art of combat, they learn to protect themselves with illusion and stealth - they can move quietly, or indeed stand unnoticed for hours. although some artists live purely on inspiration (or inherited wealth), most find they need a silver tongue to find patronage among their noble customers, and strong mercantile skills to convince them to pay up.
-- illusion, alchemy, alteration, mercantile, sneak // speechcraft, athletics, blunt weapon, unarmored, light armor
        return {
            gearList = {
                { item = "aa_cl_vagabon_boots" },
                { item = "apparatus_a_mortar_01" },
                { item = "ingred_gold_kanet_01" },
                { item = "ingred_heather_01" },
                { item = "ingred_stoneflower_petals_01" },
                { item = "ab_c_commonhood01" },
                { item = "wooden staff" },
                { item = "common_robe_01"},
                { item = "ashfall_waterskin" },
                { item = "aa_cl_speech_pot" },
                { item = "t_com_paintbrush_01" },
                { item = "jop_brush_01" },
                { item = "jop_easel_misc" },
                { item = "jop_water_palette_01" },
                { item = "jop_parchment_01", count = 5 },
                { item = "jop_coal_sticks_01", count = 2 },
            },
            spellList = {
                "calm creature",
                "chameleon",
                "paralysis",
                "shield",
            },
            customSkillList = {
                { skillId = "Ashfall:Survival", value = 5 },
                { skillId = "Bushcrafting", value = 5 },
                { skillId = "painting", value = 15 },
            }
        }
    end,

    ["courier"] = function()
-- Couriers are swift-footed messengers, trained in the art of travel and survival.
-- Major Skills: Athletics, Acrobatics, Light Armor, Speechcraft, Short Blade
-- Minor Skills: Sneak, Security, Mercantile, Alteration, Illusion
        return {
            gearList = {
                { item = "p_jump_q" },
                { item = "p_restore_fatigue_s" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "steel dagger" },
                { item = "aa_cl_message_list" },
                { item = "p_fortify_speed_e" },
            },
            spellList = {
                "invisibility",
                "chameleon",
                "feather",
                "jump",

            },
            customSkillList = {
                { skillId = "climbing", value = 10 },
                { skillId = "ashfall:survival", value = 10 },
            }
        }
    end,

    ["daedrologist"] = function()
-- The Daedrologist is an intrepid scholar and negotiator, venturing into perilous domains to uncover the mysteries of Oblivion and its denizens. Their expertise lies in manipulating magic and diplomacy to navigate the dangerous world of Daedra and their followers. 
        return {
            gearList = {
                { item = "aa_cl_demon_tanto_old" },
                { item = "random_de_robe" },
                { item = "Misc_SoulGem_Petty", count= 2},
            },
            spellList = {
                "bound dagger",
                "summon scamp",
                "invisibility",
                "shield",
                "soul trap",
                "frenzy creature",
                "calm creature",
                "aa_cl_antipal_spell",
            },
            customSkillList = {
                { skillId = "NC:CorpsePreparation", value = 5 },
                { skillId = "daedricskillId", value = 20 },
                { skillId = "common.inscriptionskillId", value = 15 },

            }
        }
    end,

    ["Fryse Hag"] = function()
        return {
            gearList = {
                { item = "aa_cl_Winterwound_Dagger" },
                { item = "frostmirror robe" },
                { item = "apparatus_a_mortar_01" },
                { item = "aa_cl_Winterwound_Dagger" },
                { item = "aa_cl_speech_pot" },
                { item = "watcher's belt" },
            },
            spellList = {
                "summon frost atronach",
                "frost bolt",
            },
            customSkillList = {
                { skillId = "MSS:Staff", value = 10 },
            }
        }
    end,

    ["aa_cl_relikSeeker"] = function()
        return {
            gearList = {
                { item = "p_chameleon_s" },
                { item = "pick_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "AB_w_SilverRapier" },
                { item = "watcher's belt" },
                { item = "aa_fedora_armour" },
                { item = "aa_Whip_Leather" },
            },
            spellList = {
                "night-eye",
                "restore strength",
                "telekinesis",
                "aa_cl_pally_power",
  },
            customSkillList = {
            }
        }
    end,
---------------------------------------------------------------
    ["xxx"] = function()
        return {
            gearList = {
                { item = "p_chameleon_s" },
                { item = "pick_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "AB_w_SilverRapier" },
                { item = "watcher's belt" },
                { item = "aa_fedora_armour" },
                { item = "aa_Whip_Leather" },
            },
            spellList = {
                "night-eye",
                "restore strength",
                "telekinesis",
                "aa_cl_pally_power",
  },
            customSkillList = {
                { skillId = "climbing", value = 5 },
            }
        }
    end,
}
return this

-- possible skills
--                { skillId = "climbing", value = 10 },
--                { skillId = "MSS:Staff", value = 5 },
--                { skillId = "daedricSkillId", value = 10 },
--                { skillId = "NC:CorpsePreparation", value = 5 },

--                { skillId = "mc_Cooking", value = 5 },
--                { skillId = "mc_Crafting", value = 5 }
--                { skillId = "mc_Smithing", value = 5 },
--                { skillId = "mc_Metalworking", value = 5 },
--                { skillId = "mc_Masonry", value = 5 },
--                { skillId = "mc_Mining", value = 5 },
--                { skillId = "mc_Sewing", value = 5 },
--                { skillId = "mc_Woodworking", value = 5 },
--                { skillId = "mc_Fletching", value = 15 },

--                { skillId = "fletching", value = 15 },
--                { skillId = "painting", value = 5 },
--                { skillId = "BardicInspiration:Performance", value = 10 },
--                { skillId = "Ashfall:Survival", value = 10 },
--                { skillId = "common.inscriptionSkillId", value = 5 },
--                { skillId = "Bushcrafting", value = 5 },
--                { skillId = "fishing", value = 5 },

--                { skillId = "fishingSkillId", value = 5 },
--                { skillId = "PoleFishing", value = 5 },


