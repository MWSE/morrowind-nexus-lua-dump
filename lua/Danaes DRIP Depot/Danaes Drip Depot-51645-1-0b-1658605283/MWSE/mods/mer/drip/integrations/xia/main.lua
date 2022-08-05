local interop = require("mer.drip")
-- Amulets by Xiamara

local materials = require("mer.drip.integrations.xia.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local clothing = require("mer.drip.integrations.xia.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
