local config = require("SolaLinguaBona.config")

--------------------------------------------------

local creatures = {
    ["dictKeys"] = {"Beasts", "Kwama"},
    ["Beasts"] = {
        {"kroke", "alit"},
        {"cliff racer", "dalad-bet"},
        {"crabfolk", "dreugh"},
        {"bigtoe", "$guar#", 2, "guar"},
        {"gharial", "kagouti"},
        {"mudcrab", "dwe'gora"},
        {"jelly", "netch", 2, "netch"},
        {"nix[-]hound", "dunran", 1, "nix-hound"},
        {"rat", "rat"},
        {"fire beetle", "shalk"},
        {"slaughterfish", "amur'lan"},
        
        {"Kroke", "Alit", 0},
        {"Cliff racer", "Dalad-bet", 0},
        {"Crabfolk", "Dreugh", 0},
        {"Bigtoe", "@Guar#", 2},
        {"Gharial", "Kagouti", 0},
        {"Mudcrab", "Dwe'gora", 0},
        {"Jelly", "Netch", 2},
        {"Nix[-]hound", "Dunran", 1},
        {"Rat", "Rat", 0},
        {"Fire beetle", "Shalk", 0},
        {"Slaughterfish", "Amur'lan", 0},
        
        {"Cliff Racer", "Dalad-Bet", 0},
        {"^Mudcrab$", "Dwe'Gora", 1},
        {"Nix[-]Hound", "Dunran", 1},
        {"Fire Beetle", "^Shalk$", 2},
        {"^Slaughterfish$", "Amur'Lan", 1},
        
        {"Hound", "Ran", 0}
    },
    ["Kwama"] = {
        {"grub", "kwama"},
        {"larva", "scrib"},
        
        {"Grub", "Kwama", 0},
        {"Larva", "Scrib", 0}
    },
    ["protected"] = {
        {"The Rat In The Pot", "RatPot"},
        {"Black Shalk Cornerclub", "BlaSha"},
        {"Lugrub", "LuGr"},
        {"grubber", "grb"},
        {"%PCRank", "%PCR"},
        {"Quality", "Qlty"},
        {"quality", "qlty"},
        {"Personality", "Prsn"},
        {"personality", "prsn"}
    }
}

--------------------------------------------------

local function init()
    config.addModTranslation("Sola Lingua Bona - Creatures", creatures)
end

event.register("initialized", init, {priority = 15})