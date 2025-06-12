return {
    -- always spawn
    skulls = {
        -- races
        ["khajiit"] = "mor_apparatus_khajiitskull",
        ["argonian"] = "mor_apparatus_argoskull",
        ["orc"] = "mor_apparatus_orcskull",
        ["breton"] = "mor_apparatus_bretonskull",
        ["imperial"] = "mor_apparatus_imperialskull",
        ["nord"] = "mor_apparatus_nordskull",
        ["redguard"] = "mor_apparatus_redguardskull",
        ["wood elf"] = "mor_apparatus_bosskull",
        ["high elf"] = "mor_apparatus_altskull",
        ["dark elf"] = "mor_apparatus_dunskull",
        -- TR races
        ["t_els_ohmes"] = "mor_apparatus_khajiitskull",
        ["t_els_cathay"] = "mor_apparatus_khajiitskull",
        ["t_els_ohmes-raht"] = "mor_apparatus_khajiitskull",
        ["t_els_suthay"] = "mor_apparatus_khajiitskull",
        ["t_els_cathay-raht"] = "mor_apparatus_khajiitskull",
        ["t_sky_reachman"] = "mor_apparatus_nordskull", -- or maybe mor_apparatus_bretonskull ??
        ["t_pya_seaelf"] = "misc_skull00", -- generic skull until something better
        ["fallback"] = "misc_skull00", -- generic skull for mod added races
        -- vampires
        ["vampire"] = "mor_apparatus_vampskull",
        -- special NPCs
        ["vivec_god"] = "mor_apparatus_vivskull",
        ["fargoth"] = "mor_apparatus_fargothskull",
        ["divayth fyr"] = "mor_apparatus_divaythskull",
        ["vedam dren"] = "mor_apparatus_dukeskull",
        ["gothren"] = "mor_apparatus_gothren",
        ["orvas dren"] = "mor_apparatus_orvasskull",
        ["dhaunayne aundae"] = "mor_apparatus_aundaeskull",
        ["raxle berne"] = "mor_apparatus_berneskull",
        ["volrina quarra"] = "mor_apparatus_quarraskull",
        ["dandras vules"] = "mor_apparatus_dbskull",
        ["lalatia varian"] = "mor_apparatus_lalatiaskull",
        ["varus vatinius"] = "mor_apparatus_varusskull",
        ["trebonius artorius"] = "mor_apparatus_trebskull",
        ["eno hlaalu"] = "mor_apparatus_enoskull",
        ["tholer saryoni"] = "mor_apparatus_saryoniskull",
        ["stacey"] = "mor_apparatus_jimskull",
    },
    -- whatever% chance to pick one
    randomParts = {
        -- NPC races
        argonian = {
            "mor_arg_brain",
            "mor_argo_eye",
            "mor_argo_flesh",
            "mor_argo_heart",
            "mor_argo_tail",
            "mor_intestine"
        },
        khajiit = {
            "mor_khajiit_brain",
            "mor_khajiit_ear",
            "mor_khajiit_eye",
            "mor_khajiit_flesh",
            "mor_khajiit_heart",
            "mor_intestine"
        },
        orc = {
            "mor_orc_brain",
            "mor_orc_eye",
            "mor_orc_flesh",
            "mor_orc_heart",
            "mor_intestine"
        },
        breton = {
            "mor_breton_brain",
            "mor_breton_eye",
            "mor_breton_flesh",
            "mor_breton_heart",
            "mor_intestine"
        },
        imperial = {
            "mor_imperial_brain",
            "mor_imperial_eye",
            "mor_imperial_flesh",
            "mor_imperial_heart",
            "mor_imperial_tongue",
            "mor_intestine"
        },
        nord = {
            "mor_nord_bones",
            "mor_nord_brain",
            "mor_nord_flesh",
            "mor_nord_heart",
            "mor_intestine"
        },
        redguard = {
            "mor_redguard_brain",
            "mor_redguard_eye",
            "mor_redguard_flesh",
            "mor_redguard_heart",
            "mor_intestine"
        },
        ["wood elf"] = {
            "mor_bosmer_brain",
            "mor_bosmer_eye",
            "mor_bosmer_flesh",
            "mor_bosmer_heart",
            "mor_intestine"
        },
        ["high elf"] = {
            "mor_altmer_brain",
            "mor_altmer_eye",
            "mor_altmer_heart",
            "mor_altmer_flesh",
            "mor_intestine"
        },
        ["dark elf"] = {
            "mor_dunmer_brain",
            "mor_dunmer_eye",
            "mor_dunmer_flesh",
            "mor_dunmer_heart",
            "mor_intestine"
        },
        -- Tamriel Data
        -- todo: better these
        ["t_els_ohmes"] = {
            "mor_khajiit_brain",
            "mor_khajiit_ear",
            "mor_khajiit_eye",
            "mor_khajiit_flesh",
            "mor_khajiit_heart",
            "mor_intestine"
        },
        ["t_els_cathay"] = {
            "mor_khajiit_brain",
            "mor_khajiit_ear",
            "mor_khajiit_eye",
            "mor_khajiit_flesh",
            "mor_khajiit_heart",
            "mor_intestine"
        },
        ["t_els_ohmes-raht"] = {
            "mor_khajiit_brain",
            "mor_khajiit_ear",
            "mor_khajiit_eye",
            "mor_khajiit_flesh",
            "mor_khajiit_heart",
            "mor_intestine"
        },
        ["t_els_suthay"] = {
            "mor_khajiit_brain",
            "mor_khajiit_ear",
            "mor_khajiit_eye",
            "mor_khajiit_flesh",
            "mor_khajiit_heart",
            "mor_intestine"
        },
        ["t_els_cathay-raht"] = {
            "mor_khajiit_brain",
            "mor_khajiit_ear",
            "mor_khajiit_eye",
            "mor_khajiit_flesh",
            "mor_khajiit_heart",
            "mor_intestine"
        },
        -- Reachmen are descended from Nords and Bretons, so a mix of parts?
        -- since it picks one at random, having all of both is okay
        -- ! fix it if that changes lol
        -- I'm no lore master, so this could probably be better
        ["t_sky_reachman"] = {
            "mor_nord_bones",
            "mor_nord_brain",
            "mor_nord_flesh",
            "mor_nord_heart",
            "mor_breton_brain",
            "mor_breton_eye",
            "mor_breton_flesh",
            "mor_breton_heart",
            "mor_intestine"
        },
        -- Generic parts until something better comes along I guess
        ["t_pya_seaelf"] = {
            "mor_intestine"
        },
        -- todo: better mod added race support
        fallback = {"mor_intestine"},
        -- creatures and such
        sleeper = {"aa_skull_sleeper"},
        ashGhoul = {"aa_skull_ashghoul"},
        ashVampire = {"aa_skull_ashvamp"}
    }
}
