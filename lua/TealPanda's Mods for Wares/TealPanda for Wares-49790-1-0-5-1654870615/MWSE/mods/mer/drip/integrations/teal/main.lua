local interop = require("mer.drip")
--FCOT
local materials = require("mer.drip.integrations.teal.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local clothing = require("mer.drip.integrations.teal.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
