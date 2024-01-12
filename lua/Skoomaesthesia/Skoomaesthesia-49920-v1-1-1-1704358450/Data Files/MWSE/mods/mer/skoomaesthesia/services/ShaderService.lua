
local common = require('mer.skoomaesthesia.common')
local logger = common.createLogger("ShaderService")
local config = require('mer.skoomaesthesia.config')
local TripStateService = require('mer.skoomaesthesia.services.TripStateService')
local ShaderService = {}

local function getDuration(duration)
    local tripping = TripStateService.getState()
    local multi = tripping and config.static.timeShift or 1.0
    return duration * multi
end

function ShaderService.getShader(shaderId)
    shaderId = shaderId or config.static.shaderName
    local shader = mge.shaders.find{ name = shaderId}
    if not shader then
        shader = mgeShadersConfig.load({ name = shaderId })
    end
    return shader
end

function ShaderService.turnOnShaderEffects()
    local shader = ShaderService.getShader()
    shader.enabled = true

    local DURATION = config.static.onSetTime / config.static.onsetIterations
    local ITERATIONS = config.static.onsetIterations
    local MAX_INTENSITY = config.mcm.maxColor/100
    local MAX_BLUR = math.clamp(config.mcm.maxBlur/100, 0.0, 1.0)
    local INTENSITY_PER_TICK = (MAX_INTENSITY / config.static.onsetIterations)
    local BLUR_PER_TICK = (MAX_BLUR / config.static.onsetIterations)

    logger:debug("Turning Shader Effects On. Max Intensity: %s", MAX_INTENSITY)
    local intensity = 0
    local blurRadius = 0
    timer.start{
        typer = timer.simulate,
        duration = getDuration(DURATION),
        iterations = ITERATIONS,
        callback = function()
            if TripStateService.isState('beginning') or TripStateService.isState('active') then
                intensity = math.clamp((intensity + INTENSITY_PER_TICK), 0, MAX_INTENSITY)
                shader.intensity = intensity
                blurRadius = math.clamp((blurRadius + BLUR_PER_TICK), 0, MAX_BLUR)
                shader.radius = blurRadius
                logger:trace("ON: set intensity to %s", intensity)
            end
        end
    }
    timer.start{
        type = timer.simulate,
        duration = getDuration(config.static.onSetTime),
        iterations = 1,
        callback = function()
            if TripStateService.isState('beginning') then
                TripStateService.updateState('active')
            end
        end
    }
end


function ShaderService.turnOffShaderEffects()
    local shader = ShaderService.getShader()

    local DURATION = config.static.onSetTime / config.static.onsetIterations
    local ITERATIONS = config.static.onsetIterations
    local MAX_INTENSITY = config.mcm.maxColor/100
    local MAX_BLUR = math.clamp(config.mcm.maxBlur/100, 0.0, 1.0)
    local INTENSITY_PER_TICK = (MAX_INTENSITY / config.static.onsetIterations)
    local BLUR_PER_TICK = (MAX_BLUR / config.static.onsetIterations)

    logger:debug("Turning Shader Effects Off")
    local intensity = MAX_INTENSITY
    local blurRadius = MAX_BLUR
    timer.start{
        type = timer.simulate,
        duration = getDuration(DURATION),
        iterations = ITERATIONS+1,--1 extra tick to avoid rounding errors
        callback = function()
            if TripStateService.isState('ending') then
                intensity = math.clamp((intensity - INTENSITY_PER_TICK), 0, MAX_INTENSITY)
                shader.intensity = intensity
                blurRadius = math.clamp((blurRadius - BLUR_PER_TICK), 0, MAX_BLUR)
                shader.radius = blurRadius
                logger:trace("OFF: set intensity to %s", intensity)
            end
        end
    }
    timer.start{
        type = timer.simulate,
        duration = getDuration(DURATION*(ITERATIONS+1)+1),
        iterations = 1,
        callback = function()
            if TripStateService.isState('ending') then
                shader.enabled = false
            end
        end
    }
end

function ShaderService.resetShader()
    logger:debug("reseting the shader")
    local shader = ShaderService.getShader()
    shader.enabled = false
end



return ShaderService