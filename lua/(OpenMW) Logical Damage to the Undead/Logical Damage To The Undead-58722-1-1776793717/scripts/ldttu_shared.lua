local M = {
    undeadData = {
        ghosts = {
            generic = {
                "ancestor_ghost",
                "ancestor_guardian",
                "gateway_haunt",
                "dwarven ghost",
                "dahrk mezalf",
                "tr_m1_aran_ghost",
                "tr_m2_ghost",
                "t_dwe_und_ghst",
                "t_cyr_und_ghst",
                "t_cyr_und_wrth",
            },
            unique = {
                ["ancestor_mg_wisewoman"] = true,
                ["wraith_sul_senipul"] = true,
                ["dahrk mezalf"] = true,
                ["tr_m2_445_sealingghost"] = true,
                ["tr_m3_cr_ebontghost"] = true,
                ["t_mw_und_ancestorwep_01"] = true,
                ["t_dwe_spectre_f_01"] = true,
                ["t_dwe_und_ghstgr_01"] = true
            }
        },
        physical = {
            generic = { 
                "bonewalker",
                "t_mw_und_bone",
                "t_mw_und_procebonwal",
                "t_mw_und_reverbon",
                "bonelord",
                "t_mw_und_boneld",
                "tr_m1_aran_mummy",
                "t_mw_und_mum",
                "t_cyr_und_mum",
                "skeleton",
                "bm_sk_champ",
                "tr_m1_aran_skel", 
                "tr_m1_q_skel",
                "t_glb_und_skel",
                "t_cyr_und_skel",
                "t_mw_und_skel",
                "t_sky_und_skel",
                "t_cyr_und_rem",
                "lich",
                "draugr",
                "t_sky_und_drgr"
            },
            unique = { 
                ["tr_m1_aran_bonew_g_pla"] = true,
                ["tr_m1_aran_bonew_plague"] = true,
                ["t_mw_und_uni_bonewalker"] = true,
                ["t_cyr_und_minobarrow_01"] = true,
                ["worm lord"] = true,
                ["tr_m2_drolarmanor_skel1"] = true, 
                ["tr_m2_drolarmanor_skel2"] = true,
                ["bm_wolf_skeleton"] = true,
                ["bm_wolf_bone_summon"] = true,
                ["t_sky_und_bonewolf_01"] = true,
                ["skeleton_fm_king"] = true
            }
        }
    },

    DEFAULTS = {
        MOD_ENABLED = true,
        GHOST_BLADE_MULT    = 1.5,
        GHOST_HEAVY_MULT    = 0.5,
        GHOST_MARKSMAN_MULT = 0.2,
        GHOST_H2H_MULT      = 0.2,
        PHYS_BLUNt_AXE_MULT = 1.5,
        PHYS_BLADE_MULT     = 0.7,
        PHYS_SPEAR_MULT     = 0.2,
        PHYS_MARKSMAN_MULT  = 0.2,
        PHYS_H2H_MULT       = 0.2,
        DEBUG_LOGGING = false,
    }
}

function M.determineGroup(recordId)
    local id = recordId:lower()
    
    if M.undeadData.ghosts.unique[id] then 
        return "ghost" 
    end
    
    for _, pattern in ipairs(M.undeadData.ghosts.generic) do
        if id:find(pattern:lower(), 1, true) then 
            return "ghost" 
        end
    end
    
    if M.undeadData.physical.unique[id] then 
        return "physical" 
    end
    
    for _, pattern in ipairs(M.undeadData.physical.generic) do
        if id:find(pattern:lower(), 1, true) then 
            return "physical" 
        end
    end
    
    return nil
end

return M