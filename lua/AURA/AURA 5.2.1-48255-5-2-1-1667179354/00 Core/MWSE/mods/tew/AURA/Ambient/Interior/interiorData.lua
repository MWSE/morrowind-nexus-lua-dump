local config = require("tew.AURA.config")
local language = require(config.language)

local this = {}

this.statics = {
    ["aba"] = {
        "in_stronghold",
        "in_strong",
        "in_strongruin",
        "in_sewer",
        "t_ayl_dngruin",
        "t_bre_dngruin",
        "t_de_dngrtrongh",
        "t_he_dngdirenni",
        "t_imp_dngruincyr",
        "t_imp_dngsewers",
        "in_om_",
    },
    ["cav"] = {
        "in_moldcave",
        "in_mudcave",
        "in_lavacave",
        "in_pycave",
        "in_bonecave",
        "in_bc_cave",
        "in_m_sewer",
        "in_sewer",
        "ab_in_kwama",
        "ab_in_lava",
        "ab_in_mvcave",
        "t_cyr_cavegc",
        "t_glb_cave",
        "t_mw_cave",
        "t_sky_cave"
    },
    ["dae"] = {
        "in_dae_hall",
        "in_dae_room",
        "in_dae_pillar",
        "t_dae_dngruin"
    },
    ["dwe"] = {
        "in_dwrv_hall",
        "in_dwrv_corr",
        "in_dwe_corr",
        "in_dwe_archway",
        "t_dwe_dngruin",
    },
    ["ice"] = {
        "bm_ic_",
        "bm_ka",
    },
}

this.names = language.interiorNames
this.tavernNames = language.tavernNames

return this
