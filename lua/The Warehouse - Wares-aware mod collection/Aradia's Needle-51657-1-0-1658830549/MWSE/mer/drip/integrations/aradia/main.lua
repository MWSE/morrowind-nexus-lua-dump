local interop = require("mer.drip")
--Aradia's Needle

local materials = require("mer.drip.integrations.aradia.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local armor = require("mer.drip.integrations.aradia.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end
local clothing = require("mer.drip.integrations.aradia.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
