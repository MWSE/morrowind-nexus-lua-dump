local this = {}
local goldAmount = 20
local arrowAmount = 20
local throwingStarAmount = 30
--[[
    Functions for each class returnErelvam's Wild Sty -spell
    gear list of item objects
]]
this.pickStarters = {
    ["Acrobat"] = function()
-- Acrobat' is a polite euphemism for agile burglars and second-story men. These thieves avoid detection by stealth, and rely on mobility and cunning to avoid capture.
        return {
            gearList = {
                { item = "p_jump_q" },
                { item = "p_restore_fatigue_q" },
                { item = "chitin throwing star", count = arrowAmount },
                { item = "watcher's belt" },
                { item = "netch_leather_helm" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "chitin spear" },
                { item = "aa_thw_net", count = 3 },
            },
            spellList = {
                "aa_cl_acrob_power",
                "jump",
            },
        }
    end,

    ["Agent"] = function()
-- Agents are operatives skilled in deception and avoidance, but trained in self-defense and the use of deadly force. Self-reliant and independent, agents devote themselves to personal goals, or to various patrons or causes.
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "p_chameleon_s" },
                { item = "p_jump_s" },
                { item = "netch_leather_helm" },
                { item = "netch_leather_cuirass" },
                { item = "chitin shortsword" },
                { item = "AB_Misc_PurseCoin" },
                { item = "watcher's belt" },
                { item = "netch_leather_shield" },
            },
            spellList = {
                "aa_cl_agent_power",
                "aa_cl_bank_power",
            },
        }
    end,

    ["Alchemist"] = function()
--Alchemists know the processes of refining and preserving the magical properties hidden in natural and supernatural ingredients. They buy and sell potions, the various kinds of apparatus needed to make potions, and ingredients.
        return {
            gearList = {
                { item = "apparatus_a_mortar_01" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
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
        }
    end,

    ["Antipaladin"] = function()
        return {
            gearList = {
                { item = "iron saber" },
                { item = "iron_shield" },
                { item = "T_Nor_Wood_Shield_01" },
                { item = "iron battle axe" },
                { item = "iron_greaves" },
                { item = "iron boots" },
                { item = "T_Com_Iron_Cuirass_01" },
                { item = "hammer_repair", count = 2 },
                { item = "bk_ArkayTheEnemy" }
            },
            spellList = {
                "aa_cl_antipal_spell",
                "absorb fatigue",
                "burden",
            },
        }
    end,
}

    ["Apothecary"] = function()
--Apothecaries brew and sell potions to heal wounds, restore bodily and mental attributes, and cure diseases.
        return {
            gearList = {
                { item = "apparatus_a_mortar_01" },
                { item = "aa_cl_speech_pot" },
                { item = "AB_Misc_PurseCoin" },
                { item = "wooden staff" },
                { item = "AB_c_CommonHood01" },
                { item = "netch_leather_shield" },
                { item = "Gold_001", count = 70 },
                { item = "jjs_plant_marsh" },
                { item = "jjs_plant_swtbardsrt" },
            },
            spellList = {
                "aa_cl_apth_destr",
                "cure poison",
            },
        }
    end,

    ["Arcanist"] = function()
--Arcanists are wizards who combine prodigious affinity to metaphysical magicks with more practical training with staff. Arcanists are ingenious and they use mystical rituals to turn the threads of fate ever slightly towards their favour.        return {
        return {
            gearList = {
                { item = "ingred_rune_a_01" },
                { item = "ingred_rune_a_10" },
                { item = "wooden staff" },
                { item = "OJ_W_WoodTwigsWand_EN_CSHB" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "AB_App_Grinder" },
            },
            spellList = {
                "disintegrate armor",
                "aa_cl_arcan_power",
                "spell absorption",
                "shield",
                "silence",
            },
        }
    end,

    ["Archeologist"] = function()
--Archeologists quietly explore ruins, hoping to uncover precious artifacts. They have knowledge of magical objects and how to restore them.            gearList = {
        return {
            gearList = {
                { item = "MU_ChalkC" },
                { item = "ashfall_woodaxe" },
                { item = "p_chameleon_s" },
                { item = "p_restore_fatigue_s" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "hammer_repair", count = 2 },
                { item = "light_com_lantern_01" },
                { item = "chitin shortsword" },
                { item = "AB_App_Grinder" }, 
            },
            spellList = {
                "aa_cl_archeo_power",
            },
        }
    end,

    ["Archer"] = function()
--Archers are fighters specializing in long-range combat and rapid movement. Opponents are kept at distance by ranged weapons and swift maneuver, and engaged in melee with sword and shield after the enemy is wounded and weary.
        return {
            gearList = {
                { item = "mer_fletch_kit" },
                { item = "long bow" },
                { item = "corkbulb arrow", count = arrowAmount },
                { item = "iron saber" },
                { item = "netch_leather_shield" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "T_Rea_Wormmouth_Helm_01" },
                { item = "p_chameleon_s" },
                { item = "chitin spear" },
            },
            spellList = {
                "aa_cl_archer_power",
            },
        }
    end,

    ["Artificer"] = function()
--Artificers are detail oriented crafters, capable of creating fine works of art or mechanical marvels. In addition to smithing and enchanting jewelry and embellishing armor, artificers may craft alchemical equipment, study dwemer mechanisms, smith locks, and if necessary, conduct cruder repairs to weapons and armor.
        return {
            gearList = {
                { item = "OJ_W_WoodTwigsWand_EN_CSHB" },
                { item = "hammer_repair", count = 2 },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "Misc_SoulGem_Lesser" },
                { item = "chitin club" },
                { item = "T_Com_Iron_PauldronR_01" },
                { item = "T_Com_Iron_PauldronL_01" },
                { item = "iron_shield" },
                { item = "AB_w_WoodCrossbow" },
                { item = "T_Com_Wood_Bolt_01", count = arrowAmount },
            },
            spellList = {
            },
        }
    end,

    ["Artisan"] = function()
    -- ["Artisan"] = function()
--Artisan are talented people who love to make new items and repair them. They are handy and skilled with a hammer. They can even create more refined items, some magical. They are shrewed salesmen.        return {
        return {
            gearList = {
                { item = "mc_pottery_wheel" },
                { item = "mc_jewelry_kit" },
                { item = "MG_Agate1" },
                { item = "WAR_BLACKSMITH_APRON01" },
                { item = "hammer_repair", count = 2 },
                { item = "watcher's belt" },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "AB_App_Grinder" },
                { item = "AB_a_WickerHelm" }, 
            },
            spellList = {
                "open",
            },
        }
    end,

    ["Assassin"] = function()
--Assassins are killers who rely on stealth and mobility to approach victims undetected. Execution is with ranged weapons or with short blades for close work. Assassins include ruthless murderers and principled agents of noble causes.
        return {
            gearList = {
                { item = "DWcalling card", count = 10 },
                { item = "p_chameleon_s" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowAmount },
                { item = "netch_leather_cuirass" },
                { item = "cruel viperblade" },
                { item = "p_jump_s" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "p_restore_fatigue_s" },
                { item = "AB_App_Grinder" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
            },
            spellList = {
            },
        }
    end,

    ["T_Mw_Baker"] = function()
--Bakers run or work in bakehouses, where they bake and sell bread, pastries, and cakes.        return {
        return {
            gearList = {
                { item = "NOM_yeast", count = 10 },
                { item = "NOM_sugar", count = 5 },
                { item = "WAR_BLACKSMITH_APRON01", },
                { item = "T_IngFood_BreadColovian_01", count = 3 },
                { item = "T_IngFood_BreadFlat_01", count = 3 },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
                { item = "AB_IngFood_SaltriceBread" },
                { item = "AB_IngFood_Sweetroll" },
                { item = "AB_w_CookKnifeBread" },
                { item = "T_Nor_Wood_Shield_01" },
                { item = "hammer_repair", count = 2 },
                { item = "AB_App_Grinder" },
                { item = "watcher's belt" },
                { item = "chitin club" },
                { item = "AB_a_WickerHelm" },
                { item = "aa_cl_speech_pot" },
            },
            spellList = {
                "mother's kiss",
            },
        }
    end,

    ["T_Glb_Banker"] = function()
--Bankers take care of deposits, withdrawals, money flow, payments, and loans at bank branches. Bankers also invest in the local economy or deal with immovable property for the benefit of their customers.            gearList = {
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "Gold_001", count = 100 },
                { item = "pick_journeyman_01" },
                { item = "watcher's belt" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "T_Imp_Chain_Boots_01" },
                { item = "expensive_pants_02" },
                { item = "expensive_shirt_02" },
                { item = "AB_Misc_PurseCoin" },
                { item = "firebite dagger" },
            },
            spellList = {
                "aa_cl_bank_power",
            },
        }
    end,

    ["Barbarian"] = function()
--Barbarians are the proud, savage warrior elite of the plains nomads, mountain tribes, and sea reavers. They tend to be brutal and direct, lacking civilized graces, but they glory in heroic feats, and excel in fierce, frenzied single combat.
        return {
            gearList = {
                { item = "iron war axe" },
                { item = "ashfall_woodaxe" },
                { item = "T_Nor_Ringmail_Cuirass_01" },
                { item = "steel club" },
                { item = "p_restore_fatigue_s" },
                { item = "nordic_leather_shield" },
                { item = "p_jump_s", count= 2 },
                { item = "fur_pauldron_left" },
                { item = "fur_pauldron_right" },
                { item = "repair_prongs", count= 2 },
                { item = "0s_throwax_chit_01", count = 15 },
                { item = "bk_ABCs" },
            },
            spellList = {
                "aa_cl_barbar_power",
            },
        }
    end,

    ["Bard"] = function()
--Bards are loremasters and storytellers. They crave adventure for the wisdom and insight to be gained, and must depend on sword, shield, spell, and enchantment to preserve them from the perils of their educational experiences.
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "AB_App_Grinder" },
                { item = "iron saber" },
                { item = "T_Nor_Wood_Shield_01" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "aa_bk_songbook_bard", },
                { item = "misc_de_lute_01", },
                { item = "T_Rea_Wormmouth_BracerR_01" },
                { item = "T_Rea_Wormmouth_BracerL_01" },
            },
            spellList = {
                "aa_cl_bard_power",
                "aa_cl_bard_spell",
            },
        }
    end,
    ["Battlemage"] = function()
