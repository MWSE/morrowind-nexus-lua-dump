local interop = require("mer.drip")
--Wulfgar Rings
local materials = require("mer.drip.integrations.wulf.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local clothing = require("mer.drip.integrations.wulf.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
