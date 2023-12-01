local this = {}
local util = require("openmw.util")

this.daedricPrinceStatue = {
    -- Sheogorath
    ["active_dae_sheogorath"] = "Sheogorath",
    ["ex_dae_sheogorath"] = "Sheogorath",
    -- Malacath
    ["active_dae_malacath"] = "Malacath",
    ["ex_dae_malacath"] = "Malacath",
    ["ex_dae_malacath_attack"] = "Malacath",
    -- Molag Bal
    ["active_dae_molagbal"] = "Molag Bal",
    ["ex_dae_molagbal"] = "Molag Bal",
    -- Mehrunes Dagon
    ["active_dae_mehrunes"] = "Mehrunes Dagon",
    ["ex_dae_mehrunesdagon"] = "Mehrunes Dagon",
    -- Azura
    ["active_dae_azura"] = "Azura",
    ["ex_dae_azura"] = "Azura",
    -- Boethiah
    ["active_dae_boethiah"] = "Boethiah",
    ["Ex_DAE_Boethiah"] = "Boethiah",
}

this.daedricCreatures = {

    -- //Daedric princes and their monsters
    ["Sheogorath"] = { "golden saint" },
    ["Molag Bal"] = { "daedroth" },
    ["Mehrunes Dagon"] = { "dremora", "dremora_lord" },
    ["Boethiah"] = { "hunger" },
    ["Azura"] = { "winged twilight" },
    ["Malacath"] = { "ogrim", "ogrim titan" },

    -- //List of possible Daedras
    ["Random"] = { "dremora", "dremora_lord", "winged twilight", "scamp", "golden saint", "daedroth", "ogrim",
        "ogrim titan", "hunger", "clannfear", "atronach_flame", "atronach_frost", "atronach_storm" },

    -- //Daedra grouped according to item value
    ["GR1"] = { "scamp", "hunger", "atronach_flame", "clannfear" },
    ["GR2"] = { "dremora", "ogrim", "atronach_frost", "daedroth" },
    ["GR3"] = { "dremora_lord", "winged twilight", "atronach_storm", "golden saint", "ogrim titan" },
}

this.summonPosition = {
    front = util.vector3(0, 128, 0),
    back = util.vector3(0, -128, 0),
    left = util.vector3(-128, 0, 0),
    right = util.vector3(128, 0, 0),
    top = util.vector3(0, 0, 128)
}


return this
