local interop = require("mer.drip")
-- Natinnet's mods

local materials = require("mer.drip.integrations.natin.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end
local weapons = require("mer.drip.integrations.natin.weapons")
for _, weapon in ipairs(weapons) do
    interop.registerWeapon(weapon)
end

local clothing = require("mer.drip.integrations.natin.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end

local armor = require("mer.drip.integrations.natin.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end