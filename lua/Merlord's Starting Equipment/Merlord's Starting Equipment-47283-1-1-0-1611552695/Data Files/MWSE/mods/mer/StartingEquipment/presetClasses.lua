local this = {}
local goldAmount = 20
local arrowAmount = 20
local throwingStarAmount = 30
--[[
    Functions for each class return
    gear list of item objects
]]
this.pickGear = {
    ["Acrobat"] = function()
        local gearList = {
            { item = "p_jump_q", count= 2},
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "steel throwing star", count = throwingStarAmount },
            { item = "p_chameleon_s", count = 2},
            { item = "sc_secondbarrier" },
            { item = "chitin spear" },
            { item = "common_glove_right_01" },
            { item = "common_glove_left_01" },
            { item = "left leather bracer" },
            { item = "right leather bracer" },
        }
        return gearList
    end,
    ["Agent"] = function()
        local gearList = {
            { item = "potion_t_bug_musk_01" },
            { item = "p_chameleon_s", count= 2},
            { item = "p_jump_q", count= 2},
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "iron dagger" },
            { item = "Gold_001", count = goldAmount },
            { item = "nordic_leather_shield" },
        }
        return gearList
    end,
    ["Alchemist"] = function()
        local gearList = {
            { item = "apparatus_a_mortar_01" },
            { item = "apparatus_a_calcinator_01" },
            { item = "Gold_001", count = goldAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "sc_fphyggisgemfeeder" },
            { item = "Misc_SoulGem_Petty", count= 2},
            { item = "p_frost_shield_s" },
            { item = "p_fire_shield_s" },
            { item = "wooden staff" },
            { item = "ingred_chokeweed_01" },
            { item = "ingred_crab_meat_01" },
            { item = "nordic_leather_shield" },
            { item = "p_fortify_personality_s" },

        }
        return gearList
    end,
    ["Apothecary"] = function()
        local gearList = {
            { item = "apparatus_a_mortar_01" },
            { item = "apparatus_a_calcinator_01" },
            { item = "probe_journeyman_01" },
            { item = "pick_journeyman_01", },
            { item = "ingred_chokeweed_01" },
            { item = "ingred_crab_meat_01" },
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "steel staff" },
            { item = "left leather bracer" },
            { item = "right leather bracer" },
            { item = "p_fortify_personality_s" },
            { item = "nordic_leather_shield" },
        }
        return gearList
    end,
    ["Archer"] = function()
        local gearList = {
            { item = "long bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "sc_firstbarrier" },
            { item = "chitin spear" },
            { item = "p_chameleon_s" },
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
        }
        return gearList
    end,
    ["Artificer"] = function()
        local gearList = {
            { item = "hammer_repair", count= 2},
            { item = "sc_fphyggisgemfeeder" },
            { item = "Misc_SoulGem_Petty", count= 2},
            { item = "apparatus_a_mortar_01" },
            { item = "apparatus_a_calcinator_01" },
            { item = "sc_didalasknack" },
            { item = "iron club" },
            { item = "iron_pauldron_right" },
            { item = "iron_pauldron_left" },
            { item = "probe_apprentice_01", count= 2},
            { item = "pick_apprentice_01", count= 2},
            { item = "steel crossbow" },
            { item = "iron bolt", count = arrowAmount },
            { item = "nordic_leather_shield" },
        }
        return gearList
    end,
    ["Assassin"] = function()
        local gearList = {
            { item = "p_chameleon_s", count= 2},
            { item = "short bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "cruel viperblade" },
            { item = "p_jump_q", count= 2},
            { item = "probe_apprentice_01", },
            { item = "pick_apprentice_01", },
            { item = "apparatus_a_mortar_01" },
            { item = "nordic_leather_shield" },
            { item = "p_fortify_fatigue_s", count= 2},
        }
        return gearList
    end,
    ["Barbarian"] = function()
        local gearList = {
            { item = "iron war axe" },
            { item = "imperial_chain_cuirass" },
            { item = "iron club" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "netch_leather_shield" },
            { item = "p_jump_s", count= 2},
            { item = "fur_pauldron_left" },
            { item = "fur_pauldron_right" },
            { item = "repair_prongs", count= 2},
            { item = "iron throwing knife", count = throwingStarAmount },
        }
        return gearList
    end,
    ["Bard"] = function()
        local gearList = {
            { item = "potion_t_bug_musk_01" },
            { item = "apparatus_a_mortar_01" },
            { item = "apparatus_a_calcinator_01" },
            { item = "p_jump_q", count= 2},
            { item = "iron broadsword" },
            { item = "netch_leather_shield" },
            { item = "Gold_001", count = goldAmount },
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
            { item = "probe_apprentice_01", count= 2},
            { item = "pick_apprentice_01", count= 2},
            { item = "misc_de_lute_01", count = 1 }
        }
        return gearList
    end,
    ["Battlemage"] = function()
        local gearList = {
            { item = "Gold_001", count = goldAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "iron war axe" },
            { item = "iron boots" },
            { item = "iron_cuirass" },
            { item = "iron saber" },
            { item = "chitin short bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "Misc_SoulGem_Petty", count= 2},
            { item = "apparatus_a_mortar_01" },
        }
        return gearList
    end,
    ["Bookseller"] = function()
        local gearList = {
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "probe_journeyman_01", count= 2},
            { item = "pick_journeyman_01", count= 2},
            { item = "potion_t_bug_musk_01" },
            { item = "sc_firstbarrier" },
            { item = "bk_specialfloraoftamriel" },
            { item = "bk_ShortHistoryMorrowind" },
            { item = "left leather bracer" },
            { item = "right leather bracer" },
            { item = "chitin club" },
            { item = "nordic_leather_shield" },
        }
        return gearList
    end,
    ["Bounty Hunter"] = function()
        local gearList = {
            { item = "iron war axe" },
            { item = "steel crossbow" },
            { item = "steel bolt", count = arrowAmount },
            { item = "imperial_chain_cuirass" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "nordic_leather_shield" },
            { item = "Gold_001", count = goldAmount },
        }
        return gearList
    end,
    ["Brawler"] = function()
        local gearList = {
            { item = "left cloth horny fist bracer" },
            { item = "right cloth horny fist bracer" },
            { item = "Gold_001", count = goldAmount },
            { item = "sc_secondbarrier" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "p_jump_q", count= 2},
            { item = "apparatus_a_mortar_01" },
            { item = "apparatus_a_calcinator_01" },
            { item = "nordic_leather_shield" },
            { item = "fur_cuirass" },
        }
        return gearList
    end,
    ["Buoyant Armiger"] = function()
        local gearList = {
            { item = "short bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "iron dagger" },
            { item = "p_chameleon_s", count= 2},
            { item = "p_jump_s", count= 2},
            { item = "bk_CantatasOfVivec" },
            { item = "nordic_leather_shield" },
            { item = "p_fortify_fatigue_s", count= 2},
        }
        return gearList
    end,
    ["Caravaner"] = function()
        local gearList = {
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "p_chameleon_s", count= 2},
            { item = "probe_journeyman_01", },
            { item = "pick_journeyman_01", },
            { item = "p_jump_q", count= 2},
            { item = "potion_t_bug_musk_01" },
            { item = "sc_firstbarrier" },
            { item = "gondolier_helm" },
            { item = "netch_leather_pauldron_left" },
            { item = "netch_leather_pauldron_right" },
            { item = "chitin club" },
            { item = "nordic_leather_shield" },
        }
        return gearList
    end,
    ["Caretaker"] = function()
        local gearList = {
            { item = "p_jump_q", count= 2},
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "probe_journeyman_01", count= 2},
            { item = "pick_journeyman_01", count= 2},
            { item = "Gold_001", count = goldAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "p_chameleon_s" },
            { item = "p_fortify_personality_s" },
            { item = "Misc_SoulGem_Petty", count= 2},
        }
        return gearList
    end,
    ["Champion"] = function()
        local gearList = {
            { item = "iron war axe" },
            { item = "netch_leather_shield" },
            { item = "imperial_chain_greaves" },
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "steel crossbow" },
            { item = "steel bolt", count = arrowAmount },
            { item = "p_fortify_fatigue_s", count= 2},
            { item = "p_jump_s", count= 2},
        }
        return gearList
    end,
    ["Clothier"] = function()
        local gearList = {
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "p_chameleon_s", count= 2},
            { item = "probe_journeyman_01", count= 2},
            { item = "pick_journeyman_01", count= 2},
            { item = "p_jump_q", count= 2},
            { item = "potion_t_bug_musk_01" },
            { item = "sc_firstbarrier" },
            { item = "expensive_pants_01_z" },
            { item = "expensive_robe_03" },
            { item = "common_robe_04" },
            { item = "common_shirt_05" },
            { item = "left leather bracer" },
            { item = "right leather bracer" },
            { item = "chitin club" },
            { item = "nordic_leather_shield" },
        }
        return gearList
    end,
    ["Commoner"] = function()
        local gearList = {
            { item = "common_glove_right_01" },
            { item = "common_glove_left_01" },
            { item = "Gold_001", count = goldAmount },
            { item = "sc_secondbarrier" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "potion_t_bug_musk_01" },
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "probe_apprentice_01", count= 2},
            { item = "pick_apprentice_01", count= 2},
            { item = "p_chameleon_s" },
            { item = "p_jump_s", count= 2},
            { item = "chitin dagger" },
            { item = "nordic_leather_shield" },
        }
        return gearList
    end,
    ["Crusader"] = function()
        local gearList = {
            { item = "iron club" },
            { item = "iron broadsword" },
            { item = "iron boots" },
            { item = "iron_cuirass" },
            { item = "netch_leather_shield" },
            { item = "repair_prongs", count= 2},
            { item = "common_glove_right_01" },
            { item = "common_glove_left_01" },
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
            { item = "apparatus_a_mortar_01" },
        }
        return gearList
    end,
    ["Dreamers"] = function()
        local gearList = {
            { item = "steel throwing star", count = throwingStarAmount },
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "iron club" },
            { item = "p_chameleon_s", count= 2},
            { item = "nordic_leather_shield" },
            { item = "probe_apprentice_01", count= 2},
            { item = "pick_apprentice_01", count= 2},
            { item = "ingred_corprus_weepings_01" },

            { item = "p_fortify_fatigue_s", count= 2},
            { item = "p_jump_s", count= 2},
        }
        return gearList
    end,
    ["Drillmaster"] = function()
        local gearList = {
            { item = "netch_leather_shield" },
            { item = "sc_secondbarrier" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "common_glove_right_01" },
            { item = "common_glove_left_01" },
            { item = "Gold_001", count = goldAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "iron saber" },
            { item = "chitin war axe" },
            { item = "chitin spear" },
            { item = "chitin club" },
            { item = "chitin dagger" },
        }
        return gearList
    end,
    ["Enchanter"] = function()
        local gearList = {
            { item = "sc_fphyggisgemfeeder" },
            { item = "Misc_SoulGem_Petty", count= 2},
            { item = "steel staff" },
            { item = "apparatus_a_mortar_01" },
            { item = "apparatus_a_calcinator_01" },
            { item = "sc_secondbarrier" },
            { item = "common_robe_02_t"},
        }
        return gearList
    end,
    ["Enforcer"] = function()
        local gearList = {
            { item = "iron dagger" },
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "short bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "p_chameleon_s", count= 2},
            { item = "probe_apprentice_01", count= 2},
            { item = "pick_apprentice_01", count= 2},
            { item = "nordic_leather_shield" },
            { item = "p_fortify_fatigue_s", count= 2},
        }
        return gearList
    end,
    ["Farmer"] = function()
        local gearList = {
            { item = "iron club" },
            { item = "misc_de_muck_shovel_01" },
            { item = "ingred_corkbulb_root_01", count= 3},
            { item = "Gold_001", count = goldAmount },
            { item = "p_fortify_fatigue_q", count= 4},
            { item = "sc_secondbarrier" },
            { item = "ingred_ash_yam_01", count = 3},
            { item = "p_jump_s", count= 2},
            { item = "chitin dagger" },
            { item = "left leather bracer" },
            { item = "right leather bracer" },
        }
        return gearList
    end,
    ["Fencer"] = function()
        local gearList = {
            { item = "steel saber" },
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "sc_secondbarrier" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "p_jump_s", count= 2},
            { item = "Misc_SoulGem_Petty", count= 2},
            { item = "apparatus_a_mortar_01" },
            { item = "p_fortify_personality_s" },
        }
        return gearList
    end,
    ["Fool"] = function()
        local gearList = {
            { item = "p_jump_q", count= 2},
            { item = "steel throwing star", count = throwingStarAmount },
            { item = "p_chameleon_s", count= 2},
            { item = "sc_secondbarrier" },
            { item = "p_fortify_personality_s" },
            { item = "common_glove_right_01" },
            { item = "common_glove_left_01" },
            { item = "chitin dagger" },
            { item = "probe_apprentice_01", count= 2},
            { item = "pick_apprentice_01", count= 2},
        }
        return gearList
    end,
    ["Gardener"] = function()
        local gearList = {
            { item = "common_glove_right_01" },
            { item = "common_glove_left_01" },
            { item = "Gold_001", count = goldAmount },
            { item = "sc_secondbarrier" },
            { item = "potion_t_bug_musk_01" },
            { item = "Gold_001", count = goldAmount },
            { item = "ingred_gold_kanet_01", count = 3},
            { item = "ingred_timsa-come-by_01", count = 3},
            { item = "apparatus_a_mortar_01" },
            { item = "p_jump_s", count= 2},
            { item = "p_fortify_fatigue_s", count= 2},
        }
        return gearList
    end,
    ["Gladiator"] = function()
        local gearList = {
            { item = "iron war axe" },
            { item = "iron spear" },
            { item = "netch_leather_shield" },
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "p_fortify_personality_s" },
            { item = "p_jump_s", count= 2},
            { item = "right leather bracer" },
            { item = "imperial_chain_pauldron_left" },
        }
        return gearList
    end,
    ["Gondolier"] = function()
        local gearList = {
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "potion_t_bug_musk_01" },
            { item = "p_chameleon_s", count= 2},
            { item = "common_shirt_gondolier" },
            { item = "gondolier_helm" },
            { item = "Gold_001", count = goldAmount },
            { item = "sc_secondbarrier" },
            { item = "probe_apprentice_01", count= 2},
            { item = "pick_apprentice_01", count= 2},
            { item = "nordic_leather_shield" },
            { item = "left leather bracer" },
            { item = "right leather bracer" },
            { item = "chitin dagger" },
        }
        return gearList
    end,
    ["Guard"] = function()
        local gearList = {
            { item = "iron broadsword" },
            { item = "iron club" },
            { item = "netch_leather_shield" },
            { item = "iron boots" },
            { item = "iron_cuirass" },
            { item = "imperial_chain_greaves" },
            { item = "p_fortify_fatigue_s", count= 2},
            { item = "p_jump_s", count= 2},
            { item = "probe_apprentice_01", count= 2},
            { item = "pick_apprentice_01", count= 2},
            { item = "p_fortify_personality_s" },
            { item = "common_glove_right_01" },
            { item = "common_glove_left_01" },
        }
        return gearList
    end,
    ["Guild Guide"] = function()
        local gearList = {
            { item = "sc_didalasknack" },
            { item = "potion_t_bug_musk_01" },
            { item = "p_chameleon_s", count= 2},
            { item = "chitin dagger" },
            { item = "sc_firstbarrier" },
            { item = "probe_apprentice_01", },
            { item = "pick_apprentice_01", },
            { item = "sc_leaguestep", },
            { item = "sc_mark", },
            { item = "common_robe_02_r"},
            { item = "Misc_SoulGem_Petty", count= 2},
        }
        return gearList
    end,
    ["Healer"] = function()
        local gearList = {
            { item = "Gold_001", count = goldAmount },
            { item = "sc_cureblight_ranged" },
            { item = "Gold_001", count = goldAmount },
            { item = "potion_t_bug_musk_01" },
            { item = "apparatus_a_mortar_01" },
            { item = "sc_firstbarrier" },
            { item = "fur_pauldron_left" },
            { item = "fur_pauldron_right" },
            { item = "common_robe_05_b"},
            { item = "wooden staff" },
        }
        return gearList
    end,
    ["Herder"] = function()
        local gearList = {
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "short bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "iron spear" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "p_jump_s", count= 2},
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
            { item = "ingred_guar_hide_01", count= 2},
            { item = "nordic_leather_shield" },
        }
        return gearList
    end,
    ["Hermit"] = function()
        local gearList = {
            { item = "apparatus_a_mortar_01" },
            { item = "apparatus_a_calcinator_01" },
            { item = "short bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "hammer_repair", count= 2},
            { item = "wooden staff" },
            { item = "fur_pauldron_left" },
            { item = "fur_pauldron_right" },
            { item = "p_chameleon_s" },
            { item = "common_robe_01"},
        }
        return gearList
    end,
    ["Hood"] = function()
        local gearList = {
            { item = "Gold_001", count = goldAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "iron dagger" },
            { item = "iron club" },
            { item = "imperial_chain_cuirass" },
            { item = "p_chameleon_s", count= 2},
            { item = "probe_apprentice_01", count= 2},
            { item = "pick_apprentice_01", count= 2},
            { item = "p_fortify_fatigue_s", count= 2},
            { item = "nordic_leather_shield" },
        }
        return gearList
    end,
    ["Hunter"] = function()
        local gearList = {
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "long bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "iron dagger" },
            { item = "p_chameleon_s", count= 2},
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "p_jump_s", count= 2},
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
            { item = "nordic_leather_shield" },
        }
        return gearList
    end,
    ["Journalist"] = function()
        local gearList = {
            { item = "sc_secondbarrier" },
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "potion_t_bug_musk_01" },
            { item = "sc_paper plain", count= 2},
            { item = "Misc_Inkwell" },
            { item = "Misc_Quill" },
            { item = "Gold_001", count = goldAmount },
            { item = "p_fortify_fatigue_s", count= 2},
            { item = "apparatus_a_mortar_01" },
            { item = "Misc_SoulGem_Petty", count= 2},
            { item = "probe_apprentice_01", count= 2},
            { item = "pick_apprentice_01", count= 2},
        }
        return gearList
    end,
    ["Juggler"] = function()
        local gearList = {
            { item = "steel throwing star", count = throwingStarAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "iron dagger" },
            { item = "p_chameleon_s" },
            { item = "common_glove_right_01" },
            { item = "common_glove_left_01" },
            { item = "sc_firstbarrier" },
            { item = "p_jump_s", count= 2},
        }
        return gearList
    end,
    ["King"] = function()
        local gearList = {
            { item = "potion_t_bug_musk_01" },
            { item = "iron broadsword" },
            { item = "iron boots" },
            { item = "iron_cuirass" },
            { item = "nordic_leather_shield" },
            { item = "exquisite_pants_01" },
            { item = "Gold_001", count = goldAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "exquisite_shirt_01" },
        }
        return gearList
    end,
    ["Knight"] = function()
        local gearList = {
            { item = "steel longsword" },
            { item = "potion_t_bug_musk_01" },
            { item = "iron boots" },
            { item = "iron_cuirass" },
            { item = "netch_leather_shield" },
            { item = "Gold_001", count = goldAmount },
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
            { item = "Misc_SoulGem_Petty", count= 2},
            { item = "repair_prongs", count= 2},
        }
        return gearList
    end,
    ["Mabrigash"] = function()
        local gearList = {
            { item = "netch_leather_shield" },
            { item = "iron war axe" },
            { item = "sc_firstbarrier" },
            { item = "p_fortify_fatigue_s", count= 2},
            { item = "p_chameleon_s" },
            { item = "expensive_robe_01"},
            { item = "p_fortify_personality_s" },
        }
        return gearList
    end,
    ["Mage"] = function()
        local gearList = {
            { item = "Gold_001", count = goldAmount },
            { item = "Misc_SoulGem_Petty", count= 2},
            { item = "apparatus_a_mortar_01" },
            { item = "sc_firstbarrier" },
            { item = "chitin dagger" },
            { item = "common_robe_03_b" },
        }
        return gearList
    end,
    ["Marauder"] = function()
        local gearList = {
            { item = "iron war axe" },
            { item = "iron club" },
            { item = "iron boots" },
            { item = "iron_cuirass" },
            { item = "imperial_chain_greaves" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "repair_prongs", count= 2},
            { item = "common_glove_right_01" },
            { item = "common_glove_left_01" },
            { item = "chitin spear" },
        }
        return gearList
    end,
    ["Master-at-Arms"] = function()
        local gearList = {
            { item = "iron spear" },
            { item = "iron dagger" },
            { item = "iron broadsword" },
            { item = "iron war axe" },
            { item = "iron club" },
            { item = "nordic_leather_shield" },
            { item = "imperial_chain_pauldron_left" },
            { item = "left leather bracer" },
            { item = "right leather bracer" },
            { item = "iron_pauldron_right" },
        }
        return gearList
    end,
    ["Merchant"] = function()
        local gearList = {
            { item = "potion_t_bug_musk_01" },
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "hammer_repair", count= 2},
            { item = "probe_journeyman_01", count= 2},
            { item = "pick_journeyman_01", count= 2},
            { item = "left leather bracer" },
            { item = "right leather bracer" },
            { item = "iron saber" },
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
        }
        return gearList
    end,
    ["Miner"] = function()
        local gearList = {
            { item = "netch_leather_shield" },
            { item = "iron club" },
            { item = "miner's pick" },
            { item = "sc_secondbarrier" },
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "food_kwama_egg_02", count= 2},
            { item = "food_kwama_egg_01", count= 3},
            { item = "repair_prongs", count= 2},
            { item = "iron_pauldron_right" },
            { item = "iron_pauldron_left" },
        }
        return gearList
    end,
    ["Monk"] = function()
        local gearList = {
            { item = "left cloth horny fist bracer" },
            { item = "right cloth horny fist bracer" },
            { item = "sc_secondbarrier", count= 2},
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "p_jump_q", count= 2},
            { item = "p_chameleon_s", count= 2},
            { item = "chitin throwing star", count = throwingStarAmount },
            { item = "netch_leather_pauldron_left" },
            { item = "netch_leather_pauldron_right" },
        }
        return gearList
    end,
    ["Necromancer"] = function()
        local gearList = {
            { item = "sc_fphyggisgemfeeder" },
            { item = "Misc_SoulGem_Petty" },
            { item = "sc_summonskeletalservant", count= 2},
            { item = "steel staff of the ancestors" },
            { item = "sc_firstbarrier" },
            { item = "common_robe_02_h"},
            { item = "misc_skull10"},
        }
        return gearList
    end,
    ["Nightblade"] = function()
        local gearList = {
            { item = "Gold_001", count = goldAmount },
            { item = "p_chameleon_s", count= 2},
            { item = "steel jinkblade" },
            { item = "netch_leather_pauldron_left" },
            { item = "netch_leather_pauldron_right" },
            { item = "sc_firstbarrier" },
            { item = "chitin throwing star", count = throwingStarAmount },
            { item = "probe_apprentice_01", count= 2},
            { item = "pick_apprentice_01", count= 2},
        }
        return gearList
    end,
    ["Noble"] = function()
        local gearList = {
            { item = "potion_t_bug_musk_01" },
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "iron dagger" },
            { item = "probe_journeyman_01" },
            { item = "pick_journeyman_01" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "left leather bracer" },
            { item = "right leather bracer" },
            { item = "exquisite_robe_01" },
            { item = "exquisite_shoes_01" },
        }
        return gearList
    end,
    ["Ordinator"] = function()
        local gearList = {
            { item = "iron broadsword" },
            { item = "iron boots" },
            { item = "iron_cuirass" },
            { item = "netch_leather_shield" },
            { item = "p_jump_s", count= 2},
            { item = "common_glove_right_01" },
            { item = "common_glove_left_01" },
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
            { item = "apparatus_a_mortar_01" },
        }
        return gearList
    end,
    ["Paladin"] = function()
        local gearList = {
            { item = "steel longsword" },
            { item = "netch_leather_shield" },
            { item = "iron boots" },
            { item = "iron_cuirass" },
            { item = "potion_t_bug_musk_01" },
            { item = "apparatus_a_mortar_01" },
            { item = "Misc_SoulGem_Petty", count= 2},
            { item = "repair_prongs", count= 2},
            { item = "bk_formygodsandemperor" }
        }
        return gearList
    end,
    ["Pauper"] = function()
        local gearList = {
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "chitin dagger" },
            { item = "nordic_leather_shield" },
        }
        return gearList
    end,
    ["Pawnbroker"] = function()
        local gearList = {
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "p_chameleon_s", count= 2},
            { item = "probe_journeyman_01", count= 2},
            { item = "pick_journeyman_01", count= 2},
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "potion_t_bug_musk_01" },
            { item = "sc_firstbarrier" },
            { item = "common_glove_right_01" },
            { item = "common_glove_left_01" },
            { item = "p_jump_s" },
            { item = "misc_de_bowl_bugdesign_01" },
            { item = "misc_de_bowl_glass_peach_01" },
            { item = "misc_com_redware_platter" },
            { item = "chitin club" },
            { item = "nordic_leather_shield" },
        }
        return gearList
    end,
    ["Pilgrim"] = function()
        local gearList = {
            { item = "potion_t_bug_musk_01" },
            { item = "sc_didalasknack" },
            { item = "short bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "imperial_chain_cuirass" },
            { item = "common_glove_right_01" },
            { item = "common_glove_left_01" },
            { item = "chitin dagger" },
            { item = "nordic_leather_shield" },
            { item = "apparatus_a_mortar_01" },
        }
        return gearList
    end,
    ["Pirate"] = function()
        local gearList = {
            { item = "iron broadsword" },
            { item = "netch_leather_shield" },
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "short bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "ingred_emerald_01" },
            { item = "p_chameleon_s" },
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
        }
        return gearList
    end,
    ["Poacher"] = function()
        local gearList = {
            { item = "iron spear" },
            { item = "short bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "imperial_chain_cuirass" },
            { item = "p_chameleon_s", count= 2},
            { item = "p_fortify_fatigue_s", count= 2},
            { item = "ingred_hound_meat_01", count = 3},
            { item = "apparatus_a_mortar_01" },
            { item = "p_jump_s", count= 2},
        }
        return gearList
    end,
    ["Priest"] = function()
        local gearList = {
            { item = "Gold_001", count = goldAmount },
            { item = "steel staff" },
            { item = "sc_secondbarrier" },
            { item = "apparatus_a_mortar_01" },
            { item = "merisan helm" },
            { item = "p_fortify_personality_s" },
            { item = "common_robe_05_a"},
        }
        return gearList
    end,
    ["Publican"] = function()
        local gearList = {
            { item = "potion_t_bug_musk_01" },
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "p_chameleon_s", count= 2},
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "probe_journeyman_01", count= 2},
            { item = "pick_journeyman_01", count= 2},
            { item = "nordic_leather_shield" },
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
            { item = "chitin spear" },
            { item = "ingred_bread_01", count= 2},
            { item = "Potion_Local_Brew_01", count= 2},
        }
        return gearList
    end,
    ["Pugilist"] = function()
        local gearList = {
            { item = "left cloth horny fist bracer" },
            { item = "right cloth horny fist bracer" },
            { item = "sc_secondbarrier", count= 2},
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "p_jump_q", count= 2},
            { item = "netch_leather_pauldron_left" },
            { item = "netch_leather_pauldron_right" },
        }
        return gearList
    end,
    ["Queen Mother"] = function()
        local gearList = {
            { item = "potion_t_bug_musk_01" },
            { item = "iron dagger" },
            { item = "sc_secondbarrier" },
            { item = "exquisite_shirt_01" },
            { item = "exquisite_skirt_01", },
            { item = "exquisite_shoes_01" },
        }
        return gearList
    end,
    ["Ranger"] = function()
        local gearList = {
            { item = "iron broadsword" },
            { item = "netch_leather_shield" },
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "long bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "apparatus_a_mortar_01" },
            { item = "apparatus_a_calcinator_01" },
            { item = "p_fortify_fatigue_s", count= 2},
            { item = "p_jump_s", count= 2},
            { item = "p_chameleon_s" },
        }
        return gearList
    end,
    ["Rogue"] = function()
        local gearList = {
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "iron war axe" },
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "Gold_001", count = goldAmount },
            { item = "nordic_leather_shield" },
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
            { item = "p_fortify_personality_s" },
            { item = "p_fortify_fatigue_s", count= 2},
        }
        return gearList
    end,
    ["Sage"] = function()
        local gearList = {
            { item = "potion_t_bug_musk_01" },
            { item = "sc_fphyggisgemfeeder" },
            { item = "Misc_SoulGem_Petty", count= 2},
            { item = "apparatus_a_mortar_01" },
            { item = "apparatus_a_calcinator_01" },
            { item = "Gold_001", count = goldAmount },
            { item = "wooden staff" },
            { item = "p_fortify_intelligence_s" },
            { item = "fur_pauldron_left" },
            { item = "fur_pauldron_right" },
            { item = "common_robe_05"},
        }
        return gearList
    end,
    ["Savant"] = function()
        local gearList = {
            { item = "potion_t_bug_musk_01" },
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "apparatus_a_mortar_01" },
            { item = "apparatus_a_calcinator_01" },
            { item = "sc_secondbarrier" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "probe_apprentice_01" },
            { item = "pick_apprentice_01", },
            { item = "bk_ShortHistoryMorrowind" },
            { item = "p_fortify_intelligence_s" },
            { item = "chitin dagger" },
            { item = "nordic_leather_shield" },
        }
        return gearList
    end,
    ["Scout"] = function()
        local gearList = {
            { item = "p_chameleon_s", count= 2},
            { item = "iron broadsword" },
            { item = "imperial_chain_cuirass" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "netch_leather_shield" },
            { item = "chitin short bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "apparatus_a_mortar_01" },
            { item = "netch_leather_pauldron_left" },
            { item = "netch_leather_pauldron_right" },
            { item = "sc_firstbarrier" },
        }
        return gearList
    end,
    ["Shadow"] = function()
        local gearList = {
            { item = "p_chameleon_s", count= 2},
            { item = "sc_secondbarrier" },
            { item = "Gold_001", count = goldAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "p_fortify_fatigue_s", count= 2},
            { item = "p_jump_s", count= 2},
            { item = "Misc_SoulGem_Petty", count= 2},
            { item = "common_robe_05"},
        }
        return gearList
    end,
    ["Shaman"] = function()
        local gearList = {
            { item = "imperial_chain_cuirass" },
            { item = "potion_t_bug_musk_01" },
            { item = "steel staff" },
            { item = "p_chameleon_s" },
            { item = "Misc_SoulGem_Petty", count= 2},
            { item = "p_fortify_fatigue_s", count= 2},
            { item = "sc_messengerscroll" },
        }
        return gearList
    end,
    ["Sharpshooter"] = function()
        local gearList = {
            { item = "long bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "imperial_chain_cuirass" },
            { item = "sc_fphyggisgemfeeder" },
            { item = "Misc_SoulGem_Petty", count= 2},
            { item = "p_chameleon_s", count= 2},
            { item = "p_jump_s", count= 2},
            { item = "probe_apprentice_01", count= 2},
            { item = "pick_apprentice_01", count= 2},
            { item = "p_fortify_fatigue_s", count= 2},
        }
        return gearList
    end,
    ["Shipmaster"] = function()
        local gearList = {
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "potion_t_bug_musk_01" },
            { item = "iron dagger" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "common_shirt_gondolier" },
            { item = "nordic_leather_shield" },
            { item = "sc_firstbarrier" },
            { item = "left leather bracer" },
            { item = "right leather bracer" },
            { item = "probe_apprentice_01", count= 2},
            { item = "pick_apprentice_01", count= 2},
        }
        return gearList
    end,
    ["Slave"] = function()
        local gearList = {
            { item = "p_chameleon_s", count= 2},
            { item = "p_jump_q", count= 2},
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "iron boots" },
            { item = "iron_cuirass" },
            { item = "slave_bracer_left" },
            { item = "slave_bracer_right" },
            { item = "repair_prongs", count= 2},
            { item = "nordic_leather_shield" },
        }
        return gearList
    end,
    ["Smith"] = function()
        local gearList = {
            { item = "netch_leather_shield" },
            { item = "steel warhammer" },
            { item = "Gold_001", count = goldAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "hammer_repair", count = 5},
            { item = "imperial_chain_pauldron_left" },
            { item = "left leather bracer" },
            { item = "right leather bracer" },
            { item = "iron_pauldron_right" },
        }
        return gearList
    end,
    ["Smuggler"] = function()
        local gearList = {
            { item = "iron club" },
            { item = "p_chameleon_s", count= 2},
            { item = "Gold_001", count = goldAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "misc_dwrv_bowl00" },
            { item = "p_fortify_fatigue_s", count= 2},
            { item = "misc_dwrv_mug00" },
            { item = "misc_dwrv_goblet00" },
            { item = "misc_dwrv_pitcher00" },
            { item = "dwemer_bracer_left" },
            { item = "dwemer_bracer_right" },
        }
        return gearList
    end,
    ["Sorcerer"] = function()
        local gearList = {
            { item = "sc_fphyggisgemfeeder" },
            { item = "Misc_SoulGem_Petty", count= 3},
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
            { item = "iron_bracer_left" },
            { item = "iron_bracer_right" },
            { item = "chitin dagger" },
            { item = "common_robe_02_rr"},
        }
        return gearList
    end,
    ["Spearman"] = function()
        local gearList = {
            { item = "steel spear" },
            { item = "imperial_chain_cuirass" },
            { item = "p_jump_q", count= 2},
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "iron_pauldron_right" },
            { item = "iron_pauldron_left" },
            { item = "apparatus_a_mortar_01" },
            { item = "repair_prongs", count= 2},
        }
        return gearList
    end,
    ["Spellsword"] = function()
        local gearList = {
            { item = "netch_leather_shield" },
            { item = "iron broadsword" },
            { item = "Gold_001", count = goldAmount },
            { item = "Misc_SoulGem_Petty", count= 2},
            { item = "apparatus_a_mortar_01" },
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
        }
        return gearList
    end,
    ["T_Cyr_Dockworker"] = function()
        local gearList = {
            { item = "iron club"},
            { item = "left leather bracer" },
            { item = "right leather bracer" },
            { item = "common_glove_right_01" },
            { item = "common_glove_left_01"},
            { item = "nordic_leather_shield" },
            { item = "p_fortify_fatigue_q", count =3},
            { item = "p_feather_q", count =3},
            { item = "p_jump_s", count = 2},
            { item = "sc_secondbarrier" },
        }
        return gearList
    end,
    ["T_Glb_Banker"] = function()
        local gearList = {
            { item = "potion_t_bug_musk_01" },
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "p_chameleon_s", count= 2},
            { item = "probe_journeyman_01", count= 2},
            { item = "pick_journeyman_01", count= 2},
            { item = "sc_firstbarrier" },
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
            { item = "chitin dagger" },
            { item = "left leather bracer" },
            { item = "right leather bracer" },
        }
        return gearList
    end,
    ["T_Mw_Baker"] = function()
        local gearList = {
            { item = "apparatus_a_mortar_01" },
            { item = "apparatus_a_calcinator_01" },
            { item = "potion_t_bug_musk_01" },
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "nordic_leather_shield" },
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
            { item = "chitin spear" },
            { item = "ingred_bread_01", count = 3},
        }
        return gearList
    end,
    ["T_Mw_CatCatcher"] = function()
        local gearList = {
            { item = "iron club" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "p_chameleon_s", count= 2},
            { item = "probe_apprentice_01", count= 2},
            { item = "pick_apprentice_01", count= 2},
            { item = "chitin short bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "fur_pauldron_left" },
            { item = "fur_pauldron_right" },
            { item = "p_jump_s", count= 2},
        }
        return gearList
    end,
    ["T_Mw_Fisherman"] = function()
        local gearList = {
            { item = "iron spear" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "ingred_scales_01" },
            { item = "ingred_crab_meat_01" },
            { item = "Gold_001", count = goldAmount },
            { item = "sc_secondbarrier" },
            { item = "left leather bracer" },
            { item = "right leather bracer" },
            { item = "Gold_001", count = goldAmount },
            { item = "nordic_leather_shield" },
            { item = "p_jump_s", count= 2},
            { item = "p_fortify_personality_s" },
        }
        return gearList
    end,
    ["T_Mw_OreMiner"] = function()
        local gearList = {
            { item = "hammer_repair", count= 2},
            { item = "netch_leather_shield" },
            { item = "miner's pick" },
            { item = "iron club" },
            { item = "sc_secondbarrier" },
            { item = "ingred_raw_glass_01" },
            { item = "left leather bracer" },
            { item = "right leather bracer" },
            { item = "common_glove_right_01" },
            { item = "common_glove_left_01" },
            { item = "iron_pauldron_right" },
            { item = "iron_pauldron_left" },
        }
        return gearList
    end,
    ["T_Mw_RiverstriderService"] = function()
        local gearList = {
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "probe_journeyman_01", count= 2},
            { item = "pick_journeyman_01", count= 2},
            { item = "potion_t_bug_musk_01" },
            { item = "nordic_leather_shield" },
            { item = "fur_pauldron_left" },
            { item = "fur_pauldron_right" },
            { item = "sc_firstbarrier" },
            { item = "common_shirt_gondolier" },
            { item = "gondolier_helm" },
            { item = "chitin club" },
        }
        return gearList
    end,
    ["T_Mw_Sailor"] = function()
        local gearList = {
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "common_shirt_gondolier" },
            { item = "gondolier_helm" },
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "sc_secondbarrier" },
            { item = "iron broadsword" },
            { item = "p_jump_s", count= 2},
            { item = "p_water_breathing_s", count= 2},
            { item = "chitin dagger" },
        }
        return gearList
    end,
    ["T_Mw_Scribe"] = function()
        local gearList = {
            { item = "potion_t_bug_musk_01" },
            { item = "sc_secondbarrier" },
            { item = "apparatus_a_mortar_01" },
            { item = "apparatus_a_calcinator_01" },
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "probe_apprentice_01", count= 2},
            { item = "pick_apprentice_01", count= 2},
            { item = "chitin war axe" },
            { item = "sc_paper plain", count= 2},
            { item = "Misc_Inkwell" },
            { item = "Misc_Quill" },
            { item = "sc_tevilspeace" },
            { item = "sc_restoration" },
        }
        return gearList
    end,
    ["T_Sky_Clever-Man"] = function()
        local gearList = {
            { item = "chitin war axe" },
            { item = "nordic_leather_shield" },
            { item = "BM_Nordic01_Robe" },
            { item = "iron_pauldron_right" },
            { item = "iron_pauldron_left" },
            { item = "p_frost_shield_s", count = 2},
            { item = "p_lightning shield_s", count = 2},
            { item = "p_fire_shield_s", count = 2},
            { item = "Misc_SoulGem_Petty", count = 2},
        }
        return gearList
    end,
    ["T_Sky_Courtesan"] = function()
        local gearList = {
            { item = "iron dagger" },
            { item = "extravagant_amulet_01" },
            { item = "extravagant_skirt_02" },
            { item = "potion_t_bug_musk_01", count =3},
            { item = "sc_didalasknack", count =2},
            { item = "p_fortify_fatigue_q", count =2},
            { item = "Gold_001", count = goldAmount},
        }
        return gearList
    end,
    ["T_Sky_Jarl"] = function()
        local gearList = {
            { item = "nordic broadsword" },
            { item = "nordic_ringmail_cuirass" },
            { item = "nordic_iron_cuirass" },
            { item = "nordic_leather_shield"},
            { item = "p_fortify_fatigue_s", count = 2},
            { item = "repair_prongs", count = 2},
        }
        return gearList
    end,

    ["Thaumaturge"] = function()
        local gearList = {
            { item = "Gold_001", count = goldAmount },
            { item = "steel staff" },
            { item = "sc_secondbarrier" },
            { item = "chitin throwing star", count = throwingStarAmount },
            { item = "p_chameleon_s" },
            { item = "netch_leather_pauldron_left" },
            { item = "netch_leather_pauldron_right" },
            { item = "common_robe_02_tt"},
        }
        return gearList
    end,
    ["Thief"] = function()
        local gearList = {
            { item = "probe_journeyman_01", count= 4},
            { item = "pick_journeyman_01", count= 4},
            { item = "p_chameleon_s", count= 2},
            { item = "p_jump_q", count= 2},
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "iron dagger" },
            { item = "chitin short bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "p_fortify_fatigue_s", count= 2},
        }
        return gearList
    end,
    ["Trader"] = function()
        local gearList = {
            { item = "sc_didalasknack" },
            { item = "Gold_001", count = goldAmount },
            { item = "Gold_001", count = goldAmount },
            { item = "p_chameleon_s", count= 2},
            { item = "potion_t_bug_musk_01" },
            { item = "probe_journeyman_01" },
            { item = "pick_journeyman_01" },
            { item = "sc_firstbarrier" },
            { item = "left leather bracer" },
            { item = "right leather bracer" },
            { item = "chitin club" },
            { item = "nordic_leather_shield" },
        }
        return gearList
    end,
    ["Veteran"] = function()
        local gearList = {
            { item = "iron broadsword" },
            { item = "iron spear" },
            { item = "netch_leather_shield" },
            { item = "iron boots" },
            { item = "iron_cuirass" },
            { item = "chitin short bow" },
            { item = "iron arrow", count = arrowAmount },
            { item = "repair_prongs", count= 2},
            { item = "apparatus_a_mortar_01" },
            { item = "imperial_chain_pauldron_right" },
            { item = "imperial_chain_pauldron_left" },
        }
        return gearList
    end,
    ["Warlock"] = function()
        local gearList = {
            { item = "iron dagger" },
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "p_fortify_fatigue_s", count= 2},
            { item = "p_chameleon_s" },
            { item = "p_jump_s", count= 2},
            { item = "p_fortify_personality_s" },
            { item = "common_robe_03"},
        }
        return gearList
    end,
    ["Warlord"] = function()
        local gearList = {
            { item = "steel axe" },
            { item = "steel_boots" },
            { item = "iron_cuirass" },
            { item = "Gold_001", count = goldAmount },
            { item = "steel crossbow" },
            { item = "iron bolt", count = arrowAmount },
            { item = "steel_shield" },
            { item = "iron flamemace" },
        }
        return gearList
    end,
    ["Warrior"] = function()
        local gearList = {
            { item = "steel broadsword" },
            { item = "imperial_chain_greaves" },
            { item = "imperial_chain_coif_helm" },
            { item = "iron boots" },
            { item = "iron_cuirass" },
            { item = "p_fortify_fatigue_q", count= 2},
            { item = "iron_shield" },
            { item = "repair_prongs", count= 2},
            { item = "chitin short bow" },
            { item = "iron arrow", count = arrowAmount },
        }
        return gearList
    end,
    ["Wise Woman"] = function()
        local gearList = {
            { item = "ingred_scathecraw_01", count= 3},
            { item = "ingred_trama_root_01", count= 3},
            { item = "Gold_001", count = goldAmount },
            { item = "potion_t_bug_musk_01" },
            { item = "apparatus_a_mortar_01" },
            { item = "p_frost_shield_s" },
            { item = "left leather bracer" },
            { item = "right leather bracer" },
            { item = "wooden staff" },
            { item = "expensive_robe_01"},
        }
        return gearList
    end,
    ["Witch"] = function()
        local gearList = {
            { item = "sc_didalasknack" },
            { item = "sc_secondbarrier" },
            { item = "iron dagger" },
            { item = "fur_pauldron_left" },
            { item = "fur_pauldron_right" },
            { item = "p_chameleon_s" },
            { item = "p_jump_s", count= 2},
            { item = "p_fortify_personality_s" },
            { item = "common_robe_05_c"},
        }
        return gearList
    end,
    ["Witchhunter"] = function()
        local gearList = {
            { item = "sc_fphyggisgemfeeder" },
            { item = "Misc_SoulGem_Petty", },
            { item = "p_dispel_s", count= 2},
            { item = "apparatus_a_mortar_01" },
            { item = "apparatus_a_calcinator_01" },
            { item = "fur_cuirass" },
            { item = "fur_boots" },
            { item = "steel crossbow" },
            { item = "steel bolt", count = arrowAmount },
            { item = "p_frost_shield_s" },
            { item = "nordic_leather_shield" },
            { item = "chitin club" },
            { item = "p_chameleon_s" },
        }
        return gearList
    end,
}

return this
