local core = require("openmw.core")

local module = {
    MOD_NAME = "FreshLoot",
    isLuaApiRecentEnough = core.API_REVISION >= 70,
    isOpenMW049 = core.API_REVISION > 29,
    saveVersion = 1.32,
    interfaceVersion = 1.0,
}

module.itemIdsLists = {
    ["morrowind-tribunal-bloodmoon"] = { "Morrowind.esm", "Tribunal.esm", "Bloodmoon.esm" },
    ["oaab-data"] = { "OAAB_Data.esm" },
    ["tamriel-data"] = { "Tamriel_Data.esm" },
    ["boots-for-beasts"] = { "Boots for Beasts-GOTY-OpenMW Version.esp" },
    ["daedric-maul"] = { "Daedric_Maul.esp" },
    ["weapons-expansion-morrowind"] = { "Weapons Expansion Morrowind.esp" },
    ["killing-spree-helluva"] = { "Killing Spree - Base.esp" },
    ["ruffin-vangarr-armories"] = { "Bal Adurid Bonemold Armor.esp", "Complete and Revised Studded leather v 1.5.esp",
                                    "Dwemer Scrap Armor V2.esp", "Morag Tong Equipment Diversity.esp", "Sacred_Necromancer.esp",
                                    "Complete Nordic Iron.esp", "Concept Art Dunmer Helms.esp", "Imperial Battlemage Armory.esp" },
    ["vanilla-friendly-wearables-expansion"] = { "Vanilla friendly wearables expansion.esm" },
}

module.events = {
    -- Global
    setItemListsSetting = module.MOD_NAME .. "_setItemListsSetting",
    onCellChanged = module.MOD_NAME .. "_onCellChanged",
    setLootsLevel = module.MOD_NAME .. "_setLootsLevel",
    sendPlayersEvent = module.MOD_NAME .. "_sendPlayersEvent",
    convertTestItem = module.MOD_NAME .. "_convertTestItem",
    filterConvertedItems = module.MOD_NAME .. "_filterConvertedItems",
    returnConvertedItems = module.MOD_NAME .. "_returnConvertedItems",
    -- Player
    showMessage = module.MOD_NAME .. "_showMessage",
    filterLootKeepers = module.MOD_NAME .. "_filterLootKeepers",
    printToConsole = module.MOD_NAME .. "_printToConsole",
    returnActorStats = module.MOD_NAME .. "_returnActorStats",
    returnActorsStats = module.MOD_NAME .. "_returnActorsStats",
    -- Actor
    equipItems = module.MOD_NAME .. "_equipItems",
    getActorStats = module.MOD_NAME .. "_getActorStats",
    -- Inventory
    revertLoot = module.MOD_NAME .. "_revertLoot",
}

module.renderers = {
    number = module.MOD_NAME .. "Number",
    hotkey = module.MOD_NAME .. "HotKey",
    multilines = module.MOD_NAME .. "Multilines",
}

return module