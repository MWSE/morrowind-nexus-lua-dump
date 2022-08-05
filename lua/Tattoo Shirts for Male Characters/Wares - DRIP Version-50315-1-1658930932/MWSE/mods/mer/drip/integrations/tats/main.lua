local interop = require("mer.drip")
--AlandroSul's tattooed shirts

local materials = require("mer.drip.integrations.tats.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local clothing = require("mer.drip.integrations.tats.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