--Battlemages are wizard-warriors, trained in both lethal spellcasting and heavily armored combat. They sacrifice mobility and versatility for the ability to supplement melee and ranged attacks with elemental damage and summoned creatures.
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "iron_cuirass" },
                { item = "iron boots" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "AB_App_Grinder" },
                { item = "iron saber" },
            },
            spellList = {
                "shield",
                "bound battle-axe",
                "aa_cl_battle_spell",
                "absorb agility",
            },
        }
    end,

    ["Beastmaster"] = function()
--Beastmasters use their understanding of animals and creatures to their advantage, either calming or even commanding creatures. They prefer medium armor and are adept with clubs though they will wrestle animals often to tame them as well. They are incredibly fit and can run with a pack of Nix-Hounds.
        return {
            gearList = {
                { item = "chitin club" },
                { item = "T_Rea_Wormmouth_BracerR_01" },
                { item = "T_Rea_Wormmouth_BracerL_01" },
                { item = "p_restore_fatigue_s" },
                { item = "T_Nor_Wood_Shield_01" },
                { item = "p_jump_s" },
                { item = "AB_c_CommonHood01" },
                { item = "AB_App_Grinder" },
                { item = "ashfall_waterskin" },
                { item = "ashfall_woodaxe" },
            },
            spellList = {
                "aa_cl_beastm_power",
                "BM_summonwolf",
            },
        }
    end,

    ["Bookseller"] = function()
--Booksellers buy and sell books, and are sometimes involved in the printing process. They are also immersed in book lore and most are happy to share a little advice.
        return {
            gearList = {
                { item = "Gold_001", count = 60 },
                { item = "AB_Misc_PurseCoin" },
                { item = "aa_cl_speech_pot" },
                { item = "watcher's belt" },
                { item = "netch_leather_shield" },
                { item = "chitin club" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "T_Bk_PocketGuide1PC" },
                { item = "bk_OnMorrowind" },
                { item = "bk_specialfloraoftamriel" },
                { item = "bk_ShortHistoryMorrowind" },
            },
            spellList = {
                "detect enchantment",
                "almsivi intervention",
            },
        }
    end,

    ["Bounty Hunter"] = function()
--Bounty hunters apply their skills to tracking down and either capturing or killing criminals that escape justice at the hands of local law ement.
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "AB_w_WoodCrossbow" },
                { item = "T_Com_Wood_Bolt_01", count = arrowAmount },
                { item = "T_Nor_Ringmail_Cuirass_01" },
                { item = "lbonemold brace of horny fist" },
                { item = "rbonemold bracer of horny fist" },
                { item = "T_Nor_Wood_Shield_01" },
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

    ["Buoyant Armiger"] = function()
--Buoyant Armigers are members of a small military order of the Tribunal Temple, exclusively dedicated to and answering to Vivec. They pattern themselves on Vivec's heroic spirit of exploration and adventure, and emulate his mastery of the varied arts of personal combat, chivalric courtesy, and subtle verse. They serve the Tribunal Temple as champions and knights-errant, and are friendly rivals of the more solemn Ordinators.
        return {
            gearList = {
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowAmount },
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

    ["Caretaker"] = function()
-- Caretakers keep buildings clean and running smoothly. They care for a stock of supplies and keep an eye out for trouble.
        return {
            gearList = {
                { item = "WAR_BLACKSMITH_APRON01" },
                { item = "p_restore_fatigue_s" },
                { item = "pick_journeyman_01" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "p_chameleon_s" },
                { item = "mc_crafting_kit" },
            },
            spellList = {
                "recall",
                "stamina",
                "light",
            },
        }
    end,

    ["T_Mw_CatCatcher"] = function()
-- Cat-catchers are ruthless and cunning slave-hunters. They employ various means of negotiation to secure leads and rewards for their work, use agility and stealth to track their prey, and are skilled in non-lethal combat to overpower any resistance they face.
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
                { item = "chitin throwing star", count = arrowAmount },
            },
            spellList = {
                "aa_cl_catcatch_power",
                "aa_cl_bounty_power",
                "restore strength",
            },
        }
    end,

    ["Champion"] = function()
-- Champions have the duty of protecting the honor of their Ashlander tribe in peace and war. They give counsel to the ashkhan in tribal affairs, and represent the tribe to guests and intruders.
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "netch_leather_shield" },
                { item = "bonemold_bracer_left" },
                { item = "bonemold_bracer_right" },
                { item = "netch_leather_helm" },
                { item = "netch_leather_cuirass" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowAmount },
                { item = "p_restore_fatigue_s" },
            },
            spellList = {
                "aa_cl_champ_power",
                "variable resist magicka",
            },
        }
    end,

    ["T_Sky_Clever-Man"] = function()
--Clever-Men are practioners of the ancient Nordic magical tradition. They act as counsellors to Kings and Jarls in the affairs of magic and the forces of the otherworld. In olden times, they were widely respected and fought alongside the legendary kings and warriors of Skyrim's past. As mages, they are specialized in the various magic schools. In battle, they adorn heavy armor and supply their magical prowess with axe and shield when needed.
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "BM_Wool01_Robe" },
                { item = "T_Nor_Wood_Shield_01" },
                { item = "T_Com_Iron_PauldronR_01" },
                { item = "T_Com_Iron_PauldronL_01" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
            },
            spellList = {
                "frost barrier",
                "flameguard",
                "frostball",
                "bound battle-axe",
                "purge magic",
                "cruel noise",
            },
        }
    end,

    ["Clothier"] = function()
--Clothiers make clothes and sell them. They also buy clothes in good condition; with a little work they can make them good as new and resell them.
        return {
            gearList = {
                { item = "misc_shears_01" },
                { item = "misc_spool_0", count= 3 },
                { item = "misc_de_cloth10", count= 2 },
                { item = "misc_de_cloth11", count= 2 },
                { item = "mc_sewing_kit" },
                { item = "aa_cl_speech_pot", count= 2 },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
                { item = "watcher's belt" },
                { item = "chitin club" },
                { item = "cloth bracer left" },
                { item = "cloth bracer right" },
                { item = "Gold_001", count = goldAmount },
                { item = "expensive_pants_01_z" },
                { item = "expensive_robe_03" },
                { item = "common_robe_04" },
                { item = "common_shirt_05" },
            },
            spellList = {
            },
        }
    end,

    ["Commoner"] = function()
--Commoners do whatever needs doing -- cooking, cleaning, building, baking, making, breaking, and sharing a little local lore.
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
        }
    end,

    ["T_Sky_Courtesan"] = function()
