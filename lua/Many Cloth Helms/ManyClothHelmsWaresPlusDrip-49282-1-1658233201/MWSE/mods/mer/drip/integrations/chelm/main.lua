local interop = require("mer.drip")
--ManyClothHelms

local armor = require("mer.drip.integrations.chelm.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end
