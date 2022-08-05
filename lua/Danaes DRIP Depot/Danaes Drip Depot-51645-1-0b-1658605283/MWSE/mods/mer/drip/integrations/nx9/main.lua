local interop = require("mer.drip")
--nx9 Hlaalu Redoran Founder MT

local materials = require("mer.drip.integrations.nx9.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end
local armor = require("mer.drip.integrations.nx9.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end


