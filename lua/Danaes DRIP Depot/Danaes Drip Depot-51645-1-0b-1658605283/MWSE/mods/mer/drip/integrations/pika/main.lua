local interop = require("mer.drip")
--AATL + bucklers

local materials = require("mer.drip.integrations.pika.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end
local armor = require("mer.drip.integrations.pika.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end

local clothing = require("mer.drip.integrations.pika.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end

local weapons = require("mer.drip.integrations.pika.weapons")
for _, weapon in ipairs(weapons) do
    interop.registerWeapon(weapon)
end

