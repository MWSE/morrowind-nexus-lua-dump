
--in order of priority
local menuButtonMapping = {
    { menu = tes3ui.registerID("MenuInventorySelect"), button = tes3ui.registerID("MenuInventorySelect_button_cancel") },
    { menu = tes3ui.registerID("MenuMagicSelect"), button = tes3ui.registerID("MenuMagicSelect_button_cancel") },
    { menu = tes3ui.registerID("MenuQuantity"), button = tes3ui.registerID("MenuQuantity_buttoncancel") },
    { menu = tes3ui.registerID("MWSE:ModConfigMenu"), button = tes3ui.registerID("MWSE:ModConfigMenu_Close") },
    { menu = tes3ui.registerID("MenuVideo"), button = tes3ui.registerID("MenuVideo_Okbutton") },
    { menu = tes3ui.registerID("MenuAudio"), button = tes3ui.registerID("MenuAudio_Okbutton") },
    { menu = tes3ui.registerID("MenuPrefs"), button = tes3ui.registerID("MenuPrefs_Okbutton") },
    { menu = tes3ui.registerID("MenuSave"), button = tes3ui.registerID("MenuSave_Cancelbutton") },
    { menu = tes3ui.registerID("MenuLoad"), button = tes3ui.registerID("MenuLoad_Okbutton") },
    { menu = tes3ui.registerID("MenuOptions"), button = tes3ui.registerID("MenuOptions_Return_container") },
    { menu = tes3ui.registerID("MenuRestWait"), button = tes3ui.registerID("MenuRestWait_cancel_button") },
    { menu = tes3ui.registerID("MenuQuick"), button = tes3ui.registerID("MenuQuick_button_cancel") },
    { menu = tes3ui.registerID("MenuScroll"), button = tes3ui.registerID("MenuScroll_Close") },
    { menu = tes3ui.registerID("MenuJournal"), button = tes3ui.registerID("MenuBook_button_close") },
    { menu = tes3ui.registerID("MenuBook"), button = tes3ui.registerID("MenuBook_button_close") },
    { menu = tes3ui.registerID("MenuAlchemy"), button = tes3ui.registerID("MenuAlchemy_cancel_button") },
    { menu = tes3ui.registerID("MenuEnchantment"), button = tes3ui.registerID("MenuEnchantment_Cancelbutton") },
    { menu = tes3ui.registerID("MenuSpellmaking"), button = tes3ui.registerID("MenuSpellmaking_Cancelbutton") },
    { menu = tes3ui.registerID("MenuServiceTravel"), button = tes3ui.registerID("MenuServiceTravel_Okbutton") },
    { menu = tes3ui.registerID("MenuServiceTraining"), button = tes3ui.registerID("MenuServiceTraining_Okbutton") },
    { menu = tes3ui.registerID("MenuServiceSpells"), button = tes3ui.registerID("MenuServiceSpells_Okbutton") },
    { menu = tes3ui.registerID("MenuServiceRepair"), button = tes3ui.registerID("MenuServiceRepair_Okbutton") },
    { menu = tes3ui.registerID("MenuRepair"), button = tes3ui.registerID("MenuRepair_Okbutton") },
    { menu = tes3ui.registerID("MenuPersuasion"), button = tes3ui.registerID("MenuPersuasion_Okbutton") },
    { menu = tes3ui.registerID("MenuBarter"), button = tes3ui.registerID("MenuBarter_Cancelbutton") },
    { menu = tes3ui.registerID("MenuDialog"), button = tes3ui.registerID("MenuDialog_button_bye") },
    { menu = tes3ui.registerID("MenuContents"), button = tes3ui.registerID("MenuContents_closebutton") },
    { menu = tes3ui.registerID("CustomMessageBox"), button = "CustomMessageBox_CancelButton"},
    { menu = tes3ui.registerID("MenuInventory"), button = "none"},
}


--Allow exiting companion share menu like other menus
local function closeMenu()
    local topMenu = tes3ui.getMenuOnTop()
    if not topMenu then return end
    --first check that at least one of our menus is on top
    --But it may not be the one we "close", i.e inventory menu might
    local menuOnTop
    for _, data in ipairs(menuButtonMapping) do
        if topMenu.id == data.menu then
            menuOnTop = true
            break
        end
    end
    if menuOnTop then
        for _, data in ipairs(menuButtonMapping) do
            local menu = tes3ui.findMenu(data.menu)
            if menu and menu.id == data.menu then
                local closeButton = menu:findChild(data.button)
                if closeButton and closeButton.visible then
                    tes3.worldController.menuClickSound:play()
                    closeButton:triggerEvent("mouseClick")
                end
                return
            end
        end
    end
end

local function onMouseButtonDown(e)
    if e.button == tes3.worldController.inputController.inputMaps[19].code then
        closeMenu()
    end
end

local function onKeyDown(e)
    if e.keyCode ~= 1 and e.keyCode == tes3.worldController.inputController.inputMaps[19].code then
        closeMenu()
    end
end

event.register("keyDown", onKeyDown)
event.register("mouseButtonDown", onMouseButtonDown)
