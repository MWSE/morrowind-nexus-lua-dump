local common = require("mer.drip.common")
local logger = common.createLogger("main")
--Register effects first so the tes3.effect exists
require("mer.drip.customEffects")
require("mer.drip.mcm")
require("mer.drip.controllers.lootPlacement")
require("mer.drip.controllers.tooltips")

--Register modifiers and items
local interop = require("mer.drip")
local materials = require("mer.drip.config.vanilla.materials")
for _, pattern in ipairs(materials) do
    interop.registerMaterialPattern(pattern)
end
local modifiers = require("mer.drip.config.vanilla.modifiers")
for _, modifierData in ipairs(modifiers) do
    interop.registerModifier(modifierData)
end
local weapons = require("mer.drip.config.vanilla.weapons")
for _, weapon in ipairs(weapons) do
    interop.registerWeapon(weapon)
end
local armor = require("mer.drip.config.vanilla.armor")
for _, armor in ipairs(armor) do
    interop.registerArmor(armor)
end
local clothing = require("mer.drip.config.vanilla.clothing")
for _, clothing in ipairs(clothing) do
    interop.registerClothing(clothing)
end
logger:info("initialized %s", common.getVersion())