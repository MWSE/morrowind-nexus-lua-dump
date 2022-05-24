local common = require("mer.drip.common")
local logger = common.createLogger("Interop")
local Modifier = require("mer.drip.components.Modifier")
local config = common.config

local drip = {}

function drip.registerMaterialPattern(str)
    --Puts patterns with multiple words at the front so they get caught first
    if string.find(str, " ") then

        table.insert(config.materials, 1, str)
    else
        table.insert(config.materials, str:lower())
    end
end

function drip.registerModifier(modifierData)
    local modifier = Modifier:new(modifierData)
    if not modifier then
        logger:trace("Invalid modifier data")
        return
    end
    if modifier.prefix then
        logger:trace("Registering as prefix %s", modifier.prefix)
        table.insert(config.modifiers.prefixes, modifier)
    elseif modifier.suffix then
        logger:trace("Registering as suffix %s", modifier.suffix)
        table.insert(config.modifiers.suffixes, modifier)
    else
        logger:trace("Invalid modifier data: no prefix or suffix provided")
        return
    end
end

function drip.registerWeapon(weaponId)
    logger:trace("registering weapon id %s", weaponId)
    config.weapons[weaponId:lower()] = true
end

function drip.registerArmor(armorId)
    logger:trace("registering armor id %s", armorId)
    config.armor[armorId:lower()] = true
end

function drip.registerClothing(clothingId)
    logger:trace("registering clothing id %s", clothingId)
    config.clothing[clothingId:lower()] = true
end

return drip
