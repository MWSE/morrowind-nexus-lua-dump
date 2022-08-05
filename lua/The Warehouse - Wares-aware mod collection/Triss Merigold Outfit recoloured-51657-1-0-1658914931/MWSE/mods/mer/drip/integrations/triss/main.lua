local interop = require("mer.drip")
--TR
local materials = require("mer.drip.integrations.triss.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local armor = require("mer.drip.integrations.triss.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end

