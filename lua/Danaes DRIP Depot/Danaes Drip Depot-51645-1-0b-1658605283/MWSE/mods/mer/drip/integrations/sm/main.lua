local interop = require("mer.drip")
--Shadow_Mimicy's mods

local materials = require("mer.drip.integrations.sm.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local armor = require("mer.drip.integrations.sm.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end
local clothing = require("mer.drip.integrations.sm.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
