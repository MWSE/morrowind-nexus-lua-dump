local ShaderService = {}

local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("ShaderService")

function ShaderService.getShader(shaderId)
    local shader = mge.shaders.find{ name = shaderId}
    if not shader then
        shader = mgeShadersConfig.load({ name = shaderId })
    end
    return shader
end

function ShaderService.setEnabled(shaderId, isEnabled)
    local shader = ShaderService.getShader(shaderId)
    if shader then
        shader.enabled = isEnabled
    else
        logger:error("ShaderService %s not found", shaderId)
    end
end

function ShaderService.enable(shaderId)
    logger:debug("Enabling shader: %s", shaderId)
    ShaderService.setEnabled(shaderId, true)
end

function ShaderService.disable(shaderId)
    logger:debug("Disabling shader: %s", shaderId)
    ShaderService.setEnabled(shaderId, false)
end

function ShaderService.setUniform(shaderId, uniformName, value)
    local shader = ShaderService.getShader(shaderId)
    if shader then
        shader[uniformName] = value
    else
        logger:error("ShaderService %s not found", shaderId)
    end
end

return ShaderService

