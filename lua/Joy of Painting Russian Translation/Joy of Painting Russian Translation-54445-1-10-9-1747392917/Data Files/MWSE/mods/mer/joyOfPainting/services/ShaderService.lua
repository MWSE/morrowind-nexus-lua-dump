local ShaderService = {}

local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("ShaderService")

---@param shaderId string
---@return mgeShaderHandle
local function getShader(shaderId)
    local shader = mge.shaders.find{ name = shaderId}
    if not shader then
        shader = mgeShadersConfig.load({ name = shaderId })
    end
    return shader
end

---comment
---@param shaderId string
---@param isEnabled boolean
function ShaderService.setEnabled(shaderId, isEnabled)
    local shader = getShader(shaderId)
    if shader then
        shader.enabled = isEnabled
    else
        logger:error("ShaderService %s not found", shaderId)
    end
end

function ShaderService.isEnabled(shaderId)
    local shader = getShader(shaderId)
    return shader and shader.enabled
end

---@param shaderId string
function ShaderService.enable(shaderId)
    logger:debug("Enabling shader: %s", shaderId)
    ShaderService.setEnabled(shaderId, true)
end

---@param shaderId string
function ShaderService.disable(shaderId)
    logger:debug("Disabling shader: %s", shaderId)
    ShaderService.setEnabled(shaderId, false)
end

---@param shaderId string
---@param uniformName string
---@param value any
function ShaderService.setUniform(shaderId, uniformName, value)
    local shader = getShader(shaderId)
    if shader then
        shader[uniformName] = value
    else
        logger:error("ShaderService %s not found", shaderId)
    end
end

function ShaderService.reload(shaderId)
    local shader = getShader(shaderId)
    if shader then
        shader:reload()
    else
        logger:error("ShaderService %s not found", shaderId)
    end
end

return ShaderService
