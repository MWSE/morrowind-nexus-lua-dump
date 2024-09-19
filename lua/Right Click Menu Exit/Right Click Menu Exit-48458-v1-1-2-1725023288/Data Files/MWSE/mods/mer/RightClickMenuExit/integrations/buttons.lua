local RCME = require("mer.RightClickMenuExit")
local buttons = {
    { menuId = "MenuInventorySelect", buttonId =  "MenuInventorySelect_button_cancel" },
    { menuId = "MenuMagicSelect", buttonId =  "MenuMagicSelect_button_cancel" },
    { menuId = "MenuQuantity", buttonId =  "MenuQuantity_buttoncancel" },
    { menuId = "MWSE:ModConfigMenu", buttonId = "MWSE:ModConfigMenu_Close" },
    { menuId = "MenuVideo", buttonId =  "MenuVideo_Okbutton" },
    { menuId = "MenuAudio", buttonId =  "MenuAudio_Okbutton" },
    { menuId = "MenuPrefs", buttonId =  "MenuPrefs_Okbutton" },
    { menuId = "MenuSave", buttonId =  "MenuSave_Cancelbutton" },
    { menuId = "MenuLoad", buttonId =  "MenuLoad_Okbutton" },
    { menuId = "MenuOptions", buttonId =  "MenuOptions_Return_container" },
    { menuId = "MenuRestWait", buttonId =  "MenuRestWait_cancel_button" },
    { menuId = "MenuQuick", buttonId =  "MenuQuick_button_cancel" },
    { menuId = "MenuScroll", buttonId =  "MenuScroll_Close" },
    { menuId = "MenuJournal", buttonId =  "MenuBook_button_close" },
    { menuId = "MenuBook", buttonId =  "MenuBook_button_close" },
    { menuId = "MenuAlchemy", buttonId =  "MenuAlchemy_cancel_button" },
    { menuId = "MenuEnchantment", buttonId =  "MenuEnchantment_Cancelbutton" },
    { menuId = "MenuSpellmaking", buttonId =  "MenuSpellmaking_Cancelbutton" },
    { menuId = "MenuServiceTravel", buttonId =  "MenuServiceTravel_Okbutton" },
    { menuId = "MenuServiceTraining", buttonId =  "MenuServiceTraining_Okbutton" },
    { menuId = "MenuServiceSpells", buttonId =  "MenuServiceSpells_Okbutton" },
    { menuId = "MenuServiceRepair", buttonId =  "MenuServiceRepair_Okbutton" },
    { menuId = "MenuRepair", buttonId =  "MenuRepair_Okbutton" },
    { menuId = "MenuPersuasion", buttonId =  "MenuPersuasion_Okbutton" },
    { menuId = "CustomMessageBox", buttonId =  "CustomMessageBox_CancelButton" },
    { menuId = "MenuMessage", buttonId =  "MenuMessage_CancelButton" },
    { menuId = "MenuBarter", buttonId =  "MenuBarter_Cancelbutton" },
    { menuId = "MenuDialog", buttonId =  "MenuDialog_button_bye" },
    { menuId = "MenuContents", buttonId =  "MenuContents_closebutton" },
}

for _, data in pairs(buttons) do
    RCME.registerMenu(data)
end

