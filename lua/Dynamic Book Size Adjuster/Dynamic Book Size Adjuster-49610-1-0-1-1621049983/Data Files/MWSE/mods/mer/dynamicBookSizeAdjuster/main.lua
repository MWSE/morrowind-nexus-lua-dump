local config = require('mer.dynamicBookSizeAdjuster.config')
local modName = config.modName
local mcmConfig = mwse.loadConfig(modName, config.mcmDefaultValues)
local data--saved on tes3.player.data

local function debug(message, ...)
    if mcmConfig.debug then
        local output = string.format("[%s] %s", modName, tostring(message):format(...) )
        mwse.log(output)
    end
end


local function modEnabled()
    return mcmConfig.enabled == true
end

local function isBook(reference)
    return reference.object.objectType == tes3.objectType.book
        and reference.object.type == 0
end
local function onItemDropped(e)
    if modEnabled() then
        if isBook(e.reference) then
            e.reference.scale = (mcmConfig.scale / 100)
        end
    end
end
event.register("itemDropped", onItemDropped)


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
    settings:createSlider{
        label = "Book Scale: %s%%",
        description = "The scale placed books should be adjusted to.",
        min = 1, max = 1000,
        step = 1, jump = 10,
        variable = mwse.mcm.createTableVariable{ id = "scale", table = mcmConfig}
    }
    settings:createOnOffButton{
        label = "Debug Mode",
        description = "Prints debug messages to mwse.log.",
        variable = mwse.mcm.createTableVariable{id = "debug", table = mcmConfig}
    }
end
event.register("modConfigReady", registerModConfig)
