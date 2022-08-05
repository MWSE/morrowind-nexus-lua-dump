local interop = require("mer.drip")
--House of Spears
local materials = require("mer.drip.integrations.hos.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end
local weapons = require("mer.drip.integrations.hos.weapons")
for _, weapon in ipairs(weapons) do
    interop.registerWeapon(weapon)
end

