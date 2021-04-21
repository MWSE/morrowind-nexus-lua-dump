local common = require("mer.QuickLoadouts.common")


local function registerMod()
    EasyMCM = require("easyMCM.EasyMCM")

    local numLoadouts = common.numLoadouts


    local template = EasyMCM.createTemplate("Quick Loadouts")

    for i = 1, numLoadouts do
        local loadoutID = "loadout_" .. i
        local path = "loadouts." .. loadoutID
        local defaultKey =  "numpad" .. i
        local defaultKeyCode = tes3.scanCode[defaultKey]

        local pageName = "Loadout " .. i
        local page = template:createSideBarPage({ label = pageName })

        --sidebar
        local sidebar = page.sidebar:createActiveInfo{
            variable = EasyMCM.createPlayerData{
                id = "loadoutInfo",
                path = path,
            },
        }
        common.sidebar = sidebar

        --Settings
        local cSettings = page:createCategory("Settings")
        cSettings:createTextField{
            label = "Loadout Name: ",
            variable = EasyMCM.createPlayerData{
                id = "name",
                path=path,
                defaultSetting = loadoutID
            },
            callback = function(self)
                tes3.messageBox("Loadout name changed to '%s'", self.variable.value)
                common.updateInfo()
            end
        }

        cSettings:createOnOffButton{
            label = "Enable Loadout",
            variable = EasyMCM.createPlayerData{
                id = "enableLoadout",
                path=path,
                defaultSetting = false
            }
        }
        cSettings:createKeyBinder{
            label = "Hotkey: Equip loadout",
            allowCombinations = true,
            variable = EasyMCM.createPlayerData{
                id="hotkey",
                path=path,
                defaultSetting = { keyCode = defaultKeyCode}
            },
            getLetter = function(self, keyCode)
                for letter, code in pairs(tes3.scanCode) do
                    if code == keyCode then
                        return string.upper(letter)
                    end
                end 
                return nil
            end
        }
        cSettings:createKeyBinder{
            label = "Hotkey: Set loadout to current equipment",
            allowCombinations = true,
            variable = EasyMCM.createPlayerData{
                id="assignKey",
                path=path,
                defaultSetting = { keyCode = defaultKeyCode, isShiftDown = true }
            },
            getLetter = function(self, keyCode)
                for letter, code in pairs(tes3.scanCode) do
                    if code == keyCode then
                        return string.upper(letter)
                    end
                end 
                return nil
            end,
        }
        cSettings:createButton{
            buttonText = "Set current equipment to loadout",
            id = loadoutID,
            inGameOnly = true,
            callback = common.assignLoadout
        }

        --Weapons
        local cWeapons = page:createSideBySideBlock("Weapons")
        cWeapons:createYesNoButton{
            label = "Include",
            description = "Include weapons in this loadout.",
            variable = EasyMCM.createPlayerData{
                id = "includeWeapons",
                path = path,
                defaultSetting = true
            }
        }
        cWeapons:createYesNoButton{
            label = "Force Unequip",
            description = "When selected, empty slots in the loadout will force unequip whatever you are wearing when you equip it.",
            variable = EasyMCM.createPlayerData{
                id = "unequipWeapons",
                path = path,
                defaultSetting = true
            }
        }

        --Shield
        local cShield = page:createSideBySideBlock("Shield")
        cShield:createYesNoButton{
            label = "Include",
            description = "Include shield in this loadout.",
            variable = EasyMCM.createPlayerData{
                id = "includeShield",
                path = path,
                defaultSetting = true
            }
        }
        cShield:createYesNoButton{
            label = "Force Unequip",
            description = "When selected, empty slots in the loadout will force unequip whatever you are wearing when you equip it.",
            variable = EasyMCM.createPlayerData{
                id = "unequipShield",
                path = path,
                defaultSetting = true
            } 
        }
        --Armor
        local cArmor = page:createSideBySideBlock("Armor")
        cArmor:createYesNoButton{
            label = "Include",
            description = "Include armor in this loadout.",
            variable = EasyMCM.createPlayerData{
                id = "includeArmor",
                path = path,
                defaultSetting = true
            }            
        }
        cArmor:createYesNoButton{
            label = "Force Unequip",
            description = "When selected, empty slots in the loadout will force unequip whatever you are wearing when you equip it.",
            variable = EasyMCM.createPlayerData{
                id = "unequipArmor",
                path = path,
                defaultSetting = true
            } 
        }

        --Clothing
        local cClothing = page:createSideBySideBlock("Clothing")
        cClothing:createYesNoButton{
            label = "Include",
            description = "Include clothing in this loadout.",
            variable = EasyMCM.createPlayerData{
                id = "includeClothing",
                path = path,
                defaultSetting = true
            }            
        }
        cClothing:createYesNoButton{
            label = "Force Unequip",
            description = "When selected, empty slots in the loadout will force unequip whatever you are wearing when you equip it.",
            variable = EasyMCM.createPlayerData{
                id = "unequipClothing",
                path = path,
                defaultSetting = true
            }
        }
        --Accessories
        local cAccessories = page:createSideBySideBlock("Accessories")
        cAccessories:createYesNoButton{
            label = "Include",
            description = "Include accessories (belt, rings, amulet) in this loadout.",
            variable = EasyMCM.createPlayerData{
                id = "includeAccessories",
                path = path,
                defaultSetting = true
            }
        }
        cAccessories:createYesNoButton{
            label = "Force Unequip",
            description = "When selected, empty slots in the loadout will force unequip whatever you are wearing when you equip it.",
            variable = EasyMCM.createPlayerData{
                id = "unequipAccessories",
                path = path,
                defaultSetting = true
            }            
        }
    end


    template:register()
end

event.register("modConfigReady", registerMod)
