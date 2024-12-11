---@class DarkShard.QuakeShader : mgeShaderHandle
---@field Range number
---@field Speed number
---@field Zoom number
local shader = mgeShadersConfig.load{ name = "darkshard_quake" }
shader.enabled = false

return shader