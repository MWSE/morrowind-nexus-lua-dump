local interop = require("mer.drip")
--Elucidate netch scout helmets + indoril ronin

local interop = require("mer.drip")
--netch scout helmets
local materials = require("mer.drip.integrations.elu.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local armor = require("mer.drip.integrations.elu.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end

