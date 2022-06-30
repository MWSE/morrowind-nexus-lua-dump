local interop = require("mer.drip")
--TR
local materials = require("mer.drip.integrations.bob.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end
local weapons = require("mer.drip.integrations.bob.weapons")
for _, weapon in ipairs(weapons) do
    interop.registerWeapon(weapon)
end
local armor = require("mer.drip.integrations.bob.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end
local clothing = require("mer.drip.integrations.bob.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
