local core = require("openmw.core")

local module = {
    MOD_NAME = "FreshLoot",
    isLuaApiRecentEnough = core.API_REVISION >= 70,
    isOpenMW049 = core.API_REVISION > 29,
    saveVersion = 3.0,
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
    ["weapons-expansion-project"] = { "Weapons Expansion Morrowind.esp" },
    ["killing-spree-helluva"] = { "Killing Spree - Base.esp" },
    ["ruffin-vangarr-armories"] = { "Bal Adurid Bonemold Armor.esp", "Complete and Revised Studded leather v 1.5.esp",
                                    "Dwemer Scrap Armor V2.esp", "Morag Tong Equipment Diversity.esp", "Sacred_Necromancer.esp",
                                    "Complete Nordic Iron.esp", "Concept Art Dunmer Helms.esp", "Imperial Battlemage Armory.esp" },
    ["vanilla-friendly-wearables-expansion"] = { "Vanilla friendly wearables expansion.esm" },
}

local function key(suffix)
    return string.format("%s_%s", module.MOD_NAME, suffix)
end

module.actions = {
    showItems = key("show_items"),
}

module.inputKeys = {
    defaultItemsKey = module.actions.showItems .. "_default",
}

module.events = {
    -- Global
    onActorActive = key("onActorActive"),
    onNewContainers = key("onNewContainers"),
    sendPlayersEvent = key("sendPlayersEvent"),
    setItemListsSetting = key("setItemListsSetting"),
    setLootsStats = key("setLootsStats"),
    filterConvertedItems = key("filterConvertedItems"),
    revertLoot = key("revertLoot"),
    convertTestItem = key("convertTestItem"),
    -- Player
    showMessage = key("showMessage"),
    printToConsole = key("printToConsole"),
    clearNewContainers = key("clearNewContainers"),
    addLootsLocalStats = key("addLootsLocalStats"),
    returnConvertedItems = key("returnConvertedItems"),
    returnActorStats = key("returnActorStats"),
    -- Actor
    equipItems = key("equipItems"),
    getActorStats = key("getActorStats"),
}

module.callbacks = {
    onActorActive = key("onActorActive"),
    checkEquipment = key("checkEquipment"),
}

module.renderers = {
    number = key("Number"),
    multilines = key("Multilines"),
}

return module