--Courtesans were originally professional courtiers living in the royal courts of Daggerfall as confidants of rulers and nobles until that practice fell out of favour. Nowadays, a Courtesan is little more than a prostitute with a wealthy or noble clientele.
        return {
            gearList = {
                { item = "extravagant_amulet_01" },
                { item = "extravagant_skirt_02" },
                { item = "Gold_001", count = goldAmount},
                { item = "AB_Misc_PurseCoin" },
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
        }
    end,

    ["Crusader"] = function()
--Any heavily armored warrior with spellcasting powers and a good cause may call himself a crusader. Crusaders do well by doing good. They hunt monsters and villains, making themselves rich by plunder as they rid the world of evil.
        return {
            gearList = {
                { item = "iron mace" },
                { item = "iron saber" },
                { item = "iron_greaves" },
                { item = "iron boots" },
                { item = "T_Nor_Wood_Shield_01" },
                { item = "AB_App_Grinder" },
                { item = "p_restore_fatigue_s" },
                { item = "T_Rea_Wormmouth_BracerL_01" },
                { item = "hammer_repair" },
            },
            spellList = {
                "aa_cl_crusad_spell",
                "clench",
            },
        }
    end,

    ["Dervish"] = function()
        return {
            gearList = {
                { item = "iron saber" },
                { item = "p_jump_s" },
                { item = "mc_toxinflask" },
                { item = "AB_App_Grinder" },
                { item = "T_Com_Iron_ThrowingKnife_01", count = arrowAmount },
                { item = "p_restore_fatigue_s" },
                { item = "chitin spear" },
                { item = "ingred_coprinus_01" },
                { item = "ingred_russula_01" },
            },
            spellList = {
                "aa_cl_dervish_spell01",
                "aa_cl_dervish_spell02",
            },
        }
    end,

    ["Diresinger"] = function()
--The Diresinger is a bard that specialises in crippling and controlling his enemies. When he fights alone, he'll weaken his enemies with a songs and finish them with daggers or bows, though he will prefer to send companions or even minions. Like all bards, speechcraft and alchemy are part of his arsenal.
        return {
            gearList = {
                { item = "chitin shortsword" },
                { item = "AB_c_CommonHood01" },
                { item = "netch_leather_cuirass" },
                { item = "misc_de_lute_01" },
                { item = "p_restore_fatigue_s" },
                { item = "aa_bk_songbook_dire" },
                { item = "AB_App_Grinder" },
                { item = "chitin throwing star", count = arrowAmount },
                { item = "T_Rea_Wormmouth_BracerR_01" },
                { item = "T_Rea_Wormmouth_BracerL_01" },
            },
            spellList = {
                "summon scamp",
                "aa_cl_bard_power",
                "aa_cl_dire_spell",
            },
        }
    end,

    ["T_Cyr_Dockworker"] = function()
--A Dock Worker is a waterfront unskilled laborer who load and unload vessels in port. Rarely, a larger military vessel will carry its own contingent of trusted Dock Workers.
        return {
            gearList = {
                { item = "p_feather_c", count= 3 },
                { item = "p_restore_fatigue_s" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "chitin club" },
                { item = "belt of orc's strength" },
                { item = "AB_a_WickerHelm" },
                { item = "p_jump_s" },
                { item = "ashfall_waterskin" },
            },
            spellList = {
                "aa_cl_dock_power",
            },
        }
    end,

    ["Dreamers"] = function()
--Dreamers are newly come to Dagoth Ur, and have not yet been infused with his power, although they are already deep in the heart of his mysteries. Eventually, Dreamers will progress towards transformation into an Ash creature.
        return {
            gearList = {
                { item = "chitin throwing star", count = arrowAmount },
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

    ["Drillmaster"] = function()
--Drillmasters train and condition the local militia, teaching the citziens the basics of block, spear, and long blade with a special consideration of athletics and acrobatics.
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
        }
    end,

    ["Druid"] = function()
--Druids have a great understanding of plants and creatures: they can make potent brews and calm animals. While they do use weapons and armor, they ignore anything made of metal, prefering natural material such a wood, leather or chitin. Druids can also wield mystical energies.
        return {
            gearList = {
                { item = "wooden staff of peace" },
                { item = "AB_w_ToolHandscythe00" },
                { item = "AB_App_Grinder" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "netch_leather_cuirass" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "common_hood_01" },
                { item = "jjs_plant_firefern" },
                { item = "jjs_plant_wickwheat" },
                { item = "ashfall_waterskin" },
                { item = "ashfall_woodaxe" },
            },
            spellList = {
                "sanctuary",
                "calm creature",
                "shield",
                "aa_cl_garden_spell",
                "spell absorption",
            },
        }
    end,

    ["Duelist"] = function()
--Duelists are combatants who in fight rely on finesse, perfect form and quickness over brute force. Uncommon among fighters, the duelists do not wear any armor at all preferring maximum speed and not being hit at all. Duelists are known to possess a silver tongue and are exceptionally nimble and quick.
        return {
            gearList = {
                { item = "ChK_rap_iron" },
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

    ["Enchanter"] = function()
--Enchanters trade with enchanted items, weapons, armor, and clothes. They also enchant items such as scrolls and sell them, or offer their lab for others to use - against a fee, of course.
        return {
            gearList = {
                { item = "sx2_quillSword" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "Misc_SoulGem_Lesser" },
                { item = "Misc_SoulGem_Common" },
                { item = "Misc_SoulGem_Greater" },
                { item = "wooden staff" },
                { item = "AB_App_Grinder" },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
                { item = "AB_sc_Blank", count= 3 },
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
        }
    end,

    ["Enforcer"] = function()
--Enforcers serve crimebosses as thugs. Their boss makes the rules and they enforce them by physical or magical force.
        return {
            gearList = {
                { item = "chitin shortsword" },
                { item = "netch_leather_helm" },
                { item = "netch_leather_cuirass" },
                { item = "chitin throwing star", count = arrowAmount },
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

    ["Farmer"] = function()
--Farmers grow crops, and raise animals for food, and gather animal products and vegetable products from the land for their own use or for sale at the markets.
        return {
            gearList = {
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "AB_a_WickerHelm" },
                { item = "p_restore_fatigue_s" },
                { item = "T_Com_Farm_Pitchfork_01" },
                { item = "T_Com_Farm_Shovel_01" },
                { item = "ingred_ash_yam_01", count = 3 },
                { item = "ashfall_waterskin" },
            },
            spellList = {
                "aa_cl_garden_spell",
            },
        }
    end,

    ["T_Mw_Fisherman"] = function()
--Fishermen work on boats to catch fishes on oceans, rivers, and causeways with lines, nets, or spears. Some also work as salt-makers, sailors, or collect and sell reed.
        return {
            gearList = {
                { item = "T_Rga_FishingSpear_01" },
                { item = "AB_w_ToolFishingNet" },
                { item = "misc_de_fishing_pole" },
                { item = "ashfall_crabpot_01_m" }, 
                { item = "NOM_food_fish", count= 2 },
                { item = "ingred_crab_meat_01", count= 4 },
                { item = "NOM_food_fish_fat_02", count= 2 },
                { item = "p_restore_fatigue_s" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "AB_a_WickerHelm" },
                { item = "netch_leather_shield" },
                { item = "ashfall_waterskin" },
            },
            spellList = {
            },
        }
    end,

    ["Gambler"] = function()
--Gamblers primarily rely on luck. They will take leaps of faith, confident that the stars will guide them to safety. Gamblers wear no armor, betting on speed or their opponent's clumsiness. The Gambler is quite charming in their candor that things will turn out all right, with just a bit of luck.
        return {
            gearList = {
                { item = "aa_coin41" },
                { item = "T_Com_Dice_01" },
                { item = "T_De_CardHortEmpty" },
                { item = "T_Com_Iron_ThrowingKnife_01", count = arrowAmount },
                { item = "watcher's belt" },
                { item = "aa_cl_speech_pot" },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "chitin shortsword" },
            },
            spellList = {
                "aa_cl_gambl_power",
                "absorb luck",
                "aa_cl_gambl_spell",
            },
        }
    end,

    ["Gardener"] = function()
--Gardeners tend the plants and trees, and keep them looking pretty. They are often employed by nobility or the temple to keep their parks and gardens watered when it's dry and dusty.
        return {
            gearList = {
                { item = "jjs_plant_timsa" },
                { item = "jjs_plant_gldkan" },
                { item = "jjs_plant_gldkan" },
                { item = "jjs_plant_gldkan" },
                { item = "T_Com_Farm_Hoe_01" },
                { item = "T_Com_Farm_Trovel_01" },
                { item = "AB_App_Grinder" },
                { item = "watcher's belt" },
                { item = "Gold_001", count = 20 },
                { item = "AB_Misc_PurseCoin" },
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
        }
    end,

    ["Gladiator"] = function()
--Gladiators fight in arenas across Tamriel for the entertainment of others. In Morrowind, slaves are sometimes trained as gladiators, but others fight for fame and fortune.
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "chitin spear" },
                { item = "netch_leather_shield" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "p_restore_fatigue_s" },
                { item = "iron saber" },
                { item = "T_Rea_Wormmouth_PauldronL_01" },
                { item = "T_Rea_Wormmouth_PauldronR_01" },
                { item = "p_jump_s" },
            },
            spellList = {
                "aa_cl_barbar_power",
            },
        }
    end,

    ["Guard"] = function()
--Guards keep the peace, collect fines and compensation, and chase down criminals to drag them off to prison. Each local authority employs its own guards, and there is always work for them.
        return {
            gearList = {
                { item = "iron saber" },
                { item = "T_Com_Wood_Mace_01" },
                { item = "T_Nor_Wood_Shield_01" },
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

    ["Healer"] = function()
--Healers are spellcasters who swear solemn oaths to heal the afflicted and cure the diseased. When threatened, they defend themselves with reason and disabling attacks and magic, relying on deadly force only in extremity.
        return {
            gearList = {
                { item = "AB_alc_HealBandage01", count = 2 },
                { item = "AB_c_CommonHood05b"},
                { item = "AB_App_Grinder" },
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

    ["Herder"] = function()
--Herders watch over their herds of guars, shalk, or netches. They are responsible for defending them against predators, bandits, and illnesses. They also butcher them and preparing the meat, skin, and other ingredients for use by craftsmen, cooks, or alchemists.
        return {
            gearList = {
                { item = "mer_tgw_flute" },
                { item = "mc_organic_kit" },
                { item = "AB_dri_GuarMilk", count= 2 },
                { item = "AB_a_WickerHelm" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowAmount },
                { item = "AB_w_ToolPitchfork" },
                { item = "p_restore_fatigue_s" },
                { item = "chitin war axe" },
                { item = "T_Rea_Wormmouth_BracerR_01" },
                { item = "T_Rea_Wormmouth_BracerL_01" },
                { item = "ingred_guar_hide_01", count= 2 },
                { item = "ashfall_woodaxe" },
                { item = "ashfall_waterskin" },
                { item = "aa_thw_net", count = 3 },
            },
            spellList = {
                "aa_cl_garden_spell",
            },
        }
    end,

    ["Hermit"] = function()
--Whether for religious reasons or merely personal preference, hermits choose to live solitary lives. It takes someone of versatile skill and knowledge to be entirely self-sufficient. Hermits develop advanced expertise of local flora and fauna.
        return {
            gearList = {
                { item = "mc_organic_kit" }, --75
                { item = "AB_App_Grinder" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowAmount },
                { item = "hammer_repair", count = 2 },
                { item = "p_chameleon_s" },
                { item = "AB_c_CommonHood01" },
                { item = "wooden staff" },
                { item = "misc_com_iron_ladle" },
                { item = "NOM_food_cabbage", count = 2 },
                { item = "common_robe_01"},
                { item = "ashfall_woodaxe" },
                { item = "ashfall_grill" },
                { item = "ashfall_kettle_06" },
                { item = "ashfall_waterskin" },
                { item = "ashfall_strawBed" },
                { item = "ashfall_firewood", count = 4 },
            },
            spellList = {
                "fire shield",
                "hearth heal",
                "five fingers of pain",
            },
        }
    end,

    ["Hood"] = function()
--Hoods are the common clay of the criminal underworld. Thugs and gangsters, hoods favor fighting in close quarters using daggers, short clubs, and fists.
        return {
            gearList = {
                { item = "lbonemold brace of horny fist" },
                { item = "rbonemold bracer of horny fist" },
                { item = "chitin shortsword" },
                { item = "T_Com_Wood_Mace_01" },
                { item = "T_Rea_Wormmouth_Helm_01" },
                { item = "p_chameleon_s" },
                { item = "chitin war axe" },
                { item = "T_Nor_Wood_Shield_01" },
                { item = "p_restore_fatigue_s" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
            },
            spellList = {
            },
        }
    end,

    ["Hunter"] = function()
--Hunters range across the lands, hunting for meat and hides. They know the native creatures, and know how to best avoid the diseased creatures.
        return {
            gearList = {
                { item = "mc_organic_kit" }, --75
                { item = "ashfall_woodaxe" },
                { item = "ashfall_waterskin" },
                { item = "mer_fletch_kit" },
                { item = "T_Rea_Wormmouth_Helm_01" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowAmount },
                { item = "chitin shortsword" },
                { item = "p_chameleon_s" },
                { item = "p_restore_fatigue_s" },
                { item = "aa_thw_net", count = 3 },
            },
            spellList = {
                "stamina",
            },
        }
    end,

    ["T_Sky_Jarl"] = function()
-- Jarls are the second highest ranking title in the hierarchy of Nordic kingdoms, answering only to their King. The Jarl acts as a vassal to the King, but essentially rules a Jarldom of his or her own. Most Jarl titles are heriditary, and as with most Nord nobility, future Jarls are trained from young age in the skills of combat, war and diplomacy.
        return {
            gearList = {
                { item = "nordic broadsword" },
                { item = "nordic_ringmail_cuirass" },
                { item = "nordic_iron_helm" },
                { item = "BM bear shield"},
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

    ["Jester"] = function()
--The Jester is often underestimated. Jester are physical entertainers, performing feats of skill and wits at court. It is a frequent mistake to conflate a jester’s intelligence with that of the bumbling character they often play. The Jester relies on tricks and deception and is the most proficient spellcaster of all the bards.
        return {
            gearList = {
                { item = "jokesofdaggerfall" },
                { item = "p_chameleon_s" },
                { item = "p_jump_s" },
                { item = "potion_t_bug_musk_01" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "aa_bk_songbook_bard" },
                { item = "AB_App_Grinder" },
                { item = "bk_yellowbookofriddles" },
            },
            spellList = {
                "five fingers of pain",
                "crying eye",
                "aa_cl_bank_power",
                "stamina",
            },
        }
    end,

    ["Journalist"] = function()
--Journalists gather the news and print them. 
        return {
            gearList = {
                { item = "sc_paper plain", count= 3 },
                { item = "Misc_Inkwell" },
                { item = "Misc_Quill" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "AB_sc_Blank" },
                { item = "watcher's belt" },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
                { item = "aa_cl_speech_pot" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "AB_App_Grinder" },
            },
            spellList = {
                "mark",
                "mother's kiss",
            },
        }
    end,

    ["Juggler"] = function()
--Jugglers use the magic arts to entertain and amaze, causing fireballs and knives to dance through the air in feats of artistic and technical skill that defy the laws of nature.
        return {
            gearList = {
                { item = "food_kwama_egg_01", count= 5 },
                { item = "T_Com_Iron_ThrowingKnife_01", count = arrowAmount },
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
        }
    end,

    ["King"] = function()
--Kings are at the top of the local nobility. Only the emperor himself is above them, and it is him who they report to.
        return {
            gearList = {
                { item = "potion_t_bug_musk_01" },
                { item = "silver longsword" },
                { item = "silver_cuirass" },
                { item = "exquisite_pants_01" },
                { item = "Gold_001", count = goldAmount },
                { item = "Gold_001", count = goldAmount },
                { item = "exquisite_shirt_01" },
                { item = "exquisite_shoes_01" },
            },
            spellList = {
                "aa_cl_king_power",
            },
        }
    end,

    ["Knight"] = function()
--Of noble birth, or distinguished in battle or tourney, knights are civilized warriors, schooled in letters and courtesy, governed by the codes of chivalry. In addition to the arts of war, knights study the lore of healing and enchantment.
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "hammer_repair", count = 2 },
                { item = "AB_Misc_PurseCoin" },
                { item = "T_Imp_Chain_Boots_01" },
                { item = "steel_shield" },
                { item = "steel longsword" },
                { item = "steel_cuirass" },
            },
            spellList = {
                "fortify block skill",
            },
        }
    end,

    ["Mabrigash"] = function()
--A Mabrigash is an outcast Ashlander witch-warrior, women who defy the Ashlanders' rules of behavior for women, mastering weapons of war and powerful sorcery.
        return {
            gearList = {
                { item = "ashfall_kettle_04" },
                { item = "ashfall_woodaxe" },
                { item = "chitin war axe" },
                { item = "netch_leather_shield" },
                { item = "watcher's belt" },
                { item = "aa_cl_speech_pot" },
                { item = "p_restore_fatigue_s" },
                { item = "WAR_MLSND_BOOT_01" },
                { item = "expensive_robe_01"},
            },
            spellList = {
                "aa_cl_mabrig_spell",
                "turn of the wheel",
                "absorb health",
                "burden",
            },
        }
    end,

    ["Mage"] = function()
--Most mages claim to study magic for its intellectual rewards, but they also often profit from its practical applications. Varying widely in temperament and motivation, mages share but one thing in common: an avid love of spellcasting.
        return {
            gearList = {
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "AB_App_Grinder" },
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
        }
    end,

    ["Marauder"] = function()
--Marauders are powerful warriors, favoring massive two-handed weapons. Marauders subscribe to the philosophy that a good offense is the best defense, forgoing shields and relying only on their armor to protect them.
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "T_Com_Wood_Mace_01" },
                { item = "T_Rea_Wormmouth_PauldronL_01" },
                { item = "T_Rea_Wormmouth_PauldronR_01" },
                { item = "T_Com_Iron_Cuirass_01" },
                { item = "iron saber" },
                { item = "chitin spear" },
                { item = "lbonemold brace of horny fist" },
                { item = "rbonemold bracer of horny fist" },
                { item = "hammer_repair", count = 2 },
                { item = "aa_cl_ench_ring" },
            },
            spellList = {
            },
        }
    end,

    ["Master-at-Arms"] = function()
--Masters-at-Arms are dedicated weapon trainers, having mastered all the basic hand weapon types: long blades, short blades, axes, blunt weapons, and spears.
        return {
            gearList = {
                { item = "chitin spear" },
                { item = "chitin shortsword" },
                { item = "iron saber" },
                { item = "chitin war axe" },
                { item = "T_Com_Wood_Mace_01" },
                { item = "netch_leather_shield" },
                { item = "netch_leather_cuirass" },
                { item = "T_Rea_Wormmouth_Helm_01" },
                { item = "T_Com_Iron_PauldronR_01" },
                { item = "T_Com_Iron_PauldronL_01" },
            },
            spellList = {
            },
        }
    end,

    ["Mercenary"] = function()
--Mercenaries are rugged fighters who employ their reputable martial prowess in service of whoever pays them the most. Mercenaries are strong and physically conditioned.
        return {
            gearList = {
                { item = "T_Com_Iron_Cuirass_01" },
                { item = "T_Com_Iron_PauldronR_01" },
                { item = "T_Com_Iron_PauldronL_01" },
                { item = "chitin war axe" },
                { item = "iron saber" },
                { item = "AB_Misc_PurseCoin" },
                { item = "p_restore_fatigue_s" },
                { item = "hammer_repair", count = 2 },
                { item = "T_Com_Wood_Mace_01" },
                { item = "AB_w_WoodCrossbow" },
                { item = "T_Com_Wood_Bolt_01", count = arrowAmount },
                { item = "iron_shield" },
            },
            spellList = {
            },
        }
    end,

    ["Merchant"] = function()
--Merchants look for goods that are well-made, and can be sold at a profit. There are many different kinds of materials a merchant can buy and sell -- animal products, vegetable products, mineral products, even exotic products. Crafts and manufactured goods they deal in include weapons, armor, clothing, books, potions, enchanted items, and various housewares.
        return {
            gearList = {
                { item = "Gold_001", count = goldAmount },
                { item = "Gold_001", count = goldAmount },
                { item = "potion_t_bug_musk_01" },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
                { item = "hammer_repair", count = 2 },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "T_Rea_Wormmouth_BracerR_01" },
                { item = "T_Rea_Wormmouth_BracerL_01" },
                { item = "watcher's belt" },
                { item = "AB_c_CommonHood01" },
                { item = "T_Imp_Cm_BootsCol_01" },
                { item = "T_Com_Wood_Mace_01" },
                { item = "iron saber" },
            },
            spellList = {
                "charisma",
                "aa_cl_pawn_power",
            },
        }
    end,

    ["Miner"] = function()
--In Morrowind, being a miner usually means being a Kwama miner. Kwama miners extrace Kwama eggs from egg mines, feeding the population.
        return {
            gearList = {
                { item = "netch_leather_shield" },
                { item = "T_Com_Wood_Mace_01" },
                { item = "miner's pick" },
                { item = "AB_a_WickerHelm" },
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
        }
    end,

    ["Monk"] = function()
--Monks are students of the ancient martial arts of hand-to-hand combat and unarmored self-defense. Monks avoid detection by stealth, mobility, and agility, and are skilled with a variety of ranged and close-combat weapons.
        return {
            gearList = {
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "_WS_right_tonfa" },
                { item = "watcher's belt" },
                { item = "p_restore_fatigue_s" },
                { item = "p_jump_s" },
                { item = "p_chameleon_s" },
                { item = "netch_leather_shield" },
                { item = "chitin throwing star", count = arrowAmount },
                { item = "AB_a_WickerHelm" },
            },
            spellList = {
                "fortify hand to hand skill",
            },
        }
    end,

    ["Necromancer"] = function()
--Necromancers are mages who summon the spirits of the dead or raise them bodily. In the Empire, necromancy is a legitimate discipline, though body and spirit are protected property, and may not be used without permission of the owner. In Morrowind, the Dunmer loathe philosophical necromancers, and put them to death. However, using sacred necromancy, the Dunmer summon their own dead to guard tombs and defend the family.
        return {
            gearList = {
                { item = "aa_necro_night_scroll" },
                { item = "T_Com_Embalming_Hook_01" },
                { item = "liche_robe1_c" },
                { item = "nc_SoulGem_blackened" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
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
        }
    end,

    ["Nightblade"] = function()
--Nightblades are spellcasters who use their magics to enhance mobility, concealment, and stealthy close combat. They have a sinister reputation, since many nightblades are thieves, enforcers, assassins, or covert agents.
        return {
            gearList = {
                { item = "p_chameleon_s" },
                { item = "chitin shortsword" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowAmount },
                { item = "AB_c_CommonHood01" },
                { item = "T_Imp_Cm_BootsCol_01" },
            },
            spellList = {
                "righteousness",
                "invisibility",
                "feather",
                "five fingers of pain",
            },
        }
    end,

    ["Ninja"] = function()
--Ninjas have trained very hard to become the ultimate assassin; they can sneak into the enemy's base and retrieve documents or kill the leader. They favor throwing items and may use secret techniques akin to magic.
        return {
            gearList = {
                { item = "left gauntlet of the horny fist" },
                { item = "_WS_right_tonfa" },
                { item = "right gauntlet of horny fist" },
                { item = "chitin throwing star", count = arrowAmount },
                { item = "p_chameleon_s" },
                { item = "p_jump_s" },
                { item = "AB_c_CommonHood01" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "p_restore_fatigue_s" },
                { item = "netch_leather_pauldron_right" },
                { item = "netch_leather_pauldron_left" },
            },
            spellList = {
                "sanctuary",
                "recall",
            },
        }
    end,

    ["Noble"] = function()
--Nobles are elevated by birth and distinction to the highest ranks of Imperial society. They do not a have trades per se, but dabble in various affairs, collecting rare treasures of beauty and refinement. In return, they serve at the command of the Emperor and the Councils, giving counsel and support, and, when duty calls, taking spell and sword to protect the smallfolk of the Empire.
        return {
            gearList = {
                { item = "Gold_001", count = goldAmount },
                { item = "Gold_001", count = goldAmount },
                { item = "Gold_001", count = 50 },
                { item = "extravagant_robe_01" },
                { item = "extravagant_shoes_01" },
                { item = "potion_t_bug_musk_01" },
                { item = "firebite dagger" },
                { item = "AB_c_ExtravagantHood01" },
                { item = "netch_leather_shield" },
                { item = "AB_Misc_PurseCoin" },
            },
            spellList = {
                "aa_cl_noble_ability",
                "turn of the wheel",
            },
        }
    end,

    ["Ordinator"] = function()
--Ordinators are the priest-soldiers of the Tribunal Temple. They have the duty of keeping worshippers from restoring the old Daedric sites scattered throughout the wastelands and along the rocky coasts and islands of Morrowind. They also fight witchcraft, necromancy, and vampirism.
        return {
            gearList = {
                { item = "T_Com_Wood_Mace_01" },
                { item = "iron saber" },
                { item = "T_Com_Iron_PauldronR_01" },
                { item = "T_Com_Iron_PauldronL_01" },
                { item = "T_Imp_Chain_GauntletL_01t" },
                { item = "T_Imp_Chain_GauntletR_02" },
                { item = "iron_shield" },
                { item = "AB_App_Grinder" },
                { item = "p_jump_s" },
                { item = "T_Rea_Wormmouth_Helm_01" },
                { item = "T_Bk_SermonOfTheSaintsTR" },
            },
            spellList = {
                "five fingers of pain",
                "cure common disease",
            },
        }
    end,

    ["T_Mw_OreMiner"] = function()
--Ore miners extract rare minerals, such as glass, diamonds or ebony from the earth.
        return {
            gearList = {
                { item = "miner's pick" },
                { item = "T_IngMine_OreIron_01" },
                { item = "T_IngMine_Coal_01" },
                { item = "hammer_repair", count = 2 },
                { item = "T_Com_Wood_Mace_01" },
                { item = "iron_bracer_left" },
                { item = "iron_bracer_right" },
                { item = "iron_shield" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "iron saber" },
            },
            spellList = {
                "aa_cl_dock_power",
            },
        }
    end,

    ["Paladin"] = function()
--Paladins are knights in service to the Aedra or good Daedra. In return they benefit from more magical capability than secular knights.

        return {
            gearList = {
                { item = "iron saber" },
                { item = "iron_shield" },
                { item = "iron_greaves" },
                { item = "iron boots" },
                { item = "T_Com_Iron_Cuirass_01" },
                { item = "aa_cl_speech_pot" },
                { item = "chitin spear" },
                { item = "hammer_repair", count = 2 },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "AB_App_Grinder" },
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

    ["Pauper"] = function()
--Pauper are the humblest smallfolk. They make their way in the world as best they can, providing unskilled labor in the fields, kitchens, and factories of lords and merchants.
        return {
            gearList = {
                { item = "p_restore_fatigue_s" },
                { item = "T_Com_Var_BottleWeapon_01" },
                { item = "nordic_leather_shield" },
                { item = "p_chameleon_s" },
                { item = "AB_Misc_PurseCoin" },
                { item = "T_Com_Wood_Mace_01" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
            },
            spellList = {
                "aa_cl_pauper_power",
            },
        }
    end,

    ["Pawnbroker"] = function()
--Pawnbrokers offer secured loans by using goods as collateral. They also sell pawned things, sometimes used and worn, sometimes almost new, and all for a fraction of what they'd cost if purchased elsewhere.
        return {
            gearList = {
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
                { item = "p_restore_fatigue_s" },
                { item = "aa_cl_speech_pot" },
                { item = "watcher's belt" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "netch_leather_shield" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "T_Com_Wood_Mace_01" },
                { item = "misc_de_bowl_bugdesign_01" },
                { item = "misc_de_bowl_glass_peach_01" },
                { item = "misc_com_redware_platter" },
            },
            spellList = {
                "aa_cl_pawn_power",
            },
        }
    end,

    ["Pearl Diver"] = function()
--Pear Divers make a living finding pearl in the waters of Morrowind
        return {
            gearList = {
                { item = "ashfall_crabpot_01_m" },
                { item = "_MM_pearl_blue" },
                { item = "ingred_pearl_01" },
                { item = "chitin shortsword" },
                { item = "T_Rga_FishingSpear_01" },
                { item = "p_restore_fatigue_s" },
                { item = "AB_App_Grinder" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
            },
            spellList = {
                "vigor",
                "aa_cl_pearl",
            },
        }
    end,

    ["Pilgrim"] = function()
--Pilgrims are travelers, seekers of truth and enlightenment. They fortify themselves for road and wilderness with arms, armor, and magic, and through wide experience of the world, they become shrewd in commerce and persuasion.
        return {
            gearList = {
                { item = "ashfall_waterskin" },
                { item = "WAR_MLSND_BOOT_01" },
                { item = "aa_cl_speech_pot" },
                { item = "AB_Misc_PurseCoin" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowAmount },
                { item = "T_Rea_Wormmouth_PauldronL_01" },
                { item = "T_Rea_Wormmouth_PauldronR_01" },
                { item = "AB_App_Grinder" },
                { item = "T_Nor_Wood_Shield_01" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "chitin shortsword" },
                { item = "ashfall_woodaxe" },
            },
            spellList = {
                "veloth's grace",
                "light",
            },
        }
    end,

    ["Pirate"] = function()
--Pirates roam the seas plundering coastal towns and good-laden ships. They are skilled with both ranged and melee weapons. Even when stuck without a ship, a pirate still embodies their defining trait, a love of freedom.
        return {
            gearList = {
                { item = "Gold_001", count = goldAmount },
                { item = "ingred_emerald_01" },
                { item = "TM_treasure_map" },
                { item = "iron saber" },
                { item = "netch_leather_shield" },
                { item = "T_Com_Iron_ThrowingKnife_01", count = arrowAmount },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
                { item = "chitin shortsword" },
                { item = "chitin war axe" },
                { item = "T_Rea_Wormmouth_BracerR_01" },
                { item = "T_Rea_Wormmouth_BracerL_01" },
                { item = "p_chameleon_s" },
            },
            spellList = {
                "chameleon",
                "aa_cl_pirate_power",
            },
        }
    end,

    ["Poacher"] = function()
--Poachers are hunters for whom the advantages of hunting on private or protected lands outweigh the risks of being caught. Poachers make use of illusion magic to avoid detection and help them talk their way out of problems, and wear medium armor as a compromise between speed and extra protection.
        return {
            gearList = {
                { item = "chitin spear" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowAmount },
                { item = "T_Rea_Wormmouth_BracerR_01" },
                { item = "T_Rea_Wormmouth_BracerL_01" },
                { item = "p_chameleon_s" },
                { item = "p_restore_fatigue_s" },
                { item = "p_jump_s" },
                { item = "AB_App_Grinder" },
                { item = "AB_Misc_PurseCoin" },
                { item = "aa_cl_speech_pot" },
                { item = "ingred_hound_meat_01", count = 4 },
                { item = "aa_thw_net", count = 3 },
            },
            spellList = {
                "chameleon",
            },
        }
    end,

    ["Poet"] = function()
--Poets are people who sing tales about great battles and write them in books so that they can be memorised for generations. Their silver tongues cannot be matched.
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "chitin shortsword" },
                { item = "watcher's belt" },
                { item = "misc_de_lute_01", },
                { item = "aa_bk_songbook_bard", },
                { item = "ashfall_waterskin" },
                { item = "AB_App_Grinder" },
                { item = "p_restore_fatigue_s" },
                { item = "iron saber" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "sc_paper plain", count= 3 },
                { item = "Misc_Inkwell" },
                { item = "Misc_Quill" },
            },
            spellList = {
                "shock barrier",
            },
        }
    end,

    ["Priest"] = function()
--Priests act as intercessors between the gods and their worshippers. As caretakers of the temples and shrines, and councilor and educator for the faithful and laymen, they hold onto the myths and lore of old.
        return {
            gearList = {
                { item = "wooden staff" },
                { item = "common_robe_05_a"},
                { item = "watcher's belt" },
                { item = "aa_cl_speech_pot" },
                { item = "AB_c_CommonHood05a" },
                { item = "AB_App_Grinder" },
            },
            spellList = {
                "cure common disease other",
                "restore attributes",
                "levitate",
                "turn undead",
                "soul trap",
                "spirit knife",
            },
        }
    end,

    ["Publican"] = function()
--Publicans maintain inns and pubs. They offer food and drinks to buy, and beds for lodgers. They know the neighborhood, and can share local lore and small rumors.
        return {
            gearList = {
                { item = "dhb_mug_coffee" },
                { item = "LFL_BR_Vvardenfell" },
                { item = "NOM_food_crab_slice" },
                { item = "T_IngFood_Cookie_01" },
                { item = "T_De_Drink_LiquorLlotham_01" },
                { item = "Gold_001", count = goldAmount },
                { item = "ingred_bread_01" },
                { item = "Potion_Local_Brew_01" },
                { item = "aa_cl_speech_pot" },
                { item = "AB_Misc_PurseCoin" },
                { item = "left gauntlet of the horny fist" },
                { item = "T_Rea_Wormmouth_BracerR_01" },
                { item = "probe_journeyman_01" },
                { item = "netch_leather_shield" },
                { item = "T_Com_Wood_Mace_01" },
                { item = "chitin spear" },
            },
            spellList = {
                "aa_cl_pawn_power",
            },
        }
    end,

    ["Pugilist"] = function()
--Pugilists are dedicated fistfighters and paragons of physical fitness. They prefer to fight unencumbered by armor. If they run into a dangerous situation, rather than turning to weapons pugilists will use magic to even the odds, silencing mages or blinding warriors.
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

    ["Pyromancer"] = function()
--Pyromancers excel at Destruction and favour fire spells above all others. They often wield staves and are competent in other schools of magic. They prefer treated leather armour to resist the flames but may forego armor altogether.
        return {
            gearList = {
                { item = "ingred_fire_salts_01" },
                { item = "netch_leather_cuirass" },
                { item = "wooden staff" },
                { item = "AB_App_Grinder" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
            },
            spellList = {
                "fire shield",
                "fireball",
                "noise",
                "mother's kiss",
                "resist fire",
                "aa_cl_pyro_power",
            },
        }
    end,

    ["Queen"] = function()
--Queens are at the top of the local nobility. Only the emperor himself is above them, and it is him who they report to.

        return {
            gearList = {
                { item = "potion_t_bug_musk_01" },
                { item = "silver longsword" },
                { item = "silver_cuirass" },
                { item = "Gold_001", count = goldAmount },
                { item = "Gold_001", count = goldAmount },
                { item = "exquisite_shirt_01" },
                { item = "exquisite_shirt_01" },
                { item = "exquisite_shoes_01" },
            },
            spellList = {
                "aa_cl_king_power",
            },
        }
    end,

    ["Ranger"] = function()
--Rangers are skilled and knowledgeable fighters who have the skills necessary to be at home in the wilderness for long stretches at a time. Rangers are expert trackers and can help guide others through difficult terrain.
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
                { item = "corkbulb arrow", count = arrowAmount },
                { item = "AB_App_Grinder" },
                { item = "p_chameleon_s" },
                { item = "p_jump_s" },
                { item = "p_restore_fatigue_s" },
            },
            spellList = {
                "aa_cl_ranger_spell",
                "chameleon",
            },
        }
    end,

    ["Rogue"] = function()
--Rogues are adventurers and opportunists with a gift for getting into and out of trouble. Relying variously on charm and dash, blades and business sense, they thrive on conflict and misfortune, trusting to their luck and cunning to survive.
        return {
            gearList = {
                { item = "common_hood_01" },
                { item = "chitin shortsword" },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
                { item = "chitin war axe" },
                { item = "left gauntlet of the horny fist" },
                { item = "right gauntlet of horny fist" },
                { item = "T_Nor_Wood_Shield_01" },
                { item = "iron saber" },
                { item = "p_restore_fatigue_s" },
                { item = "aa_cl_speech_pot" },
            },
            spellList = {
                "aa_cl_rogue_power",
            },
        }
    end,

    ["Sage"] = function()
--Sages are among the most intelligent people on Tamriel, who even other mages go to for advice or instruction. Sages are masters of Alchemy, Conjuration, Enchanting, Illusion, and Speechcraft.
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "AB_App_Grinder" },
                { item = "wooden staff" },
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
                { item = "common_robe_05"},
            },
            spellList = {
                "light",
                "bound dagger",
                "spell absorption",
                "restore intelligence",
            },
        }
    end,

    ["T_Mw_Sailor"] = function()
--Enlisted seafarers, Sailors are skilled in operating and maintaining naval vessels, as well as navigation and the occasional joust. When wor on a military vessel, a group of Sailors are often under the command of Noble officers.
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
                { item = "AB_Misc_PurseCoin" },
                { item = "aa_cl_speech_pot" },
                { item = "chitin shortsword" },
            },
            spellList = {
                "aa_cl_sailor_spell",
            },
        }
    end,

    ["Sand-runner"] = function()
