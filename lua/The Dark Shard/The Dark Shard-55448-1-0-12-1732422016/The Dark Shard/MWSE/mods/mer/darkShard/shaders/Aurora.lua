---@class DarkShard.AuroraShader : mgeShaderHandle
---@field Intensity number
local shader = mgeShadersConfig.load{ name = "darkshard_aurora" }
shader.enabled = false

return shader