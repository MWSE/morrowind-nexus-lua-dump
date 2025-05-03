local core = require("openmw.core")

local module = {
    MOD_NAME = "FreshLoot",
    isLuaApiRecentEnough = core.API_REVISION >= 70,
    isOpenMW049 = core.API_REVISION > 29,
    saveVersion = 1.5,
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
    sendPlayersEvent = module.MOD_NAME .. "_sendPlayersEvent",
    setItemListsSetting = module.MOD_NAME .. "_setItemListsSetting",
    setDoorStats = module.MOD_NAME .. "_setDoorStats",
    onCellChanged = module.MOD_NAME .. "_onCellChanged",
    setCellLootLocalStats = module.MOD_NAME .. "_setCellLootLocalStats",
    filterConvertedItems = module.MOD_NAME .. "_filterConvertedItems",
    revertLoot = module.MOD_NAME .. "_revertLoot",
    convertTestItem = module.MOD_NAME .. "_convertTestItem",
    -- Player
    showMessage = module.MOD_NAME .. "_showMessage",
    printToConsole = module.MOD_NAME .. "_printToConsole",
    getCellLootLocalStats = module.MOD_NAME .. "_getCellLootLocalStats",
    returnConvertedItems = module.MOD_NAME .. "_returnConvertedItems",
    returnActorStats = module.MOD_NAME .. "_returnActorStats",
    -- Actor
    equipItems = module.MOD_NAME .. "_equipItems",
    getActorStats = module.MOD_NAME .. "_getActorStats",
}

module.renderers = {
    number = module.MOD_NAME .. "Number",
    hotkey = module.MOD_NAME .. "HotKey",
    multilines = module.MOD_NAME .. "Multilines",
}

return module