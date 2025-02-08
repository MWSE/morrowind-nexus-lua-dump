local interop = require("mer.drip")
--Vaernis
local materials = require("mer.drip.integrations.vaernis.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local armor = require("mer.drip.integrations.vaernis.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end
