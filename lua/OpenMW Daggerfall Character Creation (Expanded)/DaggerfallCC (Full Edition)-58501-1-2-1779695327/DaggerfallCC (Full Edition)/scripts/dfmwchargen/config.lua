local config = {
  debug = true,
  requireNewGame = true,
  skillPoolTotal = 18,
  majorSkillCap = 6,
  minorSkillCap = 6,
  miscSkillCap = 6,
  lockControls = {
    movement = true,
    fighting = true,
    jumping = true,
    looking = true,
    magic = true,
    viewMode = true,
    vanityMode = true,
  },
  playerSectionName = "DFMWChargenState",

  -- background quiz effect application mappings
  affinityToFaction = {
    mages_guild = "Mages Guild",
    fighters_guild = "Fighters Guild",
    thieves_guild = "Thieves Guild",
    tribunal_temple = "Tribunal Temple",
    imperial_cult = "Imperial Cult",
    house_hlaalu = "Hlaalu",
    house_redoran = "Redoran",
    house_telvanni = "Telvanni",
    imperial_service = "Imperial Legion",
  },

  itemTemplates = {
    -- Scrolls
    starter_apprentice_scroll = "sc_ondusisunhinging",
    starter_apprentice_notes = "sc_purityofbody",
    starter_blessed_charm = "sc_almsiviintervention",
    starter_annotated_map = "sc_divineintervention",
    starter_writing_kit = "sc_ekashslocksplitter",

    -- Potions
    starter_restore_health_potion = "p_restore_health_s",
    starter_cure_common_disease_potion = "p_cure_common_s",
    starter_fatigue_potion = "p_restore_fatigue_s",
    starter_magicka_potion = "p_restore_magicka_s",

    -- Weapons
    starter_long_blade = "iron longsword",
    starter_short_blade = "iron tanto",
    starter_dagger = "iron dagger",
    starter_spear = "iron spear",
    starter_axe = "iron battle axe",
    starter_blunt = "iron mace",
    starter_bow = "chitin short bow",
    starter_arrow = "iron arrow",
    starter_heirloom_blade = "silver longsword",
    starter_ebony_dagger = "T_De_Ebony_Dagger_01",

    -- Heavy armor
    starter_heavy_cuirass = "iron_cuirass",
    starter_heavy_helm = "iron_helmet",
    starter_shield = "iron_shield",

    -- Light armor
    starter_light_cuirass = "chitin cuirass",
    starter_light_boots = "chitin boots",

    -- Clothing
    starter_common_shirt = "common_shirt_01",
    starter_common_pants = "common_pants_01",
    starter_soft_shoes = "common_shoes_02",

    -- Misc
    starter_petty_soul_gem = "misc_soulgem_petty",
    starter_repair_hammer = "repair_prongs",
    starter_ration = "ingred_bread_01",
    starter_lockpick = "pick_apprentice_01",
    starter_probe = "probe_apprentice_01",

    -- Scrolls (defensive)
    starter_shield_scroll = "sc_fourthbarrier",

    -- Flavor items
    starter_sealed_package = "potion_skooma_01",
    starter_field_notes = "bk_guide_to_vvardenfell",
    starter_strange_heirloom = "expensive_ring_01",
  },
}

return config
