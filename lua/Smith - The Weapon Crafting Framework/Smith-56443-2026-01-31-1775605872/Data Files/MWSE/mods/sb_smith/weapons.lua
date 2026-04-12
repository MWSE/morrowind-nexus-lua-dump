local interop = require("sb_smith.interop")

---@type weapon[]
local weapons = {
    ["chitin war axe"] =
    {
        handles = { "Tri W_Chitin_Axe 0" },
        blades  = { "Tri W_Chitin_Axe 1", "Tri W_Chitin_Axe 2", "Tri W_Chitin_Axe 3", "Tri W_Chitin_Axe 4" },
        rootIndexes = { 1, 1 }
    },
    ["iron war axe"] =
    {
        handles = { "Tri W_WARAXE_IRON 0", "Tri W_WARAXE_IRON 1", "Tri W_WARAXE_IRON 2" },
        blades  = { "Tri W_WARAXE_IRON 3", "Tri W_WARAXE_IRON 4" },
        rootIndexes = { 3, 2 }
    },
    ["steel axe"] =
    {
        handles = { "Tri W_WarAxe_Steel 0", "Tri W_WarAxe_Steel 2" },
        blades = { "Tri W_WarAxe_Steel 1", "Tri W_WarAxe_Steel 3", "Tri W_WarAxe_Steel 4" },
        rootIndexes = { 2, 2 }
    },
    ["steel war axe"] =
    {
        handles = { "Tri W_WarAxe_Steel 0", "Tri W_WarAxe_Steel 2" },
        blades = { "Tri W_WarAxe_Steel 1", "Tri W_WarAxe_Steel 3", "Tri W_WarAxe_Steel 4" },
        rootIndexes = { 2, 2 }
    },
    ["silver war axe"] =
    {
        handles = { "Tri W_silver_waraxe 0", "Tri W_silver_waraxe 1", "Tri W_silver_waraxe 3" },
        blades = { "Tri W_silver_waraxe 2" },
        rootIndexes = { 3, 1 }
    },
    ["dwarven war axe"] =
    {
        handles = { "Tri W_Dwemer_waraxe 0", "Tri W_Dwemer_waraxe 1", "Tri W_Dwemer_waraxe 2", "Tri W_Dwemer_waraxe 3", "Tri W_Dwemer_waraxe 4" },
        blades = { "Tri W_Dwemer_waraxe 5", "Tri W_Dwemer_waraxe 6", "Tri W_Dwemer_waraxe 7", "Tri W_Dwemer_waraxe 8", "Tri W_Dwemer_waraxe 9", "Tri W_Dwemer_waraxe 10", "Tri W_Dwemer_waraxe 11", "Tri W_Dwemer_waraxe 12", "Tri W_Dwemer_waraxe 13" },
        rootIndexes = { 5, 9 }
    },
    ["glass war axe"] =
    {
        handles = { "Tri W_waraxe_glass 0", "Tri W_waraxe_glass 2" },
        blades = { "Tri W_waraxe_glass 1", "Tri W_waraxe_glass 3" , "Tri W_waraxe_glass 4" },
        rootIndexes = { 1, 1 }
    },
    ["ebony war axe"] =
    {
        handles = { "Tri W_waraxe_ebony 0", "Tri W_waraxe_ebony 1", "Tri W_waraxe_ebony 2", "Tri W_waraxe_ebony 3" },
        blades = { "Tri W_waraxe_ebony 4", "Tri W_waraxe_ebony 5", "Tri W_waraxe_ebony 6" },
        rootIndexes = { 4, 2 }
    },
    ["daedric war axe"] =
    {
        handles = { "Tri W_waraxe_daedric 0", "Tri W_waraxe_daedric 1", "Tri W_waraxe_daedric 2", "Tri W_waraxe_daedric 6" },
        blades = { "Tri W_waraxe_daedric 3", "Tri W_waraxe_daedric 4", "Tri W_waraxe_daedric 5" },
        rootIndexes = { 3, 2 }
    },
    -----
    ["miner's pick"] =
    {
        handles = { "Tri W_miner_pick 0", "Tri W_miner_pick 2" },
        blades = { "Tri W_miner_pick 1" },
        rootIndexes = { 2, 1 }
    },
    ["iron battle axe"] =
    {
        handles = { "Tri W_BATTLEAXE_IRON 0", "Tri W_BATTLEAXE_IRON 1", "Tri W_BATTLEAXE_IRON 2" },
        blades = { "Tri W_BATTLEAXE_IRON 3", "Tri W_BATTLEAXE_IRON 4", "Tri W_BATTLEAXE_IRON 5" },
        rootIndexes = { 3, 1 }
    },
    ["nordic battle axe"] =
    {
        handles = { "Tri W_Nordic_BattleAxe 3" },
        blades = { "Tri W_Nordic_BattleAxe 0", "Tri W_Nordic_BattleAxe 1", "Tri W_Nordic_BattleAxe 2" },
        rootIndexes = { 1, 3 }
    },
    ["steel battle axe"] =
    {
        handles = { "Tri W_steel_battleaxe 0", "Tri W_steel_battleaxe 1" },
        blades = { "Tri W_steel_battleaxe 2" },
        rootIndexes = { 2, 1 }
    },
    ["dwarven battle axe"] =
    {
        handles = { "Tri W_Dwemer_battleaxe 0", "Tri W_Dwemer_battleaxe 1", "Tri W_Dwemer_battleaxe 2" },
        blades = { "Tri W_Dwemer_battleaxe 3", "Tri W_Dwemer_battleaxe 4", "Tri W_Dwemer_battleaxe 5" },
        rootIndexes = { 3, 1 }
    },
    ["orcish battle axe"] =
    {
        handles = { "Tri W_Orcish_battleaxe 0", "Tri W_Orcish_battleaxe 1" },
        blades = { "Tri W_Orcish_battleaxe 2", "Tri W_Orcish_battleaxe 3", "Tri W_Orcish_battleaxe 4", "Tri W_Orcish_battleaxe 5" },
        rootIndexes = { 2, 3 }
    },
    ["daedric battle axe"] =
    {
        handles = { "Tri W_battleaxe_daedric 0", "Tri W_battleaxe_daedric 1", "Tri W_battleaxe_daedric 2", "Tri W_battleaxe_daedric 3", "Tri W_battleaxe_daedric 4" },
        blades = { "Tri W_battleaxe_daedric 5", "Tri W_battleaxe_daedric 6", "Tri W_battleaxe_daedric 7", "Tri W_battleaxe_daedric 8", "Tri W_battleaxe_daedric 9", "Tri W_battleaxe_daedric 10", "Tri W_battleaxe_daedric 11" },
        rootIndexes = { 1, 1 }
    },
    -----
    ["chitin club"] =
    {
        handles = { "Tri W_chitin_club 1", "Tri W_chitin_club blade" },
        blades = { "Tri W_chitin_club handle" },
        rootIndexes = { 2, 1 }
    },
    ["iron club"] =
    {
        handles = { "Tri W_CLUB_IRON Handle 0", "Tri W_CLUB_IRON Handle 1", "Tri W_CLUB_IRON Handle 2" },
        blades = { "Tri Tri W_CLUB_IRON 0 0", "Tri Tri W_CLUB_IRON 0 1", "Tri Tri W_CLUB_IRON 0 2", "Tri Tri W_CLUB_IRON 1 0", "Tri Tri W_CLUB_IRON 1 1", "Tri W_CLUB_IRON 2", "Tri W_CLUB_IRON 3" },
        rootIndexes = { 3, 1 }
    },
    ["spiked club"] =
    {
        handles = { "Tri W_Club00 1", "Tri W_Club00 0.001" },
        blades = { "Tri W_Club00 0", "Tri W_Club00 2" },
        rootIndexes = { 1, 1 }
    },
    ["dreugh club"] =
    {
        handles = { "W_Dreugh_club handle" },
        blades = { "W_Dreugh_club blade" },
        rootIndexes = { 1, 1 }
    },
    ["steel club"] =
    {
        handles = { "Tri W_spikedClub Handle" },
        blades = { "Tri W_spikedClub 1", "Tri W_spikedClub Blade" },
        rootIndexes = { 1, 2 }
    },
    ["iron mace"] =
    {
        handles = { "Tri w_mace_iron 0", "Tri w_mace_iron 1", "Tri w_mace_iron 2" },
        blades = { "Tri w_mace_iron 3", "Tri w_mace_iron 4" },
        rootIndexes = { 3, 1 }
    },
    ["daedric club"] =
    {
        handles = { "Tri W_club_daedric handle 0", "Tri W_club_daedric handle 1" },
        blades = { "Tri W_club_daedric 0", "Tri W_club_daedric 1", "Tri W_club_daedric 2" },
        rootIndexes = { 1, 1 }
    },
    ["steel mace"] =
    {
        handles = { "Tri W_mace 0", "Tri W_mace 3" },
        blades = { "Tri W_mace 1", "Tri W_mace 2" },
        rootIndexes = { 2, 1 }
    },
    ["dwarven mace"] =
    {
        handles = { "Tri W_Dwemer_mace 0", "Tri W_Dwemer_mace 1" },
        blades = { "Tri W_Dwemer_mace 2", "Tri W_Dwemer_mace 3", "Tri W_Dwemer_mace 4", "Tri W_Dwemer_mace 5", "Tri W_Dwemer_mace 6", "Tri W_Dwemer_mace 7", "Tri W_Dwemer_mace 8" },
        rootIndexes = { 2, 1 }
    },
    ["ebony mace"] =
    {
        handles = { "Tri W_mace_ebony 0", "Tri W_mace_ebony 1", "Tri W_mace_ebony 2", "Tri W_mace_ebony 3", "Tri W_mace_ebony 6" },
        blades = { "Tri W_mace_ebony 4", "Tri W_mace_ebony 5" },
        rootIndexes = { 1, 1 }
    },
    ["daedric mace"] =
    {
        handles = { "Tri W_mace_daedric 0", "Tri W_mace_daedric 1", "Tri W_mace_daedric 8" },
        blades = { "Tri W_mace_daedric 2", "Tri W_mace_daedric 3", "Tri W_mace_daedric 4", "Tri W_mace_daedric 5", "Tri W_mace_daedric 6", "Tri W_mace_daedric 7" },
        rootIndexes = { 3, 1 }
    },
    ["iron warhammer"] =
    {
        handles = { "Tri w_warhammer_iron 0", "Tri w_warhammer_iron 1" },
        blades = { "Tri w_warhammer_iron 2", "Tri w_warhammer_iron 3", "Tri w_warhammer_iron 4", "Tri w_warhammer_iron 5", "Tri w_warhammer_iron 6", "Tri w_warhammer_iron 7" },
        rootIndexes = { 2, 1 }
    },
    ["steel warhammer"] =
    {
        handles = { "Tri W_Warhammer 5", "Tri W_Warhammer 7" },
        blades = { "Tri W_Warhammer 0", "Tri W_Warhammer 1", "Tri W_Warhammer 2", "Tri W_Warhammer 3", "Tri W_Warhammer 4", "Tri W_Warhammer 6" },
        rootIndexes = { 1, 6 }
    },
    ["dwarven warhammer"] =
    {
        handles = { "Tri W_Dwemer_warhammer 0", "Tri W_Dwemer_warhammer 1", "Tri W_Dwemer_warhammer 2", "Tri W_Dwemer_warhammer 3" },
        blades = { "Tri W_Dwemer_warhammer 4", "Tri W_Dwemer_warhammer 5", "Tri W_Dwemer_warhammer 6", "Tri W_Dwemer_warhammer 7", "Tri W_Dwemer_warhammer 8", "Tri W_Dwemer_warhammer 9", "Tri W_Dwemer_warhammer 10", "Tri W_Dwemer_warhammer 11", "Tri W_Dwemer_warhammer 12", "Tri W_Dwemer_warhammer 13", "Tri W_Dwemer_warhammer 14", "Tri W_Dwemer_warhammer 15", "Tri W_Dwemer_warhammer 16" },
        rootIndexes = { 4, 12 }
    },
    ["orcish warhammer"] =
    {
        handles = { "Tri W_Orcish_warhammer 0", "Tri W_Orcish_warhammer 2" },
        blades = { "Tri W_Orcish_warhammer 1", "Tri W_Orcish_warhammer 3", "Tri W_Orcish_warhammer 4", "Tri W_Orcish_warhammer 5"},
        rootIndexes = { 2, 1 }
    },
    ["6th bell hammer"] =
    {
        handles = { "Tri W_6th_Hammer Blade 0", "Tri W_6th_Hammer Blade 1", "Tri W_6th_Hammer Blade 2", "Tri W_6th_Hammer Blade 3", "Tri W_6th_Hammer Handle 0" },
        blades = { "Tri W_6th_Hammer Handle 1", "Tri W_6th_Hammer Handle 2", "Tri W_6th_Hammer Handle 3", "Tri W_6th_Hammer Handle 4" },
        rootIndexes = { 5, 3 }
    },
    ["daedric warhammer"] =
    {
        handles = { "Tri W_warhammer_daedric Blade 0", "Tri W_warhammer_daedric Blade 1" },
        blades = { "Tri W_warhammer_daedric Handle" },
        rootIndexes = { 1, 1 }
    },
    -----
    ["wooden staff"] =
    {
        handles = { "Tri W_wooden_staff 1", "Tri W_wooden_staff 2" },
        blades = { "Tri W_wooden_staff 0" },
        rootIndexes = { 1, 1 }
    },
    ["steel staff"] =
    {
        handles = { "Tri W_staff00 0", "Tri W_staff00 1", "Tri W_staff00 2" },
        blades = { "Tri W_staff00 0", "Tri W_staff00 1", "Tri W_staff00 2" },
        rootIndexes = { 1, 3 }
    },
    ["silver staff"] =
    {
        handles = { "Tri W_silver_staff 0", "Tri W_silver_staff 2", "Tri W_silver_staff 3", "Tri W_silver_staff 4" },
        blades = { "Tri W_silver_staff 1" },
        rootIndexes = { 2, 1 }
    },
    ["dreugh staff"] =
    {
        handles = { "W_Dreugh_staff hanld" },
        blades = { "W_Dreugh_staff blade" },
        rootIndexes = { 1, 1 }
    },
    ["glass staff"] =
    {
        handles = { "Tri W_staff_glass 1", "Tri W_staff_glass 2" },
        blades = { "Tri W_staff_glass 0", "Tri W_staff_glass 3", "Tri W_staff_glass 4", "Tri W_staff_glass 5", "Tri W_staff_glass 6", "Tri W_staff_glass 7", "Tri W_staff_glass 8", "Tri W_staff_glass 9", "Tri W_staff_glass 10", "Tri W_staff_glass 11", "Tri W_staff_glass 12", "Tri W_staff_glass 13", "Tri W_staff_glass 14", "Tri W_staff_glass 15", "Tri W_staff_glass 16", "Tri W_staff_glass 17" },
        rootIndexes = { 1, 1 }
    },
    ["ebony staff"] =
    {
        handles = { "Tri W_staff_ebony 1", "Tri W_staff_ebony 2", "Tri W_staff_ebony 4", "Tri W_staff_ebony 5", "Tri W_staff_ebony 6" },
        blades = { "Tri W_staff_ebony 0", "Tri W_staff_ebony 3" },
        rootIndexes = { 3, 1 }
    },
    ["daedric staff"] =
    {
        handles = { "Tri W_staff_daedric 1", "Tri W_staff_daedric 2", "Tri W_staff_daedric 5" },
        blades = { "Tri W_staff_daedric 0", "Tri W_staff_daedric 3", "Tri W_staff_daedric 4" },
        rootIndexes = { 1, 1 }
    },
    -----
    ["chitin dagger"] =
    {
        handles = { "Tri W_dagger_chitin 2", "Tri W_dagger_chitin 3", "Tri W_dagger_chitin 4", "Tri W_dagger_chitin 5" },
        blades = { "Tri W_dagger_chitin 0", "Tri W_dagger_chitin 1" },
        rootIndexes = { 2, 2 }
    },
    ["iron dagger"] =
    {
        handles = { "Tri W_iron_dagger 0", "Tri W_iron_dagger 1" },
        blades = { "Tri W_iron_dagger 2" },
        rootIndexes = { 1, 1 }
    },
    ["chitin shortsword"] =
    {
        handles = { "Tri W_Shortsword_chitin 3", "Tri W_Shortsword_chitin 4", "Tri W_Shortsword_chitin 5" },
        blades = { "Tri W_Shortsword_chitin 0", "Tri W_Shortsword_chitin 1", "Tri W_Shortsword_chitin 2" },
        rootIndexes = { 3, 2 }
    },
    ["iron tanto"] =
    {
        handles = { "Tri W_tanto_iron 0", "Tri W_tanto_iron 1" },
        blades = { "Tri W_tanto_iron 2" },
        rootIndexes = { 2, 1 }
    },
    ["steel dagger"] =
    {
        handles = { "Tri W_Dagger_dragon 1", "Tri W_Dagger_dragon 2" },
        blades = { "Tri W_Dagger_dragon 0" },
        rootIndexes = { 2, 1 }
    },
    ["iron shortsword"] =
    {
        handles = { "Tri W_Iron_shortsword 1", "Tri W_Iron_shortsword 2", "Tri W_Iron_shortsword 3" },
        blades = { "Tri W_Iron_shortsword 0" },
        rootIndexes = { 3, 1 }
    },
    ["iron wakizashi"] =
    {
        handles = { "Tri W_wakizashi_iron 0", "Tri W_wakizashi_iron 1", "Tri W_wakizashi_iron 2", "Tri W_wakizashi_iron 4", "Tri W_wakizashi_iron 5" },
        blades = { "Tri W_wakizashi_iron 3" },
        rootIndexes = { 3, 1 }
    },
    ["steel tanto"] =
    {
        handles = { "Tri W_Tanto 0", "Tri W_Tanto 1", "Tri W_Tanto 3", "Tri W_Tanto 4", "Tri W_Tanto 5" },
        blades = { "Tri W_Tanto 2" },
        rootIndexes = { 3, 1 }
    },
    ["imperial shortsword"] =
    {
        handles = { "Tri W_Shortsword_Imperial 1", "Tri W_Shortsword_Imperial 2", "Tri W_Shortsword_Imperial 3" },
        blades = { "Tri W_Shortsword_Imperial 0" },
        rootIndexes = { 2, 1 }
    },
    ["silver dagger"] =
    {
        handles = { "Tri W_silver_dagger 2" },
        blades = { "Tri W_silver_dagger 0", "Tri W_silver_dagger 1" },
        rootIndexes = { 1, 2 }
    },
    ["steel shortsword"] =
    {
        handles = { "Tri W_shortsword00 0", "Tri W_shortsword00 1", "Tri W_shortsword00 2", "Tri W_shortsword00 3", "Tri W_shortsword00 5" },
        blades = { "Tri W_shortsword00 4" },
        rootIndexes = { 4, 1 }
    },
    ["steel wakizashi"] =
    {
        handles = { "Tri W_Wakizashi 1", "Tri W_Wakizashi 2" },
        blades = { "Tri W_Wakizashi 0" },
        rootIndexes = { 2, 1 }
    },
    ["silver shortsword"] =
    {
        handles = { "Tri W_silver_Shortsword 1", "Tri W_silver_Shortsword 2", "Tri W_silver_Shortsword 3", "Tri W_silver_Shortsword 4" },
        blades = { "Tri W_silver_Shortsword 0" },
        rootIndexes = { 4, 1 }
    },
    ["dwarven shortsword"] =
    {
        handles = { "Tri W_Dwemer_shortsword 0", "Tri W_Dwemer_shortsword 1", "Tri W_Dwemer_shortsword 2", "Tri W_Dwemer_shortsword 3", "Tri W_Dwemer_shortsword 4" },
        blades = { "Tri W_Dwemer_shortsword 5" },
        rootIndexes = { 3, 4 }
    },
    ["glass dagger"] =
    {
        handles = { "Tri W_dagger_glass 0", "Tri W_dagger_glass 2", "Tri W_dagger_glass 3", "Tri W_dagger_glass 4" },
        blades = { "Tri W_dagger_glass 1" },
        rootIndexes = { 1, 1 }
    },
    ["daedric dagger"] =
    {
        handles = { "Tri W_Dagger_daedric 0" },
        blades = { "Tri W_Dagger_daedric 1" },
        rootIndexes = { 1, 1 }
    },
    ["ebony shortsword"] =
    {
        handles = { "Tri W_Shortsword_Ebony 0", "Tri W_Shortsword_Ebony 1", "Tri W_Shortsword_Ebony 2" },
        blades = { "Tri W_Shortsword_Ebony 3", "Tri W_Shortsword_Ebony 4", "Tri W_Shortsword_Ebony 5", "Tri W_Shortsword_Ebony 6" },
        rootIndexes = { 2, 4 }
    },
    ["daedric tanto"] =
    {
        handles = { "Tri W_tanto_daedric 0", "Tri W_tanto_daedric 1", "Tri W_tanto_daedric 2", "Tri W_tanto_daedric 5", "Tri W_tanto_daedric 6" },
        blades = { "Tri W_tanto_daedric 3", "Tri W_tanto_daedric 4" },
        rootIndexes = { 2, 2 }
    },
    ["daedric shortsword"] =
    {
        handles = { "Tri W_Shortsword_Daedric 0", "Tri W_Shortsword_Daedric 4", "Tri W_Shortsword_Daedric 5" },
        blades = { "Tri W_Shortsword_Daedric 1", "Tri W_Shortsword_Daedric 2", "Tri W_Shortsword_Daedric 3" },
        rootIndexes = { 3, 2 }
    },
    ["daedric wakizashi"] =
    {
        handles = { "Tri W_wakazashi_daedric 0", "Tri W_wakazashi_daedric 1", "Tri W_wakazashi_daedric 2", "Tri W_wakazashi_daedric 3" },
        blades = { "Tri W_wakazashi_daedric 4" },
        rootIndexes = { 3, 1 }
    },
    -----
    ["iron saber"] =
    {
        handles = { "Tri W_SABER_IRON 0" },
        blades = { "Tri W_SABER_IRON 1" },
        rootIndexes = { 1, 1 }
    },
    ["iron broadsword"] =
    {
        handles = { "Tri W_BROADSWORD_IRON 0" },
        blades = { "Tri W_BROADSWORD_IRON 1" },
        rootIndexes = { 1, 1 }
    },
    ["iron longsword"] =
    {
        handles = { "Tri W_Iron_Longsword 1", "Tri W_Iron_Longsword 2", "Tri W_Iron_Longsword 3", "Tri W_Iron_Longsword 4", "Tri W_Iron_Longsword 5" },
        blades = { "Tri W_Iron_Longsword 0" },
        rootIndexes = { 3, 1 }
    },
    ["steel saber"] =
    {
        handles = { "Tri W_Saber 0", "Tri W_Saber 1" },
        blades = { "Tri W_Saber 2" },
        rootIndexes = { 2, 1 }
    },
    ["steel broadsword"] =
    {
        handles = { "Tri W_Broadsword_Imperial 0", "Tri W_Broadsword_Imperial 1", "Tri W_Broadsword_Imperial 2" },
        blades = { "Tri W_Broadsword_Imperial 3" },
        rootIndexes = { 3, 1 }
    },
    ["imperial broadsword"] =
    {
        handles = { "Tri W_Broadsword_Imperial 0", "Tri W_Broadsword_Imperial 1", "Tri W_Broadsword_Imperial 2" },
        blades = { "Tri W_Broadsword_Imperial 3" },
        rootIndexes = { 3, 1 }
    },
    ["steel longsword"] =
    {
        handles = { "Tri W_Broadsword_leafblade 0", "Tri W_Broadsword_leafblade 2", "Tri W_Broadsword_leafblade 3", "Tri W_Broadsword_leafblade 4" },
        blades = { "Tri W_Broadsword_leafblade 1" },
        rootIndexes = { 3, 1 }
    },
    ["nordic broadsword"] =
    {
        handles = { "Tri W_Nordic_broadsword 0", "Tri W_Nordic_broadsword 2", "Tri W_Nordic_broadsword 3", "Tri W_Nordic_broadsword 5" },
        blades = { "Tri W_Nordic_broadsword 1", "Tri W_Nordic_broadsword 4" },
        rootIndexes = { 1, 1 }
    },
    ["steel katana"] =
    {
        handles = { "Tri W_N_Katana 0", "Tri W_N_Katana 2" },
        blades = { "Tri W_N_Katana 1"},
        rootIndexes = { 2, 1 }
    },
    ["silver longsword"] =
    {
        handles = { "Tri W_Longsword_Silver 2", "Tri W_Longsword_Silver 3", "Tri W_Longsword_Silver 4", "Tri W_Longsword_Silver 5" },
        blades = { "Tri W_Longsword_Silver 0", "Tri W_Longsword_Silver 1" },
        rootIndexes = { 2, 2 }
    },
    ["glass longsword"] =
    {
        handles = { "Tri W_Longsword_crystal 0", "Tri W_Longsword_crystal 1", "Tri W_Longsword_crystal 2", "Tri W_Longsword_crystal 3", "Tri W_Longsword_crystal 5", "Tri W_Longsword_crystal 6" },
        blades = { "Tri W_Longsword_crystal 4" },
        rootIndexes = { 3, 1 }
    },
    ["ebony broadsword"] =
    {
        handles = { "Tri W_broadsword_ebony 0", "Tri W_broadsword_ebony 1", "Tri W_broadsword_ebony 2", "Tri W_broadsword_ebony 3", "Tri W_broadsword_ebony 4" },
        blades = { "Tri W_broadsword_ebony 5", "Tri W_broadsword_ebony 6" },
        rootIndexes = { 4, 1 }
    },
    ["ebony longsword"] =
    {
        handles = { "Tri W_Longsword_ebony 3", "Tri W_Longsword_ebony 4", "Tri W_Longsword_ebony 5", "Tri W_Longsword_ebony 6" },
        blades = { "Tri W_Longsword_ebony 0", "Tri W_Longsword_ebony 1", "Tri W_Longsword_ebony 2" },
        rootIndexes = { 2, 2 }
    },
    ["daedric longsword"] =
    {
        handles = { "Tri W_Longsword_Daedric 0", "Tri W_Longsword_Daedric 1", "Tri W_Longsword_Daedric 2", "Tri W_Longsword_Daedric 4" },
        blades = { "Tri W_Longsword_Daedric 3" },
        rootIndexes = { 3, 1 }
    },
    ["daedric katana"] =
    {
        handles = { "Tri W_katana_daedric 0", "Tri W_katana_daedric 1", "Tri W_katana_daedric 2", "Tri W_katana_daedric 3", "Tri W_katana_daedric 4" },
        blades = { "Tri W_katana_daedric 5", "Tri W_katana_daedric 6" },
        rootIndexes = { 5, 1 }
    },
    -----
    ["iron claymore"] =
    {
        handles = { "Tri W_Iron_Claymore 1", "Tri W_Iron_Claymore 2", "Tri W_Iron_Claymore 3" },
        blades = { "Tri W_Iron_Claymore 0" },
        rootIndexes = { 2, 1 }
    },
    ["steel claymore"] =
    {
        handles = { "Tri W_claymore 0", "Tri W_claymore 1", "Tri W_claymore 2", "Tri W_claymore 3", "Tri W_claymore 4", "Tri W_claymore 6", "Tri W_claymore 7", "Tri W_claymore 8" },
        blades = { "Tri W_claymore 5" },
        rootIndexes = { 1, 1 }
    },
    ["nordic claymore"] =
    {
        handles = { "Tri W_Nordic_Claymore 1", "Tri W_Nordic_Claymore 2", "Tri W_Nordic_Claymore 3", "Tri W_Nordic_Claymore 5" },
        blades = { "Tri W_Nordic_Claymore 0", "Tri W_Nordic_Claymore 4" },
        rootIndexes = { 1, 1 }
    },
    ["steel dai-katana"] =
    {
        handles = { "Tri W_Daikatana 0", "Tri W_Daikatana 1" },
        blades = { "Tri W_Daikatana 2"},
        rootIndexes = { 2, 1 }
    },
    ["silver claymore"] =
    {
        handles = { "Tri W_Silver_Claymore 1", "Tri W_Silver_Claymore 2", "Tri W_Silver_Claymore 3", "Tri W_Silver_Claymore 4", "Tri W_Silver_Claymore 6" },
        blades = { "Tri W_Silver_Claymore 0", "Tri W_Silver_Claymore 5" },
        rootIndexes = { 3, 1 }
    },
    ["dwarven claymore"] =
    {
        handles = { "Tri W_Dwemer_claymore 0", "Tri W_Dwemer_claymore 1", "Tri W_Dwemer_claymore 2", "Tri W_Dwemer_claymore 3", "Tri W_Dwemer_claymore 4", "Tri W_Dwemer_claymore 5" },
        blades = { "Tri W_Dwemer_claymore 6" },
        rootIndexes = { 3, 1 }
    },
    ["glass claymore"] =
    {
        handles = { "Tri w_claymore_crystal 0", "Tri w_claymore_crystal 1", "Tri w_claymore_crystal 2", "Tri w_claymore_crystal 3", "Tri w_claymore_crystal 5" },
        blades = { "Tri w_claymore_crystal 4" },
        rootIndexes = { 5, 1 }
    },
    ["daedric claymore"] =
    {
        handles = { "Tri W_Claymore_Daedric 3", "Tri W_Claymore_Daedric 4", "Tri W_Claymore_Daedric 5" },
        blades = { "Tri W_Claymore_Daedric 0", "Tri W_Claymore_Daedric 1", "Tri W_Claymore_Daedric 2" },
        rootIndexes = { 3, 3 }
    },
    ["daedric dai-katana"] =
    {
        handles = { "Tri W_Dai-katana_daedric 0", "Tri W_Dai-katana_daedric 1", "Tri W_Dai-katana_daedric 2", "Tri W_Dai-katana_daedric 4" },
        blades = { "Tri W_Dai-katana_daedric 3" },
        rootIndexes = { 2, 1 }
    },
    -----
    ["chitin spear"] =
    {
        handles = { "Tri w_chitin_spear 0", "Tri w_chitin_spear 1" },
        blades = { "Tri w_chitin_spear 2" },
        rootIndexes = { 2, 1 }
    },
    ["iron spear"] =
    {
        handles = { "Tri w_spear_iron 2" },
        blades  = { "Tri w_spear_iron 0", "Tri w_spear_iron 1" },
        rootIndexes = { 1, 2 }
    },
    ["Iron Long Spear"] =
    {
        handles = { "Tri w_spear_iron 2" },
        blades  = { "Tri w_spear_iron 0", "Tri w_spear_iron 1" },
        rootIndexes = { 1, 2 }
    },
    ["steel spear"] =
    {
        handles = { "Tri W_spear 0", "Tri W_spear 1" },
        blades = { "Tri W_spear 2" },
        rootIndexes = { 1, 1 }
    },
    ["iron halberd"] =
    {
        handles = { "Tri W_halberd_iron 0" },
        blades = { "Tri W_halberd_iron 1" },
        rootIndexes = { 1, 1 }
    },
    ["steel halberd"] =
    {
        handles = { "Tri W_HALBERD_STEEL 0", "Tri W_HALBERD_STEEL 1" },
        blades = { "Tri W_HALBERD_STEEL 2", "Tri W_HALBERD_STEEL 3" },
        rootIndexes = { 2, 1 }
    },
    ["silver spear"] =
    {
        handles = { "Tri W_silver_spear 0", "Tri W_silver_spear 1", "Tri W_silver_spear 2", "Tri W_silver_spear 3" },
        blades = { "Tri W_silver_spear 4", "Tri W_silver_spear 5" },
        rootIndexes = { 1, 2 }
    },
    ["dwarven spear"] =
    {
        handles = { "Tri W_Dwemer_spear 0", "Tri W_Dwemer_spear 1" },
        blades = { "Tri W_Dwemer_spear 2" },
        rootIndexes = { 1, 1 }
    },
    ["dwarven halberd"] =
    {
        handles = { "Tri W_Dwemer_halberd 0", "Tri W_Dwemer_halberd 1", "Tri W_Dwemer_halberd 2", "Tri W_Dwemer_halberd 4", "Tri W_Dwemer_halberd 5" },
        blades = { "Tri W_Dwemer_halberd 3", "Tri W_Dwemer_halberd 6", "Tri W_Dwemer_halberd 7" },
        rootIndexes = { 3, 1 }
    },
    ["ebony spear"] =
    {
        handles = { "Tri W_longspear_ebony 0", "Tri W_longspear_ebony 1", "Tri W_longspear_ebony 3", "Tri W_longspear_ebony 4" },
        blades = { "Tri W_longspear_ebony 2", "Tri W_longspear_ebony 5", "Tri W_longspear_ebony 6" },
        rootIndexes = { 3, 1 }
    },
    ["glass halberd"] =
    {
        handles = { "Tri W_halberd_glass 0", "Tri W_halberd_glass 5" },
        blades = { "Tri W_halberd_glass 1", "Tri W_halberd_glass 2", "Tri W_halberd_glass 3", "Tri W_halberd_glass 4", "Tri W_halberd_glass 6" },
        rootIndexes = { 1, 3 }
    },
    ["daedric spear"] =
    {
        handles = { "Tri W_spear_daedric 0", "Tri W_spear_daedric 1", "Tri W_spear_daedric 2", "Tri W_spear_daedric 3" },
        blades = { "Tri W_spear_daedric 4" },
        rootIndexes = { 1, 1 }
    }
}

interop:registerWeapons(weapons)