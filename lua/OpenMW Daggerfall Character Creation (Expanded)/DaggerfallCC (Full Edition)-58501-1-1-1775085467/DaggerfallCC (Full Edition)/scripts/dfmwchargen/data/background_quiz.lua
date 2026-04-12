-- background_quiz.lua
-- Data-only background quiz for a Daggerfall-style Morrowind chargen mod.
-- Effect types expected by your applier:
--   skill_bonus      -> { type="skill_bonus", skill="speechcraft", amount=5 }
--   attribute_bonus  -> { type="attribute_bonus", attribute="willpower", amount=3 }
--   gold             -> { type="gold", amount=100 }
--   reward_bundle    -> { type="reward_bundle", id="travel_supplies" }
--   affinity         -> { type="affinity", id="tribunal_temple", amount=2 }
--   tag              -> { type="tag", id="wanderer" }

return {
  version = 1,
  id = "morrowind_background_quiz",

  settings = {
    selection_mode = "all_in_order",
    cumulative_effects = true,
  },

  question_order = {
    "magical_training_primary",
    "magical_training_secondary",
    "motivation",
    "social_upbringing",
    "natural_aptitude",
    "comfort_zone",
    "favored_weapon",
    "armor_and_bearing",
    "first_mark",
    "approach_to_risk",
    "trade_and_livelihood",
    "keepsake",
    "faith_worldview",
    "cultural_affinity",
    "rules_and_necessity",
    "region_origin",
  },

  reward_bundles = {
    apprentice_notes_and_scrolls = {
      description = "A few apprentice notes and basic magical consumables.",
      entries = {
        { kind = "item_template", id = "starter_apprentice_notes", count = 1 },
        { kind = "item_template", id = "starter_apprentice_scroll", count = 2 },
      },
    },
    travel_supplies = {
      description = "Rations, fatigue recovery, and an emergency escape scroll.",
      entries = {
        { kind = "item_template", id = "starter_ration", count = 3 },
        { kind = "item_template", id = "starter_fatigue_potion", count = 2 },
        { kind = "item_template", id = "starter_annotated_map", count = 1 },
      },
    },
    healer_kit = {
      description = "Minor healing and disease treatment supplies.",
      entries = {
        { kind = "item_template", id = "starter_restore_health_potion", count = 2 },
        { kind = "item_template", id = "starter_cure_common_disease_potion", count = 1 },
      },
    },
    starter_long_blade = { description = "An iron longsword and a stamina potion.", entries = { { kind = "item_template", id = "starter_long_blade", count = 1 }, { kind = "item_template", id = "starter_fatigue_potion", count = 1 } } },
    starter_short_blade = { description = "An iron tanto and a stamina potion.", entries = { { kind = "item_template", id = "starter_short_blade", count = 1 }, { kind = "item_template", id = "starter_fatigue_potion", count = 1 } } },
    starter_spear = { description = "An iron spear and a stamina potion.", entries = { { kind = "item_template", id = "starter_spear", count = 1 }, { kind = "item_template", id = "starter_fatigue_potion", count = 1 } } },
    starter_axe = { description = "An iron battle axe and a stamina potion.", entries = { { kind = "item_template", id = "starter_axe", count = 1 }, { kind = "item_template", id = "starter_fatigue_potion", count = 1 } } },
    starter_blunt = { description = "An iron mace and a stamina potion.", entries = { { kind = "item_template", id = "starter_blunt", count = 1 }, { kind = "item_template", id = "starter_fatigue_potion", count = 1 } } },
    starter_marksman_pack = {
      description = "A basic ranged weapon and a little ammunition.",
      entries = {
        { kind = "item_template", id = "starter_bow", count = 1 },
        { kind = "item_template", id = "starter_arrow", count = 25 },
      },
    },
    starter_hand_to_hand_pack = {
      description = "Supplies for an unarmed brawler: boots, potions, and grit.",
      entries = {
        { kind = "item_template", id = "starter_fatigue_potion", count = 2 },
        { kind = "item_template", id = "starter_restore_health_potion", count = 2 },
        { kind = "item_template", id = "starter_light_boots", count = 1 },
      },
    },
    starter_heavy_armor = {
      description = "A small heavy armor starter set.",
      entries = {
        { kind = "item_template", id = "starter_heavy_cuirass", count = 1 },
        { kind = "item_template", id = "starter_heavy_helm", count = 1 },
      },
    },
    starter_light_armor = {
      description = "A small light armor starter set.",
      entries = {
        { kind = "item_template", id = "starter_light_cuirass", count = 1 },
        { kind = "item_template", id = "starter_light_boots", count = 1 },
      },
    },
    starter_unarmored_pack = {
      description = "Shield scrolls, fatigue support, and healing for the unarmored.",
      entries = {
        { kind = "item_template", id = "starter_shield_scroll", count = 3 },
        { kind = "item_template", id = "starter_fatigue_potion", count = 3 },
        { kind = "item_template", id = "starter_restore_health_potion", count = 3 },
      },
    },
    starter_shield = {
      description = "A basic shield and a healing potion.",
      entries = {
        { kind = "item_template", id = "starter_shield", count = 1 },
        { kind = "item_template", id = "starter_restore_health_potion", count = 1 },
      },
    },
    hedge_mage_pack = {
      description = "Simple arcane tools for a practical mage.",
      entries = {
        { kind = "item_template", id = "starter_petty_soul_gem", count = 1 },
        { kind = "item_template", id = "starter_magicka_potion", count = 2 },
      },
    },
    caravan_guard_kit = {
      description = "Repair gear, rations, healing, and a sidearm for a road guard.",
      entries = {
        { kind = "item_template", id = "starter_repair_hammer", count = 1 },
        { kind = "item_template", id = "starter_ration", count = 2 },
        { kind = "item_template", id = "starter_restore_health_potion", count = 1 },
        { kind = "item_template", id = "starter_dagger", count = 1 },
      },
    },
    laborer_kit = {
      description = "Repair gear, rations, stamina support, and a little healing.",
      entries = {
        { kind = "item_template", id = "starter_repair_hammer", count = 1 },
        { kind = "item_template", id = "starter_ration", count = 3 },
        { kind = "item_template", id = "starter_fatigue_potion", count = 3 },
        { kind = "item_template", id = "starter_restore_health_potion", count = 1 },
      },
    },
    courier_smuggler_kit = {
      description = "Tools and a dubious package.",
      entries = {
        { kind = "item_template", id = "starter_lockpick", count = 5 },
        { kind = "item_template", id = "starter_probe", count = 3 },
        { kind = "item_template", id = "starter_sealed_package", count = 1 },
      },
    },
    temple_pilgrim_kit = {
      description = "A token of faith and a little healing.",
      entries = {
        { kind = "item_template", id = "starter_blessed_charm", count = 1 },
        { kind = "item_template", id = "starter_restore_health_potion", count = 1 },
      },
    },
    scribe_kit = {
      description = "Writing supplies and copied notes.",
      entries = {
        { kind = "item_template", id = "starter_field_notes", count = 1 },
        { kind = "item_template", id = "starter_writing_kit", count = 1 },
      },
    },
    thief_tools = {
      description = "A proper set of low-grade burglar's tools.",
      entries = {
        { kind = "item_template", id = "starter_lockpick", count = 10 },
        { kind = "item_template", id = "starter_probe", count = 5 },
      },
    },
    heirloom_blade = { description = "A family weapon kept in fair condition.", entries = { { kind = "item_template", id = "starter_heirloom_blade", count = 1 } } },
    heirloom_ebony_dagger = { description = "An ancient ebony dagger, dark and razor-keen.", entries = { { kind = "item_template", id = "starter_ebony_dagger", count = 1 } } },
    blessed_charm = {
      description = "A minor blessed token and a little protection.",
      entries = {
        { kind = "item_template", id = "starter_blessed_charm", count = 1 },
        { kind = "item_template", id = "starter_cure_common_disease_potion", count = 1 },
      },
    },
    map_and_notes = {
      description = "An annotated map and travel notes.",
      entries = {
        { kind = "item_template", id = "starter_annotated_map", count = 1 },
        { kind = "item_template", id = "starter_field_notes", count = 1 },
      },
    },
    strange_heirloom = { description = "An odd heirloom with unclear purpose.", entries = { { kind = "item_template", id = "starter_strange_heirloom", count = 1 } } },
    rooftop_kit = {
      description = "Soft shoes, lockpicks, and fatigue support for agile work.",
      entries = {
        { kind = "item_template", id = "starter_soft_shoes", count = 1 },
        { kind = "item_template", id = "starter_fatigue_potion", count = 2 },
        { kind = "item_template", id = "starter_lockpick", count = 5 },
      },
    },
    scout_kit = {
      description = "Light scouting supplies.",
      entries = {
        { kind = "item_template", id = "starter_bow", count = 1 },
        { kind = "item_template", id = "starter_arrow", count = 15 },
        { kind = "item_template", id = "starter_ration", count = 2 },
      },
    },
    shadow_apprentice_kit = {
      description = "A few tools from an old mentor.",
      entries = {
        { kind = "item_template", id = "starter_lockpick", count = 5 },
        { kind = "item_template", id = "starter_short_blade", count = 1 },
      },
    },
    patient_thief_kit = {
      description = "Supplies for the careful operator.",
      entries = {
        { kind = "item_template", id = "starter_lockpick", count = 3 },
        { kind = "item_template", id = "starter_probe", count = 3 },
        { kind = "item_template", id = "starter_fatigue_potion", count = 2 },
      },
    },
  },

  questions = {
    {
      id = "magical_training_primary",
      specialization = "magic",
      prompt = "During your apprenticeship, your master set a trial before you. What did you do?",
      options = {
        { id = "alteration", text = "I reshaped the barriers holding me and walked free", effects = { { type = "skill_bonus", skill = "alteration", amount = 5 }, { type = "affinity", id = "mages_guild", amount = 1 }, { type = "tag", id = "trained_alteration" } } },
        { id = "conjuration", text = "I called forth a guardian from beyond the veil to aid me", effects = { { type = "skill_bonus", skill = "conjuration", amount = 5 }, { type = "affinity", id = "mages_guild", amount = 1 }, { type = "tag", id = "trained_conjuration" } } },
        { id = "destruction", text = "I burned through every obstacle in my path", effects = { { type = "skill_bonus", skill = "destruction", amount = 5 }, { type = "affinity", id = "mages_guild", amount = 1 }, { type = "tag", id = "trained_destruction" } } },
        { id = "illusion", text = "I convinced the wardens they had already released me", effects = { { type = "skill_bonus", skill = "illusion", amount = 5 }, { type = "affinity", id = "mages_guild", amount = 1 }, { type = "tag", id = "trained_illusion" } } },
        { id = "mysticism", text = "I unraveled the enchantments binding the trial itself", effects = { { type = "skill_bonus", skill = "mysticism", amount = 5 }, { type = "affinity", id = "mages_guild", amount = 1 }, { type = "tag", id = "trained_mysticism" } } },
        { id = "restoration", text = "I mended my wounds and outlasted every trap", effects = { { type = "skill_bonus", skill = "restoration", amount = 5 }, { type = "affinity", id = "mages_guild", amount = 1 }, { type = "tag", id = "trained_restoration" } } },
      },
    },
    {
      id = "magical_training_secondary",
      specialization = "magic",
      prompt = "What first drew you to the study of magic?",
      options = {
        { id = "alteration", text = "The desire to reshape the world around me", effects = { { type = "skill_bonus", skill = "alteration", amount = 3 }, { type = "tag", id = "favored_alteration" } } },
        { id = "conjuration", text = "Curiosity about what lies beyond the mundane", effects = { { type = "skill_bonus", skill = "conjuration", amount = 3 }, { type = "tag", id = "favored_conjuration" } } },
        { id = "destruction", text = "The raw power to protect myself and punish my enemies", effects = { { type = "skill_bonus", skill = "destruction", amount = 3 }, { type = "tag", id = "favored_destruction" } } },
        { id = "illusion", text = "The art of bending perception — truth is what you make it", effects = { { type = "skill_bonus", skill = "illusion", amount = 3 }, { type = "tag", id = "favored_illusion" } } },
        { id = "mysticism", text = "A hunger to understand the forces that bind all things", effects = { { type = "skill_bonus", skill = "mysticism", amount = 3 }, { type = "tag", id = "favored_mysticism" } } },
        { id = "restoration", text = "Compassion — I saw suffering and wanted the power to end it", effects = { { type = "skill_bonus", skill = "restoration", amount = 3 }, { type = "tag", id = "favored_restoration" } } },
      },
    },
    {
      id = "motivation",
      prompt = "What drew you to Vvardenfell and a life of danger?",
      options = {
        { id = "wealth", text = "Wealth", effects = { { type = "gold", amount = 100 }, { type = "skill_bonus", skill = "mercantile", amount = 5 }, { type = "tag", id = "wealth_driven" } } },
        { id = "reputation", text = "Reputation", effects = { { type = "skill_bonus", skill = "speechcraft", amount = 5 }, { type = "attribute_bonus", attribute = "personality", amount = 3 }, { type = "tag", id = "renown_seeker" } } },
        { id = "forbidden_knowledge", text = "Forbidden knowledge", effects = { { type = "skill_bonus", skill = "enchant", amount = 5 }, { type = "reward_bundle", id = "apprentice_notes_and_scrolls" }, { type = "affinity", id = "house_telvanni", amount = 1 }, { type = "tag", id = "lore_seeker" } } },
        { id = "wanderlust", text = "Wanderlust", effects = { { type = "skill_bonus", skill = "athletics", amount = 5 }, { type = "attribute_bonus", attribute = "speed", amount = 3 }, { type = "reward_bundle", id = "travel_supplies" }, { type = "tag", id = "wanderer" } } },
        { id = "duty", text = "Duty", effects = { { type = "skill_bonus", skill = "restoration", amount = 5 }, { type = "attribute_bonus", attribute = "willpower", amount = 3 }, { type = "tag", id = "dutiful" } } },
        { id = "escape", text = "Escape from your past", effects = { { type = "skill_bonus", skill = "sneak", amount = 5 }, { type = "skill_bonus", skill = "security", amount = 3 }, { type = "tag", id = "fugitive_past" } } },
      },
    },
    {
      id = "social_upbringing",
      prompt = "In your youth, you spent most of your free time...",
      options = {
        { id = "traders", text = "Speaking with traders and haggling in the market", effects = { { type = "skill_bonus", skill = "mercantile", amount = 5 }, { type = "skill_bonus", skill = "speechcraft", amount = 3 }, { type = "affinity", id = "house_hlaalu", amount = 1 } } },
        { id = "tales", text = "Listening to travelers' tales in inns and cornerclubs", effects = { { type = "skill_bonus", skill = "speechcraft", amount = 5 }, { type = "affinity", id = "imperial_cult", amount = 1 }, { type = "tag", id = "well_traveled_ears" } } },
        { id = "rooftops", text = "Training your body on rooftops, walls, and riverbanks", effects = { { type = "skill_bonus", skill = "acrobatics", amount = 5 }, { type = "skill_bonus", skill = "athletics", amount = 3 } } },
        { id = "stories_and_saints", text = "Studying old stories, saints, and local customs", effects = { { type = "skill_bonus", skill = "speechcraft", amount = 5 }, { type = "skill_bonus", skill = "restoration", amount = 3 }, { type = "affinity", id = "tribunal_temple", amount = 1 } } },
        { id = "hard_labor", text = "Helping with hard labor and camp work", effects = { { type = "skill_bonus", skill = "athletics", amount = 5 }, { type = "skill_bonus", skill = "armorer", amount = 3 } } },
        { id = "unnoticed", text = "Learning how to get by without being noticed", effects = { { type = "skill_bonus", skill = "sneak", amount = 5 }, { type = "skill_bonus", skill = "security", amount = 3 } } },
      },
    },
    {
      id = "natural_aptitude",
      prompt = "Even as a child, you were known for being...",
      options = {
        { id = "stronger", text = "Stronger", effects = { { type = "attribute_bonus", attribute = "strength", amount = 3 } } },
        { id = "quicker", text = "Quicker", effects = { { type = "attribute_bonus", attribute = "speed", amount = 3 } } },
        { id = "tougher", text = "Tougher", effects = { { type = "attribute_bonus", attribute = "endurance", amount = 3 } } },
        { id = "more_graceful", text = "More graceful", effects = { { type = "attribute_bonus", attribute = "agility", amount = 3 } } },
        { id = "more_willful", text = "More willful", effects = { { type = "attribute_bonus", attribute = "willpower", amount = 3 } } },
        { id = "more_charming", text = "More charming", effects = { { type = "attribute_bonus", attribute = "personality", amount = 3 } } },
      },
    },
    {
      id = "comfort_zone",
      prompt = "You feel most at ease...",
      options = {
        { id = "market", text = "In a crowded market", effects = { { type = "skill_bonus", skill = "mercantile", amount = 5 }, { type = "skill_bonus", skill = "speechcraft", amount = 3 }, { type = "affinity", id = "house_hlaalu", amount = 1 } } },
        { id = "road", text = "On the open road", effects = { { type = "skill_bonus", skill = "athletics", amount = 5 }, { type = "skill_bonus", skill = "acrobatics", amount = 3 } } },
        { id = "temple", text = "In temple silence", effects = { { type = "skill_bonus", skill = "restoration", amount = 5 }, { type = "skill_bonus", skill = "mysticism", amount = 3 }, { type = "affinity", id = "tribunal_temple", amount = 1 } } },
        { id = "library", text = "In a library or wizard's tower", effects = { { type = "skill_bonus", skill = "mysticism", amount = 5 }, { type = "skill_bonus", skill = "alchemy", amount = 3 }, { type = "affinity", id = "mages_guild", amount = 1 } } },
        { id = "wilds", text = "In the wilds far from town", effects = { { type = "skill_bonus", skill = "marksman", amount = 5 }, { type = "skill_bonus", skill = "athletics", amount = 3 }, { type = "affinity", id = "fighters_guild", amount = 1 } } },
        { id = "shadows", text = "In the shadows where others do not look", effects = { { type = "skill_bonus", skill = "sneak", amount = 5 }, { type = "skill_bonus", skill = "security", amount = 3 }, { type = "affinity", id = "thieves_guild", amount = 1 } } },
      },
    },
    {
      id = "favored_weapon",
      specialization = "combat",
      prompt = "Where does your greatest skill in combat lie?",
      options = {
        { id = "long_blade", text = "Long Blade", effects = { { type = "skill_bonus", skill = "longblade", amount = 5 }, { type = "reward_bundle", id = "starter_long_blade" } } },
        { id = "short_blade", text = "Short Blade", effects = { { type = "skill_bonus", skill = "shortblade", amount = 5 }, { type = "reward_bundle", id = "starter_short_blade" } } },
        { id = "spear", text = "Spear", effects = { { type = "skill_bonus", skill = "spear", amount = 5 }, { type = "reward_bundle", id = "starter_spear" } } },
        { id = "axe", text = "Axe", effects = { { type = "skill_bonus", skill = "axe", amount = 5 }, { type = "reward_bundle", id = "starter_axe" } } },
        { id = "blunt_weapon", text = "Blunt Weapon", effects = { { type = "skill_bonus", skill = "bluntweapon", amount = 5 }, { type = "reward_bundle", id = "starter_blunt" } } },
        { id = "marksman", text = "Marksman", effects = { { type = "skill_bonus", skill = "marksman", amount = 5 }, { type = "reward_bundle", id = "starter_marksman_pack" } } },
        { id = "hand_to_hand", text = "Hand-to-Hand", effects = { { type = "skill_bonus", skill = "handtohand", amount = 5 }, { type = "reward_bundle", id = "starter_hand_to_hand_pack" } } },
      },
    },
    {
      id = "armor_and_bearing",
      specialization = "combat",
      prompt = "When trouble starts, you trust most in...",
      options = {
        { id = "heavy_armor", text = "Heavy armor and discipline", effects = { { type = "skill_bonus", skill = "heavyarmor", amount = 5 }, { type = "attribute_bonus", attribute = "endurance", amount = 3 }, { type = "reward_bundle", id = "starter_heavy_armor" } } },
        { id = "light_armor", text = "Light armor and quickness", effects = { { type = "skill_bonus", skill = "lightarmor", amount = 5 }, { type = "attribute_bonus", attribute = "speed", amount = 3 }, { type = "reward_bundle", id = "starter_light_armor" } } },
        { id = "unarmored", text = "No armor at all, only agility", effects = { { type = "skill_bonus", skill = "unarmored", amount = 5 }, { type = "skill_bonus", skill = "acrobatics", amount = 3 }, { type = "reward_bundle", id = "starter_unarmored_pack" } } },
        { id = "shield", text = "A shield and a firm stance", effects = { { type = "skill_bonus", skill = "block", amount = 5 }, { type = "skill_bonus", skill = "heavyarmor", amount = 3 }, { type = "reward_bundle", id = "starter_shield" } } },
        { id = "distance", text = "Distance and careful aim", effects = { { type = "skill_bonus", skill = "marksman", amount = 5 }, { type = "skill_bonus", skill = "sneak", amount = 3 }, { type = "reward_bundle", id = "starter_marksman_pack" } } },
        { id = "magic", text = "Magic before steel", effects = { { type = "skill_bonus", skill = "enchant", amount = 5 }, { type = "attribute_bonus", attribute = "willpower", amount = 3 }, { type = "reward_bundle", id = "hedge_mage_pack" } } },
      },
    },
    {
      id = "trade_and_livelihood",
      prompt = "Before fortune or fate swept you onward, you earned your keep by...",
      options = {
        { id = "caravan_guard", text = "Guarding caravans and merchants", effects = { { type = "skill_bonus", skill = "longblade", amount = 5 }, { type = "skill_bonus", skill = "mercantile", amount = 3 }, { type = "affinity", id = "house_redoran", amount = 1 }, { type = "reward_bundle", id = "caravan_guard_kit" } } },
        { id = "odd_jobs", text = "Doing odd jobs in town and camp", effects = { { type = "skill_bonus", skill = "athletics", amount = 5 }, { type = "skill_bonus", skill = "armorer", amount = 3 }, { type = "gold", amount = 50 }, { type = "reward_bundle", id = "laborer_kit" } } },
        { id = "messages_and_contraband", text = "Carrying messages and contraband", effects = { { type = "skill_bonus", skill = "sneak", amount = 5 }, { type = "skill_bonus", skill = "security", amount = 3 }, { type = "reward_bundle", id = "courier_smuggler_kit" } } },
        { id = "temple_service", text = "Serving a Temple or shrine", effects = { { type = "skill_bonus", skill = "restoration", amount = 5 }, { type = "skill_bonus", skill = "speechcraft", amount = 3 }, { type = "affinity", id = "tribunal_temple", amount = 1 }, { type = "reward_bundle", id = "temple_pilgrim_kit" } } },
        { id = "copying_notes", text = "Copying notes, ledgers, and inventories", effects = { { type = "skill_bonus", skill = "mercantile", amount = 5 }, { type = "skill_bonus", skill = "speechcraft", amount = 3 }, { type = "reward_bundle", id = "scribe_kit" } } },
        { id = "recovering_misplaced", text = "Recovering things others had 'misplaced'", effects = { { type = "skill_bonus", skill = "security", amount = 5 }, { type = "skill_bonus", skill = "shortblade", amount = 3 }, { type = "reward_bundle", id = "thief_tools" } } },
      },
    },
    {
      id = "keepsake",
      prompt = "Before you left home, you carried with you...",
      options = {
        { id = "family_blade", text = "A family blade", effects = { { type = "skill_bonus", skill = "longblade", amount = 3 }, { type = "reward_bundle", id = "heirloom_blade" }, { type = "affinity", id = "house_redoran", amount = 1 }, { type = "tag", id = "family_blade" } } },
        { id = "ebony_dagger", text = "An ebony dagger, passed down through generations", requires_record = { type = "weapon", id = "T_De_Ebony_Dagger_01" }, effects = { { type = "skill_bonus", skill = "shortblade", amount = 5 }, { type = "reward_bundle", id = "heirloom_ebony_dagger" }, { type = "tag", id = "ebony_dagger" } } },
        { id = "blessed_charm", text = "A charm blessed by a priest", effects = { { type = "skill_bonus", skill = "restoration", amount = 3 }, { type = "reward_bundle", id = "blessed_charm" } } },
        { id = "map_and_notes", text = "A handwritten map and a few notes", effects = { { type = "skill_bonus", skill = "athletics", amount = 3 }, { type = "skill_bonus", skill = "mysticism", amount = 3 }, { type = "reward_bundle", id = "map_and_notes" } } },
        { id = "lockpick_and_probe", text = "A lockpick and a spare probe", effects = { { type = "skill_bonus", skill = "security", amount = 5 }, { type = "reward_bundle", id = "thief_tools" } } },
        { id = "pouch_of_drakes", text = "A pouch of drakes", effects = { { type = "gold", amount = 150 }, { type = "skill_bonus", skill = "mercantile", amount = 3 } } },
        { id = "uncertain_heirloom", text = "A ring, amulet, or heirloom of uncertain worth", effects = { { type = "skill_bonus", skill = "enchant", amount = 3 }, { type = "reward_bundle", id = "strange_heirloom" }, { type = "tag", id = "strange_heirloom" } } },
      },
    },
    {
      id = "faith_worldview",
      prompt = "Whose wisdom do you trust when life turns cruel?",
      options = {
        { id = "tribunal", text = "The Tribunal and their saints", effects = { { type = "skill_bonus", skill = "restoration", amount = 5 }, { type = "skill_bonus", skill = "mysticism", amount = 3 }, { type = "tag", id = "tribunal_faith" } } },
        { id = "nine_divines", text = "The Nine and the Imperial Cult", effects = { { type = "skill_bonus", skill = "speechcraft", amount = 5 }, { type = "skill_bonus", skill = "restoration", amount = 3 }, { type = "affinity", id = "imperial_cult", amount = 1 }, { type = "tag", id = "imperial_faith" } } },
        { id = "ancestors", text = "Your ancestors, and the old ways", effects = { { type = "skill_bonus", skill = "mysticism", amount = 5 }, { type = "skill_bonus", skill = "spear", amount = 3 }, { type = "affinity", id = "fighters_guild", amount = 1 }, { type = "tag", id = "ancestor_reverence" } } },
        { id = "mages_and_scholars", text = "The words of mages and scholars", effects = { { type = "skill_bonus", skill = "mysticism", amount = 5 }, { type = "skill_bonus", skill = "enchant", amount = 3 }, { type = "affinity", id = "mages_guild", amount = 1 }, { type = "tag", id = "scholarly_worldview" } } },
        { id = "coin_and_steel", text = "Coin, steel, and your own judgment", effects = { { type = "skill_bonus", skill = "mercantile", amount = 5 }, { type = "skill_bonus", skill = "longblade", amount = 3 }, { type = "tag", id = "pragmatist" } } },
        { id = "whatever_answers", text = "Whatever power answers when called", effects = { { type = "skill_bonus", skill = "conjuration", amount = 5 }, { type = "skill_bonus", skill = "mysticism", amount = 3 }, { type = "tag", id = "daedric_curiosity" } } },
      },
    },
    {
      id = "cultural_affinity",
      prompt = "Before your arrest, what sort of company did you keep?",
      options = {
        { id = "hlaalu", text = "Merchants and negotiators — coin speaks every language", effects = { { type = "skill_bonus", skill = "mercantile", amount = 5 }, { type = "skill_bonus", skill = "speechcraft", amount = 3 }, { type = "affinity", id = "house_hlaalu", amount = 1 } } },
        { id = "redoran", text = "Soldiers and men-at-arms who valued honor and discipline", effects = { { type = "skill_bonus", skill = "longblade", amount = 5 }, { type = "skill_bonus", skill = "heavyarmor", amount = 3 }, { type = "affinity", id = "house_redoran", amount = 1 } } },
        { id = "telvanni", text = "Reclusive scholars who prized knowledge above all else", effects = { { type = "skill_bonus", skill = "enchant", amount = 5 }, { type = "skill_bonus", skill = "mysticism", amount = 3 }, { type = "affinity", id = "house_telvanni", amount = 1 } } },
        { id = "imperials", text = "Bureaucrats and functionaries of the Empire", effects = { { type = "skill_bonus", skill = "speechcraft", amount = 5 }, { type = "skill_bonus", skill = "longblade", amount = 3 }, { type = "affinity", id = "imperial_service", amount = 1 } } },
        { id = "temple_faithful", text = "The devout — priests, healers, and the faithful", effects = { { type = "skill_bonus", skill = "restoration", amount = 5 }, { type = "skill_bonus", skill = "speechcraft", amount = 3 } } },
        { id = "adventurers", text = "Mercenaries, sellswords, and fellow adventurers", effects = { { type = "skill_bonus", skill = "spear", amount = 5 }, { type = "skill_bonus", skill = "athletics", amount = 3 }, { type = "affinity", id = "fighters_guild", amount = 1 } } },
        { id = "rogues", text = "Cutpurses, fences, and those who work in shadow", effects = { { type = "skill_bonus", skill = "sneak", amount = 5 }, { type = "skill_bonus", skill = "security", amount = 3 }, { type = "affinity", id = "thieves_guild", amount = 1 } } },
        { id = "pilgrims", text = "Missionaries, healers, and pilgrims of the Nine Divines", effects = { { type = "skill_bonus", skill = "speechcraft", amount = 5 }, { type = "skill_bonus", skill = "restoration", amount = 3 }, { type = "affinity", id = "imperial_cult", amount = 1 } } },
      },
    },
    {
      id = "rules_and_necessity",
      prompt = "When someone stood in your way, you have always been the sort to...",
      options = {
        { id = "head_on", text = "Meet them head-on and settle it plainly", effects = { { type = "skill_bonus", skill = "longblade", amount = 5 }, { type = "attribute_bonus", attribute = "strength", amount = 3 }, { type = "affinity", id = "imperial_service", amount = 1 }, { type = "tag", id = "direct" } } },
        { id = "common_ground", text = "Find common ground and turn an enemy into an ally", effects = { { type = "skill_bonus", skill = "speechcraft", amount = 5 }, { type = "skill_bonus", skill = "restoration", amount = 3 }, { type = "tag", id = "peacemaker" } } },
        { id = "go_around", text = "Go around them without their knowing", effects = { { type = "skill_bonus", skill = "sneak", amount = 5 }, { type = "skill_bonus", skill = "acrobatics", amount = 3 }, { type = "tag", id = "indirect" } } },
        { id = "outwait", text = "Outwait them — patience outlasts stubbornness", effects = { { type = "skill_bonus", skill = "marksman", amount = 5 }, { type = "attribute_bonus", attribute = "endurance", amount = 3 }, { type = "tag", id = "patient" } } },
        { id = "offer_trade", text = "Learn what they valued and offer a trade", effects = { { type = "skill_bonus", skill = "mercantile", amount = 5 }, { type = "skill_bonus", skill = "enchant", amount = 3 }, { type = "tag", id = "dealmaker" } } },
        { id = "seek_counsel", text = "Seek counsel from someone wiser or more powerful", effects = { { type = "skill_bonus", skill = "mysticism", amount = 5 }, { type = "skill_bonus", skill = "speechcraft", amount = 3 }, { type = "affinity", id = "house_telvanni", amount = 1 } } },
      },
    },
    {
      id = "region_origin",
      prompt = "What sort of land did you grow up in?",
      options = {
        { id = "port_town", text = "A bustling port city, full of foreign ships and trade", effects = { { type = "skill_bonus", skill = "speechcraft", amount = 5 }, { type = "skill_bonus", skill = "mercantile", amount = 3 } } },
        { id = "house_city", text = "A wealthy city ruled by old families and noble politics", effects = { { type = "skill_bonus", skill = "speechcraft", amount = 5 }, { type = "tag", id = "house_city_born" } } },
        { id = "temple_settlement", text = "A quiet settlement built around a temple or shrine", effects = { { type = "skill_bonus", skill = "restoration", amount = 5 }, { type = "skill_bonus", skill = "mysticism", amount = 3 } } },
        { id = "fort_or_garrison", text = "A military outpost or garrison town on the frontier", effects = { { type = "skill_bonus", skill = "longblade", amount = 5 }, { type = "skill_bonus", skill = "block", amount = 3 }, { type = "affinity", id = "imperial_service", amount = 1 } } },
        { id = "wilderness", text = "Open wilderness, far from any settlement", effects = { { type = "skill_bonus", skill = "spear", amount = 5 }, { type = "skill_bonus", skill = "athletics", amount = 3 } } },
        { id = "swamp_coast", text = "Marshy lowlands or a rain-soaked coast", effects = { { type = "skill_bonus", skill = "alchemy", amount = 5 }, { type = "skill_bonus", skill = "athletics", amount = 3 }, { type = "tag", id = "coastwise" } } },
      },
    },
    {
      id = "first_mark",
      specialization = "stealth",
      prompt = "You learned early that survival meant seeing what others missed. What did you learn to watch for?",
      options = {
        { id = "exits", text = "Exits, angles, and the quickest way out of any room", effects = { { type = "skill_bonus", skill = "acrobatics", amount = 5 }, { type = "skill_bonus", skill = "sneak", amount = 3 }, { type = "reward_bundle", id = "rooftop_kit" } } },
        { id = "faces", text = "Faces — who is lying, who is afraid, who can be swayed", effects = { { type = "skill_bonus", skill = "speechcraft", amount = 5 }, { type = "skill_bonus", skill = "illusion", amount = 3 }, { type = "tag", id = "reads_people" } } },
        { id = "hands", text = "Hands and pockets — where valuables rest and keys hang", effects = { { type = "skill_bonus", skill = "security", amount = 5 }, { type = "skill_bonus", skill = "sneak", amount = 3 }, { type = "reward_bundle", id = "thief_tools" }, { type = "affinity", id = "thieves_guild", amount = 1 } } },
        { id = "terrain", text = "Terrain — trails, cover, and the shape of the land ahead", effects = { { type = "skill_bonus", skill = "athletics", amount = 5 }, { type = "skill_bonus", skill = "marksman", amount = 3 }, { type = "reward_bundle", id = "scout_kit" } } },
        { id = "silence", text = "Silence — when it falls wrong, trouble is close", effects = { { type = "skill_bonus", skill = "sneak", amount = 5 }, { type = "skill_bonus", skill = "shortblade", amount = 3 }, { type = "reward_bundle", id = "shadow_apprentice_kit" } } },
        { id = "patterns", text = "Patterns — guard shifts, merchant habits, the rhythm of a town", effects = { { type = "skill_bonus", skill = "sneak", amount = 5 }, { type = "skill_bonus", skill = "mercantile", amount = 3 }, { type = "gold", amount = 50 }, { type = "tag", id = "patient_observer" } } },
      },
    },
    {
      id = "approach_to_risk",
      specialization = "stealth",
      prompt = "When you must pass through unfamiliar or hostile ground, you rely most on...",
      options = {
        { id = "light_feet", text = "Light feet and knowing where not to step", effects = { { type = "skill_bonus", skill = "sneak", amount = 5 }, { type = "skill_bonus", skill = "acrobatics", amount = 3 }, { type = "reward_bundle", id = "rooftop_kit" } } },
        { id = "local_custom", text = "Local custom — dress right, speak right, and belong", effects = { { type = "skill_bonus", skill = "speechcraft", amount = 5 }, { type = "skill_bonus", skill = "mercantile", amount = 3 }, { type = "tag", id = "blends_in" } } },
        { id = "prepared_tools", text = "Prepared tools and a way through every door", effects = { { type = "skill_bonus", skill = "security", amount = 5 }, { type = "skill_bonus", skill = "sneak", amount = 3 }, { type = "reward_bundle", id = "patient_thief_kit" } } },
        { id = "speed", text = "Speed — move fast and never linger", effects = { { type = "skill_bonus", skill = "athletics", amount = 5 }, { type = "skill_bonus", skill = "acrobatics", amount = 3 }, { type = "attribute_bonus", attribute = "speed", amount = 3 } } },
        { id = "misdirection", text = "Misdirection and a few well-chosen words", effects = { { type = "skill_bonus", skill = "illusion", amount = 5 }, { type = "skill_bonus", skill = "speechcraft", amount = 3 }, { type = "tag", id = "misdirection" } } },
        { id = "sharp_eyes", text = "Sharp eyes and a blade kept close", effects = { { type = "skill_bonus", skill = "marksman", amount = 5 }, { type = "skill_bonus", skill = "shortblade", amount = 3 }, { type = "reward_bundle", id = "shadow_apprentice_kit" } } },
      },
    },
  },
}
