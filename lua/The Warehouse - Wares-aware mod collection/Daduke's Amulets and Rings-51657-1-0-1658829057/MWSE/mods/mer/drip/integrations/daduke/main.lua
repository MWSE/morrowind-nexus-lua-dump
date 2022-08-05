local interop = require("mer.drip")
-- Daduke amulets rings

local materials = require("mer.drip.integrations.daduke.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local clothing = require("mer.drip.integrations.daduke.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
