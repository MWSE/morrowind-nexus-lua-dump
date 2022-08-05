local interop = require("mer.drip")
--Olaf's Old Steel Armor + Ergalla + cloaks

local armor = require("mer.drip.integrations.olaf.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end


local materials = require("mer.drip.integrations.olaf.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