--Sand-runners excel at running long distances even under the harsh conditions of the desert. They prefer to outrun their enemes, or take them out at a distance. While not spellcaster by profession, they have an affinity with fire and are adept at healing themselves.        return {
            gearList = {
                { item = "chitin shortsword" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowAmount },
                { item = "AB_a_LeatherHatd" },
                { item = "netch_leather_boots" },
                { item = "flameguard robe" },
                { item = "p_restore_fatigue_s" },
                { item = "AB_Misc_PurseCoin" },
                { item = "flamebolt ring" },
            },
            spellList = {
                "resist fire ",
                "mother's kiss ",
                "fire barrier ",
                "invisibility ",
                "feather",
            },
        }
    end,

    ["Savant"] = function()
--Savants are people of wide learning and cosmopolitan tastes, well-traveled, educated, refined in manner, able to converse on various topics with authority, and ever ready to defend their honor, and the honor of their companions.
        return {
            gearList = {
                { item = "sc_paper plain", count= 3 },
                { item = "Misc_Inkwell" },
                { item = "Misc_Quill" },
                { item = "aa_cl_speech_pot" },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
                { item = "AB_App_Grinder" },
                { item = "watcher's belt" },
                { item = "probe_journeyman_01" },
                { item = "netch_leather_shield" },
                { item = "bk_great_houses", },
                { item = "bk_guide_to_vvardenfell" },
                { item = "T_Bk_HistoryOfDaggerfallTR" },
                { item = "sc_daydenespanacea", },
                { item = "sc_galmsesseal" },
                { item = "sc_firstbarrier" },
            },
            spellList = {
            },
        }
    end,

    ["Scavenger"] = function()
