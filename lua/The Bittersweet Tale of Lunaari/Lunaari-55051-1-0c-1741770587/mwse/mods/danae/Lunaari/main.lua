local JoyOfPainting = include("mer.JoyOfPainting")
if not JoyOfPainting then return end
if not JoyOfPainting.Subject then return end
-- code my Merlord
---@type JOP.Subject.registerSubjectParams[]

local subjects = {
    {
        id = "draggletail",
        objectIds = {
            "flora_bc_podplant_01",
            "flora_bc_podplant_02",
            "flora_bc_podplant_03",
            "flora_bc_podplant_04",
        }
    },
    {
        id = "cliffracer",
        objectIds = {
            "aa_racer1",
            "aa_racer3",
            "aa_racer4",
            "aa_racer5",
            "cliff racer",
            "cliff racer_blighted",
            "cliff racer_diseased",
        }
    },
    {
        id = "bullnetch",
        objectIds = {
            "netch_bull",
            "netch_bull_dead",
            "netch_bull_dead_2",
            "netch_bull_ilgn",
            "netch_bull_ranched",
            "netch_giant_unique",
            "cliff racer_diseased",
            "t_mw_fau_netblds_01",
            "t_mw_fau_netblrcds_01",
            "t_mw_fau_netchhostile01",
        }
    },
    {
        id = "nixhound",
        objectIds = {
            "aa_cr_nix-hound",
            "aa_cr_nixpup",
            "nix-hound",
            "t_mw_fau_nixhds_01",
            "nix-hound blighted",
        }
    },
    {
        id = "scathecraw",
        objectIds = {
            "flora_rm_scathecraw_01",
            "flora_rm_scathecraw_02",
            "T_Mw_Flora_Scathecraw03",
            "T_Mw_Flora_Scathecraw04",
            "T_Mw_Flora_Scathecraw05",
            "T_Mw_Flora_Scathecraw06",
            "T_Mw_Flora_Scathecraw07",
            "T_Mw_Flora_Scathecraw08",
        }
    },
    {
        id = "Governor's Hall",
        name = "Governor's Hall",
        objectIds = {
            "ex_imp_govmansion_wing",
            "ex_imp_govman_stair",
            "ex_imp_govmansion_gate",
            "ex_imp_govmansion_donjon",
        }
    },
    {
        id = "chokeweed",
        objectIds = {
            "flora_chokeweed_02",
        }
    },
    {
        id = "roobrush",
        objectIds = {
            "flora_roobrush_02",
        }
    },
    {
        id = "heather",
        objectIds = {
            "flora_heather_01",
        }
    },
    {
        id = "kanet",
        objectIds = {
            "flora_gold_kanet_01",
            "flora_gold_kanet_01_uni",
            "flora_gold_kanet_02",
            "flora_gold_kanet_02_uni",
        }
    },
    {
        id = "parasol",
        name = "Emperor Parasol",
        objectIds = {
            "AB_Flora_ParasolMid01",
            "AB_Flora_ParasolMid03",
            "flora_emp_parasol_01",
            "flora_emp_parasol_02",
            "Flora_emp_parasol_03",
        }
    },
}


for _, subject in ipairs(subjects) do
    JoyOfPainting.Subject.registerSubject(subject)
end