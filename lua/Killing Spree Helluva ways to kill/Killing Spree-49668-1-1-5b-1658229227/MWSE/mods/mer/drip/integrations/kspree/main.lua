local interop = require("mer.drip")
--Killing Spree

local materials = require("mer.drip.integrations.kspree.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end
local weapons = require("mer.drip.integrations.kspree.weapons")
for _, weapon in ipairs(weapons) do
    interop.registerWeapon(weapon)
end