--Scavengers are people who find items that look like junk but turns out that they are valuable treasures. Usually, they can even sell junk for a higher price, and their stealth and mobility makes them excellent for raiding caverns and bandit lairs.
        return {
            gearList = {
                { item = "aa_fact_bag01_light" },
                { item = "ingred_scrap_metal_01" },
                { item = "hammer_repair", count = 2 },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
                { item = "chitin war axe" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "T_Rea_Wormmouth_BracerR_01" },
                { item = "T_Rea_Wormmouth_BracerL_01" },
                { item = "iron_greaves" },
                { item = "iron boots" },
                { item = "netch_leather_pauldron_right" },
                { item = "netch_leather_pauldron_left" },
                { item = "p_chameleon_s" },
            },
            spellList = {
                "mark",
            },
        }
    end,

    ["Scout"] = function()
--Scouts rely on stealth to survey routes and opponents, using ranged weapons and skirmish tactics when forced to fight. By contrast with barbarians, in combat scouts tend to be cautious and methodical, rather than impulsive.
        return {
            gearList = {
                { item = "AB_a_ClothHelm1" },
                { item = "ashfall_waterskin" },
                { item = "ashfall_woodaxe" },
                { item = "ashfall_grill" },
                { item = "ashfall_kettle_06" },
                { item = "ashfall_waterskin" },
                { item = "ashfall_tent_base_m" },
                { item = "p_chameleon_s" },
                { item = "iron saber" },
                { item = "T_Rea_Wormmouth_Helm_01" },
                { item = "T_Nor_Wood_Shield_01" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowAmount },
                { item = "netch_leather_pauldron_right" },
                { item = "netch_leather_pauldron_left" },
                { item = "AB_App_Grinder" },
                { item = "WAR_MLSND_BOOT_01" },
            },
            spellList = {
                "feather",

            },
        }
    end,

    ["T_Mw_Scribe"] = function()
