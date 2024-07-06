

local config = require("mer.joyOfPainting.config")
local ShaderService = require("mer.joyOfPainting.services.ShaderService")

event.register("loaded", function()
    for _, shaderId in pairs(config.shaders) do
        ShaderService.disable(shaderId)
    end
end)