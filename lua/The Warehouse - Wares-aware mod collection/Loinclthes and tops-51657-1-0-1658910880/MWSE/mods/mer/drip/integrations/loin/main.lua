local interop = require("mer.drip")
-- Dereko's Loinclothes and tops

local materials = require("mer.drip.integrations.loin.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local clothing = require("mer.drip.integrations.loin.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