--Scribes serve as public clerks for the masses, as well as professional copyists of hand-written texts in noble courts. In western provinces, Scribes often oversee the operation and maintainance of printing presses.	
        return {
            gearList = {
                { item = "sc_paper plain", count= 2 },
                { item = "Misc_Inkwell" },
                { item = "Misc_Quill" },
                { item = "aa_cl_speech_pot" },
                { item = "AB_App_Grinder" },
                { item = "AB_Misc_PurseCoin" },
                { item = "probe_journeyman_01" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "chitin war axe" },
                { item = "chitin spear" },
                { item = "sc_tevilspeace" },
                { item = "sc_restoration" },
            },
            spellList = {
                "stamina",
            },
        }
    end,

    ["Shadow"] = function()
--Shadows are mages who turn their magical abilities to thievery. The best way to protect your goods from a shadow is to have nothing valuable or interesting enough that they would bother to steal it.
        return {
            gearList = {
                { item = "p_chameleon_s" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "p_jump_s" },
                { item = "p_restore_fatigue_s" },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
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
        }
    end,

    ["Shadowdancer"] = function()
--The shadowdancer is the bard most suited for solo adventures. He relies on potions and magic items for support. Travelling often alone, he is a proficient armourer and dabbles in Mysticism.
        return {
            gearList = {
                { item = "chitin shortsword" },
                { item = "netch_leather_pauldron_right" },
                { item = "netch_leather_pauldron_left" },
                { item = "p_jump_s" },
                { item = "p_restore_fatigue_s" },
                { item = "AB_App_Grinder" },
                { item = "iron saber" },
                { item = "hammer_repair", count = 2 },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "aa_cl_speech_pot" },
                { item = "misc_de_lute_01", },
                { item = "aa_bk_songbook_shadow" },
            },
            spellList = {
                "absorb speed",
            },
        }
    end,

    ["Shaman"] = function()
