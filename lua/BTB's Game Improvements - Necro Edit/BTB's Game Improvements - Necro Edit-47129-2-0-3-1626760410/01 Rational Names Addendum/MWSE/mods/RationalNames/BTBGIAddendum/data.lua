local this = {}

this.components = {
    tes3.objectType.clothing,
    tes3.objectType.alchemy,
    tes3.objectType.book,
}

this.baseNames = {}

this.baseNames[tes3.objectType.clothing] = {
    ["amulet of light"] = "Night-Eye Amulet",
}

this.baseNames[tes3.objectType.alchemy] = {
    ["p_burden_b"] = "Slowfall I",
    ["p_burden_c"] = "Slowfall II",
    ["p_burden_e"] = "Slowfall V",
    ["p_burden_q"] = "Slowfall IV",
    ["p_burden_s"] = "Slowfall III",
    ["p_chameleon_b"] = "Resist Blight I",
    ["p_chameleon_c"] = "Resist Blight II",
    ["p_chameleon_e"] = "Resist Blight V",
    ["p_chameleon_q"] = "Resist Blight IV",
    ["p_chameleon_s"] = "Resist Blight III",
    ["p_cure_paralyzation_s"] = "Resist Paralysis III",
    ["p_drain willpower_q"] = "Spoiled Potion",
    ["p_drain_agility_q"] = "Spoiled Potion",
    ["p_drain_endurance_q"] = "Spoiled Potion",
    ["p_drain_intelligence_q"] = "Spoiled Potion",
    ["p_drain_luck_q"] = "Spoiled Potion",
    ["p_drain_magicka_q"] = "Spoiled Potion",
    ["p_drain_personality_q"] = "Spoiled Potion",
    ["p_drain_speed_q"] = "Spoiled Potion",
    ["p_drain_strength_q"] = "Spoiled Potion",
    ["p_fortify_attack_e"] = "Fortify Attack V",
    ["p_fortify_intelligence_b"] = "Shield I",
    ["p_fortify_intelligence_c"] = "Shield II",
    ["p_fortify_intelligence_e"] = "Shield V",
    ["p_fortify_intelligence_q"] = "Shield IV",
    ["p_fortify_intelligence_s"] = "Shield III",
    ["p_fortify_luck_b"] = "Sanctuary I",
    ["p_fortify_luck_c"] = "Sanctuary II",
    ["p_fortify_luck_e"] = "Sanctuary V",
    ["p_fortify_luck_q"] = "Sanctuary IV",
    ["p_fortify_luck_s"] = "Sanctuary III",
    ["p_invisibility_b"] = "Resist Paralysis I",
    ["p_invisibility_c"] = "Resist Paralysis II",
    ["p_invisibility_e"] = "Resist Paralysis V",
    ["p_invisibility_q"] = "Resist Paralysis IV",
    ["p_invisibility_s"] = "Invisibility",
    ["p_light_b"] = "Fortify Attack I",
    ["p_light_c"] = "Fortify Attack II",
    ["p_light_e"] = "Fortify Attack V",
    ["p_light_q"] = "Fortify Attack IV",
    ["p_light_s"] = "Fortify Attack III",
    ["p_paralyze_b"] = "Water Walking I",
    ["p_paralyze_c"] = "Water Walking II",
    ["p_paralyze_e"] = "Water Walking V",
    ["p_paralyze_q"] = "Water Walking IV",
    ["p_paralyze_s"] = "Feather III",
    ["p_recall_s"] = "Divine Intervention",
    ["p_silence_b"] = "Water Breathing I",
    ["p_silence_c"] = "Water Breathing II",
    ["p_silence_e"] = "Water Breathing V",
    ["p_silence_q"] = "Water Breathing IV",
    ["p_silence_s"] = "Swift Swim III",
    ["p_slowfall_s"] = "Recall",
    ["p_water_breathing_s"] = "Water Breathing III",
    ["p_water_walking_s"] = "Water Walking III",
}

this.baseNames[tes3.objectType.book] = {
    ["sc_summongoldensaint"] = "Summon Storm Atronach",
}

return this