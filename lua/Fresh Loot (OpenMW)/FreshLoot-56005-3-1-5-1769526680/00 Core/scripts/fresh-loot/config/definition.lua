local core = require("openmw.core")

local module = {
    MOD_NAME = "FreshLoot",
    isLuaApiRecentEnough = core.API_REVISION >= 70,
    isOpenMW049 = core.API_REVISION > 29,
    saveVersion = 3.0,
    interfaceVersion = 1.0,
}

module.scripts = {
    actorEquip = "scripts/fresh-loot/actor-equip.lua",
    actorGetStats = "scripts/fresh-loot/actor-get-stats.lua",
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
    ["starwind"] = { "StarwindRemasteredV1.15.esm" }
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
    setSetting = key("set_setting"),
    onActorActive = key("on_actor_active"),
    detachScript = key("detach_script"),
    requestActorStats = key("request_actor_stats"),
    onNewContainers = key("on_new_containers"),
    sendPlayersEvent = key("send_players_event"),
    setItemListsSetting = key("set_item_lists_setting"),
    setLootsStats = key("set_loots_stats"),
    filterConvertedItems = key("filter_converted_items"),
    convertTestItem = key("convert_test_item"),
    -- Player
    showMessage = key("show_message"),
    printToConsole = key("print_to_console"),
    clearNewContainers = key("clear_new_containers"),
    addLootsLocalStats = key("add_loots_local_stats"),
    returnConvertedItems = key("return_converted_items"),
    returnActorStats = key("return_actor_stats"),
    -- Actor
    equipItems = key("equip_items"),
    getActorStats = key("get_actor_stats"),
}

module.callbacks = {
    onActorActive = key("on_actor_active"),
    checkEquipment = key("check_equipment"),
}

module.renderers = {
    number = key("number"),
    multilines = key("multilines"),
    hotkeyKeyboard = key("hotkey_keyboard"),
}

return module