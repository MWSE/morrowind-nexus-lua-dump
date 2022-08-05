local interop = require("mer.drip")
--Illy's Oh My Godess
local materials = require("mer.drip.integrations.illy.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end

local clothing = require("mer.drip.integrations.illy.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
