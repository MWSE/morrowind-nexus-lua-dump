local interop = require("mer.drip")
--Assassin's Arsenal
local materials = require("mer.drip.integrations.arsenal.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end
local weapons = require("mer.drip.integrations.arsenal.weapons")
for _, weapon in ipairs(weapons) do
    interop.registerWeapon(weapon)
end
local armor = require("mer.drip.integrations.arsenal.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end

