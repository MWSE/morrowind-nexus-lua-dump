local core = require("openmw.core")

local module = {
    MOD_NAME = "FreshLoot",
    isLuaApiRecentEnough = core.API_REVISION >= 70,
    isOpenMW049 = core.API_REVISION > 29,
    saveVersion = 2.5,
    interfaceVersion = 1.0,
    actorScriptPath = "scripts/fresh-loot/actor.lua",
    containerScriptPath = "scripts/fresh-loot/container.lua",
}

module.getMessageKeyIfOpenMWTooOld = function(key)
    if not module.isLuaApiRecentEnough then
        if module.isOpenMW049 then
            return "requiresNewerOpenmw49"
        else
            return "requiresOpenmw49"
        end
    end
    return key
end

module.itemIdsLists = {
    ["morrowind-tribunal-bloodmoon"] = { "Morrowind.esm", "Tribunal.esm", "Bloodmoon.esm" },
    ["oaab-data"] = { "OAAB_Data.esm" },
    ["tamriel-data"] = { "Tamriel_Data.esm" },
    ["armors-for-beasts"] = { "protected-beasts.omwscripts",
                              "Argonian Full Helms Lore Integrated.ESP",
                              "Boots for Beasts-GOTY-OpenMW Version.esp",
                              "Boots for Beasts-GOTY.esp",
                              "Boots for Beasts-TR+.esp",
                              "HistHelms - Lefemm.ESP",
                              "HistHelms.ESP" },
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
    onActorActive = module.MOD_NAME .. "_onActorActive",
    onNewContainers = module.MOD_NAME .. "_onNewContainers",
    sendPlayersEvent = module.MOD_NAME .. "_sendPlayersEvent",
    setItemListsSetting = module.MOD_NAME .. "_setItemListsSetting",
    setLootsStats = module.MOD_NAME .. "_setLootsStats",
    filterConvertedItems = module.MOD_NAME .. "_filterConvertedItems",
    revertLoot = module.MOD_NAME .. "_revertLoot",
    convertTestItem = module.MOD_NAME .. "_convertTestItem",
    -- Player
    showMessage = module.MOD_NAME .. "_showMessage",
    printToConsole = module.MOD_NAME .. "_printToConsole",
    clearNewContainers = module.MOD_NAME .. "_clearNewContainers",
    addLootsLocalStats = module.MOD_NAME .. "_addLootsLocalStats",
    returnConvertedItems = module.MOD_NAME .. "_returnConvertedItems",
    returnActorStats = module.MOD_NAME .. "_returnActorStats",
    -- Actor
    equipItems = module.MOD_NAME .. "_equipItems",
    getActorStats = module.MOD_NAME .. "_getActorStats",
}

module.callbacks = {
    onActorActive = module.MOD_NAME .. "_onActorActive",
    checkEquipment = module.MOD_NAME .. "_checkEquipment",
}

module.renderers = {
    number = module.MOD_NAME .. "Number",
    hotkey = module.MOD_NAME .. "HotKey",
    multilines = module.MOD_NAME .. "Multilines",
}

return module