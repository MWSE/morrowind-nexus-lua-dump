local interop = require("mer.drip")
--TR
local materials = require("mer.drip.integrations.tr.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end
local weapons = require("mer.drip.integrations.tr.weapons")
for _, weapon in ipairs(weapons) do
    interop.registerWeapon(weapon)
end
local armor = require("mer.drip.integrations.tr.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end
local clothing = require("mer.drip.integrations.tr.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