--Shamans rely on their mystical powers drawn from their worship of nature and animal spirits. They are known to be able to summon living creatures to fight by their sides, and are proficient with various weapons.
        return {
            gearList = {
                { item = "T_Nor_Ringmail_Cuirass_01" },
                { item = "T_Com_Wood_Mace_01" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "common_robe_05_a"},
            },
            spellList = {
                "summon scamp",
                "absorb fatigue",
                "aa_cl_mage_abil",
                "calm creature",
                "five fingers of pain",
                "BM_summonbear",
            },
        }
    end,

    ["Sharpshooter"] = function()
--Sharpshooter are expert marksmen, often making their living as mercenaries, working on short contracts as caravan guards or expedition escorts, or for long term contracts to nobles or .
        return {
            gearList = {
                { item = "mer_fletch_kit" },
                { item = "AB_w_WoodCrossbow" },
                { item = "T_Com_Wood_Bolt_01", count = arrowAmount },
                { item = "T_Rea_Wormmouth_BracerR_01" },
                { item = "T_Rea_Wormmouth_BracerL_01" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "p_chameleon_s" },
                { item = "p_restore_fatigue_s" },
            },
            spellList = {
                "aa_cl_sharp_spell",

            },
        }
    end,

    ["Skald"] = function()
--The Skald is a bard that goes to battle to support his companions. He is hardy and wears heavier armour than most bards. When forced into combat, he prefers the spear. Like all bards, he is a fine speaker and relies on potions and to some extent, enchanted items.
        return {
            gearList = {
                { item = "aa_cl_speech_pot" },
                { item = "T_Nor_Ringmail_Cuirass_01" },
                { item = "AB_App_Grinder" },
                { item = "fur_pauldron_left" },
                { item = "fur_pauldron_right" },
                { item = "chitin spear" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "AB_Misc_PurseCoin" },
                { item = "misc_de_lute_01", },
                { item = "aa_bk_songbook_skald" },
            },
            spellList = {
                "aa_cl_skald_spell",
                "heal companion",
            },
        }
    end,

    ["Slave"] = function()
--Slaves serve their owner and master as commanded. They clean, prepare food, fetch and carry, do the shopping and marketing, and do other tasks too tiresome or menial for their master.
        return {
            gearList = {
                { item = "slave_bracer_left" },
                { item = "slave_bracer_right" },
            },
            spellList = {
                "aa_cl_slave_ability",
                "aa_cl_slave_power",
            },
        }
    end,

    ["Smith"] = function()
--Smiths make, sell, and repair weapons and armor. They can also teach how to take care of worn weapons and worn armor, and sell the necessary armorer tools. They also repair weapons and armor, for a fee.
        return {
            gearList = {
                { item = "hammer_repair", count = 5 },
                { item = "mc_metalworking_kit" },
                { item = "AB_w_ToolSmithHammer" },
                { item = "WAR_BLACKSMITH_APRON01" },
                { item = "iron_shield" },
                { item = "left gauntlet of the horny fist" },
                { item = "T_Rea_Wormmouth_BracerR_01" },
                { item = "T_Com_Iron_Warpick_01" },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
            },
            spellList = {
            },
        }
    end,

    ["Smuggler"] = function()
