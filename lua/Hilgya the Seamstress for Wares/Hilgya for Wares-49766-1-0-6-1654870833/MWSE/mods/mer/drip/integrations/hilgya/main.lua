local interop = require("mer.drip")
--hilgya
local materials = require("mer.drip.integrations.hilgya.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local clothing = require("mer.drip.integrations.hilgya.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end