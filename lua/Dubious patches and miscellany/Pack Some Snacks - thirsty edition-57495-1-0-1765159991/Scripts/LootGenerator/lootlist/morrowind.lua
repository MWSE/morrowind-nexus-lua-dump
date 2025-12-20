return {
    food = {
        "ingred_ash_yam_01",
        "ingred_bread_01",
        "ingred_crab_meat_01",
        "ingred_hound_meat_01",
        "food_kwama_egg_01",
        "food_kwama_egg_02",
        "ingred_rat_meat_01",
        "ingred_saltrice_01",
        "ingred_scrib_jelly_01",
        "ingred_scrib_jerky_01",
        "ingred_scuttle_01",
    },

    drink = {
        "Potion_Local_Brew_01",
    },

    misc = {
        -- Plain string entries mean common misc, no tag filtering
         "misc_com_bottle_10",
         "misc_com_bottle_09",

		 
        -- Tagged entries format: { id = "item_id", tags = { "tag1", "tag2" } }
		-- e.g. { id = "Gold_100", tags = { "wealthy", "rogue" } }
		-- Available tags: warrior, mage, rogue, alchemist, scholar, wealthy, commoner, laborer
		
		-- laborer

		
		-- Commoner
		{ id = "misc_com_bottle_01", tags = { "commoner" } },
		{ id = "Misc_Com_Bottle_14", tags = { "commoner" } },
		{ id = "misc_com_bottle_09", tags = { "commoner" } },
		{ id = "Misc_Com_Redware_Cup", tags = { "commoner" } },
		{ id = "misc_com_wood_cup_01", tags = { "commoner" } },
		{ id = "misc_com_wood_cup_02", tags = { "commoner" } },
		{ id = "misc_com_redware_flask", tags = { "commoner" } },
		{ id = "misc_flask_01", tags = { "commoner" } },
		{ id = "misc_flask_02", tags = { "commoner" } },
		{ id = "misc_com_wood_knife", tags = { "commoner" } },
		{ id = "misc_lw_cup", tags = { "commoner" } },
		{ id = "repair_prongs", tags = { "commoner" } },		

		-- Scholar
		{ id = "Misc_Inkwell", tags = { "scholar" } },
		{ id = "Misc_Quill", tags = { "scholar" } },
		{ id = "sc_paper plain", tags = { "scholar" } },
		{ id = "text_paper_roll_01", tags = { "scholar" } },
		{ id = "bk_AedraAndDaedra", tags = { "scholar" } },
		{ id = "bk_AffairsOfWizards", tags = { "scholar" } },
		{ id = "bk_BookDawnAndDusk", tags = { "scholar" } },
		{ id = "bk_CantatasOfVivec", tags = { "scholar" } },
		{ id = "bk_firmament", tags = { "scholar" } },
		{ id = "bk_HomiliesOfBlessedAlmalexia", tags = { "scholar" } },
		{ id = "bk_LivesOfTheSaints", tags = { "scholar" } },
		{ id = "bk_onoblivion", tags = { "scholar" } },
		{ id = "bk_OnMorrowind", tags = { "scholar" } },
		{ id = "bk_PilgrimsPath", tags = { "scholar" } },
		{ id = "bk_redbookofriddles", tags = { "scholar" } },
		{ id = "bk_vivecandmephala", tags = { "scholar" } },
		{ id = "bk_yellowbookofriddles", tags = { "scholar" } },

		-- Alchemist
		{ id = "ingred_gold_kanet_01", tags = { "alchemist" } },
		{ id = "ingred_heather_01", tags = { "alchemist" } },
		{ id = "ingred_kresh_fiber_01", tags = { "alchemist" } },
		{ id = "ingred_bc_spore_pod", tags = { "alchemist" } },
		{ id = "ingred_stoneflower_petals_01", tags = { "alchemist" } },
		{ id = "ingred_coprinus_01", tags = { "alchemist" } },
		{ id = "ingred_corkbulb_root_01", tags = { "alchemist" } },
		{ id = "ingred_chokeweed_01", tags = { "alchemist" } },
		{ id = "ingred_bc_ampoule_pod", tags = { "alchemist" } },
		{ id = "p_cure_poison_s", tags = { "alchemist" } },

		-- Wealthy
		{ id = "misc_de_goblet_06", tags = { "wealthy" } },
		{ id = "misc_de_goblet_07", tags = { "wealthy" } },
		{ id = "misc_de_goblet_09", tags = { "wealthy" } },
		{ id = "Gold_100", tags = { "wealthy" } },

		-- Warrior
		{ id = "hammer_repair", tags = { "warrior" } },
		{ id = "repair_prongs", tags = { "warrior" } },
		{ id = "p_fortify_strength_c", tags = { "warrior" } },
		{ id = "p_fortify_fatigue_c", tags = { "warrior" } },
		{ id = "p_restore_health_c", tags = { "warrior" } },		

		-- Rogue
		{ id = "pick_apprentice_01", tags = { "rogue" } },
		{ id = "pick_journeyman_01", tags = { "rogue" } },
		{ id = "probe_apprentice_01", tags = { "rogue" } },
		{ id = "probe_journeyman_01", tags = { "rogue" } },
		{ id = "p_detect_key_s", tags = { "rogue" } },
		{ id = "p_telekinesis_s", tags = { "rogue" } },
		{ id = "p_magicka_resistance_s", tags = { "rogue" } },
		{ id = "p_invisibility_b", tags = { "rogue" } },
		{ id = "misc_de_cloth10", tags = { "rogue" } },
		{ id = "misc_de_cloth11", tags = { "rogue" } },
		{ id = "misc_de_foldedcloth00", tags = { "rogue" } },
		{ id = "Gold_25", tags = { "rogue" } },
		{ id = "iron dagger", tags = { "rogue" } },

		-- Mage
		{ id = "p_restore_magicka_c", tags = { "mage" } },
		{ id = "Misc_SoulGem_Lesser", tags = { "mage" } },
		{ id = "Misc_SoulGem_Petty", tags = { "mage" } },
		{ id = "sc_daydenespanacea", tags = { "mage" } },
		{ id = "sc_blackdespair", tags = { "mage" } },
		{ id = "sc_blackdeath", tags = { "mage" } },
		{ id = "sc_radrenesspellbreaker", tags = { "mage" } },
		{ id = "sc_ulmjuicedasfeather", tags = { "mage" } },
		{ id = "sc_princeovsbrightball", tags = { "mage" } },
		{ id = "sc_secondbarrier", tags = { "mage" } },
		{ id = "sc_inasismysticfinger", tags = { "mage" } },
    }
}
















