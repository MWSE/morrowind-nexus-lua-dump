local core = require("openmw.core")

local revenants = {
    velothi = {
        static = {
            "ancestor_ghost",
            "bonelord",
            "bonewalker",
            "Bonewalker_Greater",
        },
        leveled = {
            "in_tomb_all_lev+0",
            "in_tomb_bone_lev+0",
        },
    },
    bloodmoon = {
        static = {
            "BM_wolf_skeleton",
            "BM_draugr01",
            "bm skeleton champion gr",
        },
        leveled = {
            "bm_in_nordburial"
        }
    },
    skeleton = {
        static = {
            "skeleton",
            "skeleton archer",
            "skeleton warrior",
            "skeleton champion",
        },
        leveled = {
            "in_tomb_skele_lev+0",
        },
    }
}

local cursedContainers = {
    ["com_chest_02_tomb"] = { revenants.velothi, revenants.skeleton },
    ["chest_tomb"]        = { revenants.velothi, revenants.skeleton },
    ["urn_ash"]           = { revenants.velothi, revenants.skeleton },
    ["bm_nordictomb"]     = { revenants.bloodmoon },
}

local expansions = {
    ["OAAB_Data.esm"] = function()
        cursedContainers["ab_o_urnash"]        = { revenants.velothi, revenants.skeleton }
        cursedContainers["ab_o_velothicoffer"] = { revenants.velothi, revenants.skeleton }
    end,
    ["Tamriel_Data.esm"] = function()
        local skeletonS = revenants.skeleton.static
        skeletonS[#skeletonS + 1] = "T_Mw_Und_SkelArc_01"
        skeletonS[#skeletonS + 1] = "T_Glb_Und_SkelCmpGr_01"
        skeletonS[#skeletonS + 1] = "T_Mw_Und_SkelWWiz_01"
        skeletonS[#skeletonS + 1] = "T_Glb_Und_SkelWLor_01"
        local skeletonL = revenants.skeleton.leveled
        skeletonL[#skeletonL + 1] = "T_Mw_Lvl_SkeletonsTomb+0"

        revenants.cyrodiil                   = {
            static = {
                "T_Cyr_Und_Mum_01",
                "T_Cyr_Und_MinoBarrow_01",
            },
            leveled = {
                "T_Cyr_Lvl_ColTomb+0",
            },
        }
        revenants.skyrim                     = {
            static = {
                "T_Sky_Und_DrgrRot_01",
                "T_Sky_Und_Drgr_01",
                "T_Sky_Und_DrgrHousc_01",
                "T_Sky_Und_DrgrLor_01",
                "T_Sky_Und_DrgrTong_01",
                "T_Sky_Und_Bonewolf_01",
            },
            leveled = {
                "T_Sky_Cr_Draugr01"
            },
        }

        cursedContainers["T_CyrImp_Dng"]     = { revenants.cyrodiil, revenants.skeleton }
        cursedContainers["T_SkyNor_DngBarr"] = { revenants.skyrim, revenants.skeleton }
    end,
}

for plugin, addContainers in pairs(expansions) do
    if core.contentFiles.has(plugin) then
        addContainers()
    end
end

function GetRevenants(obj)
    for pattern, revenantList in pairs(cursedContainers) do
        if string.find(obj.recordId, pattern) then
            return revenantList[math.random(#revenantList)]
        end
    end
end
