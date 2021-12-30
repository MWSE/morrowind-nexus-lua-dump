local data = require("kindi.ancestral tomb amulets.data")
local core = require("kindi.ancestral tomb amulets.core")
local config = require("kindi.ancestral tomb amulets.config")

local EasyMCM = require("easyMCM.EasyMCM")

local template =
    EasyMCM.createTemplate {
    name = "Ancestral Tomb Amulets",
    onClose = function()
        mwse.saveConfig("ancestral_tomb_amulets", config)
    end
}

local page =
    template:createSideBarPage {
    label = "Main",
    description = "All the main setup for the mod is in this page\n"
}

local switch = page:createCategory("Main")
switch:createOnOffButton {
    label = "Mod Status",
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

switch:createButton {
    label = "Reset all main settings to defaults",
    buttonText = "Default",
    description = "All main settings will be reset to default values",
    callback = function()
        config.modActive = true
        config.chance = 7.5
        config.maxCycle = 75
        config.useBestCont = false
        config.littleSecret = false
        config.tombRaider = false
        config.showSpawn = false
        config.showReset = false
        config.affectScripted = false
        config.dangerFactor = true
        config.removeRecycle = false
        config.hotkey = true
        config.hotkeyOpenTable = {keyCode = tes3.scanCode.k}
        config.hotkeyOpenModifier = {keyCode = tes3.scanCode.lShift}

        core.refreshMCM()

        tes3.messageBox("Settings reset to Defaults")
    end
}

local chanceCycle = page:createCategory("Chance and Cycle")
chanceCycle:createTextField {
    label = "Base Chance",
    variable = EasyMCM.createTableVariable {id = "chance", table = config},
    description = "Adjust the base chance to obtain the amulets\n100% chance means all interior cells will always have an amulet to search for provided there is a valid container inside\nA negative(-) value means no amulet can be found in any cell and added chance from other options is ignored.\nMaximum value: 100\nDefault value: 7.5",
    numbersOnly = true,
    callback = function()
        if tonumber(config.chance) > 100 then
            config.chance = 100
        end
    end
}

chanceCycle:createTextField {
    label = "Max Cycle",
    variable = EasyMCM.createTableVariable {id = "maxCycle", table = config},
    description = "How many different cells to be traversed before a cell can roll for amulets again after visiting it\nMinimum value: 0\nDefault value: 75",
    numbersOnly = true,
    callback = function()
        if tonumber(config.maxCycle) < 0 then
            config.maxCycle = 0
        end
    end
}

local keybind = page:createCategory("Hotkeys and Modifiers")
keybind:createOnOffButton {
    label = "ENABLE/DISABLE Hotkey",
    variable = EasyMCM.createTableVariable {id = "hotkey", table = config},
    description = "",
    callback = function()
        if config.hotkey then
            tes3.messageBox("HOTKEY: ON")
        else
            tes3.messageBox("HOTKEY: OFF")
        end
    end
}

keybind:createKeyBinder {
    label = "Hotkey to open the ancestral tomb amulets table",
    description = "Hotkey to open a table list of all ancestral tomb amulets that have been collected",
    variable = EasyMCM.createTableVariable {id = "hotkeyOpenTable", table = config},
    defaultSetting = {
        keyCode = tes3.scanCode.k
    }
}

keybind:createKeyBinder {
    label = "Modifier key for more table interaction",
    description = "Enable more information in the table\n\nSee [HINTS] in [HELP] page for more details",
    variable = EasyMCM.createTableVariable {id = "hotkeyOpenModifier", table = config},
    defaultSetting = {
        keyCode = tes3.scanCode.lShift
    }
}

local gameplay = page:createCategory("Gameplay")
gameplay:createYesNoButton {
    label = "Dangerous cells",
    variable = EasyMCM.createTableVariable {id = "dangerFactor", table = config},
    description = "Dangerous cells, ie. cells that contain powerful enemies or many aggressive actors will have a higher chance to have an amulet inside\nFor example, there is a better chance to find an amulet inside a daedric or dwemer ruin compared to common houses or town buildings.\nThe chance from this will be added to the base chance.",
    callback = function()
        if config.dangerFactor then
            tes3.messageBox("Danger factor is ON")
        else
            tes3.messageBox("Danger factor is OFF")
        end
    end
}

gameplay:createYesNoButton {
    label = "Recycle amulet",
    variable = EasyMCM.createTableVariable {id = "removeRecycle", table = config},
    description = "If an amulet is inside a cell but you exited the cell before obtaining it, the amulet will be removed from the cell and the next cell you visit will have 10% more chance to contain an amulet\nAny cell before this option is activated is not affected.\nThe chance from this will be added to the base chance.",
    callback = function()
        if config.removeRecycle then
            tes3.messageBox("Remove and recycle is ON")
        else
            tes3.messageBox("Remove and recycle is OFF")
        end
    end
}

gameplay:createYesNoButton {
    label = "Best container",
    variable = EasyMCM.createTableVariable {id = "useBestCont", table = config},
    description = "Amulet will spawn inside the best container in the cell, ie. container with the largest capacity.\n",
    callback = function()
        if config.useBestCont then
            tes3.messageBox("Pick best container")
        else
            tes3.messageBox("Pick random container")
        end
    end
}

gameplay:createYesNoButton {
    label = "Tomb raider",
    variable = EasyMCM.createTableVariable {id = "tombRaider", table = config},
    description = "An amulet can always be found inside its associated ancestral tomb if it has not been placed elsewhere yet (yellow)\nIf base chance is negative, this will have no effect.\nIgnores cell cycling.",
    callback = function()
        if config.tombRaider then
            tes3.messageBox("Tomb raider")
        else
            config.deepestTomb = false
            tes3.messageBox("No tomb raiding")
        end
        core.refreshMCM()
    end
}

gameplay:createYesNoButton {
    label = "Deepest Tomb",
    variable = EasyMCM.createTableVariable {id = "deepestTomb", table = config},
    description = "Requires 'Tomb Raider'\n\nAmulet will spawn in the last cell of the tomb\n",
    callback = function()
        if config.deepestTomb then
            config.tombRaider = true
            tes3.messageBox("Deepest Tomb")
        else
            config.tombRaider = false
            tes3.messageBox("Shallowest Tomb")
        end
        core.refreshMCM()
    end
}

local scripted = page:createCategory("Scripted Containers")
scripted:createYesNoButton {
    label = "Scripted Containers",
    variable = EasyMCM.createTableVariable {id = "affectScripted", table = config},
    description = "If yes, then amulets can appear inside scripted containers\nSome mods attach local scripts to containers, for quests or scripted events.\nThis option will prevent unimmersive or unwanted situations to happen.\nSome mods also attach local scripts to base containers, but it is generally not a good practice now\nSetting this to NO is recommended unless you really know what you want.",
    callback = function()
        if config.affectScripted then
            tes3.messageBox("Amulets can appear inside scripted containers")
        else
            tes3.messageBox("Scripted containers will not have amulets")
        end
    end
}

local page2 =
    template:createExclusionsPage {
    label = "Blocked Cells",
    description = "Blocked cells will not spawn ancestral tomb amulets. They still count for cell cycling.\n",
    toggleText = "Toggle Filtered Cells",
    leftListLabel = "Blocked Cells",
    rightListLabel = "Allowed Cells",
    showAllBlocked = false,
    variable = EasyMCM.createTableVariable {
        id = "blockedCells",
        table = config
    },
    filters = {
        {
            label = "Blacklist Cells",
            callback = (function()
                local tombs = {}
                for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
                    if cell.isInterior and cell.id ~= "atakindidummycell" then
                        table.insert(tombs, cell.id)
                    end
                end
                return tombs
            end)
        }
    }
}

local page3 = template:createSideBarPage {label = "Help"}

page3:createCategory {label = data.otherLabel}
page3:createHyperlink {text = "Modpage", exec = string.format("start %s", data.links.modpage)}
page3:createHyperlink {text = "Watch Demo", exec = string.format("start %s", data.links.video)}
page3:createButton {
    inGameOnly = true,
    label = "Hints",
    buttonText = "Hints",
    description = "Table:\n\nGray color-> This amulet has not spawned yet\nYellow color-> The amulet is somewhere in the world, but not in your possession\nBlue color-> Amulet for this tomb is in your possession\nClick-> Teleport to the tomb\nModifier+Click-> Equip amulet\nAlt+Click-> Open Wiki\nClick bag icon/+/- -> Store or return the amulet (+modifier to open storage)\nShift+Hover-> Reveal the location of the amulet (Yellow only) [Cheat]\nClick+LCtrl+LAlt-> Instantly add the amulet to your possession (Gray only) [Cheat]\n\n\nGameplay:\n\nStore/Return-> Storing amulet will hide the amulet from your inventory. The amulet cannot be equipped but can still be used for teleportation\n\nTomb Raider-> Set base chance to 0, and 'Tomb Raider' active to make amulets spawn only inside its Ancestral Tombs\n",
    callback = function()
        tes3.messageBox("Read")
    end
}

page3:createButton {
    inGameOnly = true,
    label = "Fixes all bad amulets in the game",
    buttonText = "Clean",
    description = "If there's an issue with the mod, this will fix the issue, otherwise help submit a bug report.\n\nThis will find all the following amulets and fix them.\nMismatched amulet name/tomb\nDuplicated amulets\nAmulets without any associated tomb in the game\n\nThese usually happen due to updating to newer versions during a playthrough or adding or removing mods that contains new Ancestral Tombs.",
    callback = function()
        core.dropBad()
    end
}

page3:createButton {
    inGameOnly = true,
    label = "Reset all amulets",
    buttonText = "Reset",
    description = "Use this if you wish to recollect all amulets. Amulets will be recreated",
    callback = function()
        core.hardReset()
    end
}

page3:createButton {
    inGameOnly = true,
    label = "Give all amulets for all ancestral tombs in the game",
    buttonText = "Give All",
    description = "Press [RESET] or [CLEAN] first before using.",
    callback = function()
        core.cheat()
    end
}

page3:createButton {
    inGameOnly = true,
    label = "Removes all amulets and progress from the game",
    buttonText = "Uninstall",
    description = "WARNING: All progress will be lost, mod will not function. To undo, press RESET\n",
    callback = function()
        core.hardReset(true)
    end
}

page3:createOnOffButton {
    label = "Amulet Inside Container: Show container name",
    variable = EasyMCM.createTableVariable {id = "showSpawn", table = config},
    description = "This is for debugging, use only for testing",
    callback = function()
        if config.showSpawn then
            tes3.messageBox("ON")
        else
            tes3.messageBox("OFF")
        end
    end
}
page3:createOnOffButton {
    label = "Notify Cell Reset: Show cell name and the container name",
    variable = EasyMCM.createTableVariable {id = "showReset", table = config},
    description = "This is for debugging, use only for testing",
    callback = function()
        if config.showReset then
            tes3.messageBox("ON")
        else
            tes3.messageBox("OFF")
        end
    end
}

EasyMCM.register(template)
