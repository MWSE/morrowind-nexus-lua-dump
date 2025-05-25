

local config = require("mer.joyOfPainting.config")
local ShaderService = require("mer.joyOfPainting.services.ShaderService")

event.register("loaded", function()
    for _, shader in pairs(config.shaders) do
        ShaderService.disable(shader.shaderId)
    end
end)