local this = {}
local common = require("mer.ashfall.common.common")
local conditionConfig = common.staticConfigs.conditionConfig
local fadeTime = 1.5

local faderConfigs = {
    freezing = {
        name = "Freezing",
        texture = "Textures/Ashfall/faders/frozen.dds",
        onSound = "ashfall_freeze",
        condition = "temp",
        conditionMax = conditionConfig.temp.states.freezing.max
    },
    scorching = {
        name = "Scorching",
        texture = "Textures/Ashfall/faders/scorching.dds",
        onSound = "ashfall_scorch",
        condition = "temp",
        conditionMin = conditionConfig.temp.states.scorching.min
    },

}
local function faderSetup()
    for _, config in pairs(faderConfigs) do
        config.fader = tes3fader.new()
        config.fader:setTexture(config.texture)
        config.fader:setColor({ color = { 0.5, 0.5, 0.5 }, flag = false })
        event.register("enterFrame", 
            function()
                config.fader:update()
            end
        )
    end
end
event.register("fadersCreated", faderSetup)

local function setFading(config)
    config.isFading = true
    timer.start{
        type = timer.real, 
        duration = fadeTime,
        callback = function()
            common.log:trace("Setting isFading back to false")
            config.isFading = false
        end
    }
end

local function fadeIn(config)
    config.active = true
    config.fader:fadeTo({ value = 0.5, duration = fadeTime})
    setFading(config)
    if config.onSound then
        local effectsChannel = 2
        tes3.playSound({ sound = config.onSound, mixChannel = effectsChannel })
    end
end

local function fadeOut(config)
    config.active = false
    config.fader:fadeOut({ duration = fadeTime })
    setFading(config)
    if config.offSound then
        local effectsChannel = 2
        tes3.playSound({ sound = config.offSound, mixChannel = effectsChannel })
    end
end


local function checkFaders()
    for _, config in pairs(faderConfigs) do
        if not config.isFading then
            common.log:trace("Not already fading, checking fade values")
            local condition = conditionConfig[config.condition]
            local currentValue = condition:getValue()

            local outOfBounds = false
            if config.conditionMin and currentValue < config.conditionMin then 
                outOfBounds = true 
            end
            if config.conditionMax and currentValue > config.conditionMax then
                outOfBounds = true 
            end
            --Deactivate
            if outOfBounds and config.active then
                fadeOut(config)
            --Activate
            elseif not outOfBounds and not config.active then
                fadeIn(config)
            end
        else
            common.log:trace("wait until fader is finished")
        end
    end
end
event.register("simulate", checkFaders)

event.register("loaded", function()
    for _, config in pairs(faderConfigs) do
        config.isFading = false
        if config.active then
            fadeOut(config)
        end
    end
end)

return this