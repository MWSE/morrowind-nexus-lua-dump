local config = require('mer.guarnoCoffee.config')
local modName = config.modName
local mcmConfig = mwse.loadConfig(modName, config.mcmDefaultValues)
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
            teaName = "Guarno Coffee",
            teaDescription = "A delicious coffee made from partially digested comberries harvested from guar droppings. Its strong, musky taste hardens one's endurance.",
            effectDescription = "Fortify Endurance 10 Points",
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
        tes3.messageBox("*brrrrap*")
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
    template:saveOnClose(modName, mcmConfig)
    template:register()

    local settings = template:createSideBarPage("Settings")
    settings.description = config.modDescription

    settings:createOnOffButton{
        label = string.format("Enable %s", modName),
        description = "Turn the mod on or off.",
        variable = mwse.mcm.createTableVariable{id = "enabled", table = mcmConfig}
    }
    settings:createOnOffButton{
        label = "Debug Mode",
        description = "Prints debug messages to mwse.log.",
        variable = mwse.mcm.createTableVariable{id = "debug", table = mcmConfig}
    }
    settings:createSlider{
        label = "Digestion Interval",
        description = "Average time between eating a comberry and shitting it out.",
        min = 1, max = 12,
        variable = mwse.mcm.createTableVariable{ id = "digestionInterval", table = mcmConfig}
    }
end
event.register("modConfigReady", registerModConfig)



