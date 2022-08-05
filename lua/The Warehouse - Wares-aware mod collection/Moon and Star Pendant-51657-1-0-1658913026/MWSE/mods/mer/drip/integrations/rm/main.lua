local interop = require("mer.drip")
--Rm 's moon and star amulet

local materials = require("mer.drip.integrations.rm.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local clothing = require("mer.drip.integrations.rm.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
