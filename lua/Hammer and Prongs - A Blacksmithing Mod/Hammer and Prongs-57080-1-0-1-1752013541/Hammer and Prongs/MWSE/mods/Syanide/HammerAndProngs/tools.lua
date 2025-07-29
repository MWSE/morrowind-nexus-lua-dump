--An example of a Tool requirement with a list of valid object ids
local CraftingFramework = require("CraftingFramework")
if not CraftingFramework then return end

CraftingFramework.Tool:new{
    id = "low_hammer",
    name = "Apprentice's Armorer's Hammer",
    ids = {
        "hammer_repair",
        "repair_journeyman_01",
        "repair_master_01",
        "repair_grandmaster_01",
        "repair_secretmaster_01",
        "AB_Repair_Flatter_01",
        "AB_Repair_Mallet_01",
        "AB_Repair_Swage_01",
        "T_Com_Hammer_Repair_01",
        "T_Com_Hammer_Repair_02",
        "mallet_wood",
        "ashfall_hammer_stone"
    }
}

CraftingFramework.Tool:new{
    id = "mid_hammer",
    name = "Journeyman's Armorer's Hammer",
    ids = {
        "repair_journeyman_01",
        "repair_master_01",
        "repair_grandmaster_01",
        "repair_secretmaster_01",
        "AB_Repair_DwrvHammer"
    }
}

CraftingFramework.Tool:new{
    id = "master_hammer",
    name = "Master's Armorer's Hammer",
    ids = {
        "repair_master_01",
        "repair_grandmaster_01",
        "repair_secretmaster_01",
        "T_Dwe_Hammer_Repair_01"
    }
}

CraftingFramework.Tool:new{
    id = "grand_master_hammer",
    name = "Grandmaster's Armorer's Hammer",
    ids = {
        "repair_grandmaster_01",
        "repair_secretmaster_01",
        "mallet_daedric"
    }
}

CraftingFramework.Tool:new{
    id = "secret_hammer",
    name = "Secret Master's Armorer's Hammer",
    ids = {
        "repair_secretmaster_01",
        "mallet_daedric"
    }
}

CraftingFramework.Tool:new{
    id = "prongs",
    name = "Repair Prongs",
    ids = {
        "repair_prongs",
        "T_Com_Tongs_Repair_01",
        "prongs_bone",
        "prongs_daedric",
        "prongs_dwemer",
        "prongs_ebony",
        "prongs_glass",
        "prongs_steel"
    }
}

CraftingFramework.Tool:new{
    id = "tongs",
    name = "Jewelry Tongs",
    ids = {
        "T_Com_Tongs_Repair_01"
    }
}

CraftingFramework.Tool:new{
    id = "low_needle",
    name = "Apprentice's Armorer's Needle",
    ids = {
        "hap_apprentice_needle",
        "hap_journeyman_needle",
        "hap_master_needle",
        "hap_grandmaster_needle",
        "hap_secret_needle"
    }
}

CraftingFramework.Tool:new{
    id = "mid_needle",
    name = "Journeyman's Armorer's Needle",
    ids = {
        "hap_journeyman_needle",
        "hap_master_needle",
        "hap_grandmaster_needle",
        "hap_secret_needle"
    }
}

CraftingFramework.Tool:new{
    id = "master_needle",
    name = "Master's Armorer's Needle",
    ids = {
        "hap_master_needle",
        "hap_grandmaster_needle",
        "hap_secret_needle"
    }
}

CraftingFramework.Tool:new{
    id = "grand_master_needle",
    name = "Grandmaster's Armorer's Needle",
    ids = {
        "hap_grandmaster_needle",
        "hap_secret_needle"
    }
}

CraftingFramework.Tool:new{
    id = "secret_needle",
    name = "Secret Master's Armorer's Needle",
    ids = {
        "hap_secret_needle"
    }
}