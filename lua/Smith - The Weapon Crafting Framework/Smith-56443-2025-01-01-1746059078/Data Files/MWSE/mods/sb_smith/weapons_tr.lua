local interop = require("sb_smith.interop")

---@type weapon[]
local weapons = {
    ["adamantium_axe"] =
    {
        handles = { "Line02.002", "Line02.003" },
        blades  = { "Line02.001" },
        rootIndexes = { 2, 1 }
    },
    -----
    ["adamantium_mace"] =
    {
        handles = { "Shape01.002", "Shape01.003" },
        blades  = { "Shape01.001" },
        rootIndexes = { 2, 1 }
    },
    ["goblin_club"] =
    {
        handles = { "Shape10.002" },
        blades  = { "Shape10.001" },
        rootIndexes = { 1, 1 }
    },
    -----
    ["adamantium_shortsword"] =
    {
        handles = { "Shape02.002" },
        blades = { "Shape02.001" },
        rootIndexes = { 1, 1 }
    },
    ["goblin_sword"] =
    {
        handles = { "Shape07.002" },
        blades = { "Shape07.001" },
        rootIndexes = { 1, 1 }
    },
    -----
    ["Ebony Scimitar"] =
    {
        handles = { "Tri W_Ebony_Scimitar.001", "Tri W_Ebony_Scimitar.004" },
        blades = { "Tri W_Ebony_Scimitar.002", "Tri W_Ebony_Scimitar.003" },
        rootIndexes = { 2, 1 }
    },
    -----
    ["adamantium_claymore"] =
    {
        handles = { "Shape01.002" },
        blades = { "Shape01.001" },
        rootIndexes = { 1, 1 }
    },
    -----
    ["adamantium_spear"] =
    {
        handles = { "Shape02.002" },
        blades = { "Shape02.001" },
        rootIndexes = { 1, 1 }
    }
}

interop:registerWeapons(weapons)