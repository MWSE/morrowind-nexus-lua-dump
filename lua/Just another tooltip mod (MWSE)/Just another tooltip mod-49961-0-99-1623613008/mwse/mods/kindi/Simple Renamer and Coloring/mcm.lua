local config = require("kindi.simple renamer and coloring.config")
local EasyMCM = require("easyMCM.EasyMCM")

local template =
    EasyMCM.createTemplate {
    name = "Simple Renamer and Coloring",
    onClose = function()
        mwse.saveConfig("simple_renamer", config)
    end
}

local page =
    template:createSideBarPage {
    label = "Main",
    description = "1. To use, press the extrakey+hotkey while targeting an object to open the rename window\n\n2. To save, press extrakey+hotkey again\n\n3. To cancel, use the menumode key (see your controls setting) to exit the window without saving\n\n4. To create newline, use return (enter) key in the text input\n\n5. You cannot create newline in name input. Name input will only accept one color\n\n6. Info input can have as many newlines with different colors as you want\n\n"
}

local switch = page:createCategory("Main")
switch:createOnOffButton {
    label = "Allow mod to work?",
    variable = EasyMCM.createTableVariable {id = "modActive", table = config},
    description = "The state of the mod.",
    callback = function()
        if config.modActive then
            tes3.messageBox("ON")
        else
            tes3.messageBox("OFF")
        end
    end
}





local keybind = page:createCategory("Hotkeys and Modifiers")
keybind:createOnOffButton {
    label = "Enable hotkey?",
    variable = EasyMCM.createTableVariable {id = "allowHotkey", table = config},
    description = "When ON, you can use hotkey",
    callback = function()
        if config.allowHotkey then
            tes3.messageBox("Hotkey: ON")
        else
            tes3.messageBox("Hotkey: OFF")
        end
    end
}

keybind:createKeyBinder {
    label = "Hotkey to rename and save changes",
    description = "Hotkey to rename and save changes",
    variable = EasyMCM.createTableVariable {id = "mainHotkey", table = config},
    defaultSetting = {
        keyCode = tes3.scanCode.enter
    }
}

keybind:createOnOffButton {
    label = "Enable extra key? (Recommended)",
    variable = EasyMCM.createTableVariable {id = "allowModi", table = config},
    description = "When ON, you must press this with hotkey to rename and save changes",
    callback = function()
        if config.allowModi then
            tes3.messageBox("Modifier: ON")
        else
            tes3.messageBox("Modifier: OFF")
        end
    end
}

keybind:createKeyBinder {
    label = "Extra key to press with hotkey",
    description = "Extra key to press to rename and save changes",
    variable = EasyMCM.createTableVariable {id = "modiHotkey", table = config},
    defaultSetting = {
        keyCode = tes3.scanCode.lShift
    }
}



EasyMCM.register(template)
