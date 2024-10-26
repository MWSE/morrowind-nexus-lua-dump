local config = require("mer.backstab.config")
local this = {}

this.weaponList = {
    ["Короткие клинки"] = { [tes3.weaponType.shortBladeOneHand] = true },
    ["Длинные клинки (Одноручные)"] = {[tes3.weaponType.longBladeOneHand] = true},
    ["Длинные клинки (Двуручные)"] = {[tes3.weaponType.longBladeTwoClose] = true},
    ["Дробящее оружие (Одноручное)"] = {[tes3.weaponType.bluntOneHand] = true},
    ["Дробящее оружие (Двуручное)"] ={
        [tes3.weaponType.bluntTwoClose] = true, 
        [tes3.weaponType.bluntTwoWide] = true
    },
    ["Копья"] = {[tes3.weaponType.spearTwoWide] = true},
    ["Топоры (Одноручные)"] = {[tes3.weaponType.axeOneHand] = true},
    ["Топоры (Двуручные)"] = {[tes3.weaponType.axeTwoHand] = true},
    ["Оружие дальнего действия"] ={
        [tes3.weaponType.marksmanBow] = true, 
        [tes3.weaponType.marksmanCrossbow] = true, 
        [tes3.weaponType.marksmanThrown] = true, 
        [tes3.weaponType.arrow] = true, 
        [tes3.weaponType.bolt] = true
    },
}

local confTable = config:get()
if not confTable then
    confTable = {
        enableBrutalBackstabbing = true,
        enabledWeaponTypes = { 
            ["Короткие клинки"] = true,
            ["Оружие дальнего действия"] = true,
        },
        stabAttacksOnly = true,
        showBackStabMsg = true
    }
    config.save(confTable)
end



local function registerConfig()

    local template = mwse.mcm.createtemplate{ name = "Удар в спину" }
    template:saveOnClose( config.path, confTable )
    template:register()

    local settingsPage = template:createSideBarPage("Настройки")
    settingsPage:createOnOffButton{
        label = "Включить удар в спину",
        description = "Включить или выключить мод.",
        variable = mwse.mcm.createTableVariable{ id = "enableBrutalBackstabbing", table = confTable }
    }

    settingsPage:createOnOffButton{
        label = "Включить уведомление об ударе в спину",
        description = "Включить всплывающее сообщение при успешном ударе в спину (звук критического удара будет воспроизводиться, даже если эта функция отключена).",
        variable = mwse.mcm.createTableVariable{ id = "showBackStabMsg", table = confTable }
    }

    settingsPage:createOnOffButton{
        label = "Ограничить удары в спину только колющими атаками",
        description = (
            "При включении рубящие и режущие атаки не могут вызвать эффект удара в спину. " ..
            "Это не влияет на оружие дальнего действия (чтобы включить/отключить его, используйте страницу фильтра видов оружия)."
        ),
        variable = mwse.mcm.createTableVariable{ id = "stabAttacksOnly", table = confTable }
    }

    template:createExclusionsPage{
        label = "Фильтр видов вооружения",
        description = "Выберите вид оружия, которым можно наносить удары в спину.",
        variable = mwse.mcm.createTableVariable{ id = "enabledWeaponTypes", table = confTable },
        leftListLabel = "Разрешено",
        rightListLabel = "Заблокировано",
        filters = {
            {
                label = "Виды оружия",
                callback = (
                    function()
                        local list = {}
                        for weaponName, _ in pairs(this.weaponList) do
                            table.insert(list, weaponName)
                        end
                        return list
                    end
                )
            }
        }
    }
end

event.register("modConfigReady", registerConfig)

return this