local config = require('mer.guarnoCoffee.config')
local modName = config.modName
local configPath = config.configPath
local mcmConfig = mwse.loadConfig(configPath, config.mcmDefaultValues)
local data--saved on tes3.player.data

local function debug(message, ...)
    if mcmConfig.debug then
        local output = string.format("[%s] %s", modName, tostring(message):format(...) )
        mwse.log(output)
    end
end

local function now()
    return (tes3.worldController.daysPassed.value * 24) + tes3.worldController.hour.value
end

local ashfall = include('mer.ashfall.interop')
if ashfall then
    ashfall.registerTeas{
        [config.guarnoId] = {
            teaName = "Кофе Гуарно",
            teaDescription = "Крепкий напиток сваренный из частично переваренных ягод комуники, собранных из помета гуара. Его сильный мускусный вкус повышает выносливость.",
            effectDescription = "Улучшение выносливости 10 п.",
            duration = 6,
            spell = {
                id = "guarno_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
                        attribute = tes3.attribute.endurance

                    }
                }
            }
        }
    }
end

local function getDigestionTime()
    return math.random(mcmConfig.digestionInterval-1, mcmConfig.digestionInterval+1)
end

local function guarAteFood(e)
    if not mcmConfig.enabled then return end
    debug("ate %s", e.itemId)
    if config.comberryIds[e.itemId:lower()] then
        debug("setting timeToGuarnoPoop")
        if not e.reference.data.timeToGuarnoPoop then
            e.reference.data.timeToGuarnoPoop = now() + getDigestionTime()
        end
    end
end
event.register("GuarWhisperer:AteFood", guarAteFood)

local function shit(ref)
    tes3.playSound{ reference = ref, soundPath = "\\guarno\\shit.wav" }
    if ref.position:distance(tes3.player.position) < 500 then
        tes3.messageBox("*бррррррр*")
    end
    tes3.createReference{
        object = config.guarnoId,
        position = ref.position:copy(),
        cell = ref.cell
    }
    ref.data.timeToGuarnoPoop = nil
end


local function checkForGuarShit()
    if not mcmConfig.enabled then return end
    for _, cell in pairs(tes3.getActiveCells()) do
        for reference in cell:iterateReferences(tes3.objectType.creature) do
            if reference.data.timeToGuarnoPoop then
                if now() > reference.data.timeToGuarnoPoop then
                    shit(reference)
                end
            end
        end
    end
end

local function startShitTimer(e)
    debug("starting shit timer")
    timer.start{
        duration = 1,
        type = timer.simulate,
        iterations = -1,
        callback = checkForGuarShit
    }
end
event.register("loaded", startShitTimer)



--MCM MENU
local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = modName }
    template:saveOnClose(configPath, mcmConfig)
    template:register()

    local settings = template:createSideBarPage("Настройки")
    settings.description = config.modDescription

    settings:createOnOffButton{
        label = string.format("Включить %s", modName),
        description = "Включить или выключить мод.",
        variable = mwse.mcm.createTableVariable{id = "enabled", table = mcmConfig}
    }
    settings:createOnOffButton{
        label = "Режим отладки",
        description = "Вывод отладочных сообщений в mwse.log.",
        variable = mwse.mcm.createTableVariable{id = "debug", table = mcmConfig}
    }
    settings:createSlider{
        label = "Продолжительность пищеварения",
        description = "Среднее время между поеданием ягод комуники и испражнением.",
        min = 1, max = 12,
        variable = mwse.mcm.createTableVariable{ id = "digestionInterval", table = mcmConfig}
    }
end
event.register("modConfigReady", registerModConfig)



