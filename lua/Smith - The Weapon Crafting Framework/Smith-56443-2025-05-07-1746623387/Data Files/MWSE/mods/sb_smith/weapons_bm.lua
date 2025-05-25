local interop = require("sb_smith.interop")

---@type weapon[]
local weapons = {
    ["BM huntsman axe"] =
    {
        handles = { "W_Huntsman_waraxe.002", "W_Huntsman_waraxe.003" },
        blades  = { "W_Huntsman_waraxe.001" },
        rootIndexes = { 2, 1 }
    },
    ["BM huntsman war axe"] =
    {
        handles = { "W_Huntsman_waraxeM.002", "W_Huntsman_waraxeM.003" },
        blades  = { "W_Huntsman_waraxeM.001" },
        rootIndexes = { 2, 1 }
    },
    ["BM ice war axe"] =
    {
        handles = { "W_Ice_waraxe.002" },
        blades  = { "W_Ice_waraxe.001" },
        rootIndexes = { 1, 1 }
    },
    ["BM nordic silver axe"] =
    {
        handles = { "W_Nord_waraxe.001", "W_Nord_waraxe.003" },
        blades  = { "W_Nord_waraxe.002" },
        rootIndexes = { 1, 1 }
    },
    -----
    ["BM nordic silver battleaxe"] =
    {
        handles = { "W_Nord_battleaxe.002", "W_Nord_battleaxe.003" },
        blades = { "W_Nord_battleaxe.001" },
        rootIndexes = { 2, 1 }
    },
    -----
    ["BM ice mace"] =
    {
        handles = { "W_Ice_mace.002" },
        blades = { "W_Ice_mace.001" },
        rootIndexes = { 1, 1 }
    },
    ["BM nordic silver mace"] =
    {
        handles = { "W_Nord_mace.002" },
        blades = { "W_Nord_mace.001" },
        rootIndexes = { 1, 1 }
    },
    -----
    ["BM ice dagger"] =
    {
        handles = { "W_Ice_dagger.002" },
        blades = { "W_Ice_dagger.001" },
        rootIndexes = { 1, 1 }
    },
    ["BM nordic silver dagger"] =
    {
        handles = { "W_Nord_dagger.002" },
        blades = { "W_Nord_dagger.001" },
        rootIndexes = { 1, 1 }
    },
    ["BM nordic silver shortsword"] =
    {
        handles = { "W_Nord_Longsword.002" },
        blades = { "W_Nord_Longsword.001", "W_Nord_Longsword.003" },
        rootIndexes = { 1, "1" }
    },
    ["BM riekling lance"] =
    {
        handles = { "Tri What cha cal it.001" },
        blades = { "Tri What cha cal it", "Tri What cha cal it.002" },
        rootIndexes = { 1, 2 }
    },
    -----
    ["BM huntsman longsword"] =
    {
        handles = { "W_Huntsman_longsword.002" },
        blades = { "W_Huntsman_longsword.001" },
        rootIndexes = { 1, 1 }
    },
    ["BM ice longsword"] =
    {
        handles = { "W_Ice_Longsword.002" },
        blades = { "W_Ice_longsword.001", "W_Ice_longsword.003" },
        rootIndexes = { 1, 2 }
    },
    ["BM nordic silver longsword"] =
    {
        handles = { "W_Nord_Longsword.002" },
        blades = { "W_Nord_Longsword.001", "W_Nord_Longsword.003" },
        rootIndexes = { 1, 2 }
    },
    ["BM riekling sword"] =
    {
        handles = { "Tri What cha cal it 2.001", "Tri What cha cal it 2.002", "Tri What cha cal it 2.003", "Tri What cha cal it 2.004", "Tri What cha cal it 2.005" },
        blades = { "Tri What cha cal it 2", "Tri What cha cal it 2.002", "Tri What cha cal it 2.004", "Tri What cha cal it 2.005" },
        rootIndexes = { 2, 3 }
    },
    -----
    ["BM nordic silver claymore"] =
    {
        handles = { "W_Nord_claymore.002" },
        blades = { "W_Nord_claymore.001", "W_Nord_claymore.003" },
        rootIndexes = { 1, 2 }
    },
    -----
    ["BM huntsman spear"] =
    {
        handles = { "W_Huntsman_spear.002" },
        blades = { "W_Huntsman_spear.001" },
        rootIndexes = { 1, 1 }
    }
}

interop:registerWeapons(weapons)