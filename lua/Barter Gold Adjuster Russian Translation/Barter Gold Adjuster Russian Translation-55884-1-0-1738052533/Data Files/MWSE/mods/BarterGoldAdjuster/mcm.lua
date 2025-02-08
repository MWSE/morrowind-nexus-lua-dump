local modInfo = require("BarterGoldAdjuster.modInfo")
local config = require("BarterGoldAdjuster.config")
local common = require("BarterGoldAdjuster.common")
local list

local function checkActor(actor)
    if common.isMerchant(actor) then
        table.insert(list, actor.id:lower())
    end
end

-- Returns a list of the ID of every merchant in the game, to populate the blacklist.
local function blacklist()
    list = {}

    for actor in tes3.iterateObjects(tes3.objectType.npc) do
        checkActor(actor)
    end

    for actor in tes3.iterateObjects(tes3.objectType.creature) do
        checkActor(actor)
    end

    table.sort(list)
    return list
end

local function createPage(template)
    local page = template:createSideBarPage{
        label = "Основные настройки",
        description =
            modInfo.mod .. "\n" ..
            "Версия " .. modInfo.version .. "\n" ..
            "\n" ..
            "Этот мод позволяет вам настроить количество золота у торговцев.\n" ..
            "\n" ..
            "Наведите курсор на определенную настройку, чтобы узнать за что она отвечает.",
    }

    page:createTextField{
        label = "Множитель",
        description =
            "Золото торговцев из оригинальной игры (или добавленных модами) будет умножено на это значение, с учетом настроек нижнего и верхнего значений.\n" ..
            "\n" ..
            "Допускаются дробные числа. Отрицательные числа будут расцениваться как 0.\n" ..
            "\n" ..
            "По умолчанию: 1",
        variable = mwse.mcm.createTableVariable{
            id = "mult",
            table = config,
            numbersOnly = true,
        },
        defaultSetting = 1,
        restartRequired = true,
    }

    page:createTextField{
        label = "Нижнее значение",
        description =
            "Если золото торговцев после применения множителя окажется ниже этого значения, оно будет увеличено до указанного тут числа.\n" ..
            "\n" ..
            "Дробные числа будут округляться в меньшую сторону. Отрицательные числа будут расцениваться как 0.\n" ..
            "\n" ..
            "По умолчанию: 0",
        variable = mwse.mcm.createTableVariable{
            id = "floor",
            table = config,
            numbersOnly = true,
        },
        defaultSetting = 0,
        restartRequired = true,
    }

    page:createTextField{
        label = "Верхнее значение",
        description =
            "Если золото торговцев после применения множителя окажется выше этого значения, оно будет уменьшено до указанного тут числа.\n" ..
            "\n" ..
            "Дробные числа будут округляться в меньшую сторону. Отрицательное значение для этого параметра имеет особую функцию: оно означает, что верхнего ограничения на золото торговцев не будет.\n" ..
            "\n" ..
            "По умолчанию: -1 (нет верхнего ограничения)",
        variable = mwse.mcm.createTableVariable{
            id = "cap",
            table = config,
            numbersOnly = true,
        },
        defaultSetting = -1,
        restartRequired = true,
    }

    return page
end

local function createBlacklistPage(template)
    template:createExclusionsPage{
        label = "Черный список",
        description = "На этой вкладке можно внести определенных торговцев в черный список. Это запретит моду влиять на колличество золота у торговцев, внесенных в черный список. Для того, что бы изменения черного списка вступили в силу потребуется перезапуск игры.",
        leftListLabel = "Черный список торговцев",
        rightListLabel = "Торговцы",
        variable = mwse.mcm.createTableVariable{
            id = "blacklist",
            table = config,
        },
        filters = {
            { callback = blacklist },
        },
    }
end

local template = mwse.mcm.createTemplate("Золото торговцев")
template:saveOnClose("BarterGoldAdjuster", config)

createPage(template)
createBlacklistPage(template)

mwse.mcm.register(template)