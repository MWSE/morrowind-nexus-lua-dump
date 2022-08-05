local interop = require("mer.drip")
--anroha's mods

local weapons = require("mer.drip.integrations.anroha.weapons")
for _, weapon in ipairs(weapons) do
    interop.registerWeapon(weapon)
end

local armor = require("mer.drip.integrations.anroha.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end

local materials = require("mer.drip.integrations.anroha.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end