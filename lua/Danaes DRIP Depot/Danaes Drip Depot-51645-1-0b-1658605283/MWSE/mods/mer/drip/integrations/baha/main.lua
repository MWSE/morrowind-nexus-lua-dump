local interop = require("mer.drip")
--SaintBahamut witcherm Zirael and Tribunal Robes

local materials = require("mer.drip.integrations.baha.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end
local weapons = require("mer.drip.integrations.baha.weapons")
for _, weapon in ipairs(weapons) do
    interop.registerWeapon(weapon)
end
local armor = require("mer.drip.integrations.baha.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end

