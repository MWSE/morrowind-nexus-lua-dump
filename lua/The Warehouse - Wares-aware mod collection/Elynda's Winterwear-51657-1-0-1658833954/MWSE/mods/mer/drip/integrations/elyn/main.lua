local interop = require("mer.drip")
--Elynda Winter wear
local materials = require("mer.drip.integrations.elyn.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local armor = require("mer.drip.integrations.elyn.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end
local clothing = require("mer.drip.integrations.elyn.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
