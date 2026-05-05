local types = require("openmw.types")
local W     = types.Weapon.TYPE

------------------------------------------------------------
-- MARKSMAN TYPES
------------------------------------------------------------

local MARKSMAN_TYPES = {
    [W.MarksmanBow]      = true,
    [W.MarksmanCrossbow] = true,
    [W.MarksmanThrown]   = true,
}

------------------------------------------------------------
-- CREATURE GROUPS (for sounds/anims only)
------------------------------------------------------------

local wolves = {
    ["bm_wolf_grey"]             = true,
    ["bm_wolf_grey_lvl_1"]       = true,
    ["bm_wolf_red"]              = true,
    ["bm_wolf_snow_unique"]      = true,
    ["t_sky_fau_wolfbla_01"]     = true,
    ["t_sky_fau_wolfblasml_01"]  = true,
    ["t_sky_fau_wolfblads_01"]   = true,
    ["t_sky_fau_wolfgr_01"]      = true,
    ["t_sky_fau_wolfgr_dis_01"]  = true,
    ["t_sky_fau_wolfred_01"]     = true,
    ["t_sky_fau_wolfredds_01"]   = true,
    ["t_cyr_fau_wolfcol_01"]     = true,
    ["t_cyr_fau_wolfcolds_01"]   = true,
    ["t_cyr_fau_wolfcol_02"]     = true,
    ["t_cyr_fau_wolfcolds_02"]   = true,
}

local bears = {
    ["bm_bear_black"]            = true,
    ["bm_bear_brown"]            = true,
    ["bm_bear_snow_unique"]      = true,
    ["t_sky_fau_bearbk_01"]      = true,
    ["t_sky_fau_bearbr_01"]      = true,
    ["t_sky_fau_bearsn_01"]      = true,
    ["t_cyr_fau_bearcol_01"]     = true,
    ["t_cyr_fau_bearcolids_01"]  = true,
}

local rieklings = {
    ["bm_riekling"]              = true,
    ["bm_riekling_mounted"]      = true,
    ["bm_riekling_2"]            = true,
    ["bm_riekling_mounted_2"]    = true,
}

local nixhounds = {
    ["nix-hound"]                = true,
    ["t_mw_fau_nixhds_01"]       = true,
    ["h11_nix-hound_dis"]        = true,
    ["h11_nix-hound_rogue"]      = true,
    ["tr_m7_q_pale_biter"]       = true,
}

local kagouti = {
    ["kagouti"]                  = true,
    ["kagouti_diseased"]         = true,
    ["t_mw_fau_armunkag_01"]     = true,
    ["t_mw_fau_armunkagmat_01"]  = true,
}

local alit = {
    ["alit"]                     = true,
    ["alit_diseased"]            = true,
    ["tr_m4_q_alit_troupe"]      = true,
}

local aphyn = {
    ["t_cyr_fau_alphyn_01"]      = true,
}

local wormmouth = {
    ["t_ham_fau_wormmth_01"]     = true,
    ["sky_qre_dse4_wormmouth"]   = true,
}

local trolls = {
    ["t_glb_cre_trollcave_01"]   = true,
    ["t_glb_cre_trollcave_02"]   = true,
    ["t_glb_cre_trollcave_03"]   = true,
    ["t_glb_cre_trollcave_04"]   = true,
    ["t_glb_cre_trollcaved_03"]  = true,
}

local kobold = {
    ["t_glb_cre_kobold_01"]      = true,
}

local boars = {
    ["bm_frost_boar"]            = true,
    ["t_sky_fau_boar_01"]        = true,
}

local goblins = {
    ["goblin_bruiser"]           = true,
    ["goblin_footsoldier"]       = true,
    ["goblin_grunt"]             = true,
    ["goblin_handler"]           = true,
    ["goblin_officer"]           = true,
    ["t_cyr_cre_gob_01"]         = true,
    ["t_cyr_cre_gobbrs_01"]      = true,
    ["t_cyr_cre_gobchf_01"]      = true,
    ["t_cyr_cre_gobskm_01"]      = true,
    ["t_sky_cre_gobskr_01"]      = true,
    ["t_sky_cre_gobshm_01"]      = true,
    ["t_sky_cre_gobthr_01"]      = true,
    ["tr_m7_ns_arena_gobreg"]    = true,
}

local cliffracers = {
    ["cliff racer"]              = true,
    ["cliff racer_diseased"]     = true,
}

local kwama = {
    ["kwama forager"]            = true,
    ["ttooth_kwama forager"]     = true,
    ["h11_kwama_forager_dis"]    = true,
}

