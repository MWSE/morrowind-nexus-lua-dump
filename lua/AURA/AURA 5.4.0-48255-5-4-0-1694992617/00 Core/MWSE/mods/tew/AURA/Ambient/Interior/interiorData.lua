local config = require("tew.AURA.config")
local language = require(config.language)

local this = {}

this.statics = {
    ["aba"] = {
        "in_stronghold",
        "in_strong",
        "in_strongruin",
        "in_sewer",
        "in_m_sewer",
        "dngruin",
        "t_de_dngrtrongh",
        "t_imp_dngsewers",
        "in_om_",
        "dngdirenni",
    },
    ["cav"] = {
        "in_bm_cave",
        "in_moldcave",
        "in_mudcave",
        "in_lavacave",
        "in_pycave",
        "in_bonecave",
        "in_bc_cave",
        "in_m_sewer",
        "in_sewer",
        "ab_in_cave",
        "ab_in_kwama",
        "ab_in_lava",
        "ab_in_mvcave",
        "t_cyr_cavegc",
        "t_cyr_cavech",
        "t_cyr_caveww",
        "t_glb_cave",
        "t_mw_cave",
        "t_sky_cave"
    },
    ["dae"] = {
        "in_dae",
        "t_dae_dngruin"
    },
    ["dwe"] = {
        "in_dwrv_",
        "in_dwe_",
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
