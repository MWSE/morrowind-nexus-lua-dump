local interop = require("mer.drip")
--FCOT
local materials = require("mer.drip.integrations.fcot.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end
local armor = require("mer.drip.integrations.fcot.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end
local clothing = require("mer.drip.integrations.fcot.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