local durzogs = {
    ["durzog_diseased"]          = true,
    ["durzog_war"]               = true,
    ["durzog_war_trained"]       = true,
    ["durzog_wild"]              = true,
    ["durzog_wild_weaker"]       = true,
}

------------------------------------------------------------
-- AI FIGHT VALUES
------------------------------------------------------------

local FIGHT = {}

local function addFight(tbl, value)
    for id in pairs(tbl) do FIGHT[id] = value end
end

addFight(wolves,      10)
addFight(bears,       10)
addFight(rieklings,   10)
addFight(nixhounds,   10)
addFight(kagouti,     10)
addFight(alit,        10)
addFight(aphyn,       10)
addFight(wormmouth,   10)
addFight(trolls,      10)
addFight(kobold,      10)
addFight(boars,       10)
addFight(goblins,     10)
addFight(cliffracers, 10)
addFight(durzogs,     10)

-- additional entries not covered by groups above
local EXTRA_CREATURES = {
    ["guar"]                      = 10,
    ["guar_feral"]                = 10,
    ["kwama warrior"]             = 10,
    ["mudcrab"]                   = 10,
    ["rat"]                       = 10,
    ["rat_diseased"]              = 10,
    ["rat_cave_fgrh"]             = 10,
    ["rat_cave_fgt"]              = 10,
    ["shalk"]                     = 10,
    ["shalk_diseased"]            = 10,
    ["slaughterfish_small"]       = 10,
    ["t_mw_fau_ceph_01"]          = 10,
    ["t_mw_fau_cephbg_01"]        = 10,
    ["t_glb_fau_seacr_01"]        = 10,
    ["t_glb_fau_seacrds_01"]      = 10,
    ["t_mw_fau_molec_01"]         = 10,
    ["t_mw_fau_molecds_01"]       = 10,
    ["pc_m1_anv_crabbuck_crab"]   = 10,
    ["t_cyr_fau_muskrat_01"]      = 10,
    ["t_cyr_fau_muskratds_01"]    = 10,
    ["t_cyr_fau_moonc_01"]        = 10,
    ["t_cyr_fau_mooncDis_01"]     = 10,
    ["pc_m1_arc_snakebit_snke"]   = 10,
    ["t_cyr_fau_birdstrid_01"]    = 10,
    ["t_cyr_fau_birdstridn_01"]   = 10,
    ["t_mw_fau_muskf_01"]         = 10,
    ["t_mw_fau_muskfds_01"]       = 10,
    ["t_mw_fau_beetlehr_01"]      = 10,
    ["t_mw_fau_beetlehr_01ds"]    = 10,
    ["t_mw_fau_beetlegr_01"]      = 10,
    ["t_mw_fau_beetlegrds_01"]    = 10,
    ["t_mw_fau_beetlebr_01"]      = 10,
    ["t_mw_fau_beetlebrds_01"]    = 10,
    ["t_mw_fau_beetlebl_01"]      = 10,
    ["t_mw_fau_beetleblds_01"]    = 10,
    ["sky_qre_kg1_spikeworm"]     = 10,
    ["t_ham_fau_spkworm_01"]      = 10,
    ["t_glb_fau_ratbk_01"]        = 10,
    ["ab_fau_bat"]                = 10,
    [" t_glb_fau_bat_01"]         = 10,
    -- Repopulated Creatures
    ["t_mw_fau_mucklch_01"]       = 10,
    ["t_mw_fau_mucklchds_01"]     = 10,
    -- Ttooth Ecology
    ["ttooth_guar"]               = 10,
    ["ttooth_mudcrab"]            = 10,
    ["ttooth_rat"]                = 10,
    ["ttooth_shalk"]              = 10,
    -- Mushroom Crabs
    ["nm_mushcrab"]               = 10,
    -- instant-aggro set handled below
    ["slaughterfish"]             = 10,
    ["dreugh"]                    = 10,
    ["h11_dreugh_dis"]            = 10,
    ["h11_slaughterfish_dis"]     = 10,
}

for id, v in pairs(EXTRA_CREATURES) do FIGHT[id] = v end


------------------------------------------------------------
-- GROUP-AGGRO WHITELIST
------------------------------------------------------------

local GROUP_AGGRO = {}

local function enableGroupAggro(tbl)
    for id in pairs(tbl) do GROUP_AGGRO[id] = true end
end

