local interop = require("mer.drip")
--TR
local materials = require("mer.drip.integrations.s&t.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local clothing = require("mer.drip.integrations.s&t.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
