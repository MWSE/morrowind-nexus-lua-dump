local interop = require("mer.drip")
--ashtaar
local materials = require("mer.drip.integrations.ashtaar.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end
local armor = require("mer.drip.integrations.ashtaar.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end
local clothing = require("mer.drip.integrations.ashtaar.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end