enableGroupAggro(wolves)
enableGroupAggro(cliffracers)
enableGroupAggro(rieklings)
enableGroupAggro(goblins)
enableGroupAggro(boars)
enableGroupAggro(trolls)
enableGroupAggro(kagouti)
enableGroupAggro(kwama)
enableGroupAggro(durzogs)

------------------------------------------------------------
-- GROWL SOUNDS
------------------------------------------------------------

local sounds = {
    wolf      = { "WolfEquip1", "WolfEquip2", "WolfEquip3", "WolfEquip4", "WolfEquip5" },
    bear      = { "bear scream", "bear roar", "bear moan" },
    riek      = { "rmnt moan", "riek scream", "riek roar", "riek moan" },
    nixhound  = { "nix hound scream", "nix hound roar", "nix hound moan" },
    kagouti   = { "kagouti roar", "kagouti scream", "kagouti moan" },
    alit      = { "alitscrm", "alitroar", "alitmoan" },
    aphyn     = { "t_sndcrea_alphynscream", "t_sndcrea_alphynroar", "t_sndcrea_alphynmoan" },
    wormmouth = { "t_sndcrea_herneroar", "t_sndcrea_hernemoan", "t_sndcrea_hernescream" },
    troll     = { "t_sndcrea_cvtrollroar", "t_sndcrea_cvtrollscream", "t_sndcrea_cvtrollmoan" },
    kobold    = { "t_sndcrea_koboldmoan", "t_sndcrea_koboldroar", "t_sndcrea_mummyroar" },
    goblin    = { "goblin scream", "goblin roar", "goblin moan" },
    boar      = { "boar moan", "boar roar", "boarsniff" },
    cliff     = { "cliff racer scream", "cliff racer roar", "cliff racer moan" },
    kwama     = { "kwamF moan", "kwamF roar", "kwamF scream" },
    durzogs   = { "sludgeworm moan", "sludgeworm roar", "sludgeworm scream" },
}


------------------------------------------------------------
-- WARNING CREATURES (sounds + anim per species)
------------------------------------------------------------

local WARNING_CREATURES = {}

local function addWarning(tbl, soundList, animName)
    for id in pairs(tbl) do
        WARNING_CREATURES[id] = { sounds = soundList, anim = animName }
    end
end

addWarning(wolves,      sounds.wolf,      "walkForward")
addWarning(bears,       sounds.bear,      "walkForward")
addWarning(rieklings,   sounds.riek,      "WalkBack1h")
addWarning(nixhounds,   sounds.nixhound,  "walkForward")
addWarning(kagouti,     sounds.kagouti,   "walkForward")
addWarning(alit,        sounds.alit,      "walkForward")
addWarning(aphyn,       sounds.aphyn,     "walkForward")
addWarning(wormmouth,   sounds.wormmouth, "walkForward")
addWarning(trolls,      sounds.troll,     "walkForward")
addWarning(kobold,      sounds.kobold,    "walkForward")
addWarning(goblins,     sounds.goblin,    "walkForward")
addWarning(boars,       sounds.boar,      "walkForward")
addWarning(cliffracers, sounds.cliff,     "Idle")
addWarning(kwama,       sounds.kwama,     "Idle4")
addWarning(durzogs,     sounds.durzogs,   "walkForward")

------------------------------------------------------------
-- OPTIONAL DISTANCE OVERRIDES (e.g., cliff racers)
-- Defaults: warn 350..1500, attack < 350
------------------------------------------------------------

local DEFAULT_DISTANCES = {
    warnNear = 350,
    warnFar  = 1500,
    attack   = 350,
}

local DISTANCE_OVERRIDES = {
    ["cliff racer"]          = { warnNear = 1000, warnFar = 3000, attack = 1000 },
    ["cliff racer_diseased"] = { warnNear = 1000, warnFar = 3000, attack = 1000 },
}

-- No-warning instant aggro species (distance < 2000)
local INSTANT_AGGRO = {
    ["slaughterfish"] = true,
    ["dreugh"]        = true,
    ["h11_dreugh_dis"]            = true,
    ["h11_slaughterfish_dis"]     = true,
}

------------------------------------------------------------

return {
    FIGHT              = FIGHT,
    INSTANT_AGGRO      = INSTANT_AGGRO,
    GROUP_AGGRO        = GROUP_AGGRO,
    WARNING_CREATURES  = WARNING_CREATURES,
    DEFAULT_DISTANCES  = DEFAULT_DISTANCES,
    DISTANCE_OVERRIDES = DISTANCE_OVERRIDES,
    MARKSMAN_TYPES     = MARKSMAN_TYPES,
    EXTRA_CREATURES    = EXTRA_CREATURES,
}