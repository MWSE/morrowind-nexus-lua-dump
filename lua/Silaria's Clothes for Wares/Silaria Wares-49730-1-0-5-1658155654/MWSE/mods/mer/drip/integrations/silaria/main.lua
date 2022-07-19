local interop = require("mer.drip")
--Silaria
local materials = require("mer.drip.integrations.silaria.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end
local clothing = require("mer.drip.integrations.silaria.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
