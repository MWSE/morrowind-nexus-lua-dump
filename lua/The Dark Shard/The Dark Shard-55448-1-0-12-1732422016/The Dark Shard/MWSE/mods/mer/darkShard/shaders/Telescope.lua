---@class DarkShard.TelescopeShader : mgeShaderHandle
---@field radius number
---@field RedOffset number
---@field GreenOffset number
---@field BlueOffset number
---@field FishEyeWidth number
---@field FishEyeStrength number
---@field HideGround boolean
local shader = mgeShadersConfig.load{ name = "darkshard_telescope" }
shader.enabled = false

return shader