--Smugglers transport goods the empire has prohibited, such as skooma, moon sugar, ebony, Dwemer artifacts, exotic Dunmer weapons and armor, and slaves. Smugglers also smuggle greef, shein, and sujamma to avoid Imperial tax.
        return {
            gearList = {
                { item = "T_Com_Wood_Mace_01" },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
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
        }
    end,

    ["Sorcerer"] = function()
--Though spellcasters by vocation, sorcerers rely most on summonings and enchantments. They are greedy for magic scrolls, rings, armor, and weapons, and commanding undead and Daedric servants gratifies their egos.
        return {
            gearList = {
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "Misc_SoulGem_Lesser" },
                { item = "chitin shortsword" },
                { item = "viperstar", count = arrowAmount },
                { item = "T_Rea_Wormmouth_BracerL_01" },
                { item = "T_Com_Iron_PauldronR_01" },
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
        }
    end,

    ["Spearman"] = function()
--Spearmen form the front lines in a pitched battle, requiring strength and bravery. Mysticism is a useful skill for those spearmen who can learn it as it allows them to protect themselves from ranged magical attacks. All spearmen also carry short blades for those who manage to get past their spears.
        return {
            gearList = {
                { item = "steel spear" },
                { item = "T_Rea_Wormmouth_BracerR_01" },
                { item = "T_Rea_Wormmouth_BracerL_01" },
                { item = "p_restore_fatigue_s" },
                { item = "T_Com_Iron_PauldronR_01" },
                { item = "T_Com_Iron_PauldronL_01" },
                { item = "chitin shortsword" },
                { item = "hammer_repair", count = 2 },
                { item = "AB_App_Grinder" },
            },
            spellList = {
                "aa_cl_spear_spell",
                "dispel",
            },
        }
    end,

    ["Spellsword"] = function()
--Spellswords are spellcasting specialists trained to support Imperial troops in skirmish and battle. Veteran spellswords are prized as mercenaries, and well-suited for careers as adventurers and soldiers-of-fortune.
        return {
            gearList = {
                { item = "T_Nor_Wood_Shield_01" },
                { item = "iron saber" },
                { item = "T_Com_Wood_Mace_01" },
                { item = "T_Nor_Ringmail_Cuirass_01" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "AB_App_Grinder" },
            },
            spellList = {
                "mother's kiss",
                "five fingers of pain",
                "shield",

            },
        }
    end,

    ["Stormcaller"] = function()
--Stormcallers are the shamanistic spellbinders and spiritual guides. These hedge mages combine the ability to call upon lightning and ice, amongst other magicks, with a lifetime of training with the spear. Stormcallers are trained to withstand both physical and mental hardships.
        return {
            gearList = {
                { item = "ingred_frost_salts_01" },
                { item = "chitin spear" },
                { item = "AB_c_CommonHood01" },
                { item = "BM_Nordic01_Robe" },
                { item = "AB_App_Grinder" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "aa_cl_speech_pot" },
                { item = "BM wolf boots" },
            },
            spellList = {
                "frost bolt",
                "shock",
                "frost barrier",
                "spell absorption",
                "aa_cl_storm_power",
            },
        }
    end,

    ["Summoner"] = function()
--Summoners are people who influence the outer world by summoning creatures or objects of interest. They are talented spellcasters who understand most schools of magic but heavily favour Conjuration.
        return {
            gearList = {
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "Misc_SoulGem_Lesser" },
                { item = "chitin shortsword" },
                { item = "aa_cl_speech_pot" },
                { item = "netch_leather_cuirass" },
                { item = "common_robe_03"},
                { item = "AB_c_CommonHood03"},
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
        }
    end,

    ["Thaumaturge"] = function()
--Thaumaturges concentrate on exposing or manipulating known forces and objects within their natural laws. Thaumaturgical spells can temporarily change the appearance or structure of a force or object. Examples include levitation, magic resistance, reflect, calm, invisibility, and water walking.
        return {
            gearList = {
                { item = "wooden staff" },
                { item = "chitin throwing star", count = arrowAmount },
                { item = "p_chameleon_s" },
                { item = "AB_c_CommonHood02tt"},
                { item = "common_robe_02_tt"},
            },
            spellList = {
                "levitate",
                "reflect",
                "invisibility",
                "aa_cl_arcan_power",
                "water walking",
            },
        }
    end,

    ["Thief"] = function()
--Thieves are pickpockets and pilferers. Unlike robbers, who kill and loot, thieves typically choose stealth and subterfuge over violence, and often entertain romantic notions of their charm and cleverness in their acquisitive activities.
        return {
            gearList = {
                { item = "common_hood_01" },
                { item = "probe_journeyman_01" },
                { item = "pick_journeyman_01" },
                { item = "p_chameleon_s" },
                { item = "p_jump_s" },
                { item = "chitin shortsword" },
                { item = "chitin short bow" },
                { item = "corkbulb arrow", count = arrowAmount },
                { item = "p_restore_fatigue_s" },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
                { item = "aa_cl_speech_pot" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
            },
            spellList = {
                "aa_cl_thief_power",
            },
        }
    end,

    ["Trader"] = function()
--Traders are travelling general merchants. They look for opportunities to make a profit on their travels, often with exotic goods or services.
        return {
            gearList = {
                { item = "Gold_001", count = goldAmount },
                { item = "Gold_001", count = goldAmount },
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
                { item = "aa_cl_speech_pot" },
                { item = "probe_journeyman_01" },
                { item = "watcher's belt" },
                { item = "netch_leather_shield" },
                { item = "T_Com_Wood_Mace_01" },
                { item = "left gauntlet of the horny fist" },
                { item = "right gauntlet of horny fist" },
                { item = "WAR_MLSND_BOOT_01" },
            },
            spellList = {
                "aa_cl_bank_power",
                "aa_cl_pawn_power",
                "aa_cl_dock_power",
                "recall",
            },
        }
    end,

    ["Vestal"] = function()
        return {
            gearList = {
                { item = "AB_alc_HealBandage01", count = 2 },
                { item = "aa_cl_speech_pot" },
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "hammer_repair" },
                { item = "MG_P (2)" },
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
        }
    end,

    ["Veteran"] = function()
--Veterans are soldiers who have seen enough fighting not to desire more. They would rather sit by a campfire exchanging war stories than create new ones. However, it would still be unwise to pick a fight with someone who has survived as much combat as they have.
        return {
            gearList = {
                { item = "iron saber" },
                { item = "chitin spear" },
                { item = "T_Nor_Wood_Shield_01" },
                { item = "aa_cl_speech_pot" },
                { item = "AB_w_WoodCrossbow" },
                { item = "T_Com_Wood_Bolt_01", count = arrowAmount },
                { item = "lbonemold brace of horny fist" },
                { item = "rbonemold bracer of horny fist" },
                { item = "AB_App_Grinder" },
                { item = "iron_greaves" },
                { item = "iron boots" },
                { item = "T_Com_Iron_Cuirass_01" },
            },
            spellList = {
                "aa_cl_veteran_spell",
            },
        }
    end,

    ["Warlock"] = function()
--Warlocks are male mages who bind themselves by oath and deed to the service of a Daedra lord, and in return receive gifts of knowledge and power. In Morrowind, Warlocks often serve the House of Troubles.

        return {
            gearList = {
                { item = "ingred_rune_a_03" },
                { item = "ingred_rune_a_06" },
                { item = "chitin shortsword" },
                { item = "p_restore_fatigue_s" },
                { item = "aa_cl_speech_pot" },
                { item = "AB_c_CommonHood03" },
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
        }
    end,

    ["Warlord"] = function()
--Warlords are powerful fighters who command their own hordes. They make use of speechcraft and magic to rally and buff their troops in battle.
        return {
            gearList = {
                { item = "chitin war axe" },
                { item = "iron_greaves" },
                { item = "iron boots" },
                { item = "steel_cuirass" },
                { item = "aa_cl_speech_pot" },
                { item = "iron saber" },
                { item = "T_Com_Wood_Mace_01" },
                { item = "iron_shield" },
                { item = "AB_w_WoodCrossbow" },
                { item = "T_Com_Wood_Bolt_01", count = arrowAmount },
            },
            spellList = {
                "aa_cl_skald_spell",
                "rally humanoid",
            },
        }
    end,

    ["Warrior"] = function()
--Warriors are the professional men-at-arms, soldiers, mercenaries, and adventurers of the Empire, trained with various weapon and armor styles, conditioned by long marches, and hardened by ambush, skirmish, and battle.
        return {
            gearList = {
                { item = "iron saber" },
                { item = "T_Rea_Wormmouth_PauldronL_01" },
                { item = "T_Rea_Wormmouth_PauldronR_01" },
                { item = "iron boots" },
                { item = "T_Com_Iron_Cuirass_01" },
                { item = "p_restore_fatigue_s" },
                { item = "T_Nor_Wood_Shield_01" },
                { item = "hammer_repair", count = 2 },
                { item = "T_Com_Wood_Mace_01" },
                { item = "chitin war axe" },
                { item = "AB_w_WoodCrossbow" },
                { item = "T_Com_Wood_Bolt_01", count = arrowAmount },
                { item = "chitin spear" },
            },
            spellList = {
                "aa_cl_barbar_power",
            },
        }
    end,

    ["Wise Woman"] = function()
--The Wise Women of the Ashlanders are councilors to their tribe, guardian of secret knowledge, spirit guide and seer into the world unseen. If accepted by the tribe, they can teach outlanders about the ancestors, and about Ashlander customs.
        return {
            gearList = {
                { item = "left gauntlet of the horny fist" },
                { item = "right gauntlet of horny fist" },
                { item = "aa_cl_speech_pot" },
                { item = "wooden staff" },
                { item = "netch_leather_pauldron_right" },
                { item = "netch_leather_pauldron_left" },
                { item = "AB_App_Grinder" },
                { item = "WAR_MLSND_BOOT_01" },
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
        }
    end,

    ["Witch"] = function()
--Witches are female mages who bind themselves by oath and deed to the service of a Daedra lord, and in return receive gifts of knowledge and power. In Morrowind, Witches often serve the House of Troubles.
        return {
            gearList = {
                { item = "mc_toxinflask" },
                { item = "ingred_rune_a_04" },
                { item = "chitin shortsword" },
                { item = "AB_c_CommonHood05c" },
                { item = "aa_cl_speech_pot" },
                { item = "p_chameleon_s" },
                { item = "AB_App_Grinder" },
                { item = "common_robe_05_c"},
            },
            spellList = {
                "absorb fatigue",
                "summon scamp",
                "summon clanfear",
                "burden",
                "erelvam's wild sty",
            },
        }
    end,

    ["Witchhunter"] = function()
--Witchhunters are dedicated to rooting out and destroying the perverted practices of dark cults and profane sorcery. They train for martial, magical, and stealthy war against vampires, witches, warlocks, and necromancers.
        return {
            gearList = {
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty" },
                { item = "AB_App_Grinder" },
                { item = "left leather bracer" },
                { item = "right leather bracer" },
                { item = "netch_leather_helm" },
                { item = "AB_w_WoodCrossbow" },
                { item = "T_Com_Wood_Bolt_01", count = arrowAmount },
                { item = "watcher's belt" },
                { item = "p_chameleon_s" },
                { item = "T_Com_Wood_Mace_01" },
                { item = "netch_leather_shield" },
            },
            spellList = {
                "turn undead",
                "dispel",
                "aa_cl_whunter_power",
            },
        }
    end,

    ["XXX"] = function()
        return {
            gearList = {
                { item = "XXX" },
            },
            spellList = {
                "XXX",
            },
        }
    end,
}

return this