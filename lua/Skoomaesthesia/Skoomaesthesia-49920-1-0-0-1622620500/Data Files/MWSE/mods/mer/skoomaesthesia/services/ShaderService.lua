local ShaderService = {}
local TripStateService = require('mer.skoomaesthesia.services.TripStateService')

local config = require('mer.skoomaesthesia.config')
local Util = require('mer.skoomaesthesia.util.Util')

local function getDuration(duration)
    local tripping = TripStateService.getState()
    local multi = tripping and config.static.timeShift or 1.0
    return duration * multi
end

function ShaderService.turnOnShaderEffects()
    local DURATION = config.static.onSetTime / config.static.onsetIterations
    local ITERATIONS = config.static.onsetIterations
    local MAX_INTENSITY = config.mcm.maxColor/100
    local MAX_BLUR = math.clamp(config.mcm.maxBlur/100, 0.0, 1.0)
    local INTENSITY_PER_TICK = (MAX_INTENSITY / config.static.onsetIterations)
    local BLUR_PER_TICK = (MAX_BLUR / config.static.onsetIterations)

    Util.log:debug("Turning Shader Effects On. Max Intensity: %s", MAX_INTENSITY)
    local intensity = 0
    local blurRadius = 0
    timer.start{
        typer = timer.real,
        duration = getDuration(DURATION),
        iterations = ITERATIONS,
        callback = function()
            if TripStateService.isState('beginning') or TripStateService.isState('active') then
                intensity = math.clamp((intensity + INTENSITY_PER_TICK), 0, MAX_INTENSITY)
                blurRadius = math.clamp((blurRadius + BLUR_PER_TICK), 0, MAX_BLUR)
                mge.setShaderFloat{
                    shader=config.static.shaderName,
                    variable="intensity",
                    value= intensity
                }
                mge.setShaderFloat{
                    shader=config.static.shaderName,
                    variable="radius",
                    value= blurRadius
                }
                Util.log:trace("ON: set intensity to %s", intensity)
            end
        end
    }
    timer.start{
        type = timer.real,
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
    local DURATION = config.static.onSetTime / config.static.onsetIterations
    local ITERATIONS = config.static.onsetIterations
    local MAX_INTENSITY = config.mcm.maxColor/100
    local MAX_BLUR = math.clamp(config.mcm.maxBlur/100, 0.0, 1.0)
    local INTENSITY_PER_TICK = (MAX_INTENSITY / config.static.onsetIterations)
    local BLUR_PER_TICK = (MAX_BLUR / config.static.onsetIterations)

    Util.log:debug("Turning Shader Effects Off")
    local intensity = MAX_INTENSITY
    local blurRadius = MAX_BLUR
    timer.start{
        typer = timer.real,
        duration = getDuration(DURATION),
        iterations = ITERATIONS+1,--1 extra tick to avoid rounding errors
        callback = function()
            if TripStateService.isState('ending') then
                intensity = math.clamp((intensity - INTENSITY_PER_TICK), 0, MAX_INTENSITY)
                blurRadius = math.clamp((blurRadius - BLUR_PER_TICK), 0, MAX_BLUR)
                mge.setShaderFloat{
                    shader=config.static.shaderName,
                    variable="intensity",
                    value = intensity
                }
                mge.setShaderFloat{
                    shader=config.static.shaderName,
                    variable="radius",
                    value = blurRadius
                }
                Util.log:trace("OFF: set intensity to %s", intensity)
            end
        end
    }
    timer.start{
        type = timer.real,
        duration = getDuration(DURATION*(ITERATIONS+1)+1),
        iterations = 1,
        callback = function()
            if TripStateService.isState('ending') then
                TripStateService.updateState()
                ShaderService.resetShader()
            end
        end
    }
end

function ShaderService.resetShader()
    Util.log:debug("reseting the shader")
    mge.setShaderFloat{
        shader= config.static.shaderName,
        variable="intensity",
        value = 0
    }
    mge.setShaderFloat{
        shader= config.static.shaderName,
        variable="radius",
        value = 0
    }
end

return ShaderService