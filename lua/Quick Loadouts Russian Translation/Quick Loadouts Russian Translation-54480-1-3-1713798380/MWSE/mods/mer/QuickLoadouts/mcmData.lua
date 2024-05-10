local common = require("mer.QuickLoadouts.common")


local function registerMod()
    EasyMCM = require("easyMCM.EasyMCM")

    local numLoadouts = common.numLoadouts


    local template = EasyMCM.createTemplate("Быстрые комплекты снаряжения")

    for i = 1, numLoadouts do
        local loadoutID = "loadout_" .. i
        local path = "loadouts." .. loadoutID
        local defaultKey =  "numpad" .. i
        local defaultKeyCode = tes3.scanCode[defaultKey]

        local pageName = "Комплект " .. i
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
        local cSettings = page:createCategory("Настройки")
        cSettings:createTextField{
            label = "Название комплекта: ",
            variable = EasyMCM.createPlayerData{
                id = "name",
                path=path,
                defaultSetting = loadoutID
            },
            callback = function(self)
                tes3.messageBox("Название комплекта изменено на '%s'", self.variable.value)
                common.updateInfo()
            end
        }

        cSettings:createOnOffButton{
            label = "Включить комплект",
            variable = EasyMCM.createPlayerData{
                id = "enableLoadout",
                path=path,
                defaultSetting = false
            }
        }
        cSettings:createKeyBinder{
            label = "Горячая клавиша: Экипировать комплект",
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
            label = "Горячая клавиша: Сохранить текущее снаряжение в комплект",
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
            buttonText = "Сохранить текущее снаряжение в комплект",
            id = loadoutID,
            inGameOnly = true,
            callback = common.assignLoadout
        }

        --Weapons
        local cWeapons = page:createSideBySideBlock("Оружие")
        cWeapons:createYesNoButton{
            label = "Включить",
            description = "Включить оружие в этот комплект",
            variable = EasyMCM.createPlayerData{
                id = "includeWeapons",
                path = path,
                defaultSetting = true
            }
        }
        cWeapons:createYesNoButton{
            label = "Снять принудительно",
            description = "При включении этой опции, текущие предметы экпировки будут принудительно сниматься, даже со слотов, не занятых в комплекте.",
            variable = EasyMCM.createPlayerData{
                id = "unequipWeapons",
                path = path,
                defaultSetting = true
            }
        }

        --Shield
        local cShield = page:createSideBySideBlock("Щит")
        cShield:createYesNoButton{
            label = "Включить",
            description = "Включить щит в этот комплект",
            variable = EasyMCM.createPlayerData{
                id = "includeShield",
                path = path,
                defaultSetting = true
            }
        }
        cShield:createYesNoButton{
            label = "Снять принудительно",
            description = "При включении этой опции, текущие предметы экпировки будут принудительно сниматься, даже со слотов, не занятых в комплекте.",
            variable = EasyMCM.createPlayerData{
                id = "unequipShield",
                path = path,
                defaultSetting = true
            } 
        }
        --Armor
        local cArmor = page:createSideBySideBlock("Броня")
        cArmor:createYesNoButton{
            label = "Включить",
            description = "Включить броню в этот комплект",
            variable = EasyMCM.createPlayerData{
                id = "includeArmor",
                path = path,
                defaultSetting = true
            }            
        }
        cArmor:createYesNoButton{
            label = "Снять принудительно",
            description = "При включении этой опции, текущие предметы экпировки будут принудительно сниматься, даже со слотов, не занятых в комплекте.",
            variable = EasyMCM.createPlayerData{
                id = "unequipArmor",
                path = path,
                defaultSetting = true
            } 
        }

        --Clothing
        local cClothing = page:createSideBySideBlock("Одежда")
        cClothing:createYesNoButton{
            label = "Включить",
            description = "Включить одежду в этот комплект",
            variable = EasyMCM.createPlayerData{
                id = "includeClothing",
                path = path,
                defaultSetting = true
            }            
        }
        cClothing:createYesNoButton{
            label = "Снять принудительно",
            description = "При включении этой опции, текущие предметы экпировки будут принудительно сниматься, даже со слотов, не занятых в комплекте.",
            variable = EasyMCM.createPlayerData{
                id = "unequipClothing",
                path = path,
                defaultSetting = true
            }
        }
        --Accessories
        local cAccessories = page:createSideBySideBlock("Аксессуары")
        cAccessories:createYesNoButton{
            label = "Включить",
            description = "Включить аксессуары (пояс, кольца, амулет) в этот комплект",
            variable = EasyMCM.createPlayerData{
                id = "includeAccessories",
                path = path,
                defaultSetting = true
            }
        }
        cAccessories:createYesNoButton{
            label = "Снять принудительно",
            description = "При включении этой опции, текущие предметы экпировки будут принудительно сниматься, даже со слотов, не занятых в комплекте.",
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
