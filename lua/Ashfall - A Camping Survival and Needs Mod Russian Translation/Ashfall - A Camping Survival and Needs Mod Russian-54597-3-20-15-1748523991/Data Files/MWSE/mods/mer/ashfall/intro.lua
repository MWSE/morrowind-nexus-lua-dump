local common = require("mer.ashfall.common.common")
local logger = common.createLogger("intro")
local config = require("mer.ashfall.config").config
local overrides = require("mer.ashfall.config.overrides")
local this = {}
local newGame
local checkingChargen
local charGen
local charGenValues = {
    newGame = 10,
    charGenFinished = -1
}

function this.doNeeds(needs)
    for setting, value in pairs(needs) do
        logger:debug("Setting %s to %s", setting, value)
        config[setting] = value
    end
    event.trigger("Ashfall:UpdateHUD")
    event.trigger("Ashfall:UpdateNeedsUI")
end

function this.doTimeScale()
    local timeScale = config.manualTimeScale
    tes3.setGlobal("TimeScale", timeScale)
end

function this.doOverrides()
    for id, override in pairs(overrides) do
        local item = tes3.getObject(id)
        if item then
            logger:trace("Overriding values for %s", item.id)
            if override.name then
                item.name = override.name
            end
            if override.value then
                item.value = override.value
            end
            if override.weight then
                item.weight = override.weight
            end
        else
            logger:trace("%s not found", id)
        end
    end
end

function this.confirmManualConfigure()
    return
end


function this.doDefaultSettings()
    tes3.messageBox("Пеплопад использует настройки по умолчанию")
    config.doIntro = false
    config.overrideFood = true
    config.manualTimeScale = common.defaultValues.manualTimeScale
    this.doTimeScale()
    this.doOverrides()
    this.doNeeds({
        enableTemperatureEffects = true,
        enableHunger = true,
        enableThirst = true,
        enableTiredness = true,
        enableSickness = true,
        enableBlightness = true,
    })
    config.save()
end

function this.confirmDefaultSettings()
    local message = string.format(
        "Настройки по умолчанию: Все потребности включены. Временная шкала установлена на 20. Вес и значения элементов настроены. \n\nВы можете изменить эту настройку в меню настройки мода в любое время. Приступить?",
        common.defaultValues.manualTimeScale
    )
    tes3ui.showMessageMenu{
        message = message,
        buttons = {
            { text = "Ок", callback = this.doDefaultSettings
        },
            { text = "Назад", callback = this.startAshfall }
        }
    }
end


function this.doVanillaSettings()
    tes3.messageBox("Пеплопад использует настройки игры (без изменений).")
    config.doIntro = false
    config.overrideTimeScale = false
    config.overrideFood = false
    this.doNeeds({
        enableTemperatureEffects = true,
        enableHunger = true,
        enableThirst = true,
        enableTiredness = true,
        enableSickness = true,
        enableBlightness = true,
    })
    config.save()
end
function this.confirmVanillaSettings()
    tes3ui.showMessageMenu{
        message = "Настройки игры: шкала времени и другие значения элементов остануться без изменений. \n\nВы можете изменить эту настройку в меню настройки мода в любое время. Приступить?",
        buttons = {
            { text = "Ок", callback = this.doVanillaSettings },
            { text = "Назад", callback = this.startAshfall }
        }
    }
end

function this.disableAshfall()
    tes3.messageBox("Выбранные механики отключены.")
    config.doIntro = false
    config.overrideTimeScale = false
    config.overrideFood = false
    this.doNeeds({
        enableTemperatureEffects = false,
        enableHunger = false,
        enableThirst = false,
        enableTiredness = false,
        enableSickness = false,
        enableBlightness = false,
    })
    config.save()
end


function this.startAshfall()

    if config.doIntro == true then
        local introMessage = (
            "Добро пожаловать в Пеплопад! \n"..
            "Пожалуйста, уделите время настройке параметров запуска. \n"..
            "Вам придется сделать это только один раз."
        )
        local buttons = {
            -- {
            --     text = "Configure",
            --     callback = this.confirmManualConfigure
            -- },
            {
                text = "Использовать настройки по умолчанию (рекомендуется)",
                callback = this.confirmDefaultSettings
            },
            {
                text = "Использовать настройки игры",
                callback = this.confirmVanillaSettings
            },
            {
                text = "Отключить Пеплопад",
                callback = this.disableAshfall
            }
        }
        tes3ui.showMessageMenu{ message = introMessage, buttons = buttons}
    else
        --initialise defaults
        if config.overrideTimeScale and newGame then
            this.doTimeScale()
        end
        local doOverrideFood = config.overrideFood
        if doOverrideFood then
            logger:debug("Overriding ingredient values")
            this.doOverrides()
        end

    end
end


local function checkCharGen()
    if charGen.value == charGenValues.newGame then
        newGame = true
    elseif newGame and charGen.value == charGenValues.charGenFinished then
        checkingChargen = false
        event.unregister("simulate", checkCharGen)
        timer.start{
            type = timer.simulate,
            duration = 2.0, --If clashes with char backgrounds, mess with this
            callback = this.startAshfall
        }
        if config.startingEquipment then
            tes3.addItem{reference = tes3.player, item ="ashfall_bedroll"}
            tes3.addItem{reference = tes3.player, item="ashfall_cooking_pot"}
            tes3.addItem{reference = tes3.player, item="misc_com_iron_ladle"}
            tes3.addItem{reference = tes3.player, item="ashfall_woodaxe"}
        end
    end
end

local legacyItemMapping = {
    ashfall_tent_ashl_misc = "ashfall_tent_ashl_m",
    ashfall_tent_misc = "ashfall_tent_base_m",
    ashfall_backpack_b = "ashfall_pack_01",
    ashfall_backpack_w = "ashfall_pack_02",
    ashfall_backpack_n = "ashfall_pack_03",
}


local function replaceLegacyItems()
    for stack in tes3.iterate(tes3.player.object.inventory.iterator) do
        local newItem = legacyItemMapping[stack.object.id:lower()]
        if newItem then
            logger:debug("Found %s, replacing with a shiny new one: %s", stack.object.id, newItem)
            tes3.removeItem{ reference = tes3.player, item = stack.object, count = stack.count, playSound = false }
            tes3.addItem{ reference = tes3.player, item = newItem, count = stack.count, updateGUI = true, playSound = false }
        end
    end
end


local function onDataLoaded(e)
    newGame = nil --reset so we can check chargen state again
    charGen = tes3.findGlobal("CharGenState")
    if charGen.value == charGenValues.charGenFinished then
        this.startAshfall()
    else
        --Only reregister if necessary. If new game was started during
        --  chargen of previous game, this will already be running
        if not checkingChargen then
            event.register("simulate", checkCharGen)
            checkingChargen = true
        end
    end
    replaceLegacyItems()
end

event.register("Ashfall:dataLoaded", onDataLoaded )